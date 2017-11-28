# Best Practices

## Environment-Dependent Settings

It's common to use mappings to manage settings that depend on the deployment environment when using only
CloudFormation templates. When adding a new environment, the template has to be modified to accommodate the
new environment.

While we don't get away from this completely -- the template has to list the environment as an allowed
value -- the goal is to minimize the changes to templates when deploying to a new environment.

By putting environment-dependent settings in a YAML parameters file that sits alongside the CloudFormation
template, we can leverage the YAML dictionary merging features to extract common settings across environments.
This lets us avoid
[magic numbers](<https://en.wikipedia.org/wiki/Magic_number_(programming)#Unnamed_numerical_constants>)
as well.

For example, if we have a template setting up an auto scaling group with instance sizing dependent on
the environment, and with two AWS accounts (e.g., a lower and an upper account) and deployments in two
regions, we can create a parameters file like so:

```yaml
---
Lower: &Lower
  InstanceType: m3.medium
Upper: &Upper
  InstanceType: m4.large
USEast1: &USEast1
  Foo: bar
USWest1: &USWest1
  Foo: baz

Lower-us-east-1: &Lower-us-east-1
  <<: *Lower
  <<: *USEast1
  AmiId: ami-abcdef12
Upper-us-east-1: &Upper-us-east-1
  <<: *Upper
  <<: *USEast1
  AmiId: ami-123456ab

Lower-us-west-1: &Lower-us-west-1
  <<: *Lower
  <<: *USWest1
  AmiId: ami-cdef1234
Upper-us-west-1: &Upper-us-west-1
  <<: *Upper
  <<: *USWest1
  AmiId: ami-34cdef12

dev:
  <<: *Lower-<%= ENV['AWS_REGION'] %>
  SpotPrice: 0.02
qa:
  <<: *Lower-<%= ENV['AWS_REGION'] %>
  SpotPrice: 0.04
demo:
  <<: *Lower-<%= ENV['AWS_REGION'] %>
  SpotPrice: 0.06
staging:
  <<: *Upper-<%= ENV['AWS_REGION'] %>
production:
  <<: *Upper-<%= ENV['AWS_REGION'] %>
```

We use `Lower` and `Upper` to capture cross-region parameters that are dependent on the account, and
`USEast1` and `USWest` to capture cross-account parameters that are dependent on the region. The
`Lower-us-east-1` and similarly named dictionaries capture settings that are dependent on both the region
and account while inheriting from the cross-region and cross-account settings.

Finally, we use the environment variable specifying the region to which we are deploying to select the
proper account/region set of settings to import into the environment settings.

## Template Dependencies

Most template interdependencies can be discovered by looking at the list of `Output`s and `Fn::ImportValue`s.
But sometimes, one template builds out a feature in a VPC (e.g., peering) that another template has to have
in order to finish its build (e.g., fetching Chef cookbooks through a peering connection). In these
situations, the template with the dependency should note the required templates in a `Metadata` section:

```yaml
---
Metadata:
  DependsOn:
    Templates:
      - relative-path-to/template.yaml
```

These dependencies are harmless if they replicate what can be discovered by examining the other contents of
the template, but it's best to rely on the implicit dependencies from the `Output`s and `Fn::ImportValue`s.

## Multiple AWS Accounts

Common practice separates development and testing environments from pre-production and
production environments. The easiest way to manage templates and parameters is to ensure that
all environments across accounts have unique names. For example, rather than have a
`devops` environment in each of the accounts when there might be account-dependent
resource references, you can incorporate the account into the environment's name
(e.g., `lower-devops` and `upper-devops`).

In the parameter files, you can use YAML aliases and references to aggregate common
parameter settings for environments across accounts that share the same purpose.

If you are working with environments that share the same name but reside in different
accounts, you can use an environment variable to select the account and use YAML aliases
and references to pull in the account-specific settings:

```yaml
---
devops-lower: &devops-lower
  ImageId: ami-abcdef12

devops-upper: &devops-upper
  ImageId: ami-34cdef12

devops:
  <<: *devops-<%= ENV['AWS_ACCOUNT'] || begin
      raise AwsCftTools::IncompleteEnvironmentError,
            'Please rerun with `AWS_ACCOUNT=lower ...` or `AWS_ACCOUNT=upper ...`'
    end
  %>
```

## Authentication to AWS

The `aws-cft` command supports the `-p` or `--profile` option to select an AWS profile. This makes
it easy to get up and running with multiple AWS accounts. Best practice here is to make sure none
of your profiles are labeled `default`. If there isn't a default profile, then you must select a
profile each time you run the `aws-cft` command. This helps prevent accidentally running a job in
the wrong account.

Because the tools use the AWS SDK's standard authentication mechanism, you can avoid selecting a
profile by storing your account credentials in environment variables. This lets you use tools such
as [aws-vault](https://github.com/99designs/aws-vault) to manage credentials without having them
stored in cleartext in a file that might get checked into a source code repository or otherwise
leaked.
