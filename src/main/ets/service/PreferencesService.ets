import preferences from '@ohos.data.preferences'
import common from '@ohos.app.ability.common'

class PreferencesService {
  private prefs: preferences.Preferences | null = null

  async init(context: common.UIAbilityContext): Promise<void> {
    this.prefs = await preferences.getPreferences(context, 'plant_diary_prefs')
  }

  async getString(key: string, defValue: string): Promise<string> {
    return (await this.prefs?.get(key, defValue)) as string
  }

  async setString(key: string, value: string): Promise<void> {
    await this.prefs?.put(key, value)
    await this.prefs?.flush()
  }

  async shouldNotifyWaterToday(plantId: number): Promise<boolean> {
    const today = new Date().toDateString()
    const key = `water_notify_${plantId}_${today}`
    const hasNotified = await this.prefs?.get(key, false)
    return !hasNotified
  }

  async markWaterNotifiedToday(plantId: number): Promise<void> {
    const today = new Date().toDateString()
    const key = `water_notify_${plantId}_${today}`
    await this.prefs?.put(key, true)
    await this.prefs?.flush()
  }
}

export const prefsService = new PreferencesService()