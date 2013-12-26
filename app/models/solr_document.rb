# -*- encoding : utf-8 -*-
class SolrDocument 

  include Blacklight::Solr::Document

  # self.unique_key = 'id'
  
  ##
  # Offer the source (ActiveFedora-based) model to Rails for some of the
  # Rails methods (e.g. link_to).
  # @example
  #   link_to '...', SolrDocument(:id => 'bXXXXXX5').new => <a href="/dams_object/bXXXXXX5">...</a>
  def to_model
    m = ActiveFedora::Base.load_instance_from_solr(id, self)
    m.class == ActiveFedora::Base ? self : m
  end
  
end
