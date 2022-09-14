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

import { raise_error, compare, log, none } from './utils.js';
import * as skytap from './skytap.js';
import * as tags from './tags.js';

const TARGET_ENVIRONMENT_PREFIX = 'target_environment_id';
const TARGET_NETWORK_PREFIX = 'target_network_name';
const SOURCE_NETWORK_PREFIX = 'source_network_name';

export async function connect() {
  try {
    const source_id = await skytap.environment_id();
    const source = await skytap.environment(source_id);
    const source_tags = tags.calculate(source);
    const source_network_name = tags.ensure_zero_or_one(source_tags, SOURCE_NETWORK_PREFIX);
    const source_network = find_network(source.networks, source_network_name);

    if (none(source_network)) {
      raise_error('Source network matching criteria not found');
    }

    const target_id = tags.ensure_one(source_tags, TARGET_ENVIRONMENT_PREFIX);
    const target = await skytap.environment(target_id);
    const target_networks = tunnelable_networks(target.networks);
    const target_network_name = tags.ensure_zero_or_one(source_tags, TARGET_NETWORK_PREFIX);
    const target_network = find_network(target_networks, target_network_name);

    if (none(target_network)) {
      raise_error('Target network matching criteria not found');
    }

    if (!compare(target_network.region, source_network.region)) {
      raise_error('Target and source in different regions');
    }
    
    const tunnel = await get_or_create_tunnel({ source_network, target_network });
    
    return tunnel;
    
  } catch(error) {
    raise_error(error);
  }
}

function find_network(networks, name) {
  const matches = networks_by_name(networks, name);
  return matches && matches.length > 0 ? matches[0] : null;
}

function networks_by_name(networks, name) {
  if (none(name) || none(networks)) {
    return networks;
  } else {
    return networks.filter(network => compare(name, network.name));
  }
}

function tunnelable_networks(networks) {
  return networks.filter(network => network.tunnelable);
}

async function get_or_create_tunnel({source_network, target_network}) {
  const found_tunnel = source_network.tunnels.find(tunnel => {
    return tunnel.target_network.id === target_network.id;
  });
  if (found_tunnel) {
    log(`Tunnel found: ${found_tunnel.id}`);
    return found_tunnel;
  } else {
    const new_tunnel = await skytap.post('v2/tunnels.json', {
      source_network_id: source_network.id,
      target_network_id: target_network.id
    });
    log(`Tunnel created: ${new_tunnel.id}`);
    return new_tunnel;
  }
}