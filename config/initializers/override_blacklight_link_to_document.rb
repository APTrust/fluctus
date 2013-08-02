require 'hydra/blacklight_helper_behavior'

module Hydra
  module BlacklightHelperBehavior
    def link_to_document(doc, opts={:label=>nil, :counter => nil, :results_view => true})
      path = "#{document_partial_name(doc).pluralize}/#{doc.id}"
      opts[:label] ||= blacklight_config.index.show_link.to_sym
      label = render_document_index_label doc, opts
      # link_to label, path, {:'data-counter' => opts[:counter] }.merge(opts.reject { |k,v| [:label, :counter, :results_view].include? k  })
      link_to label, path
    end
  end
end

