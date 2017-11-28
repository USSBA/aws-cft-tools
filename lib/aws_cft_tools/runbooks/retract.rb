# frozen_string_literal: true

require 'forwardable'
require 'table_print'
require 'securerandom'

module AwsCftTools
  module Runbooks
    ##
    # Retract - manage CloudFormation stack retraction
    #
    # @example
    #   % aws-cft retract -e QA               # delete all templates in the QA environment
    #   % aws-cft retract -e Staging -n -v    # narrate the templates that would be deleted in Staging
    #   % aws-cft retract -e Production -c -v # narrate the changes implied by deleting stacks in Production
    #
    class Retract < Runbook
      require_relative 'common/changesets'
      require_relative 'retract/templates'

      extend Forwardable

      include Common::Changesets
      include Templates

      def_delegators :client, :images, :stacks

      def run
        report_template_dependencies

        detail do
          tp(free_templates, ['filename'])
        end

        remove_deployed_templates
      end

      private

      ##
      # run appropriate update function against deployed templates/stacks
      #
      def remove_deployed_templates
        free_templates.each(&method(:remove_deployed_template))
      end

      def remove_deployed_template(template)
        operation("Removing: #{template.name}") do
          checking { narrate_changes(client.changes_on_stack_delete(template, changeset_set)) }
          doing { client.delete_stack(template) }
        end
      end

      ##
      # report_undefined_image - provide list of undefined imports that block stack deployment
      #
      def report_template_dependencies
        diff = (templates - free_templates).map { |template| template.filename.to_s }
        error_on_dependencies(diff) if diff.any?
      end

      def error_on_dependencies(templates)
        puts '*** Unable to remove templates.'
        puts 'The following templates are dependencies for templates not marked for removal: ', templates
        exit 1
      end
    end
  end
end
