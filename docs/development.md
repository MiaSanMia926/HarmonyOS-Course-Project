# 开发与验证

## 配置约定

后端固定读取与 `main.py` 同目录的 `.env`，也接受已设置的进程环境变量。使用 `backend/.env.example` 创建本地配置：

| 变量 | 用途 |
| --- | --- |
| `DATABASE_URL` | MySQL SQLAlchemy 连接串，密码中的特殊字符需 URL 编码 |
| `JWT_SECRET_KEY` | 本地生成的随机签名密钥 |
| `AI_API_KEY` | 图像模型服务密钥，使用 AI 接口前需配置 |
| `AI_BASE_URL` | OpenAI 兼容地址，默认 DashScope 兼容接口 |

可用 `python -c "import secrets; print(secrets.token_urlsafe(48))"` 生成随机 JWT 密钥。不要直接使用示例占位值。示例依赖采用兼容版本范围，尚未锁定完整运行环境；`bcrypt==4.0.1` 用于兼容现有 Passlib。

## 数据库

先执行 `database/bootstrap.sql`，再启动后端，由 ORM 创建表。不要在新环境先执行 `legacy_schema.sql`：历史 SQL 与当前 ORM 的字段类型及列不完全一致，`create_all()` 不能修复已有表。

本地语法检查：

```bash
python -m compileall -q backend
```

准备好 MySQL 与模型配置后，从仓库根目录启动：

```bash
python -m uvicorn backend.main:app --host 0.0.0.0 --port 8080 --reload
```

也可在 `backend/` 内执行 `python main.py`。配置加载不依赖当前工作目录。

## 验证清单

1. 在 `/docs` 注册新账号并登录，不使用仓库内预置账号。
2. 在移动端验证图片选择、识别建档、健康分析、双图对比、日记和打卡。
3. 验证页面重进与服务重启后的数据持久化。
4. 在目标设备上检查权限拒绝、后端不可达和 AI 调用失败的表现。

移动端验证前需先补齐 DevEco 工程，详见 [mobile/README.md](../mobile/README.md)。当前没有自动化后端业务测试；语法检查不能替代 MySQL 联调与真机验证。
