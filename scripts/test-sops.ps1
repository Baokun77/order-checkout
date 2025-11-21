# SOPS + KMS 测试脚本
# 用于验证加密/解密流程

Write-Host "=== SOPS + KMS 测试脚本 ===" -ForegroundColor Cyan

# 检查 SOPS 是否安装
Write-Host "`n1. 检查 SOPS 安装..." -ForegroundColor Yellow
try {
    $sopsVersion = sops --version
    Write-Host "✓ SOPS 已安装: $sopsVersion" -ForegroundColor Green
} catch {
    Write-Host "✗ SOPS 未安装，请先安装 SOPS" -ForegroundColor Red
    Write-Host "  安装方法: choco install sops 或 scoop install sops" -ForegroundColor Yellow
    exit 1
}

# 检查 AWS 凭证
Write-Host "`n2. 检查 AWS 凭证..." -ForegroundColor Yellow
if ($env:AWS_ACCESS_KEY_ID -and $env:AWS_SECRET_ACCESS_KEY) {
    Write-Host "✓ AWS 凭证已设置" -ForegroundColor Green
} else {
    Write-Host "⚠ AWS 凭证未设置（环境变量）" -ForegroundColor Yellow
    Write-Host "  请设置: AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_REGION" -ForegroundColor Yellow
}

# 检查 .sops.yaml
Write-Host "`n3. 检查 .sops.yaml 配置..." -ForegroundColor Yellow
if (Test-Path ".sops.yaml") {
    Write-Host "✓ .sops.yaml 存在" -ForegroundColor Green
    $sopsConfig = Get-Content ".sops.yaml" -Raw
    if ($sopsConfig -match "kms:") {
        Write-Host "✓ 包含 KMS 配置" -ForegroundColor Green
    } else {
        Write-Host "⚠ 未找到 KMS 配置，请更新 .sops.yaml" -ForegroundColor Yellow
    }
} else {
    Write-Host "✗ .sops.yaml 不存在" -ForegroundColor Red
    exit 1
}

# 检查 secret.enc.yaml
Write-Host "`n4. 检查 secret.enc.yaml..." -ForegroundColor Yellow
$secretFile = "k8s/api/secret.enc.yaml"
if (Test-Path $secretFile) {
    Write-Host "✓ $secretFile 存在" -ForegroundColor Green
    
    # 检查是否已加密
    $content = Get-Content $secretFile -Raw
    if ($content -match "sops:") {
        Write-Host "✓ 文件已加密（包含 sops 元数据）" -ForegroundColor Green
    } else {
        Write-Host "⚠ 文件未加密（不包含 sops 元数据）" -ForegroundColor Yellow
        Write-Host "  请使用: sops -e -i $secretFile" -ForegroundColor Yellow
    }
} else {
    Write-Host "✗ $secretFile 不存在" -ForegroundColor Red
    exit 1
}

# 测试解密
Write-Host "`n5. 测试解密..." -ForegroundColor Yellow
try {
    $decrypted = sops -d $secretFile 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ 解密成功" -ForegroundColor Green
        Write-Host "`n解密后的内容预览:" -ForegroundColor Cyan
        $decrypted | Select-Object -First 10
    } else {
        Write-Host "✗ 解密失败: $decrypted" -ForegroundColor Red
    }
} catch {
    Write-Host "✗ 解密失败: $_" -ForegroundColor Red
}

# 检查 deployment 配置
Write-Host "`n6. 检查 deployment 配置..." -ForegroundColor Yellow
$deploymentFile = "k8s/api/deployment.yaml"
if (Test-Path $deploymentFile) {
    $deploymentContent = Get-Content $deploymentFile -Raw
    if ($deploymentContent -match "secretRef") {
        Write-Host "✓ deployment 已配置 secretRef" -ForegroundColor Green
    } else {
        Write-Host "⚠ deployment 未配置 secretRef" -ForegroundColor Yellow
    }
} else {
    Write-Host "✗ $deploymentFile 不存在" -ForegroundColor Red
}

# 检查 kubectl 和集群
Write-Host "`n7. 检查 Kubernetes 集群..." -ForegroundColor Yellow
try {
    $nodes = kubectl get nodes 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Kubernetes 集群连接正常" -ForegroundColor Green
    } else {
        Write-Host "⚠ 无法连接到 Kubernetes 集群" -ForegroundColor Yellow
    }
} catch {
    Write-Host "⚠ kubectl 未安装或集群未运行" -ForegroundColor Yellow
}

Write-Host "`n=== 测试完成 ===" -ForegroundColor Cyan
Write-Host "`n下一步:" -ForegroundColor Yellow
Write-Host "1. 如果 secret.enc.yaml 未加密，运行: sops -e -i k8s/api/secret.enc.yaml" -ForegroundColor White
Write-Host "2. 本地测试: kubectl apply -f <(sops -d k8s/api/secret.enc.yaml)" -ForegroundColor White
Write-Host "3. 验证: kubectl get secret api-secret" -ForegroundColor White

