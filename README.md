# knife-google

[![Gem Version](https://badge.fury.io/rb/knife-google.svg)](http://badge.fury.io/rb/knife-google)
[![Build Status](https://travis-ci.org/chef/knife-google.svg?branch=master)](https://travis-ci.org/chef/knife-google)
[![Dependency Status](https://gemnasium.com/chef/knife-google.svg)](https://gemnasium.com/chef/knife-google)

## Overview

This is the official Chef [Knife](http://docs.chef.io/knife.html) plugin for
[Google Compute Engine](https://cloud.google.com/products/compute-engine).
This plugin gives knife the ability to create, bootstrap, and manage
Google Compute Engine (GCE) instances.

## Compatibility

This plugin has been tested with Chef 12.x and uses the [Google API Ruby Client](https://github.com/google/google-api-ruby-client).

# Getting Started

## Install the gem

Install the gem with:

```sh
gem install knife-google
```

Or, even better, if you're using the ChefDK:

```sh
chef gem install knife-google
```

If you're using Bundler, simply add it to your Gemfile:

```ruby
gem "knife-google", "~> 2.0"
```

... and then run `bundle install`.

## Create a Google Cloud Platform project

Before getting started with this plugin, you must first create a
[Google Cloud Platform](https://cloud.google.com/) (GCP) "project" and add the
Google Compute Engine service to your project.  While GCP has many other services,
such as App Engine and Cloud Storage, this plugin only provides an integration with
Google Compute Engine (GCE). 

## Authentication and Authorization

The [underlying API](https://github.com/google/google-api-ruby-client) this plugin uses relies on the 
[Google Auth Library](https://github.com/google/google-auth-library-ruby) to handle authentication to the
Google Cloud API. The auth library expects that there is a JSON credentials file located at:

`~/.config/gcloud/application_default_credentials.json`

The easiest way to create this is to download and install the [Google Cloud SDK](https://cloud.google.com/sdk/) and run the
`gcloud auth login` command which will create the credentials file for you.

**Update:** `gcloud auth login` no longer writes application default credentials. Please run `gcloud auth application-default login` for appropriate application credentials file.

If you already have a file you'd like to use that is in a different location, set the
`GOOGLE_APPLICATION_CREDENTIALS` environment variable with the full path to that file.

##  Configuration

All knife-google commands require a project name, and most commands require zone name to be supplied.
You can supply these on the command line:

```sh
knife google server list --gce-project my-test-project --gce-zone us-east1-b
```

... or you can set them in your `knife.rb` file:

```ruby
knife[:gce_project] = 'my-test-project'
knife[:gce_zone]    = 'us-east1-b'
```

## SSH Keys

In order to Linux bootstrap nodes, you will first need to ensure your SSH
keys are set up correctly. Ensure your SSH public key is properly entered 
into your project's Metadata tab in the GCP Console. GCE will add your key
to the appropriate user's `~/.ssh/authorized_keys` file when Chef first
connects to perform the bootstrap process.

 * If you don't have one, create a key using `ssh-keygen`
 * Log in to the GCP console, select your project, go to Compute Engine, and go to the Metadata tab.
 * Select the "SSH Keys" tab.
 * Add a new item, and paste in your public key.
    * Note: to change the username automatically detected for the key, prefix your key with the username
      you plan to use as the `--ssh-user` when creating a server. For example, if you plan to connect
      as "chefuser", your key should look like: `chefuser:ssh-rsa AAAAB3N...`
 * Click "Save".

You can find [more information on configuring SSH keys](https://cloud.google.com/compute/docs/instances/adding-removing-ssh-keys) in
the Google Compute Engine documentation.

# Usage

To see all knife-google commands, run: `knife google`

All commands have additional help output. Simply append `--help` to any command. 
For example, to see additional help and flags available for the `knife google disk create` command,
run: `knife google disk create --help`

## knife google disk create DISKNAME

Create a disk in GCE.

### Parameters

 * **DISKNAME**: required. The name of the disk to create.
 * **gce-disk-size**: optional. The size of the disk, in GB, to create. Valid options are between 10 and 10,000. The default is 10.
 * **gce-disk-type**: optional. The type of GCE disk to create, such as `pd-ssd`. Default is `pd-standard`.
 * **gce-disk-source**: optional. Image to use when creating a disk. By default, the disk will be created blank.

### Example

```sh
knife google disk create my-test-disk --gce-disk-type pd-ssd --gce-disk-size 50
```

## knife google disk delete DISKNAME [DISKNAME]

Deletes one or more disks from GCE.

### Parameters

 * **DISKNAME**: required. The name of the disk to delete. You can specify more than one disk to delete at a time.

### Example

```sh
knife google disk delete my-test-disk1 my-test-disk2
```

## knife google disk list

List all disks in the currently-configured GCE project and zone.

### Parameters

None.

## knife google project quotas

Display all project resources and quotas for the currently-configured project, such as the number of snapshots allowed and currently consumed.

### Parameters

None.

## knife google region list

Display all regions available to the currently-configured project, what each region's status is, and what zones exist in each region.

Regions are collections of zones. For additional information on regions, please
refer to the [GCE documentation](https://cloud.google.com/compute/docs/zones).

### Parameters

None.

## knife google region quotas

Display all resources and quotas for all regions in the currently-configured project, such as how many instances are allowed and currently configured in a given region.

### Parameters

None.

## knife google server create INSTANCE_NAME

Create a GCE server instance and bootstrap it with Chef. You must supply an instance name,
a machine type, and an image to use.

For a Linux instance, Chef will connect to the instance over SSH based on the `--ssh-user`
parameter. This user must have SSH keys configured properly in the project's metadata.
See the [SSH Keys](#ssh-keys) section for more information.

### Parameters

 * **INSTANCE_NAME**: required. The name to use when creating the instance.
 * **--gce-machine-type**: required. The machine type to use when creating the server, such as `n1-standard-2` or `n1-highcpu-2-d`.
 * **--gce-network**: The name of the network to which your instance will be attached. Defaults to "default".
 * **--gce-subnet**: The name of the subnet to which your instance will be attached. Only applies to custom networks.
 * **--gce-image**: required. The name of the disk image to use when creating the server. knife-google will search your current project for this disk image. If the image cannot be found but looks like a common public image, the public image project will be searched as well. Additionally, this parameter supports the same image aliases that `gcloud compute instances create` supports. See the output of `gcloud compute instances create --help` for a full list of aliases.
    * Example: if you supply a gce-image of `centos-7-v20160219`, knife-google will first look for an image with that name in your currently-configured project. If it cannot be found, it will look in the `centos-cloud` project.
    * This behavior can be overridden with the `--gce-image-project` parameter.
 * **--gce-image-project**: optional. The name of the GCP project that contains the image specified with the `--gce-image` flag. If this is specified, knife-google will not search any known public projects for your image.
 * **--gce-boot-disk-name**: The name to use when creating the instance's boot disk. Defaults to the instance name.
 * **--gce-boot-disk-size**: The size of the boot disk to create, in GB. Defaults to 10.
 * **--[no-]gce-boot-disk-ssd**: If true, the boot disk will be created as a `pd-ssd` disk type. By default, this is false, and the boot disk will be created as a `pd-standard` disk type.
 * **--[no-]gce-boot-disk-autodelete**: If true, the boot disk will be automatically deleted whenever the instance is deleted. Defaults to true.
 * **--additional_disks**: A comma-separated list of disk names to attach to the instance when creating it. The disks must already exist.
 * **--[no-]gce-auto-server-restart**: If true, the instance will be automatically restarted if it was terminated for non-user-initiated actions, such as host maintenance. Defaults to true.
 * **--[no-]gce-auto-server-migrate**: If true, the instance will be automatically migrated to another host if maintenance would require the instance to be terminated. Defaulst to true.
 * **--[no-]gce-can-ip-forward**: If true, the instance will be allowed to perform network forwarding. Defaults to false.
 * **--gce-tags**: A comma-separated list of tag values to add to the instance.
 * **--gce-metadata**: A comma-separated list of key=value pairs to be added to the instance metadata. Example: `--gce-metadata mykey=myvalue,yourkey=yourvalue`
 * **--gce-service-account-scopes**: A comma-separated list of account scopes for this instance. View a list of scoped by running `gcloud compute instances create --help` and searching for the documentation for the `--scopes` parameter. You must supply the full URI (i.e. "https://www.googleapis.com/auth/devstorage.full_control"), the final part of the URI (i.e. "devstorage.full_control"), or the gcloud alias name (i.e. "storage-rw"). See the output of `gcloud compute instances create --help` for a full list of scopes.
 * **--gce-service-account-name**: the service account name to use when adding service account scopes. This usually looks like an email address and can be created in the Permissions tab of the Google Cloud Console. Defaults to "default"
 * **--gce-use-private-ip**: If true, Chef will attempt to bootstrap the device using the private IP rather than the public IP. Defaulst to false.
 * **--gce-public-ip**: The type of public IP to associate with this instance. If "ephemeral", an ephemeral IP will be assigned. If "none", no public IP will be assigned. If a specific IP address is provided, knife-google will attempt to attach that specific IP address to the instance. Default is "ephemeral".
 * **--gce-email**: required when creating and bootstrapping Microsoft Windows instances. The email address of the currently-logged-in Google Cloud user. This is required when resetting the Windows instance's password.

Additionally, all the normal `knife bootstrap` flags are supported. See the output of `knife bootstrap --help` and `knife google server create --help` for additional information.

### Example

```sh
knife google server create test-instance-1 --gce-image centos-7-v20160219 --gce-machine-type n1-standard-2 --gce-public-ip ephemeral --ssh-user myuser --identity-file /Users/myuser/.ssh/google_compute_engine
```

## knife google server delete INSTANCE_NAME [INSTANCE_NAME]

Deletes one or more GCE server instance. Additionally, if requested, the client and node object
for the given instance will be deleted off of the Chef Server as well.

The boot disk will be deleted as well unless `--no-gce-boot-disk-autodelete` was specified during
the server creation.

### Parameters

 * **INSTANCE_NAME**: required. The name of the GCE instance to delete. You may provide more than one instance to delete.
 * **--purge**: optional. If provided, the instances' client and node objects will be deleted off the Chef Server. Default is NOT to delete the objects.

### Example

```sh
knife google server delete my-instance-1 my-instance-2 --purge
```

## knife google server list

Display the instances in the currently-configured project and zone, their statuses, machine types, IP addresses, and network.

This command will display all instances in the project/zone, even if they weren't created with knife-google.

### Parameters

None.

## knife google server show INSTANCE_NAME

Display information about a single GCE instance, including its status, machine type, IP addresses, and network. Only one server may be displayed at a time.

### Parameters

 * **INSTANCE_NAME**: required. The name of the instance to show.

## knife google zone list

List all available zones in the currently-configured project and what each zone's status is.
A zone is an isolated location within a region that is independent of other
zones in the same region. For additional information on zones, please refer
to the [GCE documentation](https://cloud.google.com/compute/docs/zones).

### Parameters

None.

## Bootstrapping Windows Nodes

WinRM is used by Chef to bootstrap Windows nodes. The default settings of the GCE Windows images and GCP projects are not conducive to successful bootstrapping. Therefore, you will likely need to make some changes to your project settings and create your own image based on your company's policies. Some settings you will likely have to change include:

 * inbound firewall rule in the GCP console to allow inbound WinRM (such as port 5985/tcp)
 * inbound firewall rule in Windows Firewall to allow the inbound WinRM connections
 * enable the appropriate WinRM transports

# License and Authors

Version 3.0.0 of knife-google was rewritten by Chef Partner Engineering but is largely inspired by initial versions of knife-google, thanks to the work of the great folks at Google.

Author:: Chef Partner Engineering (<partnereng@chef.io>)

Copyright:: Copyright (c) 2016 Chef Software, Inc.

License:: Apache License, Version 2.0

Licensed under the Apache License, Version 2.0 (the "License"); you may not use
this file except in compliance with the License. You may obtain a copy of the License at

```
http://www.apache.org/licenses/LICENSE-2.0
```

Unless required by applicable law or agreed to in writing, software distributed under the
License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
either express or implied. See the License for the specific language governing permissions
and limitations under the License.

# Contributing

We'd love to hear from you if you find this isn't working for you. Please submit a GitHub issue with any problems you encounter.

Additionally, contributions are welcome!  If you'd like to send up any fixes or changes:

1. Fork it ( https://github.com/chef/knife-google/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
