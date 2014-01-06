module CatalogHelper
  include Blacklight::CatalogHelperBehavior
  # overridden to always use a partial in the `catalog' directory
  def render_document_sidebar_partial(_document = @document)
    render 'catalog/show_sidebar'
  end
end
