# frozen_string_literal: true

module AwsCftTools
  class Client
    class CFT
      ##
      # Provides changeset management functions for the CFT client.
      #
      module ChangesetManagement
        ##
        # Accepts a template for a stack and tries to create an update changeset for that stack. The stack
        # must already exist in CloudFormation.
        #
        # @param template [AwsCftTools::Template]
        # @param changeset_set [String] an identifier linking various changesets as part of the same run
        # @return [Array<AwsCftTools::Change>]
        #
        def changes_on_stack_update(template, changeset_set)
          do_changeset(update_changeset_params(template, changeset_set))
        end

        ##
        # Accepts a template for a stack and tries to create a creation changeset for the stack. The stack
        # must not exist yet in CloudFormation.
        #
        # @param template [AwsCftTools::Template]
        # @param changeset_set [String] an identifier linking various changesets as part of the same run
        # @return [Array<AwsCftTools::Change>]
        #
        def changes_on_stack_create(template, changeset_set)
          do_changeset(create_changeset_params(template, changeset_set))
        end

        ##
        # Accepts a template and creates a mock changeset listing the resources that would be removed if
        # the stack were deleted. The stack must exist in CloudFormation.
        #
        # @param template [AwsCftTools::Template]
        # @param _changeset_set [Object] ignored to maintain compatibility with the other changeset methods
        # @return [Array<AwsCftTools::DeletionChange>]
        #
        def changes_on_stack_delete(template, _changeset_set)
          mock_delete_changeset(template)
        end

        private

        ##
        # perform the changeset creation/deletion and return the changes that would happen if the
        # changes moved forward
        #
        def do_changeset(params)
          id = id_params(params)

          aws_client.create_change_set(params)
          return [] if wait_for_changeset(id) == :nochanges
          mapped_changes(AWSEnumerator.new(aws_client, :describe_change_set, id, &:changes).to_a)
        ensure
          aws_client.delete_change_set(id)
        end

        def wait_for_changeset(id, times_waited = 0)
          times_waited += 1
          aws_client.wait_until(:change_set_create_complete, id)
        rescue Aws::Waiters::Errors::FailureStateError
          status = check_failure(id)
          return status unless status == :retry
          raise_if_too_many_retries(params, times_waited)
          sleep(2**times_waited + 1)
          retry
        end

        def raise_if_too_many_retries(params, retries)
          return if retries < 5
          raise CloudFormationError, "Error waiting on changeset for #{params[:stack_name]}"
        end

        def check_failure(id)
          status = aws_client.describe_change_set(id)
          return :retry unless status.status == 'FAILED'
          return :no_changes if status.status_reason.match?(/didn't contain changes/)
          raise CloudFormationError,
                "Error creating changeset for #{params[:stack_name]}: #{status.status_reason}"
        end

        def id_params(params)
          {
            change_set_name: params[:change_set_name],
            stack_name: params[:stack_name]
          }
        end

        def update_changeset_params(template, changeset_set)
          common_changeset_params(template, changeset_set).merge(change_set_type: 'UPDATE')
        end

        def create_changeset_params(template, changeset_set)
          common_changeset_params(template, changeset_set).merge(change_set_type: 'CREATE')
        end

        def mock_delete_changeset(template)
          # act like we're doing a changeset, but just narrate all of the resources being removed
          id_params = { stack_name: template.name }
          mapped_deleted_resources(
            AWSEnumerator.new(aws_client, :list_stack_resources, id_params, &:stack_resource_summaries).to_a
          )
        rescue Aws::CloudFormation::Errors::ValidationError
          []
        end

        def common_changeset_params(template, changeset_set)
          params = template.stack_parameters
          params.merge(
            capabilities: %w[CAPABILITY_IAM CAPABILITY_NAMED_IAM],
            change_set_name: "#{params[:stack_name]}-#{changeset_set}"
          )
        end

        def mapped_deleted_resources(resources)
          resources.map { |resource| AwsCftTools::DeletionChange.new(resource) }
        end

        def mapped_changes(changes)
          changes.flat_map { |change| AwsCftTools::Change.new(change) }
        end
      end
    end
  end
end
