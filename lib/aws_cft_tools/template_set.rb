# frozen_string_literal: true

module AwsCftTools
  ##
  # Management of a set of template sources.
  #
  class TemplateSet < ::Array
    extend Forwardable

    attr_reader :known_exports
    attr_reader :dependency_tree

    require_relative 'template_set/array_methods'
    require_relative 'template_set/closure'
    require_relative 'template_set/dependencies'

    include ArrayMethods

    # @!method closure
    #   @see AwsCftTools::TemplateSet::Closure
    # @!method closed_subset
    #   @see AwsCftTools::TemplateSet::Closure
    include Closure

    include Dependencies

    # @!method undefined_variables
    #   @see AwsCftTools::DependencyTree#undefined_variables
    # @!method defined_variables
    #   @see AwsCftTools::DependencyTree#defined_variables
    def_delegators :dependency_tree, :undefined_variables, :defined_variables

    ##
    # @param list [Array<AwsCftTools::Template>] the templates in the set
    #
    def initialize(list = [])
      @dependency_tree = AwsCftTools::DependencyTree.new
      @sorted_names = []
      @known_exports = []
      super(list)

      list.each { |template| process_template_addition(template) }
    end

    # @!visibility private
    def initialize_clone(other)
      initialize_copy(other)
    end

    # @!visibility private
    def initialize_copy(other)
      super(other)
      @dependency_tree = other.dependency_tree.clone
    end

    ##
    # Set the list of known exported values in CloudFormation
    #
    # @param list [Array<String>]
    #
    def known_exports=(list)
      @known_exports |= list
      list.each do |name|
        @dependency_tree.exported(name)
      end
    end

    ##
    # @param filenames [Array<String>]
    # @return [AwsCftTools::TemplateSet] set of templates with the given filenames
    #
    def templates_for(filenames)
      select { |template| filenames.include?(template.filename.to_s) }
    end

    ##
    # @param template [AwsCftTools::Template]
    # @return [AwsCftTools::TemplateSet] set of templates on which the given template depends
    #
    def dependencies_for(template)
      templates_for(@dependency_tree.dependencies_for(template.filename.to_s))
    end

    ##
    # @param template [AwsCftTools::Template]
    # @return [AwsCftTools::TemplateSet] set of templates that depend on the given template
    #
    def dependents_for(template)
      templates_for(@dependency_tree.dependents_for(template.filename.to_s))
    end

    private

    def resort_templates
      @sorted_names = @dependency_tree.sort
      sort_by! { |template| @sorted_names.index(template.filename.to_s) || -1 }
    end

    def process_template_outputs(template)
      template.outputs.each { |name| provided(template, name) }
    end

    def process_template_inputs(template)
      template.inputs.each { |name| required(template, name) }
    end

    def process_template_dependencies(template)
      templates_for(template.template_dependencies).each { |other| linked(other, template) }
    end

    def process_template_addition(template)
      process_template_inputs(template)
      process_template_outputs(template)
      process_template_dependencies(template)

      resort_templates
      self
    end
  end
end
