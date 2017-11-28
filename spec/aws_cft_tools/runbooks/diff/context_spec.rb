# frozen_string_literal: true

require 'spec_helper'
require 'pathname'
require 'fileutils'

RSpec.describe AwsCftTools::Runbooks::Diff::Context do
  let(:context) { described_class.new(stacks, templates, config) }

  let(:config) do
    {
      verbose: verbose
    }
  end

  let(:verbose) { true }

  describe 'with no stacks or templates' do
    let(:stacks) { [] }
    let(:templates) { [] }

    it 'prints nothing for missing templates' do
      expect { context.report_on_missing_templates }.not_to output.to_stdout
    end

    it 'prints nothing for missing stacks' do
      expect { context.report_on_missing_stacks }.not_to output.to_stdout
    end

    it 'prints nothing for differences' do
      expect { context.report_on_differences }.not_to output.to_stdout
    end
  end

  describe 'with stacks and no templates' do
    let(:stacks) do
      [OpenStruct.new(
        name: stack_name
      )]
    end

    let(:templates) { [] }

    let(:stack_name) { 'stack_-_name' }

    it 'prints a list of stacks with no templates' do
      expect { context.report_on_missing_templates }.to output(/\b#{stack_name}\b/).to_stdout
    end

    it 'prints nothing for missing stacks' do
      expect { context.report_on_missing_stacks }.not_to output.to_stdout
    end

    it 'prints nothing for differences' do
      expect { context.report_on_differences }.not_to output.to_stdout
    end
  end

  describe 'with templates and no stacks' do
    let(:stacks) do
      []
    end

    let(:templates) do
      [
        OpenStruct.new(
          name: stack_name,
          filename: filename
        )
      ]
    end

    let(:stack_name) { 'stack_-_name' }
    let(:filename) { 'template-filename' }

    it 'prints nothing for missing templates' do
      expect { context.report_on_missing_templates }.not_to output.to_stdout
    end

    it 'prints a list of templates with no stacks' do
      expect { context.report_on_missing_stacks }.to output(/\b#{filename}\b/).to_stdout
    end

    it 'prints nothing for differences' do
      expect { context.report_on_differences }.not_to output.to_stdout
    end
  end

  describe 'with templates and stacks with no differences' do
    let(:stacks) do
      [
        OpenStruct.new(
          name: stack_name,
          filename: filename,
          template_source: template_content
        )
      ]
    end

    let(:templates) do
      [
        OpenStruct.new(
          name: stack_name,
          filename: filename,
          template_type: 'yaml',
          template_source_for_aws: template_content
        )
      ]
    end

    let(:stack_name) { 'stack_-_name' }

    let(:filename) { 'template-filename' }

    let(:template_content) do
      <<~EOF
        ---
        AWSTemplateFormatVersion: 'foo-bar-baz'
        EOF
    end

    it 'prints nothing for missing templates' do
      expect { context.report_on_missing_templates }.not_to output.to_stdout
    end

    it 'prints nothing for missing stacks' do
      expect { context.report_on_missing_stacks }.not_to output.to_stdout
    end

    it 'prints the filename as having no changes' do
      expect { context.report_on_differences }.to output(/\bno changes:.*\b#{filename}\b/m).to_stdout
    end
  end

  describe 'with templates and stacks with differences' do
    let(:stacks) do
      [
        OpenStruct.new(
          name: stack_name,
          filename: filename,
          template_source: stack_template_content
        )
      ]
    end

    let(:templates) do
      [
        OpenStruct.new(
          name: stack_name,
          filename: filename,
          template_type: 'yaml',
          template_source_for_aws: file_template_content
        )
      ]
    end

    let(:stack_name) { 'stack_-_name' }

    let(:filename) { 'template-filename' }

    let(:stack_template_content) do
      <<~EOF
        ---
        AWSTemplateFormatVersion: 'foo-bar-baz'
        EOF
    end

    let(:file_template_content) do
      <<~EOF
        ---
        AWSTemplateFormatVersion: 'foo-bar-bat'
        EOF
    end

    it 'prints nothing for missing templates' do
      expect { context.report_on_missing_templates }.not_to output.to_stdout
    end

    it 'prints nothing for missing stacks' do
      expect { context.report_on_missing_stacks }.not_to output.to_stdout
    end

    describe 'not in verbose mode' do
      let(:verbose) { false }
      let(:report) { context.report_on_differences }

      it 'prints nothing about no changes' do
        expect { report }.not_to output(/\bno changes:/m).to_stdout
      end

      it 'prints the name of the changed template when not verbose' do
        expect { report }.to output(/\bwith changes:.*\b#{filename}\b/m).to_stdout
      end

      it 'does not print the changes when not verbose' do
        expect { report }.not_to output(/foo-bar-bat/m).to_stdout
      end
    end

    describe 'in verbose mode' do
      let(:verbose) { true }
      let(:report) { context.report_on_differences }

      it 'prints nothing about no changes' do
        expect { report }.not_to output(/\bno changes:/m).to_stdout
      end

      it 'does not print "with changes" in verbose' do
        expect { report }.not_to output(/\bwith changes:/).to_stdout
      end

      it 'prints the changed lines in verbose' do
        expect { report }.to output(/\bfoo-bar-baz\b.*\bfoo-bar-bat\b/m).to_stdout
      end

      it 'prints the name of the template file @ AWS in verbose' do
        expect { report }.to output(/\b#{filename} @ AWS/m).to_stdout
      end

      it 'prints the name of the template file @ Local in verbose' do
        expect { report }.to output(/\b#{filename} @ Local/m).to_stdout
      end
    end
  end
end
