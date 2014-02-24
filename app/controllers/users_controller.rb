class UsersController < ApplicationController
  inherit_resources
  load_and_authorize_resource
  before_filter :authenticate_user!

  def destroy
    name = @user.to_s
    destroy!(notice: "User #{@user.to_s} was deleted.")
  end

  def edit_password
    @user = current_user
  end

  def update_password
    @user = User.find(current_user.id)
    if @user.update_with_password(user_params)
      sign_in @user, :bypass => true
      redirect_to root_path
      flash[:notice] = "Successfully changed password."
    else
      redirect_to root_path
      flash[:alert] = "Current password was incorrect, or passwords did not match. Password has not been changed."
    end
  end

  private

    def build_resource_params
      [params.fetch(:user, {}).permit(:name, :email, :phone_number, :password, :password_confirmation).tap do |p|
        p[:institution_pid] = build_institution_pid if params[:user][:institution_pid]
        p[:role_ids] = build_role_ids if params[:user][:role_ids]
      end]
    end

    def build_institution_pid
      institution = Institution.find(params[:user][:institution_pid])
      authorize!(:add_user, institution)
      institution.id
    end

    def build_role_ids
      [].tap do |role_ids|
        roles = Role.find(params[:user][:role_ids].reject &:blank?)
        roles.each do |role|
          authorize!(:add_user, role)
          role_ids << role.id
        end
      end
    end

  def user_params
    params.required(:user).permit(:password, :password_confirmation, :current_password)
  end

end
