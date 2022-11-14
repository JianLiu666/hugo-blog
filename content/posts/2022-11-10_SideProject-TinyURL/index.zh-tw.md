---
weight: 1
title: "Side Project: URL Shortening service"
date: 2022-11-10T00:00:00+08:00
lastmod: 2022-11-10T00:00:00+08:00
draft: true
author: "Jian"
authorLink: "https://JianLiu666.github.io"
description: "Create a shorter aliases for original URLs."
images: []
resources:
- name: "featured-image"
  src: "featured-image.jpg"

tags: ["Golang", "Side Project", "System Design", "TinyURL"]
categories: []

lightgallery: true

toc:
  auto: false
---

<!--more-->

前陣子在準備 System Design 時一直看到經典的短網址設計問題，直到近期比較有空決定自己實作一遍，同時把過程中遇到的重點記錄下來。

專案目標：

- 實現一個類似於 TinyURL 的短網址服務
- 練習概念驗證 (Proof of Concepts, POC)

---

## 短網址的目的？

1. 確保網址長度能夠在任何平台/瀏覽器上正常發送
2. 將原始網址替換成有識別度的別名
3. 提高網址轉換成 QRCode 時的辨識準確度

---

## 短網址的運作原理

首先，我們只針對短網址服務的核心業務流程做分析：

{{< mermaid >}}
sequenceDiagram
  participant ClientB
  participant ClientA
  participant TinyURL
  participant Resource

  autonumber
  ClientA ->> TinyURL: 申請短網址
  TinyURL ->> TinyURL: 驗證請求合法性
  TinyURL ->> ClientA: 返回短網址
  ClientA ->> ClientB: somehow, 總之 ClientB 知道了
  ClientB ->> TinyURL: 點擊短網址訪問資源
  TinyURL ->> ClientB: 返回原始網址與狀態碼 3XX 重新導向(*)
  Note over TinyURL: Response Status Code: 301 or 302
  ClientB ->> Resource: 訪問資源實際位置
{{< /mermaid >}}

從業務流程中能發想的問題點 (Functional Requirements)：

- 短網址驗證的注意事項
- 短網址有效期限的設計考量
- 重新導向的設計考量

從系統層面延伸的問題發想 (Non-Functional Requirements)：

- 服務的負載瓶頸？
- 短網址演算法的選擇？
- 業務場景中的資料讀寫比例？
- 服務監控指標的設計考量

---

## 預估系統負載

確定好核心業務後，下一步開始針對業務場景提出負載預估，每次看到大神等級的人都能逐一分析出不同面向的成本預估，而我做起來就像在雲開發 🫥

總之，接著開始吧

### 1. 使用場景

{{< echarts >}}
{
  "title": {
    "text": "短網址服務月流量統計",
    "subtext": "資料參考: Semrush",
    "sublink": "https://www.semrush.com/",
    "top": "2%",
    "left": "center"
  },
  "tooltip": {
    "trigger": "axis"
  },
  "legend": {
    "data": ["tinyurl.com", "cutt.ly", "bitly.com", "shorturl.at", "rb.gy"],
    "top": "14%"
  },
  "grid": {
    "left": "5%",
    "right": "5%",
    "bottom": "5%",
    "top": "24%",
    "containLabel": true
  },
  "xAxis": {
    "type": "category",
    "boundaryGap": true,
    "data": ["Aug,2022", "Sep,2022", "Oct,2022"]
  },
  "yAxis": {
    "name": "單位(Million)"
  },
  "series": [
    {
      "name": "tinyurl.com",
      "type": "bar",
      "data": [132.2, 108.7, 91.2]
    },
    {
      "name": "cutt.ly",
      "type": "bar",
      "data": [74.6, 62.2, 51.2]
    },
    {
      "name": "bitly.com",
      "type": "bar",
      "data": [23.1, 24.5, 25.4]
    },
    {
      "name": "shorturl.at",
      "type": "bar",
      "data": [7.1, 6.8, 5.2]
    },
    {
      "name": "rb.gy",
      "type": "bar",
      "data": [7.4, 5.1, 5.3]
    }
  ]
}
{{< /echarts >}}

從上圖來看，相同性質的產品中以 `tinyurl.com` 的 1 億次月流量穩坐龍頭

我們假設短網址的讀寫比例為 100 : 1，換句話說每 1 條短網址平均會有 100 次的點擊量，因此以 `tinyurl.com` 而言，可以先整理出來的基本資訊有：

- 每個月大約會產生 100 萬筆短網址，以及後續的 1 億次的短網址跳轉請求
- 前者的 RPS (Requests Per Second) 約 1M URLs / (30 days * 24 hours * 3,600 seconds) ~= `0.4 URLs/s`
- 同理，後者的 RPS 約 `40 URLs/s`

