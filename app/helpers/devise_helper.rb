module DeviseHelper
  def devise_error_messages!
    return "" if resource.errors.empty?

    messages = resource.errors.full_messages.map { |msg| content_tag(:li, msg) }.join

    html = <<-HTML
    <br/>
    <div id="error_explanation">
      <div class="alert alert-error">Please review the problems below:</div>
      <div class="controls help-inline">
           <ul>

           </ul>
      </div>
    </div>
    HTML

    html.html_safe
  end

  def devise_error_messages?
    resource.errors.empty? ? false : true
  end

end