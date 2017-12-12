# Change Log

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)


## Gaprindashvili RC

### Fixed
- Log encryption failures [(#127)](https://github.com/ManageIQ/manageiq-automation_engine/pull/127)
- Add remove_from_vmdb method to generic object for Service models. [(#130)](https://github.com/ManageIQ/manageiq-automation_engine/pull/130)
- Expose generic objects to the services service model. [(#128)](https://github.com/ManageIQ/manageiq-automation_engine/pull/128)

## Gaprindashvili Beta2

### Added
- Add task_href_slug as an extra_var for Ansible Playbook [(#101)](https://github.com/ManageIQ/manageiq-automation_engine/pull/101)
- Allow for substitution of hosts [(#102)](https://github.com/ManageIQ/manageiq-automation_engine/pull/102)
- Allow automate scripts to use gems from GEM_PATH and BUNDLE_PATH [(#116)](https://github.com/ManageIQ/manageiq-automation_engine/pull/116)

### Fixed
- Changes service name update to raise errors [(#118)](https://github.com/ManageIQ/manageiq-automation_engine/pull/118)
- Prefer Gem.path over ENV "GEM_PATH" [(#119)](https://github.com/ManageIQ/manageiq-automation_engine/pull/119)

## Gaprindashvili Beta1

### Added
- Expose disks and volumes in the ServiceModel through Hardware. [(#91)](https://github.com/ManageIQ/manageiq-automation_engine/pull/91)
- Pass in the workspace as href_slug [(#82)](https://github.com/ManageIQ/manageiq-automation_engine/pull/82)
- Ansible Playbook Automate Method [(#78)](https://github.com/ManageIQ/manageiq-automation_engine/pull/78)
- Changes for generic object method calls via REST API. [(#74)](https://github.com/ManageIQ/manageiq-automation_engine/pull/74)
- Expose stack refresh method [(#68)](https://github.com/ManageIQ/manageiq-automation_engine/pull/68)
- Use generic object's methods to add to/remove from a service. [(#70)](https://github.com/ManageIQ/manageiq-automation_engine/pull/70)
- Add exposed manager refresh method [(#67)](https://github.com/ManageIQ/manageiq-automation_engine/pull/67)
- Serialize/Deserialize a workspace [(#64)](https://github.com/ManageIQ/manageiq-automation_engine/pull/64)
- Allows expressions to be exported and imported [(#56)](https://github.com/ManageIQ/manageiq-automation_engine/pull/56)
- Support for expression methods [(#49)](https://github.com/ManageIQ/manageiq-automation_engine/pull/49)

### Fixed
- Need to pass the user's group in to automate when the provision starts. [(#61)](https://github.com/ManageIQ/manageiq-automation_engine/pull/61)
