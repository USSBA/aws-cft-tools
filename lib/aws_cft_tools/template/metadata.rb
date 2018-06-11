# frozen_string_literal: true

require 'json'

module AwsCftTools
  # :reek:IrresponsibleModule
  class Template
    require_relative 'parameters'

    ##
    # Simple derived information about templates.
    #
    module Metadata
      ##
      # Mapping of filename extensions to content types.
      #
      CONTENT_TYPES = {
        '.json' => 'json',
        '.rb' => 'dsl',
        '.yml' => 'yaml',
        '.yaml' => 'yaml'
      }.freeze

      ##
      # The type of template content.
      #
      # @return [String] One of +dsl+, +json+, or +yaml+.
      def template_type
        content_type(template_file)
      end

      ##
      # Queries if the template source looks like a CloudFormation template.
      #
      # @return [Boolean]
      def template?
        template && template['AWSTemplateFormatVersion']
      end

      ##
      # The name of the stack built by this template.
      #
      # @return [String]
      def name
        @name ||= @options[:environment] + '-' +
                  filename.to_s.sub(/\.(ya?ml|json|rb)$/, '').split(%r{/}).reverse.join('-')
      end

      ##
      # The parsed template as a Ruby data structure.
      #
      # @return [Hash]
      def template
        @template ||= template_content_for_filename(template_file)
      end

      ##
      # The JSON or YAML source that can be submitted to AWS to build the stack.
      #
      # @return [String]
      def template_source_for_aws
        template_type == 'dsl' ? JSON.pretty_generate(template) : template_source
      end

      ##
      # The parsed parameters for this template in the deployment environment.
      #
      # @return [Hash]
      def parameters
        @parameters ||= Parameters.new(
          environment: @options[:environment],
          aws_env: aws_env,
          content: parameters_source,
          file: parameter_file
        ).to_h
      end

      private

      def content_type(file)
        CONTENT_TYPES[file.extname] if file
      end

      ##
      # Loads the contents of the full path and returns the content as a Ruby data structure
      #
      # @return [String]
      def template_content_for_filename(file)
        type = content_type(file)
        return {} unless type
        send(:"template_content_for_#{type}!")
      rescue => exception
        raise AwsCftTools::ParseException, "Error while parsing #{template_file}: #{exception}"
      end

      def template_content_for_yaml!
        YAML.safe_load(template_source, [Date], [], true) || {}
      end

      def template_content_for_json!
        JSON.parse(template_source) || {}
      end

      def template_content_for_dsl!
        with_environment { JSON.parse(DSLContext.module_eval(template_source).to_json) }
      end

      def with_environment
        return unless block_given?
        prior = ENV.to_h
        ENV.update(aws_env)
        yield
      ensure
        ENV.update(prior)
      end

      def aws_env
        region = @options[:region]
        {
          'AWS_REGION' => region,
          'EC2_REGION' => region,
          'AWS_PROFILE' => @options[:profile]
        }
      end
    end
  end
end
