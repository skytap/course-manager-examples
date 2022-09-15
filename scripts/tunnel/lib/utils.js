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

export function raise_error(msg) {
  console.log(msg);
  process.exit(1);
}

export function log(msg) {
  console.log(msg);
}

export function deep_log(obj) {
  console.dir(obj, { depth: null });
}

export function compare(str1, str2) {
  return str1.trim().toLowerCase() === str2.trim().toLowerCase();
}

export function any(val) {
  return !none(val);
}

export function none(val) {
  if (!val) {
    return true;
  } 
  switch (typeof val) {
  case 'array':
    return val.length === 0;

  case 'object':
    return Object.keys(val).length === 0;

  default:
    return false;
  } 
}
