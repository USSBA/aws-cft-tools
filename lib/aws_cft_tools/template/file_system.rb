# frozen_string_literal: true

require 'json'

module AwsCftTools
  class Template
    ##
    # Manage template and parameter files.
    #
    module FileSystem
      ##
      # Returns the path to the cloud formation template.
      #
      # @return [Pathname]
      def template_file
        filename_path(:template_dir, filename)
      end

      ##
      # Returns the path to the template parameters file.
      #
      # @return [Pathname]
      def parameter_file
        filename_path(:parameter_dir, filename)
      end

      ##
      # The unparsed source of the template.
      #
      # @return [String]
      def template_source
        @template_source ||= @options[:template_content] || read_file(template_file)
      end

      ##
      # The unparsed source of the parameters file for this template.
      #
      # @return [String]
      def parameters_source
        @parameters_source ||= @options[:parameters_content] || read_file(parameter_file)
      end

      private

      def read_file(file)
        file ? file.read : nil
      end

      ##
      # Given the filename relative to the template/parameter root and a symbol indicating which type of
      # file to point to, returns the full path to the file
      #
      # @return [Pathname]
      def filename_path(dir, filename)
        # we need to check .yaml, .yml, and .json versions
        filename = filename.to_s.sub(/\.[^.]*$/, '')
        base = @options[:root] + @options[dir]
        %w[.yaml .yml .json .rb].map { |ext| base + (filename + ext) }.detect(&:exist?)
      end
    end
  end
end
