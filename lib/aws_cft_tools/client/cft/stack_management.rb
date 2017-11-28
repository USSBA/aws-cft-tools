# frozen_string_literal: true

module AwsCftTools
  class Client
    class CFT
      ##
      # Provide stack management functions for the CFT client.
      #
      module StackManagement
        ##
        # Accepts information about a stack and tries to update that stack. The stack must already
        # exist in CloudFormation.
        #
        # Metadata keys:
        # - filename (required)
        # - name
        # - parameters
        # - template_file
        #
        # If the update would result in no changes, no error is raised. Otherwise, all errors are
        # raised and halt deployment.
        #
        # @param template [AwsCftTools::Template]
        #
        def update_stack(template)
          aws_client.update_stack(update_stack_params(template))
          # we want to wait for the update to complete before we proceed
          aws_client.wait_until(:stack_update_complete, stack_name: template.name)
        rescue Aws::CloudFormation::Errors::ValidationError => exception
          raise exception unless exception.message.match?(/No updates/)
        end

        ##
        # Accepts information about a stack and tries to create the stack. The stack must not exist in
        # CloudFormation.
        #
        # @param template [AwsCftTools::Template]
        #
        def create_stack(template)
          aws_client.create_stack(create_stack_params(template))
          # we want to wait for the create to complete before we proceed
          aws_client.wait_until(:stack_create_complete, stack_name: template.name)
        end

        ##
        # Accepts information about a stack and tries to remove the stack. The stack must exist in
        # CloudFormation.
        #
        # @param template [AwsCftTools::Template]
        #
        def delete_stack(template)
          aws_client.delete_stack(delete_stack_params(template))
          aws_client.wait_until(:stack_delete_complete, stack_name: template.name)
        end

        private

        def update_stack_params(template)
          common_stack_params(template).merge(
            use_previous_template: false,
            # on_failure: "ROLLBACK", # for updating
          )
        end

        def create_stack_params(template)
          common_stack_params(template).merge(
            on_failure: 'DELETE', # for creation
          )
        end

        def delete_stack_params(template)
          {
            stack_name: template.name
          }
        end

        def common_stack_params(template)
          template.stack_parameters.merge(
            capabilities: %w[CAPABILITY_IAM CAPABILITY_NAMED_IAM]
          )
        end
      end
    end
  end
end
