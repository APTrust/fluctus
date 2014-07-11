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
    id  = Array(solr_doc['generic_file_id_ssim']).first
    gf = GenericFile.find(id)
    identifier = gf.identifier
    link_name = identifier ? identifier : id
    link_to link_name, generic_file_path(id)
  end

  def intellectual_object_link(solr_doc)
    id  = Array(solr_doc['intellectual_object_id_ssim']).first
    io = IntellectualObject.find(id)
    identifier = io.identifier
    link_name = identifier ? identifier : id
    link_to link_name, intellectual_object_path(id)
  end

  def display_event_outcome(solr_doc)
    Array(solr_doc['event_outcome_ssim']).first
  end

  def event_catalog_title
    if @parent_object && @parent_object.respond_to?(:title)
      "Events for #{@parent_object.title}"
    elsif @institution
      "Events for #{@institution.name}"
    else
      "Events"
    end
  end

end
