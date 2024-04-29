#!/bin/bash

# Step 1: Create ServiceAccount
kubectl apply -f - <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: developer-sa
EOF

# Step 2: Create Secret
kubectl apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: developer-sa-secret
  annotations:
    kubernetes.io/service-account.name: developer-sa
type: kubernetes.io/service-account-token
EOF

# Step 3: Apply ClusterRole
kubectl apply -f - <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: developer-readonly-access
rules:
- apiGroups:
  - ""
  - apps
  - extensions
  - batch
  - networking.k8s.io
  resources:
  - pods
  - services
  - deployments
  - replicasets
  - secrets
  - configmaps
  - persistentvolumeclaims
  - namespaces
  - cronjobs
  - jobs
  - ingresses
  - pods/log
  - pods/exec
  verbs:
  - list
  - watch
  - get
  - create
EOF

# Step 4: Apply ClusterRoleBinding
kubectl apply -f - <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: developer-readonly-access-binding
subjects:
- kind: ServiceAccount
  name: developer-sa
  namespace: default
roleRef:
  kind: ClusterRole
  name: developer-readonly-access
  apiGroup: rbac.authorization.k8s.io
EOF

# Step 5: Generate Developer kubeconfig
CA_DATA=$(kubectl config view --minify --flatten | grep certificate-authority-data | awk '{print $2}')
SERVER=$(kubectl config view --minify --raw -o jsonpath='{.clusters[].cluster.server}')
CLUSTER_NAME=$(kubectl config view --minify --raw -o jsonpath='{.clusters[].name}')
TOKEN=$(kubectl get secret developer-sa-secret -o jsonpath='{.data.token}' | base64 --decode)

cat <<EOF > developer-kubeconfig.yaml
apiVersion: v1
kind: Config
clusters:
- cluster:
    certificate-authority-data: $CA_DATA
    server: $SERVER
  name: $CLUSTER_NAME
contexts:
- context:
    cluster: $CLUSTER_NAME
    user: developer-sa
  name: developer-context
current-context: developer-context
users:
- name: developer-sa
  user:
    token: $TOKEN
EOF

echo "Developer kubeconfig generated successfully."
