# frozen_string_literal: true

module AwsCftTools
  module Runbooks
    class Retract
      ##
      # module with methods to manage ordering of templates
      #
      module Templates
        require_relative '../common/templates'

        include Common::Templates

        ##
        # list the templates in-scope for this retraction
        #
        # @return [AwsCftTools::TemplateSet]
        #
        def templates
          @templates ||= filtered_templates(client.templates)
        end

        ##
        # List the templates that are available for deletion.
        #
        # Templates with known dependents that are not in the set will be removed. Note that this does
        # not capture dependencies between environments.
        #
        # @return [AwsCftTools::TemplateSet]
        def free_templates
          deployed = client.stacks.map(&:name)
          universe = AwsCftTools::TemplateSet.new(client.templates.select do |template|
            deployed.include?(template.name)
          end)
          universe.closed_subset(templates).reverse
        end

        ##
        # @return [Array<String>]
        #
        def template_folder_order
          options[:template_folder_priorities] || []
        end
      end
    end
  end
end
