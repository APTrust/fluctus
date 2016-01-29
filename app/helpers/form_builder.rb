class StandardBuilder < ActionView::Helpers::FormBuilder
  def error_messages
    return unless object.respond_to?(:errors) && object.errors.any?

    errors_list = ''
    errors_list << @template.content_tag(:span, 'There are errors!', :class => 'title-error')
    errors_list << object.errors.full_messages.map { |message| @template.content_tag(:li, message) }.join("\n")

    @template.content_tag(:ul, errors_list.html_safe, :class => 'error-recap round-border')
  end
end