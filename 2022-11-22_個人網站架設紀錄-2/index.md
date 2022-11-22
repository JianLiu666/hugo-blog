# 個人網站架設紀錄 #2


<!--more-->

沒想到將 gitpage 導入 SEO 的方式這麼簡單，過程中只有遇到一件最困難的事情：等待

## Google Search Console

### 目的

- 向 Google 搜尋引擎建立個人網站索引 (index)
- 追蹤個人網站瀏覽數據、外部指向來源、etc.
- 檢查 AMP、行動裝置可用性問題

### 過程紀錄

#### 資源驗證

{{< image src="./img-01-資源驗證.png" caption="hugo template: loveit" >}}

資源驗證使用 `網址前置字元` + `HTML標記`，我使用的 template 自帶 Google 資源驗證的參數設定，相當方便！

#### Sitemap 建立索引

Sitemap 提交注意事項：我感覺應該是 Google Search Console 本身顯示上的 bug，第一次提交 Sitemap 申請時會出現以下錯誤：

{{< admonition type=failure title="失敗" open=true >}}
無法擷取 Sitemap
{{< /admonition >}}

只要確定 sitemap 的路徑正確無誤，我們此時唯一能做的事情就只有等，等到 Google 處理完本次提交為止

<br>

如果不確定網站上 sitemap 路徑是否正確的話，可以直接從後台右上角點擊 `開啟 SITEMAP` 檢查：

{{< image src="./img-02-開啟SITEMAP.png" caption="Google Search Console 管理後台" >}}

只要能夠正確抓到 sitemap，基本上就可以安心等待了，大約 3-7 天左右的時間就會看到 Sitemap 建立完成

{{< image src="./img-03-驗證成功.png" caption="成功新增 Sitemap" >}}

最後在 Google 搜尋上輸入 `site:{your_blog_path}` 確認是否確實被加入索引

{{< image src="./img-04-確認結果.png" caption="google chrome 搜尋結果" >}}

<br>

剩下的分析與使用環節就不在此討論了，畢竟...我目前也沒有什麼數據可以分享的 🥹

### References

- [Google Search Console 無法擷取sitemap解決方法](https://kyiplay.com/2020/04/google-search-console-coudnt-fetch-sitemap/)
- [Hugo - Google Search Console](https://yidti.github.io/blog/hugo/gsc/)

## Google Analytics

### 目的

- 覺得很潮
- 沒了，就真的只是覺得很潮

### 過程紀錄

#### GA 追蹤代碼

將想要追蹤的網頁加入 Google 代碼，就可以在用戶訪問時主動收到串流詳情：

{{< image src="./img-05-GA追蹤代碼.png" caption="hugo template: loveit" >}}

我使用的 template 一樣自帶 Google Analytics 參數設定，再次感謝 [LoveIt](https://github.com/dillonzq/LoveIt) 的作者大大 🫡

設定好之後就可以從 Google Analytics 的後台首頁看到即時數據：

{{< image src="./img-06-GA儀表板.png" caption="Google Analytics Dashboard" >}}

<br>

至此，個人網站的基本建置就大致完成了，接下來只需要持之以恆，希望能夠一直穩定產出下去 ...

