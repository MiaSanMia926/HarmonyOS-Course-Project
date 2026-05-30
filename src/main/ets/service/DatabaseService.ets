// service/DatabaseService.ets
import relationalStore from '@ohos.data.relationalStore'
import {
  Plant,
  GrowthLog,
  CareReminder,
  GrowthLogItem,
  PlantInsert,
  GrowthLogInsert,
  CareReminderInsert,
  PlantUpdateValues,
  parseHealthStatus,
  parseReminderType
} from '../model/PlantModel'
import common from '@ohos.app.ability.common'

const DB_CONFIG: relationalStore.StoreConfig = {
  name: 'PlantDiary.db',
  securityLevel: relationalStore.SecurityLevel.S1
}

const CREATE_PLANT = `CREATE TABLE IF NOT EXISTS plant (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER,
  name TEXT NOT NULL,
  species TEXT DEFAULT '',
  cover_image_path TEXT DEFAULT '',
  ai_care_plan TEXT DEFAULT '',
  health_status TEXT DEFAULT 'unknown',
  water_interval_days INTEGER DEFAULT 3,
  last_watered_at TEXT DEFAULT '',
  created_at TEXT NOT NULL
)`

const CREATE_LOG = `CREATE TABLE IF NOT EXISTS growth_log (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  plant_id INTEGER NOT NULL,
  note TEXT DEFAULT '',
  image_path TEXT DEFAULT '',
  ai_analysis TEXT DEFAULT '',
  emotion_tag TEXT DEFAULT '',
  recorded_at TEXT NOT NULL
)`

const CREATE_REMINDER = `CREATE TABLE IF NOT EXISTS care_reminder (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  plant_id INTEGER NOT NULL,
  reminder_type TEXT NOT NULL,
  remind_at TEXT NOT NULL,
  is_done INTEGER DEFAULT 0
)`

class DatabaseService {
  private rdbStore: relationalStore.RdbStore | null = null

  async init(context: common.UIAbilityContext): Promise<void> {
    this.rdbStore = await relationalStore.getRdbStore(context, DB_CONFIG)
    await this.rdbStore.executeSql(CREATE_PLANT)
    await this.rdbStore.executeSql(CREATE_LOG)
    await this.rdbStore.executeSql(CREATE_REMINDER)
  }

  // ── Plant CRUD ──────────────────────────────────────────

  async insertPlant(plant: PlantInsert): Promise<number> {
    const values: relationalStore.ValuesBucket = {
      user_id: plant.userId, // 🌟 绑定用户ID
      name: plant.name,
      species: plant.species,
      cover_image_path: plant.cover_image,
      ai_care_plan: plant.aiCarePlan,
      health_status: plant.healthStatus,
      water_interval_days: plant.waterIntervalDays,
      last_watered_at: plant.lastWateredAt,
      created_at: plant.createdAt
    }
    return await this.rdbStore!.insert('plant', values)
  }

  async getAllPlants(userId: number): Promise<Plant[]> { // 🌟 接收 userId
    const predicates = new relationalStore.RdbPredicates('plant')
    predicates.equalTo('user_id', userId).orderByDesc('created_at') // 🌟 数据隔离过滤
    const cursor = await this.rdbStore!.query(predicates, [
      'id', 'user_id', 'name', 'species', 'cover_image_path', 'ai_care_plan',
      'health_status', 'water_interval_days', 'last_watered_at', 'created_at'
    ])
    const plants: Plant[] = []
    while (cursor.goToNextRow()) {
      plants.push({
        id: cursor.getLong(cursor.getColumnIndex('id')),
        userId: cursor.getLong(cursor.getColumnIndex('user_id')), // 🌟 映射 userId
        name: cursor.getString(cursor.getColumnIndex('name')),
        species: cursor.getString(cursor.getColumnIndex('species')),
        cover_image: cursor.getString(cursor.getColumnIndex('cover_image_path')),
        aiCarePlan: cursor.getString(cursor.getColumnIndex('ai_care_plan')),
        healthStatus: parseHealthStatus(cursor.getString(cursor.getColumnIndex('health_status'))),
        waterIntervalDays: cursor.getLong(cursor.getColumnIndex('water_interval_days')),
        lastWateredAt: cursor.getString(cursor.getColumnIndex('last_watered_at')),
        createdAt: cursor.getString(cursor.getColumnIndex('created_at'))
      })
    }
    cursor.close()
    return plants
  }

