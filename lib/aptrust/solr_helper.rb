module Aptrust
  module SolrHelper
    def filter_on_institution(solr_parameters, user_parameters)
      if current_user and !current_user.is? :admin
        solr_parameters[:fq] ||= []
        solr_parameters[:fq] << "+#{Solrizer.solr_name("is_part_of", :symbol)}:\"info:fedora/#{current_user.institution.pid}\""
      end
    end
  end
end
