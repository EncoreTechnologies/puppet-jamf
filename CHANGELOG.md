# Changelog

All notable changes to this project will be documented in this file.

## Release 1.0.1
- Added a provider/type for API Roles.

## Release 1.0.9
- The name of Jamf's Tomcat service has changed. Set the value needed
    for your environment in params.pp
- Removed "Customer Experience Metrics" from Account Group Permissions due to removal from the API
- Removed extraneous "Read Push Certificates" permission from list

## Release 1.0.8
- Added ability for Restricted Software Records to be managed in Jamf Cloud

## Release 1.0.7
- Disabling default mysql only for RHEL 8

## Release 1.0.6
- Added an additional provider for Mobile Device Groups

## Release 1.0.5
- Adding custom fact to check if jamf is configured

## Release 1.0.4
- Removed "Managed Preference Profiles" from Account Group permissions due to removal from the API

## Release 1.0.3

- Adjusted Computer Check-in provider to match API of Jamf 11 Release

## Release 1.0.2

- Changed "Managed Software Update Plans" to "Managed Software Updates" for Jamf 10.50 release

## Release 1.0.1

- Added on-prem support for RHEL8

## Release 1.0.0

- Added Onboarding Configurations to JSS Settings Privileges for Jamf 10.48 release
- Updates for PDK v3.0.0

## Release 0.1.0

- Initial Release
