# frozen_string_literal: true

require 'spec_helper'
require 'pathname'

RSpec.describe AwsCftTools::TemplateSet do
  let(:template_set) { described_class.new(templates) }

  let(:templates) { [] }

  let(:vpc_template) { AwsCftTools::Template.new(vpc_template_filename, client_options) }
  let(:network_template) { AwsCftTools::Template.new(network_template_filename, client_options) }

  let(:env) { 'QA' }

  let(:client_options) do
    {
      region: 'us-east-1',
      environment: env,
      root: Pathname.new('/tmp'),
      template_dir: 'cloudformation/templates/',
      parameter_dir: 'cloudformation/parameters/'
    }
  end

  let(:vpc_template_path) do
    (
      client_options[:root] +
      client_options[:template_dir] +
      vpc_template_filename
    ).cleanpath
  end

  let(:vpc_template_filename) { Pathname.new('vpc/base.yaml') }

  let(:vpc_template_contents) do
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
          Value: '10.0.0.0/8'
          Export:
            Name: !Sub "${Environment}-vpc-cidr"
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
    EOF
  end

  let(:network_template_path) do
    (
      client_options[:root] +
      client_options[:template_dir] +
      network_template_filename
    ).cleanpath
  end

  let(:network_template_filename) { Pathname.new('network/vpc.yaml') }

  let(:network_template_contents) do
    <<~EOF
      ---
      AWSTemplateFormatVersion: "2010-09-09"
      Description: VPC Network definition.
      Metadata:
        Role: network
        DependsOn:
          Templates:
            - vpc/base.yaml
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
        SubnetAPublic:
          Value: !Ref USEast1APublicSubnet
          Export:
            Name: !Sub "${Environment}-subnet-a-public"
        SubnetBPublic:
          Value: !Ref USEast1BPublicSubnet
          Export:
            Name: !Sub "${Environment}-subnet-b-public"
      Resources:
        ###
        ### VPC Network Definition
        ###
        USEast1APublicSubnet:
          Type: "AWS::EC2::Subnet"
          Properties:
            AvailabilityZone: "us-east-1a"
            CidrBlock: !FindInMap [Environments, !Ref Environment, USEast1APublicSubnet]
            MapPublicIpOnLaunch: "true"
            Tags:
              - Key: Environment
                Value: !Ref Environment
              - Key: Name
                Value: !Sub "${Environment}-public-subnet-a"
              - Key: Role
                Value: vpc
            VpcId:
              Fn::ImportValue:
                !Sub "${Environment}-vpc"
        USEast1BPublicSubnet:
          Type: "AWS::EC2::Subnet"
          Properties:
            AvailabilityZone: "us-east-1b"
            CidrBlock: !FindInMap [Environments, !Ref Environment, USEast1BPublicSubnet]
            MapPublicIpOnLaunch: "true"
            Tags:
              - Key: Environment
                Value: !Ref Environment
              - Key: Name
                Value: !Sub "${Environment}-public-subnet-b"
              - Key: Role
                Value: vpc
            VpcId:
              Fn::ImportValue:
                !Sub "${Environment}-vpc"
    EOF
  end

  before do
    allow(IO).to receive(:read).with(vpc_template_path.to_path).and_return(vpc_template_contents)
    allow(IO).to receive(:read).with(network_template_path.to_path).and_return(network_template_contents)
    allow(FileTest).to receive(:exist?).and_return(false)
    allow(FileTest).to receive(:exist?).with(vpc_template_path.to_path).and_return(true)
    allow(FileTest).to receive(:exist?).with(network_template_path.to_path).and_return(true)
  end

  describe 'with no templates' do
    let(:templates) { [] }

    describe '#length' do
      it 'is zero' do
        expect(template_set.length).to eq 0
      end
    end

    it 'is empty' do
      expect(template_set).to be_empty
    end
  end

  describe 'with one template' do
    describe 'with no dependencies' do
      let(:templates) { [vpc_template] }

      it '#length is one' do
        expect(template_set.length).to eq 1
      end

      it '#undefined_variables is empty' do
        expect(template_set.undefined_variables).to be_empty
      end
    end

    describe 'missing a dependency' do
      let(:templates) { [network_template] }

      it '#length is one' do
        expect(template_set.length).to eq 1
      end

      it '#undefined_variables is not empty' do
        expect(template_set.undefined_variables).not_to be_empty
      end
    end
  end

  describe 'with both templates' do
    let(:templates) { [vpc_template, network_template] }

    describe '#length' do
      it 'is two' do
        expect(template_set.length).to eq 2
      end
    end

    describe '#undefined_variables' do
      it 'is empty' do
        expect(template_set.undefined_variables).to be_empty
      end
    end

    describe '#closure' do
      let(:closure) { template_set.closure(described_class.new([network_template])) }

      it 'finds the dependency' do
        expect(closure.length).to eq 2
      end
    end

    describe '#templates_for' do
      it 'finds the network template' do
        expect(template_set.templates_for([network_template.filename.to_s])).to eq [network_template]
      end
    end

    describe '#dependencies_for' do
      it 'finds the vpc template' do
        expect(template_set.dependencies_for(network_template)).to eq [vpc_template]
      end
    end

    describe '#dependents_for' do
      it 'finds the network template' do
        expect(template_set.dependents_for(vpc_template)).to eq [network_template]
      end
    end

    describe '#known_exports' do
      it 'saves the list' do
        template_set.known_exports = %w[foo bar]
        expect(template_set.known_exports).to eq %w[foo bar]
      end
    end
  end
end
