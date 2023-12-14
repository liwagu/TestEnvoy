### 测试方法
1. kubectl apply -f qs_https, 创建gateway
2. 执行 init, 创建大量pod
3. 执行 test, 查看生效速度

### 测试结果
创建1000个pod的情况下 再次提交workload，网关生效速度依然是0s
![img.png](img.png)
![img_1.png](img_1.png)
