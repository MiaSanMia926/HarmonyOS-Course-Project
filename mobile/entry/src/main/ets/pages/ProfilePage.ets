// pages/ProfilePage.ets
import { dbService } from '../service/DatabaseService'
import { prefsService } from '../service/PreferencesService'
import { fileService } from '../service/FileService'
import { apiService } from '../service/ApiService' // 🌟 引入云端 API
import { Plant, GrowthLog, CareReminder, getReminderLabel, PlantNameEntry } from '../model/PlantModel'
import { formatDate } from '../utils/DateUtils'
import { AppTheme } from '../common/AppTheme'
import { AnimationUtils } from '../common/AnimationUtils'
import promptAction from '@ohos.promptAction'
import common from '@ohos.app.ability.common'
import picker from '@ohos.file.picker'
import router from '@ohos.router'

@Component
struct ProfileStatCard {
  @Prop label: string = ''
  @Prop value: number = 0
  @Prop icon: string = ''

  build() {
    Column({ space: 6 }) {
      Text(this.icon).fontSize(28)
      Text(`${this.value}`).fontSize(26).fontWeight(FontWeight.Bold).fontColor(AppTheme.PRIMARY)
      Text(this.label).fontSize(12).fontColor(AppTheme.MUTED)
    }
    .layoutWeight(1)
    .backgroundColor(AppTheme.CARD)
    .borderRadius(AppTheme.RADIUS_CARD)
    .padding(16)
    .alignItems(HorizontalAlign.Center)
    .shadow(AppTheme.SHADOW)
  }
}

@Component
struct ProfileBadgeCard {
  @Prop icon: string = ''
  @Prop label: string = ''
  @Prop unlocked: boolean = false
  @Prop showBadges: boolean = false

  build() {
    Column({ space: 6 }) {
      Text(this.icon)
        .fontSize(28)
        .opacity(this.unlocked ? 1 : 0.3)
        .grayscale(this.unlocked ? 0 : 1)
      Text(this.label)
        .fontSize(11)
        .fontColor(this.unlocked ? AppTheme.PRIMARY_DARK : AppTheme.MUTED)
        .fontWeight(this.unlocked ? FontWeight.Medium : FontWeight.Normal)
    }
    .width(80)
    .height(80)
    .justifyContent(FlexAlign.Center)
    .backgroundColor(this.unlocked ? '#E8F5E9' : '#F5F5F5')
    .borderRadius(12)
    .shadow(this.unlocked ? AppTheme.SHADOW : undefined)
    .scale({ x: this.showBadges ? 1 : 0.8, y: this.showBadges ? 1 : 0.8 })
    .opacity(this.showBadges ? 1 : 0)
  }
}

@Component
export default struct ProfilePage {
  @State userName: string = '植物爱好者'
  @State avatarPath: string = ''
  @State plantCount: number = 0
  @State logCount: number = 0
  @State editingName: boolean = false
  @State tempName: string = ''
  @State reminders: CareReminder[] = []
  @State plantNameEntries: PlantNameEntry[] = []
  @State showReminders: boolean = false

  // 动画状态
  @State showBadges: boolean = false

  @Prop @Watch('onTabActivated') currentTabIndex: number = 0
  @Prop @Watch('onUpdateTriggered') updateTrigger: number = 0

  onUpdateTriggered() {
    this.loadAll()
  }

  onTabActivated() {
    if (this.currentTabIndex === 4) {
      this.loadAll()
    }
  }

  aboutToAppear() {
    this.loadAll()
  }

  onPageShow() {
    this.loadAll()
  }

  private getCurrentUserId(): number {
    let rawId = AppStorage.get<number | string>('current_user_id')
    return Number(rawId) || 0
  }

