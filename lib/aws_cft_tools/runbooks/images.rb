# frozen_string_literal: true

module AwsCftTools
  module Runbooks
    ##
    # Images - report on available AMIs
    #
    # @example
    #   % aws-cli images              # list all known AMIs
    #   % aws-cli images -e QA        # list all known AMIs tagged for the QA environment
    #   % aws-cli images -e QA -r App # list all known AMIs tagged for the QA environment and App role
    #
    class Images < Runbook::Report
      ###
      # @return [Array<OpenStruct>]
      #
      def items
        client.images.sort_by(&method(:sort_key))
      end

      ###
      # @return [Array<String>]
      #
      def columns
        environment_column + role_column + %w[created_at public type image_id]
      end

      private

      def sort_key(image)
        [image.environment, image.role, image.created_at].compact
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
