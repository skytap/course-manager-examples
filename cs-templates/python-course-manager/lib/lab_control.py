# Copyright 2025 Skytap Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import json
import os
import requests
from requests.auth import HTTPBasicAuth

class LabControl:
    _instance = None

    @classmethod
    def get(cls):
        if cls._instance is None:
            control_url = os.getenv("CONTROL_ENDPOINT_URL")
            if control_url:
                cls._instance = LiveLabControl(control_url, os.getenv("CREDENTIAL_USERNAME"), os.getenv("CREDENTIAL_TOKEN"))
            else:
                cls._instance = StubbedLabControl()
        return cls._instance

    def control_data(self):
        if not hasattr(self, '_control_data'):
            self._control_data = json.loads(self.control_data_json())
        return self._control_data

    def update_control_data(self, data):
        raise NotImplementedError

    def refresh_content_pane(self):
        raise NotImplementedError

    def refresh_lab(self):
        raise NotImplementedError

    def find_metadata_attr(self, key, within=None):
        collections = [within] if within else ['metadata', 'sensitive_metadata']
        for collection in collections:
            for obj in [None, 'event', 'course', 'user', 'feature']:
                path = [obj, collection, key] if obj else [collection, key]
                value = self._dig(self.control_data(), *filter(None, path))
                if value is not None:
                    return value
        return None

    def _dig(self, data, *keys):
        for key in keys:
            if isinstance(data, dict) and key in data:
                data = data[key]
            else:
                return None
        return data

    def control_data_json(self):
        raise NotImplementedError

class LiveLabControl(LabControl):
    def __init__(self, control_url, username, token):
        self._control_url = control_url
        self._username = username
        self._token = token

    def update_control_data(self, data):
        response = requests.put(
            self._control_url,
            json=data,
            auth=HTTPBasicAuth(self._username, self._token)
        )
        response.raise_for_status()
        self._control_data_json = response.text

    def refresh_content_pane(self):
        self._lab_broadcast('refresh_content_pane')

    def refresh_lab(self):
        self._lab_broadcast('refresh_lab')

    def _lab_broadcast(self, type):
        broadcast_url = f"{self.control_data()['user_access_url']}/learning_console/broadcast"
        response = requests.post(
            broadcast_url,
            json={"type": type}
        )
        response.raise_for_status()

    def control_data_json(self):
        if not hasattr(self, '_control_data_json'):
            response = requests.get(
                self._control_url,
                auth=HTTPBasicAuth(self._username, self._token)
            )
            response.raise_for_status()
            self._control_data_json = response.text
        return self._control_data_json

class StubbedLabControl(LabControl):
    METADATA_FIELDS = [
        ['metadata'], ['sensitive_metadata'],
        ['feature', 'metadata'], ['feature', 'sensitive_metadata'],
        ['course', 'metadata'], ['course', 'sensitive_metadata'],
        ['user', 'metadata'], ['user', 'sensitive_metadata'],
        ['event', 'metadata'], ['event', 'sensitive_metadata'],
    ]

    def refresh_content_pane(self):
        pass

    def refresh_lab(self):
        pass

    def control_data_json(self):
        if not hasattr(self, '_control_data_json'):
            with open(os.path.join(os.path.dirname(__file__), "stub_data/control_data.json")) as f:
                self._control_data_json = f.read()
        return self._control_data_json

    def update_control_data(self, data):
        for keys in self.METADATA_FIELDS:
            incoming_metadata = self._dig(data, *keys)
            if isinstance(incoming_metadata, dict):
                self._update_metadata(keys, incoming_metadata)
        return self.control_data()

    def _update_metadata(self, keys, incoming_metadata):
        first_key = keys[0]
        if first_key not in self.control_data():
            self.control_data()[first_key] = {}
        if len(keys) > 1:
            second_key = keys[1]
            if second_key not in self.control_data()[first_key]:
                self.control_data()[first_key][second_key] = {}
            self.control_data()[first_key][second_key].update(incoming_metadata)
        else:
            self.control_data()[first_key].update(incoming_metadata)

  

