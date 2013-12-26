module BlacklightHelper
  include Blacklight::BlacklightHelperBehavior

  # We overrode the function from Blacklight in order to replace the "bookmark"
  # button with the show/edit buttons
  def render_index_doc_actions(document, options={})
    wrapping_class = options.delete(:wrapping_class) || "documentFunctions"
    
    content_tag("div", class: wrapping_class) do
      render 'intellectual_objects/actions', {document: document}
    end
  end
end
