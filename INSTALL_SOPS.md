# 安装 SOPS 和 Age（Windows）

## 方法 1: 使用 Chocolatey（推荐）

### 安装 Chocolatey（如果还没有）
以管理员身份运行 PowerShell：
```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
```

### 安装 SOPS
```powershell
choco install sops -y
```

### 安装 Age（可选，SOPS 3.8+ 内置支持）
```powershell
choco install age -y
```

## 方法 2: 使用 Scoop

### 安装 Scoop（如果还没有）
```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
irm get.scoop.sh | iex
```

### 安装 SOPS
```powershell
scoop install sops
```

### 安装 Age
```powershell
scoop install age
```

## 方法 3: 手动下载

1. 访问 [SOPS Releases](https://github.com/mozilla/sops/releases)
2. 下载 Windows 版本（sops-v3.x.x.windows.exe）
3. 重命名为 `sops.exe`
4. 放到 PATH 目录或添加到 PATH

## 验证安装

```powershell
sops --version
age --version  # 如果单独安装了 age
```

## 下一步

安装完成后，运行：
```powershell
.\scripts\setup-age-encryption.ps1
```

