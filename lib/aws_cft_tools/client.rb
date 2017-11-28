# frozen_string_literal: true

require 'aws-sdk'
require 'forwardable'

module AwsCftTools
  ##
  # = AWS Tools Client
  #
  # A collection of higher-level business methods built on top of the AWS API.
  #
  class Client
    require_relative 'client/base'
    require_relative 'client/ec2'
    require_relative 'client/cft'
    require_relative 'client/templates'

    extend Forwardable

    ##
    # Create a new client instance.
    #
    # Options are passed on to domain-specific client objects within the +AwsCftTools::Client::+ namespace.
    #
    # @param options [Hash] client configuration
    # @option options [String] :environment Environment with which the client is concerned.
    # @option options [String] :parameter_dir The location of parameter files within the project.
    # @option options [String] :profile The profile to use from the shared credentials file.
    # @option options [String] :region The AWS region in which to operate.
    # @option options [String] :role The role that resources are attached to.
    # @option options [Pathname] :root The location of the top-level directory of the project.
    # @option options [String] :template_dir The location of tmeplate files within the project.
    #
    def initialize(options)
      @client_options = options.merge(client: self)
    end

    # @!method instances
    #   @see AwsCftTools::Client::EC2#instances
    # @!method images
    #   @see AwsCftTools::Client::EC2#images
    def_delegators :ec2_client, :instances, :images

    # @!method exports
    #   @see AwsCftTools::Client::CFT#exports
    # @!method stacks
    #   @see AwsCftTools::Client::CFT#stacks
    # @!method create_stack
    #   @see AwsCftTools::Client::CFT::StackManagement#create_stack
    # @!method delete_stack
    #   @see AwsCftTools::Client::CFT::StackManagement#delete_stack
    # @!method update_stack
    #   @see AwsCftTools::Client::CFT::StackManagement#update_stack
    # @!method all_stacks
    #   @see AwsCftTools::Client::CFT#all_stacks
    # @!method changes_on_stack_update
    #   @see AwsCftTools::Client::CFT::ChangesetManagement#changes_on_stack_update
    # @!method changes_on_stack_delete
    #   @see AwsCftTools::Client::CFT::ChangesetManagement#changes_on_stack_delete
    # @!method changes_on_stack_create
    #   @see AwsCftTools::Client::CFT::ChangesetManagement#changes_on_stack_create
    def_delegators :cft_client, :exports, :stacks, :create_stack, :update_stack, :all_stacks,
                   :changes_on_stack_update, :changes_on_stack_create, :changes_on_stack_delete,
                   :delete_stack

    # @!method templates
    #   @see AwsCftTools::Client::Templates#templates
    def_delegators :template_client, :templates

    private

    def ec2_client
      @ec2_client ||= AwsCftTools::Client::EC2.new(@client_options)
    end

    def cft_client
      @cft_client ||= AwsCftTools::Client::CFT.new(@client_options)
    end

    def template_client
      @template_client ||= AwsCftTools::Client::Templates.new(@client_options)
    end
  end
end
