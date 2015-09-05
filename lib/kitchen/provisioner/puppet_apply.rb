# -*- encoding: utf-8 -*-
#
# Author:: Chris Lundquist (<chris.lundquist@github.com>) Neill Turner (<neillwturner@gmail.com>)
#
# Copyright (C) 2013,2014 Chris Lundquist, Neill Turner
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# See https://github.com/neillturner/kitchen-puppet/blob/master/provisioner_options.md
# for documentation configuration parameters with puppet_apply provisioner.
#

require 'uri'
require 'json'
require 'kitchen'
require 'kitchen/provisioner/puppet/librarian'

module Kitchen
  class Busser
    def non_suite_dirs
      %w(data data_bags environments nodes roles puppet)
    end
  end

  module Configurable
    def platform_name
      instance.platform.name
    end
  end

  module Provisioner
    #
    # Puppet Apply provisioner.
    #
    class PuppetApply < Base
      attr_accessor :tmp_dir

      default_config :require_puppet_collections, false
      default_config :puppet_yum_collections_repo, 'http://yum.puppetlabs.com/puppetlabs-release-pc1-el-6.noarch.rpm'
      default_config :puppet_apt_collections_repo, 'http://apt.puppetlabs.com/puppetlabs-release-pc1-wheezy.deb'
      default_config :puppet_coll_remote_path, '/opt/puppetlabs'
      default_config :puppet_version, nil
      default_config :facter_version, nil
      default_config :hiera_version, nil
      default_config :install_hiera, false
      default_config :require_puppet_repo, true
      default_config :require_chef_for_busser, true
      default_config :resolve_with_librarian_puppet, true
      default_config :puppet_environment, nil
      default_config :install_custom_facts, false
      default_config :puppet_apt_repo, 'http://apt.puppetlabs.com/puppetlabs-release-precise.deb'
      default_config :puppet_yum_repo, 'https://yum.puppetlabs.com/puppetlabs-release-el-6.noarch.rpm'
      default_config :chef_bootstrap_url, 'https://www.getchef.com/chef/install.sh'
      default_config :puppet_logdest, nil
      default_config :custom_install_command, nil

      default_config :puppet_apply_command, nil

      default_config :puppet_git_init, nil
      default_config :puppet_git_pr, nil

      default_config :http_proxy, nil
      default_config :https_proxy, nil

      default_config :hiera_data_remote_path, '/var/lib/hiera'
      default_config :manifest, 'site.pp'

      default_config :manifests_path do |provisioner|
        provisioner.calculate_path('manifests') ||
          fail('No manifests_path detected. Please specify one in .kitchen.yml')
      end

      default_config :modules_path do |provisioner|
        modules_path = provisioner.calculate_path('modules')
        if modules_path.nil? && provisioner.calculate_path('Puppetfile', :file).nil?
          fail 'No modules_path detected. Please specify one in .kitchen.yml'
        end
        modules_path
      end

      default_config :files_path do |provisioner|
        provisioner.calculate_path('files') || 'files'
      end

      default_config :hiera_data_path do |provisioner|
        provisioner.calculate_path('hiera')
      end

      default_config :puppet_config_path do |provisioner|
        provisioner.calculate_path('puppet.conf', :file)
      end

      default_config :hiera_config_path do |provisioner|
        provisioner.calculate_path('hiera.yaml', :file)
      end

      default_config :fileserver_config_path do |provisioner|
        provisioner.calculate_path('fileserver.conf', :file)
      end
      default_config :puppetfile_path do |provisioner|
        provisioner.calculate_path('Puppetfile', :file)
      end

      default_config :modulefile_path do |provisioner|
        provisioner.calculate_path('Modulefile', :file)
      end

      default_config :metadata_json_path do |provisioner|
        provisioner.calculate_path('metadata.json', :file)
      end

      default_config :manifests_path do |provisioner|
        provisioner.calculate_path('manifests', :directory)
      end

      default_config :spec_files_path do |provisioner|
        provisioner.calculate_path('spec', :directory)
      end

      default_config :spec_files_remote_path, '/etc/puppet/spec'

      default_config :puppet_debug, false
      default_config :puppet_verbose, false
      default_config :puppet_noop, false
      default_config :platform do |provisioner|
        provisioner.platform_name()
      end
      default_config :update_package_repos, true
      default_config :remove_puppet_repo, false
      default_config :custom_facts, {}
      default_config :facterlib, nil
      default_config :puppet_detailed_exitcodes, nil
      default_config :facter_file, nil
      default_config :librarian_puppet_ssl_file, nil

      default_config :hiera_eyaml, false
      default_config :hiera_eyaml_key_remote_path, '/etc/puppet/secure/keys'

      default_config :hiera_eyaml_key_path do |provisioner|
        provisioner.calculate_path('hiera_keys')
      end

      default_config :hiera_deep_merge, false

      def calculate_path(path, type = :directory)
        base = config[:test_base_path]
        candidates = []
        candidates << File.join(base, instance.suite.name, 'puppet', path)
        candidates << File.join(base, instance.suite.name, path)
        candidates << File.join(base, path)
        candidates << File.join(Dir.pwd, path)

        candidates.find do |c|
          type == :directory ? File.directory?(c) : File.file?(c)
        end
      end

      # TODO: refactor for smaller cyclomatic complexity and perceived complexity
      # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      def install_command
        return unless config[:require_puppet_collections] || config[:require_puppet_repo]
        if config[:require_puppet_collections]
          install_command_collections
        else
          case puppet_platform
          when 'debian', 'ubuntu'
            info("Installing puppet on #{config[:platform]}")
            <<-INSTALL
              if [ ! $(which puppet) ]; then
                #{sudo('apt-get')} -y install wget
                #{sudo('wget')} #{wget_proxy_parm} #{puppet_apt_repo}
                #{sudo('dpkg')} -i #{puppet_apt_repo_file}
                #{update_packages_debian_cmd}
                #{sudo_env('apt-get')} -y install facter#{facter_debian_version}
                #{sudo_env('apt-get')} -y install puppet-common#{puppet_debian_version}
                #{sudo_env('apt-get')} -y install puppet#{puppet_debian_version}
                #{install_hiera}
              fi
              #{install_eyaml}
              #{install_deep_merge}
              #{install_busser}
              #{custom_install_command}
            INSTALL
          when 'redhat', 'centos', 'fedora', 'oracle', 'amazon'
            info("Installing puppet from yum on #{puppet_platform}")
            <<-INSTALL
              if [ ! $(which puppet) ]; then
                #{install_puppet_yum_repo}
              fi
              #{install_eyaml}
              #{install_deep_merge}
              #{install_busser}
              #{custom_install_command}
            INSTALL
          else
            info('Installing puppet, will try to determine platform os')
            <<-INSTALL
              if [ ! $(which puppet) ]; then
                if [ -f /etc/centos-release ] || [ -f /etc/redhat-release ] || [ -f /etc/oracle-release ]; then
                    #{install_puppet_yum_repo}
                else
                  if [ -f /etc/system-release ] || [ grep -q 'Amazon Linux' /etc/system-release ]; then
                     #{install_puppet_yum_repo}
                  else
                    #{sudo('apt-get')} -y install wget
                    #{sudo('wget')} #{wget_proxy_parm} #{puppet_apt_repo}
                    #{sudo('dpkg')} -i #{puppet_apt_repo_file}
                    #{update_packages_debian_cmd}
                    #{sudo_env('apt-get')} -y install facter#{facter_debian_version}
                    #{sudo_env('apt-get')} -y install puppet-common#{puppet_debian_version}
                    #{sudo_env('apt-get')} -y install puppet#{puppet_debian_version}
                    #{install_hiera}
                  fi
                fi
              fi
              #{install_eyaml}
              #{install_deep_merge}
              #{install_busser}
              #{custom_install_command}
            INSTALL
          end
        end
      end

      def install_command_collections
        case puppet_platform
        when 'debian', 'ubuntu'
          info("Installing Puppet Collections on #{puppet_platform}")
          <<-INSTALL
          #{sudo('apt-get')} -y install wget
          #{sudo('wget')} #{wget_proxy_parm} #{config[:puppet_apt_collections_repo]}
          #{sudo('dpkg')} -i #{puppet_apt_coll_repo_file}
          #{custom_install_command}
          INSTALL
        when 'redhat', 'centos', 'fedora', 'oracle', 'amazon'
          info("Installing Puppet Collections on #{puppet_platform}")
          <<-INSTALL
          #{Util.shell_helpers}
          if [ ! -d "#{config[:puppet_coll_remote_path]}" ]; then
            echo "-----> #{sudo_env('yum')} -y localinstall #{config[:puppet_yum_collections_repo]}"
            #{sudo_env('yum')} -y localinstall #{config[:puppet_yum_collections_repo]}
            #{sudo_env('yum')} -y install puppet
          fi
          #{install_eyaml("#{config[:puppet_coll_remote_path]}/puppet/bin/gem")}
          #{install_deep_merge}
          #{install_busser}
          #{custom_install_command}
          INSTALL
        else
          info('Installing Puppet Collections, will try to determine platform os')
          <<-INSTALL
            if [ ! -d "#{config[:puppet_coll_remote_path]}" ]; then
              if [ -f /etc/centos-release ] || [ -f /etc/redhat-release ] || [ -f /etc/oracle-release ]; then
                 #{Util.shell_helpers}
                 if [ ! -d "#{config[:puppet_coll_remote_path]}" ]; then
                   echo "-----> #{sudo_env('yum')} -y localinstall #{config[:puppet_yum_collections_repo]}"
                   #{sudo_env('yum')} -y localinstall #{config[:puppet_yum_collections_repo]}
                   #{sudo_env('yum')} -y install puppet
                 fi
              else
                if [ -f /etc/system-release ] || [ grep -q 'Amazon Linux' /etc/system-release ]; then
                  #{Util.shell_helpers}
                  if [ ! -d "#{config[:puppet_coll_remote_path]}" ]; then
                    echo "-----> #{sudo_env('yum')} -y localinstall #{config[:puppet_yum_collections_repo]}"
                    #{sudo_env('yum')} -y localinstall #{config[:puppet_yum_collections_repo]}
                    #{sudo_env('yum')} -y install puppet
                  fi
                else
                  #{sudo('apt-get')} -y install wget
                  #{sudo('wget')} #{wget_proxy_parm} #{config[:puppet_apt_collections_repo]}
                  #{sudo('dpkg')} -i #{puppet_apt_coll_repo_file}
                fi
              fi
            fi
            #{install_eyaml("#{config[:puppet_coll_remote_path]}/puppet/bin/gem")}
            #{install_deep_merge}
            #{install_busser}
            #{custom_install_command}
          INSTALL
        end
      end

      def install_deep_merge
        return unless config[:hiera_deep_merge]
        <<-INSTALL
          # Support for hash merge lookups to recursively merge hash keys
          if [[ $(#{sudo('gem')} list deep_merge -i) == 'false' ]]; then
            echo '-----> Installing deep_merge to provide deep_merge of hiera hashes'
            #{sudo('gem')} install #{gem_proxy_parm} --no-ri --no-rdoc deep_merge
          fi
        INSTALL
      end

      def install_eyaml(gem_cmd = 'gem')
        return unless config[:hiera_eyaml]
        <<-INSTALL
          # A backend for Hiera that provides per-value asymmetric encryption of sensitive data
          if [[ $(#{sudo(gem_cmd)} list hiera-eyaml -i) == 'false' ]]; then
            echo '-----> Installing hiera-eyaml to provide encryption of hiera data'
            #{sudo(gem_cmd)} install #{gem_proxy_parm} --no-ri --no-rdoc highline -v 1.6.21
            #{sudo(gem_cmd)} install #{gem_proxy_parm} --no-ri --no-rdoc hiera-eyaml
          fi
        INSTALL
      end

      def install_busser
        return unless config[:require_chef_for_busser]
        <<-INSTALL
          #{Util.shell_helpers}
          # install chef omnibus so that busser works as this is needed to run tests :(
          # TODO: work out how to install enough ruby
          # and set busser: { :ruby_bindir => '/usr/bin/ruby' } so that we dont need the
          # whole chef client
          if [ ! -d "/opt/chef" ]
          then
            echo '-----> Installing Chef Omnibus to install busser to run tests'
            do_download #{chef_url} /tmp/install.sh
            #{sudo('sh')} /tmp/install.sh
          fi
        INSTALL
      end

      def install_hiera
        return unless config[:install_hiera]
        <<-INSTALL
          #{sudo_env('apt-get')} -y install hiera-puppet#{puppet_hiera_debian_version}
        INSTALL
      end

      # /bin/wget -P /etc/pki/rpm-gpg/ http://yum.puppetlabs.com/RPM-GPG-KEY-puppetlabs
      # changed to curl

      def install_puppet_yum_repo
        <<-INSTALL
          rhelversion=$(cat /etc/redhat-release | grep 'release 7')
          # For CentOS7/RHEL7 the rdo release contains puppetlabs repo, creating conflict. Create temp-repo
          #{sudo_env('curl')} -o /etc/pki/rpm-gpg/RPM-GPG-KEY-puppetlabs http://yum.puppetlabs.com/RPM-GPG-KEY-puppetlabs
          if [ -n "$rhelversion" ]; then
          echo '[puppettemp-products]
          name=Puppet Labs Products - \$basearch
          baseurl=http://yum.puppetlabs.com/el/7/products/\$basearch
          gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-puppetlabs
          enabled=0
          gpgcheck=1
          [puppettemp-deps]
          name=Puppet Labs Dependencies - \$basearch
          baseurl=http://yum.puppetlabs.com/el/7/dependencies/\$basearch
          gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-puppetlabs
          enabled=0
          gpgcheck=1' | sudo tee /etc/yum.repos.d/puppettemp.repo > /dev/null
          sudo sed -i 's/^[ \t]*//' /etc/yum.repos.d/puppettemp.repo
            #{update_packages_redhat_cmd}
            #{sudo_env('yum')} -y --enablerepo=puppettemp-products --enablerepo=puppettemp-deps install puppet#{puppet_redhat_version}
            # Clean up temporary puppet repo
            sudo rm -rf /etc/pki/rpm-gpg/RPM-GPG-KEY-puppetlabs
            sudo rm -rf /etc/yum.repos.d/puppettemp.repo
          else
            #{sudo('rpm')} -ivh #{proxy_parm} #{puppet_yum_repo}
            #{update_packages_redhat_cmd}
            #{sudo_env('yum')} -y install puppet#{puppet_redhat_version}
          fi
        INSTALL
      end

      def custom_install_command
        <<-INSTALL
          #{config[:custom_install_command]}
        INSTALL
      end

      def init_command
        dirs = %w(modules manifests files hiera hiera.yaml spec)
        .map { |dir| File.join(config[:root_path], dir) }.join(' ')
        cmd = "#{sudo('rm')} -rf #{dirs} #{hiera_data_remote_path} \
              /etc/hiera.yaml #{puppet_dir}/hiera.yaml \
              #{spec_files_remote_path} \
              #{puppet_dir}/fileserver.conf;"
        cmd += config[:puppet_environment] ? "#{sudo('rm')} -f #{File.join(puppet_dir, config[:puppet_environment])};" : ''
        cmd += " mkdir -p #{config[:root_path]}; #{sudo('mkdir')} -p #{puppet_dir}"
        debug(cmd)
        cmd
      end

      def create_sandbox
        super
        debug("Creating local sandbox in #{sandbox_path}")
        yield if block_given?
        prepare_modules
        prepare_manifests
        prepare_files
        prepare_facts
        prepare_puppet_config
        prepare_hiera_config
        prepare_fileserver_config
        prepare_hiera_data
        prepare_spec_files
        info('Finished Preparing files for transfer')
      end

      def cleanup_sandbox
        return if sandbox_path.nil?
        debug("Cleaning up local sandbox in #{sandbox_path}")
        FileUtils.rmtree(sandbox_path)
      end

      # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      def prepare_command
        commands = []
        if puppet_git_init
          commands << [
            sudo('rm -rf'), '/etc/puppet'
          ].join(' ')

          commands << [
            sudo('git clone'), puppet_git_init, '/etc/puppet'
          ].join(' ')
        end

        if puppet_git_pr
          commands << [sudo('git'),
                       '--git-dir=/etc/puppet/.git/',
                       'fetch -f',
                       'origin',
                       "pull/#{puppet_git_pr}/head:pr_#{puppet_git_pr}"
                      ].join(' ')

          commands << [sudo('git'), '--git-dir=/etc/puppet/.git/',
                       '--work-tree=/etc/puppet/',
                       'checkout',
                       "pr_#{puppet_git_pr}"
                      ].join(' ')
        end

        if puppet_config
          commands << [
            sudo('cp'),
            File.join(config[:root_path], 'puppet.conf'),
            puppet_dir
          ].join(' ')
        end

        if hiera_config
          commands << [
            sudo('cp'), File.join(config[:root_path], 'hiera.yaml'), '/etc/'
          ].join(' ')

          commands << [
            sudo('cp'), File.join(config[:root_path], 'hiera.yaml'), puppet_dir
          ].join(' ')
        end

        if fileserver_config
          commands << [
            sudo('cp'),
            File.join(config[:root_path], 'fileserver.conf'),
            puppet_dir
          ].join(' ')
        end

        if hiera_data && hiera_data_remote_path == '/var/lib/hiera'
          commands << [
            sudo('cp -r'), File.join(config[:root_path], 'hiera'), '/var/lib/'
          ].join(' ')
        end

        if hiera_data && hiera_data_remote_path != '/var/lib/hiera'
          commands << [
            sudo('mkdir -p'), hiera_data_remote_path
          ].join(' ')
          commands << [
            sudo('cp -r'), File.join(config[:root_path], 'hiera/*'), hiera_data_remote_path
          ].join(' ')
        end

        if hiera_eyaml
          commands << [
            sudo('mkdir -p'), hiera_eyaml_key_remote_path
          ].join(' ')
          commands << [
            sudo('cp -r'), File.join(config[:root_path], 'hiera_keys/*'), hiera_eyaml_key_remote_path
          ].join(' ')
        end

        if puppet_environment
          commands << [
            sudo('ln -s '), config[:root_path], File.join(puppet_dir, config[:puppet_environment])
          ].join(' ')
        end

        if spec_files_path && spec_files_remote_path
          commands << [
            sudo('mkdir -p'), spec_files_remote_path
          ].join(' ')
          commands << [
            sudo('cp -r'), File.join(config[:root_path], 'spec/*'), spec_files_remote_path
          ].join(' ')
        end

        command = commands.join(' && ')
        debug(command)
        command
      end
      # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

      def run_command
        if !config[:puppet_apply_command].nil?
          return config[:puppet_apply_command]
        else
          [
            facterlib,
            custom_facts,
            facter_facts,
            puppet_cmd,
            'apply',
            File.join(config[:root_path], 'manifests', manifest),
            "--modulepath=#{File.join(config[:root_path], 'modules')}",
            puppet_manifestdir,
            "--fileserverconfig=#{File.join(config[:root_path], 'fileserver.conf')}",
            puppet_environment_flag,
            puppet_noop_flag,
            puppet_detailed_exitcodes_flag,
            puppet_verbose_flag,
            puppet_debug_flag,
            puppet_logdest_flag,
            remove_repo
          ].join(' ')
        end
      end

      protected

      def load_needed_dependencies!
        return unless File.exist?(puppetfile)
        return unless config[:resolve_with_librarian_puppet]
        debug("Puppetfile found at #{puppetfile}, loading Librarian-Puppet")
        Puppet::Librarian.load!(logger)
      end

      def tmpmodules_dir
        File.join(sandbox_path, 'modules')
      end

      def puppetfile
        config[:puppetfile_path] || ''
      end

      def modulefile
        config[:modulefile_path] || ''
      end

      def metadata_json
        config[:metadata_json_path] || ''
      end

      def manifest
        config[:manifest]
      end

      def manifests
        config[:manifests_path]
      end

      def modules
        config[:modules_path]
      end

      def files
        config[:files_path] || 'files'
      end

      def puppet_config
        config[:puppet_config_path]
      end

      def puppet_environment
        config[:puppet_environment]
      end

      def puppet_git_init
        config[:puppet_git_init]
      end

      def puppet_git_pr
        config[:puppet_git_pr]
      end

      def hiera_config
        config[:hiera_config_path]
      end

      def fileserver_config
        config[:fileserver_config_path]
      end

      def hiera_data
        config[:hiera_data_path]
      end

      def hiera_data_remote_path
        config[:hiera_data_remote_path]
      end

      def hiera_eyaml
        config[:hiera_eyaml]
      end

      def hiera_eyaml_key_path
        config[:hiera_eyaml_key_path]
      end

      def hiera_eyaml_key_remote_path
        config[:hiera_eyaml_key_remote_path]
      end

      def hiera_deep_merge
        config[:hiera_deep_merge]
      end

      def librarian_puppet_ssl_file
        config[:librarian_puppet_ssl_file]
      end

      def puppet_cmd
        if config[:require_puppet_collections]
          sudo_env("#{config[:puppet_coll_remote_path]}/bin/puppet")
        else
          sudo_env('puppet')
        end
      end

      def puppet_dir
        if config[:require_puppet_collections]
          '/etc/puppetlabs/puppet'
        else
          '/etc/puppet'
        end
      end

      def puppet_debian_version
        config[:puppet_version] ? "=#{config[:puppet_version]}" : nil
      end

      def facter_debian_version
        config[:facter_version] ? "=#{config[:facter_version]}" : nil
      end

      def puppet_hiera_debian_version
        config[:hiera_version] ? "=#{config[:hiera_version]}" : nil
      end

      def puppet_redhat_version
        config[:puppet_version] ? "-#{config[:puppet_version]}" : nil
      end

      def puppet_environment_flag
        if config[:puppet_version] =~ /^2/
          config[:puppet_environment] ? "--environment=#{config[:puppet_environment]}" : nil
        else
          config[:puppet_environment] ? "--environment=#{config[:puppet_environment]} --environmentpath=#{puppet_dir}" : nil
        end
      end

      def puppet_manifestdir
        config[:puppet_environment] ? nil : "--manifestdir=#{File.join(config[:root_path], 'manifests')}"
      end

      def puppet_noop_flag
        config[:puppet_noop] ? '--noop' : nil
      end

      def puppet_debug_flag
        config[:puppet_debug] ? '-d' : nil
      end

      def puppet_verbose_flag
        config[:puppet_verbose] ? '-v' : nil
      end

      def puppet_logdest_flag
        return nil unless config[:puppet_logdest]
        destinations = ''
        config[:puppet_logdest].each do |dest|
          destinations << "--logdest #{dest} "
        end
        destinations
      end

      def puppet_platform
        config[:platform].gsub(/-.*/, '')
      end

      def facter_facts
        return nil unless config[:facter_file]
        fact_vars = 'export '
        fact_hash = YAML.load_file(config[:facter_file])
        fact_hash.each do |key, value|
          fact_vars << "FACTER_#{key}=#{value} "
        end
        fact_vars << ';'
        fact_vars
      end

      def update_packages_debian_cmd
        config[:update_package_repos] ? "#{sudo_env('apt-get')} update" : nil
      end

      def update_packages_redhat_cmd
        # #{sudo('yum')}
        config[:update_package_repos] ? "#{sudo_env('yum')} makecache" : nil
      end

      def sudo_env(pm)
        s = https_proxy ? "https_proxy=#{https_proxy}" : nil
        p = http_proxy ? "http_proxy=#{http_proxy}" : nil
        p || s ? "#{sudo('env')} #{p} #{s} #{pm}" : "#{sudo(pm)}"
      end

      def remove_puppet_repo
        config[:remove_puppet_repo]
      end

      def spec_files_path
        config[:spec_files_path]
      end

      def spec_files_remote_path
        config[:spec_files_remote_path]
      end

      def facterlib
        return nil if config[:facterlib].nil?
        bash_vars = "export FACTERLIB='#{config[:facterlib]}';"
        debug(bash_vars)
        bash_vars
      end

      def custom_facts
        return nil if config[:custom_facts].none?
        bash_vars = config[:custom_facts].map { |k, v| "FACTER_#{k}=#{v}" }.join(' ')
        bash_vars = "export #{bash_vars};"
        debug(bash_vars)
        bash_vars
      end

      def puppet_detailed_exitcodes_flag
        config[:puppet_detailed_exitcodes] ? '--detailed-exitcodes' : nil
      end

      def remove_repo
        remove_puppet_repo ? "; #{sudo('rm')} -rf /tmp/kitchen #{hiera_data_remote_path} #{hiera_eyaml_key_remote_path} #{puppet_dir}/* " : nil
      end

      # rubocop:disable Metrics/CyclomaticComplexity
      def puppet_apt_repo
        platform_version = config[:platform].partition('-')[2]
        case puppet_platform
        when 'ubuntu'
          case platform_version
          when '14.10'
            # Utopic Repo
            'https://apt.puppetlabs.com/puppetlabs-release-utopic.deb'
          when '14.04'
            # Trusty Repo
            'https://apt.puppetlabs.com/puppetlabs-release-trusty.deb'
          when '12.04'
            # Precise Repo
            'https://apt.puppetlabs.com/puppetlabs-release-precise.deb'
          else
            # Configured Repo
            config[:puppet_apt_repo]
          end
        when 'debian'
          case platform_version.gsub(/\..*/, '')
          when '8'
            # Debian Jessie
            'https://apt.puppetlabs.com/puppetlabs-release-jessie.deb'
          when '7'
            # Debian Wheezy
            'https://apt.puppetlabs.com/puppetlabs-release-wheezy.deb'
          when '6'
            # Debian Squeeze
            'https://apt.puppetlabs.com/puppetlabs-release-squeeze.deb'
          else
            # Configured Repo
            config[:puppet_apt_repo]
          end
        else
          error("Unsupported Platform - #{config[:platform]}")
        end
      end

      def puppet_apt_repo_file
        puppet_apt_repo.split('/').last
      end

      def puppet_apt_coll_repo_file
        config[:puppet_apt_collections_repo].split('/').last
      end

      def puppet_yum_repo
        config[:puppet_yum_repo]
      end

      def proxy_parm
        http_proxy ? "--httpproxy #{URI.parse(http_proxy).host.downcase} --httpport #{URI.parse(http_proxy).port} " : nil
      end

      def gem_proxy_parm
        http_proxy ? "--http-proxy #{http_proxy}" : nil
      end

      def wget_proxy_parm
        p = http_proxy ? "-e http_proxy=#{http_proxy}" : nil
        s = https_proxy ? "-e http_proxy=#{http_proxy}" : nil
        p || s ? "-e use_proxy=yes #{p} #{s}" : nil
      end

      def http_proxy
        config[:http_proxy]
      end

      def https_proxy
        config[:https_proxy]
      end

      def chef_url
        config[:chef_bootstrap_url]
      end

      def prepare_manifests
        info('Preparing manifests')
        debug("Using manifests from #{manifests}")

        tmp_manifests_dir = File.join(sandbox_path, 'manifests')
        FileUtils.mkdir_p(tmp_manifests_dir)
        FileUtils.cp_r(Dir.glob("#{manifests}/*"), tmp_manifests_dir)
      end

      def prepare_files
        info('Preparing files')
        unless File.directory?(files)
          info 'nothing to do for files'
          return
        end

        debug("Using files from #{files}")

        tmp_files_dir = File.join(sandbox_path, 'files')
        FileUtils.mkdir_p(tmp_files_dir)
        FileUtils.cp_r(Dir.glob("#{files}/*"), tmp_files_dir)
      end

      def prepare_facts
        return unless config[:install_custom_facts]
        return unless config[:custom_facts]
        info 'Installing custom facts'
        facter_dir = File.join(sandbox_path, 'facter')
        FileUtils.mkdir_p(facter_dir)
        tmp_facter_file = File.join(facter_dir, 'kitchen.yaml')
        facter_facts = Hash[config[:custom_facts].map { |k, v| [k.to_s, v.to_s] }]
        File.open(tmp_facter_file, 'w') do |out|
          YAML.dump(facter_facts, out)
        end
      end

      def prepare_modules
        info('Preparing modules')

        FileUtils.mkdir_p(tmpmodules_dir)
        resolve_with_librarian if File.exist?(puppetfile) && config[:resolve_with_librarian_puppet]

        if modules && File.directory?(modules)
          debug("Copying modules from #{modules} to #{tmpmodules_dir}")
          FileUtils.cp_r(Dir.glob("#{modules}/*"), tmpmodules_dir, remove_destination: true)
        else
          info 'nothing to do for modules'
        end

        copy_self_as_module
      end

      def copy_self_as_module
        if File.exist?(modulefile)
          warn('Modulefile found but this is depricated, ignoring it, see https://tickets.puppetlabs.com/browse/PUP-1188')
        end

        return unless File.exist?(metadata_json)
        module_name = nil
        begin
          module_name = JSON.parse(IO.read(metadata_json))['name'].split('-').last
        rescue
          error("not able to load or parse #{metadata_json_path} for the name of the module")
        end

        return unless module_name
        module_target_path = File.join(sandbox_path, 'modules', module_name)
        FileUtils.mkdir_p(module_target_path)
        FileUtils.cp_r(
          Dir.glob(File.join(config[:kitchen_root], '*')).reject { |entry| entry =~ /modules$|spec$|pkg$/ },
          module_target_path,
          remove_destination: true
        )
      end

      def prepare_puppet_config
        return unless puppet_config

        info('Preparing puppet.conf')
        debug("Using puppet config from #{puppet_config}")

        FileUtils.cp_r(puppet_config, File.join(sandbox_path, 'puppet.conf'))
      end

      def prepare_hiera_config
        return unless hiera_config

        info('Preparing hiera')
        debug("Using hiera from #{hiera_config}")

        FileUtils.cp_r(hiera_config, File.join(sandbox_path, 'hiera.yaml'))
      end

      def prepare_fileserver_config
        return unless fileserver_config

        info('Preparing fileserver')
        debug("Using fileserver config from #{fileserver_config}")

        FileUtils.cp_r(fileserver_config, File.join(sandbox_path, 'fileserver.conf'))
      end

      def prepare_hiera_data
        return unless hiera_data
        info('Preparing hiera data')
        tmp_hiera_dir = File.join(sandbox_path, 'hiera')
        debug("Copying hiera data from #{hiera_data} to #{tmp_hiera_dir}")
        FileUtils.mkdir_p(tmp_hiera_dir)
        FileUtils.cp_r(Dir.glob("#{hiera_data}/*"), tmp_hiera_dir)
        return unless hiera_eyaml_key_path
        tmp_hiera_key_dir = File.join(sandbox_path, 'hiera_keys')
        debug("Copying hiera eyaml keys from #{hiera_eyaml_key_path} to #{tmp_hiera_key_dir}")
        FileUtils.mkdir_p(tmp_hiera_key_dir)
        FileUtils.cp_r(Dir.glob("#{hiera_eyaml_key_path}/*"), tmp_hiera_key_dir)
      end

      def prepare_spec_files
        return unless spec_files_path
        info('Preparing spec files')
        tmp_spec_dir = File.join(sandbox_path, 'spec')
        debug("Copying specs from #{spec_files_path} to #{tmp_spec_dir}")
        FileUtils.mkdir_p(tmp_spec_dir)
        FileUtils.cp_r(Dir.glob("#{spec_files_path}/*"), tmp_spec_dir)
      end

      def resolve_with_librarian
        Kitchen.mutex.synchronize do
          ENV['SSL_CERT_FILE'] = librarian_puppet_ssl_file if librarian_puppet_ssl_file
          Puppet::Librarian.new(puppetfile, tmpmodules_dir, logger).resolve
          ENV['SSL_CERT_FILE'] = '' if librarian_puppet_ssl_file
        end
      end
    end
  end
end
