# frozen_string_literal: true

require 'pathname'

module AwsCftTools
  class Client
    ##
    # All of the business logic behind direct interaction with the AWS Template sources.
    #
    class Templates < Base
      ##
      # Default template directory in the project.
      DEFAULT_TEMPLATE_DIR = 'cloudformation/templates/'

      ##
      # Default parameters directory in the project.
      DEFAULT_PARAMETER_DIR = 'cloudformation/parameters/'

      ##
      # Default set of file extensions that might contain templates.
      #
      TEMPLATE_FILE_EXTENSIONS = %w[.yaml .yml .json .rb].freeze

      ##
      #
      # @param options [Hash] client configuration
      # @option options [String] :environment the operational environment in which to act
      # @option options [String] :parameter_dir
      # @option options [String] :region the AWS region in which to act
      # @option options [Pathname] :root
      # @option options [String] :template_dir
      #
      def initialize(options)
        super({
          template_dir: DEFAULT_TEMPLATE_DIR,
          parameter_dir: DEFAULT_PARAMETER_DIR
        }.merge(options))
      end

      ##
      # Lists all templates.
      #
      # @return AwsCftTools::TemplateSet
      #
      def templates
        template_file_root = (options[:root] + options[:template_dir]).cleanpath
        filtered_by_region(
          filtered_by_environment(
            all_templates(
              template_file_root
            )
          )
        )
      end

      private

      def filtered_by_environment(set)
        set.select { |template| template.environment?(options[:environment]) }
      end

      def filtered_by_region(set)
        set.select { |template| template.region?(options[:region]) }
      end

      def all_templates(root)
        AwsCftTools::TemplateSet.new(glob_templates(root)).tap do |set|
          set.known_exports = options[:client].exports.map(&:name)
        end
      end

      def glob_templates(root)
        Pathname.glob(root + '**/*')
                .select { |file| TEMPLATE_FILE_EXTENSIONS.include?(file.extname) }
                .map { |file| file_to_template(root, file) }
                .select(&:template?)
      end

      def file_to_template(root, file)
        AwsCftTools::Template.new(file.relative_path_from(root), options)
      end
    end
  end
end
