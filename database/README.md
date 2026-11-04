# 数据库初始化

`bootstrap.sql` 仅创建 `plant_diary_db` 数据库。为应用配置该库的账号与权限后，后端首次启动会根据 `backend/main.py` 中的 SQLAlchemy 模型创建缺失的表。

在 MySQL 客户端执行 `SOURCE /实际路径/database/bootstrap.sql;`，或使用客户端的导入功能。Windows PowerShell 不支持 Bash 风格的输入重定向，不应直接照搬 `mysql < file.sql`。

`legacy_schema.sql` 为原始建表材料，保留用于追溯，不作为新环境初始化入口：其中部分列与当前 ORM 不一致。已有数据库需要单独核对并迁移；`create_all()` 不会添加缺失列或修改列类型。

不随仓库提供用户数据、默认账号或密码文件。百科数据需自行维护。