  async loadAll() {
    const context = getContext(this) as common.UIAbilityContext
    await prefsService.init(context)

    let currentUserId = this.getCurrentUserId()

    this.userName = await prefsService.getString(`userName_${currentUserId}`, '植物爱好者')
    this.avatarPath = await prefsService.getString(`userAvatar_${currentUserId}`, '')

    await this.loadStats()
    await this.loadReminders()

    setTimeout(() => {
      animateTo({ duration: 800, curve: AnimationUtils.SPRING_HEAVY }, () => {
        this.showBadges = true
      })
    }, 200)
  }

  async changeAvatar(): Promise<void> {
    try {
      let options = new picker.PhotoSelectOptions()
      options.MIMEType = picker.PhotoViewMIMETypes.IMAGE_TYPE
      options.maxSelectNumber = 1

      let photoPicker = new picker.PhotoViewPicker()
      let result = await photoPicker.select(options)

      if (result && result.photoUris.length > 0) {
        let uri = result.photoUris[0]
        let sandboxPath = await fileService.saveImageToSandbox(uri)
        this.avatarPath = sandboxPath

        let currentUserId = this.getCurrentUserId()
        await prefsService.setString(`userAvatar_${currentUserId}`, sandboxPath)

        promptAction.showToast({ message: '头像更新成功 🌱', duration: 1500 })
      }
    } catch (error) {
      promptAction.showToast({ message: '更换头像失败', duration: 2000 })
    }
  }

  async saveUserName(name: string) {
    if (!name.trim()) return

    let currentUserId = this.getCurrentUserId()
    await prefsService.setString(`userName_${currentUserId}`, name.trim())

    this.userName = name.trim()
    this.editingName = false
  }

  // 🌟 从云端加载真实统计数据
  async loadStats() {
    let currentUserId = this.getCurrentUserId()

    const plants = await apiService.getUserPlants(currentUserId)
    this.plantCount = plants.length

    let totalLogs = 0
    const entries: PlantNameEntry[] = []

    for (const p of plants) {
      // 🌟 修复：必须加上 PlantNameEntry 类型声明
      let entry: PlantNameEntry = { id: p.id, name: p.name }
      entries.push(entry)

      const records = await apiService.getPlantRecords(p.id)
      totalLogs += records.length
    }

    this.logCount = totalLogs
    this.plantNameEntries = entries
  }

  async loadReminders() {
    let currentUserId = this.getCurrentUserId()
    this.reminders = await dbService.getPendingReminders(currentUserId)
  }

  getPlantName(plantId: number): string {
    for (const entry of this.plantNameEntries) {
      if (entry.id === plantId) {
        return entry.name
      }
    }
    return '植物'
  }

  async completeReminder(reminder: CareReminder) {
    await dbService.markReminderDone(reminder.id)
    await this.loadReminders()
    promptAction.showToast({ message: '已标记完成', duration: 1500 })
  }

  doLogout() {
    AppStorage.delete('jwt_token')
    AppStorage.delete('current_user_id')
    router.replaceUrl({ url: 'pages/LoginPage' })
    promptAction.showToast({ message: '已安全退出登录' })
  }

  // 🌟 导出日记也切换到了云端拉取，确保证据完整
  async exportDiary() {
    let currentUserId = this.getCurrentUserId()
    const plants: Plant[] = await apiService.getUserPlants(currentUserId)
    let content = `植物成长日记导出\n导出时间：${formatDate(new Date().toISOString())}\n${'='.repeat(40)}\n\n`
    for (const plant of plants) {
      content += `【${plant.name}】${plant.species ? `（${plant.species}）` : ''}\n`
      content += `创建时间：${formatDate(plant.createdAt)}\n`
      const logs: GrowthLog[] = await apiService.getPlantRecords(plant.id)
      for (const log of logs) {
        content += `\n  ${formatDate(log.recordedAt)} ${log.emotionTag}\n`
        if (log.note) content += `  ${log.note}\n`
        if (log.aiAnalysis) content += `  [AI] ${log.aiAnalysis}\n`
      }
      content += '\n' + '-'.repeat(30) + '\n'
    }
    const path = await fileService.exportLogsToText(content)
    if (path) {
      promptAction.showToast({ message: `已成功保存到设备 📄`, duration: 3000 })
    } else {
      promptAction.showToast({ message: '导出已取消或失败', duration: 2000 })
    }
  }

