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

### Nomenclature

This plugin conforms to the nomenclature used by similar plugins and uses
the term "server" when referencing nodes managed by the plugin.  But in
Google Compute Engine parlance, this is equivalent to an "instance" or
"virtual machine instance".

### Create a Google Cloud Platform project

Before getting started with this plugin, you must first create a
[Google Cloud Platform](https://cloud.google.com/) "project" and add the
Google Compute Engine service to your project.  Once you have created your
project, you will have access to other Google Cloud Platform services such as
[App Egnine](https://developers.google.com/appengine/),
[Cloud Storage](https://developers.google.com/storage/),
[Cloud SQL](https://developers.google.com/cloud-sql/)
and others, but this plugin only requires you enable Google Compute Engine in
your project.  Note that you will need to be logged in with your Google
Account before creating the project and adding services.

### Authorizing Setup

In order for the knife plugin to programatically manage your servers, you
will first need to authorize its use of the Google Compute Engine API.
Authorization to use any of Google's Cloud service API's utilizes the
[OAuth 2.0](https://developers.google.com/accounts/docs/OAuth2) standard.
Once your project has been created, log in to your Google account and visit the
[API Console](http://code.google.com/apis/console) and follow the "API Access"
menu.  Create a new "Client ID" and specify the
[Installed Application](https://developers.google.com/accounts/docs/OAuth2#installed)
Application type with sub-type "Other".  These actions will generate a new
"Client ID", "Client secret", and "Redirect URI's".

This knife plugin includes a 'setup' sub-command that requires you to supply
the client ID and secret in order to obtain an "authorization token".  You
will only need to run this command one time and the plugin will record your
credential information and tokens for future API calls.

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

Depending on your system's configuration, you may need to run this command
with root/Administrator privileges.

##  Configuration

### Setting up the plugin

For initial setup, you must first have created your Google Cloud Platform
project, enabled Google Compute Engine, and set up the Client ID described
above.  Run the 'setup' sub-command and supply the Project ID (not your
project name or number), the Client ID, client secret, and authorization
tokens when prompted.  It will also prompt you to open a URL in a browser.
Make sure sure the you are logged in with the Google account associated
with the project and client id/secrete in order to authorize the plugin.

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
file (make sure to prefix the entry with the username).  An example
entry should look something like this (note the prepended username of
`adamed`:

  ```
  adamed:ssh-rsa AYAAB3Nwejwejjfjawlwl990sefjsfC5lPulcP4eZB+z1zcMF
  76gTV4vojT/SWXymTfGpBL2KHTmF4jnGfEKPwjHIiLrZNHM2ISMi/atlKjOoUCVT
  AvUyjqqp3z2KVXSP9P50Kgf8JYWjjXKApiZHkJOHJZ8GGf7aTnRU9NEGLbQK6Q1k
  4UHbVG4ps4kSLWsJ7eVcu981GvlwP3ooiJ6YWcOX9PS58d4SNtq41/XaoLibKt/Y
  Wzd/4tjYwMRVcxJdAy1T2474vkU/Qr7ibFinKeJymgouoQpEGhF64cF2pncCcmR7
  zRk7CzL3mhcma8Zvwj234-2f3/+234/AR#@R#y1EEFsbzGbxOJfEVSTgJfvY7KYp
  329df/2348sd3ARTx99 adamedwards@myhost
  ```

## Usage

Some usage examples follow:

  ```sh
  # See a list of all zones, their statuses and maintenance windows
  $ knife google zone list

  # List all servers (including those that may not be managed by Chef)
  $ knife google server list -Z us-central2-a

  # Create a server
  $ knife google server create www1 -m n1-standard-1 -I centos-6-v20130325 -Z us-central2-a -i ~/.ssh/id_rsa -x jdoe

  # Delete a server (along with Chef node and API client via --purge)
  $ knife google server delete www1 --purge -Z us-central2-a
  ```

For a full list of commands, run `knife google` without additional arguments:

  ```sh
  $ knife google

  ** GOOGLE COMMANDS **
  knife google disk list --google-compute-zone ZONE (options)
  knife google zone list (options)
  knife google server delete SERVER [SERVER] --google-compute-zone ZONE (options)
  knife google server create NAME --google-compute-zone ZONE (options)
  knife google disk create NAME --google-disk-size N --google-compute-zone ZONE (options)
  knife google setup
  knife google server list --google-compute-zone ZONE (options)
  knife google disk delete NAME --google-compute-zone ZONE
  ```

More detailed help can be obtained by specifying sub-commands.  For
instance,

  ```sh
  $ knife google server list -Z foo --help
  knife google server list --google-compute-zone ZONE (options)
      -s, --server-url URL             Chef Server URL
      -k, --key KEY                    API Client Key
          --[no-]color                 Use colored output, defaults to enabled
      -f CREDENTIAL_FILE,              Google Compute credential file (google setup can create this)
          --google-compute-credential-file
      -c, --config CONFIG              The configuration file to use
          --defaults                   Accept default values for all questions
      -d, --disable-editing            Do not open EDITOR, just accept the data as is
      -e, --editor EDITOR              Set the editor to use for interactive commands
      -E, --environment ENVIRONMENT    Set the Chef environment
      -F, --format FORMAT              Which format to use for output
      -u, --user USER                  API Client Username
          --print-after                Show the data after a destructive operation
      -V, --verbose                    More verbose output. Use twice for max verbosity
      -v, --version                    Show chef version
      -y, --yes                        Say yes to all prompts for confirmation
      -Z, --google-compute-zone ZONE   The Zone for this server (required)
      -h, --help                       Show this message
  ```

## Sub-commands

### knife google setup

Use this command to initially set up authorization (see above for more
details).  Note that if you override the default credential file with the
`-f` parameter, you'll need to use the `-f` switch for *all* sub-commands.
When prompted, make sure to specify the "Project ID" (and not the name or
number) or you will see 404/not found errors even if the setup command
completes successfully.

### knife google zone list

Use this command to list out the available Google Compute Engine zones.
You can find a zone's current status, number of deployed servers, disks,
and upcoming maintenance windows.  The output should look similar to:

  ```
  Name            Status  Servers  Disks  Maintainance Window                                   
  europe-west1-a  up      0        0      2013-08-03 19:00:00 +0000 to 2013-08-18 19:00:00 +0000
  europe-west1-b  up      0        0      2013-05-11 19:00:00 +0000 to 2013-05-26 19:00:00 +0000
  us-central1-a   up      0        1      2013-08-17 19:00:00 +0000 to 2013-09-01 19:00:00 +0000
  us-central1-b   up      0        0      2013-06-08 19:00:00 +0000 to 2013-06-23 19:00:00 +0000
  us-central2-a   up      10       6      2013-05-25 19:00:00 +0000 to 2013-06-09 19:00:00 +0000
  ```

### knife google server create

Use this command to create a new Google Compute Engine server (a.k.a.
instance).  You must specify a name, the machine type, the zone, and
image.  Note that if you are bootstrapping the node, make sure to
follow the preparation instructions earlier and use the `-x` and
`-i` commands to specify the username and the identify file for
that user.  Make sure to use the private key file (e.g. `~/.ssh/id_rsa`)
for the identity file and *not* the public key file.

See the extended options that also allow bootstrapping the node with
`knife google server create --help`.

### knife google server delete

This command terminates and deletes a server.  Use the `--purge`
option to also remove it from Chef.  Use `knife google server
delete --help` for other options.

### knife google server list

Get a list of servers in the specified zone.  Note that this may
include servers that are *not* managed by Chef.  Your output should
look something like:

  ```
  Name              Type           Image                 Public IP        Private IP      Disks               Zone           Status 
  chef-svr          n1-standard-1  gcel-12-04-v20130325  103.59.80.113    10.240.45.78                        us-central2-a  running
  chef-workstation  n1-standard-1  gcel-12-04-v20130325  103.59.85.188    10.240.9.140                        us-central2-a  running
  fuse-dev          n1-standard-1  gcel-12-04-v20130225  103.59.80.147    10.240.166.18   pd-fuse             us-central2-a  running
  magfs-c1          n1-standard-2  gcel-12-04-v20130225  103.59.87.217    10.240.61.92                        us-central2-a  running
  magfs-c2          n1-standard-2  gcel-12-04-v20130225  103.59.80.161    10.240.175.240                      us-central2-a  running
  magfs-c3          n1-standard-2  gcel-12-04-v20130325  178.255.120.69   10.240.34.197   jay-scratch         us-central2-a  running
  magfs-svr         n1-standard-4  gcel-12-04-v20130225  103.59.80.178    10.240.81.25    pd28g               us-central2-a  running
  ```

### knife google disk create

Create a new persistent disk.  You must provide a name, size in
gigabytes, and the desired zone.

### knife google disk delete

Delete an existing disk in the specified zone.  Note that the
disk will *not* be deleted if it is currently attached to a
running server.

### knife google disk list

See a listing of disks defined for a specific zone.  For example,

  ```
  Name                Zone           Source Snapshot  Size (In GB)  Status
  jay-scratch         us-central2-a                   10            ready 
  pd-fuse             us-central2-a                   10            ready 
  pd28g               us-central2-a                   28            ready 
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
## Contributing
  * See [CONTRIB.md](https://github.com/opscode/knife-google/blob/master/CONTRIB.md)

## Licensing
  * See [LICENSE](https://raw.github.com/opscode/knife-google/master/LICENSE)

