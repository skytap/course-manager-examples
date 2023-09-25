# Copyright 2023 Skytap Inc.

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
from skytap_metadata import SkytapMetadata

class LabControl:
  def __new__(cls):
    if not hasattr(cls, 'instance'):
      cls.instance = super(LabControl, cls).__new__(cls)
    return cls.instance

  def __init__(self):
    self.control_url = SkytapMetadata().control_url()

  def control_data(self):
    if not hasattr(self, 'control_data_data'):
      self.control_data_data = requests.get(self.control_url).json()
    return self.control_data_data

  def find_metadata_attr(self, key, within = None):
    collections = []
    if within != None:
      collections.append(within)
    else:
      collections.append('metadata')
      collections.append('sensitive_metadata')
    for collection in collections:
      for k in [None, 'event', 'course', 'user', 'feature']:
        data = self.control_data()
        if (data != None) and (k in data):
          data = data[k]
        if (collection in data) and (key in data[collection]):
          return data[collection][key]
    return None

  def update_control_data(self, data):
    if (type(data) == dict):
      data = json.dumps(data)

    self.control_data_data = requests.put(self.control_url, data=data, headers={'content-type': 'application/json'}).json()
    return self.control_data_data

  def refresh_content_pane(self):
    self.__lab_broadcast('refresh_content_pane')

  def refresh_lab(self):
    self.__lab_broadcast('refresh_lab')

  def __lab_broadcast(self, type):
    broadcast_url = f'{self.control_data()["user_access_url"]}/learning_console/broadcast'
    requests.post(broadcast_url, json={'type': type})