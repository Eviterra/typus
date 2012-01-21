module Typus
  module Orm
    module Base
      module Search

        def build_search_conditions(key, value)
          raise "Not implemented!"
        end

        def build_boolean_conditions(key, value)
          { key => (value == 'true') ? true : false }
        end

        # Timezone?
        def build_datetime_conditions(key, value)
          firstdate, lastdate = value.strip.split('-')
          lastdate ||= firstdate
          interval = firstdate.to_date.beginning_of_day..lastdate.to_date.end_of_day
          build_filter_interval(interval, key)
        end

        alias_method :build_time_conditions, :build_datetime_conditions

        def build_date_conditions(key, value)
          firstdate, lastdate = value.strip.split('-')
          lastdate ||= firstdate
          interval = firstdate.to_date..lastdate.to_date
          build_filter_interval(interval, key)
        end

        def build_filter_interval(interval, key)
          raise "Not implemented!"
        end

        def build_string_conditions(key, value)
          { key => value }
        end

        alias_method :build_integer_conditions, :build_string_conditions
        alias_method :build_belongs_to_conditions, :build_string_conditions

        # TODO: Detect the primary_key for this object.
        def build_has_many_conditions(key, value)
          ["#{key}.id = ?", value]
        end

        ##
        # To build conditions we reject all those params which are not model
        # fields.
        #
        # Note: We still want to be able to search so the search param is not
        #       rejected.
        #
        def build_conditions(params)
          Array.new.tap do |conditions|
            query_params = params.dup

            query_params.reject! do |k, v|
              !model_fields.keys.include?(k.to_sym) &&
              !model_relationships.keys.include?(k.to_sym) &&
              !(k.to_sym == :search)
            end

            query_params.compact.each do |key, value|
              filter_type = model_fields[key.to_sym] || model_relationships[key.to_sym] || key
              conditions << send("build_#{filter_type}_conditions", key, value)
            end
          end
        end

        def build_my_joins(params)
          query_params = params.dup
          query_params.reject! { |k, v| !model_relationships.keys.include?(k.to_sym) }
          query_params.compact.map { |k, v| k.to_sym }
        end

      end
    end
  end
end
