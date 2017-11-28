# frozen_string_literal: true

module AwsCftTools
  class Template
    ##
    # Utility module for evaluating ruby dsl templates.
    #
    module DSLContext
      require 'cloudformation-ruby-dsl/cfntemplate'
      require 'cloudformation-ruby-dsl/spotprice'
      require 'cloudformation-ruby-dsl/table'
    end
  end
end
