# frozen_string_literal: true

module AwsCftTools
  class Client
    ##
    # = CloudFormation Client
    #
    # All of the business logic behind direct interaction with the AWS API for CloudFormation templates
    # and stacks.
    #
    class CFT < Base
      require_relative 'cft/changeset_management'
      require_relative 'cft/stack_management'

      include ChangesetManagement
      include StackManagement

      ##
      #
      # @param options [Hash] client configuration
      # @option options [String] :environment the operational environment in which to act
      # @option options [String] :profile the AWS credential profile to use
      # @option options [String] :region the AWS region in which to act
      #
      def initialize(options)
        super(options)
      end

      def self.aws_client_class
        Aws::CloudFormation::Client
      end

      ##
      # Lists all exports from stacks in CloudFormation.
      #
      # @return [Array<Aws::CloudFormation::Types::Export>]
      #
      def exports
        @exports ||= AWSEnumerator.new(aws_client, :list_exports, {}, &:exports).to_a
      end

      ##
      # Lists all of the stacks in CloudFormation that are specific to the selected environment.
      #
      # @return [Array<OpenStruct>]
      #
      def stacks
        @stacks ||= all_stacks.select do |stack|
          tags = stack.tags
          satisfies_environment(tags) &&
            satisfies_role(tags) &&
            satisfies_tags(tags)
        end
      end

      ##
      # List all of the stacks in CloudFormation.
      #
      # @return [Array<OpenStruct>]
      #
      def all_stacks
        @all_stacks ||= AWSEnumerator.new(aws_client, :describe_stacks, &method(:map_stacks)).to_a
      end

      private

      def map_stacks(resp)
        resp.stacks.map { |stack| Stack.new(stack, aws_client) }
      end

      def satisfies_environment(tag_set)
        env = options[:environment]
        !env || tag_set['Environment'] == env
      end

      # :reek:FeatureEnvy
      def satisfies_role(tag_set)
        roles = options[:roles] || []
        roles.empty? || roles.include?(tag_set['Role'])
      end

      def satisfies_tags(tag_set)
        tags = options[:tags]
        return true unless tags
        tag_set.all? { |key, value| satisfies_tag(tags, key, value) }
      end

      def satisfies_tag(tags, key, value)
        tag = tags[key]
        !tag || tag == value
      end
    end
  end
end
