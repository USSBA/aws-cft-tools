# frozen_string_literal: true

module AwsCftTools
  class Client
    ##
    # = EC2 Instance Client
    #
    # All of the business logic behind direct interaction with the AWS API for EC2 instances and related
    # resources.
    #
    # :reek:UncommunicativeModuleName
    class EC2 < Base
      ##
      #
      # @param options [Hash] client configuration
      # @option options [String] :environment the operational environment in which to act
      # @option options [String] :profile the AWS credential profile to use
      # @option options [String] :region the AWS region in which to act
      # @option options [String] :role the operational role of the resources under consideration
      #
      def initialize(options)
        super(options)
      end

      def self.aws_client_class
        Aws::EC2::Resource
      end

      ##
      # Returns a list of running instances filtered by any environment or role specified in the
      # options passed to the constructor.
      #
      # Each instance is represented by a Hash with the following keys:
      # - private_ip: the private IP address of the instance
      # - public_ip: the public IP address (if any) of the instance
      # - instance: the ID of the instance
      # - role: the value of the `Role` tag if not filtering by role
      # - environment: the value of the `Environment` tag if not filtering by environment
      #
      # @return [Array<OpenStruct>]
      #
      def instances
        @instances ||= aws_client.instances(filters: instance_filters).map do |instance|
          OpenStruct.new(
            with_tags(instance, private_ip: instance.private_ip_address,
                                public_ip: instance.public_ip_address,
                                instance: instance.instance_id)
          )
        end
      end

      ##
      # Returns a list of available AMI images filtered by any environment or role specified in the
      # options passed to the constructor.
      #
      # Each image is represented by an OpenStruct with the following keys/methods:
      # - image_id: the ID of the AMI or image
      # - type: the type of AMI or image
      # - public: a flag indicating if the image is public
      # - created_at: the date/time at which the image was created
      # - role: the value of the `Role` tag if not filtering by role
      # - environment: the value of the `Environment` tag if not filtering by environment
      #
      # @return [Array<OpenStruct>]
      #
      def images
        @images ||= aws_client.images(owners: ['self'], filters: image_filters).map do |image|
          OpenStruct.new(
            with_tags(image, image_id: image.image_id,
                             type: image.image_type,
                             public: image.public,
                             created_at: image.creation_date)
          )
        end
      end

      private

      def instance_filters
        @instance_filters ||= begin
          [
            { name: 'instance-state-name', values: ['running'] }
          ] + tag_filters
        end
      end

      def image_filters
        @image_filters ||= begin
          [
            { name: 'state', values: ['available'] }
          ] + tag_filters
        end
      end

      def tag_filters
        @tag_filters ||= begin
          environment_filter +
            role_filter +
            arbitrary_tag_filters
        end
      end

      def environment_filter
        tag_filter('Environment', options[:environment])
      end

      def role_filter
        tag_filter('Role', options[:roles])
      end

      def arbitrary_tag_filters
        tags = options[:tags] || []
        tags.inject([]) { |set, tag_value| set + tag_filter(*tag_value) }
      end

      def tag_filter(tag, value)
        values = [value].flatten.compact
        if values.any?
          [{ name: "tag:#{tag}", values: values }]
        else
          []
        end
      end

      def with_tags(resource, info = {})
        tags = resource.tags.each_with_object({}) { |tag, collection| collection[tag.key] = tag.value }
        info.merge(
          role: tags.delete('Role'),
          environment: tags.delete('Environment'),
          tags: tags
        )
      end
    end
  end
end
