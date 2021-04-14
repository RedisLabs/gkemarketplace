#!/usr/bin/env bash
RELEASE=${1:-6.001205}
REPO=${2:-gcr.io/proven-reality-226706/redislabs}
SA=$3

RELEASE_SUFFIX=$(echo $RELEASE | sed s/\\./-/g)
if [ -z "$SA" ];
then
SA=redis-enterprise-operator-upgrade-${RELEASE_SUFFIX}
cat <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  labels:
    app.kubernetes.io/name: redis-enterprise-operator
  name: ${SA}
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  labels:
    app.kubernetes.io/name: redis-enterprise-operator
  name: ${SA}
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: ${SA}
---
EOF
fi

cat <<EOF
apiVersion: batch/v1
kind: Job
metadata:
  labels:
    app.kubernetes.io/name: redis-enterprise-operator
  name: redis-enterprise-operator-deployer-${RELEASE_SUFFIX}
spec:
  backoffLimit: 0
  template:
    metadata:
      annotations:
        sidecar.istio.io/inject: 'false'
    spec:
      containers:
      - command:
        - /bin/deploy.sh
        image: ${REPO}/deployer:${RELEASE}
        imagePullPolicy: Always
        name: deployer
        resources:
          requests:
            cpu: 100m
            memory: 100Mi
        volumeMounts:
        - mountPath: /data/values.yaml
          name: config-volume
          readOnly: true
          subPath: values.yaml
      restartPolicy: Never
      serviceAccountName: $SA
      volumes:
      - name: config-volume
        secret:
          secretName: redis-enterprise-operator-deployer-config
EOF
