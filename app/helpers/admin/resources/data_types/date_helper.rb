module Admin::Resources::DataTypes::DateHelper

  # do nothing
  def date_filter(filter)
    []
  end

  alias_method :datetime_filter, :date_filter
  alias_method :timestamp_filter, :date_filter

end
