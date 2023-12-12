#!/bin/bash

# 设置目录和基本配置
BASE_DIR="k8s_configs"
mkdir -p ${BASE_DIR}


i=5999

cat <<EOF > ${BASE_DIR}/test_backend${i}.yaml
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

kubectl apply -f ${BASE_DIR}/test_backend${i}.yaml





# 应用YAML文件
kubectl apply -f ${BASE_DIR}/test_backend${i}.yaml


# 检查Pod是否就绪，并记录开始时间
echo "正在等待 pod backend${i} 变为就绪状态..."
start_time=$(date +%s)
while true; do
  current_time=$(date +%s)
  if kubectl get pods -l app=backend${i} -o jsonpath='{.items[*].status.conditions[?(@.type=="Ready")].status}' | grep -q "True"; then
    echo "Pod backend${i} 已经就绪."
    pod_ready_time=$(date +%s)
    break
  else
    echo "等待了 $((current_time - start_time)) 秒..."
  fi
  sleep 1
done

# 输出创建Pod所需的总时间
echo "创建 pod backend${i} 花费了总共 $((pod_ready_time - start_time)) 秒."

# 测试Gateway生效时间
echo "正在测试 Gateway 生效时间..."
for j in {1..300}; do 
  if  curl --verbose --header "Host: www${i}.example.com" --resolve "www${i}.example.com:31283:192.168.0.1" --cacert CA.crt https://www${i}.example.com:31283; then
    gateway_effective_time=$(date +%s)
    echo "Gateway 在 $((gateway_effective_time - pod_ready_time)) 秒后生效."
    break
  fi
  sleep 1
done