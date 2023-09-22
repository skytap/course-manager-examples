# Skytap Course Manager Course Manual Manager

## Introduction

Skytap Course Manager allows you to create rich lab experiences for your end users through the use of the [Course Manuals](https://help.skytap.com/course-manager-use-manual-in-learning-console.html) feature. Manuals can be edited directly in the embedded [Manual editor](https://help.skytap.com/course-manager-edit-manual.html) within Course Manager. However, many customers prefer to develop and maintain instructional content using an external documentation management tool, and/or to store these resources in a source code management platform like GitHub. 

By using this tool, you can upload, publish or delete a HTML-based course manual directly to a Course Manager course. Embedded images and attachments linked from the content can automatically be uploaded and linked to the content. The tool can be run manually or automatically, and can even form part of a continuous delivery pipeline for your course documentation if desired.

## Developing the Manual Content

A Course Manager Manual is a single HTML file. Many familiar HTML tags are supported, as are a number of "custom" tags that drive proprietary Course Manager Manual features such as:

* Scripts
* Commands
* Virtual Browser
* Callouts
* Copyable text
* Pagination

Documentation of our custom tags for use in manually developed HTML content will be released in the future. In the meantime, to learn how to use these features, we recommend using the web-based editor to create sample content, and then clicking over to the Code View within the editor to capture the resulting markup.

Only HTML tags supported by the web-based editor are supported. Unsupported tags are stripped out as part of the publishing process.

### Images and attachments

Your Manual can embed images and link to attachments. This tool can locate these resources on your local system, upload them, and link them to your Manual during the publishing process. 

To achieve this, the tool will parse your HTML file and look for `<img src="...">` tags and `<a href="..."`>` tags with paths matching the following patterns:

* URLs beginning with `file://` that reference an absolute local path on your local system, e.g. `file:///Users/jsmith/files/image.png`
* Relative paths, e.g. `files/image.png` or `../resources/images/photo.jpg` or `./assets/brochure.pdf`

The tool will try to follow each link on your local system, and if found, it will upload the resource to the Manual and replace the local path with the correct remote URL after the file has been uploaded. 

Note that the directory where your HTML file resides is used as the base location for resolving relative paths.

For a simple example, see the `sample/` directory.

### Page break
- For Course Manager manuals, there are special page breaks to limit what content is on each page and for blocking navigation. 
  - This page break should be inserted at the top level of the HTML with the following HTML:
    ```HTML
    <hr data-page-break />
    ```

### Callouts 
- Callouts appear as alert boxes with helpful information to the user.
 - For a yellow callout use the following HTML
   ```HTML
   <x-block data-callout data-callout-info class="alert alert-warning"><p>&#8203;Text in yellow callout</p></x-block>
   ```
- For a red callout use the following HTML
  ```HTML
  <x-block data-callout data-callout-warning class="alert alert-danger"><p>&#8203;Text in red callout</p></x-block>
  ```

### Copyable text
- If you wrap the text you want the end user to be able to copy in the HTML tag **X-COPY-TEXT**, then it will become copyable. 
  - e.g.`<x-copy-text>Copy Me</x-xopy-text>`

### Command Shortcuts
Formatted like a standard HTML element with a name of **X-COMMAND** `<x-command>Button Text</x-command>`

#### Required Attributes
- **data-command** - Command to execute over the VM
- **data-guid** - Formatted like a UUID and must be unique to this command.
- **data-command-type** - The type of helper to send this command to.
  - `interactive` - CMHelper
  - `system` - CMSysHelper
- **data-description** - The hover text of the button.

#### Optional Attributes
- **data-target** (Defaults to any Helper in the environment)
- **data-blocking** (Defaults to not blocking forward progress in the manual)
  - `` - Does not block manual progress.
  - `invoke` - Blocks manual progress till command shortcut has been executed.
  - `success` - Blocks manual progress till the command shortcut has been successfully executed.
- **data-spinner** - Determines if the spinner and/or notification occurs (defaults to none).
  - `none` - No spinner or command completion notification happens.
  - `spin` - Spinner shows while command is running, but no command completion notification occurs.
  - `all` - Spinner shows while command is running and a notification occurs when the command completes.
- **data-attempts** (Defaults to always available)
  - `` - The lab end user can always click the command shortcut.
  - `invoke` - The lab end user can click the command shortcut until they execute the command.
  - `success` - The lab end user can click the command shortcut until they successfully execute the command.
- **data-display** (Defaults to button)
  - `` - Button
  - `inline` - Inline link
- **data-timeout** - Time in seconds that the command can run before automatically failing.
  - `0` - Acts as no timeout.
- **data-activate** - Displays the VM that receives and accepts the command when it is executed (defaults to not displaying).
  - `false` - Does not display the VM.
  - `true` - Displays the VM.

### Script Shortcuts
_Similar to Command shortcuts with a few small modifications_
Formatted like a standard HTML element with a name of **X-COMMAND** `<x-command>Button Text</x-command>`

#### Required Attributes
- **data-target** - Must be set to `%{script_vm_host}`.
- **data-command-type** - Must be set to `system`.
- **data-command** - The script to execute formatted like the following `invoke "script_name.zip"`
- **data-guid** - Formatted like a UUID and must be unique to this command.
- **data-description** - The hover text of the button.

#### Optional Attributes
- **data-blocking** (Defaults to not blocking forward progress in the manual)
    - `` - Does not block manual progress.
    - `invoke` - Blocks manual progress till command shortcut has been executed.
    - `success` - Blocks manual progress till the command shortcut has been successfully executed.
- **data-spinner** - Determines if the spinner and/or notification occurs (defaults to none).
    - `none` - No spinner or command completion notification happens.
    - `spin` - Spinner shows while command is running, but no command completion notification occurs.
    - `all` - Spinner shows while command is running and a notification occurs when the command completes.
- **data-attempts** (Defaults to always available)
    - `` - The lab end user can always click the command shortcut.
    - `invoke` - The lab end user can click the command shortcut until they execute the command.
    - `success` - The lab end user can click the command shortcut until they successfully execute the command.
- **data-display** (Defaults to button)
    - `` - Button
    - `inline` - Inline link
- **data-timeout** - Time in seconds that the command can run before automatically failing.
    - `0` - Acts as no timeout.

### Browser Shortcuts
_Similar to Command shortcuts with a some modifications_
Formatted like a standard HTML element with a name of **X-COMMAND** `<x-command>Button Text</x-command>`

#### Required Attributes
- **data-target** - Must be set to `%{browser_vm_host}`.
- **data-command-type** - Must be set to `interactive`.
- **data-command** - The script to execute formatted like the following `launch identifier "application destination"`
  - **identifier** - Replace this with the unique identifier for the Virtual Browser shortcut. If the lab end user has already clicked a Virtual Browser Manual shortcut or lab action with the same Identifier, they will return to the existing instance.
  - **application** - Replace this with the method used to connect to the destination. Options are `browser`, `sshterm`, and `vnc`
  - **destination** - Replace this with the destination that the Virtual Browser should connect to when the lab end user clicks the Virtual Browser shortcut in the Manual. The Destination can be external or within the user’s Skytap environment.
- **data-guid** - Formatted like a UUID and must be unique to this command.
- **data-description** - The hover text of the button.

#### Optional Attributes
- **data-display** (Defaults to button)
    - `` - Button
    - `inline` - Inline link

### Questions

#### Format
- Questions are inserted with the following HTML 
  ```HTML
    <X-QUESTION class="panel panel-default">
        <X-PROMPT class="panel-heading">Question text</X-PROMPT>
    </X-QUESTION>
  ```
  - Attributes discussed in the next sections are applied directly to the X-QUESTION tag.
  - The question text will be rendered as the question the end user will answer

#### Required Attributes
- **data-question-type** - The type of question
  - `multiple-choice` - A multiple-choice question, answer must have multiple lines of answers, and only one line can start with an asterisks.
  - `short-answer-exact` - A short answer question, if an answer is provided, then the end user must get the question correct (case sensitive).
  - `short-answer` - A short answer question, if an answer is provided, then the end user must get the question correct (case in-sensitive).
- **data-guid** - Formatted like a UUID and must be unique to this question.


#### Optional Attributes
- **data-answer** - (REQUIRED FOR MULTIPLE CHOICE)
  - Multiple choice, answers should be separated by a \n and if there is a correct answer then it should start with an asterisks.
  - Short Answer, answer should be the text answer that end user is expected to guess. If no answer is given, then any input will be recorded and marked as correct.
- **data-blocking** (Defaults to not blocking forward progress in the manual)
    - `` - Does not block manual progress.
    - `invoke` - Blocks manual progress till question has been answered.
    - `success` - Blocks manual progress till the question has been successfully answered.
- **data-metadata-attribute** - If provided the value will create/update a Metadata attribute using the value as the attribute name and the answer as the attribute value.

## Running the Manual Manager

The Manual Manager tool can be run in 2 different ways. The easiest way is to run it from our public Docker image, using a command like:

```
docker run -it -v $HOME:$HOME -w $PWD skytapcmscripttools.azurecr.io/course_manual_manager
```

Note: when using the Docker image, it's important to mount as a volume the directory structure that contains your manual content so it's available to the Publisher.

Alternatively, you can install Ruby 3.1+ with RubyGems and Bundler, check the code out and run it with a command like `bundle install && bundle exec ruby course_manual_manager`.

### Supported command line arguments
**--delete**: Deletes the current manual draft, if any.

**--upload**: Uploads a manual and associated attachments (implies **--delete**). When run without **--publish**, this option allows you to a preview your manual without publishing it to end users.

**--publish**: Publishes the uploaded manual. This can be a manual uploaded previously with the **--upload** option, or can be used along with **--upload** to upload and publish in one step.

If no command line arguments are specified, **--delete --upload --publish** is assumed.

### Interactive configuration
The first time you run the tool in a particular directory, it will prompt you for the following details to publish your Manual:

* Path to your Manual HTML file
* Your organization's Course Manager hostname (e.g. customername.skytap-portal.com)
* Course Manager API key and secret
* The ID of the course for which you wish to publish the manual

These details are saved to a file called .publish.yml in the working directory and will automatically be used the next time you invoke the script from that location. To reset, simply delete the file.

### Verbose mode

To enable verbose logging, set the environment variable VERBOSE to any value.

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