#!/usr/bin/env python3
import sys
import json
import yaml

if len(sys.argv) < 3:
    print("Usage: generate_alert_config.py <entity_file> <mobile_notifier> <telegram_notifier>", file=sys.stderr)
    sys.exit(1)

entity_file = sys.argv[1]
mobile_notifier = sys.argv[2] if sys.argv[2] != "" else None
telegram_notifier = sys.argv[3]

try:
    with open(entity_file, 'r') as f:
        entity_data = json.load(f)
except Exception as e:
    print(f"Error reading entity data: {e}", file=sys.stderr)
    sys.exit(1)

notifiers = [telegram_notifier]
if mobile_notifier:
    notifiers.append(mobile_notifier)

alert_config = {
    'alert': {}
}

# Device tracker offline alerts
for entity in entity_data.get('device_tracker', [])[:20]:  # Limit to 20
    entity_name = entity.replace('device_tracker.', '').replace('_', ' ').title()
    alert_key = entity.replace('device_tracker.', '').replace('.', '_')
    alert_config['alert'][f'{alert_key}_offline'] = {
        'name': f'{entity_name} Offline',
        'done_message': f'{entity_name} Back Online',
        'entity_id': entity,
        'state': 'not_home',
        'repeat': 30,
        'can_acknowledge': True,
        'skip_first': False,
        'notifiers': notifiers
    }

# Binary sensor offline alerts (with "online" or "available" in name)
for entity in entity_data.get('binary_sensor', []):
    if 'online' in entity.lower() or 'available' in entity.lower():
        entity_name = entity.replace('binary_sensor.', '').replace('_', ' ').title()
        alert_key = entity.replace('binary_sensor.', '').replace('.', '_')
        alert_config['alert'][f'{alert_key}_offline'] = {
            'name': f'{entity_name} Offline',
            'done_message': f'{entity_name} Back Online',
            'entity_id': entity,
            'state': 'off',
            'repeat': 60,
            'can_acknowledge': True,
            'skip_first': False,
            'notifiers': notifiers
        }

# Output as YAML
yaml_output = yaml.dump(alert_config, default_flow_style=False, sort_keys=False)
print(yaml_output)

