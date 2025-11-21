# API Gateway 验证指南

## 快速验证步骤

### 1. 配置 hosts 文件（需要管理员权限）

```powershell
# 以管理员身份运行 PowerShell
Add-Content -Path "$env:SystemRoot\System32\drivers\etc\hosts" -Value "127.0.0.1 local.orders.com"
```

### 2. 启动端口转发

```powershell
kubectl port-forward svc/traefik 80:80 -n traefik
```

保持此终端窗口打开。

### 3. 验证路由

在另一个终端运行：

```powershell
# 运行测试脚本
.\scripts\test-api-gateway.ps1

# 或手动测试
curl http://local.orders.com/doc
curl http://local.orders.com/orders
curl http://local.orders.com/metrics
```

## 预期结果

### ✅ /doc (Swagger UI)
- 应该返回 Swagger UI 页面
- HTTP 200 状态码

### ✅ /orders (Orders API)
- 应该返回订单列表（JSON 格式）
- HTTP 200 状态码

### ✅ /metrics (Prometheus Metrics)
- 应该返回 Prometheus metrics 格式数据
- HTTP 200 状态码
- 包含 `# HELP` 和 `# TYPE` 注释

## 故障排除

### 无法解析 local.orders.com
- 确保 hosts 文件已正确配置
- 刷新 DNS：`ipconfig /flushdns`
- 检查 hosts 文件权限

### 连接被拒绝
- 确保端口转发正在运行
- 检查 Traefik Service：`kubectl get svc -n traefik`
- 检查 API Pod：`kubectl get pods -l app=api`

### 404 Not Found
- 检查 Ingress：`kubectl describe ingress api-ingress`
- 检查 Traefik 日志：`kubectl logs -n traefik -l app=traefik`
- 确认 API 路由已注册

