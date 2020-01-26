{{- define "redis_operator.CRDsConfigMap" -}}
{{- printf "%s-crd-config-map" .Release.Name | trunc 63 -}}
{{- end -}}

{{- define "redis_operator.CRDsJob" -}}
{{- printf "%s-crd-job" .Release.Name | trunc 63 -}}
{{- end -}}

{{- define "redis_operator.DeploymentName" -}}
{{- printf "%s-redis-operator" .Release.Name | trunc 63 -}}
{{- end -}}

{{- define "initContainerWaitForCRDsDeploy" -}}
- command:
  - "/bin/bash"
  - "-ec"
  - |
    timeout 120 bash -c '
    until kubectl get crd redisenterpriseclusters.app.redislabs.com;
      do echo "Waiting for Redis CRDs created"; sleep 5;
    done'
  name: wait-for-crds-created
  image: {{ .Values.deployerHelm.image }}
{{- end -}}
