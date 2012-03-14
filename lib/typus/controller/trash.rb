# Module designed to work with `rails-trash`.
module Typus
  module Controller
    module Trash

      def self.included(base)
        base.before_filter :set_predefined_filter_for_trash, :only => [:index, :trash]
      end

      def set_predefined_filter_for_trash
        if admin_user.can?('edit', @resource.model_name)
          add_predefined_filter("Trash", "trash", "deleted")
        end
      end
      private :set_predefined_filter_for_trash

      def trash
        set_deleted

        get_objects

        respond_to do |format|
          format.html do
            # Actions by resource.
            add_resource_action 'Restore', { :action => 'restore' }, { :confirm => Typus::I18n.t("Restore %{resource}?", :resource => @resource.model_name.human) }
            add_resource_action 'Delete Permanently', { :action => 'wipe' }, { :confirm => Typus::I18n.t("Delete Permanently?") }
            # Generate and render.
            generate_html
            render 'index'
          end

          format.csv { generate_csv }
          format.json { export(:json) }
          format.xml { export(:xml) }
        end
      end

      def restore
        @resource.restore(params[:id])
        redirect_to :back, :notice => Typus::I18n.t("%{resource} recovered from trash.", :resource => @resource.name)
      rescue ActiveRecord::RecordNotFound
        redirect_to :back, :notice => Typus::I18n.t("%{resource} can't be recovered from trash.", :resource => @resource.name)
      end

      def wipe
        item = @resource.find_in_trash(params[:id])
        item.disable_trash { item.destroy }
        redirect_to :back, :notice => Typus::I18n.t("%{resource} has been successfully removed from trash.", :resource => @resource.name)
      end

      def set_deleted
        @resource = @resource.deleted
      end
      private :set_deleted

    end
  end
end
