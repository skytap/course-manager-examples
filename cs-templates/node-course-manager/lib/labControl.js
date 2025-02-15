import fs from 'fs';
import path from 'path';
import axios from 'axios';
import { fileURLToPath } from 'url';
import { dirname } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

export default class LabControl {
  static _instance = null;

  static get() {
    if (!LabControl._instance) {
      const controlUrl = process.env.LAB_CONTROL_PROXY_URL;
      if (controlUrl) {
        LabControl._instance = new LiveLabControl(controlUrl);
      } else {
        LabControl._instance = new StubbedLabControl();
      }
    }
    return LabControl._instance;
  }

  async controlData() {
    if (!this._controlData) {
      const controlDataJson = await this.controlDataJson();
      this._controlData = JSON.parse(controlDataJson);
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
        const path = obj ? [obj, collection, key] : [collection, key];
        const value = this._dig(controlData, ...path.filter(Boolean));
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

  controlDataJson() {
    throw new Error('NotImplementedError');
  }
}

class LiveLabControl extends LabControl {
  constructor(controlUrl) {
    super();
    this._controlUrl = controlUrl;
  }

  async updateControlData(data) {
    const response = await axios.put(this._controlUrl, data);
    this._controlDataJson = response.data;
  }

  async refreshContentPane() {
    await this._labBroadcast('refresh_content_pane');
  }

  async refreshLab() {
    await this._labBroadcast('refresh_lab');
  }

  async _labBroadcast(type) {
    const broadcastUrl = `${this.controlData().user_access_url}/learning_console/broadcast`;
    await axios.post(broadcastUrl, { type });
  }

  async controlDataJson() {
    if (!this._controlDataJson) {
      const response = await axios.get(this._controlUrl);
      this._controlDataJson = response.data;
    }
    return this._controlDataJson;
  }
}

class StubbedLabControl extends LabControl {
  constructor() {
    super();
    this.METADATA_FIELDS = [
      ['metadata'], ['sensitive_metadata'],
      ['feature', 'metadata'], ['feature', 'sensitive_metadata'],
      ['course', 'metadata'], ['course', 'sensitive_metadata'],
      ['user', 'metadata'], ['user', 'sensitive_metadata'],
      ['event', 'metadata'], ['event', 'sensitive_metadata'],
    ];
  }

  async refreshContentPane() {
    // No operation, but async
  }

  async refreshLab() {
    // No operation, but async
  }

  async controlDataJson() {
    if (!this._controlDataJson) {
      const filePath = path.join(__dirname, 'stub_data', 'control_data.json');
      this._controlDataJson = await fs.promises.readFile(filePath, 'utf8');
    }
    return this._controlDataJson;
  }

  async updateControlData(data) {
    const controlData = await this.controlData();
    for (const keys of this.METADATA_FIELDS) {
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