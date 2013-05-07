# knife-google

A [knife] (http://wiki.opscode.com/display/chef/Knife) plugin to create, delete and enlist [Google Compute Engine] (https://cloud.google.com/products/compute-engine) instances.

## Installation

* You need to have [google compute access] (https://cloud.google.com/products/compute-engine) 

```sh
    gem install knife-google
```

or, for Gemfile:

```ruby
    gem 'knife-google'
```

##  Uasge

For initial setup, run:

  ```sh
  knife google setup
  ```

If you use the default file location for the token data, then you will not need
to supply the `-f` flag with each run.

Some usage examples follow:

  ```sh
  # to list all instances (including those that may not be managed by Chef)
  knife google instance list -Z <zone>

  # to create an instance
  knife google instance create <instance name> -m <machine type> -I <image> -Z <zone> -i <ssh key file> -x <ssh-user>

  # to delete an instance (along with chef node and api client)
  knife google instance delete <instance> --purge -Z <zone>
  ```

For a full list of commands, run `knife google` without additional arguments:

  ```sh
  % knife google

  ** GCE COMMANDS **
  knife google disk list --zone ZONE (options)
  knife google zone list (options)
  knife google instance delete INSTANCE [INSTANCE] --zone ZONE (options)
  knife google instance create NAME --zone ZONE (options)
  knife google disk create NAME --size N --zone ZONE (options)
  knife google setup
  knife google instance list --zone ZONE (options)
  knife google disk delete NAME --zone ZONE
  ```

## Contributing to changes
  * See [CONTRIB.md](https://github.com/opscode/knife-google/blob/master/CONTRIB.md)

## Licensing
  * See [LICENSE](https://raw.github.com/opscode/knife-google/master/LICENSE)

