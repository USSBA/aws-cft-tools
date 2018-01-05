# frozen_string_literal: true

require 'spec_helper'
require 'pathname'

RSpec.describe AwsCftTools::Template do
  let(:template) { described_class.new(template_filename, client_options) }

  let(:env) { 'testing' }

  let(:client_options) do
    {
      region: 'us-east-1',
      environment: env,
      root: Pathname.new('/tmp'),
      template_dir: 'cloudformation/templates/',
      parameter_dir: 'cloudformation/parameters/'
    }
  end

  let(:template_path) do
    (
      client_options[:root] +
      client_options[:template_dir] +
      template_filename
    ).cleanpath
  end

  before do
    allow(IO).to receive(:read).with(template_path.to_path).and_return(template_contents)
    allow(FileTest).to receive(:exist?).and_return(false)
    allow(FileTest).to receive(:exist?).with(template_path.to_path).and_return(true)
  end

  describe 'templates without an outputs section' do
    let(:template_filename) { Pathname.new('vpc/base.yaml') }

    let(:template_contents) do
      <<~EOF
        ---
        AWSTemplateFormatVersion: "2010-09-09"
        Parameters:
          Environment:
            Description: "Enter QA, Staging, or Production. Default is QA."
            Type: String
            Default: QA
            AllowedValues:
              - QA
              - Staging
              - Production
      EOF
    end

    describe '#outputs' do
      it 'reflects the lack of outputs in the template' do
        expect(template.outputs).to be_empty()
      end
    end
  end

  describe 'yaml templates' do
    let(:template_filename) { Pathname.new('vpc/base.yaml') }

    let(:template_contents) do
      <<~EOF
        ---
        AWSTemplateFormatVersion: "2010-09-09"
        Description: VPC definition.
        Metadata:
          Role: vpc
          DependsOn:
            Templates:
              - some/template.yaml
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

    describe '#role' do
      it 'reflects the value in the template' do
        expect(template.role).to eq 'vpc'
      end
    end

    describe '#allowed_environments' do
      it 'reflects the values in the template' do
        expect(template.allowed_environments).to eq %w[QA Staging Production]
      end
    end

    describe '#template_dependencies' do
      it 'reflects the values in the template' do
        expect(template.template_dependencies).to eq %w[some/template.yaml]
      end
    end

    describe '#outputs' do
      it 'reflects the values in the template' do
        expect(template.outputs).to eq %w[
          testing-vpc testing-vpc-cidr
          testing-public-acl testing-private-acl
        ]
      end
    end

    describe '#inputs' do
      it 'reflects the values in the template' do
        expect(template.inputs).to eq ['testing-sub-vpc-output']
      end
    end

    describe '#name' do
      it 'reflects the filename' do
        expect(template.name).to eq "#{env}-base-vpc"
      end
    end

    describe '#stack_parameters' do
      let(:parameters) do
        [{
          parameter_key: 'Environment',
          parameter_value: env,
          use_previous_value: false
        }]
      end

      let(:tags) do
        [
          { key: 'Environment', value: env },
          { key: 'Source', value: '/' + template.filename.to_s },
          { key: 'Role', value: 'vpc' }
        ]
      end

      let(:expected_stack_parameters) do
        {
          stack_name: template.name,
          template_body: template_contents,
          parameters: parameters,
          tags: tags
        }
      end

      it 'has parameters' do
        expect(template.stack_parameters).to eq expected_stack_parameters
      end
    end
  end

  describe 'json templates' do
    let(:template_filename) { Pathname.new('vpc/base.json') }

    let(:template_contents) do
      <<~EOF
        {
          "AWSTemplateFormatVersion": "2010-09-09",
          "Description": "VPC definition",
          "Metadata": {
            "Role": "vpc",
            "DependsOn": {
              "Templates": [
                  "some/template.yaml"
              ]
            }
          },
          "Parameters": {
            "Environment": {
              "Description": "Enter QA, Staging, or Production. Default is QA.",
              "Type": "String",
              "Default": "QA",
              "AllowedValues": ["QA", "Staging", "Production"]
            }
          },
          "Outputs": {
            "VPC": {
              "Value": { "Ref": "VPC" },
              "Export": {
                "Name": { "Sub": "${Environment}-vpc" }
              }
            },
            "VPCCidr": {
              "Value": { "FindInMap": ["Environments", {"Ref": "Environment"}, "VPCCidr"] },
              "Export": {
                "Name": { "Sub": "${Environment}-vpc-cidr" }
              }
            },
            "PublicAcl": {
              "Value": { "Ref": "PublicNetworkAcl" },
              "Export": {
                "Name": { "Sub": "${Environment}-public-acl" }
              }
            },
            "PrivateAcl": {
              "Value": { "Ref": "PrivateNetworkAcl" },
              "Export": {
                "Name": { "Sub": "${Environment}-private-acl" }
              }
            }
          },
          "Resources": {
            "VPC": {
              "Type": "AWS::EC2::VPC",
              "Properties": {
                "Tags": [
                  {"Key": "Environment", "Value": {"Ref": "Environment"}},
                  {"Key": "Name", "Value": {"Sub": "${Environment}-vpc"}},
                  {"Key": "Role", "Value": "vpc"},
                  {"Key": "Foo", "Value": {"Fn::ImportValue": {"Sub": "${Environment}-sub-vpc-output"}}}
                ]
              }
            }
          }
        }
      EOF
    end

    describe '#role' do
      it 'reflects the value in the template' do
        expect(template.role).to eq 'vpc'
      end
    end

    describe '#allowed_environments' do
      it 'reflects the values in the template' do
        expect(template.allowed_environments).to eq %w[QA Staging Production]
      end
    end

    describe '#template_dependencies' do
      it 'reflects the values in the template' do
        expect(template.template_dependencies).to eq %w[some/template.yaml]
      end
    end

    describe '#outputs' do
      it 'reflects the values in the template' do
        expect(template.outputs).to eq %w[
          testing-vpc testing-vpc-cidr
          testing-public-acl testing-private-acl
        ]
      end
    end

    describe '#inputs' do
      it 'reflects the values in the template' do
        expect(template.inputs).to eq ['testing-sub-vpc-output']
      end
    end

    describe '#name' do
      it 'reflects the filename' do
        expect(template.name).to eq "#{env}-base-vpc"
      end
    end
  end

  describe 'ruby dsl templates' do
    let(:template_filename) { Pathname.new('vpc/base.rb') }

    let(:template_contents) do
      <<~EOF
        # frozen_string_literal: true

        template do
          value AWSTemplateFormatVersion: '2010-09-09'
          value Description: 'VPC definition'
          metadata 'Role', 'vpc'
          metadata 'DependsOn',
                   Templates: ['some/template.yaml']
          parameter 'Environment',
                    Description: 'Enter QA, Staging, or Production. Default is QA.',
                    Type: 'String',
                    Default: 'QA',
                    AllowedValues: %w[QA Staging Production]
          output 'VPC',
                 Value: ref('VPC'),
                 Export: {
                   Name: sub('${Environment}-vpc')
                 }
          output 'VPCCidr',
                 Value: find_in_map('Environments', ref('Environment'), 'VPCCidr'),
                 Export: {
                   Name: sub('${Environment}-vpc-cidr')
                 }
          output 'PublicAcl',
                 Value: ref('PublicNetworkAcl'),
                 Export: {
                   Name: sub('${Environment}-public-acl')
                 }
          output 'PrivateAcl',
                 Value: ref('PrivateNetworkAcl'),
                 Export: {
                   Name: sub('${Environment}-private-acl')
                 }
          resource 'VPC', Type: 'AWS::EC2::VPC', Properties: {
            Tags: [
              {
                Key: 'Environment',
                Value: ref('Environment')
              },
              {
                Key: 'Name',
                Value: sub('${Environment}-vpc')
              },
              { Key: 'Role', Value: 'vpc' },
              {
                Key: 'Foo',
                Value: import_value(sub('${Environment}-sub-vpc-output'))
              }
            ]
          }
        end
      EOF
    end

    describe '#role' do
      it 'reflects the value in the template' do
        expect(template.role).to eq 'vpc'
      end
    end

    describe '#allowed_environments' do
      it 'reflects the values in the template' do
        expect(template.allowed_environments).to eq %w[QA Staging Production]
      end
    end

    describe '#template_dependencies' do
      it 'reflects the values in the template' do
        expect(template.template_dependencies).to eq %w[some/template.yaml]
      end
    end

    describe '#outputs' do
      it 'reflects the values in the template' do
        expect(template.outputs).to eq %w[
          testing-vpc testing-vpc-cidr
          testing-public-acl testing-private-acl
        ]
      end
    end

    describe '#inputs' do
      it 'reflects the values in the template' do
        expect(template.inputs).to eq ['testing-sub-vpc-output']
      end
    end

    describe '#name' do
      it 'reflects the filename' do
        expect(template.name).to eq "#{env}-base-vpc"
      end
    end
  end
end
