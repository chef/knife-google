# knife-google Change Log

## Release 3.0.0

* This release of knife-google is a complete rewrite utilizing
  `google-api-ruby-client`.
* GCE project and zone values can now be set in the `knife.rb` file. Doing so
  will eliminate having to specify the GCE project and zone each time
  `knife-google` is invoked.

## Release 3.0.0 Breaking Changes

* Many arguments and all output from sub commands has changed.
* Setup using `google setup` has been removed. To obtain credentials use
  `gcloud auth login` from the [Google Cloud SDK](https://cloud.google.com/sdk/).
  See README.md for additional details.
* The `project list` command has been removed. Use the new command `project
  quotas` or from the `gcloud` tool from the
  [Google Cloud SDK](https://cloud.google.com/sdk/gcloud/).
* The `region list` command has been removed. Use the new command `region
  quotas` or from the `gcloud` tool from the
  [Google Cloud SDK](https://cloud.google.com/sdk/gcloud/).
* Options and output from `server create` have changed.
* The `server delete` option to specify a different `node name` from the
  `client name` has been removed.

## Release 1.3.1 (04/24/2014)

* Refresh access token (KNIFE-473)

## Release: 1.2.0 (02/17/2014)

See source control commit history for earlier changes.
