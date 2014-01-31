module IntellectualObjectsHelper
  def format_display(format)
    format == 'all' ? 'Total content upload' : format
  end

  def format_class(format)
    format.split('/')[-1].downcase.gsub(/\s/, '_') + "_label"
  end
end
