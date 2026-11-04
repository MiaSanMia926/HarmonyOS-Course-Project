from fastapi import FastAPI, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy import create_engine, Column, Integer, String, Text, ForeignKey, DateTime
from sqlalchemy.dialects.mysql import LONGTEXT
from sqlalchemy.orm import sessionmaker, Session, declarative_base
from passlib.context import CryptContext
import jwt
import datetime
import os
from pathlib import Path
import json
from openai import OpenAI
from dotenv import load_dotenv

load_dotenv(Path(__file__).resolve().parent / ".env")

SQLALCHEMY_DATABASE_URL = os.getenv("DATABASE_URL")
SECRET_KEY = os.getenv("JWT_SECRET_KEY")
if not SQLALCHEMY_DATABASE_URL or not SECRET_KEY:
    raise RuntimeError("请先配置 backend/.env 中的 DATABASE_URL 和 JWT_SECRET_KEY")


engine = create_engine(SQLALCHEMY_DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

class DBUser(Base):
    __tablename__ = "users"
    id = Column(Integer, primary_key=True, index=True)
    username = Column(String(50), unique=True, index=True)
    password_hash = Column(String(255))
    memo = Column(String(255), default="")

class DBPlant(Base):
    __tablename__ = "plants"
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    name = Column(String(100), nullable=False)
    species = Column(String(100), default="")
    water_days = Column(Integer, default=0)
    sunlight = Column(String(50), default="")
    fertilize = Column(String(100), default="")
    health_score = Column(Integer, default=100)
    tips = Column(String(255), default="")
    created_at = Column(String(50), default=lambda: datetime.datetime.now().isoformat())
    last_watered_at = Column(String(50), default="")
    cover_image = Column(LONGTEXT)

class DBGrowthRecord(Base):
    __tablename__ = "growth_records"
    id = Column(Integer, primary_key=True, index=True)
    plant_id = Column(Integer, ForeignKey("plants.id", ondelete="CASCADE"), nullable=False)
    record_type = Column(String(50), nullable=False)
    image_base64 = Column(LONGTEXT)
    analysis_result = Column(Text)
    
    # 🌟 核心新增：存储手账日记的三个字段
    note = Column(Text, default="")
    emotion_tag = Column(String(50), default="")
    created_at = Column(String(50), default=lambda: datetime.datetime.now().isoformat())

class DBReminder(Base):
    __tablename__ = "reminders"
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    plant_id = Column(Integer, ForeignKey("plants.id", ondelete="CASCADE"), nullable=False)
    task_type = Column(String(50), nullable=False)
    remind_time = Column(String(50), nullable=False)
    is_completed = Column(Integer, default=0)

class DBPlantEncyclopedia(Base):
    __tablename__ = "plant_encyclopedia"
    id = Column(Integer, primary_key=True, index=True)
    species_name = Column(String(100), unique=True, nullable=False)
    alias = Column(String(100), default="")
    morphology = Column(Text)
    growth_habit = Column(Text)
    toxicity = Column(String(255), default="无毒")

class DBUserFavorite(Base):
    __tablename__ = "user_favorites"
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    encyclopedia_id = Column(Integer, ForeignKey("plant_encyclopedia.id", ondelete="CASCADE"), nullable=False)

Base.metadata.create_all(bind=engine)

class LoginRequest(BaseModel):
    id: int = 0
    name: str
    pwd: str
    memo: str = ""

class LoginResponse(BaseModel):
    code: int
    msg: str
    data: str
    userId: int = 0

class PlantIdentifyRequest(BaseModel):
    userId: int
    plantName: str
    image_base64: str

class HealthAnalyzeRequest(BaseModel):
    plantId: int
    image_base64: str

class GrowthCompareRequest(BaseModel):
    plantId: int
    before_base64: str
    after_base64: str

# 🌟 新增：写日记的请求模型
class GrowthRecordCreateRequest(BaseModel):
    note: str = ""
    image_base64: str = ""
    emotion_tag: str = ""
    ai_analysis: str = ""

class ReminderCreateRequest(BaseModel):
    userId: int
    plantId: int
    taskType: str
    remindTime: str

class FavoriteRequest(BaseModel):
    userId: int
    encyclopediaId: int

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
ALGORITHM = "HS256"

client = OpenAI(
    api_key=os.getenv("AI_API_KEY"),
    base_url=os.getenv("AI_BASE_URL", "https://dashscope.aliyuncs.com/compatible-mode/v1")
)

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

app = FastAPI(title="Plant Diary API Pro")

@app.post("/user/register")
def register(request: LoginRequest, db: Session = Depends(get_db)):
    if db.query(DBUser).filter(DBUser.username == request.name).first():
        raise HTTPException(status_code=400, detail="用户名已被注册")
    hashed_password = pwd_context.hash(request.pwd)
    new_user = DBUser(username=request.name, password_hash=hashed_password, memo=request.memo)
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    return {"code": 200, "msg": "注册成功", "data": f"用户ID: {new_user.id}"}

@app.post("/user/login", response_model=LoginResponse)
def login(request: LoginRequest, db: Session = Depends(get_db)):
    db_user = db.query(DBUser).filter(DBUser.username == request.name).first()
    if not db_user or not pwd_context.verify(request.pwd, db_user.password_hash):
        return LoginResponse(code=401, msg="用户名或密码错误", data="")
    expiration = datetime.datetime.now(datetime.timezone.utc) + datetime.timedelta(days=7)
    token_payload = {"sub": db_user.username, "id": db_user.id, "exp": expiration}
    access_token = jwt.encode(token_payload, SECRET_KEY, algorithm=ALGORITHM)
    return LoginResponse(code=200, msg="登录成功", data=access_token, userId=db_user.id)

@app.post("/api/plants/identify")
async def identify_plant(request: PlantIdentifyRequest, db: Session = Depends(get_db)):
    if not request.image_base64:
        raise HTTPException(status_code=400, detail="没有图片数据")
    
    system_prompt = """你是一个植物学家。
    严格按照以下JSON格式返回：
    {
      "species": "植物品种名称",
      "waterDays": 3,
      "sunlight": "光照要求",
      "fertilize": "施肥要求",
      "healthScore": 85,
      "tips": "一句话建议"
    }"""
    try:
        response = client.chat.completions.create(
            model="qwen-vl-plus", 
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": [
                    {"type": "text", "text": f"植物名叫：{request.plantName}。请识别并生成方案。"},
                    {"type": "image_url", "image_url": {"url": f"data:image/jpeg;base64,{request.image_base64}"}}
                ]}
            ]
        )
        ai_result_text = response.choices[0].message.content
        clean_json_str = ai_result_text.replace("```json", "").replace("```", "").strip()
        ai_data = json.loads(clean_json_str)
        
        new_plant = DBPlant(
            user_id=request.userId,
            name=request.plantName,
            species=ai_data.get("species", "未知"),
            water_days=ai_data.get("waterDays", 3),
            sunlight=ai_data.get("sunlight", ""),
            fertilize=ai_data.get("fertilize", ""),
            health_score=ai_data.get("healthScore", 100),
            tips=ai_data.get("tips", ""),
            cover_image=request.image_base64
        )
        db.add(new_plant)
        db.commit()
        db.refresh(new_plant)
        
        new_record = DBGrowthRecord(
            plant_id=new_plant.id,
            record_type="identify",
            image_base64=request.image_base64,
            analysis_result=clean_json_str
        )
        db.add(new_record)
        db.commit()
        
        ai_data["plantId"] = new_plant.id
        return {"code": 200, "data": ai_data}
    except Exception as e:
        raise HTTPException(status_code=500, detail="AI 识别失败")

