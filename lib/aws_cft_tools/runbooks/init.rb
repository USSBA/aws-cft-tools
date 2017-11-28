# frozen_string_literal: true

module AwsCftTools
  module Runbooks
    ##
    # Deploy - manage CloudFormation stack deployment
    #
    # @example
    #   % aws-cli init # create skeleton project in the current directory
    #
    class Init < Runbook
      ##
      # The default project configuration file.
      #
      DEFAULT_CONFIG = <<~EOF
        ---
        ###
        # Values in this file override the defaults in aws-cft. Command line options override these values.
        #
        # This is a good place to put project- or account-wide defaults for teams using the templates in this
        # repo.
        ###

        ###
        # By default, we want as much detail as possible.
        #
        :verbose: true

        ###
        # When different templates have nothing indicating their relative ordering, they are ordered based on the
        # directory/folder in which they appear ordered by this list.
        #
        :template_folder_priorities:
          - vpcs
          - networks
          - security
          - data-resources
          - data-services
          - applications
      EOF

      ##
      # The template role directories to build out when creating a project.
      #
      TEMPLATE_ROLES = %w[applications data-resources data-services networks security vpcs].freeze

      ##
      # The different types of files used when managing templates and stacks.
      #
      FILE_TYPES = %w[parameters templates].freeze

      def run
        ensure_project_directory
        ensure_cloudformation_directories
        ensure_config_file
      end

      private

      def ensure_config_file
        operation('Creating configuration file') do
          file = options[:root] + options[:config_file]
          if file.exist?
            narrative 'Configuration file already exists. Not overwriting.'
          else
            doing { file.write(DEFAULT_CONFIG) }
          end
        end
      end

      def ensure_project_directory
        ensure_directory(options[:root])
      end

      def ensure_cloudformation_directories
        FILE_TYPES.product(TEMPLATE_ROLES).map { |list| list.join('/') }.each do |dir|
          ensure_directory(options[:root] + 'cloudformation/' + dir)
        end
      end

      def ensure_directory(dir)
        operation("Ensure #{dir} exists") { dir.mkpath }
      end
    end
  end
end
