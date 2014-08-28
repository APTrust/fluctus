module ProcessedItemHelper

  def current_path(param, value)
    if request.fullpath.include? '?'
      path = "#{request.fullpath}&#{param}=#{value}"
    else
      path = "#{request.fullpath}?#{param}=#{value}"
    end
    if request.fullpath.include? 'search'
      unless request.fullpath.include? 'qq'
        path = "#{path}&search_field=#{params[:search_field]}&qq=#{params[:qq]}"
      end
    end
    path
  end
end