  @Builder
  MenuRow(icon: string, label: string, badge: string, action: () => void) {
    Row({ space: 12 }) {
      Text(icon).fontSize(20)
      Text(label).fontSize(15).layoutWeight(1).fontColor('#333')
      if (badge) {
        Text(badge)
          .fontSize(11)
          .fontColor(Color.White)
          .backgroundColor(AppTheme.WARNING)
          .padding({ left: 6, right: 6, top: 2, bottom: 2 })
          .borderRadius(8)
      }
      Text('›').fontSize(18).fontColor('#BBBBBB')
    }
    .width('100%')
    .height(52)
    .padding({ left: 16, right: 16 })
    .backgroundColor(AppTheme.CARD)
    .onClick(action)
  }

  @Builder
  ReminderPanel() {
    if (this.showReminders) {
      Column({ space: 8 }) {
        Text('待办养护')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor(AppTheme.PRIMARY_DARK)
          .width('100%')
        if (this.reminders.length === 0) {
          Text('暂无待办，继续保持！')
            .fontSize(13)
            .fontColor(AppTheme.MUTED)
        } else {
          ForEach(this.reminders, (r: CareReminder) => {
            Row() {
              Column({ space: 4 }) {
                Text(`${this.getPlantName(r.plantId)} · ${getReminderLabel(r.reminderType)}`)
                  .fontSize(14)
                  .fontColor('#333')
                Text(formatDate(r.remindAt))
                  .fontSize(11)
                  .fontColor(AppTheme.MUTED)
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)
              Button('完成')
                .height(30)
                .fontSize(12)
                .backgroundColor(AppTheme.PRIMARY)
                .fontColor(Color.White)
                .onClick(() => this.completeReminder(r))
            }
            .width('100%')
            .padding(12)
            .backgroundColor('#F9FBE7')
            .borderRadius(10)
          }, (r: CareReminder) => `${r.id}`)
        }
      }
      .width('100%')
      .padding(16)
      .backgroundColor(AppTheme.CARD)
      .borderRadius(AppTheme.RADIUS_CARD)
      .margin({ left: 16, right: 16, top: 12 })
    }
  }

