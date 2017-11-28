# frozen_string_literal: true

module AwsCftTools
  module Runbooks
    ##
    # Hosts - report on EC2 instances
    #
    # @example
    #   % aws-cli hosts                  # list all known EC2 instances
    #   % aws-cli hosts -e QA            # list all known EC2 instances in the QA environment
    #   % aws-cli hosts -r Bastion -e QA # list all known Bastion hosts in the QA environment
    #
    class Hosts < Runbook::Report
      ###
      # @return [Array<OpenStruct>]
      #
      def items
        client.instances.sort_by(&method(:sort_key))
      end

      ###
      # @return [Array<String>]
      #
      def columns
        %w[public_ip private_ip] + environment_column + role_column + ['instance']
      end

      private

      def sort_key(host)
        [host.environment, host.role, host.ip].compact
      end

      def environment_column
        options[:environment] ? [] : ['environment']
      end

      def role_column
        options[:role] ? [] : ['role']
      end
    end
  end
end
