# Changelog

## UNRELEASED

### Changed

* When retracting stacks, a template that hadn't been deployed yet could block removal of any templates it
  depended on. Now, retraction only considers templates that have been deployed. (Issue #18)

## [0.1.1] - 2017-12-15

### Added

* The `-d` and `--debug` options for `deploy` show more narrative. This can be useful if running parallel
  jobs in a deployment (`-j` option with a value greater than one). This option is available for all
  runbooks, but only the `deploy` runbook uses it in this release.
* Documentation on why `aws-cft-tools` is better than plain vanilla CloudFormation or Terraform. (Issue #10)

### Changed

* Parallel deployments use threads. We weren't always handling output properly, so some output could be lost
  if there was an error. We've reworked how we coordinate output from threads to reduce the chance of this
  happening. (Issue #7)
* Deployments special case the `-j1` option to avoid threads. If you run into issues with `-j` and a value
  greater than one, run without the option or with `-j1` to make sure that threads aren't the source of the
  problem. (Issue #7)

## [0.1.0] - 2017-11-29

Initial release.
