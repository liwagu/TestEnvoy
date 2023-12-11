#!/bin/bash

BASE_DIR="k8s_configs"
mkdir -p ${BASE_DIR}

for i in {1..1000}; do
  cat <<EOF > ${BASE_DIR}/k8s_config_${i}.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: backend${i}
---
apiVersion: v1
kind: Service
metadata:
  name: backend${i}
  labels:
    app: backend${i}
    service: backend${i}
spec:
  ports:
    - name: http
      port: 80
      targetPort: 80
  selector:
    app: backend${i}
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend${i}
spec:
  replicas: 1
  selector:
    matchLabels:
      app: backend${i}
      version: v1
  template:
    metadata:
      labels:
        app: backend${i}
        version: v1
    spec:
      serviceAccountName: backend${i}
      containers:
        - image: nginx
          imagePullPolicy: IfNotPresent
          name: backend${i}
          ports:
            - containerPort: 80
          env:
            - name: POD_NAME
              valueFrom:
                fieldRef:
                  fieldPath: metadata.name
            - name: NAMESPACE
              valueFrom:
                fieldRef:
                  fieldPath: metadata.namespace
---
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: backend${i}
spec:
  parentRefs:
    - name: eg
      sectionName: https
  hostnames:
    - "www${i}.example.com"
  rules:
    - backendRefs:
        - group: ""
          kind: Service
          name: backend${i}
          port: 80
          weight: 1
      matches:
        - path:
            type: PathPrefix
            value: /
EOF
kubectl apply -f ${BASE_DIR}/k8s_config_${i}.yaml
done
