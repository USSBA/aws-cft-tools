# frozen_string_literal: true

require 'forwardable'

module AwsCftTools
  module Runbooks
    ##
    # Deploy - manage CloudFormation stack deployment
    #
    # @example
    #   % aws-cft deploy -e QA               # deploy all templates to the QA environment
    #   % aws-cft deploy -e Staging -n -v    # narrate the templates that would be used for Staging
    #   % aws-cft deploy -e Production -c -v # narrate the changes that would go into Production
    #
    class Deploy < Runbook
      require_relative 'common/changesets'
      require_relative 'common/templates'
      require_relative 'deploy/reporting'
      require_relative 'deploy/stacks'
      require_relative 'deploy/templates'
      require_relative 'deploy/threading'

      extend Forwardable

      include Common::Changesets
      include Common::Templates
      include Reporting
      include Stacks
      include Templates
      include Threading

      def_delegators :client, :images
      def_delegator  :client, :all_stacks, :stacks

      def run
        run_reports

        detail 'Updating template parameters...'
        update_parameters

        process_templates(options[:jobs] || 1)
      end

      private

      def process_templates(slice_size)
        templates_in_folder_order.each_slice(slice_size, &method(:process_slice))
      end

      def process_slice(templates)
        jobs = options[:jobs]
        if jobs && jobs > 1
          process_slice_threaded(templates)
        else
          templates.each(&method(:process_template))
        end
      end

      def process_slice_threaded(templates)
        original_stdout, $stdout = $stdout, ThreadedOutput.new(original_stdout)
        create_threads(templates, &method(:process_template)).map(&:join)
      ensure
        $stdout = original_stdout
      end

      def process_template(template)
        setup_processing_template_thread(template)
        if deployed_templates.include?(template)
          manage_template_process(template, 'Updating', :update)
        else
          manage_template_process(template, 'Creating', :create)
        end
      ensure
        cleanup_processing_template_thread(template)
      end

      def setup_processing_template_thread(template)
        ThreadedOutput.prefix = template_name = template.name
        debug("Processing #{template_name}")
      end

      def manage_template_process(template, op_name, op_type)
        operation("#{op_name}: #{template.name}") do
          exec_template(template: template, type: op_type)
        end
      end

      def cleanup_processing_template_thread(template)
        $stdout.flush
        debug("Finished processing #{template.name}")
      end

      def exec_template(params) # template:, type:
        checking { exec_template_check(**params) }
        doing { exec_template_for_real(**params) }
      end

      def exec_template_check(template:, type:)
        narrate_changes(client.send(:"changes_on_stack_#{type}", template, changeset_set))
      rescue Aws::CloudFormation::Errors::ValidationError => error
        puts "Error checking #{template.filename}: #{error.message}"
      end

      def exec_template_for_real(template:, type:)
        client.send(:"#{type}_stack", template)
      rescue Aws::CloudFormation::Errors::ValidationError => error
        raise AwsCftTools::CloudFormationError, "Error processing #{template.filename}: #{error}"
      end

      ##
      # update_parameters - notate templates with region and image id as appropriate
      #
      def update_parameters
        templates.each { |template| update_template_with_image_id(template) }
      end

      ##
      # the set of templates corresponding to deployed CloudFormation stacks
      #
      def deployed_templates
        @deployed_templates ||= templates_in_folder_order.select do |template|
          deployed_stack_names.include?(template.name)
        end
      end

      ##
      # the set of templates with no corresponding deployed CloudFormation stack
      #
      def new_templates
        @new_templates ||= templates_in_folder_order - deployed_templates
      end
    end
  end
end
