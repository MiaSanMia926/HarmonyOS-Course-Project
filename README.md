# 🌿 植物成长日记

> 一款运行在华为鸿蒙手机上、由 AI 驱动的植物养护助手。
> 拍张照片即可识别品种、获取养护方案，并持续追踪植物的健康成长。

---

## 目录

- [效果预览](#效果预览)
- [功能特性](#功能特性)
- [技术栈](#技术栈)
- [项目结构](#项目结构)
- [环境要求](#环境要求)
- [后端部署（电脑端）](#后端部署电脑端)
- [前端部署（鸿蒙手机端）](#前端部署鸿蒙手机端)
- [配置说明](#配置说明)
- [使用指南](#使用指南)
- [常见问题](#常见问题)

---

## 效果预览

| 花园首页 | AI 品种识别 | 健康诊断 | 成长日志 |
|---------|------------|---------|---------|
| 植物卡片列表，今日 AI 寄语 | 拍照 → 自动识别品种 + 生成养护方案 | 单图分析叶片健康状态 | 图文时间线，情绪标签 |

---

## 功能特性

- **🤖 AI 品种识别**：拍一张照片，自动识别植物品种，并生成包含浇水周期、光照需求、施肥建议的个性化养护方案
- **🏥 健康诊断**：随时为植物做一次 AI 体检，分析叶片状态并给出具体建议
- **📊 生长对比**：上传前后两张照片，AI 从叶片、颜色、长势三个维度生成对比报告
- **📓 成长日志**：图文并茂地记录植物每个阶段，支持情绪标签和时间线浏览
- **🔔 养护提醒**：自动检测浇水时间，到期后推送系统通知，同一天内不重复打扰
- **👥 多用户隔离**：每个账号的数据完全独立，JWT 鉴权保障安全

---

## 技术栈

| 层次 | 技术 |
|------|------|
| 前端 | HarmonyOS · ArkTS · ArkUI 声明式框架 |
| 后端 | Python 3.11 · FastAPI · SQLAlchemy · PyMySQL |
| 数据库 | MySQL 8.0 |
| AI 模型 | 通义千问 Qwen-VL-Plus（图像理解）· DeepSeek（文字生成） |
| 鉴权 | JWT（PyJWT）· bcrypt 密码哈希 |

---

## 项目结构

```
.
├── backend_plant/          # Python 后端
│   ├── main.py             # FastAPI 主程序（所有接口）
│   ├── plant_diary_db.sql  # 数据库建表 SQL
│   ├── .env                # 环境变量（需自行创建，见下文）
│   └── requirements.txt    # Python 依赖（需自行创建，见下文）
│
└── PlantDiaryback/         # 鸿蒙前端
    └── entry/src/main/ets/
        ├── common/
        │   └── Constants.ets   # ⭐ 后端地址配置（需修改）
        ├── pages/              # 所有页面
        └── service/            # 业务服务层
```

---

## 环境要求

### 电脑端（运行后端）

| 软件 | 版本要求 | 下载地址 |
|------|---------|---------|
| Python | 3.9 或以上 | https://www.python.org/downloads/ |
| MySQL | 8.0 或以上 | https://dev.mysql.com/downloads/mysql/ |
| pip | 随 Python 自带 | — |

### 手机端（运行前端）

| 要求 | 说明 |
|------|------|
| 操作系统 | HarmonyOS 4.0 或以上 |
| 开发工具 | DevEco Studio 4.0 或以上（如需自行编译）|
| DevEco Studio 下载 | https://developer.huawei.com/consumer/cn/deveco-studio/ |

> **注意**：电脑和手机必须处于**同一个局域网**（连接同一个 Wi-Fi），或者手机能访问到你电脑的 IP 地址。

---

## 后端部署（电脑端）

### 第一步：安装 MySQL 并创建数据库

1. 安装 MySQL 后，打开命令行，登录 MySQL：

   ```bash
   mysql -u root -p
   ```

2. 执行建库 SQL（将 `plant_diary_db.sql` 文件内容粘贴执行，或使用以下命令导入）：

   ```bash
   mysql -u root -p < backend_plant/plant_diary_db.sql
   ```

   这会自动创建 `plant_diary_db` 数据库和 `users` 表。

### 第二步：配置数据库连接

打开 `backend_plant/main.py`，找到第 **20 行**，修改为你自己的 MySQL 密码：

```python
# 修改前（默认密码是 761026）
SQLALCHEMY_DATABASE_URL = "mysql+pymysql://root:761026@127.0.0.1:3306/plant_diary_db"

# 修改后（换成你的 MySQL root 密码）
SQLALCHEMY_DATABASE_URL = "mysql+pymysql://root:你的密码@127.0.0.1:3306/plant_diary_db"
```

### 第三步：配置 AI 接口密钥

在 `backend_plant/` 目录下新建一个 `.env` 文件（注意文件名就是 `.env`，没有其他扩展名）：

```bash
# backend_plant/.env

AI_API_KEY=你的通义千问API密钥
AI_BASE_URL=https://dashscope.aliyuncs.com/compatible-mode/v1
```

**如何获取通义千问 API Key：**

1. 打开 https://bailian.console.aliyun.com/
2. 注册/登录阿里云账号
3. 进入「模型广场」→ 搜索「qwen-vl-plus」→ 点击「API」
4. 在「API-KEY」页面创建一个新的 Key，复制填入上方

> 如果你同时需要 DeepSeek 每日寄语功能，还需要在 `.env` 中添加：
> ```
> DEEPSEEK_API_KEY=你的DeepSeek密钥
> ```
> DeepSeek API Key 申请地址：https://platform.deepseek.com/

### 第四步：安装 Python 依赖

在 `backend_plant/` 目录下创建 `requirements.txt` 文件，内容如下：

```
fastapi==0.111.0
uvicorn==0.30.1
sqlalchemy==2.0.30
pymysql==1.1.1
passlib[bcrypt]==1.7.4
pyjwt==2.8.0
python-dotenv==1.0.1
openai==1.30.5
```

然后在终端执行安装：

```bash
cd backend_plant
pip install -r requirements.txt
```

> **Windows 用户**：如果 `pip` 不可用，请尝试 `python -m pip install -r requirements.txt`

### 第五步：启动后端服务

```bash
cd backend_plant
python main.py
```

看到以下输出说明启动成功：

```
INFO:     Started server process [xxxxx]
INFO:     Waiting for application startup.
INFO:     Application startup complete.
INFO:     Uvicorn running on http://0.0.0.0:8080 (Press CTRL+C to quit)
```

### 第六步：查看你的电脑 IP 地址

后续前端需要填写这个 IP。

**Windows：**
```bash
ipconfig
# 找到"以太网适配器"或"无线局域网适配器"下的 IPv4 地址，例如 192.168.1.100
```

**macOS / Linux：**
```bash
ifconfig | grep "inet "
# 找到非 127.0.0.1 的地址，例如 192.168.1.100
```

---

## 前端部署（鸿蒙手机端）

### 第一步：修改后端地址

打开文件 `PlantDiaryback/entry/src/main/ets/common/Constants.ets`：

```typescript
export class Constants {
  // 将这里改成你电脑的 IP 地址（后端第六步查到的那个）
  static readonly BASE_URL: string = 'http://192.168.1.100:8080';
  //                                           ↑ 改成你自己的 IP
}
```

### 第二步：用 DevEco Studio 打开项目

1. 打开 DevEco Studio
2. 点击「Open」，选择 `PlantDiaryback` 文件夹
3. 等待依赖同步完成（右下角进度条消失即可）

### 第三步：连接鸿蒙手机

1. 在手机上开启「开发者模式」：
   - 进入「设置」→「关于手机」→ 连续点击「版本号」7次
   - 返回「设置」→「系统与更新」→「开发人员选项」→ 开启「USB 调试」
2. 用数据线连接手机与电脑
3. 手机上弹出「是否允许 USB 调试」→ 点击「允许」
4. DevEco Studio 右上角设备列表会出现你的手机型号

### 第四步：运行到手机

点击 DevEco Studio 右上角的 **▶ 运行按钮**（绿色三角），等待编译完成后应用会自动安装并打开。

> 首次运行时手机会弹出权限申请（相机、相册、网络），请全部允许，否则 AI 功能无法正常使用。

---

## 配置说明

### 所有需要修改的地方汇总

| 文件 | 位置 | 需要改什么 |
|------|------|-----------|
| `backend_plant/main.py` | 第 20 行 | MySQL 密码 |
| `backend_plant/.env` | 整个文件（新建）| 通义千问 API Key |
| `PlantDiaryback/.../Constants.ets` | `BASE_URL` | 电脑的局域网 IP 地址 |

### 端口说明

后端默认运行在 `8080` 端口。如需修改，在 `main.py` 最后一行改：

```python
uvicorn.run(app, host="0.0.0.0", port=8080)  # 修改 port 的值
```

同时在 `Constants.ets` 中同步修改端口号。

---

## 使用指南

### 注册与登录

1. 打开应用，点击「去注册」创建账号
2. 输入用户名和密码，点击「注册」
3. 回到登录页，输入账号密码，点击「登录」

> 初始测试账号（如果你导入了 `password.txt` 中的用户）：
> - 账号：`admin`，密码：`123`
> - 账号：`pedri`，密码：`8888`

### 添加第一株植物

1. 点击底部「工作台」Tab 或花园页右上角「+」按钮
2. 输入植物昵称（如「我的绿萝」）
3. 点击「选择图片」，从相册选一张植物照片，或直接拍照
4. 点击「AI 识别」，等待 3–5 秒
5. 查看 AI 生成的养护方案（品种、浇水周期、光照需求等）
6. 点击「保存」，植物档案建立完成

### AI 健康体检

1. 进入任意植物的详情页
2. 点击「健康体检」，上传今日状态照片
3. 查看 AI 的健康分析报告

### 生长对比

1. 进入植物详情页 → 「AI 对比分析」
2. 分别上传「之前」和「现在」两张照片
3. 查看从叶片、颜色、长势三维度的对比报告

---

## 常见问题

**Q：应用提示「网络请求失败」怎么办？**

1. 确认后端服务已启动（终端没有报错，显示 `Uvicorn running on...`）
2. 检查 `Constants.ets` 中的 IP 是否是你电脑在当前 Wi-Fi 下的 IP
3. 确认手机和电脑连接的是**同一个 Wi-Fi**
4. 检查电脑防火墙是否拦截了 8080 端口（Windows 用户可临时关闭防火墙测试）

**Q：AI 识别失败 / 返回错误怎么办？**

1. 检查 `.env` 文件中的 `AI_API_KEY` 是否正确，前后没有多余空格
2. 确认阿里云账号的通义千问 API 余额充足
3. 查看后端终端的报错日志（`【报错记录】`开头的行）

**Q：MySQL 连接失败怎么办？**

1. 确认 MySQL 服务正在运行（Windows：任务管理器 → 服务 → MySQL80）
2. 确认 `main.py` 第 20 行的密码与你安装 MySQL 时设置的 root 密码一致
3. 确认数据库 `plant_diary_db` 已创建（执行过 `.sql` 文件）

**Q：DevEco Studio 找不到设备怎么办？**

1. 检查 USB 数据线是否支持数据传输（部分充电线不支持）
2. 手机是否已开启「USB 调试」
3. 重新插拔 USB 线，或重启 DevEco Studio

**Q：权限被拒绝后 AI 功能不可用怎么办？**

进入手机「设置」→「应用」→「植物成长日记」→「权限」，手动开启相机和相册权限。

---

## 致谢

- AI 能力由 [通义千问 Qwen-VL](https://bailian.console.aliyun.com/) 和 [DeepSeek](https://platform.deepseek.com/) 提供
- 前端基于 [HarmonyOS ArkUI](https://developer.huawei.com/consumer/cn/) 构建
- 后端基于 [FastAPI](https://fastapi.tiangolo.com/) 构建

---

*南开大学 密码与网络空间安全学院 · 物联网工程 · 程子涵 · 2026*
