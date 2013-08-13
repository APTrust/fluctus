class InstitutionsController < ApplicationController
  load_and_authorize_resource
  before_filter :authenticate_user!
  before_action :set_institution, only: [:show, :edit, :update, :destroy]

  # GET /institutions
  # GET /institutions.json
  def index
    @institutions = Institution.all
  end

  # GET /institutions/1
  # GET /institutions/1.json
  #
  # Return the most recent 50 Description Objects uploaded by an instituion.
  def show
    @description_objects = DescriptionObject.where(is_part_of_ssim: "info:fedora/#{@institution.pid}").limit(50).to_a
  end

  # GET /institutions/new
  def new
    @institution = Institution.new
  end

  # GET /institutions/1/edit
  def edit
  end

  # POST /institutions
  # POST /institutions.json
  def create
    @institution = Institution.new(institution_params)

    respond_to do |format|
      if @institution.save
        format.html { redirect_to @institution, notice: 'Institution was successfully created.' }
        format.json { render action: 'show', status: :created, location: @institution }
      else
        format.html { render action: 'new' }
        format.json { render json: @institution.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /institutions/1
  # PATCH/PUT /institutions/1.json
  def update
    respond_to do |format|
      if @institution.update_attributes(institution_params)
        format.html { redirect_to @institution, notice: 'Institution was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @institution.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /institutions/1
  # DELETE /institutions/1.json
  def destroy
    name = @institution.name
    respond_to do |format|
      if @institution.destroy
        format.html { redirect_to institutions_url, notice: "#{name} was successfully destroyed." }
        format.json { head :no_content }
      else
        format.html { redirect_to institutions_url, flash: {error: @institution.errors[:base].join("<br/>").html_safe }}
        format.json { render json: @institution.errors, status: :unprocessable_entity }
      end
    end
  end

  private
    # If an id is passed through params, use it.  Otherwise default to show a current user's institution.
    def set_institution
      @institution = params[:id].nil? ? Institution.find(current_user.institution_pid) : Institution.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def institution_params
      params.require(:institution).permit(:name)
    end
end
