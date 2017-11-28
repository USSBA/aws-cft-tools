# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AwsCftTools::Runbooks::Diff do
  let(:runbook) { described_class.new(config) }

  let(:config) { {} }

  describe 'runs through the various context methods' do
    before do
      allow(context).to receive(:report_on_missing_templates).and_return(true)
      allow(context).to receive(:report_on_missing_stacks).and_return(true)
      allow(context).to receive(:report_on_differences).and_return(true)
      allow(AwsCftTools::Runbooks::Diff::Context).to receive(:new).and_return(context)
      allow(runbook.client).to receive(:templates).and_return([])
      allow(runbook.client).to receive(:stacks).and_return([])
    end

    let(:verbose) { :verbose }

    let(:context) { AwsCftTools::Runbooks::Diff::Context.new([], [], config) }

    it 'runs the report on missing templates' do
      runbook.run
      expect(context).to have_received(:report_on_missing_templates)
    end

    it 'runs the report on missing stacks' do
      runbook.run
      expect(context).to have_received(:report_on_missing_stacks)
    end

    it 'runs the report on differences' do
      runbook.run
      expect(context).to have_received(:report_on_differences)
    end
  end
end
