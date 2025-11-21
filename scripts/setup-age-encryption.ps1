# Age 加密设置脚本
# 用于设置 SOPS + Age 加密

Write-Host "=== SOPS + Age 加密设置 ===" -ForegroundColor Cyan

# 步骤 1: 检查并安装 SOPS
Write-Host "`n[1/5] 检查 SOPS..." -ForegroundColor Yellow
try {
    $sopsVersion = sops --version 2>&1
    Write-Host "✓ SOPS 已安装: $sopsVersion" -ForegroundColor Green
} catch {
    Write-Host "✗ SOPS 未安装" -ForegroundColor Red
    Write-Host "`n请安装 SOPS:" -ForegroundColor Yellow
    Write-Host "1. 使用 Chocolatey: choco install sops -y" -ForegroundColor White
    Write-Host "2. 使用 Scoop: scoop install sops" -ForegroundColor White
    Write-Host "3. 手动下载: https://github.com/mozilla/sops/releases" -ForegroundColor White
    Write-Host "`n安装后请重新运行此脚本" -ForegroundColor Yellow
    exit 1
}

# 步骤 2: 检查并安装 Age
Write-Host "`n[2/5] 检查 Age..." -ForegroundColor Yellow
try {
    $ageVersion = age --version 2>&1
    Write-Host "✓ Age 已安装: $ageVersion" -ForegroundColor Green
} catch {
    Write-Host "⚠ Age 未安装（SOPS 3.8+ 内置 Age 支持）" -ForegroundColor Yellow
    Write-Host "  如果解密失败，请安装: choco install age -y" -ForegroundColor White
}

# 步骤 3: 生成 Age 密钥对
Write-Host "`n[3/5] 生成 Age 密钥对..." -ForegroundColor Yellow
$ageKeyFile = "age-key.txt"

if (Test-Path $ageKeyFile) {
    Write-Host "⚠ $ageKeyFile 已存在" -ForegroundColor Yellow
    $overwrite = Read-Host "是否覆盖? (y/N)"
    if ($overwrite -ne "y" -and $overwrite -ne "Y") {
        Write-Host "使用现有密钥文件" -ForegroundColor Green
    } else {
        Remove-Item $ageKeyFile -Force
        age-keygen -o $ageKeyFile
        Write-Host "✓ 新密钥对已生成" -ForegroundColor Green
    }
} else {
    age-keygen -o $ageKeyFile
    Write-Host "✓ 密钥对已生成: $ageKeyFile" -ForegroundColor Green
}

# 步骤 4: 提取公钥
Write-Host "`n[4/5] 提取公钥..." -ForegroundColor Yellow
$keyContent = Get-Content $ageKeyFile
$publicKey = $keyContent | Where-Object { $_ -match "^age1" }

if ($publicKey) {
    Write-Host "✓ 公钥已提取:" -ForegroundColor Green
    Write-Host $publicKey -ForegroundColor Gray
    
    # 更新 .sops.yaml
    Write-Host "`n[5/5] 更新 .sops.yaml..." -ForegroundColor Yellow
    $sopsConfig = Get-Content ".sops.yaml" -Raw
    
    # 检查是否已经配置了 Age
    if ($sopsConfig -match "age:\s*>-\s*age1") {
        Write-Host "⚠ .sops.yaml 已包含 Age 配置" -ForegroundColor Yellow
        $update = Read-Host "是否更新为当前公钥? (y/N)"
        if ($update -eq "y" -or $update -eq "Y") {
            $newConfig = $sopsConfig -replace "age:\s*>-\s*age1[^\s]+", "age: >-`n      $publicKey"
            $newConfig | Set-Content ".sops.yaml"
            Write-Host "✓ .sops.yaml 已更新" -ForegroundColor Green
        }
    } else {
        # 替换 KMS 配置为 Age
        $newConfig = @"
# SOPS configuration file
# This file tells SOPS how to encrypt/decrypt files

# Creation rules for different file patterns
creation_rules:
  # Rule for Kubernetes secrets
  - path_regex: k8s/.*/secret\.enc\.yaml`$
    age: >-
      $publicKey
"@
        $newConfig | Set-Content ".sops.yaml"
        Write-Host "✓ .sops.yaml 已更新为使用 Age 加密" -ForegroundColor Green
    }
    
    Write-Host "`n=== 设置完成 ===" -ForegroundColor Cyan
    Write-Host "`n下一步:" -ForegroundColor Yellow
    Write-Host "1. 编辑 k8s/api/secret.enc.yaml，设置真实密码" -ForegroundColor White
    Write-Host "2. 运行加密: sops -e -i k8s/api/secret.enc.yaml" -ForegroundColor White
    Write-Host "3. 配置 GitHub Secret:" -ForegroundColor White
    Write-Host "   - 名称: SOPS_AGE_KEY" -ForegroundColor Gray
    Write-Host "   - 值: (复制 age-key.txt 的完整内容)" -ForegroundColor Gray
    Write-Host "4. 提交加密文件: git add k8s/api/secret.enc.yaml .sops.yaml" -ForegroundColor White
    
    Write-Host "`n⚠ 重要: age-key.txt 包含私钥，不要提交到 Git！" -ForegroundColor Red
    Write-Host "   .gitignore 已配置排除 age-key.txt" -ForegroundColor Green
} else {
    Write-Host "✗ 无法从密钥文件中提取公钥" -ForegroundColor Red
    Write-Host "请检查 $ageKeyFile 文件格式" -ForegroundColor Yellow
}

