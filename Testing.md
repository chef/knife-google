## Manual Testing Prerequisite:

To work with knife google commands following setup needs to be done.

Configure google authentication and authorization as suggested [here](https://github.com/chef/knife-google#authentication-and-authorization).

To work with knife google command you should create GCP project and assign zone and region to that project

**Ref:** https://cloud.google.com/resource-manager/docs/creating-managing-projects
https://cloud.google.com/compute/docs/regions-zones/changing-default-zone-region

Some useful Google cloud commands which you can use with Google Cloud command line interface [#REF](https://cloud.google.com/compute/docs/gcloud-compute/#set_default_zone_and_region_in_your_local_client)

``` gcloud projects create PROJECT_ID ```

``` gcloud config configurations activate CONFIGURATION_NAME ```

``` gcloud config set compute/zone ZONE ```

``` gcloud config set compute/zone ZONE ```

Once the above setup is done get the PROJECT_ID and Zone and set it in your knife configuration file(knife.rb/config.rb).
```
knife[:gce_project] = 'my-test-project'
knife[:gce_zone]    = 'us-east1-b'
```
**NOTE** Not providing `gce_project` and `gce_zone` in knife configuartion file will run into following errors while running any knife google command.

```
ERROR: The following required parameters are missing: gce_project, gce_zone
ERROR: RuntimeError: The following required parameters are missing: gce_project, gce_zone
```

## Valid knife google commands

```
knife google disk create NAME --gce-disk-size N (options)
knife google disk delete NAME [NAME] (options)
knife google disk list
knife google project quotas
knife google region list
knife google region quotas
knife google server create NAME -m MACHINE_TYPE -I IMAGE (options)
knife google server delete INSTANCE_NAME [INSTANCE_NAME] (options)
knife google server list
knife google server show INSTANCE_NAME (options)
knife google zone list
```