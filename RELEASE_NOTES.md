<!---
This file is reset every time a new release is done. The contents of this file are for the currently unreleased version.

Example Note:

## Example Heading
Details about the thing that changed that needs to get included in the Release Notes in markdown.
-->
# knife-google 1.3.1 Release Notes :
This release of knife-google contains a fix for an issue where access tokens
could expire during long-running operations such as `knife google server
create`. If you've experienced intermittent failures with your usage of the
knife-google plug-in, you should consider upgrading to this version.

Thanks go to Eric Johnson at Google for the fix.

## knife-google on RubyGems and Github
https://rubygems.org/gems/knife-google
https://github.com/opscode/knife-google

## Issues fixed in knife-google 1.3.1

* KNIFE-473: knife-google should refresh access token

## knife-google Breaking Changes:

None.
