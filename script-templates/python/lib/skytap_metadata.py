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