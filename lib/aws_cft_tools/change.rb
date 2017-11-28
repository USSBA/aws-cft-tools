# frozen_string_literal: true

require 'forwardable'

module AwsCftTools
  # Represents a change in a changeset.
  class Change
    extend Forwardable

    attr_reader :resource

    # @param change [Aws::CloudFormation::Types::Change] The AWS SDK change object to be wrapped.
    def initialize(change)
      @resource = change.resource_change
    end

    def_delegators :resource, :action, :replacement
    def_delegator :resource, :logical_resource_id, :logical_id
    def_delegator :resource, :physical_resource_id, :physical_id

    ###
    #
    # @return [String] human readable type of resource being changed
    #
    # @example EC2::Network::ACL
    #
    #   "ec2 network acl"
    #
    def type
      humanize_camelized(resource.resource_type)
    end

    ###
    #
    # @return [String] a comma-separated list of scopes
    #
    def scopes
      resource.scope.sort.join(', ')
    end

    ###
    #
    # @return [Hash] information useful for creating a tabular report
    #
    def to_narrative
      {
        action: action,
        logical_id: logical_id,
        physical_id: physical_id,
        type: type,
        scopes: scopes,
        replacement: replacement
      }
    end

    protected

    def humanize_camelized(string)
      string.sub(/^AWS::/, '')
            .gsub(/:+/, ' ')
            .gsub(/([A-Z]+)([A-Z][a-z])/, '\1 \2')
            .gsub(/([a-z\d])([A-Z])/, '\1 \2')
            .downcase
    end
  end
end
