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