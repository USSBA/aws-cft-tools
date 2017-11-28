# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AwsCftTools::Client::EC2 do
  let(:client) { described_class.new(client_options) }

  let(:client_options) do
    {
      region: 'us-east-1'
    }
  end

  let(:mocked_client) { double }

  before do
    allow(Aws::EC2::Resource).to receive(:new).and_return(mocked_client)
  end

  describe 'filters' do
    let(:client_options) do
      {
        region: 'us-east-1',
        environment: 'foo',
        role: 'bar',
        tags: { 'Team' => 'baz' }
      }
    end

    describe '#tag_filters' do
      it 'gets the right tags' do
        expect(client.send(:tag_filters)).to eq [
          { name: 'tag:Environment', values: ['foo'] },
          { name: 'tag:Role', values: ['bar'] },
          { name: 'tag:Team', values: ['baz'] }
        ]
      end
    end

    describe '#image_filters' do
      let(:expected_tags) do
        [
          { name: 'state', values: ['available'] },
          { name: 'tag:Environment', values: ['foo'] },
          { name: 'tag:Role', values: ['bar'] },
          { name: 'tag:Team', values: ['baz'] }
        ]
      end

      it 'gets the right tags' do
        expect(client.send(:image_filters)).to eq expected_tags
      end
    end

    describe '#instance_filters' do
      let(:expected_tags) do
        [
          { name: 'instance-state-name', values: ['running'] },
          { name: 'tag:Environment', values: ['foo'] },
          { name: 'tag:Role', values: ['bar'] },
          { name: 'tag:Team', values: ['baz'] }
        ]
      end

      it 'gets the right tags' do
        expect(client.send(:instance_filters)).to eq expected_tags
      end
    end
  end

  describe '#images' do
    let(:mocked_client) do
      client = double
      allow(client).to receive(:images).and_return(image_results)
      client
    end

    context 'with no images' do
      let(:image_results) { [] }

      it 'returns an empty list' do
        expect(client.images).to be_empty
      end
    end

    context 'with images' do
      let(:ctime) { Time.now.to_s }

      let(:image_results) do
        [
          OpenStruct.new(image_id: 'AMI123',
                         image_type: 'machine',
                         public: false,
                         state: 'available',
                         creation_date: ctime,
                         tags: [
                           OpenStruct.new(key: 'Role', value: 'foo'),
                           OpenStruct.new(key: 'Environment', value: 'bar')
                         ])
        ]
      end

      let(:mapped_image) do
        OpenStruct.new(
          image_id: 'AMI123',
          type: 'machine',
          public: false,
          created_at: ctime,
          role: 'foo',
          environment: 'bar',
          tags: {}
        )
      end

      it 'returns a list of the correct length' do
        expect(client.images.length).to eq image_results.length
      end

      it 'returns a list with the right items' do
        expect(client.images).to eq [mapped_image]
      end
    end
  end

  describe '#instances' do
    let(:mocked_client) do
      client = double
      allow(client).to receive(:instances).and_return(host_results)
      client
    end

    context 'with no instances' do
      let(:host_results) { [] }

      it 'returns an empty list' do
        expect(client.instances).to be_empty
      end
    end

    context 'with instances' do
      let(:host_results) do
        [
          OpenStruct.new(private_ip_address: '127.0.0.1',
                         public_ip_address: '128.0.0.2',
                         instance_id: 'i819203948576',
                         tags: [
                           OpenStruct.new(key: 'Role', value: 'foo'),
                           OpenStruct.new(key: 'Environment', value: 'bar'),
                           OpenStruct.new(key: 'Team', value: 'baz')
                         ])
        ]
      end

      let(:mapped_host) do
        OpenStruct.new(
          private_ip: '127.0.0.1',
          public_ip: '128.0.0.2',
          instance: 'i819203948576',
          role: 'foo',
          environment: 'bar',
          tags: { 'Team' => 'baz' }
        )
      end

      it 'returns a list with the correct length' do
        expect(client.instances.length).to eq host_results.length
      end

      it 'returns a list with the right items' do
        expect(client.instances).to eq [mapped_host]
      end
    end
  end
end
