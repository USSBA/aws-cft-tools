# frozen_string_literal: true

module AwsCftTools
  ##
  # This is the base class for runbooks.
  #
  # A runbook is a command that can be accessed via the `aws-cft` script. A runbook is implemented as a
  # subclass of this class.
  #
  # == Callbacks
  # The AwsCftTools::CLI uses callbacks to manage runbook-specific options and behaviors.
  #
  # == Helpers
  #
  # The various helpers make managing logic flow much easier. Rather than having to be aware of how the
  # different modes (+verbose+, +change+, +noop+) interplay and are configured, you can use the
  # methods in this section to annotate the flow with your intent.
  #
  # @abstract Subclass and override {.default_options}, {.options}, and {#run} to implement
  #   a custom Runbook class.
  class Runbook
    require_relative 'runbook/report'

    ##
    # The AwsCftTools::Client instance used by the runbook.
    #
    attr_reader :client

    ##
    # The configuration options passed in to the runbook.
    #
    attr_reader :options

    ##
    # Recognized configuration options depend on the runbook but include any options valid for
    # AwsCftTools::Client.
    #
    # Modes are selected by various configuration options:
    #
    # +:verbose+:: provide more narrative as the runbook executes
    # +:noop+:: do nothing that could modify state
    # +:change+:: do nothing that could permanently modify state, though some modifications are permitted
    #  in order to examine what might change if permanent changes were made
    #
    # @param configuration [Hash] Various options passed to the AwsCftTools::Client.
    # @return AwsCftTools::Runbook
    #
    def initialize(configuration = {})
      @options = configuration
      @client = AwsCftTools::Client.new(options)
    end

    # @!group Callbacks

    ##
    # A callback to implement the runbook actions. Nothing is passed in or returned.
    #
    # @return void
    #
    def run; end

    ##
    # An internal wrapper around +#run+ to catch credential errors and print a useful message.
    #
    def _run
      run
    rescue Aws::Errors::MissingCredentialsError
      puts 'Unable to access AWS without valid credentials. Either define a default credential' \
      ' profile or use the -p option to specify an AWS credential profile.'
    end

    # @!group Helpers

    ##
    # @param description [String] an optional description of the operation
    # @yield runs the block if not in +noop+ mode
    # @return void
    #
    # Defines an operation that may or may not be narrated and that should not be run if in +noop+ mode.
    #
    # @example
    #   operation("considering the change" ) do
    #     checking("seeing what changes") { check_what_changes }
    #     doing("committing the change") { make_the_change }
    #   end
    #
    def operation(description = nil)
      narrative(description)
      return if options[:noop]

      yield if block_given?
    end

    ##
    # @param description [String] an optional description of the check
    # @yield runs the block if in +check+ mode and not in +noop+ mode
    # @return void
    #
    # Runs the given block when in +check+ mode and not in +noop+ mode. Outputs the description if the
    # block is run.
    #
    # @example (see #operation)
    #
    def checking(description = nil)
      return if options[:noop] || !options[:check]
      output(description)
      yield if block_given?
    end

    ##
    # @param description [String] an optional description of the action
    # @yield runs the block if not in +check+ or +noop+ mode
    # @return void
    #
    # Runs the given block when not in +check+ or +noop+ mode. Outputs the description if the block is run.
    #
    # @example (see #operation)
    #
    def doing(description = nil)
      return if options[:noop] || options[:check]
      output(description)
      yield if block_given?
    end

    ##
    # @param description [String] an optional narrative string
    # @return void
    #
    # Prints out the given description to stdout. If in +noop+ mode, +" (noop)"+ is appended.
    #
    def narrative(description = nil)
      return unless description
      if options[:noop]
        puts "#{description} (noop)"
      else
        puts description
      end
    end

    ##
    # @param description [String] an optional verbose description
    # @yield runs the block if in +verbose+ mode
    # @return void
    #
    # Prints out the given description and runs the block if in +verbose+ mode. This is useful if the
    # verbose narrative might be computationally expensive.
    #
    # @example
    #    detail do
    #      ... run some extensive processing to summarize stuff
    #      puts "The results are #{interesting}."
    #    end
    #
    def detail(description = nil)
      return unless options[:verbose]
      output(description)
      yield if block_given?
    end

    private

    def output(description)
      puts description if description
    end
  end
end
