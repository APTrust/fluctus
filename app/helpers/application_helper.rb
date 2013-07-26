module ApplicationHelper
  def show_link(object, content = nil, options={})
    content ||= "View"
    options[:class] = 'btn btn-primary' if options[:class].nil?
    link_to(content, object, options) if can?(:read, object)
  end

  def edit_link(object, content = nil, options={})
    content ||= "Edit"
    options[:class] = 'btn btn-warning' if options[:class].nil?
    link_to(content, [:edit, object], options) if can?(:update, object)
  end

  def destroy_link(object, content = nil, options={})
    content ||= "Delete"
    options[:class] = 'btn btn-danger' if options[:class].nil?
    options[:method] = :delete if options[:method].nil?
    options[:confirm] = "Are you sure?" if options[:confirm].nil?
    link_to(content, object, options) if can?(:destroy, object)
  end

  def create_link(object, content = nil, options={})
    content ||= "Create"
    options[:class] = 'btn btn-info' if options[:class].nil?
    if can?(:create, object)
      object_class = (object.kind_of?(Class) ? object : object.class)
      link_to(content, [:new, object_class.name.underscore.to_sym], options)
    end
  end
end
