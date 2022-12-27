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