# Copyright 2022 Skytap Inc.

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at

#     http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import requests
import json

class SkytapMetadata:
  base_url = "http://skytap-metadata/skytap"

  def __new__(cls):
    if not hasattr(cls, 'instance'):
      cls.instance = super(SkytapMetadata, cls).__new__(cls)
    return cls.instance

  def metadata(self):
    if not hasattr(self, 'metadata_data'):
      self.metadata_data = requests.get(self.base_url).json()
    return self.metadata_data

  def user_data(self):
    return json.loads(self.metadata()['user_data'])

  def configuration_user_data(self):
    return json.loads(self.metadata()['configuration_user_data'])

  def control_url(self):
    return self.user_data()['control_url']