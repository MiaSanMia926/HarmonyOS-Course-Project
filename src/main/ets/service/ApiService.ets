// service/ApiService.ets
import http from '@ohos.net.http'
import { Constants } from '../common/Constants'
import { Plant, GrowthLog } from '../model/PlantModel'

interface DeepSeekMessage {
  role: string;
  content: string;
}

interface ChatRequestBody {
  model: string;
  max_tokens: number;
  messages: DeepSeekMessage[];
}

interface DeepSeekChoice {
  message: DeepSeekMessage;
}

interface DeepSeekResponse {
  choices: DeepSeekChoice[];
}

interface BaseResponse<T> {
  code: number;
  msg: string;
  data: T;
  result: T;
}

interface RawPlantData {
  id: number;
  user_id: number;
  name: string;
  species: string;
  tips: string;
  health_score: number;
  water_days: number;
  created_at: string;
  last_watered_at?: string;
  cover_image?: string;
}

interface RawLogData {
  id: number
  plant_id: number
  record_type?: string
  image_base64?: string
  analysis_result?: string
  created_at?: string
  note?: string;         // 🌟 补齐字段
  emotion_tag?: string;  // 🌟 补齐字段
}

interface IdentifyResult {
  species: string;
  waterDays: number;
  sunlight: string;
  fertilize: string;
  healthScore: number;
  tips: string;
  plantId: number;
}


class ApiService {

  private async request<T>(path: string, method: http.RequestMethod, extraData?: Record<string, string | number>): Promise<T> {
    const httpRequest = http.createHttp()
    const options: http.HttpRequestOptions = {
      method: method,
      header: { 'Content-Type': 'application/json' },
      readTimeout: 30000,
      connectTimeout: 30000
    }

    if (extraData) {
      options.extraData = JSON.stringify(extraData)
    }

    try {
      const response = await httpRequest.request(`${Constants.BASE_URL}${path}`, options)
      if (response.responseCode === 200) {
        const resObj = JSON.parse(response.result as string) as BaseResponse<T>
        if (resObj.code === 200) {
          return resObj.data !== undefined ? resObj.data : resObj.result
        } else {
          throw new Error(resObj.msg || '业务接口返回错误')
        }
      } else {
        throw new Error(`HTTP 报错: ${response.responseCode}`)
      }
    } finally {
      httpRequest.destroy()
    }
  }


  async identifyAndCreatePlant(userId: number, plantName: string, imageBase64: string): Promise<IdentifyResult> {
    const payload: Record<string, string | number> = {
      'userId': userId,
      'plantName': plantName,
      'image_base64': imageBase64
    }
    return await this.request<IdentifyResult>('/api/plants/identify', http.RequestMethod.POST, payload)
  }

  async analyzeHealth(plantId: number, imageBase64: string): Promise<string> {
    const payload: Record<string, string | number> = {
      'plantId': plantId,
      'image_base64': imageBase64
    }
    return await this.request<string>('/api/plants/analyze', http.RequestMethod.POST, payload)
  }

  async compareGrowth(plantId: number, beforeBase64: string, afterBase64: string): Promise<string> {
    const payload: Record<string, string | number> = {
      'plantId': plantId,
      'before_base64': beforeBase64,
      'after_base64': afterBase64
    }
    return await this.request<string>('/api/plants/compare', http.RequestMethod.POST, payload)
  }


  async getUserPlants(userId: number): Promise<Plant[]> {
    const rawData = await this.request<RawPlantData[]>(`/api/users/${userId}/plants`, http.RequestMethod.GET)
    const plants: Plant[] = []

    for (let i = 0; i < rawData.length; i++) {
      const item = rawData[i]
      const plant: Plant = {
        id: item.id,
        userId: item.user_id,
        name: item.name,
        species: item.species || '',
        cover_image: item.cover_image || '',
        aiCarePlan: item.tips || '',
        healthStatus: item.health_score >= 80 ? 'healthy' : 'warning',
        waterIntervalDays: item.water_days || 3,
        lastWateredAt: item.last_watered_at || '',
        createdAt: item.created_at || ''
      }
      plants.push(plant)
    }
    return plants
  }

