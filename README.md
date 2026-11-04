# MuseFlow Landing Page

MuseFlow 的官方产品落地页，纯静态 HTML / CSS / JavaScript，无构建步骤，可直接部署到 GitHub Pages、Cloudflare Pages、Vercel 或任意静态服务器。

## 预览

在项目根目录（`museflow/`）启动静态服务器：

```bash
python3 -m http.server 8092
```

然后访问 **http://localhost:8092/landing/**。

> 下载按钮指向 `landing/downloads/MuseFlow-1.0.0-arm64.apk`，因此请保持 `landing/` 目录完整；如果单独部署 `landing/` 目录，APK 也会一起部署。

## 结构

```
landing/
├── index.html              # 页面结构
├── styles.css              # Aurora Noir 视觉与响应式布局
├── main.js                 # 导航、滚动揭示、截图切换、视差
├── downloads/              # Android arm64 安装包
└── assets/
    ├── fonts/              # 本地 Inter 字体
    ├── shots/              # 桌面端 / 手机端界面截图
    ├── app-icon.png        # 品牌图标
    └── favicon.png
```

## 修改下载版本

1. 将新的 APK 放入 `downloads/`；
2. 更新 `index.html` 中的下载链接、版本号与文件大小；
3. 如需更新社交分享图，替换 `assets/shots/home-desktop.jpg`。

## 说明

页面不加载任何第三方 CDN、字体或统计脚本，离线也能完整显示。所有截图来自实际运行的 MuseFlow。
