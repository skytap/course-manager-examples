# Developing Course Manager Manuals in HTML

## Introduction

A Course Manager Manual consists of a single HTML file. This document can help you to develop an HTML Manual for publishing using the [Course Manual Manager](README.md).

## Supported standard HTML

A number of standard HTML tags are supported, including the following. Unsupported tags are stripped from the content before publishing.

- a
- blockquote
- div
- em
- h1
- h2
- h3
- h4
- hr
- iframe
- img
- li
- ol
- p
- pre
- s
- span
- strong
- sup
- table
- tbody
- td
- thead
- th
- tr
- u
- ul

A number of standard HTML attributes are supported, including the following. Unsupported attributes are stripped from the markup before publishing.

- align
- alt
- aria-.*
- autoplay
- border
- cellpadding
- cellspacing
- charset
- class
- color
- cols
- colspan
- contenteditable
- controls
- coords
- data
- data-.*
- default
- dir
- disabled
- download
- for
- frameborder
- headers
- height
- hidden
- href
- hreflang
- http-equiv
- icon
- id
- kind
- label
- lang
- language
- loop
- media
- muted
- name
- ping
- playsinline
- poster
- preload
- readonly
- rel
- reversed
- rows
- rowspan
- sandbox
- scope
- scrolling
- seamless
- sizes
- span
- src
- srcdoc
- srclang
- srcset
- start
- style
- summary
- tabindex
- target
- title
- translate
- type
- valign
- value
- width

## Proprietary tags

Course Manager uses proprietary HTML tags to represent special types of content that can be included in your Manual. This section details how to use these special features within your Manual content.

### Page break

Page breaks allow Manual content to be broken into pages, which can provide several benefits:

- Content is displayed in the Manual viewer one page at a time. We recommended breaking content into many pages to provide a "step by step" lab experience and to avoid overwhelming the user.
- The user's page position is recorded and preserved between visits.
- Scripts and command shortcuts and questions can be configured to block navigation beyond the current page until executed.

To insert a page break:

    ```HTML
    <hr data-page-break />
    ```

### Callouts

Callouts are shaded content boxes that highlight helpful information to the user.

To insert a yellow "warning" callout:
   ```HTML
   <x-block data-callout data-callout-info class="alert alert-warning"><p>&#8203;Text in yellow callout</p></x-block>
   ```

To insert a red "alert" callout:
  ```HTML
  <x-block data-callout data-callout-warning class="alert alert-danger"><p>&#8203;Text in red callout</p></x-block>
  ```

### Copyable text

Text within the Manual can be marked as copyable. A button is displayed alongside copyable text that, when clicked, copies the content to the user's clipboard.

To insert copyable text:
  ```HTML
  <x-copy-text>Copy Me</x-copy-text>
  ```

### Command Shortcuts

