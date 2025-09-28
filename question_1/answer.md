# Docker Log Collection - 部署步驟

## 前提條件

- 已配置適當憑證的 AWS CLI
- 已安裝 Terragrunt (v0.45+)
- 已安裝 Terraform (v1.0+)

## 架構概述

此基礎設施設置：

- 用於 Docker Log 的 CloudWatch Log Group 和 Log Stream
- ECS 任務執行和日誌記錄的 IAM Role and Policy
- 用於日誌視覺化的 CloudWatch DashBoard
- 用於錯誤監控的 CloudWatch Alarm
- 預設使用 default VPC

## 部署步驟

### 1. Init 遠端狀態

```bash
# 導航到 live 目錄
cd question_1/live

# 建立 S3 儲存桶用於狀態管理（一次性設置）
aws s3 mb s3://terragrunt-state-$(aws sts get-caller-identity --query Account --output text)-us-west-2
```

### 2. 按環境部署

#### 開發環境

```bash
cd dev
terragrunt run --all plan    # 檢視變更
terragrunt run --all apply   # 部署基礎設施
```

#### UAT 環境

```bash
cd ../uat
terragrunt run --all plan
terragrunt run --all apply
```

#### 生產環境

```bash
cd ../prod
terragrunt run --all plan
terragrunt run --all apply
```

### 3. 部署特定元件

```bash
# 僅部署 CloudWatch 資源
terragrunt apply --terragrunt-working-dir cloudwatch

# 僅部署應用程式資源（需要先部署 CloudWatch）
terragrunt apply --terragrunt-working-dir app
```

## 配置

- **AWS 區域**：us-west-2（在 `root.hcl` 中配置）
- **狀態後端**：S3
- **日誌保留期**：7 天（Dev/Uat），30 天（Prod）
- **依賴關係**：應用程式模組依賴於 CloudWatch 模組

## 清理

```bash
# 銷毀特定環境
cd <環境名稱>
terragrunt run --all destroy

# 或銷毀特定元件
terragrunt destroy --terragrunt-working-dir <元件名稱>
```

## 驗證

部署後，驗證以下內容：

1. CloudWatch Log Group 已建立
2. IAM Role 具有適當權限
3. CloudWatch DashBoard 顯示日誌指標
4. CloudWatch Alarm 已配置並啟動
