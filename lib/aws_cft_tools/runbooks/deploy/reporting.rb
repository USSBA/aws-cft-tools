# frozen_string_literal: true

require 'table_print'

module AwsCftTools
  module Runbooks
    class Deploy
      ##
      # module with various reporting functions for deployment
      #
      module Reporting
        private

        def run_reports
          report_available_images
          report_undefined_variables

          detail do
            tp(templates, ['filename'])
          end
        end

        ##
        # report_available_images - provide tabular report of available images
        #
        def report_available_images
          detail('Available Images') { tp(report_available_images_data) }
        end

        def report_available_images_data
          available_images.map { |role_env, ami| role_env.split(/:/).reverse + [ami] }
                          .compact
                          .sort
                          .map { |role_env_ami| %w[role environment ami].zip(role_env_ami).to_h }
        end

        ##
        # report_undefined_image - provide list of undefined imports that block stack deployment
        #
        def report_undefined_variables
          vars = templates_in_folder_order.undefined_variables
          return unless vars.any?
          puts '*** Unable to update or create templates.'
          puts 'The following variables are referenced but not defined: ', vars
          exit 1 # TODO: convert to a raise
        end
      end
    end
  end
end
