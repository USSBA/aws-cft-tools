# frozen_string_literal: true

require_relative 'each_slice_state'

module AwsCftTools
  class TemplateSet
    ##
    # Simple derived information about templates.
    #
    module Dependencies
      ##
      # @param template [AwsCftTools::Template]
      # @param variable [#to_s]
      def provided(template, variable)
        @dependency_tree.provided(template.filename.to_s, variable.to_s)
      end

      ##
      # @param template [AwsCftTools::Template]
      # @param variable [#to_s]
      def required(template, variable)
        @dependency_tree.required(template.filename.to_s, variable.to_s)
      end

      ##
      # @param from [AwsCftTools::Template]
      # @param to [AwsCftTools::Template]
      #
      def linked(from, to)
        @dependency_tree.linked(from.filename.to_s, to.filename.to_s)
      end

      ##
      # Iterates through the sorted list and yields an array of templates with no unsatisfied dependencies,
      # up to the maximum slice size.
      #
      # @param maximum_slice_size [Integer]
      # @yield [Array<AwsCftTools::Template>] up to +maximum_slice_size+ templates with no unsatisfied
      #   dependencies
      #
      def each_slice(maximum_slice_size, &block)
        return unless block_given?
        # we want to start at the beginning and get up to <n> items for which all prior dependencies have
        # already been returned in a prior call
        state = EachSliceState.new(maximum_slice_size, &block)

        each do |template|
          state.add_template(template, @dependency_tree.dependencies_for(template.filename.to_s))
        end
        # catch the last templates
        state.process_slice
      end
    end
  end
end
