# frozen_string_literal: true

require 'diffy'

module AwsCftTools
  module Runbooks
    ##
    # Images - report on available AMIs
    #
    # @example
    #   % aws-cli diff -e QA        # list the differences between deployed and local definitions for QA
    #   % aws-cli diff -e QA -r App # list the differences between deployed and local definitions for
    #                               # the App role in QA
    #
    class Diff < Runbook
      require_relative 'diff/context'

      def run
        context = Context.new(client.stacks, client.templates, options)

        # now match them up
        context.report_on_missing_templates
        context.report_on_missing_stacks
        context.report_on_differences
      end
    end
  end
end
