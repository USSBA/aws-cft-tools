# AwsCftTools

[![Build Status](https://travis-ci.org/USSBA/aws-cft-tools.svg?branch=master)](https://travis-ci.org/USSBA/aws-cft-tools)

CloudFormation and related services provide a way to manage infrastructure state in "the cloud." This
gem and its included command (`aws-cft`) build on top of this state management system to create an
infrastructure management solution native to the AWS environment.

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
