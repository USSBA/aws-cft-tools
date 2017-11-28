# frozen_string_literal: true

module AwsCftTools
  module Runbooks
    class Deploy
      ##
      # module with methods to manage threading
      #
      module Threading
        private

        # FIXME: things don't always work out well when capturing output
        #        for now, we don't, and output gets mangled a bit when running with
        #        multiple jobs in parallel
        def with_captured_stdout(capture)
          old_stdout = $stdout
          old_table_io = TablePrint::Config.io
          TablePrint::Config.io = $stdout = capture
          yield
        ensure
          $stdout = old_stdout
          TablePrint::Config.io = old_table_io
        end

        def create_threads(list, &_block)
          list.map { |item| threaded_process { yield item } }
        end

        def threaded_process(&block)
          output = StringIO.new
          thread = Thread.new { with_captured_stdout(output, &block) }
          OpenStruct.new(output: output, thread: thread)
        end
      end
    end
  end
end
