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
# for documentation configuration parameters with puppet_agent provisioner.
#

require 'json'
require 'kitchen/provisioner/base'
require 'kitchen/provisioner/puppet/librarian'

module Kitchen
  class Busser
    def non_suite_dirs
      %w(data data_bags environments nodes roles puppet)
    end
  end

  module Provisioner
    #
    # Puppet Agent provisioner.
    #
    class PuppetAgent < Base
      attr_accessor :tmp_dir

      default_config :require_puppet_omnibus, false
      # TODO: use something like https://github.com/fnichol/omnibus-puppet
      default_config :puppet_omnibus_url, nil
      default_config :puppet_omnibus_remote_path, '/opt/puppet'
      default_config :puppet_version, nil
      default_config :facter_version, nil
      default_config :require_puppet_repo, true
      default_config :require_chef_for_busser, true

      default_config :puppet_apt_repo, 'http://apt.puppetlabs.com/puppetlabs-release-precise.deb'
      default_config :puppet_yum_repo, 'https://yum.puppetlabs.com/puppetlabs-release-el-6.noarch.rpm'
      default_config :chef_bootstrap_url, 'https://www.getchef.com/chef/install.sh'

      default_config :puppet_agent_command, nil

      default_config :http_proxy, nil

      default_config :puppet_config_path do |provisioner|
        provisioner.calculate_path('puppet.conf', :file)
      end

      default_config :puppet_debug, false
      default_config :puppet_verbose, false
      default_config :puppet_noop, false
      default_config :puppet_platform, ''
      default_config :update_package_repos, true

      default_config :custom_facts, {}

      default_config :puppet_detailed_exitcodes, nil
      default_config :puppet_logdest, nil
      default_config :puppet_masterport, nil
      default_config :puppet_test, false
      default_config :puppet_onetime, true
      default_config :puppet_no_daemonize, true
      default_config :puppet_server, nil # will default to 'puppet'
      default_config :puppet_waitforcert, '0'
      default_config :puppet_certname, nil
      default_config :puppet_digest, nil

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

      def install_command
        return unless config[:require_puppet_omnibus] || config[:require_puppet_repo]
        if config[:require_puppet_omnibus]
          info('Installing puppet using puppet omnibus')
          version = ''
          version = "-v #{config[:puppet_version]}" if config[:puppet_version]
          <<-INSTALL
            #{Util.shell_helpers}

            if [ ! -d "#{config[:puppet_omnibus_remote_path]}" ]; then
              echo "-----> Installing Puppet Omnibus"
              do_download #{config[:puppet_omnibus_url]} /tmp/puppet_install.sh
              #{sudo('sh')} /tmp/puppet_install.sh #{version}
            fi
            #{install_busser}
          INSTALL
        else
          case puppet_platform
          when 'debian', 'ubuntu'
            info("Installing puppet on #{puppet_platform}")
            <<-INSTALL
              if [ ! $(which puppet) ]; then
                #{sudo('apt-get')} -y install wget
                #{sudo('wget')} #{wget_proxy_parm} #{puppet_apt_repo}
                #{sudo('dpkg')} -i #{puppet_apt_repo_file}
                #{update_packages_debian_cmd}
                #{sudo_env('apt-get')} -y install facter#{facter_debian_version}
                #{sudo('apt-get')} -y install puppet-common#{puppet_debian_version}
                #{sudo('apt-get')} -y install puppet#{puppet_debian_version}
              fi
              #{install_busser}
            INSTALL
          when 'redhat', 'centos', 'fedora', 'oracle', 'amazon'
            info("Installing puppet on #{puppet_platform}")
            <<-INSTALL
              if [ ! $(which puppet) ]; then
                #{sudo('rpm')} -ivh #{proxy_parm} #{puppet_yum_repo}
                #{update_packages_redhat_cmd}
                #{sudo('yum')} -y install puppet#{puppet_redhat_version}
              fi
              #{install_busser}
            INSTALL
          else
            info('Installing puppet, will try to determine platform os')
            <<-INSTALL
              if [ ! $(which puppet) ]; then
                if [ -f /etc/centos-release ] || [ -f /etc/redhat-release ] || [ -f /etc/oracle-release ]; then
                  #{sudo('rpm')} -ivh #{proxy_parm} #{puppet_yum_repo}
                  #{update_packages_redhat_cmd}
                  #{sudo('yum')} -y install puppet#{puppet_redhat_version}
                else
                  if [ -f /etc/system-release ] || grep -q 'Amazon Linux' /etc/system-release; then
                    #{sudo('rpm')} -ivh #{proxy_parm} #{puppet_yum_repo}
                    #{update_packages_redhat_cmd}
                    #{sudo('yum')} -y install puppet#{puppet_redhat_version}
                  else
                    #{sudo('apt-get')} -y install wget
                    #{sudo('wget')} #{wget_proxy_parm} #{puppet_apt_repo}
                    #{sudo('dpkg')} -i #{puppet_apt_repo_file}
                    #{update_packages_debian_cmd}
                    #{sudo('apt-get')} -y install facter#{facter_debian_version}
                    #{sudo('apt-get')} -y install puppet-common#{puppet_debian_version}
                    #{sudo('apt-get')} -y install puppet#{puppet_debian_version}
                  fi
                fi
              fi
              #{install_busser}
            INSTALL
          end
        end
      end
      # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

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
            echo "-----> Installing Chef Omnibus to install busser to run tests"
            do_download #{chef_url} /tmp/install.sh
            #{sudo('sh')} /tmp/install.sh
          fi
        INSTALL
      end

      def init_command
      end

      def create_sandbox
        super
        debug("Creating local sandbox in #{sandbox_path}")

        yield if block_given?

        prepare_puppet_config
        info('Finished Preparing files for transfer')
      end

      def cleanup_sandbox
        return if sandbox_path.nil?
        debug("Cleaning up local sandbox in #{sandbox_path}")
        FileUtils.rmtree(sandbox_path)
      end

      def prepare_command
        commands = []

        if puppet_config
          commands << [
            sudo('cp'),
            File.join(config[:root_path], 'puppet.conf'),
            '/etc/puppet'
          ].join(' ')
        end

        command = commands.join(' && ')
        debug(command)
        command
      end

      def run_command
        if !config[:puppet_agent_command].nil?
          return config[:puppet_agent_command]
        else
          [
            custom_facts,
            sudo_env('puppet'),
            'agent',
            puppet_server_flag,
            "--waitforcert=#{config[:puppet_waitforcert]}",
            puppet_masterport_flag,
            puppet_certname_flag,
            puppet_digest_flag,
            puppet_detailed_exitcodes_flag,
            puppet_logdest_flag,
            puppet_test_flag,
            puppet_onetime_flag,
            puppet_no_daemonize_flag,
            puppet_noop_flag,
            puppet_verbose_flag,
            puppet_debug_flag
          ].join(' ')
        end
      end

      protected

      def load_needed_dependencies!
      end

      def puppet_config
        config[:puppet_config_path]
      end

      def puppet_debian_version
        config[:puppet_version] ? "=#{config[:puppet_version]}" : nil
      end

      def facter_debian_version
        config[:facter_version] ? "=#{config[:facter_version]}" : nil
      end

      def puppet_redhat_version
        config[:puppet_version] ? "-#{config[:puppet_version]}" : nil
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

      def puppet_platform
        config[:puppet_platform].to_s.downcase
      end

      def update_packages_debian_cmd
        config[:update_package_repos] ? "#{sudo_env('apt-get')} update" : nil
      end

      def update_packages_redhat_cmd
        config[:update_package_repos] ? "#{sudo_env('yum')} makecache" : nil
      end

      def sudo_env(pm)
        http_proxy ? "#{sudo('env')} http_proxy=#{http_proxy} #{pm}" : sudo(pm).to_s
      end

      def custom_facts
        return nil if config[:custom_facts].none?
        bash_vars = config[:custom_facts].map { |k, v| "FACTER_#{k}=#{v}" }.join(' ')
        bash_vars = "export #{bash_vars};"
        debug(bash_vars)
        bash_vars
      end

      def puppet_server_flag
        config[:puppet_server] ? "--server=#{config[:puppet_server]}" : nil
      end

      def puppet_masterport_flag
        config[:puppet_masterport] ? '--masterport=#{config[:puppet_masterport]}' : nil
      end

      def puppet_detailed_exitcodes_flag
        config[:puppet_detailed_exitcodes] ? '--detailed-exitcodes' : nil
      end

      def puppet_logdest_flag
        config[:puppet_logdest] ? "--logdest=#{config[:puppet_logdest]}" : nil
      end

      def puppet_test_flag
        config[:puppet_test] ? '--test' : nil
      end

      def puppet_onetime_flag
        config[:puppet_onetime] ? '--onetime' : nil
      end

      def puppet_no_daemonize_flag
        config[:puppet_no_daemonize] ? '--no-daemonize' : nil
      end

      def puppet_no_daemonize
        config[:puppet_no_daemonize]
      end

      def puppet_server
        config[:puppet_server]
      end

      def puppet_certname_flag
        config[:puppet_certname] ? "--certname=#{config[:puppet_certname]}" : nil
      end

      def puppet_digest_flag
        config[:puppet_digest] ? "--digest=#{config[:puppet_digest]}" : nil
      end

      def puppet_apt_repo
        config[:puppet_apt_repo]
      end

      def puppet_apt_repo_file
        config[:puppet_apt_repo].split('/').last
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
        http_proxy ? "-e use_proxy=yes -e http_proxy=#{http_proxy}" : nil
      end

      def http_proxy
        config[:http_proxy]
      end

      def chef_url
        config[:chef_bootstrap_url]
      end

      def prepare_puppet_config
        return unless puppet_config

        info('Preparing puppet.conf')
        debug("Using puppet config from #{puppet_config}")

        FileUtils.cp_r(puppet_config, File.join(sandbox_path, 'puppet.conf'))
      end
    end
  end
end
