# Course Manager Example Course: Mastodon

This directory contains the course manual, scripts and utilities used to build the "Intro to Mastodon" training course in Course Manager by Skytap. The goal of this course is to provide a working example of a hybrid cloud lab, orchestrated with Course Manager. 

The examples demonstrate the following:

- Using metadata and sensitve metadata to store lab credentials and context
- Using Terraform in scripts to provision and tear down course and lab resources
- Using the Skytap API to customize labs provisioned by Course Manager
- Integrating scripts and metadata with Course Manager Manuals
- Using LTI basic outcomes to report grades to an LTI-compliant LMS
- Provisioning resources in Microsoft Azure and Amazon Web Services

For more information, please contact your Skytap Customer Success Manager.

## Dependencies

The course manual, scripts and utilities are mutually dependent, and also have several external dependencies. Individual scripts or utilities may not work outside of a properly configured Course Manager course. 

The course also has several external dependencies, including:

- Skytap templates for the Mastodon server and clients
- Microsoft Azure subscription and service principal
- Azure storage account (for Terraform state)
- Azure translation account (for translation bot exercise and associated scripts)
- Sendgrid account and API token
- Amazon Web Services access key

## Manual

The manual is available at `manual/mastodon_manual.html`, which references images in the `images` directory. The manual can be published using the Course Manual Manager, which is documented here: https://github.com/skytap/course-manager-examples/tree/master/tools/course_manual_manager

## Scripts

The `scripts` directory contains the Course Manager scripts that are referenced in the manual. All scripts are based on the [ruby script template](https://github.com/skytap/course-manager-examples/tree/master/script-templates/ruby). This is one of several templates that providing a starting point for developing scripts, including utilities for managing metadata, controlling lab state, testing the script locally, and deploying to Course Manager. 

The scripts include:
- `bot_tooter` - creates Mastodon posts as the bot user
- `check_bot_frozen` - attempts to post as the bot user, fails if the post is successful
- `english_tooter` - creates a Mastodon post in English
- `provision_and_teardown/provision` - generates random IDs for use by the lab, provisions the shared course infrastructure in Azure with Terraform if not provisioned already, provisions the lab infrastructure in Azure with Terraform, customizes the Skytap environment used by the lab
- `provision_and_teardown/teardown` - grades the user's lab, sends a grade report by email, reports grade to the LTI service that launched the lab (if relevant), destroys lab infrastructure with Terraform
- `provision_mac` - provisions the Mac host in Aamzon Web Services
- `server_init` - configures and deploys Mastodon to the Mastodon server VM
- `setup_exam` - prepares the lab for the exam portion of the training
- `setup_translator` - creates a token for the Azure translation API and the Mastodon user used for the translation portion of the course
- `setup_users` - creates the initial Mastodon users and initial posts
- `spanish_tooter` - creates a Mastodon post in Spanish
- `teardown_mac` - destroys the Mac instance created in `provision_mac`

Some scripts use composition to copy shared code, located at `scripts/shared`, into a `.build` directory which is then deployed to Skytap.

Some scripts post example user content to Mastodon. This content was was not created by Skytap, and was retrieved from the following sources:

- `scripts/shared/tooter/lib/script_support/toots/en.txt` - created by Microsoft's Bing chatbot on 9/30/2023
- `scripts/shared/tooter/lib/script_support/toots/es.txt` - created by Microsoft's Bing chatbot on 9/30/2023
- `scripts/shared/tooter/lib/script_support/toots/esbot.txt` - contains exerpts from Don Quijote by Miguel de Cervantes Saavendra, sourced from https://www.gutenberg.org/ebooks/2000

## Metadata Requirements

The scripts in this course require the following metadata attributes to be created in Course Manager, as course, feature, or lab metadata. In addition, the scripts create several lab metadata attributes, which are not enumerated here.

### Metadata (available to lab user)

- `azure_tenant_id`
- `azure_subscription_id`
- `azure_resource_group`
- `azure_storage_account`
- `azure_storage_account`
- `azure_container`
- `skytap_username`
- `skytap_mastodon_server_template_Id`
- `mastodon_server_ip`
- `base_dns_name`
- `mastodon_server_username`
- `aws_default_region`
- `mac_user`
- `mac_ssh_key_name`
- `mastodon_ssh_public_key`
- `mac_new_pass`
- `mac_old_pass`
- `mac_vnc_password`
- `mac_instance_type`
- `mac_zone`
- `mac_ami`
- `mac_security_group_id`
- `mac_num_allowed_hosts`
- `instructor_email`

### Sensitive Metadata (available to scripts only)

- `azure_client_id`
- `azure_client_secret`
- `sendgrid_key`
- `skytap_token`
- `mastodon_server_password`
- `translation_key`
- `aws_access_key_id`
- `aws_secret_access_key`
- `mac_ssh_priv_key`
- `lti_key`
- `lti_secret`

## License 

Copyright 2023 Skytap Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

<http://www.apache.org/licenses/LICENSE-2.0>

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.