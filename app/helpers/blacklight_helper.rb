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

  # override Blacklight so link_to will load GET /objects/id
  def link_to_document(doc, opts={:label=>nil, :counter => nil})
  	opts[:label] ||= document_show_link_field(doc)
    label = render_document_index_label doc, opts
    link_to label, doc
  end
end
