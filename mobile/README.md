# HarmonyOS 移动端

`entry/src/` 包含原始 ArkTS 页面、服务、资源及测试代码；整理保持 `src/main`、`src/test`、`src/ohosTest` 的标准相对层级。

## 集成到 DevEco Studio 工程

1. 创建一个面向目标设备 SDK 的 Stage / ArkTS 空项目，模块名使用 `entry`。
2. 将本目录的 `entry/src/` 内容合入新项目的 `entry/src/`；保留新工程生成的 `AppScope/`、`build-profile.json5`、`oh-package.json5`、`hvigorfile.ts` 等构建文件。
3. 合并 `module.json5` 中的 Ability、页面和权限配置。仓库模块内图标统一引用现有的 `$media:icon`；AppScope 的应用级图标、名称等仍需使用生成工程的资源。
4. 检查目标 SDK 对相机、媒体读取、通知和本地数据库 API 的支持，按编译器提示适配权限。
5. 修改 `entry/src/main/ets/common/Constants.ets` 的后端地址，连接设备编译运行。

`@ohos.*` API 和权限与 SDK 版本有关。由于原始仓库未提供 SDK / 构建配置，无法仅凭源码准确指定最低兼容版本，也不能直接把本目录当作完整工程打开运行。

## 代码导航

| 目录 | 内容 |
| --- | --- |
| `src/main/ets/pages` | 登录、花园、植物详情、日记、分析与资料页 |
| `src/main/ets/service` | HTTP、本地数据库、偏好、文件与通知 |
| `src/main/ets/model` | 植物与成长记录数据类型 |
| `src/main/ets/common` | 地址、主题、动画和图片选择工具 |
| `src/main/resources` | 图片、文案、页面清单和主题资源 |
| `src/test`、`src/ohosTest` | 原有测试，需集成到可构建工程后执行 |

## 每日寄语配置

现有 `ApiService` 的每日寄语方法直接读取 AppStorage 的 `DEEPSEEK_KEY`，并从客户端调用 DeepSeek。原源码中嵌入的 Key 已清空；仓库不再分发客户端密钥，未配置时该功能不可用。后端 `.env` 的 `AI_API_KEY` 用于植物图像分析，不会自动传入此功能。后续应将每日寄语调用迁到后端，避免把服务密钥打包进应用。
