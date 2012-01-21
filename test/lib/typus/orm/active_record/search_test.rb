require "test_helper"

class ActiveRecordTest < ActiveSupport::TestCase

  context "build_search_conditions" do

    should "work for Post (title)" do
      output = Post.build_search_conditions("search", "bacon")

      expected = case db_adapter
                 when "postgresql"
                   "LOWER(TEXT(posts.title)) LIKE '%bacon%'"
                 else
                   "posts.title LIKE '%bacon%'"
                 end

      assert_equal expected, output
    end

    should "work for Comment (email, body)" do
      output = Comment.build_search_conditions("search", "bacon")

      expected = case db_adapter
                 when "postgresql"
                   ["LOWER(TEXT(comments.body)) LIKE '%bacon%'",
                    "LOWER(TEXT(comments.email)) LIKE '%bacon%'"]
                 else
                   ["comments.body LIKE '%bacon%'",
                    "comments.email LIKE '%bacon%'"]
                 end

      expected.each { |e| assert_match e, output }
      assert_match /OR/, output
    end

    should "generate conditions for id" do
      Post.expects(:typus_defaults_for).with(:search).returns(["id"])

      expected = case db_adapter
                 when "postgresql"
                   "LOWER(TEXT(posts.id)) LIKE '%1%'"
                 else
                   "posts.id LIKE '%1%'"
                 end
      output = Post.build_search_conditions("search", "1")

      assert_equal expected, output
    end

    should "generate conditions for fields starting with equal" do
      Post.expects(:typus_defaults_for).with(:search).returns(["=id"])

      expected = case db_adapter
                 when "postgresql"
                   "LOWER(TEXT(posts.id)) LIKE '1'"
                 else
                   "posts.id LIKE '1'"
                 end
      output = Post.build_search_conditions("search", "1")

      assert_equal expected, output
    end

    should "generate conditions for fields starting with ^" do
      Post.expects(:typus_defaults_for).with(:search).returns(["^id"])

      expected = case db_adapter
                 when "postgresql"
                   "LOWER(TEXT(posts.id)) LIKE '1%'"
                 else
                   "posts.id LIKE '1%'"
                 end
      output = Post.build_search_conditions("search", "1")

      assert_equal expected, output
    end

  end

  test "build_boolean_conditions returns true" do
    expected = {'status'=>true}
    output = Page.build_boolean_conditions('status', 'true')
    assert_equal expected, output
  end

  test "build_boolean_conditions returns false" do
    expected = {'status'=>false}
    output = Page.build_boolean_conditions('status', 'false')
    assert_equal expected, output
  end

  context "build_datetime_conditions" do

    [["2012/1/13", Date.new(2012,1,13).to_time..Date.new(2012,1,13).end_of_day],
      ["2012/1/13 - 2012/1/15", Date.new(2012,1,13).to_time..Date.new(2012,1,15).end_of_day]].each do |input, interval|

      should "generate the condition for #{input}" do
        output = Article.build_datetime_conditions('created_at', input).first
        assert_equal "articles.created_at BETWEEN ? AND ?", output
      end

      should "work for #{input}" do
        expected = [interval.first.to_s(:db), interval.last.to_s(:db)]
        output = Article.build_datetime_conditions('created_at', input)[1..-1]
        assert_equal expected, output
      end

    end

  end

  context "build_date_conditions" do

    [["2012/1/13", Date.new(2012,1,13)..Date.new(2012,1,13)],
     ["2012/1/13 - 2012/1/15", Date.new(2012,1,13)..Date.new(2012,1,15)]].each do |input, interval|

      should "generate the condition for #{input}" do
        output = Article.build_date_conditions('created_at', input).first
        assert_equal "articles.created_at BETWEEN ? AND ?", output
      end

      should "work for #{input}" do
        expected = [interval.first.to_s(:db), interval.last.to_s(:db)]
        output = Article.build_date_conditions('created_at', input)[1..-1]
        assert_equal expected, output
      end

    end

  end

  test "build_string_conditions" do
    expected = {'test'=>'true'}
    output = Page.build_string_conditions('test', 'true')
    assert_equal expected, output
  end

  # TODO: build_has_many_conditions with non-standard primary keys
  test "build_has_many_conditions" do
    expected = ["projects.id = ?", "1"]
    output = User.build_has_many_conditions('projects', '1')
    assert_equal expected, output
  end

  context "build_conditions" do

    should "return an array" do
      params = { :search => '1' }
      assert Post.build_conditions(params).is_a?(Array)
    end

    should "return_sql_conditions_on_search_for_typus_user" do
      expected = case db_adapter
                 when "postgresql"
                   ["LOWER(TEXT(typus_users.first_name)) LIKE '%francesc%'",
                    "LOWER(TEXT(typus_users.last_name)) LIKE '%francesc%'", 
                    "LOWER(TEXT(typus_users.email)) LIKE '%francesc%'",
                    "LOWER(TEXT(typus_users.role)) LIKE '%francesc%'"]
                 else
                   ["typus_users.first_name LIKE '%francesc%'",
                    "typus_users.last_name LIKE '%francesc%'",
                    "typus_users.email LIKE '%francesc%'",
                    "typus_users.role LIKE '%francesc%'"]
                 end

      [{:search =>"francesc"}, {:search => "Francesc"}].each do |params|
        expected.each do |expect|
          assert_match expect, TypusUser.build_conditions(params).first
        end
        assert_no_match /AND/, TypusUser.build_conditions(params).first
      end
    end

    should "return_sql_conditions_on_search_and_filter_for_typus_user" do
      expected = case db_adapter
                 when "postgresql"
                   ["LOWER(TEXT(typus_users.role)) LIKE '%francesc%'",
                    "LOWER(TEXT(typus_users.last_name)) LIKE '%francesc%'",
                    "LOWER(TEXT(typus_users.email)) LIKE '%francesc%'",
                    "LOWER(TEXT(typus_users.first_name)) LIKE '%francesc%'"]
                 else
                    ["typus_users.first_name LIKE '%francesc%'",
                     "typus_users.last_name LIKE '%francesc%'",
                     "typus_users.email LIKE '%francesc%'",
                     "typus_users.role LIKE '%francesc%'"]
                 end

      params = { :search => "francesc", :status => "true" }

      FactoryGirl.create(:typus_user, :email => "francesc.one@example.com")
      FactoryGirl.create(:typus_user, :email => "francesc.dos@example.com", :status => false)

      resource = TypusUser
      resource.build_conditions(params).each do |condition|
        resource = resource.where(condition)
      end

      assert_equal ["francesc.one@example.com"], resource.map(&:email)
    end

    should "return_sql_conditions_on_filtering_typus_users_by_status true" do
      params = { :status => "true" }
      expected = { :status => true }
      assert_equal expected, TypusUser.build_conditions(params).first
    end

    should "return_sql_conditions_on_filtering_typus_users_by_status false" do
      params = { :status => "false" }
      expected = { :status => false }
      assert_equal expected, TypusUser.build_conditions(params).first
    end

    should "return_sql_conditions_on_filtering_posts_by_string" do
      params = { :role => "admin" }
      assert_equal params, TypusUser.build_conditions(params).first
    end

  end

  test "build_my_joins return the expected joins" do
    @project = FactoryGirl.create(:project)
    FactoryGirl.create_list(:project, 2)
    params = { :projects => @project.id }
    assert_equal [:projects], User.build_my_joins(params)
  end

  test "build_my_joins works when users are filtered by projects" do
    @project = FactoryGirl.create(:project)
    FactoryGirl.create_list(:project, 2)

    params = { :projects => @project.id }

    @resource = User
    @resource.build_conditions(params).each { |c| @resource = @resource.where(c) }
    @resource.build_my_joins(params).each { |j| @resource = @resource.joins(j) }

    assert_equal [@project.user.id], @resource.map(&:id)
  end

end
