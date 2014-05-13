# knife-google

A [knife] (http://wiki.opscode.com/display/chef/Knife) plugin to create,
delete and enlist
[Google Compute Engine] (https://cloud.google.com/products/compute-engine)
resources.

## Overview

This plugin adds functionality to Chef through a knife plugin to create,
delete, and manage
[Google Compute Engine](https://cloud.google.com/products/compute-engine)
servers and disks.

### Compatibility

This plugin utilizes Google Compute Engine API v1. Please review API v1
[release notes](https://developers.google.com/compute/docs/release-notes#december032013)
for additional information.

With knife-google 1.3.0 options have changed. Several GCE specific short
options have been deprecated and GCE specific long options now start
with '--gce-'.

### Nomenclature

This plugin conforms to the nomenclature used by similar plugins and uses
the term "server" when referencing nodes managed by the plugin.  In
Google Compute Engine parlance, this is equivalent to an "instance" or
"virtual machine instance".

### Create a Google Cloud Platform project

Before getting started with this plugin, you must first create a
[Google Cloud Platform](https://cloud.google.com/) "project" and add the
Google Compute Engine service to your project.  Once you have created your
project, you will have access to other Google Cloud Platform services such as
[App Engine](https://developers.google.com/appengine/),
[Cloud Storage](https://developers.google.com/storage/),
[Cloud SQL](https://developers.google.com/cloud-sql/)
and others, but this plugin only requires you enable Google Compute Engine in
your project.  Note that you will need to be logged in with your Google
Account before creating the project and adding services.

### Authorizing Setup

In order for the knife plugin to programmatically manage your servers, you
will first need to authorize its use of the Google Compute Engine API.
Authorization to use any of Google's Cloud service API's utilizes the
[OAuth 2.0](https://developers.google.com/accounts/docs/OAuth2) standard.
Once your project has been created, log in to your Google Account and visit the
[API Console](http://code.google.com/apis/console) and follow the "APIs & auth"
menu.  Select "Credentials".  Under the "OAuth" section, select "Create New
Client ID".  Specify the [Installed Application](https://developers.google.com/accounts/docs/OAuth2#installed)
Application type with sub-type "Other", then "Create Client ID".  These
actions will generate a new "Client ID", "Client secret", and "Redirect URI's".

This knife plugin includes a 'setup' sub-command that requires you to
supply the client ID and secret in order to obtain an "authorization
token". You will only need to run this command one time and the plugin
will record your credential information and tokens for future API calls.

## Installation

Be sure you are running Chef version 0.10.0 or higher in order to use knife
plugins.

```sh
    gem install knife-google
```

or, for Gemfile:

```ruby
    gem 'knife-google'
```

There is a long standing issue in Ruby where the net/http library by default
does not check the validity of an SSL certificate during a TLS handshake.

To configure Windows system to validate SSL certificate please download
[cacert.pem](http://curl.haxx.se/ca/cacert.pem) file and save to C: drive.
Now make ruby aware of your certificate authority by setting SSL_CERT_FILE.

To set this in your current command prompt session, type:

```sh
    set SSL_CERT_FILE = C:\cacert.pem
```

On Linux system the configuration for SSL certificate validation is present by default.

Depending on your system's configuration, you may need to run this command
with root/Administrator privileges.

##  Configuration

### Setting up the plugin

For initial setup, you must first have created your Google Cloud Platform
project, enabled Google Compute Engine, and set up the Client ID described
above.  Run the 'setup' sub-command and supply the Project ID, the Client
ID, Client secret, and authorization tokens when prompted. It will also
prompt you to open a URL in a browser. Make sure sure the you are logged
in with the Google account associated with the project and client
id/secrete in order to authorize the plugin.

  ```sh
  knife google setup
  ```

By default, the credential and token information will be stored in
`~/.google-compute.json`.  You can override this location with
`-f <credential_file>` flag with all plugin commands.

### Bootstrap Preparation and SSH

In order to bootstrap nodes, you will first need to ensure your SSH
keys are set up correctly.  In Google Compute Engine, you can store
SSH keys in project metadata that will get copied over to new servers
and placed in the appropriate user's `~/.ssh/authorized_keys` file.

If you don't already have SSH keys set up, you can create them with
the `ssh-keygen` program.  Open up the Metadata page from the
GCE section of the cloud console.  If it doesn't already exist, create
a new `sshKeys` key and paste in your user's `~/.ssh/id_rsa.pub`
file; make sure to prefix the entry with the username that corresponds
to the username specified with the `-x` (aka `--ssh-user`) argument of the knife 
command or its default value of `root`.  An example entry should look
something like this -- notice the prepended username of `myuser`:

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

Some usage examples follow:

  ```sh
  # See a list of all zones, their statuses and maintenance windows
  $ knife google zone list

  # List all servers (including those that may not be managed by Chef)
  $ knife google server list -Z us-central1-a

  # Create a server
  $ knife google server create www1 -m n1-standard-1 -I debian-7-wheezy-v20131120 -Z us-central1-a -i ~/.ssh/id_rsa -x jdoe

  # Create a server with service account scopes
  $ knife google server create www1 -m n1-standard-1 -I debian-7-wheezy-v20131120 -Z us-central1-a -i ~/.ssh/id_rsa -x jdoe --gce-service-account-scopes https://www.googleapis.com/auth/userinfo.email,https://www.googleapis.com/auth/compute,https://www.googleapis.com/auth/devstorage.full_control

  # Delete a server (along with Chef node and API client via --purge)
  $ knife google server delete www1 --purge -Z us-central1-a
  ```

For a full list of commands, run `knife google` without additional arguments:

  ```sh
  $ knife google

  ** GOOGLE COMMANDS **
  knife google disk create NAME --gce-disk-size N -Z ZONE (options)
  knife google disk delete NAME -Z ZONE (options)
  knife google disk list -Z ZONE (options)
  knife google project list (options)
  knife google region list (options)
  knife google server create NAME -m MACHINE_TYPE -I IMAGE -Z ZONE (options)
  knife google server delete SERVER [SERVER] -Z ZONE (options)
  knife google server list -Z ZONE (options)
  knife google setup
  knife google zone list (options)
  ```

More detailed help can be obtained by specifying sub-commands.  For
instance,

  ```sh
  $ knife google server list -Z us-central1-a --help
  knife google server list -Z ZONE (options)
    -s, --server-url URL             Chef Server URL
        --chef-zero-port PORT        Port to start chef-zero on
    -k, --key KEY                    API Client Key
        --[no-]color                 Use colored output, defaults to false on Windows, true otherwise
    -f CREDENTIAL_FILE,              Google Compute credential file (google setup can create this)
        --gce-credential-file
    -c, --config CONFIG              The configuration file to use
        --defaults                   Accept default values for all questions
    -d, --disable-editing            Do not open EDITOR, just accept the data as is
    -e, --editor EDITOR              Set the editor to use for interactive commands
    -E, --environment ENVIRONMENT    Set the Chef environment
    -F, --format FORMAT              Which format to use for output
    -z, --local-mode                 Point knife commands at local repository instead of server
    -u, --user USER                  API Client Username
        --print-after                Show the data after a destructive operation
    -V, --verbose                    More verbose output. Use twice for max verbosity
    -v, --version                    Show chef version
    -y, --yes                        Say yes to all prompts for confirmation
    -Z, --gce-zone ZONE              The Zone for this server (required)
    -h, --help                       Show this message
  ```

## Sub-commands

### knife google setup

Use this command to initially set up authorization (see above for more
details).  Note that if you override the default credential file with the
`-f` switch, you'll need to use the `-f` switch for *all* sub-commands.
When prompted, make sure to specify the "Project ID" (and not the name or
number) or you will see 404/not found errors even if the setup command
completes successfully.

### knife google zone list

A zone is an isolated location within a region that is independent of
other zones in the same region. Zones are designed to support instances
or applications that have high availability requirements. Zones are
designed to be fault-tolerant, so that you can distribute instances
and resources across multiple zones to protect against the system
failure of a single zone. This keeps your application available even
in the face of expected and unexpected failures. The fully-qualified
name is made up of `<region>/<zone>`. For example, the fully-qualified
name for zone `a` in region `us-central1` is `us-central1-a`. Depending on
how widely you want to distribute your resources, you may choose to
create instances across multiple zones within one region or across
multiple regions and multiple zones.

Use this command to list out the available Google Compute Engine zones.
You can find a zone's current status and upcoming maintenance windows.

The output for `knife google zone list` should look similar to:

  ```
  name            status  deprecation  maintainance window
  europe-west1-a  up      -            2014-01-18 12:00:00 -0800 to 2014-02-02 12:00:00 -0800
  europe-west1-b  up      -            2014-03-15 12:00:00 -0700 to 2014-03-30 12:00:00 -0700
  us-central1-a   up      -            -
  us-central1-b   up      -            -
  ```

### knife google region list

Each region in Google Compute Engine contains any number of zones.
The region describes the geographic location where your resources
are stored. For example, a zone named `us-east1-a` is in region `us-east1`.
A region contains one or more zones.

Choose a region that makes sense for your scenario. For example, if you
only have customers on the east coast of the US, or if you have specific
needs that require your data to live in the US, it makes sense to store
your resources in a zone with a us-east region.

Use this command to list out the available Google Compute Engine regions.
You can find the region's current status, cpus, disks-total-gb,
in-use-addresses and static-addresses. Use the `-L` switch to also list
the quota limit for each resource.

The output for `knife google region list -L` should look similar to:

  ```
  Name          status  deprecation  cpus  disks-total-gb  in-use-addresses  static-addresses
  europe-west1  up      -            1/10  100/100000      1/10              1/7
  us-central1   up      -            0/10  0/100000        0/10              0/7
  us-central2   up      -            1/10  50/100000       1/10              1/7
  ```

### knife google project list

A project resource is the root collection and settings resource for
all Google Compute Engine resources.

Use this command to list out your project's current usage of snapshots,
networks, firewalls, images, routes, forwarding-rules, target-pools and
health-checks. Use the `-L` switch to also list the quota limit for
each resource.

The output for `knife google project list -L` should look similar to:

  ```
  name        snapshots  networks  firewalls  images  routes forwarding-rules  target-pools  health-checks
  chef-test1  0/1000     1/5       3/100      0/100   2/100  0/50              0/50          0/50
  chef-test2  1/1000     2/5       3/100      1/100   2/100  0/50              0/50          0/50
  ```

### knife google server create

Use this command to create a new Google Compute Engine server (a.k.a.
instance) with a persistent boot disk. You must specify a name, the
machine type, the zone, and the the image name. Images provided by
Google follow this naming convention:

  ```
  debian-7-wheezy-vYYYYMMDD
  centos-6-vYYYYMMDD
  ```

By default, the plugin will look for the specified image in the instance's
primary project first and then consult GCE's officially supported image
locations. The `--gce-image-project-id IMAGE_PROJECT_ID` option can be 
specified to force the plugin to look for the image in an alternate project
location.

Note that if you are bootstrapping the node, make sure to follow the 
preparation instructions earlier and use the `-x` and `-i` commands 
to specify the username and the identity file for that user.  Make sure 
to use the private key file (e.g. `~/.ssh/id_rsa`) for the identity 
file and *not* the public key file.

If you would like to set up your server with a service account, provide
the --gce-service-account-scopes argument during server creation. The service
account associated with your project will be used by default unless otherwise
specified with the optional --gce-service-account-name argument.

See the extended options that also allow bootstrapping the node with
`knife google server create --help`.

### knife google server delete

This command terminates and deletes a server.  Use the `--purge`
option to also remove it from Chef.

Note that persistent disks associated with the server, including the
boot disk, are not deleted with this operation. To delete persistent
disks use `knife google disk delete`.

Use `knife google server delete --help` for other options.

### knife google server list

Get a list of servers in the specified zone.  Note that this may
include servers that are *not* managed by Chef. Your output should
look something like:

  ```
  name              type             public ip        private ip      disks               zone           status
  chef-server       n1-standard-1    103.59.80.113    10.240.45.78    chef-server         us-central1-a  running
  chef-workstation  n1-standard-1    103.59.85.188    10.240.9.140    chef-workstation    us-central1-a  running
  fuse-dev          n1-standard-1    103.59.80.147    10.240.166.18   fuse-dev            us-central1-a  running
  magfs-c1          n1-standard-2    103.59.87.217    10.240.61.92    magfs-c1            us-central1-a  running
  magfs-c2          n1-standard-2    103.59.80.161    10.240.175.240  magfs-c2            us-central1-a  running
  magfs-c3          n1-standard-2    178.255.120.69   10.240.34.197   magfs-c3            us-central1-a  running
  magfs-svr         n1-standard-4    103.59.80.178    10.240.81.25    magfs-svr           us-central1-a  running
  ```

### knife google disk create

Create a new persistent disk. You must provide a name, size in
gigabytes, and the desired zone.

### knife google disk delete

Delete an existing disk in the specified zone. Note that the
disk will *not* be deleted if it is currently attached to a
running server.

### knife google disk list

See a listing of disks defined for a specific zone. Your output should
look something like:

  ```
  name              zone            source snapshot   size (in GB)   status
  dev-1             us-central1-a                     10             ready 
  dev-2             us-central1-a                     10             ready 
  test-1            us-central1-a                     20             ready 
  ```

## Troubleshooting

 * Seeing 404 errors or zone not found?
   This can result if you mistakenly specified an invalid "Project ID"
   while going through the `knife google setup` command.  Make sure
   you specified the "Project ID" (not the project name or number).

## Build and Development

Standard rake commands for building, installing, testing, and uninstalling the module.

  ```
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

The version number of the release is simply the gem version. All releases to RubyGems **MUST** be tagged in git with the version number of the release.

## Contributing
  * See [CONTRIB.md](https://github.com/opscode/knife-google/blob/master/CONTRIB.md)

## Licensing
  * See [LICENSE](https://raw.github.com/opscode/knife-google/master/LICENSE)
