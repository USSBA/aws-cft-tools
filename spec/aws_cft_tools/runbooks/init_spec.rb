# frozen_string_literal: true

require 'spec_helper'
require 'pathname'
require 'fileutils'

RSpec.describe AwsCftTools::Runbooks::Init do
  let(:runbook) { described_class.new(config) }

  let(:noop) {}
  let(:check) {}
  let(:verbose) {}

  let(:config) do
    {
      region: 'us-east-1',
      root: Pathname.new('/tmp'),
      config_file: '.aws_cft_for_testing',
      template_dir: 'cloudformation/templates/',
      parameter_dir: 'cloudformation/parameters/',
      noop: noop,
      check: check,
      verbose: verbose
    }
  end

  describe 'in noop mode' do
    let(:noop) { true }

    before do
      allow(FileUtils).to receive(:mkpath) # for dirname.mkpath
      allow(IO).to receive(:write) # for filename.write(...)
    end

    it 'outputs (noop) in narrative' do
      expect { runbook.run }.to output(/\(noop\)/).to_stdout
    end

    it 'does not create directories' do
      runbook.run
      expect(FileUtils).not_to have_received(:mkpath)
    end

    it 'does not write file contents' do
      runbook.run
      expect(IO).not_to have_received(:write)
    end
  end

  describe 'in regular mode' do
    let(:noop) { false }
    let(:file_exists) { false }

    let(:directories) do
      [
        %w[cloudformation/templates cloudformation/parameters],
        %w[vpcs networks security data-services data-resources applications]
      ].inject([]) { |set, acc| acc.product(set) }
        .map { |parts| '/tmp/' + parts.join('/') }
    end

    before do
      allow(FileUtils).to receive(:mkpath).and_return(true) # for dirname.mkpath
      allow(IO).to receive(:write).and_return(true) # for filename.write(...)
      allow(FileTest).to receive(:exist?).and_return(file_exists)
    end

    it 'does not output (noop) to stdout' do
      expect { runbook.run }.not_to output(/\(noop\)/).to_stdout
    end

    it 'makes directories' do
      runbook.run
      directories.each do |directory|
        expect(FileUtils).to have_received(:mkpath).with(directory)
      end
    end

    describe 'with no config file yet' do
      it 'writes the configuration file' do
        runbook.run
        expect(IO).to have_received(:write).once
      end
    end

    describe 'with config file already on file system' do
      let(:file_exists) { true }

      it 'does not write a config file' do
        runbook.run
        expect(IO).not_to have_received(:write)
      end
    end
  end
end
