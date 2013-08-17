require 'spec_helper'

describe Users::OmniauthCallbacksController do
  
  describe "#registered user" do
    # context "when google email doesn't exist in the system" do
    #   before(:each) do
    #     stub_env_for_omniauth

    #     get :facebook
    #     @user = User.where(:email => "ghost@nobody.com").first
    #   end

    #   it { @user.should_not be_nil }

    #   it "should create authentication with facebook id" do
    #     authentication = @user.authentications.where(:provider => "facebook", :uid => "1234").first
    #     authentication.should_not be_nil
    #   end

    #   it { should be_user_signed_in }

    #   it { response.should redirect_to tasks_path }
    # end
    
    context "when capabpe of authenticating into the system" do
      before(:each) do
        stub_env_for_omniauth
        
        @user = FactoryGirl.create(:user, email: "john@company_name.com")
        sign_in(@user)

        get :google_oauth2
      end
      
      it { flash[:notice].should == (I18n.t "devise.omniauth_callbacks.success", :kind => "Google") }
      it { flash[:notice].should == "Successfully authenticated from Google account."}
      it { response.should redirect_to root_url }
    end
  end

  describe "unregistered user" do
    before(:each) do 
      stub_env_for_omniauth
      @user = User.new
      sign_in(@user)
      get :google_oauth2
    end

    it {flash[:error].should == "john@company_name.com is not authorized to access this application." }
    it {response.should redirect_to root_url}
  end
  
  # describe "#logged in user" do
  #   context "when user don't have facebook authentication" do
  #     before(:each) do
  #       stub_env_for_omniauth

  #       user = User.create!(:email => "user@example.com", :password => "my_secret")
  #       sign_in user

  #       get :facebook
  #     end

  #     it "should add facebook authentication to current user" do
  #       user = User.where(:email => "user@example.com").first
  #       user.should_not be_nil
  #       fb_authentication = user.authentications.where(:provider => "facebook").first
  #       fb_authentication.should_not be_nil
  #       fb_authentication.uid.should == "1234"
  #     end

  #     it { should be_user_signed_in }

  #     it { response.should redirect_to authentications_path }
      
  #     it { flash[:notice].should == "Facebook is connected with your account."}
  #   end
    
  #   context "when user already connect with facebook" do
  #     before(:each) do
  #       stub_env_for_omniauth
        
  #       user = User.create!(:email => "ghost@nobody.com", :password => "my_secret")
  #       user.authentications.create!(:provider => "facebook", :uid => "1234")
  #       sign_in user

  #       get :facebook
  #     end
      
  #     it "should not add new facebook authentication" do
  #       user = User.where(:email => "ghost@nobody.com").first
  #       user.should_not be_nil
  #       fb_authentications = user.authentications.where(:provider => "facebook")
  #       fb_authentications.count.should == 1
  #     end
      
  #     it { should be_user_signed_in }
      
  #     it { flash[:notice].should == "Signed in successfully." }
      
  #     it { response.should redirect_to tasks_path }
      
  #   end
  # end
  
end

def stub_env_for_omniauth
  request.env["devise.mapping"] = Devise.mappings[:user]
  request.env["omniauth.auth"] = OmniAuth.config.mock_auth[:google]
end