# frozen_string_literal: true

require 'spec_helper'
require 'pathname'

RSpec.describe AwsCftTools::Runbooks::Stacks do
  let(:runbook) { described_class.new(config) }

  let(:constant_columns) { %w[filename created_at name state] }
  let(:env) {}
  let(:roles) { [] }

  let(:config) do
    {
      roles: roles,
      environment: env
    }
  end

  describe 'with no environment or role selected' do
    it 'has a full set of columns' do
      expect(runbook.columns).to eq %w[environment role] + constant_columns
    end
  end

  describe 'with an environment but no role' do
    let(:env) { 'env' }

    it 'has all columns except environment' do
      expect(runbook.columns).to eq %w[role] + constant_columns
    end
  end

  describe 'with a single role but no environment' do
    let(:roles) { ['role'] }

    it 'has all columns except role' do
      expect(runbook.columns).to eq %w[environment] + constant_columns
    end
  end

  describe 'with more than one role but no environment' do
    let(:roles) { %w[role1 role2] }

    it 'has all columns except environment' do
      expect(runbook.columns).to eq %w[environment role] + constant_columns
    end
  end

  describe 'with an environment and a role' do
    let(:env) { 'env' }
    let(:roles) { ['role'] }

    it 'has all columns except environment and role' do
      expect(runbook.columns).to eq constant_columns
    end
  end

  describe 'with an environment and multiple roles' do
    let(:env) { 'env' }
    let(:roles) { %w[role1 role2] }

    it 'has all columns except environment' do
      expect(runbook.columns).to eq %w[role] + constant_columns
    end
  end
end
