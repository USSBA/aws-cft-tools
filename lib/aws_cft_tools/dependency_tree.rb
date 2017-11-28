# frozen_string_literal: true

module AwsCftTools
  ##
  # = Dependency Tree
  #
  # Manage dependencies between CloudFormation templates based on exported and imported variables.
  #
  class DependencyTree
    extend Forwardable

    require_relative 'dependency_tree/nodes'
    require_relative 'dependency_tree/variables'

    attr_reader :filenames, :nodes, :variables

    def initialize
      @nodes = Nodes.new
      @variables = Variables.new
      @filenames = []
    end

    # @!method undefined_variables
    #   @see AwsCftTools::DependencyTree::Variables#undefined_variables
    # @!method defined_variables
    #   @see AwsCftTools::DependencyTree::Variables#defined_variables
    def_delegators :variables, :undefined_variables, :defined_variables
    # @!method exported
    #   @see AwsCftTools::DependencyTree::Variables#defined
    def_delegator :variables, :defined, :exported

    # @!method dependencies_for
    #   @see AwsCftTools::DependencyTree::Nodes#dependencies_for
    # @!method dependents_for
    #   @see AwsCftTools::DependencyTree::Nodes#dependents_for
    def_delegators :nodes, :dependencies_for, :dependents_for

    ##
    # computes a topological sort and returns the filenames in that sort order
    #
    # @return [Array<String>]
    #
    def sort
      nodes.tsort & filenames
    end

    ##
    # notes that the given filename defines the given variable name
    #
    # @param filename [#to_s]
    # @param variable [String]
    #
    def provided(filename, variable)
      filename = filename.to_s
      nodes.make_link(variable, filename)
      @filenames |= [filename]
      exported(variable)
    end

    ##
    # notes that the given filename requires the given variable name to be defined before deployment
    #
    # @param filename [#to_s]
    # @param variable [String]
    #
    def required(filename, variable)
      filename = filename.to_s
      nodes.make_link(filename, variable)
      @filenames |= [filename]
      variables.referenced(variable)
    end

    ##
    # links two nodes in a directed fashion
    #
    # The template named by _from_ provides resources required by the template named by _to_.
    #
    # @param from [#to_s]
    # @param to [#to_s]
    #
    def linked(from, to)
      linker = "#{from}$$#{to}"
      provided(from, linker)
      required(to, linker)
    end

    ##
    # finds a subset of the given set that has no dependencies outside the set
    #
    # @param set [Array<T>]
    # @return [Array<T>]
    #
    def closed_subset(set)
      # list all nodes that have no dependents outside the set
      close_subset(set, &method(:dependents_for))
    end

    private

    def close_subset(set, &block)
      return [] unless block_given?
      set - items_outside_subset(set, &block)
    end

    def items_outside_subset(set)
      set.select { |node| (yield(node) - set).any? }
    end
  end
end
