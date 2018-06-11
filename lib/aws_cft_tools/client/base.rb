# frozen_string_literal: true

module AwsCftTools
  class Client
    ##
    # = CloudFormation Client
    #
    # All of the business logic behind direct interaction with the AWS API for CloudFormation templates
    # and stacks.
    #
    class Base
      attr_reader :options

      ##
      #
      # @param options [Hash] client configuration
      # @option options [String] :environment the operational environment in which to act
      # @option options [String] :profile the AWS credential profile to use
      # @option options [String] :region the AWS region in which to act
      #
      def initialize(options = {})
        @options = options
      end

      ##
      # The AWS SDK client object for this part of the AwsCftTools client
      # :reek:NilCheck
      def aws_client
        @aws_client ||= begin
          self.class.aws_client_class&.new(
            region: options[:region],
            profile: options[:profile]
          )
        end
      end

      def self.aws_client_class; end
    end
  end
end
