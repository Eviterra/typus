module Admin::Resources::PaginationHelper

  def admin_paginate(items, options)
    if defined?(Kaminari)
      paginate(items, options)
    elsif defined?(WillPaginate)
      will_paginate(items, options)
    else
      "<p align='center'>Showing only #{@resource.typus_options_for(:per_page)} records. Please, install <strong>Kaminari</strong> or <strong>WillPaginate</strong> to paginate.</p>".html_safe
    end
  end

end