  async getPlantById(id: number): Promise<Plant | null> {
    const predicates = new relationalStore.RdbPredicates('plant')
    predicates.equalTo('id', id)
    const cursor = await this.rdbStore!.query(predicates)
    if (cursor.goToNextRow()) {
      const plant: Plant = {
        id: cursor.getLong(cursor.getColumnIndex('id')),
        userId: cursor.getLong(cursor.getColumnIndex('user_id')), // 🌟 映射 userId
        name: cursor.getString(cursor.getColumnIndex('name')),
        species: cursor.getString(cursor.getColumnIndex('species')),
        cover_image: cursor.getString(cursor.getColumnIndex('cover_image_path')),
        aiCarePlan: cursor.getString(cursor.getColumnIndex('ai_care_plan')),
        healthStatus: parseHealthStatus(cursor.getString(cursor.getColumnIndex('health_status'))),
        waterIntervalDays: cursor.getLong(cursor.getColumnIndex('water_interval_days')),
        lastWateredAt: cursor.getString(cursor.getColumnIndex('last_watered_at')),
        createdAt: cursor.getString(cursor.getColumnIndex('created_at'))
      }
      cursor.close()
      return plant
    }
    cursor.close()
    return null
  }

  async updatePlant(id: number, values: PlantUpdateValues): Promise<void> {
    const predicates = new relationalStore.RdbPredicates('plant')
    predicates.equalTo('id', id)
    const bucket: relationalStore.ValuesBucket = {}
    if (values.name !== undefined) {
      bucket['name'] = values.name
    }
    if (values.species !== undefined) {
      bucket['species'] = values.species
    }
    if (values.cover_image_path !== undefined) {
      bucket['cover_image_path'] = values.cover_image_path
    }
    if (values.ai_care_plan !== undefined) {
      bucket['ai_care_plan'] = values.ai_care_plan
    }
    if (values.health_status !== undefined) {
      bucket['health_status'] = values.health_status
    }
    if (values.water_interval_days !== undefined) {
      bucket['water_interval_days'] = values.water_interval_days
    }
    if (values.last_watered_at !== undefined) {
      bucket['last_watered_at'] = values.last_watered_at
    }
    if (values.created_at !== undefined) {
      bucket['created_at'] = values.created_at
    }
    await this.rdbStore!.update(bucket, predicates)
  }

  async deletePlant(id: number): Promise<void> {
    const predicates = new relationalStore.RdbPredicates('plant')
    predicates.equalTo('id', id)
    await this.rdbStore!.delete(predicates)
    const logPred = new relationalStore.RdbPredicates('growth_log')
    logPred.equalTo('plant_id', id)
    await this.rdbStore!.delete(logPred)
    const remPred = new relationalStore.RdbPredicates('care_reminder')
    remPred.equalTo('plant_id', id)
    await this.rdbStore!.delete(remPred)
  }

  // ── GrowthLog CRUD ──────────────────────────────────────

  async insertLog(log: GrowthLogInsert): Promise<number> {
    const values: relationalStore.ValuesBucket = {
      plant_id: log.plantId,
      note: log.note,
      image_path: log.imagePath,
      ai_analysis: log.aiAnalysis,
      emotion_tag: log.emotionTag,
      recorded_at: log.recordedAt
    }
    return await this.rdbStore!.insert('growth_log', values)
  }

  async getLogsByPlant(plantId: number): Promise<GrowthLog[]> {
    const predicates = new relationalStore.RdbPredicates('growth_log')
    predicates.equalTo('plant_id', plantId).orderByDesc('recorded_at')
    const cursor = await this.rdbStore!.query(predicates)
    const logs: GrowthLog[] = []
    while (cursor.goToNextRow()) {
      logs.push({
        id: cursor.getLong(cursor.getColumnIndex('id')),
        plantId: cursor.getLong(cursor.getColumnIndex('plant_id')),
        note: cursor.getString(cursor.getColumnIndex('note')),
        imagePath: cursor.getString(cursor.getColumnIndex('image_path')),
        aiAnalysis: cursor.getString(cursor.getColumnIndex('ai_analysis')),
        emotionTag: cursor.getString(cursor.getColumnIndex('emotion_tag')),
        recordedAt: cursor.getString(cursor.getColumnIndex('recorded_at'))
      })
    }
    cursor.close()
    return logs
  }

