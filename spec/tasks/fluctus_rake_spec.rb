require 'spec_helper'
require 'rake'

#Attempt here to create a test for the modified populate_db rake test. So far unsuccessful, commented
#out so I can come back to it later / so it won't break anything else in the application
describe 'fluctus' do
  #before do
  #  @rake = Rake::Application.new
  #  Rake.application = @rake
  #  Rake.application.rake_require 'lib/tasks/fluctus'
  #  Rake::Task.define_task(:environment)
  #end
  #
  #describe 'fluctus:populate_db' do
  #  let :run_rake_task do
  #    Rake::Task['fluctus:populate_db'].reenable
  #  end
  #
  #  it 'should accept parameters' do
  #    @rake['fluctus:populate_db'].invoke('1','1','1')
  #    intobjs = IntellectualObject.all
  #    intobjs.count.should == 1
  #  end
  #
  #end
end