{{- define "redis_operator.CRDsJob" -}}
{{- printf "%s-crd-job" .Release.Name | trunc 63 -}}
{{- end -}}

{{- define "redis_operator.DeployPatchJob" -}}
{{- printf "%s-deploy-patch-job" .Release.Name | trunc 63 -}}
{{- end -}}

{{- define "redis_operator.CRsConfigMap" -}}
{{- printf "%s-cr-config-map" .Release.Name | trunc 63 -}}
{{- end -}}

{{- define "redis_operator.UBBAgentConfigMap" -}}
{{- printf "%s-ubbagent-config-map" .Release.Name | trunc 63 -}}
{{- end -}}

{{- define "redis_operator.CRsJob" -}}
{{- printf "%s-cr-job" .Release.Name | trunc 63 -}}
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
    COUNTER=0
    until kubectl get crd redisenterpriseclusters.app.redislabs.com redisenterprisedatabases.app.redislabs.com;
      do ((COUNTER++)); echo "Waiting for Redis CRDs to be created, counter: ${COUNTER}"; sleep 5;
    done
    echo "Finished waiting for Redis CRDs to be created"'

  name: wait-for-crds-created
  image: {{ .Values.deployerHelm.image }}
{{- end -}}

{{- define "initContainerWaitForOperator" -}}
- command:
  - "/bin/bash"
  - "-ec"
  - |
    timeout 600 bash -c '
      STATE="PendingCreation"
      while [ "$STATE" = "PendingCreation" ];
      do
        echo "Waiting for redis enterprise operator to be active"; STATE=$(kubectl get --namespace="{{ .Release.Namespace }}" rec/redis-enterprise -o jsonpath='{.status.state}') ; sleep 5;
      done 
      echo "Redis Enterprise Cluster resource is Active"
    '

  name: wait-for-cr-patch-created
  image: {{ .Values.deployerHelm.image }}
{{- end -}}
