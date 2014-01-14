module EventsHelper

  def parent_object_link(solr_doc)
    if solr_doc['generic_file_id_ssim']
      generic_file_link(solr_doc)
    elsif solr_doc['intellectual_object_id_ssim']
      intellectual_object_link(solr_doc)
    else
      "Event"
    end
  end

  def generic_file_link(solr_doc)
    uri = Array(solr_doc['generic_file_uri_ssim']).first
    id  = Array(solr_doc['generic_file_id_ssim']).first
    link_name = uri ? uri : id
    link_to link_name, generic_file_path(id)
  end

  def intellectual_object_link(solr_doc)
    id  = Array(solr_doc['intellectual_object_id_ssim']).first
    link_to id, intellectual_object_path(id)
  end

end
