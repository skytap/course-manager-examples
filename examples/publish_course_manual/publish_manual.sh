#!/bin/bash
###################################################################
#   SCRIPT NAME: Publish Course Manual
#   DESCRIPTION: Uses the Course Manager API to upload a manual and its attachments.
#        AUTHOR: Skytap Course Manager Team
#         EMAIL: coursemanager@skytap.com
#       VERSION: 1.0
#       CREATED: 11/01/2022
###################################################################
#    Copyright 2022 Skytap Inc.
#    Licensed under the Apache License, Version 2.0 (the "License");
#    you may not use this file except in compliance with the License.
#    You may obtain a copy of the License at
#        http://www.apache.org/licenses/LICENSE-2.0
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.
###################################################################

#### Dependencies ####
# jq - Command-line JSON processor (https://stedolan.github.io/jq/download/)
# md5sum - Compute and check MD5 message digest. [Could use md5 as a replacement] (https://man7.org/linux/man-pages/man1/md5sum.1.html)
# curl - A command line tool for getting or sending data using URL syntax (https://curl.se/)
# Other standard functions, though replacements could be found: (echo, base64, awk, xxd, file, basename, wc)
for app in jq md5sum curl echo base64 awk xxd file basename wc; do command -v "${app}" &>/dev/null || not_available+=("${app}"); done
(( ${#not_available[@]} > 0 )) && echo "Please install missing dependencies: ${not_available[*]}" 1>&2 && exit 1

#### Variables ####
readonly BASE64=`((echo test | base64 -w 0 > /dev/null 2>&1) && echo "base64 -w 0") || echo base64`
readonly HTML_FILE='./ABC_training_course_manual.html'
readonly COURSE_ID="REPLACE WITH COURSE_ID"
readonly ATTACHMENT_DIR='./files'
readonly COURSE_MANAGER_SUBDOMAIN="REPLACE WITH COURSE_MANAGER_SUBDOMAIN"
readonly COURSE_MANAGER_HOST="skytap-portal.com"
readonly API_TOKEN="REPLACE WITH API_TOKEN"
readonly API_SECRET="REPLACE WITH API_SECRET"
readonly AUTHORIZATION_BASIC=$(echo -n "$API_TOKEN:$API_SECRET" | $BASE64)
readonly SECONDS_BETWEEN_POLLS=5
readonly COURSE_MANUAL_API_URL="https://$COURSE_MANAGER_SUBDOMAIN.$COURSE_MANAGER_HOST/api/v1/courses/$COURSE_ID/course_manual/versions/draft"

#### Functions ####

# Tests the Course Manager API to see if it is working.
TestAPI () {
  HTTPCode=$(curl -s -o /dev/null -w '%{http_code}' -L -X GET $COURSE_MANUAL_API_URL \
                  --header "Authorization: Basic $AUTHORIZATION_BASIC" \
                  --header "Content-Type: application/json")
  if [[ $HTTPCode != "200" && $HTTPCode != "204" ]]; then
    if [[ $HTTPCode == "401" ]]; then
      echo "API Key is invalid, please update and try again."
      exit 1;
    fi
    if [[ $HTTPCode == "404" ]]; then
      echo "Not a valid Course, check Course ID and try again."
      exit 1;
    fi
    if [[ $HTTPCode == "000" ]]; then
      echo "URL is not valid, make sure the script is configured to point to Course Manager's Website."
      exit 1;
    fi
    echo "Connection to Course Manager's API has failed with status code: $HTTPCode."
    exit 1
  fi
}

# Deletes the existing Course Manual draft.
DeleteManualDraft() {
  echo "Deleting the manual draft if any exists."
  HTTPCode=$(curl -s -o /dev/null -w '%{http_code}' -L -X DELETE $COURSE_MANUAL_API_URL \
                  --header "Authorization: Basic $AUTHORIZATION_BASIC" \
                  --header "Content-Type: application/json")
  if [[ $HTTPCode != "202" ]]; then
    echo "Unexpected response when trying to delete the manual draft"
    exit 1
  fi
}

# Modifies the current draft in Course Manager
# First argument as the data to send as the body of the request
# Second argument is the descriptive action that the update is performing/triggering.
UpdateManualDraft() {
  echo "Updating the manual draft. ($2)"
  HTTPCode=$(curl -s -o /dev/null -w '%{http_code}' -L -X PUT $COURSE_MANUAL_API_URL \
                  --header "Authorization: Basic $AUTHORIZATION_BASIC" \
                  --header "Content-Type: application/json" \
                  --header "Accept: application/json" \
                  --data-raw "$1")
  if [[ $HTTPCode != "202" ]]; then
    if [[ $HTTPCode == "423" ]]; then
      echo "Manual is locked for editing, someone else is editing it, please try again later."
      exit 1
    fi

    echo "Unexpected response when trying to update the manual draft: $HTTPCode"
    exit 1
  fi
}

# Fetches the current status of the manual from Course Manager
# Stores http status in $http_code
# Stores json representation of the manual in $manual
GetManualDraft() {
  local response
  response=$(curl -s -w "\n%{http_code}" -L -X GET $COURSE_MANUAL_API_URL \
                  --header "Authorization: Basic $AUTHORIZATION_BASIC" \
                  --header "Content-Type: application/json")
  Manual=$(head -n 1 <<< "$response")  # get all but the last line
  HTTPCode=$(echo "$response" | head -n 2 | tail -n 1)  # get the last line
  if [[ $HTTPCode != "204" && $HTTPCode != "200" ]]; then
    echo "Unexpected response when trying to fetch the manual draft"
    exit 1
  fi
}

# Calculates the MD5 checksum for the attachment, in base64.
MD5inBase64 () {
  md5sum "$1" | awk '{print $1}' | xxd -r -p | $BASE64
}

# Generates the attachment info for passed filepath.
# First argument is the file path.
AttachmentInfo () {
 echo "{
   \"filename\": \"$(basename "$1")\",
   \"byte_size\": $(wc -c "$1" | awk '{print $1}'),
   \"file_path\": \"$1\",
   \"checksum\": \"$(MD5inBase64 "$1")\",
   \"content_type\": \"$(file -b --mime-type "$1")\"
 }"
}

# Joins the array using the specified string between each string.
# First argument is the join string.
# Second argument is the array to join together.
joinByChar() {
  IFS="$1"
  shift
  echo "$*"
}

# Generate the upload data for attachments in the selected directory.
GenerateAttachmentUploadData () {
  declare -a AttachmentsData
  Attachments=0
  for attachment in "$ATTACHMENT_DIR"/*
  do
    Attachments=1
    AttachmentsData+=( "$(AttachmentInfo "$attachment")" )
  done
  AttachmentUploadData=$(echo "[$(joinByChar "," "${AttachmentsData[@]}")]" | jq '@text')
}

# Takes the HTML content from file and makes it ready for the API. JSON escaping and removing newlines.
LoadContentFromFile () {
  Content=$(sed 's/\"/\\\"/g' "$HTML_FILE" | tr -d '\n')
}

# Updates $CurrentStatus with the current state of the manual.
StateFromResponse () {
  echo -n "."
  GetManualDraft
  CurrentStatus=$(echo "$Manual" | jq --raw-output 'getpath(["state"])')
}

# Holds up the script for the next state change due an asynchronous action ran in Course Manager.
# First argument is the status to move on.
# Second argument is a status that would result in exiting the script.
PollForState () {
  echo -n "Checking for a state update."
  StateFromResponse
  until [[ "$CurrentStatus" == "$1" ]]; do
    if [[ "$CurrentStatus" == "$2" ]]; then
      echo "Something failed in uploading the manual."
      exit 2
    fi
    sleep $SECONDS_BETWEEN_POLLS
    StateFromResponse
  done
  echo ""
}

# Finds the attachments for the manual and uploads any that need to be uploaded.
UploadAttachments () {
  echo "Uploading attachments."
  for EncodedAttachment in $(echo "$Manual" | jq -r 'getpath(["attachment_upload_data"])[] | @base64');
  do
    Attachment() {
      echo ${EncodedAttachment} | $BASE64 --decode | jq -r ${1}
    }
    file_path=$(Attachment '.file_path')
    uploadURL=$(Attachment '.blob_upload_url')
    if [ "${uploadURL}" != "null" ]; then
      response=$(curl -X PUT -T "$file_path" "$uploadURL" \
                       --header "Content-Length: $(wc -c "$file_path" | awk '{print $1}')" \
                       --header "Content-Type: $(file -b --mime-type "$file_path")" \
                       --header "Content-MD5: $(MD5inBase64 "$file_path")" \
                       --header "Content-Disposition: inline; filename=\"$(basename "$file_path")\"; filename*=UTF-8''$(basename "$file_path")")
    fi
  done
}

#### Script ####
TestAPI
### Delete existing draft ###
DeleteManualDraft
### Submit initial content and attachment information
LoadContentFromFile
GenerateAttachmentUploadData
if [ $Attachments ]; then
  UpdateManualDraft "{\"status\": \"content_complete\", \"content\": \"$Content\", \"attachment_upload_data\": $AttachmentUploadData }" "Processing content"
  PollForState "needs_attachments" "draft"

  ### Upload attachments
  UploadAttachments
  UpdateManualDraft "{\"status\": \"ready_to_process\"}" "Processing attachments"
  PollForState "ready_to_publish" "needs_attachments"
else
  UpdateManualDraft "{\"status\": \"content_complete\", \"content\": \"$Content\"}"
  PollForState 'ready_to_publish' 'draft'
fi

### Publish
UpdateManualDraft "{\"status\": \"published\"}" "Publishing"