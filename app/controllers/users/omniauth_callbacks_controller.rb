class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController

  #def google_oauth2
  #  # You need to implement the method below in your model (e.g. app/models/user.rb)
  #  @user = User.find_for_google_oauth2(request.env["omniauth.auth"], current_user)
  #
  #  if @user.persisted?
  #    flash[:notice] = I18n.t "devise.omniauth_callbacks.success", :kind => "Google"
  #    sign_in_and_redirect @user, :event => :authentication
  #  else
  #    data = request.env["omniauth.auth"].info
  #    # session["devise.google_data"] = request.env["omniauth.auth"]
  #    # redirect_to new_user_registration_url
  #    redirect_to root_path, :flash => { :error => "#{data[:email]} is not authorized to access this application." }
  #  end
  #end
end