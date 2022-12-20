#!/bin/bash
MY_INTERVAL=${INTERVAL:-300}
MY_ENDPOINT=${ENDPOINT:-http://localhost:8888}
TIER_METRICS="--infer-metric-module tier_pricing --infer-metric-name tier_from_usage"
MY_METRICS=${METRICS:-$TIER_METRICS}
trap 'exit 255' TERM
python meter.py --interval $MY_INTERVAL --send-to $MY_ENDPOINT $MY_METRICS
