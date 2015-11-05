<!---
This file is reset every time a new release is done. The contents of this file are for the currently unreleased version.

Example Note:

## Example Heading
Details about the thing that changed that needs to get included in the Release Notes in markdown.
-->
# knife-google 2.0.0 Release Notes :
In this release of knife-google the option names have been changed to conform to the long option names.
For example the `zone` option has been changed to `--gce-zone` as per the long option.
Also, support has been added so that the options can be set from knife.rb file.

## Issues fixed in knife-google 2.0.0

* [knife-google #70] (https://github.com/chef/knife-google/pull/70) Fix for --bootstrap-version command line option
* [knife-google #76] (https://github.com/chef/knife-google/pull/76) Fix for picking options from knife.rb
* [knife-google #77] (https://github.com/chef/knife-google/pull/77) Changed option names according to long options