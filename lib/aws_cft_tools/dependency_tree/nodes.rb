# frozen_string_literal: true

module AwsCftTools
  class DependencyTree
    ##
    # Manages a list of nodes or vertices. Edges pass from a filename node to a variable node or from
    # a variable node to a filename node, but never from a filename node to a filename node or from
    # a variable node to a variable node.
    #
    class Nodes
      include TSort

      def initialize
        @nodes = default_hash
        @inverse_nodes = default_hash
      end

      ##
      # Computes the direct dependencies of a node that are of the same type as the node. If the node
      # is a filename, then the returned nodes will be filenames. Likewise with variable names.
      #
      # @param node [String]
      # @return [Array<String>]
      #
      def dependencies_for(node)
        double_hop(@nodes, node.to_s)
      end

      ##
      # Computes the things dependent on the given node. If the node is a filename, then the returned
      # nodes will be filenames. Likewise with variable names.
      #
      # @param node [String]
      # @return [Array<String>]
      #
      def dependents_for(node)
        double_hop(@inverse_nodes, node.to_s)
      end

      ##
      # Draws a directed link from +from+ to +to+.
      #
      # @param from [String]
      # @param to [String]
      def make_link(from, to)
        @nodes[from] << to
        @inverse_nodes[to] << from
      end

      private

      def double_hop(set, node)
        # we hop from a filename to a variable child to a filename child
        #     or from a variable to a filename child to a variable child
        set[node].flat_map { |neighbor| set[neighbor] }.uniq
      end

      def tsort_each_node(&block)
        @nodes.each_key(&block)
      end

      def tsort_each_child(node, &block)
        @nodes[node].each(&block) if @nodes.include?(node)
      end

      def default_hash
        Hash.new { |hash, key| hash[key] = [] }
      end
    end
  end
end
