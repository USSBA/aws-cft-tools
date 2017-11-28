# frozen_string_literal: true

module AwsCftTools
  module Runbooks
    module Common
      ##
      # Changesets - operations on changesets in the deploy runbook
      #
      module Changesets
        private

        # @todo store this somewhere so we can have an "active" changeset to be reviewed and committed.
        #
        def changeset_set
          @changeset_set ||= SecureRandom.hex(16)
        end

        ##
        # provide a tabular report of changeset actions
        #
        def narrate_changes(changes)
          tp(
            changes.map(&:to_narrative),
            %i[action logical_id physical_id type replacement scopes]
          )
        end
      end
    end
  end
end
