require_relative '../../../spec_helper.rb'

require 'kitchen/provisioner/puppet/librarian'

describe Kitchen::Provisioner::Puppet::Librarian do
  let(:puppetfile)  { 'TestPuppetfile' }
  let(:path)  { 'Path'}
  let(:librarian) { Kitchen::Provisioner::Puppet::Librarian.new(puppetfile, path)}

  context 'defaults' do

    it 'should initialize with correct default variables' do
      expect(librarian.puppetfile).to eq('TestPuppetfile')
      expect(librarian.path).to eq('Path')
      expect(librarian.logger).to eq(Kitchen.logger)
    end
  end
end
