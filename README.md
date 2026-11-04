# 植物成长日记 · Plant Diary

面向 HarmonyOS 的植物养护应用，使用 ArkTS / ArkUI 构建移动端，FastAPI 与 MySQL 提供数据与图像分析接口，覆盖植物建档、健康分析、生长对比和图文日记。

## 功能概览

| 场景 | 实现位置 |
| --- | --- |
| 账号注册与登录 | 移动端登录页、后端 `/user/*` |
| 图片识别与养护建议 | Qwen-VL 图像理解 + 植物建档接口 |
| 健康分析与生长对比 | 单图 / 双图分析接口 |
| 成长记录与养护打卡 | ArkUI 页面、成长记录及提醒接口 |
| 百科检索与收藏 | 百科及收藏接口，内容需自行维护 |

## 目录结构

```text
.
├── backend/
│   ├── main.py                 # FastAPI、ORM 模型与 AI 接口
│   ├── requirements.txt
│   └── .env.example
├── mobile/
│   └── entry/src/              # HarmonyOS entry 模块源码、资源与测试
├── database/
│   ├── bootstrap.sql           # 新环境建库
│   └── legacy_schema.sql       # 历史 SQL，非当前建表入口
└── docs/
    ├── architecture.md
    ├── development.md
    ├── api.md
    └── archive/                # 原毕业论文与汇报材料
```

## 启动后端

建议 Python 3.11、MySQL 8.0。从仓库根目录执行：

```bash
python -m venv .venv
# Windows: .venv\Scripts\activate
# macOS / Linux: source .venv/bin/activate
python -m pip install -r backend/requirements.txt
```

1. 使用 MySQL 客户端执行 `database/bootstrap.sql`，并为应用账号配置该库的访问权限。
2. 复制 `backend/.env.example` 为 `backend/.env`，填写数据库连接、随机 JWT 密钥和图像模型 Key。
3. 运行：`python -m uvicorn backend.main:app --host 0.0.0.0 --port 8080 --reload`。
4. 打开 `http://localhost:8080/docs` 查看接口。

后端从 `backend/.env` 读取配置，不再要求修改源码中的数据库密码。首次启动根据 ORM 模型创建缺失的表；不会自动迁移已有表结构。

## 运行移动端

当前仓库包含 `entry/src` 源码，**尚未包含完整 DevEco 工程配置**（如 AppScope、Hvigor 和构建配置）。请先在 DevEco Studio 创建适合目标 SDK 的 Stage / ArkTS 空项目，再按照 [mobile/README.md](mobile/README.md) 集成源码。

将 `mobile/entry/src/main/ets/common/Constants.ets` 的 `BASE_URL` 改为手机可访问的后端地址。真机上的 `127.0.0.1` 指向手机自身，需要使用电脑的局域网 IP。

## 文档与状态

- [模块架构与当前边界](docs/architecture.md)
- [开发、配置与验证](docs/development.md)
- [API 导览](docs/api.md)
- [数据库说明](database/README.md)
- [目录迁移记录](docs/migration.md)
- [贡献指南](CONTRIBUTING.md)

当前登录会签发 JWT，但业务路由尚未统一校验身份与资源归属；移动端完整构建和设备运行也需在补齐工程配置后验证。本文按现有代码描述能力，不将原型声明为已完成生产部署。

本次目录整理的实际检查结果见[验证记录](docs/validation.md)。
