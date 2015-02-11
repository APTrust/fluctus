require 'spec_helper'

describe IoAggregation do
  it 'should properly set a file count' do
    subject.file_count = 2
    subject.file_count.should == 2
  end

  it 'should properly set a file size' do
    subject.file_size = 75
    subject.file_size.should == 75
  end

  it 'should properly set a file_format' do
    subject.file_format = 'application/pdf'
    subject.file_format.should == 'application/pdf'
  end

  it 'should properly set an identifier' do
    subject.identifier = 'test.edu/1234567890'
    subject.identifier.should == 'test.edu/1234567890'
  end

  it '#add_format should properly add a format' do
    new_format = 'video/mp4'
    subject.add_format(new_format)
    subject.file_format.should == 'video/mp4'
  end

  it '#change_format should properly change a format' do
    subject.file_format = 'application/pdf,video/mp4'
    gf = FactoryGirl.create(:generic_file, file_format: 'video/mp4')
    params = {file_format: 'audio/wav'}
    file = [gf, params]
    subject.change_format(file)
    subject.file_format.should == 'application/pdf,audio/wav'
  end

  it '#remove_format should properly remove a format' do
    subject.file_format = 'application/pdf,audio/wav'
    format = 'application/pdf'
    subject.remove_format(format)
    subject.file_format.should == 'audio/wav'
  end

  it '#add_to_count should properly add to the count' do
    subject.file_count = 1
    subject.add_to_count
    subject.file_count.should == 2
  end

  it '#remove_from_count should properly remove from the count' do
    subject.file_count = 1
    subject.remove_from_count
    subject.file_count.should == 0
  end

  it '#add_to_size should properly add to the file size' do
    subject.file_size = 100.0
    subject.add_to_size(25.0)
    subject.file_size.should == 125.0
  end

  it '#change_size should properly change the file size' do
    subject.file_size = 100.0
    gf = FactoryGirl.create(:generic_file, file_size: 25)
    params = {file_size: 30}
    file = [gf, params]
    subject.change_size(file)
    subject.file_size.should == 105.0
  end

  it '#remove_from_size should properly remove from the file size' do
    subject.file_size = 100.0
    subject.remove_from_size(25.0)
    subject.file_size.should == 75.0
  end

  it '#format_to_map should properly convert the file_format attribute into a mpa' do
    subject.file_format = 'application/pdf,audio/wav,video/mp4,application/pdf'
    map = subject.format_to_map
    map.should == {'application/pdf' => 2, 'audio/wav' => 1, 'video/mp4' => 1}
  end

  it '#initialize_object should properly initialize an object' do
    subject.initialize_object('test.edu/123')
    subject.file_size.should == 0
    subject.file_count.should == 0
    subject.file_format.should == ''
    subject.identifier.should == 'test.edu/123'
  end

  it '#update_aggregations should properly add a new file to the aggregations' do
    io = FactoryGirl.create(:intellectual_object)
    subject.initialize_object(io.id)
    file = FactoryGirl.create(:generic_file, file_size: 100, file_format: 'application/pdf')
    subject.update_aggregations('add', file)
    subject.file_count.should == 1
    subject.file_size.should == 100
    subject.file_format.should == 'application/pdf'
  end

  it '#update_aggregations should properly change a file in the aggregations' do
    io = FactoryGirl.create(:intellectual_object)
    subject.identifier = io.id
    subject.file_count = 3
    subject.file_size = 194
    subject.file_format = 'application/pdf,audio/wav,video/mp4'
    gf = FactoryGirl.create(:generic_file, file_size: 100, file_format: 'application/pdf')
    params = {file_format: 'application/txt', file_size: 68}
    file = [gf, params]
    subject.update_aggregations('update', file)
    subject.file_count.should == 3
    subject.file_size.should == 162
    subject.file_format.should == 'audio/wav,video/mp4,application/txt'
  end

  it '#update_aggregations should properly remove a file from the aggregations' do
    io = FactoryGirl.create(:intellectual_object)
    subject.identifier = io.id
    subject.file_count = 3
    subject.file_size = 194
    subject.file_format = 'application/pdf,audio/wav,video/mp4'
    gf = FactoryGirl.create(:generic_file, file_size: 100, file_format: 'application/pdf')
    subject.update_aggregations('delete', gf)
    subject.file_count.should == 2
    subject.file_size.should == 94
    subject.file_format.should == 'audio/wav,video/mp4'
  end

end

