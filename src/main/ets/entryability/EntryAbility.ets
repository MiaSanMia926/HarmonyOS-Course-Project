// entryability/EntryAbility.ets
import UIAbility from '@ohos.app.ability.UIAbility'
import hilog from '@ohos.hilog'
import window from '@ohos.window'

// 🌟 1. 导入必要的严格类型约束（解决 arkts-no-any-unknown）
import Want from '@ohos.app.ability.Want'
import AbilityConstant from '@ohos.app.ability.AbilityConstant'

// 2. 导入你需要初始化的所有核心服务
// (⚠️ 如果你的文件夹叫 services，请把这里的 service 改成 services)
import { dbService } from '../service/DatabaseService'
import { fileService } from '../service/FileService'
import { prefsService } from '../service/PreferencesService'

const TAG = 'PlantDiary'

export default class EntryAbility extends UIAbility {
  // 🌟 3. 给 want 和 launchParam 加上明确类型
  async onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): Promise<void> {
    hilog.info(0x0000, TAG, '%{public}s', 'Ability onCreate')
    AppStorage.setOrCreate('DEEPSEEK_KEY', 'sk-b7e41d5b1bae4822acabef6f7124a1e2');

    try {
      // 依序初始化各种服务
      await dbService.init(this.context)
      fileService.init(this.context)
      await prefsService.init(this.context)

      hilog.info(0x0000, TAG, '%{public}s', '【通电成功】所有核心服务已完成初始化！')
    } catch (error) {
      hilog.error(0x0000, TAG, '【通电失败】服务初始化报错: %{public}s', JSON.stringify(error))
    }
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // 🌟 4. 给回调里的 err 加上明确类型 Error
    windowStage.loadContent('pages/LoginPage', (err: Error) => {
      if (err && err.name) {
        hilog.error(0x0000, TAG, 'Failed to load LoginPage. Cause: %{public}s', JSON.stringify(err))
        return
      }
      hilog.info(0x0000, TAG, '%{public}s', 'LoginPage loaded')
    })
  }
}