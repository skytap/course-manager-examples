const axios = require('axios');

class SkytapMetadata {
    constructor() {
        throw new Error('Use SkytapMetadata.get()');
    }

    static get() {
        if (!this.instance) {
            this.instance = new PrivateSkytapMetadata();
        }

        return this.instance;
    }
};

class PrivateSkytapMetadata {
    constructor() {
        this.baseURL = "http://skytap-metadata/skytap";
    }

    async metadata() {
        if (!this.metadataData) {
            this.metadataData = (await axios.get(this.baseURL)).data;
        }
        return this.metadataData;
    }

    async userData() {
        return (await this.metadata()).user_data;
    }

    async configurationUserData() {
        return (await this.metadata()).configuration_user_data;
    }

    async controlURL() {
        return JSON.parse(await this.userData()).control_url;
    }
}

module.exports = SkytapMetadata;
