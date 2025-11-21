# API Gateway 路由测试脚本

Write-Host "=== API Gateway 路由测试 ===" -ForegroundColor Cyan

# 检查 hosts 文件
Write-Host "`n[1] 检查 hosts 文件..." -ForegroundColor Yellow
$hostsPath = "$env:SystemRoot\System32\drivers\etc\hosts"
$hostsContent = Get-Content $hostsPath -ErrorAction SilentlyContinue
if ($hostsContent -match "local\.orders\.com") {
    Write-Host "✓ hosts 文件已配置" -ForegroundColor Green
} else {
    Write-Host "✗ hosts 文件未配置" -ForegroundColor Red
    Write-Host "请以管理员身份运行:" -ForegroundColor Yellow
    Write-Host 'Add-Content -Path "$env:SystemRoot\System32\drivers\etc\hosts" -Value "127.0.0.1 local.orders.com"' -ForegroundColor White
    exit 1
}

# 检查端口转发
Write-Host "`n[2] 检查端口转发..." -ForegroundColor Yellow
$portForward = Get-Process -Name kubectl -ErrorAction SilentlyContinue | Where-Object { $_.CommandLine -match "port-forward.*traefik" }
if ($portForward) {
    Write-Host "✓ 端口转发正在运行" -ForegroundColor Green
} else {
    Write-Host "⚠ 端口转发未检测到" -ForegroundColor Yellow
    Write-Host "请运行: kubectl port-forward svc/traefik 80:80 -n traefik" -ForegroundColor White
}

# 测试路由
Write-Host "`n[3] 测试路由..." -ForegroundColor Yellow

$routes = @(
    @{ Path = "/doc"; Name = "Swagger UI" },
    @{ Path = "/orders"; Name = "Orders API" },
    @{ Path = "/metrics"; Name = "Prometheus Metrics" }
)

foreach ($route in $routes) {
    Write-Host "`n测试: $($route.Name) ($($route.Path))" -ForegroundColor Cyan
    try {
        $url = "http://local.orders.com$($route.Path)"
        $response = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 5 -ErrorAction Stop
        Write-Host "  ✓ HTTP $($response.StatusCode) - 成功" -ForegroundColor Green
        
        if ($route.Path -eq "/metrics") {
            Write-Host "  Metrics 内容预览 (前 200 字符):" -ForegroundColor Gray
            $preview = $response.Content.Substring(0, [Math]::Min(200, $response.Content.Length))
            Write-Host "  $preview..." -ForegroundColor DarkGray
        }
    } catch {
        Write-Host "  ✗ 失败: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "`n=== 测试完成 ===" -ForegroundColor Cyan

