module Aptrust
  module BlacklightConfiguration
    extend ActiveSupport::Concern

    included do

      configure_blacklight do |config|
        title_field =       solr_name('desc_metadata__title', :stored_searchable)
        institution_field = solr_name('institution_name', :stored_sortable)
        identifier_field =  solr_name('desc_metadata__intellectual_object_identifier', :stored_searchable)
        description_field = solr_name('desc_metadata__description', :stored_searchable)
        access_field = solr_name('desc_metadata__access', :facetable)
        bag_name_field = solr_name('desc_metadata__bag_name', :stored_searchable)
        alt_identifier_field = solr_name('desc_metadata__alt_identifier', :stored_searchable)
        file_format_field = solr_name('file_format', :facetable)
        event_type_field = solr_name('event_type', :symbol)
        event_outcome_field = solr_name('event_outcome', :symbol)
        gf_format_field = solr_name('tech_metadata__file_format', :stored_sortable)
        gf_institution_field = solr_name('gf_institution_name', :symbol)
        gf_parent_field = solr_name('gf_parent', :symbol)
        gf_identifier_field = solr_name('tech_metadata__identifier', :stored_searchable)

        config.default_solr_params = {
          :qf => [title_field, identifier_field, description_field, bag_name_field, alt_identifier_field, gf_identifier_field].join(' '),
          :qt => 'search',
          :rows => 10
        }

        # solr field configuration for search results/index views
        config.index.title_field = 'desc_metadata__title_tesim'
        config.index.display_type_field = 'has_model_ssim'

        # solr field configuration for document/show views
        config.show.title_field = 'desc_metadata__title_tesim'
        config.show.display_type_field = 'has_model_ssim'

        config.add_facet_field institution_field, sort: 'index', label: 'Institution'
        config.add_facet_field access_field, sort: 'index', label: 'Access'
        config.add_facet_field file_format_field, sort: 'index', label: 'Format'
        config.add_facet_field event_type_field, sort: 'index', label: 'Event Type'
        config.add_facet_field event_outcome_field, sort: 'index', label: 'Event Outcome'
        config.add_facet_field gf_format_field, sort: 'index', label: 'Mimetype'
        config.add_facet_field gf_institution_field, sort: 'index', label: 'Institution'
        config.add_facet_field gf_parent_field, sort: 'index', label: 'Associated Object'

        # Have BL send all facet field names to Solr, which has been the default
        # previously. Simply remove these lines if you'd rather use Solr request
        # handler defaults, or have no facets.
        config.default_solr_params[:'facet.field'] = config.facet_fields.keys
        config.add_facet_fields_to_solr_request!

        # solr fields to be displayed in the index (search results) view
        #   The ordering of the field names is the order of the display
        config.add_index_field title_field, label: 'Title'
        config.add_index_field institution_field, label: 'Institution'
        config.add_index_field identifier_field, label: 'Identifier'
        config.add_index_field bag_name_field, label: 'Bag Name'
        config.add_index_field 'system_modified_dtsi', label: 'Last Modified'
        config.add_index_field description_field, label: 'Description'
        config.add_index_field alt_identifier_field, label: 'Alternate Identifiers'

        config.add_search_field 'all_fields', :label => 'All Fields'

        config.add_search_field(identifier_field) do |field|
          field.label = "Object Identifier"
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
          field.solr_local_parameters = {
             :qf => title_field,
             :pf => '$title_pf'
          }
        end

        config.add_search_field(bag_name_field) do |field|
          field.label = "Bag Name"
          field.solr_local_parameters = {
              :qf => bag_name_field,
              :pf => '$bag_name_pf'
          }
        end

        config.add_search_field(alt_identifier_field) do |field|
          field.label = "Alternate Identifier"
          field.solr_local_parameters = {
              :qf => alt_identifier_field,
              :pf => '$alt_identifier_pf'
          }
        end

        config.add_search_field(gf_identifier_field) do |field|
          field.label = 'File Identifier'
          field.solr_local_parameters = {
              :qf => gf_identifier_field,
              :pf => '$gf_identifier_pf'
          }
        end

        config.add_sort_field 'score desc, system_create_dtsi desc, desc_metadata__title_si asc', :label => 'relevance'
        config.add_sort_field 'pub_date_dtsi desc, desc_metadata__title_si asc', :label => 'date added'
        config.add_sort_field 'system_modified_dtsi desc', :label => 'date changed'
        config.add_sort_field 'desc_metadata__title_si asc, system_create_dtsi desc', :label => 'title'

        # If there are more than this many search results, no spelling ("did you
        # mean") suggestion is offered.
        config.spell_max = 5
      end
    end
  end
end
