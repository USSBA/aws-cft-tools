# frozen_string_literal: true

module AwsCftTools
  module Runbooks
    class Deploy
      ##
      # module with methods to manage ordering of templates
      #
      module Templates
        ##
        # list the templates in-scope for this deployment
        #
        def templates
          @templates ||= begin
            candidates = client.templates

            candidates.closure(
              filtered_templates(
                candidates
              )
            )
          end
        end

        def template_folder_order
          options[:template_folder_priorities] || []
        end

        private

        def templates_in_folder_order
          templates.in_folder_order(template_folder_order)
        end
      end
    end
  end
end