  build() {
    Column() {
      Scroll() {
        Column({ space: 0 }) {
          Column({ space: 16 }) {
            Stack({ alignContent: Alignment.BottomEnd }) {
              if (this.avatarPath) {
                Image('file://' + this.avatarPath)
                  .width(80)
                  .height(80)
                  .borderRadius(40)
                  .objectFit(ImageFit.Cover)
              } else {
                Column() {
                  Text(this.userName.substring(0, 1).toUpperCase())
                    .fontSize(32)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(AppTheme.PRIMARY)
                }
                .width(80)
                .height(80)
                .borderRadius(40)
                .backgroundColor('#C8E6C9')
                .justifyContent(FlexAlign.Center)
              }
              Text('📷')
                .fontSize(12)
                .backgroundColor(Color.White)
                .borderRadius(10)
                .padding(4)
                .offset({ x: 4, y: 4 })
                .shadow({ radius: 2, color: 'rgba(0,0,0,0.2)', offsetY: 1 })
            }
            .onClick(() => {
              this.changeAvatar()
            })

            if (this.editingName) {
              Row({ space: 10 }) {
                TextInput({ text: this.tempName })
                  .onChange((v) => { this.tempName = v })
                  .height(36)
                  .layoutWeight(1)
                  .borderRadius(18)
                  .backgroundColor('#F5F5F5')
                  .fontSize(15)
                Button('确定')
                  .height(36)
                  .backgroundColor(AppTheme.PRIMARY)
                  .fontColor(Color.White)
                  .borderRadius(18)
                  .onClick(() => this.saveUserName(this.tempName))
              }
              .padding({ left: 40, right: 40 })
            } else {
              Text(this.userName)
                .fontSize(20)
                .fontWeight(FontWeight.Medium)
                .onClick(() => {
                  this.tempName = this.userName
                  this.editingName = true
                })
              Text('点击修改昵称').fontSize(12).fontColor('#AAAAAA')
            }
          }
          .width('100%')
          .padding({ top: 48, bottom: 32 })
          .backgroundColor(AppTheme.BG)
          .alignItems(HorizontalAlign.Center)

          Row({ space: 12 }) {
            ProfileStatCard({ label: '我的植物', value: this.plantCount, icon: '🪴' })
            ProfileStatCard({ label: '成长记录', value: this.logCount, icon: '📷' })
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 20, bottom: 20 })
          .backgroundColor(AppTheme.BG)

          Column({ space: 12 }) {
            Text('🎖️ 种植成就').fontSize(16).fontWeight(FontWeight.Bold).fontColor('#333').width('100%')
            Row({ space: 12 }) {
              ProfileBadgeCard({ icon: '🌱', label: '初级园丁', unlocked: this.plantCount >= 1, showBadges: this.showBadges })
              ProfileBadgeCard({ icon: '💧', label: '浇水能手', unlocked: this.plantCount >= 3, showBadges: this.showBadges })
              ProfileBadgeCard({ icon: '🤖', label: 'AI探索者', unlocked: this.logCount >= 1, showBadges: this.showBadges })
              ProfileBadgeCard({ icon: '👑', label: '植物大师', unlocked: this.plantCount >= 10, showBadges: this.showBadges })
            }
            .width('100%')
            .justifyContent(FlexAlign.SpaceAround)
          }
          .width('100%')
          .padding({ left: 16, right: 16, bottom: 20 })
          .backgroundColor(AppTheme.BG)

          Column({ space: 1 }) {
            this.MenuRow('📤', '导出日记', '', (): void => { this.exportDiary() })
            Divider().color('#F0F0F0').height(1)
            this.MenuRow(
              '🔔',
              '养护提醒',
              this.reminders.length > 0 ? `${this.reminders.length}` : '',
              () => { this.showReminders = !this.showReminders }
            )
            Divider().color('#F0F0F0').height(1)
            this.MenuRow('🌿', '关于植物成长日记', '', () => {
              promptAction.showDialog({
                title: '植物成长日记',
                message: 'AI 驱动的个人植物档案：识别品种、记录成长、智能分析与浇水提醒。',
                buttons: [{ text: '知道了', color: AppTheme.PRIMARY }]
              })
            })
          }
          .backgroundColor(AppTheme.CARD)
          .borderRadius(AppTheme.RADIUS_CARD)
          .margin({ left: 16, right: 16 })
          .clip(true)

          this.ReminderPanel()

          Button('退出登录')
            .width('calc(100% - 32vp)')
            .height(50)
            .backgroundColor(Color.White)
            .fontColor('#E53935')
            .fontSize(16)
            .margin({ top: 24, bottom: 20 })
            .borderRadius(AppTheme.RADIUS_CARD)
            .shadow(AppTheme.SHADOW)
            .onClick(() => {
              promptAction.showDialog({
                title: '退出登录',
                message: '确定要退出当前账号吗？',
                buttons: [
                  { text: '取消', color: '#888888' },
                  { text: '确定退出', color: '#E53935' }
                ]
              }).then(data => {
                if (data.index === 1) {
                  this.doLogout()
                }
              })
            })

          Blank().height(80)
        }
      }
      .layoutWeight(1)
      .backgroundColor(AppTheme.BG)
    }
    .width('100%')
    .height('100%')
  }
}