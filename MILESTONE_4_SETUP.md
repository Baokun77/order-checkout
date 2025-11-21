# 里程碑 4：API Gateway 生效验证

## 目标

验证以下路由是否正常工作：
- `local.orders.com/doc` - Swagger UI 文档
- `local.orders.com/orders` - Orders API
- `local.orders.com/metrics` - Prometheus Metrics

## 前置条件

1. Traefik 已部署
2. Ingress 已配置
3. API 服务正在运行

## 设置步骤

### 步骤 1: 配置 hosts 文件

**Windows (需要管理员权限):**

```powershell
# 以管理员身份运行 PowerShell
Add-Content -Path "$env:SystemRoot\System32\drivers\etc\hosts" -Value "127.0.0.1 local.orders.com"
```

**或手动编辑:**
1. 打开 `C:\Windows\System32\drivers\etc\hosts`
2. 添加一行：`127.0.0.1 local.orders.com`
3. 保存文件

### 步骤 2: 设置端口转发

```powershell
# 转发 Traefik Service 到本地 80 端口
kubectl port-forward svc/traefik 80:80 -n traefik
```

### 步骤 3: 重新构建镜像（如果修改了代码）

```powershell
# 构建新镜像
docker build -t api:v1 .

# 加载到 kind
kind load docker-image api:v1 --name orders

# 重启 deployment
kubectl rollout restart deployment/api
```

### 步骤 4: 验证路由

```powershell
# 测试 /doc (Swagger UI)
curl http://local.orders.com/doc

# 测试 /orders
curl http://local.orders.com/orders

# 测试 /metrics
curl http://local.orders.com/metrics
```

## 验证清单

- [ ] hosts 文件已配置 `127.0.0.1 local.orders.com`
- [ ] 端口转发已启动 `kubectl port-forward svc/traefik 80:80 -n traefik`
- [ ] Traefik Pod 正在运行
- [ ] API Pod 正在运行
- [ ] Ingress 已创建
- [ ] `/doc` 可以访问（Swagger UI）
- [ ] `/orders` 可以访问（返回订单列表）
- [ ] `/metrics` 可以访问（返回 Prometheus metrics）

## 故障排除

### 无法解析 local.orders.com
- 检查 hosts 文件是否正确配置
- 确保以管理员权限编辑 hosts 文件
- 刷新 DNS 缓存：`ipconfig /flushdns`

### 连接被拒绝
- 检查端口转发是否运行：`kubectl port-forward svc/traefik 80:80 -n traefik`
- 检查 Traefik Service 状态：`kubectl get svc -n traefik`
- 检查 API Pod 状态：`kubectl get pods -l app=api`

### 404 Not Found
- 检查 Ingress 配置：`kubectl describe ingress api-ingress`
- 检查 API 路由是否正确注册
- 查看 Traefik 日志：`kubectl logs -n traefik -l app=traefik`

