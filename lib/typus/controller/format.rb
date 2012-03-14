require 'csv'

module Typus
  module Controller
    module Format

      protected

      # This is crazy, but I want to have support for Kaminari, WillPaginate
      # and whatever other pagination system which comes.
      def get_paginated_data
        items_per_page = @resource.typus_options_for(:per_page)

        @items = if defined?(Kaminari)
          @resource.page(params[:page]).per(items_per_page)
        elsif defined?(WillPaginate)
          @resource.paginate(:page => params[:page], :per_page => items_per_page)
        else
          @resource.limit(items_per_page) # Pagination is disabled, so just in case limit to 50 records.
        end
      end

      alias_method :generate_html, :get_paginated_data

      def generate_csv
        fields = @resource.typus_fields_for(:csv)

        data = ::CSV.generate do |csv|
          csv << fields.keys.map { |k| @resource.human_attribute_name(k) }
          @resource.all.each do |record|
            csv << fields.map do |key, value|
                     case value
                     when :transversal
                       a, b = key.split(".")
                       record.send(a).send(b)
                     when :belongs_to
                       record.send(key).try(:to_label)
                     else
                       record.send(key)
                     end
                   end
          end
        end

        send_data data, :filename => "export-#{@resource.to_resource}-#{Time.zone.now.to_s(:number)}.csv"
      end

      def export(format)
        fields = @resource.typus_fields_for(format).map(&:first)
        methods = fields - @resource.column_names
        except = @resource.column_names - fields

        get_paginated_data

        render format => @items.send("to_#{format}", :methods => methods, :except => except)
      end

    end
  end
end
