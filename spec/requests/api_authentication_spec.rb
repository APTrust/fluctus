require 'spec_helper'

describe 'API Authentication: Editing an Intellectual Object via API request' do
  let(:inst) { FactoryGirl.create :institution }

  let(:old_title) { 'Old Title' }
  let(:new_title) { 'New Title' }
  let(:obj) { FactoryGirl.create :intellectual_object, institution: inst, title: old_title }

  let(:update_fields) {
    { id: obj.id, intellectual_object: { title: new_title }}
  }
  let(:headers) {{ 'CONTENT_TYPE' => 'application/json', 'HTTP_ACCEPT' => 'application/json' }}

  let(:valid_key) { '123' }
  let(:invalid_key) { '456' }
  let(:user) { FactoryGirl.create :user, :institutional_admin, institution_pid: inst.pid, api_secret_key: valid_key }


  describe 'Valid login' do
    let(:login_params) {{ user: { email: user.email, api_secret_key: valid_key }}}

    it 'updates the object' do
      params = update_fields.merge(login_params).to_json
      response = patch(intellectual_object_path(obj), params, headers)
      response.should == 204
      obj.reload.title.should == new_title
    end
  end

  describe 'Log in with valid user, but invalid API key' do
    let(:login_params) {{ user: { email: user.email, api_secret_key: invalid_key }}}

    it 'fails to log in' do
      params = update_fields.merge(login_params).to_json
      response = patch(intellectual_object_path(obj), params, headers)
      response.should == 401
      obj.reload.title.should == old_title
    end
  end

  describe 'Log in with invalid user' do
    let(:login_params) {{ user: { email: 'not_a_user@example.com', api_secret_key: valid_key }}}

    it 'fails to log in' do
      params = update_fields.merge(login_params).to_json
      response = patch(intellectual_object_path(obj), params, headers)
      response.should == 401
      obj.reload.title.should == old_title
    end
  end

  describe 'A user without an API key' do
    let(:user_without_key) { FactoryGirl.create :user, :institutional_admin, institution_pid: inst.pid }
    let(:login_params) {{ user: { email: user_without_key.email, api_secret_key: nil }}}

    it 'cannot log in via API request' do
      params = update_fields.merge(login_params).to_json
      response = patch(intellectual_object_path(obj), params, headers)
      response.should == 401
      obj.reload.title.should == old_title
    end
  end

end