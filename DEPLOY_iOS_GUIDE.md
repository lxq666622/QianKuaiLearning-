# 倩快学习 Flutter 跨平台版 · iPhone 装机指南 🍎

## ⚡ 最快 5 分钟方案（零Mac，普通Apple ID，推荐）

### 第一步：准备
1. 电脑和 iPhone 连同一个WiFi，数据线插上
2. iPhone 设置 → 面容ID与密码 → 打开「USB配件」
3. 数据线连上电脑 → iPhone点「信任」

### 第二步：下载 IPA（三种办法任选其一）

#### 办法A（推荐）：GitHub Actions 自动构建
```bash
# 把本项目推到 GitHub（私有仓库也行，免费）
git init && git add . && git commit -m "first"
git branch -M main
git remote add origin https://github.com/你的用户名/QianKuaiLearning.git
git push -u origin main
```
→ 打开 GitHub 仓库 → **Actions** Tab → 点一下「Run workflow」
→ 等 **30-45 分钟**（GitHub免费Mac排队）
→ 构建完成后：Summary 页面最底部 **Artifacts** 里有两个下载包：
   - `QianKuaiLearning-iOS-IPA.zip`（iPhone用）
   - `QianKuaiLearning-Android-APK.zip`（安卓用）

#### 办法B：Codemagic（3分钟排队更快）
- 登录 codemagic.io → Drag & drop 项目 zip
- Build for iOS → Build outputs → 下载 `.ipa`

#### 办法C：租一台Mac（本地打，不受网络限制，见下方「进阶」章）

### 第三步：安装（Sideloadly）
1. 官网下 Sideloadly Windows 版：https://sideloadly.io/
2. 打开 Sideloadly：
   - **iDevice** = 选你iPhone（同一WiFi/USB都行，找不到点搜索按钮）
   - **Apple ID** = 填你自己的
   - **IPA** = 拖入刚才下载的 ipa
3. 点 **Start** → 输密码 → 出双验证码时把iPhone上显示的6位数填进去
4. 完成 ✅ 显示 "Verification & Installation Successful"

### 第四步：打开 App
- iPhone 桌面第一次点开 → 弹「未受信任的开发者」
- 去 **设置 → 通用 → VPN与设备管理** → 找到你 Apple ID → 点「信任 xxx@gmail.com」
- 回桌面，打开 **倩快学习** 🎉

---

## ⚠️  7天签名过期，怎么办？（三选一）
| 方案 | 有效期 | 成本 | 操作 |
|---|---|---|---|
| 手动Sideloadly | 7天 | 免费 | 到期重按 Step 3「Start」，30秒 |
| AltStore + AltServer(Windows后台) | 7天自动续签 | 免费 | 同WiFi自动续签，无感 |
| 苹果开发者账号（$99/年） | **12个月** | $99/年 | Xcode配证书，Sideloadly选Ad-Hoc签名 |

---

## 🏠 进阶：打包过程需要改 iOS 配置（如权限说明）时？
本项目已在 `ios/Runner/Info.plist` 预留了所有必要权限：

```xml
<key>NSMicrophoneUsageDescription</key>
<string>录音用于口语练习、跟唱评分，不会上传</string>
<key>NSSpeechRecognitionUsageDescription</key>
<string>语音识别用于发音评分和口语转文字</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>读取图片用于OCR提取英文单词</string>
<key>NSCameraUsageDescription</key>
<string>拍照识别图片中的英文单词</string>
<key>NSUserNotificationUsageDescription</key>
<string>沈星回的学习提醒与定时通知</string>
```
> 如果构建失败，检查这几个key在Info.plist里。

---

## 📱 本项目 iOS 最低版本
- **iOS 13.0+**（你的iPhone版本26 = iOS 18，完美兼容 ✅）
- iPhone 8 / SE 2 以上

---

## 🔗 相关文件
- 云构建脚本: [.github/workflows/build_ios_android.yml](file:///workspace/QianKuaiLearning_Flutter/.github/workflows/build_ios_android.yml)
- 一键部署脚本: [scripts/deploy_iphone.sh](file:///workspace/QianKuaiLearning_Flutter/scripts/deploy_iphone.sh)
- 项目入口: [main.dart](file:///workspace/QianKuaiLearning_Flutter/lib/main.dart)
