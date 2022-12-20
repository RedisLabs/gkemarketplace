import os

from kubernetes import client, config
from kubernetes.client.rest import ApiException

from base64 import b64decode

import yaml

apis = {
   'rec' : {
      'group' : 'app.redislabs.com',
      'version' : 'v1',
      'kind' : 'RedisEnterpriseCluster',
      'plural' : 'redisenterpriseclusters'
   },
   'redb' : {
      'group' : 'app.redislabs.com',
      'version' : 'v1alpha1',
      'kind' : 'RedisEnterpriseDatabase',
      'plural' : 'redisenterprisedatabases'
   }
}

def get_api(name):
   return apis.get(name).copy()

def _current_namespace_from_kubeconfig():
   location = os.path.expanduser(os.environ.get('KUBECONFIG', '~/.kube/config'))
   with open(location,'r') as config_data:
      kconfig = yaml.load(config_data,Loader=yaml.Loader)
      current_context = kconfig.get('current-context')
      if current_context is not None:
         for context in kconfig.get('contexts',[]):
            if current_context==context.get('name'):
               cluster = context.get('context',{})
               return cluster.get('namespace')
   return None

NAMESPACE_LOCATION='/var/run/secrets/kubernetes.io/serviceaccount/namespace'

def bootstrap(use_config=False,namespace=None):
   if use_config or os.getenv('KUBERNETES_SERVICE_HOST') is None:
      config.load_kube_config()
      return namespace if namespace is not None else _current_namespace_from_kubeconfig()
   else:
      config.load_incluster_config()

      if os.path.isfile(NAMESPACE_LOCATION):
         with open(NAMESPACE_LOCATION,'r') as data:
            ns = data.read().strip()
            return ns
      else:
         return None

def get_rec_specs(namespace):

   try:

      custom_objects = client.CustomObjectsApi()
      api_spec = get_api('rec')
      obj_list = custom_objects.get_namespaced_custom_object(api_spec['group'],api_spec['version'],namespace,api_spec['plural'],'')

      return [(obj_list['items'][0]['metadata']['name'],item['spec']) for item in obj_list['items']]

   except ApiException as e:
      if e.status==404:
         return []
      else:
         print('{}: {}'.format(str(e.status),e.reason),file=sys.stderr)
         return []

def get_rec_api(namespace,name):
   dns_name = name + '.' + namespace + '.svc'
   url = 'https://' + dns_name + ':9443'

   try:

      api = client.CoreV1Api()
      secret = api.read_namespaced_secret(name,namespace)
      password = secret.data.get('password')
      username = secret.data.get('username')
      return url, b64decode(username).decode() if username is not None else None, b64decode(password).decode() if password is not None else None,

   except ApiException as e:
      if e.status==404:
         return None
      else:
         raise e
