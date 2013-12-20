module Aptrust
  module SolrHelper
    def clean_for_solr(myString)
      myString.gsub(/:/,"_")
    end
  end
end
