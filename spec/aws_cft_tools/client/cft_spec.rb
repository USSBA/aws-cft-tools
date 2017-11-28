# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AwsCftTools::Client::CFT do
  let(:client) { described_class.new(client_options) }

  let(:env) { 'testing' }
  let(:role) { 'Tasting' }

  let(:client_options) do
    {
      region: 'us-east-1',
      environment: env
    }
  end

  let(:mocked_client) { double }

  before do
    allow(Aws::CloudFormation::Client).to receive(:new).and_return(mocked_client)
  end

  describe '#exports' do
    let(:first_export_result) do
      OpenStruct.new(
        next_token: second_export_token,
        exports: %i[a c e]
      )
    end

    let(:second_export_token) { 'second-export-token' }

    let(:second_export_result) do
      OpenStruct.new(
        next_token: nil,
        exports: %i[b d]
      )
    end

    let(:mocked_client) do
      client = double
      allow(client).to receive(:list_exports).and_return(first_export_result)
      allow(client).to receive(:list_exports)
        .with(next_token: second_export_token).and_return(second_export_result)
      client
    end

    it 'returns the full exported list' do
      expect(client.exports).to eq(%i[a c e b d])
    end
  end

  describe '#stacks' do
    let(:first_stack_result) do
      OpenStruct.new(
        next_token: second_stack_token,
        stacks: [
          OpenStruct.new(
            tags: [
              OpenStruct.new(key: 'Environment', value: env),
              OpenStruct.new(key: 'Role', value: role)
            ],
            stack_name: 'stack-1'
          ),
          OpenStruct.new(
            tags: [
              OpenStruct.new(key: 'Environment', value: 'not-' + env),
              OpenStruct.new(key: 'Role', value: role)
            ],
            stack_name: 'stack-2'
          )
        ]
      )
    end

    let(:second_stack_token) { 'second-export-token' }

    let(:second_stack_result) do
      OpenStruct.new(
        next_token: nil,
        stacks: [
          OpenStruct.new(
            tags: [
              OpenStruct.new(key: 'Environment', value: env),
              OpenStruct.new(key: 'Role', value: 'not-' + role)
            ],
            stack_name: 'stack-3'
          ),
          OpenStruct.new(
            tags: [OpenStruct.new(key: 'Environment', value: 'not-' + env)],
            stack_name: 'stack-4'
          ),
          OpenStruct.new(
            tags: [OpenStruct.new(key: 'Role', value: role)],
            stack_name: 'stack-5'
          )
        ]
      )
    end

    let(:mocked_client) do
      client = double
      allow(client).to receive(:describe_stacks).and_return(first_stack_result)
      allow(client).to receive(:describe_stacks)
        .with(next_token: second_stack_token).and_return(second_stack_result)
      client
    end

    describe 'filtered by environment' do
      let(:client_options) do
        {
          region: 'us-east-1',
          environment: env
        }
      end

      it 'returns the full exported list' do
        expect(client.stacks.map(&:name)).to eq(%w[stack-1 stack-3])
      end
    end

    describe 'filtered by role' do
      let(:client_options) do
        {
          region: 'us-east-1',
          role: role
        }
      end

      it 'returns the right stacks' do
        expect(client.stacks.map(&:name)).to eq(%w[stack-1 stack-2 stack-5])
      end
    end
  end
end