峰值的計算參考八二法則，即一天中 80% 的流量會集中在 20% 的時間裡：

- 產生短網址的請求峰值約為 (1M URLs / 30 days * 80%) / (86,400 seconds * 20%) ~= `1.5 URLs/s`
- 同理，跳轉請求的峰值約為 `150 URLs/s`

### 2. 網路傳輸

實際在 `tinyurl.com` 使用 Chrome DevTools 分析可以得到：

- 每產生一筆短網址的封包傳輸量約為 1k bytes
- 每次跳轉請求封包傳輸量約為 500 bytes

沿用一開始計算出的流量可以得到：

- 產生短網址的網路傳輸量為 0.4 URLs * 1k bytes ~= `400 B/s`
  - 峰值約為 1.5 URLs * 1k bytes ~= `1.5 KB/s`
- 短網址跳轉為 40 URLs * 500 bytes ~= `20 KB/s`
  - 峰值約為 `75 KB/s`

### 3. 資料儲存

我們以 response payload 的封包大小 600 bytes 為假設：

- 每一年總共會產生 1M URLs * 12 months ~= `12M URLs/year` 筆短網址
- 每一年資料儲存量為 12M URLs * 600 bytes ~= `7.2 GB`

### 4. 資料快取

為了加快服務的響應速度，我們通常會將常用的資料保留在 server 上，在這裡就是短網址，一樣以八二法則為例，倘若我們希望保留近三個月的熱門網址查詢記錄，所需要的記憶體大小為：

- 1M URLs * 3 months * 600 bytes * 20% ~= `360 MB`

<br>

有了上述這些參考資料後，在後續開發與測試上就能以更精確的數字帶入使用

---

## 產品原型規劃

prototype 的相關開發文件請直接瀏覽我的 [GitHub Repo](https://github.com/JianLiu666/TinyURL)，包含：

- 核心功能技術文件、DB Schema、部署與啟動方式、整合測試、etc.

---

## 實驗結果

機器規格如下：

- 機器型號：MacBook Pro 14" 2021
- CPU：Apple M1 Pro
- RAM：32 GB

所有服務皆透過 Docker-compose 啟動，主要服務統一以下設定：
  - e.g. TinyURL server、MySQL、Redis
  - 詳細配置請見 [deployment](https://github.com/JianLiu666/TinyURL/tree/main/deployment)

```yaml
services:
  {service}:
    ...
    ...
    deploy:
      resources:
        limits:
          cpus: "2"
          memory: 4G
        reservations:
          memory: 2G
```

### Locust

{{< image src="./benchmark-locust.png" caption="Benchmark with 1000 users & 10 minutes" >}}

上圖是使用 `locust.io` 這套 Python 的壓測工具實測出來的結果，以 100 : 1 的讀寫請求模擬使用場景，RPS 平均落在 ~1460 左右

### Grafana

#### Server

{{< image src="./benchmark-server.png" caption="Grafana with TinyURL server metrics" >}}

同一時間 Prometheus 對 Server 採集到的指標

#### MySQL

{{< image src="./benchmark-mysql-1.png" caption="Grafana with MySQL metrics" >}}
{{< image src="./benchmark-mysql-2.png" caption="Grafana with MySQL metrics" >}}

僅擷取 MySQL 的部分 metrics，可以發現 server 對 MySQL 的請求數並不高，QPS 僅有 40~50

#### Redis

{{< image src="./benchmark-redis.png" caption="Grafana with Redis metrics" >}}

原因在於大部分的查詢都能在 Redis 處理完畢

<br>

更多的測試模擬可以從 [python script](https://github.com/JianLiu666/TinyURL/blob/main/benchmark/locustfile.py) 中找到，這裡就不逐一展開  

有興趣的朋友可以下載我的 [repo](https://github.com/JianLiu666/TinyURL) 後自行使用，過程中若有遇到問題也歡迎提供給我一起研究

---

## 技術筆記

### MurmurHash3

關於 `加密雜湊算法` 與 `非加密雜湊算法` 之間的原理，我想留到下次在做一個完整的筆記

---

## 後記

這次實作讓我釐清了很多當時在看 System Design 時不清楚的細節，但也因為這次主要是為了練習 POC，因此在實作過程中省略了不少細節

- e.g. 跨資料庫時的一致性保證、災難復原 & 故障轉移機制、限流機制、etc.

---

## References

- [Semrush](https://www.semrush.com/)
- [短 URL 系统是怎么设计的？](https://www.zhihu.com/question/29270034)