module ApplicationHelper
  def show_link(object, content = nil, options={})
    content ||= '<i class="glyphicon glyphicon-eye-open"></i> <strong>View</strong>'
    options[:class] = 'btn doc-action-btn' if options[:class].nil?
    link_to(content.html_safe, object, options) if can?(:read, object)
  end

  def edit_link(object, content = nil, options={})
    content ||= '<i class="glyphicon glyphicon-edit"></i> <strong>Edit</strong>'
    options[:class] = 'btn doc-action-btn' if options[:class].nil?
    link_to(content.html_safe, [:edit, object], options) if can?(:update, object)
  end

  def destroy_link(object, content = nil, options={})
    content ||= '<i class="glyphicon glyphicon-trash"></i> <strong>Delete</strong>'
    options[:class] = 'btn doc-action-btn btn-danger' if options[:class].nil?
    options[:method] = :delete if options[:method].nil?
    options[:data] = { confirm: 'Are you sure?' }if options[:confirm].nil?
    link_to(content.html_safe, object, options) if can?(:destroy, object)
  end

  def create_link(object, content = nil, options={})
    content ||= '<i class="glyphicon glyphicon-plus"></i> <strong>Create</strong>'
    options[:class] = 'btn doc-action-btn' if options[:class].nil?
    if can?(:create, object)
      object_class = (object.kind_of?(Class) ? object : object.class)
      link_to(content.html_safe, [:new, object_class.name.underscore.to_sym], options)
    end
  end

  def header_title
    # TODO put base_title into an ENV
    base_title = "APTrust"
  end

  def full_title(page_title)
    # TODO put the base_title into an ENV
    base_title = "APTrust"
    if page_title.empty?
      base_title
    else
      "#{page_title} | #{base_title}"
    end
  end

  def format_boolean_as_yes_no(boolean)
    if boolean == 'true'
      return 'Yes'
    else
      return 'No'
    end
  end

  def display_version
    return '' if Rails.env.production?
    app_version = Fluctus::Application::VERSION
    return "Running Fluctus ver #{app_version} on Rails #{Rails.version} under Ruby #{RUBY_VERSION}"
  end

end
