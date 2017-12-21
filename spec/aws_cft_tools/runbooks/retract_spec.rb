# frozen_string_literal: true

require 'spec_helper'
require 'pathname'

RSpec.describe AwsCftTools::Runbooks::Retract do
  let(:runbook) { described_class.new(config) }

  let(:env) { 'test' }

  let(:role) {}

  let(:noop) {}
  let(:check) {}

  let(:config) do
    {
      region: 'us-east-1',
      role: role,
      environment: env,
      templates: [],
      noop: noop,
      check: check,
      root: Pathname.new('/tmp'),
      template_dir: 'cloudformation/templates/',
      parameter_dir: 'cloudformation/parameters/'
    }
  end

  let(:vpc_base_template) do
    AwsCftTools::Template.new(
      'vpcs/base.yaml',
      config.merge(
        template_content: <<~EOF
          ---
          Metadata:
            Role: vpc
          Parameters:
            Environment:
              AllowedValues:
                - test
        EOF
      )
    )
  end

  let(:vpc_network_template) do
    AwsCftTools::Template.new(
      'network/vpc.yaml',
      config.merge(
        template_content: <<~EOF
          ---
          Metadata:
            Role: network
            DependsOn:
              Templates:
                - vpcs/base.yaml
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
    allow(FileTest).to receive(:exist?).with('/tmp/cloudformation/templates/vpcs/base.yaml')
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

    let(:all_stacks) do
      all_templates.to_a.map do |template|
        OpenStruct.new(
          name: template.name
        )
      end
    end

    before do
      allow(runbook).to receive(:deployed_filenames).and_return(['vpcs/base.yaml'])
      allow(runbook.client).to receive(:stacks).and_return(all_stacks)
      allow(runbook.client).to receive(:templates).and_return(all_templates)
      allow(runbook.client).to receive(:images).and_return([])
      allow(runbook.client).to receive(:exports).and_return([])
      allow(runbook.client).to receive(:create_stack).and_return(true)
      allow(runbook.client).to receive(:update_stack).and_return(true)
      allow(runbook.client).to receive(:delete_stack).and_return(true)
      allow(runbook.client).to receive(:changes_on_stack_update).and_return([])
      allow(runbook.client).to receive(:changes_on_stack_create).and_return([])
    end

    it 'outputs (noop) in narrative' do
      expect { runbook.run }.to output(/\(noop\)/).to_stdout
    end

    it 'does not call a delete method' do
      runbook.run
      expect(runbook.client).not_to have_received(:delete_stack)
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
        expect(runbook.templates.length).to eq 2
      end
    end

    describe 'with templates and a role' do
      let(:all_templates) do
        AwsCftTools::TemplateSet.new([
                                       vpc_base_template,
                                       vpc_network_template
                                     ])
      end

      let(:role) { 'network' }

      it 'returns a non-empty set' do
        expect(runbook.templates).not_to be_empty
      end

      it 'returns a single template' do
        expect(runbook.templates.length).to eq 1
      end

      it 'returns the right template' do
        expect(runbook.templates.first.filename).to eq vpc_network_template.filename
      end
    end
  end

  describe '#free_templates' do
    let(:all_stacks) do
      all_templates.to_a.map do |template|
        OpenStruct.new(
          name: template.name
        )
      end
    end

    before do
      allow(runbook.client).to receive(:stacks).and_return(all_stacks)
      allow(runbook.client).to receive(:templates).and_return(all_templates)
    end

    describe 'with no templates' do
      let(:all_templates) do
        AwsCftTools::TemplateSet.new([])
      end

      it 'returns an empty set' do
        expect(runbook.free_templates).to be_empty
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
        expect(runbook.free_templates).not_to be_empty
      end

      it 'returns all of the templates' do
        expect(runbook.free_templates.length).to eq 2
      end
    end

    describe 'with templates and a specific leaf role' do
      let(:all_templates) do
        AwsCftTools::TemplateSet.new([
                                       vpc_base_template,
                                       vpc_network_template
                                     ])
      end

      let(:role) { 'network' }

      it 'returns a single template in the set' do
        expect(runbook.free_templates.length).to eq 1
      end

      it 'returns the network template' do
        expect(runbook.free_templates).to eq [vpc_network_template]
      end
    end

    describe 'with templates and a specific embedded role' do
      let(:all_templates) do
        AwsCftTools::TemplateSet.new([
                                       vpc_base_template,
                                       vpc_network_template
                                     ])
      end

      let(:role) { 'vpc' }

      it 'has a template in the list to look for' do
        expect(runbook.templates).to eq [vpc_base_template]
      end

      it 'returns no templates in the set for removal' do
        expect(runbook.free_templates).to be_empty
      end
    end

    describe 'with undeployed leaf templates' do
      let(:all_templates) do
        AwsCftTools::TemplateSet.new([
                                       vpc_base_template,
                                       vpc_network_template
                                     ])
      end
      
      let(:all_stacks) do
        [
          OpenStruct.new(name: vpc_base_template.name)
        ]
      end

      it 'returns a template in the set for removal' do
        expect(runbook.free_templates).to eq [vpc_base_template]
      end
    end
  end
end
