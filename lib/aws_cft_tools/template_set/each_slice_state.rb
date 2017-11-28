# frozen_string_literal: true

module AwsCftTools
  class TemplateSet
    ##
    # Keeps track of state for the .each_slice(n) method.
    #
    class EachSliceState
      ##
      # @param slice_size [Integer] maximum number of templates to yield at once
      # @yield [Array<AwsCftTools::Template>]
      #
      def initialize(slice_size, &block)
        @seen = []
        @size = slice_size
        @slice = []
        @block = block
      end

      ##
      # Have all of the listed dependencies been seen in prior yields?
      #
      # @param deps [Array<String>]
      # @return [Boolean]
      #
      def fulfilled?(deps)
        (deps - @seen).empty?
      end

      ###
      # Add the template to the current slice and process the slice if it reaches the maximum slice size.
      #
      # @param template [AwsCftTools::Template]
      #
      def add_template(template, dependencies = [])
        process_slice unless fulfilled?(dependencies)
        unless fulfilled?(dependencies)
          raise AwsCftTools::UnsatisfiedDependencyError, "Unable to process #{template.filename}"
        end

        @slice << template

        process_slice if @slice.count == @size
      end

      ###
      # Pass the current slice through the block and reset for the next slice.
      #
      # @return [Integer] number of templates processed in this batch
      #
      def process_slice
        @block.call(@slice) if @slice.any?
        @seen |= @slice.map(&:filename).map(&:to_s)
        @slice = []
      end
    end
  end
end
