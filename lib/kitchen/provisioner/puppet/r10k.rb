# -*- encoding: utf-8 -*-

#
# Author:: Fletcher Nichol (<fnichol@nichol.ca>) Neill Turner (<neillwturner@gmail.com>) Dennis Lerch (<dennis.lerch@transporeon.com>)
#
# Copyright (C) 2018, Fletcher Nichol, Neill Turner, Dennis Lerch
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

require 'kitchen/errors'
require 'kitchen/logging'

module Kitchen
  module Provisioner
    module Puppet
      # Puppet module resolver that uses R10K and a Puppetfile to
      # calculate # dependencies.
      #
      class R10K
        include Logging

        def initialize(puppetfile, path, logger = Kitchen.logger)
          @puppetfile = puppetfile
          @path = path
          @logger = logger
        end

        def self.load!(logger = Kitchen.logger)
          load_r10k!(logger)
        end

        def resolve
          version = ::R10K::VERSION
          info("Resolving module dependencies with R10K-Puppet #{version}...")
          debug("Using Puppetfile from #{puppetfile}")

          ::R10K::Git::Cache.settings[:cache_root] = '.r10k/git'
          ::R10K::Forge::ModuleRelease.settings[:cache_root] = '.r10k/cache'

          pf = ::R10K::Puppetfile.new(nil, path, puppetfile)
          pf.load
          pf.modules.map(&:sync)
        end

        attr_reader :puppetfile, :path, :logger

        def self.load_r10k!(logger)
          require 'r10k/puppetfile'

          version = ::R10K::VERSION
          logger.debug("R10K #{version} library loaded")
        rescue LoadError => e
          logger.fatal("The `r10k' gem is missing and must be installed" \
            ' or cannot be properly activated. Run' \
            ' `gem install r10k` or add the following to your' \
            " Gemfile if you are using Bundler: `gem 'r10k'`.")
          raise UserError,
                "Could not load or activate R10K (#{e.message})"
        end
      end
    end
  end
end
