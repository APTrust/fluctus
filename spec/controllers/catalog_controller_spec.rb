require 'spec_helper'

describe CatalogController do 
  render_views

  describe "GET #index" do
    before(:all) do 
      @user = User.new
    end

    describe 'for all users' do
      it 'should have link called Google Login' do

      end

      it 'should have APTrust footer information' do 

      end

      it 'should return unauthorized login message' do
        get :index
        sign_in @user
        # response.should contain('not authorized to access this application')
        response.body.should have_content("Hello world")
      end
    end

    describe 'for unauthenticated users' do 

    end

    describe 'for authenticated' do
      describe 'admin users' do 

      end
      describe 'institutional_admin users' do 

      end
      describe 'institutional_user users' do 

      end
    end
  end
end