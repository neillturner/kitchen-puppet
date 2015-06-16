# encoding: utf-8
require_relative '../../spec_helper.rb'

require 'kitchen/provisioner/puppet_apply'
require 'kitchen/transport/dummy'
require 'kitchen/verifier/dummy'
require 'kitchen/driver/dummy'

describe Kitchen::Provisioner::PuppetApply do
  let(:logged_output) { StringIO.new }
  let(:logger)        { Logger.new(logged_output) }
  let(:config)        { { test_base_path: '/kitchen' } }
  let(:platform)      { Kitchen::Platform.new(name: 'fooos-99') }
  let(:suite)         { Kitchen::Suite.new(name: 'suitey') }
  let(:verifier)      { Kitchen::Verifier::Dummy.new }
  let(:transport)     { Kitchen::Transport::Dummy.new }
  let(:state_file)    { double('state_file') }
  let(:state)         { Hash.new }
  let(:env)           { Hash.new }
  let(:driver) { Kitchen::Driver::Dummy.new }

  let(:provisioner_object) { Kitchen::Provisioner::PuppetApply.new(config) }

  # Create Provisioner With Config
  let(:provisioner) do
    p = provisioner_object
    instance
    p
  end

  # Create new Kitchen Instance
  let(:instance) do
    Kitchen::Instance.new(
      verifier: verifier,
      driver: driver,
      logger: logger,
      suite: suite,
      platform: platform,
      provisioner: provisioner_object,
      transport: transport,
      state_file: state_file
    )
  end

  # Test Puppet Apply Config
  describe 'config' do
    context 'defaults' do
      it 'Should have nil Puppet Version' do
        expect(provisioner[:puppet_version]).to eq(nil)
      end

      it 'Should have nil facter version' do
        expect(provisioner[:facter_version]).to eq(nil)
      end

      it 'Should have nil hiera version' do
        expect(provisioner[:hiera_version]).to eq(nil)
      end

      it 'should not include puppet collections' do
        expect(provisioner[:require_puppet_collections]).to eq(false)
      end

      it 'should set yum collections repo' do
        expect(provisioner[:puppet_yum_collections_repo]).to eq('http://yum.puppetlabs.com/puppetlabs-release-pc1-el-6.noarch.rpm')
      end

      it 'should set apt collections repo' do
        expect(provisioner[:puppet_apt_collections_repo]).to eq('http://apt.puppetlabs.com/puppetlabs-release-pc1-wheezy.deb')
      end

      it 'should set puppet collections remote path' do
        expect(provisioner[:puppet_coll_remote_path]).to eq('/opt/puppetlabs')
      end

      it 'Should require Puppet Repo' do
        expect(provisioner[:require_puppet_repo]).to eq(true)
      end

      it 'Should require Chef for Busser' do
        expect(provisioner[:require_chef_for_busser]).to eq(true)
      end

      it 'Should resolve with librarian' do
        expect(provisioner[:resolve_with_librarian_puppet]).to eq(true)
      end

      it 'Should set puppet environment to nil' do
        expect(provisioner[:puppet_environment]).to eq(nil)
      end

      it 'Should not install custom facts' do
        expect(provisioner[:install_custom_facts]).to eq(false)
      end

      it 'Should set correct apt repo' do
        expect(provisioner[:puppet_apt_repo]).to eq('http://apt.puppetlabs.com/puppetlabs-release-precise.deb')
      end

      it 'Should set correct yum repo' do
        expect(provisioner[:puppet_yum_repo]).to eq('https://yum.puppetlabs.com/puppetlabs-release-el-6.noarch.rpm')
      end

      it 'Should set correct chef bootstrap url' do
        expect(provisioner[:chef_bootstrap_url]).to eq('https://www.getchef.com/chef/install.sh')
      end

      it 'Should set nil puppet log destination' do
        expect(provisioner[:puppet_logdest]).to eq(nil)
      end

      it 'Should set nil puppet apply command' do
        expect(provisioner[:puppet_apply_command]).to eq(nil)
      end

      it 'should set git init to nil' do
        expect(provisioner[:puppet_git_init]).to eq(nil)
      end

      it 'should set git pr to nil' do
        expect(provisioner[:puppet_git_pr]).to eq(nil)
      end

      it 'Should set nil for http proxy' do
        expect(provisioner[:http_proxy]).to eq(nil)
      end

      it 'Should set sane hiera remote data path' do
        expect(provisioner[:hiera_data_remote_path]).to eq('/var/lib/hiera')
      end

      it 'Should set site.pp as default manifest' do
        expect(provisioner[:manifest]).to eq('site.pp')
      end

      it 'Should fail to find mainfests path' do
        expect(provisioner[:manifests_path]).to eq(nil)
      end

      it 'Should find files path' do
        expect(provisioner[:files_path]).to eq('files')
      end

      it 'Should fail to find hiera data path' do
        expect(provisioner[:hiera_data_path]).to eq(nil)
      end

      it 'Should fail to find puppet config path' do
        expect(provisioner[:puppet_config_path]).to eq(nil)
      end

      it 'Should fail to find hiera config path' do
        expect(provisioner[:hiera_config_path]).to eq(nil)
      end

      it 'Should fail to find fileserver config path' do
        expect(provisioner[:fileserver_config_path]).to eq(nil)
      end

      it 'Should fail to find puppetfile path' do
        expect(provisioner[:puppetfile_path]).to eq(nil)
      end

      it 'Should fail to find modulefile path' do
        expect(provisioner[:modulefile_path]).to eq(nil)
      end

      it 'Should fail to find metadata_json_path' do
        expect(provisioner[:metadata_json_path]).to eq(nil)
      end

      it 'Should fail to find manifests path' do
        expect(provisioner[:manifests_path]).to eq(nil)
      end

      it 'Should set Puppet Debug to False' do
        expect(provisioner[:puppet_debug]).to eq(false)
      end

      it 'Should set puppet verbose to false' do
        expect(provisioner[:puppet_verbose]).to eq(false)
      end

      it 'should set puppet noop to false' do
        expect(provisioner[:puppet_noop]).to eq(false)
      end

      it "should set puppet platform to ''" do
        expect(provisioner[:puppet_platform]).to eq('')
      end

      it 'should update package repos' do
        expect(provisioner[:update_package_repos]).to eq(true)
      end

      it 'should not remove puppet repo' do
        expect(provisioner[:remove_puppet_repo]).to eq(false)
      end

      it 'should set custom facts to empty hash' do
        expect(provisioner[:custom_facts]).to eq({})
      end

      it 'should not use detailed exit codes' do
        expect(provisioner[:puppet_detailed_exitcodes]).to eq(nil)
      end

      it 'should set facter file to nil' do
        expect(provisioner[:facter_file]).to eq(nil)
      end

      it 'should not use librarian ssl file' do
        expect(provisioner[:librarian_puppet_ssl_file]).to eq(nil)
      end

      it 'should not use hiera eyaml' do
        expect(provisioner[:hiera_eyaml]).to eq(false)
      end

      it 'should set hiera eyaml remote path' do
        expect(provisioner[:hiera_eyaml_key_remote_path]).to eq('/etc/puppet/secure/keys')
      end

      it 'should not find hiera eyaml key path' do
        expect(provisioner[:hiera_eyaml_key_path]).to eq(nil)
      end

      it 'should set hiera deep merge to false' do
        expect(provisioner[:hiera_deep_merge]).to eq(false)
      end
    end

    # Test Puppet Version
    it 'Sets Puppet Version to 3.5.1' do
      config[:puppet_version] = '3.5.1'
      expect(provisioner[:puppet_version]).to eq('3.5.1')
    end

    # Test Facter Version
    it 'Sets Facter Version to 2.4.3' do
      config[:facter_version] = '2.4.3'
      expect(provisioner[:facter_version]).to eq('2.4.3')
    end

    # Test Hiera Version
    it 'Sets Hiera Version to 2.0.1' do
      config[:hiera_version] = '2.0.1'
      expect(provisioner[:hiera_version]).to eq('2.0.1')
    end
  end
end
