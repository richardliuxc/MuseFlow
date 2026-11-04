<p align="center">
  <img src="assets/images/app_icon.png" width="132" alt="MuseFlow app icon" />
</p>

<h1 align="center">MuseFlow · 沐声</h1>

<p align="center">
  多平台聚合音乐播放器 · 商业级 Flutter UI · 让声音自然流动
</p>

<p align="center">
  <img alt="Flutter" src="https://img.shields.io/badge/Flutter-3.19-02569B?logo=flutter&logoColor=white" />
  <img alt="Dart" src="https://img.shields.io/badge/Dart-3.3-0175C2?logo=dart&logoColor=white" />
  <img alt="Platforms" src="https://img.shields.io/badge/Platforms-Android%20%7C%20iOS%20%7C%20macOS%20%7C%20Web-6C63FF" />
  <img alt="License" src="https://img.shields.io/badge/License-MIT-34D399" />
</p>

---

MuseFlow 是一个完整的 Flutter 音乐播放器项目：从品牌 Logo、设计系统、动效，到聚合搜索、播放、歌词、队列、收藏、歌单、离线下载与设置，全部可运行。界面采用「Aurora Noir」视觉语言——近黑舞台、玻璃质感表面与极光渐变，适配手机、平板与桌面宽屏。

![MuseFlow 首页](docs/home.jpg)

## 亮点

- **多平台聚合搜索**：网易云、酷我、酷狗、QQ 音乐、咪咕，一次搜索、统一结果。
- **自动换源**：当前音源无版权 / 需会员时，自动按标题、歌手、时长匹配其它平台的可播放版本。
- **完整播放体验**：队列、上一首 / 下一首、随机、列表循环、单曲循环、进度拖拽、音量、睡眠定时。
- **逐行歌词**：LRC 解析、翻译合并、当前行高亮、点击歌词跳转，歌词自动滚动。
- **本地音乐库**：我喜欢的音乐、自建歌单、最近播放、离线下载，全部持久化到本机。
- **商业级界面**：响应式侧边栏 / 底栏、正在播放侧栏、迷你播放器、沉浸式全屏播放页、玻璃拟态、极光背景、等化器动效。
- **离线示例曲库**：内置 8 首由程序合成的原创氛围音乐（含封面与歌词），无网络也能完整体验。
- **品牌资产**：自绘 SVG Logo、应用图标、8 张专辑封面，已适配 Android / iOS / macOS / Web 图标。

| 搜索 | 播放器 | 音乐库 |
| --- | --- | --- |
| ![搜索](docs/search.jpg) | ![播放器](docs/player.jpg) | ![音乐库](docs/library.jpg) |

> 截图使用 Web 预览构建，宽屏布局；移动端会自动切换为底部导航 + 迷你播放器。

<p align="center">
  <img src="docs/home-mobile.jpg" width="300" alt="MuseFlow 移动端首页" />
  <img src="docs/player-mobile.jpg" width="300" alt="MuseFlow 移动端播放器" />
  <img src="docs/phone.jpg" width="300" alt="MuseFlow 在 Android 真机运行" />
</p>

## 音乐资源如何获取