@app.post("/api/plants/analyze")
async def analyze_health(request: HealthAnalyzeRequest, db: Session = Depends(get_db)):
    plant_name = "未知植物"
    if request.plantId != 0:
        plant = db.query(DBPlant).filter(DBPlant.id == request.plantId).first()
        if plant:
            plant_name = f"{plant.name}({plant.species})"

    try:
        response = client.chat.completions.create(
            model="qwen-vl-plus", 
            messages=[
                {"role": "system", "content": "你是一位植物医生。请直接输出纯文本分析，不超过100字。"},
                {"role": "user", "content": [
                    {"type": "text", "text": f"这是我的{plant_name}今天的状态，请分析健康并给建议。"},
                    {"type": "image_url", "image_url": {"url": f"data:image/jpeg;base64,{request.image_base64}"}}
                ]}
            ]
        )
        ai_msg = response.choices[0].message.content
        
        if request.plantId != 0:
            new_record = DBGrowthRecord(
                plant_id=request.plantId,
                record_type="analyze",
                image_base64=request.image_base64,
                analysis_result=ai_msg
            )
            db.add(new_record)
            db.commit()
            
        return {"code": 200, "result": ai_msg}
    except Exception as e:
        return {"code": 500, "result": "网络波动，稍后再试。"}

@app.post("/api/plants/compare")
async def compare_growth(request: GrowthCompareRequest, db: Session = Depends(get_db)):
    plant = db.query(DBPlant).filter(DBPlant.id == request.plantId).first()
    plant_name = plant.name if plant else "植物"
    try:
        response = client.chat.completions.create(
            model="qwen-vl-plus", 
            messages=[
                {"role": "system", "content": "你是一位植物生长分析师。请直接输出纯文本评价，100字以内。"},
                {"role": "user", "content": [
                    {"type": "text", "text": f"这是{plant_name}前后两张照片，请简短描述生长变化。"},
                    {"type": "image_url", "image_url": {"url": f"data:image/jpeg;base64,{request.before_base64}"}},
                    {"type": "image_url", "image_url": {"url": f"data:image/jpeg;base64,{request.after_base64}"}}
                ]}
            ]
        )
        ai_msg = response.choices[0].message.content
        
        new_record = DBGrowthRecord(
            plant_id=request.plantId,
            record_type="compare",
            image_base64=request.after_base64,
            analysis_result=ai_msg
        )
        db.add(new_record)
        db.commit()
        
        return {"code": 200, "result": ai_msg}
    except Exception as e:
        return {"code": 500, "result": "网络波动，稍后再试。"}


