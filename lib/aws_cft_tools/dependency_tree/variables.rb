# frozen_string_literal: true

module AwsCftTools
  class DependencyTree
    ##
    # Manage list of defined/undefined variables
    #
    class Variables
      attr_reader :undefined_variables, :defined_variables

      def initialize
        @undefined_variables = []
        @defined_variables = []
      end

      ##
      # Notes that the given variable name is provided either by the CloudFormation environment or by
      # another template.
      #
      # @param name [String]
      #
      def defined(name)
        @undefined_variables -= [name]
        @defined_variables |= [name]
      end

      ##
      # Notes that the given variable name is used as an input into a template.
      #
      # @param name [String]
      #
      def referenced(name)
        @undefined_variables |= [name] unless @defined_variables.include?(name)
      end
    end
  end
end
