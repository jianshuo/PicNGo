# PicNGo（Food Analyzer）

一款基于 **GPT-4o** 的 iOS 食物分析应用。拍一张食物照片或从相册选择，即可获得成分识别、热量估算、健康评级与营养建议。

## 功能

- **拍照 / 选图**：使用相机拍摄或从相册选择食物照片
- **智能分析**：通过 OpenAI GPT-4o 视觉能力识别食物并分析：
  - 食物名称
  - 主要成分列表
  - 预估热量（每份）
  - 健康等级（Healthy / Moderate / Unhealthy）
  - 简要营养与健康评估
  - 实用健康小贴士
- **成分详情**：点击任意成分可查看更详细的营养与说明
- **多语言**：支持 **英文**、**中文**、**日语** 的分析结果
- **隐私**：API Key 仅保存在本机，不会上传或共享

## 技术栈

- **SwiftUI**：界面与导航
- **OpenAI API**：`gpt-4o` 多模态（图像 + 文本）调用
- **PhotosUI**：相册选图
- **AVFoundation**：相机拍摄

## 要求

- iOS 17+
- Xcode 15+
- [OpenAI API Key](https://platform.openai.com/api-keys)（需有 GPT-4o 权限）

## 安装与运行

1. 克隆仓库并打开工程：
   ```bash
   git clone <repository-url>
   cd PicNGo
   open PicNGo.xcodeproj   # 或 .xcworkspace（若使用 CocoaPods/SPM）
   ```
2. 在 Xcode 中选择目标设备或模拟器，运行（⌘R）。
3. 首次使用：点击右上角 **齿轮** 进入设置，填入你的 **OpenAI API Key** 并保存。
4. 选择 **相机** 或 **相册** 添加食物照片，点击 **Analyze Food** 即可查看分析结果。

## 项目结构（主要文件）

| 文件 | 说明 |
|------|------|
| `PicNGoApp.swift` | 应用入口 |
| `ContentView.swift` | 主界面：选图、分析按钮、结果展示 |
| `FoodAnalyzerService.swift` | 调用 OpenAI API 进行食物与成分分析 |
| `FoodAnalysisResult.swift` | 分析结果数据模型与健康等级 |
| `IngredientDetailView.swift` | 成分详情页 |
| `CameraView.swift` | 相机拍照视图 |
| `SettingsView.swift` | 设置（API Key、语言） |
| `APIKeyManager.swift` | API Key 与语言偏好管理 |

## 许可证

请参阅仓库中的许可证文件。
