// Copyright 2026 Kyndryl Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import fs from 'fs';
import path from 'path';
import axios from 'axios';
import { fileURLToPath } from 'url';
import { dirname } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

export default class LabControl {
  static #instance = null;

  static get() {
    if (!LabControl.#instance) {
      const controlUrl = process.env.CONTROL_ENDPOINT_URL;
      if (controlUrl) {
        LabControl.#instance = new LiveLabControl(controlUrl, process.env.CREDENTIAL_USERNAME, process.env.CREDENTIAL_TOKEN);
      } else {
        LabControl.#instance = new StubbedLabControl();
      }
    }
    return LabControl.#instance;
  }

  async controlData() {
    if (!this._controlData) {
      this._controlData = await this.loadControlData();
    }
    return this._controlData;
  }

  async updateControlData(data) {
    throw new Error('NotImplementedError');
  }

  async refreshContentPane() {
    throw new Error('NotImplementedError');
  }

  async refreshLab() {
    throw new Error('NotImplementedError');
  }

  async findMetadataAttr(key, within = null) {
    const controlData = await this.controlData();
    const collections = within ? [within] : ['metadata', 'sensitive_metadata'];
    for (const collection of collections) {
      for (const obj of [null, 'event', 'course', 'user', 'feature']) {
        const pathArray = obj ? [obj, collection, key] : [collection, key];
        const value = this._dig(controlData, ...pathArray.filter(Boolean));
        if (value !== undefined) {
          return value;
        }
      }
    }
    return null;
  }

  _dig(data, ...keys) {
    for (const key of keys) {
      if (data && typeof data === 'object' && key in data) {
        data = data[key];
      } else {
        return undefined;
      }
    }
    return data;
  }

  async loadControlData() {
    throw new Error('NotImplementedError');
  }
}

class LiveLabControl extends LabControl {
  #controlUrl;
  #username;
  #token;
  #controlDataObject;

  constructor(controlUrl, username, token) {
    super();
    this.#controlUrl = controlUrl;
    this.#username = username;
    this.#token = token;
  }

  async updateControlData(data) {
    const response = await axios.put(this.#controlUrl, data, {
      auth: {
        username: this.#username,
        password: this.#token
      }
    });
    this.#controlDataObject = response.data;
  }

  async refreshContentPane() {
    await this.#labBroadcast('refresh_content_pane');
  }

  async refreshLab() {
    await this.#labBroadcast('refresh_lab');
  }

  async #labBroadcast(type) {
    const controlData = await this.controlData();
    const broadcastUrl = `${controlData.user_access_url}/learning_console/broadcast`;
    await axios.post(broadcastUrl, { type });
  }

  async loadControlData() {
    if (!this.#controlDataObject) {
      const response = await axios.get(this.#controlUrl, {
        auth: {
          username: this.#username,
          password: this.#token
        }
      });
      this.#controlDataObject = response.data;
    }
    return this.#controlDataObject;
  }
}

class StubbedLabControl extends LabControl {
  #METADATA_FIELDS = [
    ['metadata'],
    ['sensitive_metadata'],
    ['feature', 'metadata'],
    ['feature', 'sensitive_metadata'],
    ['course', 'metadata'],
    ['course', 'sensitive_metadata'],
    ['user', 'metadata'],
    ['user', 'sensitive_metadata'],
    ['event', 'metadata'],
    ['event', 'sensitive_metadata']
  ];

  async refreshContentPane() {
    // No operation, but async
  }

  async refreshLab() {
    // No operation, but async
  }

  async loadControlData() {
    if (!this._controlDataObject) {
      const filePath = path.join(__dirname, 'stub_data', 'control_data.json');
      const fileString = await fs.promises.readFile(filePath, 'utf8');
      this._controlDataObject = JSON.parse(fileString);
    }
    return this._controlDataObject;
  }

  async updateControlData(data) {
    const controlData = await this.controlData();
    for (const keys of this.#METADATA_FIELDS) {
      const incomingMetadata = this._dig(data, ...keys);
      if (typeof incomingMetadata === 'object') {
        this._updateMetadata(controlData, keys, incomingMetadata);
      }
    }
    return controlData;
  }

  _updateMetadata(controlData, keys, incomingMetadata) {
    const firstKey = keys[0];
    if (!controlData[firstKey]) {
      controlData[firstKey] = {};
    }
    if (keys.length > 1) {
      const secondKey = keys[1];
      if (!controlData[firstKey][secondKey]) {
        controlData[firstKey][secondKey] = {};
      }
      Object.assign(controlData[firstKey][secondKey], incomingMetadata);
    } else {
      Object.assign(controlData[firstKey], incomingMetadata);
    }
  }
}
