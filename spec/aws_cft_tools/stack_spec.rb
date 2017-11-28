# frozen_string_literal: true

require 'spec_helper'
require 'pathname'

RSpec.describe AwsCftTools::Stack do
  let(:stack) { described_class.new(aws_stack, aws_client) }

  let(:aws_stack) do
    OpenStruct.new(
      outputs: [OpenStruct.new(output_key: :foo), OpenStruct.new(output_key: :bar)],
      parameters: [OpenStruct.new(parameter_key: :foop), OpenStruct.new(parameter_key: :barp)]
    )
  end

  let(:aws_client) do
    OpenStruct.new
  end

  it 'has outputs as a hash with the right' do
    expect(stack.outputs).to include(:bar, :foo)
  end

  it 'has parameters as a hash with the right keys' do
    expect(stack.parameters).to include(:barp, :foop)
  end
end
