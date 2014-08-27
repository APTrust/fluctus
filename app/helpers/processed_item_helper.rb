module ProcessedItemHelper

  def current_path(param, value)
      if request.fullpath.include? '?'
        path = "#{request.fullpath}&#{param}=#{value}"
      else
        path = "#{request.fullpath}?#{param}=#{value}"
      end
  end
end
