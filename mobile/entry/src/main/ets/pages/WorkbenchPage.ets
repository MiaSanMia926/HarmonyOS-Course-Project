// pages/WorkbenchPage.ets
import { dbService } from '../service/DatabaseService'
import { CareReminder, getReminderLabel } from '../model/PlantModel'
import { AppTheme } from '../common/AppTheme'
import { formatDate } from '../utils/DateUtils'
import router from '@ohos.router'
import promptAction from '@ohos.promptAction'
import picker from '@ohos.file.picker'

@Component
export default struct WorkbenchPage {
  @State reminders: CareReminder[] = []
  @State plantsMap: Map<number, string> = new Map()
  @Prop @Watch('onTabActivated') currentTabIndex: number = 0
  @Prop @Watch('onUpdateTriggered') updateTrigger: number = 0

  onUpdateTriggered() {
    this.loadData()
  }

  onTabActivated() {
    if (this.currentTabIndex === 2) {
      this.loadData()
    }
  }

  aboutToAppear() {
    this.loadData()
  }

  async loadData() {
    let currentUserId = Number(AppStorage.get<number | string>('current_user_id')) || 0
    this.reminders = await dbService.getPendingReminders(currentUserId)
    const plantList = await dbService.getAllPlants(currentUserId)
    const pMap = new Map<number, string>()
    plantList.forEach(p => pMap.set(p.id, p.name))
    this.plantsMap = pMap
  }

  async completeReminder(reminder: CareReminder) {
    await dbService.markReminderDone(reminder.id)
    promptAction.showToast({ message: '任务已完成 🌿' })
    await this.loadData()
  }

  async pickAndGo(isHealthCheck: boolean) {
    try {
      let documentSelectOptions = new picker.DocumentSelectOptions()
      documentSelectOptions.maxSelectNumber = 1
      documentSelectOptions.fileSuffixFilters = ['.png', '.jpg', '.jpeg']

      let documentViewPicker = new picker.DocumentViewPicker()
      let documentSelectResult = await documentViewPicker.select(documentSelectOptions)

      if (documentSelectResult && documentSelectResult.length > 0) {
        let selectedUri = documentSelectResult[0]
        router.pushUrl({
          url: 'pages/AddPlantPage',
          params: { imageUri: selectedUri, isHealthCheck: isHealthCheck }
        })
      }
    } catch (e) {
      console.error('Picker error:', e)
    }
  }

  build() {
    Column() {
      Row() {
        Text('工作台')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppTheme.PRIMARY_DARK)
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 56, bottom: 12 })

      Scroll() {
        Column({ space: 24 }) {
          // 1. 选图区域 (AI识别)
          Column({ space: 12 }) {
            Text('📸 记录新植物')
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor('#333')
              .width('100%')

            Column({ space: 10 }) {
              Text('➕').fontSize(40).fontColor(AppTheme.PRIMARY)
              Text('点击选择照片 / 拍照').fontSize(15).fontWeight(FontWeight.Medium).fontColor('#333')
              Text('AI 将自动识别品种并生成专属养护方案').fontSize(12).fontColor(AppTheme.MUTED)
            }
            .width('100%')
            .height(140)
            .justifyContent(FlexAlign.Center)
            .backgroundColor('#F1F8E9')
            .borderRadius(16)
            .border({ width: 2, color: AppTheme.PRIMARY, style: BorderStyle.Dashed })
            .onClick(() => this.pickAndGo(false))
          }
          .width('100%')
          .padding({ left: 16, right: 16 })

          // 2. 今日待办
          Column({ space: 12 }) {
            Row() {
              Text('✅ 今日待办').fontSize(16).fontWeight(FontWeight.Bold).fontColor('#333')
              Blank()
              Text(`共 ${this.reminders.length} 项`).fontSize(13).fontColor(AppTheme.MUTED)
            }
            .width('100%')

            if (this.reminders.length === 0) {
              Column({ space: 8 }) {
                Text('🎉').fontSize(32)
                Text('今天没有待办任务，植物们都很健康！').fontSize(13).fontColor(AppTheme.MUTED)
              }
              .width('100%')
              .padding(24)
              .backgroundColor(Color.White)
              .borderRadius(16)
              .alignItems(HorizontalAlign.Center)
              .shadow(AppTheme.SHADOW)
            } else {
              ForEach(this.reminders, (r: CareReminder) => {
                Row({ space: 12 }) {
                  Text(r.reminderType === 'water' ? '💧' : (r.reminderType === 'fertilize' ? '🌿' : '✂️')).fontSize(24)
                  Column({ space: 4 }) {
                    Text(`${this.plantsMap.get(r.plantId) || '未知植物'} - ${getReminderLabel(r.reminderType)}`)
                      .fontSize(15).fontWeight(FontWeight.Medium).fontColor('#333')
                    Text(`计划时间: ${formatDate(r.remindAt)}`)
                      .fontSize(12).fontColor(AppTheme.MUTED)
                  }
                  .alignItems(HorizontalAlign.Start)
                  .layoutWeight(1)

                  Button('完成')
                    .height(32)
                    .fontSize(13)
                    .backgroundColor(AppTheme.PRIMARY)
                    .fontColor(Color.White)
                    .borderRadius(16)
                    .onClick(() => this.completeReminder(r))
                }
                .width('100%')
                .padding(16)
                .backgroundColor(Color.White)
                .borderRadius(16)
                .shadow(AppTheme.SHADOW)
              }, (r: CareReminder) => `${r.id}`)
            }
          }
          .width('100%')
          .padding({ left: 16, right: 16 })

          // 3. 快捷工具
          Column({ space: 12 }) {
            Text('🛠️ 快捷工具').fontSize(16).fontWeight(FontWeight.Bold).fontColor('#333').width('100%')

            Row({ space: 12 }) {
              Column({ space: 8 }) {
                Text('🩺').fontSize(28)
                Text('AI 健康体检').fontSize(14).fontWeight(FontWeight.Medium).fontColor('#333')
              }
              .layoutWeight(1)
              .height(90)
              .justifyContent(FlexAlign.Center)
              .backgroundColor('#FFF3E0')
              .borderRadius(12)
              .shadow(AppTheme.SHADOW)
              .onClick(() => this.pickAndGo(true))

              Column({ space: 8 }) {
                Text('📖').fontSize(28)
                Text('手动添加').fontSize(14).fontWeight(FontWeight.Medium).fontColor('#333')
              }
              .layoutWeight(1)
              .height(90)
              .justifyContent(FlexAlign.Center)
              .backgroundColor('#E3F2FD')
              .borderRadius(12)
              .shadow(AppTheme.SHADOW)
              .onClick(() => router.pushUrl({ url: 'pages/AddPlantPage' }))
            }
            .width('100%')
          }
          .width('100%')
          .padding({ left: 16, right: 16, bottom: 40 })

        }
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppTheme.BG)
  }
}