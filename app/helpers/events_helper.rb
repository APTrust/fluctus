module EventsHelper

  def parent_object_link(solr_doc)
    if solr_doc['generic_file_id_ssim']
      generic_file_link(solr_doc['generic_file_id_ssim'].first)
    elsif solr_doc['intellectual_object_id_ssim']
      intellectual_object_link(solr_doc['intellectual_object_id_ssim'].first)
    else
      "Event"
    end
  end

  def generic_file_link(id)
    link_to id, generic_file_path(id)
  end

  def intellectual_object_link(id)
    link_to id, intellectual_object_path(id)
  end

end
