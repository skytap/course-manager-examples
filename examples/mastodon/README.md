# Course Manager Lab Concept: Mastodon

This directory contains the Course Manual, Scripts and utilities used to create the [Intro to Mastodon](manual/mastodon_manual.html) concept training lab on Course Manager by Skytap. Used together, they build an integrated hybrid cloud lab environment in Skytap using services from Microsoft Azure, Amazon Web Servies and Twilio Sendgrid. The lab uses synthetic data to train the user on an ephemeral instance of Mastodon. 

If you are not a Skytap customer and would like to learn more, please [contact us and request a demo](https://www.skytap.com/contact-us/).

## Dependencies

- Skytap templates for the Mastodon server and clients
- Microsoft Azure subscription and service principal
- Microsoft Azure storage account (for Terraform state)
- Microsoft Azure Translation API account (for translation bot exercise and associated Scripts)
- Sendgrid account and API token with permissions to create lab tokens and send mail
- Amazon Web Services subscription and access key (for Mac lesson)

## Course Manual

The [Course Manual](manual/mastodon_manual.html) can be published using the [Course Manual Manager](../../tools/course_manual_manager/).

## Scripts

All Scripts use the [Course Manager Script template for ruby](https://github.com/skytap/course-manager-examples/tree/master/script-templates/ruby). This is one of [several templates](../../script-templates/) that providing a starting point for developing Scripts.

These Scripts provide an example for Skytap customers to build their own courses or titles. They should not be used as an example for managing Mastodon.

The scripts include:
- [provision](scripts/provision_and_teardown/provision/script/script.rb) - generates random IDs for use by the lab, provisions the [shared course infrastructure with Terraform](scripts/provision_and_teardown/provision/terraform/course/) if not provisioned already, provisions the [lab infrastructure with Terraform](scripts/provision_and_teardown/shared/terraform/lab/), customizes the Skytap environment used by the lab
- [teardown](scripts/provision_and_teardown/teardown/script/script.rb) - grades the user's lab, sends a grade report by email, reports grade to the LTI service that launched the lab (if relevant), destroys lab infrastructure with Terraform
- [provision_mac](scripts/provision_mac/script/script.rb) - provisions the Mac host in Aamzon Web Services
- [server_init](scripts/server_init/script/script.rb) - configures and deploys Mastodon to the Mastodon server VM
- [setup_exam](scripts/setup_exam/script/script.rb) - prepares the lab for the exam portion of the training
- [setup_translator](scripts/setup_translator/script/script.rb) - creates a token for the Azure translation API and the Mastodon user used for the translation portion of the course
- [setup_users](scripts/setup_translator/script/script.rb) - creates the initial Mastodon users and initial posts
- [spanish_tooter](scripts/setup_translator/script/script.rb) - creates a Mastodon post in Spanish
- [teardown_mac](scripts/teardown_mac/script/script.rb) - destroys the Mac instance created in
- [check_bot_frozen](scripts/check_bot_frozen/script/script.rb) - attempts to post as the troll user, fails if the post is successful
- [english_tooter](scripts/english_tooter/script/script.rb) - creates a Mastodon post in English

Some scripts post example user content to Mastodon. This content was retrieved from the following sources:

- [English example content](scripts/shared/tooter/lib/script_support/toots/en.txt) - created by Microsoft's Bing chatbot on 9/30/2023
- [Spanish example content](scripts/shared/tooter/lib/script_support/toots/es.txt) - created by Microsoft's Bing chatbot on 9/30/2023
- [Troll content](scripts/shared/tooter/lib/script_support/toots/esbot.txt) - contains public domain text from https://www.gutenberg.org/ebooks/2000

## Metadata Requirements

The Scripts in this course require the following Metadata and Sensitive Metadata attributes to be created in Course Manager, associated with the lab, event, user, course or feature. The Scripts also create several Metadata attributes for the lab that are referenced in the Course Manager

### Metadata

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

### Sensitive Metadata

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