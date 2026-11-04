// service/NotificationService.ets
import notificationManager from '@ohos.notificationManager'
import notification from '@ohos.notification'

class NotificationService {
  private notifId = 1000

  private getReminderLabel(reminderType: string): string {
    if (reminderType === 'water') {
      return '浇水'
    }
    if (reminderType === 'fertilize') {
      return '施肥'
    }
    if (reminderType === 'prune') {
      return '修剪'
    }
    return reminderType
  }

  async sendCareReminder(plantName: string, reminderType: string): Promise<void> {
    const label = this.getReminderLabel(reminderType)
    const content: notificationManager.NotificationContent = {
      notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
      normal: {
        title: `${plantName} 需要${label}啦 🌱`,
        text: `你的植物 "${plantName}" 该${label}了，快去查看一下吧！`,
        additionalText: '植物成长日记'
      }
    }
    const request: notificationManager.NotificationRequest = {
      id: this.notifId++,
      content: content
    }
    try {
      await notificationManager.publish(request)
    } catch (e) {
      console.error('通知发送失败', JSON.stringify(e))
    }
  }

  async sendWaterReminder(plantName: string): Promise<void> {
    await this.sendCareReminder(plantName, 'water')
  }
}

export const notificationService = new NotificationService()