实现思路参考了 [guohuiyuan/go-music-dl](https://github.com/guohuiyuan/go-music-dl) 及其核心库 [music-lib](https://github.com/guohuiyuan/music-lib)，在 Flutter 侧重新实现了轻量客户端：

| 音源 | 搜索 | 播放直链 | 歌词 | 说明 |
| --- | --- | --- | --- | --- |
| 网易云音乐 | `music.163.com/api/search/get/web` | `api/song/enhance/player/url` + 外链兜底 | `api/song/lyric` | 默认音源，元数据最全 |
| 酷我音乐 | `search.kuwo.cn/r.s` | `antiserver.kuwo.cn/anti.s` | 需登录态，通常回退网易云 | 直链可用率高 |
| 酷狗音乐 | `songsearch.kugou.com/song_search_v2` | `m.kugou.com/app/i/getSongInfo.php` | `krcs.kugou.com` + `lyrics.kugou.com` | 部分曲目需会员 |
| QQ 音乐 | `c.y.qq.com/.../client_search_cp` | `u.y.qq.com` vkey 接口 | `fcg_query_lyric_new` | 会员曲目会自动换源 |
| 咪咕音乐 | `pd.musicapp.migu.cn/.../search_all.do` | 暂不支持 | 资源自带 LRC | 提供搜索与元数据 |
| MuseFlow 录音室 | 本地目录 | 本地资源 | 内置 LRC | 完全离线 |

播放失败时会按 `netease → kuwo → kugou → qq` 的顺序寻找同名、同歌手、时长接近的版本；成功后在播放器与迷你播放器中标注「已换源」。

> **版权声明**：本项目不存储、不托管任何音频文件，也不提供破解能力。所有音乐版权归各平台与版权方所有。接口仅用于个人学习、研究与技术交流，请勿用于商业用途，请支持正版音乐。

## 技术栈

- **Flutter 3.19 / Dart 3.3**，Material 3 自定义主题
- **just_audio + audio_session**：跨平台音频播放
- **provider**：轻量状态管理（Player / Library / Settings / Download）
- **http**：各平台接口客户端，按音源隔离错误与超时
- **shared_preferences**：收藏、歌单、历史、设置持久化
- **cached_network_image**：封面缓存与渐变占位
- **path_provider**：离线下载目录
- **url_launcher**：开源项目与合规链接
- **Inter / InterDisplay**：界面字体（本地打包，无网络字体依赖）

## 目录结构

```
lib/
├── app.dart                 # Provider 装配、主题、本地化
├── main.dart                # 启动与本地数据加载
├── core/                    # 主题、工具、LRC 解析
├── models/                  # Song / Playlist / Download 模型
├── data/demo_catalog.dart   # 原创离线曲库与编辑精选
├── services/
│   ├── music_source.dart    # 音源抽象
│   ├── music_repository.dart# 聚合搜索、榜单、自动换源
│   ├── sources/             # 网易云 / 酷我 / 酷狗 / QQ / 咪咕 / 示例
│   ├── player_service.dart  # 队列与播放状态机
│   ├── library_store.dart   # 收藏、歌单、历史、下载记录
│   ├── settings_store.dart  # 音质、音源开关、播放偏好
│   └── download_service.dart# 流式下载与本地持久化
└── ui/
    ├── screens/             # 发现、搜索、音乐库、设置、播放器、歌单、榜单
    ├── sheets/              # 底部弹层
    └── widgets/             # 设计系统与业务组件
```

## 运行

环境：Flutter `>= 3.19`（Dart `>= 3.3.4`）。

```bash
flutter pub get
flutter run -d chrome        # Web 预览
flutter run -d macos         # macOS（需 Xcode）
flutter run -d android       # Android（需 Android SDK）
flutter run -d ios           # iOS（需 Xcode + 签名）
```

构建：

```bash
flutter build web --release --web-renderer html
flutter build apk --release --target-platform android-arm64
flutter build macos --release
flutter build ios --release --no-codesign
```

### 安装到 Android 手机

开启手机 USB 调试或无线调试，确认设备已连接：

```bash
adb devices
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

项目提供的 arm64 安装包位于 `dist/MuseFlow-1.0.0-arm64.apk`（约 21 MB，包名 `app.museflow.museflow`，versionName `1.0.0`），使用本机自签名 keystore 完成签名（密钥与密码不纳入版本库），可直接安装；生产发布请替换为自己的正式签名。

### 平台说明

- **Android / iOS / macOS**：可访问全部第三方音源；首次构建请允许网络权限（项目已配置）。
- **Web**：浏览器受 CORS 限制，第三方接口可能拒绝跨域请求。Web 构建适合 UI 预览与离线示例曲库体验；完整曲库请使用 App / 桌面端。
- **离线下载**：仅 App / 桌面端支持，文件保存在应用文档目录 `MuseFlow/Downloads`。
- **后台播放**：iOS 已声明 `audio` 后台模式；Android 目前由 just_audio 持有一个前台音频会话，后续可接入 `audio_service` 获得系统媒体通知。

## 测试

```bash
flutter analyze   # 0 issues
flutter test      # 17 tests
```

测试覆盖 LRC 解析与翻译合并、数据模型序列化、格式化工具，以及歌曲列表组件交互。

## 设计资产

- 品牌语：**Every sound, your flow.**
- 主色：`#8B5CF6` → `#22D3EE` → `#34D399` 极光渐变
- 背景：`#06070D` 近黑舞台
- Logo 由 `tool/gen_art.py` 生成 SVG 并通过无头 Chrome 栅格化；应用图标与专辑封面同源生成。
- 示例音乐由 `tool/gen_audio.py` 使用 numpy 合成，原创且可自由用于演示。

## 致谢

- [go-music-dl](https://github.com/guohuiyuan/go-music-dl) — 多平台音乐搜索与下载的接口与产品设计参考
- [music-lib](https://github.com/guohuiyuan/music-lib) — 各平台接口细节参考
- [Inter](https://rsms.me/inter/) — 字体
- Flutter 社区与所有音乐平台公开接口

## License

代码以 MIT License 发布。品牌名称、Logo、内置示例音乐仅用于本项目演示；第三方平台接口与内容版权归各自权利人所有。
