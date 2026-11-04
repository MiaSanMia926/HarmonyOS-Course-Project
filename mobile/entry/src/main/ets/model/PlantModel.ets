// model/PlantModel.ets

export type HealthStatus = 'healthy' | 'warning' | 'unknown'
export type ReminderType = 'water' | 'fertilize' | 'prune'

export interface Plant {
  userId: number;
  id: number
  name: string
  species: string
  cover_image: string
  aiCarePlan: string
  healthStatus: HealthStatus
  waterIntervalDays: number
  lastWateredAt: string
  createdAt: string
}

export interface PlantInsert {
  userId: number;
  name: string
  species: string
  cover_image: string
  aiCarePlan: string
  healthStatus: HealthStatus
  waterIntervalDays: number
  lastWateredAt: string
  createdAt: string
}

export interface GrowthLog {
  id: number
  plantId: number
  note: string
  imagePath: string
  aiAnalysis: string
  emotionTag: string
  recordedAt: string
}

export interface GrowthLogInsert {
  plantId: number
  note: string
  imagePath: string
  aiAnalysis: string
  emotionTag: string
  recordedAt: string
}

export interface CareReminder {
  id: number
  plantId: number
  reminderType: ReminderType
  remindAt: string
  isDone: number
}

export interface CareReminderInsert {
  plantId: number
  reminderType: ReminderType
  remindAt: string
  isDone: number
}

export interface PlantUpdateValues {
  name?: string
  species?: string
  cover_image_path?: string
  ai_care_plan?: string
  health_status?: HealthStatus
  water_interval_days?: number
  last_watered_at?: string
  created_at?: string
}

export interface AICarePlan {
  species?: string
  waterDays: number
  sunlight: string
  fertilize: string
  tips: string
  healthScore: number
}

export interface GrowthLogItem extends GrowthLog {
  plantName: string
}

export interface PlantNameEntry {
  id: number
  name: string
}

export function getHealthLabel(status: HealthStatus): string {
  if (status === 'healthy') {
    return '健康'
  }
  if (status === 'warning') {
    return '需关注'
  }
  return '未知'
}

export function getReminderLabel(type: ReminderType): string {
  if (type === 'water') {
    return '浇水'
  }
  if (type === 'fertilize') {
    return '施肥'
  }
  if (type === 'prune') {
    return '修剪'
  }
  return type
}

export function parseHealthStatus(raw: string): HealthStatus {
  if (raw === 'healthy' || raw === 'warning' || raw === 'unknown') {
    return raw
  }
  return 'unknown'
}

export function parseReminderType(raw: string): ReminderType {
  if (raw === 'water' || raw === 'fertilize' || raw === 'prune') {
    return raw
  }
  return 'water'
}
