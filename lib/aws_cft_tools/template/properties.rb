# frozen_string_literal: true

module AwsCftTools
  class Template
    ##
    # Simple properties of templates.
    #
    module Properties
      ##
      # Returns the list of environments allowed for the +Environment+ parameter.
      #
      # @return [Array<String>]
      #
      def allowed_environments
        template.dig('Parameters', 'Environment', 'AllowedValues') || []
      end

      def environment?(value)
        allowed_environments.include?(value)
      end

      ##
      # Returns the parameter defaults for the template.
      #
      def default_parameters
        (template['Parameters'] || []).each_with_object({}) do |param, hash|
          hash[param.first] = param.last['Default']
        end
      end

      ##
      # Returns the role of the template as specified in the template metadata.
      #
      # @return [String]
      #
      def role
        template.dig('Metadata', 'Role')
      end

      def role?(value)
        !value || role == value
      end

      ##
      # Returns the list of regions in which the template is allowed.
      #
      # @note The region in which a template is deployed is available as the +AWS::Region+ pseudo-parameter.
      #
      # @return [Array<String>]
      #
      def allowed_regions
        template.dig('Metadata', 'Region') || []
      end

      def region?(region)
        !region || allowed_regions.empty? || allowed_regions.include?(region)
      end

      ##
      # Returns any templates on which this template has an explicit dependency.
      #
      # These explicit dependencies are combined with any dependencies implied by imported values.
      #
      def template_dependencies
        template.dig('Metadata', 'DependsOn', 'Templates') || []
      end

      ##
      # lists the exported values from the template
      #
      # Note that this does substitutions of any references to template parameters.
      #
      # @return [Array<String>]
      #
      def outputs
        (template['Outputs'] || []).map do |_, output|
          with_substitutions(output_name(output.dig('Export', 'Name')))
        end
      end

      ##
      # lists the imports expected by the template
      #
      # Note that this does substitutions of any references to template parameters.
      #
      # @return [Array<String>]
      #
      def inputs
        (template['Resources'] || {})
          .values
          .flat_map { |resource| pull_imports(resource['Properties'] || {}) }
          .uniq
          .map(&method(:with_substitutions))
      end

      private

      def output_name(name)
        if name.is_a?(Hash)
          name['Sub'] || name['Fn::Sub']
        else
          name
        end
      end

      def substitutions
        @substitutions ||= begin
          defaults = Hash.new { |hash, key| hash[key] = "${#{key}}" }
          # need to get the default values of parameters from the template and populate those

          [default_parameters, parameters].flat_map(&:to_a).each do |key, value|
            defaults["${#{key}}"] = value
          end

          defaults
        end
      end

      ## expands ${param} when ${param} is defined in the parameters
      ## but only works with "${param}" and not [ "${param}", {param: value}]
      ## only substitutes when a value is provided as a parameter - otherwise, leaves it unsubsituted
      def with_substitutions(string)
        return string if string.is_a?(Array)

        string.gsub(/(\${[^}]*})/, substitutions)
      end
    end
  end
end
