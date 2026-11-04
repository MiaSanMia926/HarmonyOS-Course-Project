# API 导览

后端默认端口为 8080，完整请求字段见运行服务的 `/docs`。

| 方法 | 路径 | 功能 |
| --- | --- | --- |
| POST | `/user/register`、`/user/login` | 注册、登录 |
| POST | `/api/plants/identify` | 图像识别与植物建档 |
| POST | `/api/plants/analyze` | 健康分析 |
| POST | `/api/plants/compare` | 前后图片对比 |
| POST | `/api/plants/{plant_id}/records` | 写成长日记 |
| GET | `/api/users/{user_id}/plants` | 用户植物列表 |
| GET | `/api/plants/{plant_id}/records` | 成长记录列表 |
| DELETE | `/api/plants/{plant_id}` | 删除植物 |
| PUT | `/api/plants/{plant_id}/water` | 浇水打卡 |
| GET | `/api/users/{user_id}/reminders/today` | 当前实现返回未完成提醒 |
| POST | `/api/reminders` | 创建提醒 |
| POST | `/api/reminders/{reminder_id}/complete` | 完成提醒 |
| GET | `/api/encyclopedia/search` | 百科检索 |
| POST | `/api/favorites` | 添加收藏 |
| GET | `/api/users/{user_id}/favorites` | 收藏列表 |

业务响应常使用 `code`、`msg`、`data` 或 `result`。HTTP 错误使用 FastAPI 的异常响应，并不完全复用此格式。

当前业务接口接收用户 / 植物 ID，但未统一验证 JWT 与资源归属；登录返回令牌不等同于业务数据已隔离。后续补齐鉴权时应同步调整移动端请求头与接口契约。
