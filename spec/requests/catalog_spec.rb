require 'spec_helper'

describe "Catalog" do 
  describe "GET #index", :type => :feature do
    before(:each) do 
      visit('/')
    end

    describe 'for all users' do
      it 'should have link called Google Login' do
        expect(page).to have_link 'Google Login'
      end

      it 'should have APTrust footer information' do 
        expect(page).to have_content '© 2013 Academic Preservation Trust'
      end
    end

    describe 'for unauthenticated users' do 
      it 'should return unauthorized login message' do
        click_link('Google Login')
        expect(page).to have_content 'not authorized to access this application'
      end
    end

    describe 'for authenticated' do
      describe 'admin users' do
        before(:all) do
          @user = FactoryGirl.create(:user, :admin)
          login_as(@user)
        end

        it 'should have admin dropdown' do
          login_as(@user)
          expect(page).to have_content('Admin')
        end

        it 'should present the users name' do 
          login_as(@user)
          expect(page).to have_content("#{@user.name}")
        end
      end

      describe 'institutional_admin users' do 
        before(:all) do 
          @user = FactoryGirl.create(:aptrust_user, :institutional_admin)
          login_as(@user)
        end

        it 'should have admin dropdown' do
          login_as(@user)
          expect(page).to have_content('Admin')
        end

        it 'should present the users name' do 
          login_as(@user)
          expect(page).to have_content("#{@user.name}")
        end
      end

      describe 'institutional_user users' do 
        before(:all) do 
          @user = FactoryGirl.create(:aptrust_user, :institutional_user)
          login_as(@user)
        end

        it 'should have not admin dropdown' do
          login_as(@user)
          expect(page).to_not have_content('Admin')
        end

        it 'should present the users name' do 
          login_as(@user)
          expect(page).to have_content("#{@user.name}")
        end
      end
    end
  end
end