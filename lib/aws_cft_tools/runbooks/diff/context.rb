# frozen_string_literal: true

require 'diffy'

module AwsCftTools
  module Runbooks
    class Diff
      ##
      # The context of stacks and templates for a Diff report.
      #
      class Context
        attr_reader :stacks, :templates, :options

        ##
        # The options provided to the +diff+ command to build template diffs.
        #
        DIFF_OPTIONS = %w[-w -U5 -t].freeze

        require_relative '../common/templates'
        require_relative 'context/reporting'

        include Common::Templates
        include Context::Reporting

        ##
        # @param stacks [Array<AwsCftTools::Stack>]
        # @param templates [AwsCftTools::TemplateSet]
        # @param options [Hash]
        def initialize(stacks, templates, options = {})
          @stacks = build_map(stacks)
          @templates = build_map(templates)
          @options = options
        end

        ##
        # Reports out stacks that do not have corresponding templates.
        #
        def report_on_missing_templates
          output_report_on_missing_templates(stacks.keys - templates.keys)
        end

        ##
        # Reports out templates that do not have corresponding stacks.
        #
        def report_on_missing_stacks
          output_report_on_missing_stacks(templates.keys - stacks.keys)
        end

        ##
        # Reports on the differences in the template bodies between the set of templates and the
        # deployed stacks.
        #
        def report_on_differences
          # these are stacks with templates
          output_report_on_differences(build_diffs)
        end

        private

        def build_map(list)
          list.each_with_object({}) do |thing, map|
            map[thing.name] = thing
          end
        end

        def build_diffs
          stacks
            .keys
            .sort
            .select { |fn| templates[fn] }
            .each_with_object({}) do |name, acc|
              acc[name] = build_diff(stacks[name], templates[name])
            end
        end

        def build_diff(stack, template)
          output_type = options[:colorize] ? :color : :text
          Diffy::Diff.new(
            stack.template_source, template.template_source_for_aws,
            include_diff_info: true, diff: DIFF_OPTIONS
          ).to_s(output_type)
        end
      end
    end
  end
end
