module Aptrust
  module SolrHelper

    def clean_for_solr(myString)
      if myString.nil?
        return nil
      else
        cleanString = myString.gsub(/:/,"_")
      end
    end
  end
end
