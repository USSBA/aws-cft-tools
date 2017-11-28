# frozen_string_literal: true

require 'spec_helper'
require 'pathname'

RSpec.describe AwsCftTools::Runbooks::Deploy do
  let(:runbook) { described_class.new(config) }

  let(:env) { 'test' }

  let(:role) {}

  let(:noop) {}
  let(:check) {}
  let(:verbose) {}
  let(:template_filenames) { [] }

  let(:config) do
    {
      region: 'us-east-1',
      role: role,
      environment: env,
      root: Pathname.new('/tmp'),
      template_dir: 'cloudformation/templates/',
      parameter_dir: 'cloudformation/parameters/',
      template_folder_priorities: %w[vpcs network],
      noop: noop,
      check: check,
      verbose: verbose,
      templates: template_filenames,
      environment_successors: {
        'test' => 'staging',
        'staging' => 'production'
      }
    }
  end

  let(:vpc_base_template_filename) { 'vpcs/base.json' }

  let(:vpc_base_template) do
    AwsCftTools::Template.new(
      vpc_base_template_filename,
      config.merge(
        template_content: <<~EOF
          {
            "Metadata": {
              "Role": "vpc"
            },
            "Parameters": {
              "Environment": {
                "AllowedValues": ["test"]
              }
            }
          }
        EOF
      )
    )
  end

  let(:vpc_network_template_filename) { 'network/vpc.yaml' }

  let(:vpc_network_template) do
    AwsCftTools::Template.new(
      vpc_network_template_filename,
      config.merge(
        template_content: <<~EOF
          ---
          Metadata:
            Role: network
            DependsOn:
              Templates:
                - vpcs/base.json
          Parameters:
            Environment:
              AllowedValues:
                - test
        EOF
      )
    )
  end

  before do
    allow(FileTest).to receive(:exist?).and_return(false)
    allow(FileTest).to receive(:exist?).with('/tmp/cloudformation/templates/vpcs/base.json')
                                       .and_return(true)
    allow(FileTest).to receive(:exist?).with('/tmp/cloudformation/templates/network/vpc.yaml')
                                       .and_return(true)
  end

  describe 'in noop mode' do
    let(:noop) { true }

    let(:all_templates) do
      AwsCftTools::TemplateSet.new([
                                     vpc_base_template,
                                     vpc_network_template
                                   ])
    end

    before do
      allow(runbook).to receive(:deployed_stack_names).and_return(["#{env}-base-vpcs"])
      allow(runbook.client).to receive(:templates).and_return(all_templates)
      allow(runbook.client).to receive(:images).and_return([])
      allow(runbook.client).to receive(:create_stack).and_return(true)
      allow(runbook.client).to receive(:update_stack).and_return(true)
      allow(runbook.client).to receive(:changes_on_stack_update).and_return([])
      allow(runbook.client).to receive(:changes_on_stack_create).and_return([])
    end

    it 'outputs (noop) in narrative' do
      expect { runbook.run }.to output(/\(noop\)/).to_stdout
    end

    it 'does not call an update method' do
      runbook.run
      expect(runbook.client).not_to have_received(:update_stack)
    end

    it 'does not call a create template method' do
      runbook.run
      expect(runbook.client).not_to have_received(:create_stack)
    end
  end

  describe 'not in noop or check mode' do
    let(:noop) { false }
    let(:check) { false }

    let(:all_templates) do
      AwsCftTools::TemplateSet.new([
                                     vpc_base_template,
                                     vpc_network_template
                                   ])
    end

    before do
      allow(runbook).to receive(:deployed_stack_names).and_return(["#{env}-base-vpcs"])
      allow(runbook.client).to receive(:templates).and_return(all_templates)
      allow(runbook.client).to receive(:images).and_return([])
      allow(runbook.client).to receive(:create_stack).and_return(true)
      allow(runbook.client).to receive(:update_stack).and_return(true)
      allow(runbook.client).to receive(:changes_on_stack_update).and_return([])
      allow(runbook.client).to receive(:changes_on_stack_create).and_return([])
    end

    describe 'in verbose mode' do
      let(:verbose) { true }

      it 'prints out a list of template filenames' do
        expect { runbook.run }.to output(/test-base-vpcs.+test-vpc-network/m).to_stdout
      end
    end

    it 'does not output (noop) in narrative' do
      expect { runbook.run }.not_to output(/\(noop\)/).to_stdout
    end

    it 'does call a create method' do
      runbook.run
      expect(runbook.client).to have_received(:create_stack)
    end

    it 'does call an update method' do
      runbook.run
      expect(runbook.client).to have_received(:update_stack)
    end

    it 'does not call a changeset on update method' do
      runbook.run
      expect(runbook.client).not_to have_received(:changes_on_stack_update)
    end

    it 'does not call a changeset on create method' do
      runbook.run
      expect(runbook.client).not_to have_received(:changes_on_stack_create)
    end
  end

  describe 'in check mode' do
    let(:check) { true }

    let(:all_templates) do
      AwsCftTools::TemplateSet.new([
                                     vpc_base_template,
                                     vpc_network_template
                                   ])
    end

    before do
      allow(runbook).to receive(:deployed_stack_names).and_return(["#{env}-base-vpcs"])
      allow(runbook.client).to receive(:templates).and_return(all_templates)
      allow(runbook.client).to receive(:images).and_return([])
      allow(runbook.client).to receive(:create_stack).and_return(true)
      allow(runbook.client).to receive(:update_stack).and_return(true)
      allow(runbook.client).to receive(:changes_on_stack_update).and_return([])
      allow(runbook.client).to receive(:changes_on_stack_create).and_return([])
    end

    it 'does not call a create template method' do
      runbook.run
      expect(runbook.client).not_to have_received(:create_stack)
    end

    it 'does not call an update stack method' do
      runbook.run
      expect(runbook.client).not_to have_received(:update_stack)
    end

    it 'does call a changeset on update method' do
      runbook.run
      expect(runbook.client).to have_received(:changes_on_stack_update)
    end

    it 'does call a changeset on create method' do
      runbook.run
      expect(runbook.client).to have_received(:changes_on_stack_create)
    end
  end

  describe '#successor_environment' do
    it 'goes from testing to staging' do
      expect(runbook.send(:successor_environment, 'test')).to eq 'staging'
    end

    it 'has no successor for production' do
      expect(runbook.send(:successor_environment, 'production')).to be_nil
    end
  end

  describe '#find_image' do
    let(:image_a) do
      OpenStruct.new(
        environment: 'test',
        role: 'foo',
        image_id: 'image_a',
        created_at: '2010-01-01'
      )
    end

    let(:image_b) do
      OpenStruct.new(
        environment: 'production',
        role: 'foo',
        image_id: 'image_b',
        created_at: '2011-01-01'
      )
    end

    let(:image_c) do
      OpenStruct.new(
        environment: 'staging',
        role: 'bar',
        image_id: 'image_c',
        created_at: '2012-01-01'
      )
    end

    before do
      allow(runbook).to receive(:images).and_return([image_a, image_b, image_c])
    end

    it 'finds the right image for staging foo' do
      expect(runbook.send(:find_image, 'foo', 'production')).to eq 'image_b'
    end

    it 'finds no image for production bar' do
      expect(runbook.send(:find_image, 'bar', 'production')).to be_nil
    end

    it 'finds the right image for test bar' do
      expect(runbook.send(:find_image, 'bar', 'test')).to eq 'image_c'
    end
  end

  describe '#update_template_with_image_id' do
    let(:image_a) do
      OpenStruct.new(
        environment: 'test',
        role: 'foo',
        image_id: 'image_a',
        created_at: '2010-01-01'
      )
    end

    let(:image_b) do
      OpenStruct.new(
        environment: 'production',
        role: 'foo',
        image_id: 'image_b',
        created_at: '2011-01-01'
      )
    end

    let(:image_c) do
      OpenStruct.new(
        environment: 'staging',
        role: 'bar',
        image_id: 'image_c',
        created_at: '2012-01-01'
      )
    end

    let(:template) do
      AwsCftTools::Template.new(
        'application/foo.json',
        config.merge(
          parameters_content: (
            <<~EOP
              ---
              default: &default
                FooImageId:
                  Role: foo
              staging:
                <<: *default
              demo:
                <<: *default
            EOP
          ),
          template_content:
            <<~EOF
              {
                "Metadata": {
                  "Role": "foo"
                },
                "Parameters": {
                  "FooImageId": {
                    "Type": "String"
                  }
                }
              }
            EOF
        )
      )
    end

    let(:env) { 'staging' }

    before do
      allow(runbook).to receive(:images).and_return([image_a, image_b, image_c])
    end

    it 'populates the template parameters with the right image' do
      runbook.send(:update_template_with_image_id, template)
      expect(template.parameters['FooImageId']).to eq 'image_b'
    end

    describe 'with no matching image' do
      let(:env) { 'demo' }

      it 'prints an error' do
        expect do
          runbook.send(:update_template_with_image_id, template)
        end.to output(/Unable to find image/).to_stdout
      end
    end
  end

  describe '#templates' do
    before do
      allow(runbook.client).to receive(:templates).and_return(all_templates)
    end

    describe 'with no templates' do
      let(:all_templates) do
        AwsCftTools::TemplateSet.new([])
      end

      it 'returns an empty set' do
        expect(runbook.templates).to be_empty
      end
    end

    describe 'with templates and no role' do
      let(:all_templates) do
        AwsCftTools::TemplateSet.new([
                                       vpc_base_template,
                                       vpc_network_template
                                     ])
      end

      let(:role) {}

      it 'returns a non-empty set' do
        expect(runbook.templates).not_to be_empty
      end

      it 'returns all of the templates' do
        expect(runbook.templates.length).to eq all_templates.length
      end
    end

    describe 'with templates and a filename for a template dependent on another' do
      let(:all_templates) do
        AwsCftTools::TemplateSet.new([
                                       vpc_base_template,
                                       vpc_network_template
                                     ])
      end

      let(:template_filenames) { [vpc_network_template_filename] }

      let(:env) { 'test' }

      it 'returns a non-empty set' do
        expect(runbook.templates).not_to be_empty
      end

      it 'returns both templates' do
        expect(runbook.templates.length).to eq 2
      end
    end

    describe 'with templates and a filename for a template not dependent on another' do
      let(:all_templates) do
        AwsCftTools::TemplateSet.new([
                                       vpc_base_template,
                                       vpc_network_template
                                     ])
      end

      let(:template_filenames) { [vpc_base_template_filename] }

      let(:env) { 'test' }

      it 'returns a non-empty set' do
        expect(runbook.templates).not_to be_empty
      end

      it 'returns one template' do
        expect(runbook.templates.length).to eq 1
      end

      it 'returns the right template' do
        expect(runbook.templates.first.filename.to_s).to eq vpc_base_template_filename
      end
    end

    describe 'with templates and a role' do
      let(:all_templates) do
        AwsCftTools::TemplateSet.new([
                                       vpc_base_template,
                                       vpc_network_template
                                     ])
      end

      let(:role) { 'vpc' }

      it 'returns a non-empty set' do
        expect(runbook.templates).not_to be_empty
      end

      it 'returns a single template' do
        expect(runbook.templates.length).to eq 1
      end

      it 'returns the right template' do
        expect(runbook.templates.first.filename).to eq vpc_base_template.filename
      end
    end
  end
end
