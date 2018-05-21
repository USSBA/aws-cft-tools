# frozen_string_literal: true

require 'json'

module AwsCftTools
  class Template
    ##
    # Environment-specific parameters for a template.
    #
    class Parameters
      ##
      # Mapping of filename extensions to content types.
      #
      CONTENT_TYPES = {
        '.json' => 'json',
        '.rb' => 'dsl',
        '.yml' => 'yaml',
        '.yaml' => 'yaml'
      }.freeze

      attr_reader :environment, :aws_env

      def initialize(info = {})
        info.each { |(key, value)| instance_variable_set("@#{key}", value) }
      end

      ##
      # The parsed parameters for a template in the deployment environment.
      #
      # If no file exists, then a simple hash with the +Environment+ key set.
      #
      # @return [Hash]
      def to_h
        parameters_for_filename_and_environment
      rescue AwsCftTools::ToolingException
        raise
      rescue StandardError => exception
        raise AwsCftTools::ParseException, "Error while reading and parsing #{file}: #{exception}"
      end

      private

      attr_reader :content, :file

      # :reek:FeatureEnvy
      def parameters_for_filename_and_environment
        default_parameters_if_no_source ||
          parameters_for_environment ||
          default_parameters_for_environment
      end

      # :reek:FeatureEnvy
      def parameters_for_environment
        defaults = default_parameters_for_environment
        params_for_all = YAML.safe_load(process_erb_file(content), [], [], true)
        return params_for_all[environment].update(defaults) if params_for_all.key?(environment)

        # now check for regex match on keys
        env_match = environment_match(params_for_all.keys)
        params_for_all[env_match].update(defaults) if env_match
      end

      def default_parameters_if_no_source
        default_parameters_for_environment unless content
      end

      def environment_match(patterns)
        patterns.sort_by(&:length).reverse.detect do |pattern|
          Regexp.compile("\\A#{pattern}\\Z").match?(environment)
        end
      end

      def default_parameters_for_environment
        { 'Environment' => environment }
      end

      def process_erb_file(content)
        with_environment { ERB.new(content).result }
      end

      def with_environment
        return unless block_given?
        prior = ENV.to_h
        ENV.update(aws_env)
        yield
      ensure
        ENV.update(prior)
      end
    end
  end
end
