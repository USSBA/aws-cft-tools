# frozen_string_literal: true

module AwsCftTools
  ##
  # Namespace for runbooks
  #
  module Runbooks
    require_relative 'runbooks/deploy'
    require_relative 'runbooks/diff'
    require_relative 'runbooks/hosts'
    require_relative 'runbooks/images'
    require_relative 'runbooks/init'
    require_relative 'runbooks/retract'
    require_relative 'runbooks/stacks'
  end
end
