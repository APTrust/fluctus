class EventSolrDoc
  include ActiveModel::Conversion

  def to_partial_path
    File.join('events', 'event')
  end

end