  async getPlantRecords(plantId: number): Promise<GrowthLog[]> {
    try {
      let rawList = await this.request<RawLogData[]>(`/api/plants/${plantId}/records`, http.RequestMethod.GET)
      return rawList.map((item: RawLogData) => {
        let log: GrowthLog = {
          id: item.id,
          plantId: item.plant_id,
          // 🌟 核心：优先使用我们刚存的 note 和 emotion_tag
          note: item.note || (item.record_type === 'compare' ? '进行了生长对比' : '记录了最新状态'),
          imagePath: item.image_base64 ? `data:image/jpeg;base64,${item.image_base64}` : '',
          aiAnalysis: item.analysis_result || '',
          emotionTag: item.emotion_tag || (item.record_type === 'identify' ? '🌟 新建档' : '💚 健康打卡'),
          recordedAt: item.created_at || new Date().toISOString()
        }
        return log
      })
    } catch (error) {
      console.error('获取成长记录失败:', error)
      return []
    }
  }

  // 🌟 新增：手动发送日记的 API 请求
  async addPlantRecord(plantId: number, note: string, imageBase64: string, emotionTag: string, aiAnalysis: string): Promise<boolean> {
    const payload: Record<string, string | number> = {
      'note': note,
      'image_base64': imageBase64,
      'emotion_tag': emotionTag,
      'ai_analysis': aiAnalysis
    }
    try {
      await this.request<void>(`/api/plants/${plantId}/records`, http.RequestMethod.POST, payload)
      return true
    } catch (e) {
      console.error('【写日记失败】', e)
      return false
    }
  }

  async deletePlant(plantId: number): Promise<boolean> {
    try {
      await this.request<void>(`/api/plants/${plantId}`, http.RequestMethod.DELETE)
      return true
    } catch (e) {
      return false
    }
  }

  async waterPlant(plantId: number): Promise<boolean> {
    try {
      await this.request<void>(`/api/plants/${plantId}/water`, http.RequestMethod.PUT)
      return true
    } catch (e) {
      return false
    }
  }

  async getTodayReminders(userId: number): Promise<Record<string, string | number>[]> {
    return await this.request<Record<string, string | number>[]>(`/api/users/${userId}/reminders/today`, http.RequestMethod.GET)
  }

  async completeReminder(reminderId: number): Promise<void> {
    await this.request<void>(`/api/reminders/${reminderId}/complete`, http.RequestMethod.POST)
  }

  async searchEncyclopedia(keyword: string): Promise<Record<string, string | number>[]> {
    return await this.request<Record<string, string | number>[]>(`/api/encyclopedia/search?keyword=${encodeURIComponent(keyword)}`, http.RequestMethod.GET)
  }

  async addFavorite(userId: number, encyclopediaId: number): Promise<void> {
    const payload: Record<string, string | number> = {
      'userId': userId,
      'encyclopediaId': encyclopediaId
    }
    await this.request<void>('/api/favorites', http.RequestMethod.POST, payload)
  }

  private async chatWithDeepSeek(messages: DeepSeekMessage[]): Promise<string> {
    const httpRequest = http.createHttp()
    const deepseekKey = AppStorage.get<string>('DEEPSEEK_KEY')

    if (!deepseekKey) {
      return '系统提示：应用未正确加载密钥，请重启 App 后重试。'
    }

    const body: ChatRequestBody = {
      model: 'deepseek-chat',
      max_tokens: 100,
      messages: messages
    }

    const options: http.HttpRequestOptions = {
      method: http.RequestMethod.POST,
      header: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${deepseekKey}`
      },
      extraData: JSON.stringify(body)
    }

    try {
      const response = await httpRequest.request('https://api.deepseek.com/v1/chat/completions', options)
      const result = JSON.parse(response.result as string) as DeepSeekResponse
      if (result.choices && result.choices.length > 0) {
        return result.choices[0].message.content
      }
      return '寄语获取失败'
    } finally {
      httpRequest.destroy()
    }
  }

  async getDailyTip(plantName: string, species: string): Promise<string> {
    const msg: DeepSeekMessage = {
      role: 'user',
      content: `我有一株${species || '植物'}，名叫"${plantName}"。请给我一句今日养护小贴士，20字以内，温馨有趣。`
    }
    try {
      return await this.chatWithDeepSeek([msg])
    } catch {
      return `记得今天查看一下${plantName}的状态哦～`
    }
  }
}

export const apiService = new ApiService()