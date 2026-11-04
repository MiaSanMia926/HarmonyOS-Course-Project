# 目录迁移记录

| 原位置 | 现位置 |
| --- | --- |
| `main.py` | `backend/main.py` |
| `plant_diary_db.sql` | `database/legacy_schema.sql` |
| `src/` | `mobile/entry/src/` |
| 毕业论文与汇报 PPTX | `docs/archive/` |
| `password.txt` | 从新版本移除，不再分发本地测试账号 |

新增后端依赖文件、环境变量示例、建库脚本与开发文档。数据库连接和 JWT 签名密钥改从环境读取，移动端模块图标引用改为已有资源。原来源与毕业设计材料保留，不改写为商业交付经历。

删除密码文件不会抹除 Git 历史；历史版本仍可追溯。本次整理没有替代密钥轮换，也没有补齐原仓库缺失的 DevEco 构建配置。

客户端 `EntryAbility.ets` 中嵌入的模型 API Key 已清空。该 Key 曾进入公开仓库，应在服务商控制台撤销并更换；仅在新提交中删除不能让旧 Key 失效。
