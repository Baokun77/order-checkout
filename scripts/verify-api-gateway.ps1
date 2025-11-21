# API Gateway 验证脚本
# 验证 local.orders.com 的路由是否正常工作

Write-Host "=== API Gateway 验证 ===" -ForegroundColor Cyan

# 检查 Traefik 状态
Write-Host "`n[1/5] 检查 Traefik..." -ForegroundColor Yellow
$traefikPods = kubectl get pods -n traefik -o json | ConvertFrom-Json
if ($traefikPods.items.Count -gt 0) {
    $pod = $traefikPods.items[0]
    Write-Host "✓ Traefik Pod: $($pod.metadata.name) - Status: $($pod.status.phase)" -ForegroundColor Green
} else {
    Write-Host "✗ Traefik Pod 未找到" -ForegroundColor Red
    exit 1
}

# 检查 Ingress
Write-Host "`n[2/5] 检查 Ingress..." -ForegroundColor Yellow
$ingress = kubectl get ingress api-ingress -o json | ConvertFrom-Json
if ($ingress) {
    Write-Host "✓ Ingress: $($ingress.metadata.name)" -ForegroundColor Green
    Write-Host "  Host: $($ingress.spec.rules[0].host)" -ForegroundColor Gray
} else {
    Write-Host "✗ Ingress 未找到" -ForegroundColor Red
    exit 1
}

# 检查 API Service
Write-Host "`n[3/5] 检查 API Service..." -ForegroundColor Yellow
$apiSvc = kubectl get svc api -o json | ConvertFrom-Json
if ($apiSvc) {
    Write-Host "✓ API Service: $($apiSvc.metadata.name)" -ForegroundColor Green
    Write-Host "  Port: $($apiSvc.spec.ports[0].port)" -ForegroundColor Gray
} else {
    Write-Host "✗ API Service 未找到" -ForegroundColor Red
    exit 1
}

# 检查 hosts 文件
Write-Host "`n[4/5] 检查 hosts 文件..." -ForegroundColor Yellow
$hostsPath = "$env:SystemRoot\System32\drivers\etc\hosts"
$hostsContent = Get-Content $hostsPath -ErrorAction SilentlyContinue
if ($hostsContent -match "local\.orders\.com") {
    Write-Host "✓ hosts 文件已配置 local.orders.com" -ForegroundColor Green
} else {
    Write-Host "⚠ hosts 文件未配置 local.orders.com" -ForegroundColor Yellow
    Write-Host "  请添加: 127.0.0.1 local.orders.com" -ForegroundColor White
}

# 检查 Traefik Service 端口
Write-Host "`n[5/5] 检查 Traefik Service..." -ForegroundColor Yellow
$traefikSvc = kubectl get svc traefik -n traefik -o json | ConvertFrom-Json
if ($traefikSvc) {
    $nodePort = $traefikSvc.spec.ports | Where-Object { $_.name -eq "web" } | Select-Object -ExpandProperty nodePort
    Write-Host "✓ Traefik Service NodePort: $nodePort" -ForegroundColor Green
    Write-Host "  访问地址: http://localhost:$nodePort" -ForegroundColor Gray
} else {
    Write-Host "✗ Traefik Service 未找到" -ForegroundColor Red
}

# 测试路由
Write-Host "`n=== 测试路由 ===" -ForegroundColor Cyan

$baseUrl = "http://local.orders.com"
$traefikPort = if ($traefikSvc) { 
    $traefikSvc.spec.ports | Where-Object { $_.name -eq "web" } | Select-Object -ExpandProperty nodePort 
} else { 
    30080 
}

$routes = @(
    @{ Path = "/doc"; Name = "Swagger UI" },
    @{ Path = "/orders"; Name = "Orders API" },
    @{ Path = "/metrics"; Name = "Prometheus Metrics" }
)

foreach ($route in $routes) {
    Write-Host "`n测试: $($route.Name) ($($route.Path))" -ForegroundColor Yellow
    try {
        $url = "$baseUrl$($route.Path)"
        $response = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 5 -ErrorAction Stop
        Write-Host "  ✓ HTTP $($response.StatusCode) - 成功" -ForegroundColor Green
    } catch {
        Write-Host "  ✗ 失败: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "  提示: 确保已配置 hosts 文件并设置端口转发" -ForegroundColor Gray
        Write-Host "  端口转发: kubectl port-forward svc/traefik 80:80 -n traefik" -ForegroundColor Gray
    }
}

Write-Host "`n=== 验证完成 ===" -ForegroundColor Cyan
Write-Host "`n如果测试失败，请确保:" -ForegroundColor Yellow
Write-Host "1. hosts 文件已配置: 127.0.0.1 local.orders.com" -ForegroundColor White
Write-Host "2. 端口转发已启动: kubectl port-forward svc/traefik 80:80 -n traefik" -ForegroundColor White
Write-Host "3. API Pod 正在运行: kubectl get pods -l app=api" -ForegroundColor White

