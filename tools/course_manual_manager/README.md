# Skytap Course Manager Course Manual Publisher

## Introduction

Skytap Course Manager allows you to create rich lab experiences for your end users through the use of the [Course Manuals](https://help.skytap.com/course-manager-use-manual-in-learning-console.html) feature. Manuals can be edited directly in the embedded [Manual editor](https://help.skytap.com/course-manager-edit-manual.html) within Course Manager. However, many customers prefer to develop and maintain instructional content using an external documentation management tool, and/or to store these resources in a source code management platform like GitHub. 

By using this tool -- or perhaps by developing your own, using this one as a starting point -- you can publish an HTML-based course manual directly to a Course Manager course. Embedded images and attachments linked from the content can automatically be uploaded and linked to the content. The tool can be run manually or automatically, and can even form part of a continuous delivery pipeline for your course documentation if desired.

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

## Running the Publisher

The Publisher tool can be run in 2 different ways. The easiest way is to run it from our public Docker image, using a command like:

```
docker run -it -v $HOME:$HOME -w $PWD skytapcmscripttools.azurecr.io/course_manual_manager
```

Note: when using the Docker image, it's important to mount as a volume the directory structure that contains your manual content so it's available to the Publisher.

Alternatively, you can install Ruby 3.1+ with RubyGems and Bundler, check the code out and run it with a command like `bundle install && bundle exec ruby publish`.

The tool will prompt you for the following details to publish your Manual:

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