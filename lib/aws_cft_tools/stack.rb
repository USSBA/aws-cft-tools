# frozen_string_literal: true

module AwsCftTools
  ##
  # Provides a unified interface for accessing information about deployed CloudFormation templates.
  #
  class Stack
    extend Forwardable

    def initialize(aws_stack, aws_client)
      @aws_client = aws_client
      @aws_stack = aws_stack
    end

    def_delegators :@aws_stack, :description
    def_delegator :@aws_stack, :stack_name, :name
    def_delegator :@aws_stack, :creation_time, :created_at
    def_delegator :@aws_stack, :last_updated_time, :updated_at
    def_delegator :@aws_stack, :stack_status, :state
    def_delegator :@aws_stack, :stack_id, :id

    ###
    # @return [String] the unparsed body of the template definition
    #
    def template_source
      @template ||= begin
        resp = @aws_client.get_template(stack_name: name,
                                        template_stage: 'Original')
        resp.template_body
      end
    end

    ##
    # @return [Hash] dictionary of tag names and values for the stack
    #
    def tags
      @tags ||= @aws_stack.tags.each_with_object({}) { |tag, hash| hash[tag.key] = tag.value }
    end

    ##
    # @return [Hash] mapping of output name with output definition
    def outputs
      @outputs ||= build_hashes(@aws_stack.outputs || [], &:output_key)
    end

    ##
    # @return [Hash] mapping of parameter name to parameter definition
    #
    def parameters
      @parameters ||= build_hashes(@aws_stack.parameters || [], &:parameter_key)
    end

    ##
    # @return [String] the environment of the stack
    #
    def environment
      tags['Environment']
    end

    ##
    # @return [String] the role of the stack
    #
    def role
      tags['Role']
    end

    ##
    # @return [String] the filename of the stack's template source
    #
    def filename
      @filename ||= begin
        source = tags['Source']
        source ? source.sub(%r{^/+}, '') : nil
      end
    end

    private

    def build_hashes(source, &block)
      source.map(&block).zip(source).to_h
    end
  end
end
