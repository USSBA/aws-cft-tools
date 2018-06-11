# frozen_string_literal: true

require 'diffy'

module AwsCftTools
  module Runbooks
    class Diff
      class Context
        ##
        # Reporting functions for the Diff context
        #
        module Reporting
          private

          # :reek:FeatureEnvy
          def output_report_on_missing_templates(missing)
            puts "\nStacks with no template:\n  #{missing.sort.join("\n  ")}\n" if missing.any?
          end

          def output_report_on_missing_stacks(missing)
            missing = template_filenames(missing)
            puts "\nUndeployed templates:\n  #{missing.sort.join("\n  ")}\n" if missing.any?
          end

          def output_report_on_differences(diffs)
            report_on_blank_diffs(diffs)
            report_on_real_diffs(diffs)
          end

          def report_on_blank_diffs(diffs)
            no_diffs = diffs.keys.select { |name| diffs[name].match(/\A\s*\Z/) }
            return if no_diffs.empty?

            puts "\nTemplates with no changes:\n  #{template_filenames(no_diffs).sort.join("\n  ")}\n"
          end

          def report_on_real_diffs(diffs)
            real_diffs = diffs.keys.reject { |name| diffs[name].match(/\A\s*\Z/) }

            return if real_diffs.empty?

            if options[:verbose]
              report_full_diffs(real_diffs, diffs)
            else
              report_list_of_diffs(real_diffs)
            end
          end

          def report_full_diffs(names, diffs)
            names.sort.each do |name|
              report_pos_diff(templates[name].filename.to_s, diffs[name])
            end
          end

          def report_list_of_diffs(real_diffs)
            puts "\nTemplates with changes:\n  #{template_filenames(real_diffs).sort.join("\n  ")}\n"
          end

          def template_filenames(stack_names)
            set = templates.values_at(*stack_names).map(&:filename).map(&:to_s)
            allowed = options[:templates]
            if allowed && allowed.any?
              set & allowed
            else
              set
            end
          end

          def report_pos_diff(filename, diff)
            return unless template_in_consideration(options[:templates], filename)
            puts diff_with_filenames(diff, filename), ''
          end

          def diff_with_filenames(diff, filename)
            diff.sub(%r{--- /.*$}, "--- #{filename} @ AWS")
                .sub(%r{\+\+\+ /.*$}, "+++ #{filename} @ Local")
          end

          def template_in_consideration(list, filename)
            !list || list.empty? || list.include?(filename)
          end
        end
      end
    end
  end
end
