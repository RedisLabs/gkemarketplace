# Usage Meter Sidecar

## Overview

For usage metering with Redis Enterprise, the `meter.py` program provides the
ability to read the cluster node sizing, shard usage, and shard maximum and
report that usage to a billing endpoint.

## Collecting Usage

The metrics that can be collected:

 * `interval` - the time period for the usage
 * `memory` - the memory allocated to the RS node
 * `cpu` - the cpu allocated to the RS node
 * `shards_used` - the number of shards in use by the cluster
 * `shards_max` - the maximum shards allowed by the licensed used by the cluster

A report contains is send to the billing endpoint in JSON format that
contains:

 * `name` - the metric name
 * `startTime` - an ISO 8601 timestamp of the start datetime of the period
 * `endTime` - an ISO 8601 timestamp of the end datetime of the period
 * `value` - the metric value (e.g., '{ "int64Value" : 10}')

The `meter.py` program has the following options:

 * `--use-config` - enable using the .kubeconfig file for K8s credentials
 * `--interval nn` - the collection interval (in seconds)
 * `--namespace ns` - the namespace to inspect (defaults to the context or pod namespace)
 * `--send-to url` - the URL of the reporting endpoint to which to send the reports
 * `--metric-name name` - the name of the metric to report
 * `--report-value name` - the value to report - must be one of metric names (e.g., shards_used). This defaults to the time period between the last succesful report and the current report.
 * `--shards` - enable reading the shard used/max from the cluster REST API
 * `--infer-metric-name` - a python function expression to infer the metric name. If the `--infer-metric-module` option is used, this value is the name of a function in that module.
 * `--infer-metric-module` - the python module for the the expression.

A metric name can be dynamically computed from the collected metrics. For example:

```
python meter.py --infer-metric-module tier_pricing --infer-metric-name tier_from_usage
```

## Sidecar usage

See the example in [operator-with-meter.yaml](operator-with-meter.yaml).

The meter container can be built via:

```
docker build -t you/redis-k8s-meter-usage:latest .
```

And the demonstration bill agent receiver via:

```
docker build -t you/flask-receiver:latest -f receiver.Dockerfile .
```
