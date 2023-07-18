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

const SkytapMetadata = require('skytapMetadata');
const LabControl = require('labControl');

(async () => {
    const skytapMetadata = SkytapMetadata.get();
    const labControl = await LabControl.get();

    console.log(`Welcome to ${(await labControl.controlData()).title}!`);
    console.log(`This Skytap environment is ${(await skytapMetadata.metadata()).configuration_url}`)

    await labControl.updateControlData({ 'metadata': { 'AcmeDataProUsername': 'user_assigned_from_script'}, 'sensitive_metadata': { 'AcmeDataProPassword': 'password_assigned_from_script' } });

    console.log(`Metadata updated to ${JSON.stringify((await labControl.controlData()).metadata)}`);
    console.log(`Sensitive metadata updated to ${JSON.stringify((await labControl.controlData()).sensitive_metadata)}`);
})();