# frozen_string_literal: true

require 'spec_helper'
require 'pathname'

RSpec.describe AwsCftTools::Runbooks::Images do
  let(:runbook) { described_class.new(config) }

  let(:constant_columns) { %w[created_at public type image_id] }

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
      expect(runbook.columns).to eq %w[environment role] + constant_columns
    end
  end

  describe 'with an environment but no role' do
    let(:env) { 'env' }

    it 'has all columns except environment' do
      expect(runbook.columns).to eq %w[role] + constant_columns
    end
  end

  describe 'with a role but no environment' do
    let(:role) { 'role' }

    it 'has all columns except role' do
      expect(runbook.columns).to eq %w[environment] + constant_columns
    end
  end

  describe 'with an environment and a role' do
    let(:env) { 'env' }
    let(:role) { 'role' }

    it 'has all columns except environment and role' do
      expect(runbook.columns).to eq constant_columns
    end
  end
end
