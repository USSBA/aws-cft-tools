# frozen_string_literal: true

module AwsCftTools
  module Runbooks
    class Deploy
      ##
      # module with methods to manage threading
      #
      module Threading
        private

        def create_threads(list, &_block)
          list.map { |item| Thread.new { yield item } }
        end
      end
    end
  end
end
