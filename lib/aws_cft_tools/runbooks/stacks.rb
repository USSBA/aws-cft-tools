# frozen_string_literal: true

module AwsCftTools
  module Runbooks
    ##
    # Images - report on available AMIs
    #
    # @example
    #   % aws-cli stacks              # list all known stacks
    #   % aws-cli stacks -e QA        # list all known stacks tagged for the QA environment
    #   % aws-cli stacks -e QA -r App # list all known stacks tagged for the QA environment and App role
    #
    class Stacks < Runbook::Report
      ###
      # @return [Array<AwsCftTools::Stack>]
      #
      def items
        client.stacks.sort_by(&method(:sort_key))
      end

      ###
      # @return [Array<String>]
      #
      def columns
        environment_column + role_column + %w[filename created_at name state]
      end

      private

      def sort_key(stack)
        stack.name
      end

      def environment_column
        options[:environment] ? [] : ['environment']
      end

      # :reek:NilCheck
      def role_column
        options[:roles]&.size == 1 ? [] : ['role']
      end
    end
  end
end
