# Change Log

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)


## Unreleased as of Sprint 107 ending 2019-03-18

### Fixed
- Set current user for exposed methods in automate. [(#302)](https://github.com/ManageIQ/manageiq-automation_engine/pull/302)

## Hammer-3

### Fixed
- Don't overwrite message in create_automation_object [(#287)](https://github.com/ManageIQ/manageiq-automation_engine/pull/287)

## Unreleased as of Sprint 105 ending 2019-02-18

### Fixed
- Don't set User.current_user [(#293)](https://github.com/ManageIQ/manageiq-automation_engine/pull/293)
- Redirect writable_storages to writable_accessible_storages [(#292)](https://github.com/ManageIQ/manageiq-automation_engine/pull/292)

## Unreleased as of Sprint 103 ending 2019-01-21

### Fixed
- Reset System Domains Missing RedHat Domain [(#274)](https://github.com/ManageIQ/manageiq-automation_engine/pull/274)

## Hammer-1 - Released 2019-01-15

### Added
- Expose validate_conversion_hosts for TransformationPlanRequest [(#263)](https://github.com/ManageIQ/manageiq-automation_engine/pull/263)
- Expose ConversionHost and ServiceTemplateTransformationPlanTask methods [(#246)](https://github.com/ManageIQ/manageiq-automation_engine/pull/246)
- Expose folders to ems_folder service model. [(#256)](https://github.com/ManageIQ/manageiq-automation_engine/pull/256)
- Expose ext_management_system from ConversionHost [(#255)](https://github.com/ManageIQ/manageiq-automation_engine/pull/255)
- Add conversion_host= method to MiqAeServiceServiceTemplateTransformationPlanTask [(#253)](https://github.com/ManageIQ/manageiq-automation_engine/pull/253)
- Exposes cancelation status to client side [(#229)](https://github.com/ManageIQ/manageiq-automation_engine/pull/229)
- delete_state_var method for MiqAeService. [(#225)](https://github.com/ManageIQ/manageiq-automation_engine/pull/225)
- Allow for embedded methods to contain embedded methods [(#207)](https://github.com/ManageIQ/manageiq-automation_engine/pull/207)
- Add MiqWidget service model and expose queue_generate_content method [(#218)](https://github.com/ManageIQ/manageiq-automation_engine/pull/218)
- Add support to redhat VM for set_memory and set_number_of_cpus [(#216)](https://github.com/ManageIQ/manageiq-automation_engine/pull/216)
- Add plugin display name [(#214)](https://github.com/ManageIQ/manageiq-automation_engine/pull/214)
- Expose configuration_workflow and workflow_job [(#206)](https://github.com/ManageIQ/manageiq-automation_engine/pull/206)
- Add vm.remove_disk method for a VMware VM [(#191)](https://github.com/ManageIQ/manageiq-automation_engine/pull/191)
- Keep track of the server ids where the automate task has been processed. [(#183)](https://github.com/ManageIQ/manageiq-automation_engine/pull/183)
- Added show_url for specific service model objects [(#181)](https://github.com/ManageIQ/manageiq-automation_engine/pull/181)
- Ability to add and remove volumes for an instance  [(#178)](https://github.com/ManageIQ/manageiq-automation_engine/pull/178)
- Expose initializing to automate [(#173)](https://github.com/ManageIQ/manageiq-automation_engine/pull/173)
- Adds better logging to class copy methods [(#120)](https://github.com/ManageIQ/manageiq-automation_engine/pull/120)
- Set state machine retry interval for Ansible playbook method. [(#98)](https://github.com/ManageIQ/manageiq-automation_engine/pull/98)
- Added support for manageiq_connection [(#95)](https://github.com/ManageIQ/manageiq-automation_engine/pull/95)
- Use options instead of data to fetch config info [(#94)](https://github.com/ManageIQ/manageiq-automation_engine/pull/94)
- Add remove_from_vmdb method to Host object for Service models [(#93)](https://github.com/ManageIQ/manageiq-automation_engine/pull/93)
- Automate Workspace encrypt/decrypt support [(#90)](https://github.com/ManageIQ/manageiq-automation_engine/pull/90)
- Get the current user if user context is set. [(#86)](https://github.com/ManageIQ/manageiq-automation_engine/pull/86)

### Fixed
- convert_value_based_on_datatype won't take "Integer" [(#258)](https://github.com/ManageIQ/manageiq-automation_engine/pull/258)
- Fix class name for conversion host [(#252)](https://github.com/ManageIQ/manageiq-automation_engine/pull/252)
- Take out detect vendor changes for orch stack retire tasks [(#249)](https://github.com/ManageIQ/manageiq-automation_engine/pull/249)
- Clean up the password field and value in automate and evm.log [(#228)](https://github.com/ManageIQ/manageiq-automation_engine/pull/228)
- Enable cancelation_status to be updated for service model [(#212)](https://github.com/ManageIQ/manageiq-automation_engine/pull/212)
- Clear stale data from ae_state_data and ae_state_previous [(#222)](https://github.com/ManageIQ/manageiq-automation_engine/pull/222)
- Expose storage_profiles association in Storage's service model. [(#219)](https://github.com/ManageIQ/manageiq-automation_engine/pull/219)
- Handle MIQ_STOP in state machine processing [(#208)](https://github.com/ManageIQ/manageiq-automation_engine/pull/208)
- Updating miq_task for the CustomButton request call with open_url. [(#205)](https://github.com/ManageIQ/manageiq-automation_engine/pull/205)
- Incorporating the deliver method change into the refactoring [(#200)](https://github.com/ManageIQ/manageiq-automation_engine/pull/200)
- Expose storages to VmOrTemplate service model. [(#187)](https://github.com/ManageIQ/manageiq-automation_engine/pull/187)
- Exclude private model methods from being exposed in the Service model. [(#175)](https://github.com/ManageIQ/manageiq-automation_engine/pull/175)
- Add support for accessing objects from anywhere in the workspace [(#112)](https://github.com/ManageIQ/manageiq-automation_engine/pull/112)
- Change URI.split to replace double slashes with a single slash. [(#162)](https://github.com/ManageIQ/manageiq-automation_engine/pull/162)
- Expose generic_objects from GenericObjectDefinition. [(#170)](https://github.com/ManageIQ/manageiq-automation_engine/pull/170)
- Add some helper methods for MiqAeObject. [(#237)](https://github.com/ManageIQ/manageiq-automation_engine/pull/237)
- Add orch stack retirement task to category [(#238)](https://github.com/ManageIQ/manageiq-automation_engine/pull/238)
- Add orch stack retire task to vendor detect [(#242)](https://github.com/ManageIQ/manageiq-automation_engine/pull/242)
- Make disconnect_storage a no-op [(#272)](https://github.com/ManageIQ/manageiq-automation_engine/pull/272)

## Unreleased as of Sprint 101 ending 2018-12-17

### Added
- Add resource to conversion_host to pass validation [(#275)](https://github.com/ManageIQ/manageiq-automation_engine/pull/275)
- Adding a domain lock check for automate import. [(#271)](https://github.com/ManageIQ/manageiq-automation_engine/pull/271)

## Gaprindashvili-6 - Released 2018-11-02

### Added
- Add support to redhat VM for set_memory and set_number_of_cpus [(#216)](https://github.com/ManageIQ/manageiq-automation_engine/pull/216)

### Fixed
- Updating miq_task for the CustomButton request call with open_url. [(#205)](https://github.com/ManageIQ/manageiq-automation_engine/pull/205)
- Clear stale data from ae_state_data and ae_state_previous [(#222)](https://github.com/ManageIQ/manageiq-automation_engine/pull/222)
- Expose storage_profiles association in Storage's service model. [(#219)](https://github.com/ManageIQ/manageiq-automation_engine/pull/219)
- Clean up the password field and value in automate and evm.log [(#228)](https://github.com/ManageIQ/manageiq-automation_engine/pull/228)
- Add orch stack retirement task to category [(#238)](https://github.com/ManageIQ/manageiq-automation_engine/pull/238)

## Gaprindashvili-5 - Released 2018-09-07

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

## Gaprindashvili-3 released 2018-05-15

### Fixed
- Making processing log to be uniform. [(#152)](https://github.com/ManageIQ/manageiq-automation_engine/pull/152)
- Don't call on_exit method while Ansible Playbook method is running. [(#168)](https://github.com/ManageIQ/manageiq-automation_engine/pull/168)

## Gaprindashvili-2 released 2018-03-06

### Added
- Support calling update_vm_name for miq_provision service models [(#153)](https://github.com/ManageIQ/manageiq-automation_engine/pull/153)

## Gaprindashvili-1 - Released 2018-01-31

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

## Initial changelog added
