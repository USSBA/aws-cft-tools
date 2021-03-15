# AwsCftTools

**DEPRECATION NOTICE**

This tool is no longer maintained.

---

[![Gem Version](https://badge.fury.io/rb/aws-cft-tools.svg)](https://badge.fury.io/rb/aws-cft-tools)
[![Build Status](https://travis-ci.org/USSBA/aws-cft-tools.svg?branch=master)](https://travis-ci.org/USSBA/aws-cft-tools)

CloudFormation and related services provide a way to manage infrastructure state in "the cloud." This
gem and its included command (`aws-cft`) build on top of this state management system to create an
infrastructure management solution native to the AWS environment.

`aws-cft-tools` empowers users to organize their CloudFormation templates using any form of directory
structure, without the need to tediously deploy their templates in a specific order or create quickly
outdated scripts to manage the deployment thereof.  This project links together templates using the
Export/ImportValue features of CloudFormation to determine the order of operations, manages stack
names, and supports multiple parallel "Environments" within a single AWS account.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'aws-cft-tools'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install aws-cft-tools

## Usage

The `aws-cft` command provides access to a number of run books that manage different tasks.

- `aws-cft deploy` to deploy CloudFormation templates
- `aws-cft diff` to see differences between local and deployed CloudFormation templates
- `aws-cft hosts` to list running EC2 instances
- `aws-cft images` to list available AMIs
- `aws-cft init` to initialize a new infrastructure project
- `aws-cft retract` to remove deployed CloudFormation templates
- `aws-cft stacks` to list CloudFormation stacks

See [`USAGE.adoc`](USAGE.adoc) for more details.

### Template organization

CloudFormation templates are managed in any number of directories that correspond to infrastructure
layers. For example, `vpcs`, `networks`, `security`, and `applications`. The layers are completely
arbitrary.

Templates also belong to a "role" based on their participation in the infrastructure.  The role is defined
with metadata in the template:

```yaml
Metadata:
  Role: foo
```

Templates are deployed or retracted based on their dependency order. The scripts try to discover this
by examining the values exported by one template and imported by another. When this fails to describe
the proper dependencies of a template, you can add an explicit dependency in the template's `Metadata`:

```yaml
Metadata:
  DependsOn:
    Templates:
      - relative_path_to/template.yaml
```

This follows the pattern for listing explicit dependencies between resources in a template.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the
tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version,
update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git
tag for the version, push git commits and tags, and push the `.gem` file to
[rubygems.org](https://rubygems.org).

## Why `aws-cft-tools`?

`aws-cft-tools` is designed to work in an "infrastructure as code" DevOps environment. Infrastructure is
software that is developed, tested, peer reviewed, and finally merged and deployed.

### "Vanilla" CloudFormation

When first using CloudFormation, it is very easy to launch a single stack and get off the ground quickly.
As you move forward, users quickly find out that their Templates need to be managed in source control.
Later, users want to test their infrastructure changes in a different Environment, so a "dev" layer is
created, then an "integration", then a "staging", etc.  Before too long, launching stacks is a nightmare
due to dependency conflicts, manual naming failures of Stacks, typos, and so on.  On top of that,
remembering which Stacks have been deployed for which environment becomes impossible, so infrastructure
drift is inevitable.

This tool builds on top of the normal progression of teams using CloudFormation, enabling managed
Environments using parameters on templates.  It offers simple deployments to roll out a full stack in
a new environment with a single command.  It allows developers to continue to use CloudFormation for all
their infrastructure, while vastly simplifying the deployment and retraction process.

### Ansible

[Ansible](https://www.ansible.com/) provides features that are a mix of infrastructure management and
instance configuration. For example, Ansible can do the work of TerraForm and Chef, combined. However,
Ansible works best when working with an expected inventory of resources. It makes changes to bring
infrastructure in line with the inventory. `aws-cft-tools` only manages CloudFormation templates and leaves
configuration of instances to other tools such as Chef or Ansible.

#### Using Ansible with `aws-cft-tools`

Ansible can manage the production of an Amazon Machine Image (AMI). It can spin up a temporary EC2 instance
and install all of the necessary system packages, make any configuration changes, and trigger the creation
of a tagged AMI. If the AMI is tagged with an Environment and Role, then `aws-cft-tools` can discover the
AMI and provide it as a parameter to any CloudFormation stacks that require the image. For example, creating
a new AMI and then using `aws-cft-tools` to deploy the CloudFormation Template for an auto-scaling group
that uses that AMI can result in the deployment of a new version of an application.

### TerraForm

[TerraForm](https://www.terraform.io/) and `aws-cft-tools` are solving similar problems with fundamentally
different approaches. TerraForm is designed to work with multiple cloud providers while `aws-cft-tools` is
specific to AWS. So TerraForm can't depend on features that aren't provided by all cloud providers. Thus,
TerraForm requires a state file that introduces some complexity into managing infrastructure.

Using `aws-cft-tools` doesn't mean infrastructure management is less complex than when using TerraForm. Only
that the complexity is different. Instead of managing a state file outside of AWS, `aws-cft-tools` assumes
that AWS is the source of all state information.

Rather than computing changes, for example, `aws-cft-tools` requests a list of changes from AWS for a given
change in template and parameters. This does take more time than if all of that information was in a local
state file, but it ensures that any changes reflect the current deployment.

In exchange for taking a little more time to make changes (e.g., pull requests and code reviews after
initial development), teams can work on different parts of the infrastructure without having to coordinate
with each other.

## Building Gem for Local Use

```shell
bundle install --deployment --without development test
gem build ./aws-cft-tools.gemspec
```

## Minimum IAM Policy to run initial script

```json
{
  "Sid": "aws-cft",
  "Effect": "Allow",
  "Action": [
    "ec2:DescribeInstances",
    "ec2:DescribeTags",
    "ec2:DescribeImages",
    "ec2:DescribeImageAttribute"
  ],
  "Resource": [ "*" ]
}
```

## Security Policy

Please do not submit an issue on GitHub for a security vulnerability. Please contact the development team
through the Certify Help Desk at [help@certify.sba.gov](mailto:help@certify.sba.gov).

Be sure to include all the pertinent information.

## License

Aws-cft-tools is licensed permissively under the Apache License v2.0.
A copy of that license is distributed with this software.

## Contributing

We welcome contributions. Please read [`CONTRIBUTING.md`](CONTRIBUTING.md) for how to contribute.

We strive for a welcoming and inclusive environment for the aws-cft-tools project.

Please follow this guidelines in all interactions:

1. Be Respectful: use welcoming and inclusive language.
2. Assume best intentions: seek to understand others' opinions.
