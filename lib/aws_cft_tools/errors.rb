# frozen_string_literal: true

module AwsCftTools
  ##
  # Provides a root class for matching any internal exceptions.
  #
  class ToolingException < StandardError; end

  ##
  # Exception when a needed environment variable is not provided. Intended for use in
  # parameter files.
  class IncompleteEnvironmentError < ToolingException; end

  ##
  # Exception raised when the template or parameter source file can not be read and parsed.
  class ParseException < ToolingException; end

  ##
  # Exception raised when the AWS SDK raises an error interacting with the AWS API.
  class CloudFormationError < ToolingException; end

  ##
  # Exception raised when an expected resolvable template dependency can not be satisfied.
  class UnsatisfiedDependencyError < ToolingException; end
end
