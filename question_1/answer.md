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
- **SNS 通知整合**：支援不同環境的告警通知配置

## SNS 通知配置

### 環境差異

各環境的 SNS 配置和告警閾值設計不同：

#### 開發環境 (Dev)

- **錯誤閾值**: 3 次錯誤觸發告警
- **警告閾值**: 5 次警告觸發告警
- **日誌保留**: 7 天
- **SNS 用途**: 開發團隊內部通知，通常配置為 Slack 或開發郵件群組
- **告警頻率**: 較敏感，便於早期發現問題

#### UAT 環境 (UAT)

- **錯誤閾值**: 2 次錯誤觸發告警（最敏感）
- **警告閾值**: 4 次警告觸發告警
- **日誌保留**: 14 天
- **SNS 用途**: 測試團隊和 QA 通知，確保測試階段問題及時發現
- **告警頻率**: 最敏感設置，確保測試品質

#### 正式環境 (Prod)

- **錯誤閾值**: 5 次錯誤觸發告警（較保守）
- **警告閾值**: 10 次警告觸發告警
- **日誌保留**: 30 天（法規遵循）
- **SNS 用途**: 營運團隊、監控中心、管理層通知
- **告警頻率**: 較保守設置，避免過多誤報

### SNS 主題配置建議

```bash
# 為各環境建立 SNS 主題
aws sns create-topic --name docker-logs-dev-alerts
aws sns create-topic --name docker-logs-uat-alerts
aws sns create-topic --name docker-logs-prod-alerts

# 訂閱不同的通知端點
aws sns subscribe --topic-arn arn:aws:sns:us-west-2:ACCOUNT:docker-logs-dev-alerts \
  --protocol email --notification-endpoint dev-team@company.com

aws sns subscribe --topic-arn arn:aws:sns:us-west-2:ACCOUNT:docker-logs-prod-alerts \
  --protocol email --notification-endpoint ops-team@company.com
```

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

#### 正式環境

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
