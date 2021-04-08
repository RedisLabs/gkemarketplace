import sys
import argparse
import signal
import time
import datetime
import importlib

from common import bootstrap, get_rec_specs, get_rec_api

import requests
import urllib3
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

running = True
def sigterm_handler(signal,frame):
   running = False
   sys.print('SIGTERM received - terminating process.')
signal.signal(signal.SIGTERM, sigterm_handler)

def tstamp():
   return datetime.datetime.utcnow().replace(tzinfo=datetime.timezone.utc).isoformat()

def parse_numberunit(value):
   unit_pos = -1
   for index, digit in enumerate(value):
      if not digit.isdigit():
         unit_pos = index
         break
   if unit_pos < 0:
      return float(value), None
   else:
      return float(value[0:unit_pos]),value[unit_pos:]


def parse_cpu(value):
   scalar, unit = parse_numberunit(value)
   if unit == 'm':
      scalar / 1000.0
   return scalar

memory_units = {
   'K' : 10**3,
   'M' : 10**6,
   'G' : 10**9,
   'T' : 10**12,
   'P' : 10**15,
   'Ki' : 2**10,
   'Mi' : 2**20,
   'Gi' : 2**30,
   'Ti' : 2**40,
   'Pi' : 2**50
}

def parse_memory(value):
   scalar, unit = parse_numberunit(value)
   if unit is not None:
      if unit not in memory_units:
         return None
      multiplier = memory_units[unit]
      scalar = scalar * multiplier
   scalar = scalar / memory_units['Gi']
   return scalar

def requested_value(current,resources,category,item,parser):
   if category in resources:
      if item in resources[category]:
         value = parser(resources[category][item])
         if value > current:
            current = value
   return current

def get_shards(namespace, name):
   base_url, username, password = get_rec_api(namespace,name)

   response = requests.get(base_url + '/v1/nodes',auth=(username,password),verify=False)
   if response.status_code != 200:
      raise Exception('Cannot get nodes from REST API {}, status={}'.format(base_url,response.status_code))
   nodes = response.json()
   response = requests.get(base_url + '/v1/license',auth=(username,password),verify=False)
   if response.status_code != 200:
      raise Exception('Cannot get license from REST API {}, status={}'.format(base_url,response.status_code))
   license = response.json()
   used = 0
   for node in nodes:
      count = node.get('shard_count')
      if count is not None:
         used += count
   max = license.get('shards_limit')

   return used, max

def send_report(endpoint,data):
   print('\x1E',data,sep='',flush=True)
   response = requests.post(endpoint,json=data)
   if response.status_code < 200 or response.status_code >= 300:
      print('Cannot post report, status={}'.format(response.status_code),flush=True)
      return False
   return True

def report_usage(namespace,interval=60,shards=False,report=None):
   start = tstamp()
   since_last_report = 0
   if report is None:
      def printer(*args):
         print(args,flush=True)
      report = printer
   while running:
      time.sleep(interval)
      end = tstamp()
      since_last_report += interval
      try:
         sent = True
         for name, rec in get_rec_specs(namespace):
            cpu = 2.0
            memory = 4.0
            if 'redisEnterpriseNodeResources' in rec:
               resources = rec['redisEnterpriseNodeResources']
               cpu = requested_value(cpu,resources,'requests','cpu',parse_cpu)
               cpu = requested_value(cpu,resources,'limits','cpu',parse_cpu)
               memory = requested_value(memory,resources,'requests','memory',parse_memory)
               memory = requested_value(memory,resources,'limits','memory',parse_memory)
            shards_used = 0
            shards_max = 0
            if shards:
               shards_used, shards_max = get_shards(namespace,name)
            success = report(name,start,end,{'interval':since_last_report,'cpu':cpu,'memory':memory,'shards_used':shards_used,'shards_max':shards_max})
            if not success:
               sent = False
         if sent:
            since_last_report = 0
            start = tstamp()
      except Exception as e:
         print(e,file=sys.stderr)



if __name__ == "__main__":

   argparser = argparse.ArgumentParser(description='kubectl-redis-rec')
   argparser.add_argument('--verbose',help='Verbose output',action='store_true',default=False)
   argparser.add_argument('--use-config',help='Use the .kubeconfig',action='store_true',default=False)
   argparser.add_argument('--interval',help='Usage interval (in seconds)',type=int,default=60)
   argparser.add_argument('--time-period',help='The time period for reporting (e.g. per hour 3600)',type=int)
   argparser.add_argument('--namespace',help='The namespace; defaults to the context.')
   argparser.add_argument('--send-to',help='The URL of the endpoint to report the usage.')
   argparser.add_argument('--shards',help='Enable shard usage report',action='store_true',default=False)
   argparser.add_argument('--metric-name',help='The metric to report')
   argparser.add_argument('--report-value',help='The value to report',choices=['interval','cpu','memory','shards_used','shards_max'],default='interval')
   argparser.add_argument('--infer-metric-module',help='An function to compute the metric name')
   argparser.add_argument('--infer-metric-name',help='An function to compute the metric name')

   args = argparser.parse_args()

   namespace = bootstrap(use_config=args.use_config,namespace=args.namespace)

   if namespace is None:
      print('Cannot determine current namespace.',file=sys.stderr)
      sys.exit(1)

   metric_namer = (lambda data : args.metric_name) if args.metric_name is not None else (lambda data : args.report_value)
   if args.infer_metric_name is not None:
      if args.infer_metric_module:
         m = importlib.import_module(args.infer_metric_module)
         metric_namer = getattr(m,args.infer_metric_name)
      else:
         metric_name = eval(args.infer_metric_name)

   def print_report(name,start,end,data):
      metric = metric_namer(data)
      print('{}: {} {} {} {}'.format(name,metric,start,end,data),flush=True)
      return True
   report = print_report

   scale = None

   if args.time_period:
      scale = args.interval / args.time_period

   if args.send_to:
      def sender(name,start,end,data):
         metric = metric_namer(data)
         value = int(data[args.report_value])
         usage_data = {
            'name' : metric,
            'startTime' : start,
            'endTime' : end,
            'value' : { 'int64Value' : value} if scale is None else {'doubleValue' : value * scale}
         }
         return send_report(args.send_to,usage_data)
      report = sender

   report_usage(namespace,interval=args.interval,shards=args.shards,report=report);
