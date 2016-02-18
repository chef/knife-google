# knife-google

## Overview

This is the official Chef [Knife](http://docs.chef.io/knife.html) plugin for
[Google Compute Engine](https://cloud.google.com/products/compute-engine).
This plugin gives knife the ability to create, bootstrap, and manage GCE instances.

### Compatibility

Chef 12.x is required. This plugin utilizes the
[Google API Ruby Client](https://github.com/google/google-api-ruby-client).

### Nomenclature

This plugin conforms to the nomenclature used by similar plugins and uses the
term "server" when referencing nodes managed by the plugin. In Google Compute
Engine parlance, this is equivalent to an "instance" or "virtual machine instance".

### Create a Google Cloud Platform project

Before getting started with this plugin, you must first create a
[Google Cloud Platform](https://cloud.google.com/) project and enable the
Google Compute Engine service to your project.

### Authorizing Setup

In order for the knife plugin manage your servers, you will first need to get
credentials using `gcloud auth login`. [Download](https://cloud.google.com/sdk/)
the Google Cloud SDK and review the `gcloud`
[documentation](https://cloud.google.com/sdk/gcloud/reference/auth/login)
for more information.

## Installation

Be sure you are running Chef 12 or higher.

### Bundler

If you're using Bundler, simply add Chef and Knife Google to your `Gemfile`:

```ruby
gem 'chef', '~> 12.0'
gem 'knife-google'
```

If the knife-google gem out of date, the most recent version can be installed
from Github by replacing the `gem 'knife-ec2'` line with the following:

```ruby
gem 'knife-google', :github => 'chef/knife-google'
```

### RubyGems

If you are not using bundler, you can install the gem manually. This plugin is
distributed as a Ruby Gem. Be sure you are running Chef 12 or higher. To install
it, run:

```sh
$ gem install chef -v '~> 12.0'
$ gem install knife-google
```

### Github

To build the gem from the knife-google source code on Github:

```sh
$ git clone https://github.com/chef/knife-google.git
$ cd knife-google
$ rake install
```

## Configuration

### Setting up the plugin

For initial setup, you must first have created your Google Cloud Platform
project, enabled Google Compute Engine, and authorized as described
above.

### Bootstrap Preparation and SSH

In order to bootstrap nodes, you will first need to ensure your SSH keys are set
up correctly. In Google Compute Engine, you can store SSH keys in project
metadata that will get copied over to new servers and placed in the appropriate
user's `~/.ssh/authorized_keys` file.

If you don't already have SSH keys set up, you can create them with the
`ssh-keygen` program. Open up the Metadata page from the GCE section of the
cloud console. If it doesn't already exist, create a new `sshKeys` key and paste
in your user's `~/.ssh/id_rsa.pub` file; make sure to prefix the entry with the
username that corresponds to the username specified with the `-x`
(aka `--ssh-user`) argument of the knife command or its default value of `root`.
An example entry should look something like this -- notice the prepended
username of `myuser`:

```
myuser:ssh-rsa AYAAB3Nwejwejjfjawlwl990sefjsfC5lPulcP4eZB+z1zcMF
76gTV4vojT/SWXymTfGpBL2KHTmF4jnGfEKPwjHIiLrZNHM2ISMi/atlKjOoUCVT
AvUyjqqp3z2KVXSP9P50Kgf8JYWjjXKApiZHkJOHJZ8GGf7aTnRU9NEGLbQK6Q1k
4UHbVG4ps4kSLWsJ7eVcu981GvlwP3ooiJ6YWcOX9PS58d4SNtq41/XaoLibKt/Y
Wzd/4tjYwMRVcxJdAy1T2474vkU/Qr7ibFinKeJymgouoQpEGhF64cF2pncCcmR7
zRk7CzL3mhcma8Zvwj234-2f3/+234/AR#@R#y1EEFsbzGbxOJfEVSTgJfvY7KYp
329df/2348sd3ARTx99 mymail@myhost
```

## Usage

### Optional knife.rb defaults

Setting these values in `knife.rb` file will eliminate having to specify the GCE
project and zone each time you use `knife-google`.

```
knife[:gce_project] = "myproject"
knife[:gce_zone]    = "us-central1-a"
```

### Examples

Some usage examples follow:

```sh
# List all servers (including those that may not be managed by Chef)
$ knife google server list

# Create a server
$ knife google server create www1 -m n1-standard-1 -I ubuntu-1204-precise-v20150316 -x jdoe --gce-zone us-central1-a

# Create a server with service account scopes
$ knife google server create www1 -m n1-standard-1 -I ubuntu-1204-precise-v20150316 -x jdoe --gce-zone us-central1-a --gce-service-account-scopes https://www.googleapis.com/auth/userinfo.email,https://www.googleapis.com/auth/compute,https://www.googleapis.com/auth/devstorage.full_control

# Delete a server (and purge from the Chef server)
$ knife google server delete www1 --purge

# See a list of all zones and their status
$ knife google zone list
```

For a full list of commands, run `knife google` without additional arguments:

```sh
$ knife google

** GOOGLE COMMANDS **
knife google disk create NAME --gce-disk-size N (options)
knife google disk delete NAME (options)
knife google disk list (options)
knife google project quotas
knife google region quotas
knife google server create NAME -m MACHINE_TYPE -I IMAGE (options)
knife google server delete SERVER [SERVER] (options)
knife google server list
knife google zone list
```

More detailed help can be obtained by specifying sub-commands. For example,

```sh
$ knife google server list --help
knife google server list
    -s, --server-url URL             Chef Server URL
        --chef-zero-host HOST        Host to start chef-zero on
        --chef-zero-port PORT        Port (or port range) to start chef-zero on. Port ranges like 1000,1010 or 8889-9999 will try all given ports until one works.
    -k, --key KEY                    API Client Key
        --[no-]color                 Use colored output, defaults to false on Windows, true otherwise
    -c, --config CONFIG              The configuration file to use
        --defaults                   Accept default values for all questions
    -d, --disable-editing            Do not open EDITOR, just accept the data as is
    -e, --editor EDITOR              Set the editor to use for interactive commands
    -E, --environment ENVIRONMENT    Set the Chef environment (except for in searches, where this will be flagrantly ignored)
    -F, --format FORMAT              Which format to use for output
        --gce-project PROJECT        Your Google project
    -Z, --gce-zone ZONE              The Zone for server listing
        --[no-]listen                Whether a local mode (-z) server binds to a port
    -z, --local-mode                 Point knife commands at local repository instead of server
    -u, --user USER                  API Client Username
        --print-after                Show the data after a destructive operation
    -V, --verbose                    More verbose output. Use twice for max verbosity
    -v, --version                    Show chef version
    -y, --yes                        Say yes to all prompts for confirmation
    -h, --help                       Show this message
```

## Sub-commands

### `knife google zone list`

A zone is an isolated location within a region that is independent of other
zones in the same region. For additional information on zones, please refer
to the GCE [documentation](https://cloud.google.com/compute/docs/zones).

Use this command to list out the available Google Compute Engine zones and
their status.

```sh
$ knife google zone list
name            status
asia-east1-b    up
asia-east1-a    up
asia-east1-c    up
europe-west1-b  up
europe-west1-c  up
europe-west1-d  up
us-central1-f   up
us-central1-a   up
us-central1-b   up
us-central1-c   up
```

This information is also available using `gcloud`:

```sh
$ gcloud compute zones list
```

### `knife google region quotas`

Regions are collections of zones. For additional information on regions, please
refer to the GCE [documentation](https://cloud.google.com/compute/docs/zones).

Use this command to list all available regions and their quota information.

```sh
$ knife google region quotas
region        quota               limit    usage
asia-east1    cpus                24.0     0.0
asia-east1    disks_total_gb      10240.0  0.0
asia-east1    static_addresses    7.0      0.0
asia-east1    in_use_addresses    23.0     0.0
asia-east1    ssd_total_gb        2048.0   0.0
asia-east1    local_ssd_total_gb  6000.0   0.0
asia-east1    instances           240.0    0.0
europe-west1  cpus                24.0     0.0
europe-west1  disks_total_gb      10240.0  0.0
europe-west1  static_addresses    7.0      0.0
europe-west1  in_use_addresses    23.0     0.0
europe-west1  ssd_total_gb        2048.0   0.0
europe-west1  local_ssd_total_gb  6000.0   0.0
europe-west1  instances           240.0    0.0
us-central1   cpus                24.0     1.0
us-central1   disks_total_gb      10240.0  20.0
us-central1   static_addresses    7.0      1.0
us-central1   in_use_addresses    23.0     1.0
us-central1   ssd_total_gb        2048.0   10.0
us-central1   local_ssd_total_gb  6000.0   0.0
us-central1   instances           240.0    1.0
```

This information is also available using `gcloud`:

```sh
$ gcloud compute regions list
```

### `knife google project quotas`

All Google Compute Engine resources belong to a project.

Use this command to list your project's current usage.

```sh
$ knife google project quotas
project          quota                limit   usage
myproject        snapshots            1000.0  1.0
myproject        networks             5.0     2.0
myproject        firewalls            100.0   6.0
myproject        images               100.0   1.0
myproject        static_addresses     7.0     0.0
myproject        routes               100.0   4.0
myproject        forwarding_rules     15.0    0.0
myproject        target_pools         50.0    0.0
myproject        health_checks        50.0    1.0
myproject        in_use_addresses     23.0    0.0
myproject        target_instances     50.0    0.0
myproject        target_http_proxies  10.0    0.0
myproject        url_maps             10.0    0.0
myproject        backend_services     3.0     0.0
myproject        target_vpn_gateways  5.0     0.0
myproject        vpn_tunnels          10.0    0.0
```

This information is also available using `gcloud`:

```sh
$ gcloud compute project-info describe
```

### `knife google server create`

Use this command to create a new Google Compute Engine server (instance).
You must specify a name, machine type, zone and boot disk image name.
Images provided by Google follow this naming convention:

```
debian-7-wheezy-vYYYYMMDD
centos-7-vYYYYMMDD
```

By default, knife-google will look for the specified image in the instance's
primary project first and then consult GCE's officially supported image
locations. The `--gce-image-project-id IMAGE_PROJECT_ID` option can be specified
to force the plugin to look for the image in an alternate project location.

Note that if you are bootstrapping the node, make sure to follow the preparation
instructions earlier and use the `-x` arguments to specify the username for the
matching SSH key metadata.

If you would like to set up your server with a service account, provide the
`--gce-service-account-scopes` argument during server creation. The service
account associated with your project will be used by default unless otherwise
specified with the optional `--gce-service-account-name` argument.

See the extended options that also allow bootstrapping the node with
`knife google server create --help`.

### `knife google server delete`

This command terminates and deletes a server. Use the `--purge` option to also
remove it from Chef.

Note that persistent disks associated with the server. Boot disks are deleted
only if `--gce-boot-disk-autodelete` was specified when creating the server.
To delete persistent disks use `knife google disk delete`.

See the extended options with `knife google server delete --help`.

### `knife google server list`

Get a list of servers in the specified zone.  Note that this may include servers
that are *not* managed by Chef.

```sh
$ knife google server list
name    status
www1    running
```

### `knife google disk create`

Create a new disk. You must provide a name, size in gigabytes and zone.

### `knife google disk delete`

Delete an existing disk in the specified zone. Note that the disk will *not* be
deleted if it is currently attached to a running server.

### `knife google disk list`

See a listing of disks defined for a specific zone.

```sh
$ knife google disk list
name    zone           source image                  size (GB)  status
www1    us-central1-a  ubuntu-1404-trusty-v20150316  10         ready
disk1   us-central1-a  -                             10         ready
```

## Troubleshooting

## Build and Development

Standard rake commands for building, installing, testing, and uninstalling
the module.

```sh
# Run spec tests
$ rake

# Build and install the module
$ rake install

# Uninstall
$ rake uninstall
```

## Versioning and Release Protocol

Knife-google is released by the maintainer of this source repository to the gem
repository at [RubyGems](https://rubygems.org). Releases are versioned
according to [SemVer](http://semver.org) as much as possible, with a specific
provision for GCE API changes:

* When the implementation of knife-google switches to a new GCE API revision,
  the minor version **MUST** be incremented.

The version number of the release is simply the gem version. All releases to
RubyGems **MUST** be tagged in git with the version number of the release.

## Contributing

* See [CONTRIB.md](https://github.com/opscode/knife-google/blob/master/CONTRIB.md)

## Licensing

* See [LICENSE](https://raw.github.com/opscode/knife-google/master/LICENSE)
