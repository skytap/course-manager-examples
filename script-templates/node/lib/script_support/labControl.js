// Copyright 2023 Skytap Inc.

// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at

//     http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

const axios = require('axios');
const SkytapMetadata = require('./skytapMetadata');

class LabControl {
    constructor() {
        throw new Error('Use LabControl.get()');
    }

    static async get() {
        if (!this.instance) {
            this.instance = new PrivateLabControl(await SkytapMetadata.get().controlURL());
        }

        return this.instance;
    }
};

class PrivateLabControl {
    constructor(controlURL) {
        this.controlURL = controlURL;
    }

    async controlData() {
        if (!this.controlDataData) {
            this.controlDataData = (await axios.get(this.controlURL)).data;
        }
        return this.controlDataData;
    }

    async updateControlData(data) {
        let result = await axios.put(this.controlURL, data);
        this.controlDataData = result.data;
        return this.controlDataData;
    }

    async findMetadataAttr(key, within = undefined) {
        let collections = [];
        if (within) {
            collections.push(within);
        } else {
            collections.push('metadata', 'sensitive_metadata');
        }
        for (const collection of collections) {
            for (const obj of [null, 'event', 'course', 'user', 'feature']) {
                let data = await this.controlData();
                if (obj != null) data = data[obj];
                if (data[collection] && data[collection][key]) {
                    return data[collection][key];
                }
            }
        }
        return null;
    }

    async refreshContentPane() {
        return await this.#labBroadcast('refresh_content_pane');
    }

    async refreshLab() {
        return await this.#labBroadcast('refresh_lab');
    }

    async #labBroadcast(type) {
        let broadcastURL = `${(await this.controlData()).user_access_url}/learning_console/broadcast`;
        return await axios.post(broadcastURL, {type: type});
    }
}

module.exports = LabControl;