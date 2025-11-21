# Age 加密快速开始

## ✅ 已完成的配置

- [x] `.sops.yaml` - 准备使用 Age（待填入公钥）
- [x] `.github/workflows/deploy.yaml` - 已更新为使用 Age 解密
- [x] `.gitignore` - 已排除 `age-key.txt`（私钥）
- [x] `scripts/setup-age-encryption.ps1` - 自动设置脚本

## 🚀 快速开始（3 步）

### 步骤 1: 安装 SOPS

**选项 A: 使用 Chocolatey（推荐）**
```powershell
# 以管理员身份运行
choco install sops -y
```

**选项 B: 使用 Scoop**
```powershell
scoop install sops
```

**选项 C: 手动下载**
- 访问 https://github.com/mozilla/sops/releases
- 下载 Windows 版本
- 添加到 PATH

**验证安装:**
```powershell
sops --version
```

### 步骤 2: 运行设置脚本

```powershell
.\scripts\setup-age-encryption.ps1
```

这个脚本会：
- 检查 SOPS 是否安装
- 生成 Age 密钥对（`age-key.txt`）
- 自动更新 `.sops.yaml` 使用公钥
- 提供下一步说明

### 步骤 3: 加密 Secret

```powershell
# 1. 编辑 secret，设置真实密码
notepad k8s/api/secret.enc.yaml

# 2. 设置环境变量（指向私钥文件）
$env:SOPS_AGE_KEY_FILE="age-key.txt"

# 3. 加密文件
sops -e -i k8s/api/secret.enc.yaml

# 4. 验证加密（应该看到 sops: 元数据）
cat k8s/api/secret.enc.yaml
```

## 🔐 配置 GitHub Secrets

1. 打开 GitHub 仓库：**Settings → Secrets and variables → Actions**
2. 点击 **New repository secret**
3. 添加：
   - **Name**: `SOPS_AGE_KEY`
   - **Value**: 复制 `age-key.txt` 的**完整内容**（包括两行：`# created: ...` 和 `AGE-SECRET-KEY-1...`）

## 📤 提交并推送

```powershell
git add .sops.yaml
git add k8s/api/secret.enc.yaml
git add .github/workflows/deploy.yaml
git add .gitignore
git commit -m "Add SOPS + Age encryption for secrets"
git push
```

## ✅ 验证

### 本地验证
```powershell
# 测试解密
$env:SOPS_AGE_KEY_FILE="age-key.txt"
sops -d k8s/api/secret.enc.yaml

# 应用到集群
kubectl apply -f <(sops -d k8s/api/secret.enc.yaml)

# 验证
kubectl get secret api-secret
kubectl exec deployment/api -- env | grep DATABASE_PASSWORD
```

### CI/CD 验证
1. 推送代码后，查看 GitHub Actions
2. 确认 "Decrypt secrets with SOPS" 步骤成功
3. 确认 secret 被正确部署

## ⚠️ 重要提示

- **不要提交 `age-key.txt`** - 这是私钥，已配置在 `.gitignore` 中
- **加密后的文件可以安全提交** - `secret.enc.yaml` 已加密
- **GitHub Secret 存储私钥** - 用于 CI/CD 解密

## 🐛 故障排除

### SOPS 命令未找到
- 确保 SOPS 已安装并在 PATH 中
- 重启 PowerShell 终端
- 验证：`sops --version`

### 解密失败
- 检查 `SOPS_AGE_KEY_FILE` 环境变量是否正确
- 确认 `age-key.txt` 文件存在
- 验证 `.sops.yaml` 中的公钥正确

### GitHub Actions 解密失败
- 检查 GitHub Secret `SOPS_AGE_KEY` 是否正确设置
- 确认私钥内容完整（包括两行）

