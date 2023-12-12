#!/bin/bash

# 设置包含YAML文件的目录
BASE_DIR="k8s_configs"

# 删除YAML文件中定义的所有对象
kubectl delete -f ${BASE_DIR}/

# 删除生成的YAML文件
rm -rf ${BASE_DIR}/
