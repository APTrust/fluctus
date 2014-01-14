require 'spec_helper'

describe EventsHelper do

  let(:id) { '123' }
  let(:uri) { 'uri for file' }

  describe '#generic_file_link' do
    it 'returns a link for the GenericFile' do
      solr_doc = { 'generic_file_id_ssim' => [id],
                   'generic_file_uri_ssim' => [uri] }
      expected_result =  "<a href=\"/files/#{id}\">#{uri}</a>"
      helper.generic_file_link(solr_doc).should == expected_result
    end

    it "returns a link for the GenericFile, even if it doesn't know the uri" do
      solr_doc = { 'generic_file_id_ssim' => [id] }
      expected_result =  "<a href=\"/files/#{id}\">#{id}</a>"
      helper.generic_file_link(solr_doc).should == expected_result
    end
  end

  describe '#intellectual_object_link' do
    it 'returns a link for the IntellectualObject' do
      solr_doc = { 'intellectual_object_id_ssim' => [id] }
      expected_result =  "<a href=\"/objects/#{id}\">#{id}</a>"
      helper.intellectual_object_link(solr_doc).should == expected_result
    end
  end

  describe '#parent_object_link' do

    describe 'without enough info in the solr doc' do
      it 'it returns a string instead of a link' do
        helper.parent_object_link({}).should == 'Event'
      end
    end

    describe 'with info about a generic file' do
      let(:solr_doc) { { 'generic_file_id_ssim' => [id],
                         'generic_file_uri_ssim' => [uri] }
      }

      it 'returns a link to the generic file' do
        helper.should_receive(:generic_file_link).with(solr_doc)
        helper.parent_object_link(solr_doc)
      end
    end

    describe 'with info about an intellectual object' do
      let(:solr_doc) { { 'intellectual_object_id_ssim' => [id] } }
      it 'returns a link to the intellectual object' do
        helper.should_receive(:intellectual_object_link).with(solr_doc)
        helper.parent_object_link(solr_doc)
      end
    end

  end

end
