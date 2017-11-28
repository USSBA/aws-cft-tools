# frozen_string_literal: true

require 'spec_helper'
require 'pathname'

RSpec.describe AwsCftTools::Runbooks::Hosts do
  let(:runbook) { described_class.new(config) }

  let(:env) {}
  let(:role) {}

  let(:config) do
    {
      role: role,
      environment: env
    }
  end

  describe 'with no environment or role selected' do
    it 'has a full set of columns' do
      expect(runbook.columns).to eq %w[public_ip private_ip environment role instance]
    end
  end

  describe 'with an environment but no role' do
    let(:env) { 'env' }

    it 'has all columns except environment' do
      expect(runbook.columns).to eq %w[public_ip private_ip role instance]
    end
  end

  describe 'with a role but no environment' do
    let(:role) { 'role' }

    it 'has all columns except role' do
      expect(runbook.columns).to eq %w[public_ip private_ip environment instance]
    end
  end

  describe 'with an environment and a role' do
    let(:env) { 'env' }
    let(:role) { 'role' }

    it 'has all columns except environment and role' do
      expect(runbook.columns).to eq %w[public_ip private_ip instance]
    end
  end
end
