# frozen_string_literal: true

module AwsCftTools
  # Represents a change in a changeset.
  class DeletionChange < Change
    attr_reader :resource

    ###
    #
    # @param resource
    #
    def initialize(resource)
      @resource = resource
    end

    ###
    # Return the action taken. For deletion, this is always +DELETE+.
    #
    # @return [String] +'DELETE'+ to indicate a deletion
    #
    def action
      'DELETE'
    end

    ###
    # Return the status of this change as a replacement. For deletion, this is always +nil+.
    #
    # @return [nil]
    #
    def replacement
      nil
    end

    ###
    # Return the scopes of the change. For deletions, this is always +Resource+.
    #
    # @return [String] +'Resource'+
    #
    def scopes
      'Resource'
    end
  end
end
