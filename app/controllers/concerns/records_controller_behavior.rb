module RecordsControllerBehavior
  extend ActiveSupport::Concern

  included do
    #load_resource only: [:new, :edit, :update, :create], instance_name: resource_instance_name

    rescue_from HydraEditor::InvalidType do
      render 'records/choose_type'
    end
    helper_method :resource
  end

  module ClassMethods
    #def cancan_resource_class
      #HydraEditor::ControllerResource
    #end
    def resource_instance_name
      name.sub("Controller", "").underscore.split('/').last.singularize
    end
  end

  def new
    initialize_fields
    render 'records/new'
  end

  def edit
    initialize_fields
    render 'records/edit'
  end

  def create
    set_attributes

    respond_to do |format|
      if resource.save
        format.html { redirect_to redirect_after_create, notice: 'Object was successfully created.' }
        format.json { render json: object_as_json, status: :created, location: redirect_after_create }
      else
        format.html { render 'records/new' }
        format.json { render json: resource.errors, status: :unprocessable_entity }
      end
    end

  end

  def update
    set_attributes
    respond_to do |format|
      if resource.save
        format.html { redirect_to redirect_after_update, notice: 'Object was successfully updated.' }
        # Passenger bug. Until we can upgrade, don't return :no_content.
        # https://github.com/phusion/passenger/issues/1595
        format.json { render json: object_as_json, status: :ok }
      else
        format.html { render 'records/edit' }
        format.json { render json: resource.errors, status: :unprocessable_entity }
      end
    end
  end

  protected

  def object_as_json
    # ActiveFedora::Base#to_json causes a circular reference (before 7.0).  Do something easy
    resource.terms_for_editing.each_with_object({}) { |term, h|  h[term] = resource[term] }
  end

  # Override this method if you want to set different metadata on the object
  def set_attributes
    resource.attributes = collect_form_attributes
  end

  def collect_form_attributes
    raw_attributes = params[ActiveModel::Naming.singular(resource)]
    # we could probably do this with strong parameters if the gemspec depends on Rails 4+
    permitted_attributes = resource.terms_for_editing.each_with_object({}) { |key, attrs| attrs[key] = raw_attributes[key] if raw_attributes[key] }
    # removes attributes that were only changed by initialize_fields
    permitted_attributes.reject { |key, value| resource[key].empty? and value == [""] }
  end

  # Override to redirect to an alternate location after create
  def redirect_after_create
    main_app.catalog_path resource
  end

  # Override to redirect to an alternate location after update
  def redirect_after_update
    main_app.catalog_path resource
  end

  def has_valid_type?
    HydraEditor.models.include? params[:type]
  end

  def initialize_fields
    resource.terms_for_editing.each do |key|
      # if value is empty, we create an one element array to loop over for output
      resource[key] = [''] if resource[key].empty?
    end
  end

  def resource
    get_resource_ivar
  end

  # Get resource ivar based on the current resource controller.
  #
  def get_resource_ivar #:nodoc:
    instance_variable_get("@#{resource_instance_name}")
  end

  def resource_instance_name
    self.class.resource_instance_name
  end

end
