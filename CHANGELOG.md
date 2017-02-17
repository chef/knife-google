# Change Log

## [3.1.1](https://github.com/chef/knife-google/tree/v3.1.1)

[Full Changelog](https://github.com/chef/knife-google/compare/v3.1.0...v3.1.1)

**Closed issues:**

- Can't Modify Frozen String [\#118](https://github.com/chef/knife-google/issues/118)

**Merged pull requests:**

- Fix for \#118 [\#119](https://github.com/chef/knife-google/pull/119) ([jjasghar](https://github.com/jjasghar))

## [v3.1.0](https://github.com/chef/knife-google/tree/v3.1.0) (2016-11-08)
[Full Changelog](https://github.com/chef/knife-google/compare/v3.0.0...v3.1.0)

**Closed issues:**

- No support for GCE image family [\#108](https://github.com/chef/knife-google/issues/108)

**Merged pull requests:**

- v3.1.0 [\#115](https://github.com/chef/knife-google/pull/115) ([jjasghar](https://github.com/jjasghar))
- Move deps to the Gemfile [\#114](https://github.com/chef/knife-google/pull/114) ([tas50](https://github.com/tas50))
- make public\_ip work for any case 'none' at 'instance\_access\_configs\_for' [\#106](https://github.com/chef/knife-google/pull/106) ([abhishekkr](https://github.com/abhishekkr))

## [v3.0.0](https://github.com/chef/knife-google/tree/v3.0.0) (2016-09-28)
[Full Changelog](https://github.com/chef/knife-google/compare/v2.2.1...v3.0.0)

**Merged pull requests:**

- v3.0.0 version [\#113](https://github.com/chef/knife-google/pull/113) ([jjasghar](https://github.com/jjasghar))
- Require Ruby 2.2 and add 2.3 testing [\#111](https://github.com/chef/knife-google/pull/111) ([tas50](https://github.com/tas50))

## [v2.2.1](https://github.com/chef/knife-google/tree/v2.2.1) (2016-09-27)
[Full Changelog](https://github.com/chef/knife-google/compare/v2.2.0...v2.2.1)

**Closed issues:**

- Google::Apis::ClientError [\#107](https://github.com/chef/knife-google/issues/107)

**Merged pull requests:**

- fixed region and zone [\#112](https://github.com/chef/knife-google/pull/112) ([jjasghar](https://github.com/jjasghar))
- v2.2.1: Version bump + Travis Update [\#110](https://github.com/chef/knife-google/pull/110) ([cblecker](https://github.com/cblecker))
- \[Issue \#108\] Matching public image families and adding Ubuntu 16.04 [\#109](https://github.com/chef/knife-google/pull/109) ([nelsonjr](https://github.com/nelsonjr))

## [v2.2.0](https://github.com/chef/knife-google/tree/v2.2.0) (2016-03-17)
[Full Changelog](https://github.com/chef/knife-google/compare/v2.1.0...v2.2.0)

**Implemented enhancements:**

- New Functionality: knife-google unable to spinup servers in subnets [\#89](https://github.com/chef/knife-google/issues/89)
- Creating a preemptible instance flag feature  [\#72](https://github.com/chef/knife-google/issues/72)

**Closed issues:**

- Support an alias for latest public image [\#96](https://github.com/chef/knife-google/issues/96)
- knife google command not working [\#87](https://github.com/chef/knife-google/issues/87)
- Server create command returns error [\#86](https://github.com/chef/knife-google/issues/86)
- Can't execute any command with knife [\#84](https://github.com/chef/knife-google/issues/84)
- google-api-client dependency is about to break APIs [\#75](https://github.com/chef/knife-google/issues/75)
- Feature Request: lists for additional assets [\#73](https://github.com/chef/knife-google/issues/73)
- knife google hides quota errors from GCE [\#71](https://github.com/chef/knife-google/issues/71)
- Dependency conflict building from master [\#65](https://github.com/chef/knife-google/issues/65)
- knife-google master should be deployed to RubyGems [\#57](https://github.com/chef/knife-google/issues/57)
- 400 Error from Google During 'knife google setup' [\#55](https://github.com/chef/knife-google/issues/55)
- Documentation for adding a tag to the server [\#53](https://github.com/chef/knife-google/issues/53)

**Merged pull requests:**

- Adding support for image aliases [\#104](https://github.com/chef/knife-google/pull/104) ([adamleff](https://github.com/adamleff))
- Add support for deploying instance on subnetworks [\#103](https://github.com/chef/knife-google/pull/103) ([adamleff](https://github.com/adamleff))
- adding support for preemptible GCE instances [\#102](https://github.com/chef/knife-google/pull/102) ([adamleff](https://github.com/adamleff))

## [v2.1.0](https://github.com/chef/knife-google/tree/v2.1.0) (2016-03-04)
[Full Changelog](https://github.com/chef/knife-google/compare/v2.0.0...v2.1.0)

**Closed issues:**

- Set application\_name and application\_version [\#100](https://github.com/chef/knife-google/issues/100)
- Support the use of service account scope aliases [\#95](https://github.com/chef/knife-google/issues/95)

**Merged pull requests:**

- Adding application name and version when creating the connection [\#101](https://github.com/chef/knife-google/pull/101) ([adamleff](https://github.com/adamleff))
- add support for service account scope aliases [\#99](https://github.com/chef/knife-google/pull/99) ([adamleff](https://github.com/adamleff))
- README updates, reincorporating changes from \#93 [\#98](https://github.com/chef/knife-google/pull/98) ([adamleff](https://github.com/adamleff))

## [v2.0.0](https://github.com/chef/knife-google/tree/v2.0.0) (2016-03-01)
[Full Changelog](https://github.com/chef/knife-google/compare/1.3.1...v2.0.0)

**Implemented enhancements:**

- Complete rewrite of knife-google gem, replacing use of `fog` with `google-api-ruby-client` [\#66](https://github.com/chef/knife-google/pull/66) ([paulrossman](https://github.com/paulrossman))

**Closed issues:**

- rake install does not work [\#91](https://github.com/chef/knife-google/issues/91)
- Error in metadata parsing while creating a compute instance [\#82](https://github.com/chef/knife-google/issues/82)
- Spinning up a GCP instance from an EC2 instance results in an error [\#81](https://github.com/chef/knife-google/issues/81)
- GCP Service Accounts [\#79](https://github.com/chef/knife-google/issues/79)
- knife-google not setting custom metadata [\#74](https://github.com/chef/knife-google/issues/74)
- `--bootstrap-version` flag isn't working [\#67](https://github.com/chef/knife-google/issues/67)
- knife google server create is having an error boostraping [\#62](https://github.com/chef/knife-google/issues/62)
- no implicit conversion of nil into String on knife google server create [\#61](https://github.com/chef/knife-google/issues/61)
- ERROR: Image 'ubuntu-1404-trusty-v20150316' not found [\#59](https://github.com/chef/knife-google/issues/59)
- knife-google fails with google-api-client \>0.8 [\#44](https://github.com/chef/knife-google/issues/44)
- google-knife and knife dependency versions [\#43](https://github.com/chef/knife-google/issues/43)
- For any command "ERROR: ArgumentError: unknown keyword: interval"  [\#42](https://github.com/chef/knife-google/issues/42)
- Knife google failing to setup [\#40](https://github.com/chef/knife-google/issues/40)
- Password prompt each time I run 'knife google server create' or 'knife bootstrap' with GCE instances [\#39](https://github.com/chef/knife-google/issues/39)
- Failing to create a server with a custom image [\#38](https://github.com/chef/knife-google/issues/38)
- Custom Metadata [\#37](https://github.com/chef/knife-google/issues/37)

**Merged pull requests:**

- Rewrite of knife-google using knife-cloud, adding windows support [\#94](https://github.com/chef/knife-google/pull/94) ([adamleff](https://github.com/adamleff))
- Google api ruby client [\#93](https://github.com/chef/knife-google/pull/93) ([paulrossman](https://github.com/paulrossman))
- Error when installing via `rake install` [\#92](https://github.com/chef/knife-google/pull/92) ([l337ch](https://github.com/l337ch))
- Updated ffi and win32-service versions [\#90](https://github.com/chef/knife-google/pull/90) ([adamedx](https://github.com/adamedx))
- Updated ffi and win32-service versions [\#88](https://github.com/chef/knife-google/pull/88) ([Vasu1105](https://github.com/Vasu1105))
- Changes for fixing the issue with excuting knife google commands. [\#85](https://github.com/chef/knife-google/pull/85) ([Vasu1105](https://github.com/Vasu1105))
- Error in metadata parsing while creating a compute instance [\#83](https://github.com/chef/knife-google/pull/83) ([SinisterLight](https://github.com/SinisterLight))
- Updated release notes and changelog files [\#80](https://github.com/chef/knife-google/pull/80) ([siddheshwar-more](https://github.com/siddheshwar-more))
- Bumping the version to 2.0.0 [\#78](https://github.com/chef/knife-google/pull/78) ([siddheshwar-more](https://github.com/siddheshwar-more))
- Changed option names according to the long options and used locate\_config\_value\_method [\#77](https://github.com/chef/knife-google/pull/77) ([siddheshwar-more](https://github.com/siddheshwar-more))
- Added support for picking options from knife.rb [\#76](https://github.com/chef/knife-google/pull/76) ([siddheshwar-more](https://github.com/siddheshwar-more))
- Fixed --bootstrap-version command line option [\#70](https://github.com/chef/knife-google/pull/70) ([Vasu1105](https://github.com/Vasu1105))
- Change homepage to the GitHub repo. [\#69](https://github.com/chef/knife-google/pull/69) ([mbrukman](https://github.com/mbrukman))
- Added badges: gem version, build status, and deps. [\#68](https://github.com/chef/knife-google/pull/68) ([mbrukman](https://github.com/mbrukman))
- 1.4.3 version bump [\#64](https://github.com/chef/knife-google/pull/64) ([paulrossman](https://github.com/paulrossman))
- bootstrap issue with --gce-public-ip set to none resolved [\#63](https://github.com/chef/knife-google/pull/63) ([Vasu1105](https://github.com/Vasu1105))
- server create support for additional Linux-based operating systems [\#60](https://github.com/chef/knife-google/pull/60) ([paulrossman](https://github.com/paulrossman))
- Fix spec tests [\#58](https://github.com/chef/knife-google/pull/58) ([siddheshwar-more](https://github.com/siddheshwar-more))
- Fix "ERROR: TypeError: no implicit conversion of nil into String"  [\#56](https://github.com/chef/knife-google/pull/56) ([BrentChapman](https://github.com/BrentChapman))
- New pd-ssd option, Gemfile updates [\#54](https://github.com/chef/knife-google/pull/54) ([paulrossman](https://github.com/paulrossman))
- fix formatting [\#52](https://github.com/chef/knife-google/pull/52) ([paulrossman](https://github.com/paulrossman))
- fix for undefined method 'snake\_case' [\#51](https://github.com/chef/knife-google/pull/51) ([paulrossman](https://github.com/paulrossman))
- Formatting and grammar fixes. [\#50](https://github.com/chef/knife-google/pull/50) ([mbrukman](https://github.com/mbrukman))
- Fix formatting, spelling, and grammar. [\#49](https://github.com/chef/knife-google/pull/49) ([mbrukman](https://github.com/mbrukman))
- Format commands in headings with code font. [\#48](https://github.com/chef/knife-google/pull/48) ([mbrukman](https://github.com/mbrukman))
- Remove extra indentation for code blocks and lists. [\#47](https://github.com/chef/knife-google/pull/47) ([mbrukman](https://github.com/mbrukman))
- Allow enabling ip forward when creating instance [\#46](https://github.com/chef/knife-google/pull/46) ([luisbosque](https://github.com/luisbosque))
- Add instance's boot disk autodelete option [\#41](https://github.com/chef/knife-google/pull/41) ([nullbus](https://github.com/nullbus))
- minor typos in setup process [\#36](https://github.com/chef/knife-google/pull/36) ([gmiranda23](https://github.com/gmiranda23))
- updated for console UI changes [\#35](https://github.com/chef/knife-google/pull/35) ([gmiranda23](https://github.com/gmiranda23))
- Adding the ability to insert additional disks on server creation [\#32](https://github.com/chef/knife-google/pull/32) ([snapsam](https://github.com/snapsam))

## [1.3.1](https://github.com/chef/knife-google/tree/1.3.1) (2014-04-25)
[Full Changelog](https://github.com/chef/knife-google/compare/1.2.0...1.3.1)

**Merged pull requests:**

- Update CHANGELOG and release notes for 1.3.1 [\#34](https://github.com/chef/knife-google/pull/34) ([adamedx](https://github.com/adamedx))
- updated readme and minor version bump [\#33](https://github.com/chef/knife-google/pull/33) ([paulrossman](https://github.com/paulrossman))
- Refresh access token [\#31](https://github.com/chef/knife-google/pull/31) ([erjohnso](https://github.com/erjohnso))
- Add release and versioning protocol documentation [\#29](https://github.com/chef/knife-google/pull/29) ([adamedx](https://github.com/adamedx))

## [1.2.0](https://github.com/chef/knife-google/tree/1.2.0) (2014-02-17)
[Full Changelog](https://github.com/chef/knife-google/compare/1.1.0...1.2.0)

**Merged pull requests:**

- Get google plugin working for knife bootstrapping on GCE instances. [\#28](https://github.com/chef/knife-google/pull/28) ([anthonyu](https://github.com/anthonyu))
- made service accounts easier to use [\#27](https://github.com/chef/knife-google/pull/27) ([paulrossman](https://github.com/paulrossman))
- \[KNIFE-417\] knife-google 1.3.1 [\#26](https://github.com/chef/knife-google/pull/26) ([paulrossman](https://github.com/paulrossman))
- \[KNIFE-417\] knife-google compatible with GCE API v1 [\#25](https://github.com/chef/knife-google/pull/25) ([paulrossman](https://github.com/paulrossman))
- v1beta16 api support [\#24](https://github.com/chef/knife-google/pull/24) ([paulrossman](https://github.com/paulrossman))
- OC-9429: Fix rspec deprecation errors for knife-google [\#21](https://github.com/chef/knife-google/pull/21) ([adamedx](https://github.com/adamedx))
- OC-9429 Fix rspec deprecation errors for knife-google [\#20](https://github.com/chef/knife-google/pull/20) ([siddheshwar-more](https://github.com/siddheshwar-more))

## [1.1.0](https://github.com/chef/knife-google/tree/1.1.0) (2013-08-14)
**Merged pull requests:**

- KNIFE-356: Knife google is using deprecated v1beta14 api, should upgrade to v1beta15 [\#19](https://github.com/chef/knife-google/pull/19) ([adamedx](https://github.com/adamedx))
- V1beta15 updates [\#18](https://github.com/chef/knife-google/pull/18) ([paulrossman](https://github.com/paulrossman))
- \[KNIFE-326\] travis integration validation [\#17](https://github.com/chef/knife-google/pull/17) ([josephrdsmith](https://github.com/josephrdsmith))
- Better Error handling when SSL Certificate is not available [\#16](https://github.com/chef/knife-google/pull/16) ([chirag-jog](https://github.com/chirag-jog))
- OC-7868: Knife google plug-in does not read cli switches from knife.rb [\#15](https://github.com/chef/knife-google/pull/15) ([adamedx](https://github.com/adamedx))
- OC 7869 Knife google does not work on Windows due to REST method failures [\#14](https://github.com/chef/knife-google/pull/14) ([siddheshwar-more](https://github.com/siddheshwar-more))
- Oc 7868 - \[ Taking the zone value from knife config file \] [\#13](https://github.com/chef/knife-google/pull/13) ([prabhu-das](https://github.com/prabhu-das))
- OC-4667: Merge Google API-based implementation [\#12](https://github.com/chef/knife-google/pull/12) ([adamedx](https://github.com/adamedx))
- New implementation using API and updated for v1beta14 [\#11](https://github.com/chef/knife-google/pull/11) ([erjohnso](https://github.com/erjohnso))
- Update to the latest 1.5.0 version of gcutils [\#9](https://github.com/chef/knife-google/pull/9) ([chirag-jog](https://github.com/chirag-jog))
- Support for gcutils-1.3.4 [\#8](https://github.com/chef/knife-google/pull/8) ([chirag-jog](https://github.com/chirag-jog))
- OC-4513: Knife-google Issue with gcutils [\#6](https://github.com/chef/knife-google/pull/6) ([mohitsethi](https://github.com/mohitsethi))
- OC-4235: Implement delay loading to reduce load-time [\#4](https://github.com/chef/knife-google/pull/4) ([mohitsethi](https://github.com/mohitsethi))
- V1beta12 works [\#3](https://github.com/chef/knife-google/pull/3) ([leopd](https://github.com/leopd))
- Updated for clarity. If the PROJECT\_ID is required then it should show i... [\#2](https://github.com/chef/knife-google/pull/2) ([jamescott](https://github.com/jamescott))
- Changed --server-name short option to -s [\#1](https://github.com/chef/knife-google/pull/1) ([paulmooring](https://github.com/paulmooring))



\* *This Change Log was automatically generated by [github_changelog_generator](https://github.com/skywinder/Github-Changelog-Generator)*
