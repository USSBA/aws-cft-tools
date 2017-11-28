# frozen_string_literal: true

module AwsCftTools
  class TemplateSet
    ##
    # Closure-related functions for a TemplateSet.
    #
    module Closure
      ##
      # Provides the given templates and any from the set that those templates depend on.
      #
      # @param templates [Array<AwsCftTools::Template>]
      # @return [AwsCftTools::TemplateSet]
      #
      def closure(templates)
        templates_for(
          calculate_closure(templates.filenames) { |template| @dependency_tree.dependencies_for(template) }
        )
      end

      ##
      # Provides a list of filenames holding the source for the templates in a set.
      #
      # @return [Array<String>]
      #
      def filenames
        map(&:filename).map(&:to_s)
      end

      ##
      # Provides the subset of the given templates that have no dependent templates outside the set.
      #
      # @param templates [AwsCftTools::TemplateSet]
      # @return [AwsCftTools::TemplateSet]
      #
      def closed_subset(templates)
        templates_for(@dependency_tree.closed_subset(templates.filenames))
      end

      ##
      # @param folders [Array<String>]
      # @return [AwsCftTools::TemplateSet]
      #
      def in_folder_order(folders)
        proper_ordered_set, set = folders.reduce([clone, []]) do |memo, folder|
          set, proper_ordered_set = memo
          selected = closure(templates_in_folder(set, folder)) - proper_ordered_set
          [set - selected, proper_ordered_set | selected]
        end

        proper_ordered_set | set
      end

      private

      def templates_in_folder(set, folder)
        set.select { |template| template.filename.to_s.start_with?(folder + '/') }
      end

      def calculate_closure(set, &block)
        stack = set.clone

        stack += closure_step(stack.shift, set, &block) while stack.any?
        set
      end

      def closure_step(template, set)
        [].tap do |stack|
          (yield(template) - set).each do |depedency|
            stack << depedency
            set.unshift(depedency)
          end
        end
      end
    end
  end
end
