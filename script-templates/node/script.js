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

const SkytapMetadata = require('./lib/skytapMetadata');
const LabControl = require('./lib/labControl');

(async () => {
    const skytapMetadata = SkytapMetadata.get();
    const labControl = await LabControl.get();

    console.log(`Welcome to ${(await labControl.controlData()).title}!`);
    console.log(`This Skytap environment is ${(await skytapMetadata.metadata()).configuration_url}`)

    // Note: custom data attributes must be configured in Course Manager settings to be saved; see README.md
    await labControl.updateControlData({'integration_data':{'AcmeDataProUsername': 'user_assigned_from_script', 'AcmeDataProPassword':'password_assigned_from_script'}});

    await labControl.refreshContentPane();

    console.log(`Integration data updated to ${JSON.stringify((await labControl.controlData()).integration_data)}`);
})();