# Change Log

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)


## Gaprindashvili-7

### Added
- Expose folders to ems_folder service model. [(#256)](https://github.com/ManageIQ/manageiq-automation_engine/pull/256)

### Fixed
- Make disconnect_storage a no-op [(#272)](https://github.com/ManageIQ/manageiq-automation_engine/pull/272)

## Gaprindashvili-6 - Released 2018-11-06

### Added
- Add support to redhat VM for set_memory and set_number_of_cpus [(#216)](https://github.com/ManageIQ/manageiq-automation_engine/pull/216)

### Fixed
- Updating miq_task for the CustomButton request call with open_url. [(#205)](https://github.com/ManageIQ/manageiq-automation_engine/pull/205)
- Clear stale data from ae_state_data and ae_state_previous [(#222)](https://github.com/ManageIQ/manageiq-automation_engine/pull/222)
- Expose storage_profiles association in Storage's service model. [(#219)](https://github.com/ManageIQ/manageiq-automation_engine/pull/219)
- Clean up the password field and value in automate and evm.log [(#228)](https://github.com/ManageIQ/manageiq-automation_engine/pull/228)
- Add orch stack retirement task to category [(#238)](https://github.com/ManageIQ/manageiq-automation_engine/pull/238)

## Gaprindashvili-5 - Released 2018-09-7

### Added
- Support for v2v pre/post Ansible playbook service. [(#192)](https://github.com/ManageIQ/manageiq-automation_engine/pull/192)

### Fixed
- Lock the model object when modify an option key [(#211)](https://github.com/ManageIQ/manageiq-automation_engine/pull/211)
- Adds tracking label back to AeMethod lines [(#190)](https://github.com/ManageIQ/manageiq-automation_engine/pull/190)
- Fix for ae_method copy with embedded methods. [(#193)](https://github.com/ManageIQ/manageiq-automation_engine/pull/193)
- Start the drb server with a unix socket [(#201)](https://github.com/ManageIQ/manageiq-automation_engine/pull/201)

## Gaprindashvili-4 - Released 2018-07-16

### Added
- New service model for v2v request and task [(#155)](https://github.com/ManageIQ/manageiq-automation_engine/pull/155)
- Support for substitution from state_var [(#151)](https://github.com/ManageIQ/manageiq-automation_engine/pull/151)
- Expose task.mark_vm_migrated to Service. [(#186)](https://github.com/ManageIQ/manageiq-automation_engine/pull/186)

## Gaprindashvili-3 - Released 2018-05-15

### Fixed
- Making processing log to be uniform. [(#152)](https://github.com/ManageIQ/manageiq-automation_engine/pull/152)
- Don't call on_exit method while Ansible Playbook method is running. [(#168)](https://github.com/ManageIQ/manageiq-automation_engine/pull/168)

## Gaprindashvili-2 - Released 2018-03-07

### Added
- Support calling update_vm_name for miq_provision service models [(#153)](https://github.com/ManageIQ/manageiq-automation_engine/pull/153)

## Gaprindashvili-1 - Released 2018-02-01

### Added
- Add task_href_slug as an extra_var for Ansible Playbook [(#101)](https://github.com/ManageIQ/manageiq-automation_engine/pull/101)
- Allow for substitution of hosts [(#102)](https://github.com/ManageIQ/manageiq-automation_engine/pull/102)
- Allow automate scripts to use gems from GEM_PATH and BUNDLE_PATH [(#116)](https://github.com/ManageIQ/manageiq-automation_engine/pull/116)
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
- Add vm_reconfigure_request service model [(#97)](https://github.com/ManageIQ/manageiq-automation_engine/pull/97)

### Fixed
- Log encryption failures [(#127)](https://github.com/ManageIQ/manageiq-automation_engine/pull/127)
- Add remove_from_vmdb method to generic object for Service models. [(#130)](https://github.com/ManageIQ/manageiq-automation_engine/pull/130)
- Expose generic objects to the services service model. [(#128)](https://github.com/ManageIQ/manageiq-automation_engine/pull/128)
- Changes service name update to raise errors [(#118)](https://github.com/ManageIQ/manageiq-automation_engine/pull/118)
- Prefer Gem.path over ENV "GEM_PATH" [(#119)](https://github.com/ManageIQ/manageiq-automation_engine/pull/119)
- Need to pass the user's group in to automate when the provision starts. [(#61)](https://github.com/ManageIQ/manageiq-automation_engine/pull/61)
- Add and remove dependent services correctly in hierarchical structures [(#132)](https://github.com/ManageIQ/manageiq-automation_engine/pull/132)
- Add check for a single domain in git import [(#124)](https://github.com/ManageIQ/manageiq-automation_engine/pull/124)
- Fix Automate State Machine ae_max_retries root object value [(#137)](https://github.com/ManageIQ/manageiq-automation_engine/pull/137)
