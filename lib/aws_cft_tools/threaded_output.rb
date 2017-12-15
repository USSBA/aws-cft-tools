# frozen_string_literal: true

require 'forwardable'
require 'thread'

module AwsCftTools
  ##
  # Provides a way to process output and prefix with a thread identifier. The object is shared by
  # threads. Each thread should set its own prefix.
  #
  class ThreadedOutput
    extend Forwardable

    #
    # @param real_stdout [IO] The file object that should be written to with prefixed text.
    #
    def initialize(real_stdout)
      @stdout = real_stdout
      @buffer = Hash.new { |hash, key| hash[key] = '' }
      @semaphore = Mutex.new
    end

    def_delegator :@semaphore, :synchronize, :guarded
    def_delegators ThreadedOutput, :prefix

    ##
    # The prefix for output from the current thread.
    #
    def self.prefix
      Thread.current['output_prefix'] || ''
    end

    ##
    # @param prefix [String] The prefix for each line of text output by the calling thread.
    #
    def self.prefix=(prefix)
      Thread.current['output_prefix'] = prefix + ': '
    end

    ##
    # Ensure all buffered text is output. If any text is output, a newline is output as well.
    #
    def flush
      guarded { @stdout.puts prefix + buffer } if buffer != ''
      self.buffer = ''
    end

    ##
    # Write the string to the output with prefixes as appropriate. If the string does not end in a
    # newline, then the remaining text will be buffered until a newline is seen.
    #
    def write(string)
      print(string)
    end

    ##
    # Writes all of the arguments to the output with prefixes. Appends a newline to each argument.
    #
    # @param args [Array<String>]
    #
    def puts(*args)
      print(args.join("\n") + "\n")
    end

    ##
    # Writes all of the arugments to the output without newlines. Will output the prefix after each
    # newline.
    #
    # @param args [Array<String>]
    #
    def print(*args)
      append(args.join(''))
      printable_lines.each do |line|
        guarded { @stdout.puts prefix + line }
      end
    end

    private

    def printable_lines
      lines = buffer.split(/\n/)
      if buffer[-1..-1] == "\n"
        self.buffer = ''
      else
        self.buffer = lines.last
        lines = lines[0..-2]
      end
      lines
    end

    def buffer
      @buffer[prefix]
    end

    def append(value)
      @buffer[prefix] += value
    end

    def buffer=(string)
      @buffer[prefix] = string
    end
  end
end
