# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AwsCftTools::Runbook::Report do
  let(:report) { described_class.new({}) }

  describe 'without items or subclassing' do
    it 'has no items' do
      expect(report.items).to eq []
    end

    it 'has no columns' do
      expect(report.columns).to eq []
    end
  end

  describe 'with items' do
    let(:items) do
      [{ a: 1, b: 2 }, { a: 3, b: 4 }]
    end

    let(:columns) do
      %w[a b]
    end

    before do
      allow(report).to receive(:items).and_return(items)
      allow(report).to receive(:columns).and_return(columns)
      allow(report).to receive(:tp).and_return(0)
    end

    describe '#run' do
      it 'calls #items' do
        report.run
        expect(report).to have_received(:items)
      end

      it 'calls #columns' do
        report.run
        expect(report).to have_received(:columns)
      end

      it 'outputs the column names' do
        report.run
        expect(report).to have_received(:tp).with(items, columns)
      end
    end
  end

  describe '#_run' do
    before do
      allow(report).to receive(:run)
    end

    it 'calls #run' do
      report._run
      expect(report).to have_received(:run)
    end
  end

  describe '#_run without credentials' do
    before do
      allow(report).to receive(:run).and_raise(Aws::Errors::MissingCredentialsError)
    end

    it 'reports out an error' do
      expect { report._run }.to output(/without valid credentials/).to_stdout
    end
  end
end
