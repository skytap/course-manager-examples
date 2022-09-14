// Copyright 2022 Skytap Inc.

// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at

//     http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import { raise_error, none } from './utils.js';

export function calculate(environment) {
  return environment.tags.reduce((result, tag) => {
    const tag_string = tag.value;
    const tag_string_tokens = tag_string.split(':');
    if (tag_string_tokens.length > 1) {
      const tag_name = tag_string_tokens[0];
      const tag_value = tag_string.substring(tag_name.length + 1).trim();
      if (tag_name in result) {
        result[tag_name].push(tag_value);
      } else {
        result[tag_name] = [tag_value];
      }
    }
    return result;
  }, {});
}

export function ensure_one(tags, tag_key) {
  ensure_at_least_one(tags, tag_key);
  return ensure_zero_or_one(tags, tag_key);
}

export function ensure_at_least_one(tags, tag_key) {
  const values = tags[tag_key];
  if (none(values)) {
    raise_error(
      `Tag starting with ${tag_key} was not found on the environment`
    );
  }
  return values;
}

export function ensure_zero_or_one(tags, tag_key) {
  const values = tags[tag_key];
  if (none(values)) {
    return null;
  } else if (values.length > 1) {
    raise_error(
      `Multiple tags starting with ${tag_key} were found on the environment`
    );
  } else {
    return values[0];
  }
}
