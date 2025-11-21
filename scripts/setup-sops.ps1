# SOPS + KMS 自动设置脚本
# 此脚本帮助完成 SOPS 和 KMS 的配置

Write-Host "=== SOPS + KMS 设置向导 ===" -ForegroundColor Cyan

# 步骤 1: 检查并安装 SOPS
Write-Host "`n[1/5] 检查 SOPS 安装..." -ForegroundColor Yellow
try {
    $sopsVersion = sops --version 2>&1
    Write-Host "✓ SOPS 已安装: $sopsVersion" -ForegroundColor Green
} catch {
    Write-Host "✗ SOPS 未安装" -ForegroundColor Red
    Write-Host "`n请选择安装方式:" -ForegroundColor Yellow
    Write-Host "1. Chocolatey (推荐)" -ForegroundColor White
    Write-Host "2. Scoop" -ForegroundColor White
    Write-Host "3. 手动下载" -ForegroundColor White
    Write-Host "4. 跳过（稍后手动安装）" -ForegroundColor White
    
    $choice = Read-Host "`n请输入选项 (1-4)"
    
    switch ($choice) {
        "1" {
            Write-Host "正在使用 Chocolatey 安装 SOPS..." -ForegroundColor Yellow
            choco install sops -y
        }
        "2" {
            Write-Host "正在使用 Scoop 安装 SOPS..." -ForegroundColor Yellow
            scoop install sops
        }
        "3" {
            Write-Host "请访问: https://github.com/mozilla/sops/releases" -ForegroundColor Yellow
            Write-Host "下载 Windows 版本并添加到 PATH" -ForegroundColor Yellow
        }
        "4" {
            Write-Host "跳过 SOPS 安装" -ForegroundColor Yellow
        }
        default {
            Write-Host "无效选项，跳过安装" -ForegroundColor Yellow
        }
    }
}

# 步骤 2: 检查 AWS CLI
Write-Host "`n[2/5] 检查 AWS CLI..." -ForegroundColor Yellow
try {
    $awsVersion = aws --version 2>&1
    Write-Host "✓ AWS CLI 已安装: $awsVersion" -ForegroundColor Green
} catch {
    Write-Host "⚠ AWS CLI 未安装（可选，用于本地测试）" -ForegroundColor Yellow
    Write-Host "  安装: choco install awscli" -ForegroundColor White
}

# 步骤 3: 检查 AWS 凭证
Write-Host "`n[3/5] 检查 AWS 凭证..." -ForegroundColor Yellow
$hasAwsCreds = $false

if ($env:AWS_ACCESS_KEY_ID -and $env:AWS_SECRET_ACCESS_KEY) {
    Write-Host "✓ 环境变量中已设置 AWS 凭证" -ForegroundColor Green
    $hasAwsCreds = $true
} else {
    try {
        $awsIdentity = aws sts get-caller-identity 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✓ AWS CLI 配置中已设置凭证" -ForegroundColor Green
            $hasAwsCreds = $true
        }
    } catch {
        Write-Host "⚠ 未检测到 AWS 凭证" -ForegroundColor Yellow
    }
}

if (-not $hasAwsCreds) {
    Write-Host "`n提示: 你需要设置 AWS 凭证才能使用 KMS 加密" -ForegroundColor Yellow
    Write-Host "方法 1: 设置环境变量" -ForegroundColor White
    Write-Host "  `$env:AWS_ACCESS_KEY_ID='your-key'" -ForegroundColor Gray
    Write-Host "  `$env:AWS_SECRET_ACCESS_KEY='your-secret'" -ForegroundColor Gray
    Write-Host "  `$env:AWS_REGION='us-east-1'" -ForegroundColor Gray
    Write-Host "`n方法 2: 使用 AWS CLI" -ForegroundColor White
    Write-Host "  aws configure" -ForegroundColor Gray
}

# 步骤 4: 检查 .sops.yaml
Write-Host "`n[4/5] 检查 .sops.yaml 配置..." -ForegroundColor Yellow
if (Test-Path ".sops.yaml") {
    $sopsConfig = Get-Content ".sops.yaml" -Raw
    if ($sopsConfig -match "kms:.*REGION") {
        Write-Host "⚠ .sops.yaml 包含占位符，需要更新 KMS Key ARN" -ForegroundColor Yellow
        Write-Host "`n请编辑 .sops.yaml，替换以下内容:" -ForegroundColor White
        Write-Host "  kms: 'arn:aws:kms:REGION:ACCOUNT_ID:key/KMS_KEY_ID'" -ForegroundColor Gray
        Write-Host "  为实际的 KMS Key ARN" -ForegroundColor Gray
    } elseif ($sopsConfig -match "kms:.*arn:aws") {
        Write-Host "✓ .sops.yaml 已配置 KMS Key" -ForegroundColor Green
    } else {
        Write-Host "⚠ .sops.yaml 存在但未配置 KMS" -ForegroundColor Yellow
    }
} else {
    Write-Host "✗ .sops.yaml 不存在" -ForegroundColor Red
}

# 步骤 5: 检查 secret 文件
Write-Host "`n[5/5] 检查 secret 文件..." -ForegroundColor Yellow
$secretFile = "k8s/api/secret.enc.yaml"
if (Test-Path $secretFile) {
    $content = Get-Content $secretFile -Raw
    if ($content -match "sops:") {
        Write-Host "✓ $secretFile 已加密" -ForegroundColor Green
    } else {
        Write-Host "⚠ $secretFile 未加密" -ForegroundColor Yellow
        Write-Host "`n下一步: 加密 secret 文件" -ForegroundColor Cyan
        Write-Host "1. 编辑 $secretFile，设置真实密码" -ForegroundColor White
        Write-Host "2. 运行: sops -e -i $secretFile" -ForegroundColor White
    }
} else {
    Write-Host "✗ $secretFile 不存在" -ForegroundColor Red
}

# 总结
Write-Host "`n=== 设置总结 ===" -ForegroundColor Cyan
Write-Host "`n已完成:" -ForegroundColor Green
Write-Host "  ✓ 项目结构已配置" -ForegroundColor Green
Write-Host "  ✓ Deployment 已配置 secretRef" -ForegroundColor Green
Write-Host "  ✓ GitHub Actions workflow 已配置 SOPS 解密" -ForegroundColor Green

Write-Host "`n待完成:" -ForegroundColor Yellow
Write-Host "  1. 安装 SOPS (如果未安装)" -ForegroundColor White
Write-Host "  2. 创建 AWS KMS Key" -ForegroundColor White
Write-Host "  3. 更新 .sops.yaml 中的 KMS Key ARN" -ForegroundColor White
Write-Host "  4. 设置 AWS 凭证" -ForegroundColor White
Write-Host "  5. 编辑并加密 k8s/api/secret.enc.yaml" -ForegroundColor White
$secrets = "AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_REGION"
Write-Host "  6. 配置 GitHub Secrets ($secrets)" -ForegroundColor White

Write-Host "`n详细说明请查看: SOPS_SETUP.md" -ForegroundColor Cyan