# 🌟 新增：手动保存日记本的接口
@app.post("/api/plants/{plant_id}/records")
def create_plant_record(plant_id: int, request: GrowthRecordCreateRequest, db: Session = Depends(get_db)):
    plant = db.query(DBPlant).filter(DBPlant.id == plant_id).first()
    if not plant:
        raise HTTPException(status_code=444, detail="植物不存在")
    
    new_record = DBGrowthRecord(
        plant_id=plant_id,
        record_type="diary",
        image_base64=request.image_base64,
        analysis_result=request.ai_analysis,
        note=request.note,
        emotion_tag=request.emotion_tag
    )
    db.add(new_record)
    db.commit()
    return {"code": 200, "msg": "日记保存成功"}


@app.get("/api/users/{user_id}/plants")
def get_user_plants(user_id: int, db: Session = Depends(get_db)):
    plants = db.query(DBPlant).filter(DBPlant.user_id == user_id).order_by(DBPlant.id.desc()).all()
    return {"code": 200, "data": plants}

@app.get("/api/plants/{plant_id}/records")
def get_plant_records(plant_id: int, db: Session = Depends(get_db)):
    records = db.query(DBGrowthRecord).filter(DBGrowthRecord.plant_id == plant_id).order_by(DBGrowthRecord.id.desc()).all()
    return {"code": 200, "data": records}

@app.get("/api/users/{user_id}/reminders/today")
def get_today_reminders(user_id: int, db: Session = Depends(get_db)):
    reminders = db.query(DBReminder).filter(DBReminder.user_id == user_id, DBReminder.is_completed == 0).all()
    return {"code": 200, "data": reminders}

@app.post("/api/reminders")
def create_reminder(request: ReminderCreateRequest, db: Session = Depends(get_db)):
    new_reminder = DBReminder(
        user_id=request.userId,
        plant_id=request.plantId,
        task_type=request.taskType,
        remind_time=request.remindTime
    )
    db.add(new_reminder)
    db.commit()
    return {"code": 200, "msg": "提醒创建成功"}

@app.post("/api/reminders/{reminder_id}/complete")
def complete_reminder(reminder_id: int, db: Session = Depends(get_db)):
    reminder = db.query(DBReminder).filter(DBReminder.id == reminder_id).first()
    if reminder:
        reminder.is_completed = 1
        db.commit()
        return {"code": 200, "msg": "打卡成功"}
    raise HTTPException(status_code=444, detail="任务不存在")

@app.get("/api/encyclopedia/search")
def search_encyclopedia(keyword: str, db: Session = Depends(get_db)):
    results = db.query(DBPlantEncyclopedia).filter(DBPlantEncyclopedia.species_name.like(f"%{keyword}%")).all()
    return {"code": 200, "data": results}

@app.post("/api/favorites")
def add_favorite(request: FavoriteRequest, db: Session = Depends(get_db)):
    exists = db.query(DBUserFavorite).filter(
        DBUserFavorite.user_id == request.userId, 
        DBUserFavorite.encyclopedia_id == request.encyclopediaId
    ).first()
    if exists:
        return {"code": 200, "msg": "已经收藏过了"}
    new_fav = DBUserFavorite(user_id=request.userId, encyclopedia_id=request.encyclopediaId)
    db.add(new_fav)
    db.commit()
    return {"code": 200, "msg": "收藏成功"}

@app.get("/api/users/{user_id}/favorites")
def get_user_favorites(user_id: int, db: Session = Depends(get_db)):
    favs = db.query(DBPlantEncyclopedia).join(
        DBUserFavorite, DBUserFavorite.encyclopedia_id == DBPlantEncyclopedia.id
    ).filter(DBUserFavorite.user_id == user_id).all()
    return {"code": 200, "data": favs}

@app.delete("/api/plants/{plant_id}")
def delete_plant(plant_id: int, db: Session = Depends(get_db)):
    plant = db.query(DBPlant).filter(DBPlant.id == plant_id).first()
    if not plant:
        raise HTTPException(status_code=444, detail="植物不存在")
    db.delete(plant)
    db.commit()
    return {"code": 200, "msg": "删除成功"}

@app.put("/api/plants/{plant_id}/water")
def water_plant(plant_id: int, db: Session = Depends(get_db)):
    plant = db.query(DBPlant).filter(DBPlant.id == plant_id).first()
    if not plant:
        raise HTTPException(status_code=444, detail="植物不存在")
    plant.last_watered_at = datetime.datetime.now().isoformat()
    db.commit()
    return {"code": 200, "msg": "浇水记录成功"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8080)