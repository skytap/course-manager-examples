// Copyright 2025 Skytap Inc.

// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at

//     http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import LabControl from './lib/labControl.js';

(async () => {
  const labControl = LabControl.get();

  console.log(`Welcome to ${(await labControl.controlData()).title}!`);
  console.log(`This Skytap environment ID is ${(await labControl.controlData()).skytap_environment_id}`)

  await labControl.updateControlData({ 'metadata': { 'AcmeDataProUsername': 'user_assigned_from_script' }, 'sensitive_metadata': { 'AcmeDataProPassword': 'password_assigned_from_script' } });

  console.log(`Metadata updated to ${JSON.stringify((await labControl.controlData()).metadata)}`);
  console.log(`Sensitive metadata updated to ${JSON.stringify((await labControl.controlData()).sensitive_metadata)} (displayed for demo purposes only -- sensitive metadata is not normally intended for exposure to end users!)`);
  console.log(await labControl.findMetadataAttr('AcmeDataProUsername'))
  console.log(await labControl.findMetadataAttr('AcmeDataProPassword'))
})();
