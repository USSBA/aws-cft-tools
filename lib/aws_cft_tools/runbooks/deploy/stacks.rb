# frozen_string_literal: true

module AwsCftTools
  module Runbooks
    class Deploy
      ##
      # Stacks - operations on stacks in the deploy runbook
      #
      module Stacks
        private

        ##
        # Provides the next environment to look at if the current one fails.
        #
        # This is mainly used to find an AMI that is appropriate for the environment. Since we want
        # to be able to promote AMIs from one environment to the next without rebuilding them, we
        # should use the AMI that is most appropriate even if it's not tagged with the environment
        # in scope.
        #
        # This can be configured in the configuration file with the +:environment_successors+ key.
        #
        def successor_environment(env)
          (options[:environment_successors] || {})[env]
        end

        ##
        # list the available images by role and environment
        #
        # An image for a role/environment is the most recent AMI tagged with that role and environment.
        #
        def available_images
          @available_images ||= images.sort_by(&:created_at).each_with_object({}) do |image, mapping|
            key = image_key(image)
            mapping[key] = image.image_id if key != ':'
          end
        end

        def image_key(image)
          (image.environment || '') + ':' + (image.role || '')
        end

        ##
        # retrieve the appropriate AMI identifier for an environment/role
        #
        # This takes into account environment succession (see #successor_environment) to find the
        # best image for an environment/role as determined by #available_images.
        #
        def find_image(role, env)
          key = "#{env}:#{role}"
          image = available_images[key]
          return image if image
          next_env = successor_environment(env)
          find_image(role, next_env) if next_env
        end

        ##
        # list the template files containing `Region` metadata
        #
        def files_with_region_param
          @files_with_region_param ||=
            templates.select { |template| template.allowed_regions.any? }.map(&:filename)
        end

        ##
        # list the template source filenames for deployed stacks
        #
        # This returns the filename as reported by the `Source` tag on the CloudFormation stack.
        #
        def deployed_stack_names
          stacks.map(&:name).compact
        end

        ##
        # list the filenames of all of the in-scope templates
        #
        def files
          templates.map(&:filename)
        end

        ##
        # add `ImageId` parameter to templates as-needed
        #
        def update_template_with_image_id(template)
          params = template.parameters
          params.each do |key, value|
            update_params_with_image_id(params, key, value)
          end
        end

        def update_params_with_image_id(params, key, value)
          return unless value.is_a?(Hash)
          role = value['Role']
          image = find_image(role, options[:environment])
          params[key] = image if role
          report_undefined_image(role) if role && !image
        end

        ##
        # utility function to create an error message about undefined AMIs
        #
        def report_undefined_image(role)
          puts format('Unable to find image for %s suitable for %s',
                      role,
                      options[:environment])
        end
      end
    end
  end
end
