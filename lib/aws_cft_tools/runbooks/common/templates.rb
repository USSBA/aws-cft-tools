# frozen_string_literal: true

module AwsCftTools
  module Runbooks
    module Common
      ##
      # Templates - operations on templates in multiple runbooks
      #
      module Templates
        private

        def filtered_templates(set)
          filtered_by_environment(
            filtered_by_role(
              filtered_by_selection(options[:templates], set)
            )
          )
        end

        def filtered_by_role(set)
          set.select { |template| template.role?(options[:role]) }
        end

        def filtered_by_environment(set)
          set.select { |template| template.environment?(options[:environment]) }
        end

        def filtered_by_selection(templates, set)
          if templates && templates.any?
            set.select { |template| templates.include?(template.filename.to_s) }
          else
            set
          end
        end
      end
    end
  end
end
