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

import { any, raise_error, log, deep_log } from './utils.js';
import axios from 'axios';

const METADATA_URL = 'http://169.254.169.254/skytap';
const SKYTAP_BASE_URL = 'https://cloud.skytap.com';
const AXIOS_OPTIONS = {
  auth: {
    username: process.env.SKYTAP_USERNAME,
    password: process.env.SKYTAP_TOKEN
  },
  headers: {
    accept: 'application/json',
    'content-type': 'application/json'
  }
};

export async function environment_id() {
  const metadata = await skytap_metadata();
  return metadata.configuration_url.split('/').pop();
}

export async function environment(skytap_id) {
  return await get(`v2/configurations/${skytap_id}`);
}

async function skytap_metadata() {
  try {
    const { data } = await axios.get(METADATA_URL);
    return data;
  } catch {
    raise_error('Error retrieving VM metadata');
  }
}

export async function get(path) {
  return await api({ method: 'GET', path });
}

export async function post(path, data) {
  return await api({ method: 'POST', path, data });
}

async function api(args) {
  const { method, path, data } = args;
  try {
    const response = await axios({
      ...AXIOS_OPTIONS,
      method,
      url: `${SKYTAP_BASE_URL}/${path}`,
      data
    });
    return response.data;
  } catch(error) {
    log('Request failed with options:');
    deep_log(args);
    if (error.response) {
      log_response_error(error.response);
    }
    raise_error(error.message);
  }
}

function log_response_error(response) {
  try {
    const { status, statusText } = response;
    log(`Response code: ${status} ${statusText}`);
    if (response.data) {
      if (any(response.data.errors)) {
        const error_types = response.data.errors.reduce(
          (result, error) => {
            any(error.type) && result.push(error.type);
            return result;
          }, []
        );
        
        if(any(error_types)) {
          log(`Response error type: ${error_types.join(', ')}`);
        } else {
          log('Response errors:');
          deep_log(response.data.errors);
        }
      } else {
        deep_log(response.data);
      }
    }
  } catch(error) {
    log(error);
  }
}
