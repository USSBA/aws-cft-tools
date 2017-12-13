# frozen_string_literal: true

require 'aws_cft_tools/version'

##
# = AWS CloudFormation Tools
#
# A collection of classes and methods to manage AWS Infrastructure using CloudFormation as the fundamental
# unit of infrastructure state. Aws::Cft supports JSON, YAML, and DSL templates with minimal decoration
# to establish dependencies between templates.
#
# == Command Line Interface
#
# A CLI is provided through the +aws-cft+ command that will run any of the "runbooks" under the
# +AwsCftTools::Runbooks::+ namespace.
#
# To find a complete list of subcommands, run +aws-cft --help+.
#
module AwsCftTools
  require 'aws_cft_tools/errors'
  require 'aws_cft_tools/aws_enumerator'
  require 'aws_cft_tools/change'
  require 'aws_cft_tools/deletion_change'
  require 'aws_cft_tools/client'
  require 'aws_cft_tools/dependency_tree'
  require 'aws_cft_tools/threaded_output'
  require 'aws_cft_tools/stack'
  require 'aws_cft_tools/template'
  require 'aws_cft_tools/template_set'
  require 'aws_cft_tools/runbook'
  require 'aws_cft_tools/runbooks'
end
