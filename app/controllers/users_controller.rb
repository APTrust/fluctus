class UsersController < ApplicationController
  load_and_authorize_resource
  before_filter :authenticate_user!
  before_action :set_user, only: [:show, :edit, :update, :destroy]

  # DELETE /Users/1
  # DELETE /Users/1.json
  def destroy
    name = @user.to_s
    destroy!(notice: "User #{@user.to_s} was deleted.")
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_user
      @user = User.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def user_params
      params[:user].permit(:name, :institution_pid, :email, :phone_number, {role_ids: []})
    end
end
