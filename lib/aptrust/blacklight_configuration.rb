module Aptrust
  module BlacklightConfiguration
    extend ActiveSupport::Concern

    included do

      configure_blacklight do |config|
        title_field =       solr_name('desc_metadata__title', :stored_searchable)
        institution_field = solr_name('institution_name', :stored_sortable)
        identifier_field =  solr_name('desc_metadata__identifier', :stored_searchable)
        description_field = solr_name('desc_metadata__description', :stored_searchable)
        rights_field = solr_name('desc_metadata__rights', :facetable)
        format_field = solr_name('format', :facetable)

        config.default_solr_params = {
          :qf => [title_field, identifier_field, description_field].join(' '),
          :qt => 'search',
          :rows => 10
        }

        # solr field configuration for search results/index views
        config.index.show_link = 'desc_metadata__title_tesim'
        config.index.record_display_type = 'has_model_ssim'

        # solr field configuration for document/show views
        config.show.html_title = 'desc_metadata__title_tesim'
        config.show.heading = 'desc_metadata__title_tesim'
        config.show.display_type = 'has_model_ssim'

        config.add_facet_field institution_field, sort: 'index', label: "Institution"
        config.add_facet_field rights_field, sort: 'index', label: "Rights"
        config.add_facet_field format_field, sort: 'index', label: "Format"

        # Have BL send all facet field names to Solr, which has been the default
        # previously. Simply remove these lines if you'd rather use Solr request
        # handler defaults, or have no facets.
        config.default_solr_params[:'facet.field'] = config.facet_fields.keys
        config.add_facet_fields_to_solr_request!

        # solr fields to be displayed in the index (search results) view
        #   The ordering of the field names is the order of the display
        config.add_index_field title_field, label: 'Title:'
        config.add_index_field institution_field, label: 'Institution:'
        config.add_index_field identifier_field, label: 'Identifier:'
        config.add_index_field description_field, label: 'Description:'

        config.add_search_field 'all_fields', :label => 'All Fields'

        config.add_search_field(identifier_field) do |field|
          field.label = "Identifier"
          field.solr_local_parameters = {
            :qf => identifier_field,
            :pf => '$original_pid_pf'
          }
        end

        # Now we see how to over-ride Solr request handler defaults, in this
        # case for a BL "search field", which is really a dismax aggregate
        # of Solr search fields.

        config.add_search_field(title_field) do |field|
          field.label = "Title"
           # :solr_local_parameters will be sent using Solr LocalParams
           # syntax, as eg {! qf=$title_qf }. This is neccesary to use
           # Solr parameter de-referencing like $title_qf.
           # See: http://wiki.apache.org/solr/LocalParams
           field.solr_local_parameters = {
             :qf => title_field,
             :pf => '$title_pf'
           }
        end

        config.add_sort_field 'score desc, system_create_dtsi desc, desc_metadata__title_si asc', :label => 'relevance'
        config.add_sort_field 'pub_date_dtsi desc, desc_metadata__title_si asc', :label => 'date added'
        config.add_sort_field 'desc_metadata__title_si asc, system_create_dtsi desc', :label => 'title'

        # If there are more than this many search results, no spelling ("did you
        # mean") suggestion is offered.
        config.spell_max = 5
      end
    end
  end
end
