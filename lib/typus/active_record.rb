module Typus

  def self.included(base)
    base.extend ClassMethods
  end

  module ClassMethods

    ##
    # Return model fields as an array
    #
    def model_fields
      columns.map { |u| [u.name, u.type.to_s] }
    end

    ##
    # Return model fields as a hash
    #
    def model_fields_hash
      hash = Hash.new
      columns.map { |u| hash[u.name.to_sym] = u.type.to_sym }
      return hash
    end

    ##
    #
    #
    def humanize
      name.titleize.capitalize
    end

    ##
    # Form and list fields
    #
    #   class Post < ActiveRecord::Base
    #
    #     def self.list_fields
    #       [ :title, :category_id, :status ]
    #     end
    #
    #     def self.form_fields
    #       [ :title, :body, :excerpt, :category_id, :status ]
    #     end
    #
    #   end
    #
    def typus_fields_for(filter)

      fields_with_type = []

      begin
        if self.respond_to?("#{filter.to_s}_fields")
          fields = self.send("#{filter.to_s}_fields").map { |a| a.to_s }
        else
          fields = Typus::Configuration.config["#{self.name}"]["fields"][filter.to_s].split(", ")
        end
      rescue
        filter = 'list'
        retry
      end

      begin

        fields.each do |field|

          ##
          # Get the field_type for each field
          #
          self.model_fields.each do |af|
            @attribute_type = af.last if af.first == field
          end

          ##
          # Believe me, I don't know why I have to do this, otherwise
          # the plugin doesn't work.
          #
          attribute_type = @attribute_type

          ##
          # Some custom field_type depending on the attribute name
          #
          case field
            when 'parent_id':       attribute_type = 'tree'
            when /_id/:             attribute_type = 'collection'
            when /file_name/:       attribute_type = 'file'
            when /password/:        attribute_type = 'password'
            when 'position':        attribute_type = 'position'
            when self.typus_selectors.join(',')
              attribute_type = 'selector'
          end

          ##
          # And finally insert the field and the attribute_type 
          # into the fields_with_type.
          #
          fields_with_type << [ field, attribute_type ]

        end

      rescue
        fields = Typus::Configuration.config["#{self.name}"]["fields"]["list"].split(", ")
        retry
      end

      return fields_with_type

    end

    ##
    # Typus sidebar filters.
    #
    #   class Post < ActiveRecord::Base
    #
    #     def self.filters
    #       [ :created_at, :status ]
    #     end
    #
    #   end
    #
    def typus_filters
      available_fields = self.model_fields
      begin
        fields = self.filters.map { |a| a.to_s }
      rescue
        return [] unless Typus::Configuration.config["#{self.name}"]["filters"]
        fields = Typus::Configuration.config["#{self.name}"]["filters"].split(", ")
      end
      fields_with_type = []
      fields.each do |field|
        if available_fields.map { |a| a.first }.include? field
          type = available_fields.map { |a| a.last if field == a.first }.compact.first
          fields_with_type << [ field, type ]
        end
      end
      return fields_with_type
    end

    ##
    #  Extended actions for this model on Typus.
    #
    #    class Post < ActiveRecord::Base
    #
    #      def self.list_actions
    #        [ :rebuild_all ]
    #      end
    #
    #      def self.form_actions
    #        [ :rebuild, :notify ]
    #      end
    #
    #    end
    #
    def typus_actions_for(filter)
      begin
        self.send("#{filter}_actions").map { |a| a.to_s }
      rescue
        Typus::Configuration.config[self.name]['actions'][filter.to_s].split(', ') rescue []
      end
    end

    ##
    # Used for +order_by+, +search+ and more ...
    #
    # Someday we could use something like:
    #
    #     typus_search :title, :details
    #     typus_related :tags, :categories
    #
    # Default order is ASC, except for datetime items which is DESC.
    #
    def typus_defaults_for(filter)
      Typus::Configuration.config[self.name][filter.to_s].split(', ') rescue []
    end

    ##
    # This has to be removed.
    #
    def typus_selectors
      Typus::Configuration.config[self.name]['selectors'].split(', ') rescue []
    end

    ##
    #
    #
    def typus_field_options_for(filter)
      Typus::Configuration.config[self.name]['fields']['options'][filter.to_s].split(', ') rescue []
    end

    ##
    # Used for +relationships+
    #
    def typus_relationships_for(filter)
      Typus::Configuration.config[self.name]['relationships'][filter.to_s].split(', ') rescue []
    end

    def typus_order_by
      return "id ASC" unless Typus::Configuration.config[self.name]['order_by']
      fields = Typus::Configuration.config[self.name]['order_by'].split(', ')
      order = []
      fields.each do |field|
        if field.include?("-")
          order << "#{field.delete("-")} DESC"
        else
          order << "#{field} ASC"
        end
      end
      return order.join(", ")
    end

    ##
    # This is used by acts_as_tree
    #
    def top
      find :all, :conditions => [ "parent_id IS ?", nil ]
    end

    ##
    # Build conditions
    #
    #     params = request.env['QUERY_STRING']
    #
    def build_conditions(params)
      conditions = "1 = 1 "
      params.split('&').each do |q|
        the_key, the_value = q.split("=").first, q.split("=").last
        if the_key == "search"
          search = Array.new
          self.typus_defaults_for('search').each { |s| search << "LOWER(#{s}) LIKE '%#{CGI.unescape(the_value)}%'" }
          conditions << "AND (#{search.join(" OR ")}) "
        end
        self.model_fields.each do |f|
          filter_type = f[1] if f[0] == the_key
          case filter_type
          when "boolean"
            if %w(sqlite3 sqlite).include? ActiveRecord::Base.connection.adapter_name.downcase
              conditions << "AND #{f[0]} = '#{the_value[0..0]}' "
            else
              status = (the_value == 'true') ? 1 : 0
              conditions << "AND #{f[0]} = '#{status}' "
            end
          when "datetime"
            case the_value
            when 'today':         start_date, end_date = Time.today, Time.today.tomorrow
            when 'past_7_days':   start_date, end_date = 6.days.ago.midnight, Time.today.tomorrow
            when 'this_month':    start_date, end_date = Time.today.last_month, Time.today.tomorrow
            when 'this_year':     start_date, end_date = Time.today.last_year, Time.today.tomorrow
            end
            start_date, end_date = start_date.to_s(:db), end_date.to_s(:db)
            conditions << "AND created_at > '#{start_date}' AND created_at < '#{end_date}' "
          when "integer"
            conditions << "AND #{f[0]} = #{the_value} " if f[0].include? "_id"
          when "string"
            conditions << "AND #{f[0]} = '#{the_value}' "
          end
        end
      end
      return conditions
    end

  end

  module InstanceMethods

    def previous(condition = {})

      if condition.empty?
        conditions = "id < #{self.id}"
      else
        conditions = self.class.build_conditions(condition)
        conditions << " AND id != #{self.id}"
      end

      self.class.find :first, 
                      :order => "id DESC", 
                      :conditions => conditions

    end

    def next(condition = {})

      if condition.empty?
        conditions = "id > #{self.id}"
      else
        conditions = self.class.build_conditions(condition)
        conditions << " AND id != #{self.id}"
      end

      self.class.find :first, 
                      :order => "id ASC", 
                      :conditions => conditions

    end

    ##
    # Used by acts_as_tree to detect children.
    #
    def has_children?
      children.size > 0
    end

    ##
    #
    #
    def typus_name
      return to_label if respond_to? :to_label
      return name if respond_to? :name
      "#{self.class}##{id}"
    end

  end

end

ActiveRecord::Base.send :include, Typus
ActiveRecord::Base.send :include, Typus::InstanceMethods