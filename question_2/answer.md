# HCM

# Docker Container Log 收集方案（Linux 系統）

題目：收集 Linux 系統中 Docker 容器日誌，提供兩種情境的建置方案：

1. 應用程式已有實體檔案
2. Log 僅輸出至 stdout/stderr（透過 `docker logs` 取得）

---

## 方案一：收集應用程式已存在的日誌檔案

### 方案概要

如果容器內的應用程式已經將日誌寫入檔案（例如 `/app/logs/app.log`），最簡單方式是透過 **Volume 映射**，將容器內日誌目錄映射到主機上，使主機可以直接存取並收集日誌。

### 建置步驟

1. 建立主機日誌目錄

```bash
sudo mkdir -p /var/log/myapp
sudo chmod 755 /var/log/myapp
```

1. 執行容器並掛載日誌目錄

```bash
docker run -d \
  --name myapp \
  -v /var/log/myapp:/app/logs \
  myapp:latest
```

1. 驗證日誌

```bash
tail -f /var/log/myapp/app.log
```

1. Log Rotation（Optional）

在 `/etc/logrotate.d/myapp` 添加：

```bash
/var/log/myapp/*.log {
    daily
    rotate 7
    compress
    missingok
    notifempty
    copytruncate
}
```

### 結果

容器內的日誌會持續寫入 `/var/log/myapp/`，可供其他收集工具（如 ElasticSearch）使用。

---

## 方案二：收集 stdout/stderr 日誌（透過 `docker logs`）

### 方案概要

如果應用程式僅輸出日誌到標準輸出或錯誤，Docker 自動捕獲 stdout/stderr，透過 `docker logs` 可以查看。

若需要將這些日誌保存為實體檔案，可將 `docker logs -f` 輸出導向檔案，並使用 systemd 進行自動化管理。

### 建置步驟

1. 將日誌導出到檔案

```bash
docker logs -f myapp >> /var/log/docker/myapp.log 2>&1 &
```

1. 建立 systemd service and unit，自動持續收集

建立 `/etc/systemd/system/docker-logs-myapp.service`：

```bash
[Unit]
Description=Collect logs for Docker container myapp
After=docker.service
Requires=docker.service

[Service]
ExecStart=/usr/bin/docker logs -f myapp >> /var/log/docker/myapp.log 2>&1
Restart=always

[Install]
WantedBy=multi-user.target
```

啟用服務：

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now docker-logs-myapp
```

1. 驗證日誌

```bash
tail -f /var/log/docker/myapp.log
```

1. Log rotation （Optional）

在 `/etc/logrotate.d/docker-stdout` 添加：

```bash
/var/log/docker/*.log {
    daily
    rotate 7
    compress
    missingok
    notifempty
    copytruncate
}
```

- 需注意的是，由於 `docker logs >>` 不會隨著 `logrotate` 更換指向的檔案，因此使用`copytruncate` 保證 `docker logs -f` 持續寫入同一檔案，不會因輪替中斷。

### 注意事項

- Systemd Log Unit 需與容器名稱（Container name）綁定，容器必須已存在才能啟動。
- 如果容器重啟，systemd 會自動重啟收集過程。
- 若需要自動處理大量動態容器，建議使用 **Docker Loggin Drivers**（如 `awslogs` 、`Fluent Bit`、`Filebeat`）。

---

## Log rotation 的目的與原理

### 目的

- 防止日誌檔案無限增長耗盡磁碟空間。
- 保持檔案大小可管理，提高搜尋與備份效率。
- 避免系統服務因磁碟滿而中斷。

### 原理

1. 將目前日誌檔案複製或重新命名（如 `myapp.log` → `myapp.log.1`）。
2. 建立新的空檔案或使用 `copytruncate` 清空原檔。
3. 壓縮或刪除舊日誌，保留最近 N 份。
4. 日誌繼續寫入新的檔案。

---

## 小結

- **方案一（已有實體檔案）**：透過 Volume 映射將容器日誌直接存到主機目錄。
- **方案二（stdout/stderr）**：使用 `docker logs -f` 導出，並透過 systemd 自動管理，搭配 logrotate 保持檔案大小。
- 若容器動態生成或大量容器建議使用 **Docker Logging Drivers** 或 **Logging Agents**，以避免手動管理 systemd unit。
