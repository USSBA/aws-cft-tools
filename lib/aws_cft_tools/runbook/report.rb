# frozen_string_literal: true

require 'table_print'

module AwsCftTools
  class Runbook
    ##
    # A subclass of the Runbook designed for reporting out status or other information about resources.
    #
    class Report < Runbook
      def run
        tp(items, columns)
      end

      ###
      # @return [Array<Object>]
      #
      def items
        []
      end

      ###
      # @return [Array<String>]
      #
      def columns
        []
      end
    end
  end
end