  // ── CareReminder ────────────────────────────────────────

  async insertReminder(reminder: CareReminderInsert): Promise<number> {
    const values: relationalStore.ValuesBucket = {
      plant_id: reminder.plantId,
      reminder_type: reminder.reminderType,
      remind_at: reminder.remindAt,
      is_done: reminder.isDone
    }
    return await this.rdbStore!.insert('care_reminder', values)
  }

  async getPendingReminders(userId: number): Promise<CareReminder[]> { // 🌟 接收 userId 进行隔离查询
    const plants = await this.getAllPlants(userId)
    if (plants.length === 0) return []
    const plantIds = plants.map(p => p.id)

    const predicates = new relationalStore.RdbPredicates('care_reminder')
    predicates.in('plant_id', plantIds).equalTo('is_done', 0).orderByAsc('remind_at')
    const cursor = await this.rdbStore!.query(predicates)
    const reminders: CareReminder[] = []
    while (cursor.goToNextRow()) {
      reminders.push({
        id: cursor.getLong(cursor.getColumnIndex('id')),
        plantId: cursor.getLong(cursor.getColumnIndex('plant_id')),
        reminderType: parseReminderType(cursor.getString(cursor.getColumnIndex('reminder_type'))),
        remindAt: cursor.getString(cursor.getColumnIndex('remind_at')),
        isDone: cursor.getLong(cursor.getColumnIndex('is_done'))
      })
    }
    cursor.close()
    return reminders
  }

  async markReminderDone(id: number): Promise<void> {
    const predicates = new relationalStore.RdbPredicates('care_reminder')
    predicates.equalTo('id', id)
    await this.rdbStore!.update({ is_done: 1 }, predicates)
  }

  async getLogCount(userId: number): Promise<number> { // 🌟 接收 userId 进行隔离查询
    const plants = await this.getAllPlants(userId)
    if (plants.length === 0) return 0
    const plantIds = plants.map(p => p.id)

    const predicates = new relationalStore.RdbPredicates('growth_log')
    predicates.in('plant_id', plantIds)
    const cursor = await this.rdbStore!.query(predicates, ['id'])
    let count = 0
    while (cursor.goToNextRow()) {
      count++
    }
    cursor.close()
    return count
  }

  private lookupPlantName(nameMap: Map<number, string>, plantId: number): string {
    const name = nameMap.get(plantId)
    if (name !== undefined) {
      return name
    }
    return '未知植物'
  }

  async getRecentLogsWithPlant(userId: number, limit: number = 30): Promise<GrowthLogItem[]> { // 🌟 同步隔离
    const plants = await this.getAllPlants(userId)
    if (plants.length === 0) return []
    const nameMap = new Map<number, string>()
    for (const p of plants) {
      nameMap.set(p.id, p.name)
    }
    const plantIds = plants.map(p => p.id)

    const predicates = new relationalStore.RdbPredicates('growth_log')
    predicates.in('plant_id', plantIds).orderByDesc('recorded_at')
    const cursor = await this.rdbStore!.query(predicates)
    const items: GrowthLogItem[] = []
    while (cursor.goToNextRow() && items.length < limit) {
      const plantId = cursor.getLong(cursor.getColumnIndex('plant_id'))
      items.push({
        id: cursor.getLong(cursor.getColumnIndex('id')),
        plantId,
        plantName: this.lookupPlantName(nameMap, plantId),
        note: cursor.getString(cursor.getColumnIndex('note')),
        imagePath: cursor.getString(cursor.getColumnIndex('image_path')),
        aiAnalysis: cursor.getString(cursor.getColumnIndex('ai_analysis')),
        emotionTag: cursor.getString(cursor.getColumnIndex('emotion_tag')),
        recordedAt: cursor.getString(cursor.getColumnIndex('recorded_at'))
      })
    }
    cursor.close()
    return items
  }
}

export const dbService = new DatabaseService()