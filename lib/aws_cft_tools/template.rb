# frozen_string_literal: true

require 'yaml'
require 'erb'
require 'pathname'

module AwsCftTools
  ##
  # The AwsCftTools::Template class wraps a CloudFormation template source to provide support for various
  # operations by the toolset.
  #
  # == CloudFormation Templates
  #
  # As much as possible, this tool uses CloudFormation templates as-is and makes as many inferences as
  # reasonable. However, some things aren't captured in stock template information.
  #
  # @note Stacks should be removed ("retracted") from AWS before they are removed from the set of templates.
  #   Otherwise, they won't be considered in the set of available templates or stacks.
  #
  # @todo Fetch templates from deployed stacks and consider them in the dependency tree for removing or
  #   deploying templates in the repo. Flag stacks with no local source to not be updated on deployment.
  #
  # @todo Add ability to init to fetch templates from stacks and put them in files.
  #
  # === Allowed Environments
  #
  # The environments in which a template should be deployed is provided by the +AllowedValues+ key of the
  # +Environment+ template parameter.
  #
  # @example Allowed Environments
  #   ---
  #   Parameters:
  #     Environment:
  #       AllowedValues:
  #         - QA
  #         - Staging
  #         - Production
  #
  # === Allowed Regions
  #
  # A template can be pinned to a particular region or set of regions by providing a list of values for
  # the +Region+ key in the template metadata. If no such key is present, then the template can be
  # deployed or otherwise used in all regions.
  #
  # @example Allowed Regions
  #   ---
  #   Metadata:
  #     Region:
  #       - us-east-1
  #       - us-west-1
  #
  # === Explicit Template Dependencies
  #
  # As much as possible, dependencies between templates are inferred based on exported and imported
  # values. However, some templates might depend on another template in a way that isn't captured by
  # these values. For those dependencies, the templates that should be run first can be listed under the
  # +DependesOn.Templates+ metadata key.
  #
  # @example Explicit Template Dependency
  #   ---
  #   Metadata:
  #     DependsOn:
  #       Templates:
  #         - network/peering.yaml
  #
  # === Template Parameters
  #
  # Rather than require mappings in templates to hold environment-specific values, a template has a
  # corresponding parameters file that holds the value for the stack parameter for each environment.
  # This parameters file is in YAML format and passed through ERB before parsing, so it can incorporate
  # environment variables and other logic into specifying parameter values.
  #
  class Template
    attr_reader :filename

    require_relative 'template/dsl_context'
    require_relative 'template/file_system'
    require_relative 'template/metadata'
    require_relative 'template/properties'

    include FileSystem
    include Metadata
    include Properties

    ##
    # @param filename [String] path to template relative to the +template_dir+ path
    # @param options [Hash] runbook options
    # @option options [String] :environment environment in which parameters should be fetched
    # @option options [String] :parameter_dir directory relative to the +root+ path in which parameter files
    #   are found
    # @option options [Pathname] :root path to the root of the project
    # @option options [String] :template_dir directory relative to the +root+ path in which template sources
    #   are found
    #
    def initialize(filename, options = {})
      @options = options
      @filename = filename
    end

    ##
    # @return [Array<Hash>] template tags suitable for use in deploying a stack
    #
    def tags
      [
        { key: 'Environment', value: @options[:environment] },
        { key: 'Source', value: ('/' + filename.to_s).gsub(%r{/+}, '/') }
      ] + role_tag
    end

    ##
    # @return [Hash] parameters to provide to the AWS client to deploy the template
    #
    def stack_parameters
      {
        stack_name: name,
        template_body: template_source_for_aws,
        parameters: hash_to_param_list(parameters || {}),
        tags: tags
      }
    end

    private

    def role_tag
      if role
        [{ key: 'Role', value: role }]
      else
        []
      end
    end

    def hash_to_param_list(hash)
      hash.map do |key, value|
        {
          parameter_key: key.to_s,
          parameter_value: value_to_string(value),
          use_previous_value: !value && value != false || value == ''
        }
      end
    end

    def value_to_string(value)
      case value
      when false
        'false'
      when true
        'true'
      else
        value ? value.to_s : value
      end
    end

    ##
    # Looks through the template to find instances of +Fn::ImportValue+
    #
    def pull_imports(hash)
      hash.flat_map do |key, value|
        value ||= key
        if %w[Fn::ImportValue ImportValue].include?(key)
          pull_import(value)
        elsif value.is_a?(Hash) || value.is_a?(Array)
          pull_imports(value)
        else
          []
        end
      end
    end

    def pull_import(value)
      if value.is_a?(Hash)
        [value['Fn::Sub'] || value['Sub'] || value]
      else
        [value]
      end
    end
  end
end
