require 'spec_helper'

describe UsersController do
  describe "POST create" do
    before do
      @user = FactoryGirl.create(:user, :admin)
      sign_in(@user)
    end

    it "should reject no parameters" do
      expect {
        post :create, {}
      }.to_not change(User, :count)
    end

    it 'should accept good parameters' do
      expect {
        post :create, user: FactoryGirl.attributes_for(:user, :admin)
      }.to change(User, :count)
    end
  end
end