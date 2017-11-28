# frozen_string_literal: true

module AwsCftTools
  class TemplateSet
    ##
    # Array methods that need to be overridden to work well with template sets.
    #
    module ArrayMethods
      ##
      # create a new template set holding templates in either set without duplicates
      #
      # Note that this is identical to `|`.
      #
      # @param other [AwsCftTools::TemplateSet]
      # @return [AwsCftTools::TemplateSet]
      #
      def +(other)
        self.class.new(super(other).uniq(&:name)).tap do |union|
          union.known_exports = @known_exports
        end
      end

      ##
      # create a new template set holding templates in either set without duplicates
      #
      # @param other [AwsCftTools::TemplateSet]
      # @return [AwsCftTools::TemplateSet]
      #
      def |(other)
        self + other
      end

      ##
      # create a new template set holding templates in the first set not in the second
      #
      # @param other [AwsCftTools::TemplateSet]
      # @return [AwsCftTools::TemplateSet]
      #
      def -(other)
        forbidden_names = other.map(&:name)
        clone.replace_list(
          reject { |template| forbidden_names.include?(template.name) }
        )
      end

      ##
      # @return [AwsCftTools::TemplateSet]
      # @yield [AwsCftTools::Template]
      #
      def select
        return unless block_given?
        clone.replace_list(super)
      end

      protected

      def replace_list(new_list)
        self[0..size - 1] = new_list
        self
      end
    end
  end
end