Course Manager [Commands](https://help.skytap.com/course-manager-use-commands-scripts-and-virtual-browser.html#Usingcommandshortcutsandactions) allow users to execute commands within lab VMs. Shortcuts can be inserted into Manual content that invoke commands when clicked.

To insert a command shortcut:
  ```HTML
  <x-command [attributes]>Button Text</x-command>
  ```

#### Required Attributes
- **data-command** - Command to execute within the VM.
- **data-guid** - An identifier for the command. The identifier should be formatted as a UUID (e.g. `550e8400-e29b-41d4-a716-446655440000`) and should be unique within the Manual.
- **data-command-type** - Represents the type of command to be invoked. The valid options are `interactive` and `system`. More information is available [here](https://help.skytap.com/course-manager-use-commands-scripts-and-virtual-browser.html#Choosingbetweeninteractiveandsystemcommands).
- **data-description** - The text that will be displayed as a tooltip when the mouse is hovered over the shortcut.

#### Optional Attributes
- **data-target** - The name or partial name of the target VM as assigned in Skytap. If blank, the command may run on any available VM.
- **data-blocking** - Indicates whether navigation beyond the current Manual page should be affected by the status of this command shortcut. The valid options are:
  - (blank) - Never block navigation.
  - `invoke` - Block Manual navigation until the command shortcut has been executed.
  - `success` - Block Manual navigation until the command shortcut has been _successfully_ executed.
- **data-spinner** - Indicates whether a spinner should be displayed while the command executes and whether a notification modal should be displayed when complete. The valid options are:
  - `none` - Don't show spinner or notification (default).
  - `spin` - Show spinner while command is running, but don't show notification when complete.
  - `all` - Show spinner while command is running and show notification when complete.
- **data-attempts** - Indicates under what circumstances the command shortcut is available. The valid options are:
  - (blank) - Always available (default).
  - `invoke` - Available until it has been clicked once.
  - `success` - Available until it has been clicked and executed successfully.
- **data-display** - Indicates whether to format the shortcut as a button or an inline link. The valid options are:
  - (blank) - Button (default).
  - `inline` - Inline link.
- **data-timeout** - Indicates the time period in seconds beyond which the command is considered to have failed if execution has not completed. For no timeout, use `0`.
- **data-activate** - Indicates whether the VM that accepts the command for execution should be switched into view within the Learning Console. The valid options are:
  - `false` - Don't switch to the VM (default).
  - `true` - Switch to the VM.

### Script Shortcuts

Course Manual [Scripts](https://help.skytap.com/course-manager-use-commands-scripts-and-virtual-browser.html#Usingscriptshortcutsscriptactionsandlifecyclescripts) allow users to execute arbitrary code provided by the lab developer. Shortcuts can be inserted into Manual content that invoke scripts when clicked.

Script shortcuts are a special type of command shortcut. Most of the same options apply, with the following additional requirements:

- **data-target** - Must be set to `%{script_vm_host}`.
- **data-command-type** - Must be set to `system`.
- **data-command** - The script to execute, formatted like the following `invoke name_of_the_script_without_zip_extension`.

### Browser Shortcuts

The Course Manager [Virtual Browser](https://help.skytap.com/course-manager-use-commands-scripts-and-virtual-browser.html#UsingVirtualBrowsershortcutsandactions) provides a lightweight browser interface integrated into the lab. Shortcuts can be inserted into Manual content that open resources in the Virtual Browser when clicked.

Browser shortcuts are a special type of command shortcut. Most of the same options apply, with the following additional requirements:

- **data-target** - Must be set to `%{browser_vm_host}`.
- **data-command-type** - Must be set to `interactive`.
- **data-command** - Must be set to `launch [identifier] "[application] [destination]"`.
  - **identifier** - An identifier for the browser shortcut. It does not need to be unique within the Manual. If the lab end user has already clicked a browser shortcut or lab action with the same identifier, they will be returned to the existing browser instance rather than a new one being opened.
  - **application** - The method used to connect to the destination. The valid options are are `browser`, `sshterm`, and `vnc`.
  - **destination** - The destination of the browser shortcut. The destination can refer to an external resource or one residing within the user's Skytap lab.

### Questions

Course Manual [Questions](https://help.skytap.com/course-manager-edit-manual.html#Insertingaquestion) allow users to be prompted to answer multiple choice and short answer questions. 

#### Format

To insert a question:
  ```HTML
    <x-question class="panel panel-default" [attributes]>
        <x-prompt class="panel-heading">Question text</x-prompt>
    </x-question>
  ```

#### Required Attributes
- **data-question-type** - The type of question to display. Valid options include:
  - `multiple-choice` - A multiple choice question; requires the `data-answer` attribute described below.
  - `short-answer-exact` - A case-sensitive short answer question.
  - `short-answer` - A case-insensitive short answer question.
- **data-answer** - The answer to the question. _Required for multiple choice, optional for short answer._ Supplied as follows:
  - _For multiple choice questions:_ A single data attribute, with the individual choices separated with newlines (\n) within the string. If one of the answer choices is considered correct, it should be preceded with an asterisk (*).
  - _For short answer questions:_ The text of the correct answer. If not specified, then any answer will be accepted.
- **data-guid** - An identifier for the question. The identifier should be formatted as a UUID (e.g. `550e8400-e29b-41d4-a716-446655440000`) and should be unique within the Manual.

#### Optional Attributes
- **data-blocking** - Indicates whether navigation beyond the current Manual page should be affected by the status of this question. The valid options are:
  - (blank) - Never block navigation.
  - `invoke` - Block Manual navigation until the question has been answered.
  - `success` - Block Manual navigation until the command shortcut has been _correctly_ answered.
- **data-metadata-attribute** - If specified, a metadata attribute will be created on the lab when the question is answered. The attribute name will be the name specified and the value will be the answer supplied by the user.