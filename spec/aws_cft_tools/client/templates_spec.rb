# frozen_string_literal: true

require 'spec_helper'
require 'pathname'

RSpec.describe AwsCftTools::Client::Templates do
  let(:client) { AwsCftTools::Client.new(client_options).send(:template_client) }

  let(:env) { 'testing' }

  let(:client_options) do
    {
      region: 'us-east-1',
      environment: env,
      root: Pathname.new('/tmp'),
      template_dir: 'cloudformation/templates',
      parameter_dir: 'cloudformation/parameters'
    }
  end

  let(:template_path) do
    (
      client_options[:root] +
      client_options[:template_dir] +
      template_filename
    ).cleanpath
  end
  let(:template_filename) { Pathname.new('vpc/base.yaml') }

  let(:template_contents) do
    <<~EOF
      ---
      AWSTemplateFormatVersion: "2010-09-09"
      Description: VPC definition.
      Metadata:
        Role: vpc
      Parameters:
        Environment:
          Description: "Enter QA, Staging, or Production. Default is QA."
          Type: String
          Default: QA
          AllowedValues:
            - QA
            - Staging
            - Production
      Outputs:
        VPC:
          Value: !Ref VPC
          Export:
            Name: !Sub "${Environment}-vpc"
        VPCCidr:
          Value: !FindInMap [Environments, !Ref Environment, VPCCidr]
          Export:
            Name: !Sub "${Environment}-vpc-cidr"
        PublicAcl:
          Value: !Ref PublicNetworkAcl
          Export:
            Name: !Sub "${Environment}-public-acl"
        PrivateAcl:
          Value: !Ref PrivateNetworkAcl
          Export:
            Name: !Sub "${Environment}-private-acl"
      Mappings:
        Environments:
          QA:
            VPCCidr: "10.1.0.0/16"
          Staging:
            VPCCidr: "10.2.0.0/16"
          Production:
            VPCCidr: "10.3.0.0/16"
      Resources:
        ###
        ### VPC Definition
        ###
        VPC:
          Type: "AWS::EC2::VPC"
          Properties:
            CidrBlock: !FindInMap [Environments, !Ref Environment, VPCCidr]
            EnableDnsHostnames: "false"
            Tags:
              - Key: Environment
                Value: !Ref Environment
              - Key: Name
                Value: !Sub "${Environment}-vpc"
              - Key: Role
                Value: vpc
              - Key: Foo
                Value:
                  Fn::ImportValue:
                    !Sub "${Environment}-sub-vpc-output"
        PublicNetworkAcl:
          Type: AWS::EC2::NetworkAcl
          Properties:
            VpcId: !Ref VPC
            Tags:
              - Key: Name
                Value: !Sub "${Environment}-public-acl"
              - Key: Network
                Value: Public
              - Key: Role
                Value: vpc
        PrivateNetworkAcl:
          Type: AWS::EC2::NetworkAcl
          Properties:
            VpcId: !Ref VPC
            Tags:
              - Key: Name
                Value: !Sub "${Environment}-private-acl"
              - Key: Network
                Value: Private
              - Key: Role
                Value: vpc
    EOF
  end

  let(:mocked_client) { double }

  before do
    allow(IO).to receive(:read).with(template_path.to_path).and_return(template_contents)
    allow(FileTest).to receive(:exist?).and_return(false)
    allow(FileTest).to receive(:exist?).with(template_path.to_path).and_return(true)
    allow(Pathname).to receive(:glob)
      .with(client_options[:root] + client_options[:template_dir] + '**/*')
      .and_return([template_path])

    allow(Aws::CloudFormation::Client).to receive(:new).and_return(mocked_client)
    allow(mocked_client).to receive(:list_exports).and_return(OpenStruct.new(
                                                                exports: []
    ))
  end

  describe '#templates' do
    describe 'for QA' do
      let(:env) { 'QA' }

      it 'returns a single template' do
        expect(client.templates.length).to eq 1
      end

      it 'returns the right template' do
        expect(client.templates.map(&:name)).to eq ['QA-base-vpc']
      end
    end

    describe 'for UnknownEnvironment' do
      let(:env) { 'UnknownEnvironment' }

      it 'returns no templates' do
        expect(client.templates.length).to eq 0
      end
    end
  end
end
