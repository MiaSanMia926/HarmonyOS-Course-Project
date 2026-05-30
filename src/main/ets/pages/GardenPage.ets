// pages/GardenPage.ets
import { dbService } from '../service/DatabaseService'
import { notificationService } from '../service/NotificationService'
import { prefsService } from '../service/PreferencesService'
import { apiService } from '../service/ApiService'
import { Plant, getHealthLabel, CareReminderInsert } from '../model/PlantModel'
import { daysAgo } from '../utils/DateUtils'
import { AppTheme } from '../common/AppTheme'
import { AnimationUtils } from '../common/AnimationUtils'
import router from '@ohos.router'
import promptAction from '@ohos.promptAction'

@Component
export default struct GardenPage {
  @State plants: Plant[] = []
  @State loading: boolean = true
  @State refreshing: boolean = false
  @State dailyTip: string = '正在获取今日养护灵感...'

  @State isCardsAppeared: boolean[] = []

  @Prop @Watch('onUpdateTriggered') updateTrigger: number = 0

  onUpdateTriggered() {
    this.loadPlants()
  }

  aboutToAppear() {
    this.loadPlants()
  }

  async loadPlants() {
    this.loading = true
    let rawId = AppStorage.get<number | string>('current_user_id')
    let currentUserId: number = Number(rawId) || 0

    this.plants = await apiService.getUserPlants(currentUserId)

    if (this.isCardsAppeared.length === 0) {
      this.isCardsAppeared = new Array(this.plants.length).fill(false)
    } else {
      this.isCardsAppeared = new Array(this.plants.length).fill(true)
    }

    this.loading = false
    await this.checkWaterReminders()
    await this.loadDailyTip()
  }

  async onRefresh() {
    this.refreshing = true
    await this.loadPlants()
    this.refreshing = false
  }

  async loadDailyTip() {
    if (this.plants.length === 0) {
      this.dailyTip = '添加第一株植物，AI 会为你生成专属养护小贴士 🌱'
      return
    }
    const pick = this.plants[Math.floor(Math.random() * this.plants.length)]
    this.dailyTip = await apiService.getDailyTip(pick.name, pick.species)
  }

  async checkWaterReminders() {
    for (const plant of this.plants) {
      if (!plant.lastWateredAt) {
        continue
      }
      const diffDays = Math.floor((Date.now() - new Date(plant.lastWateredAt).getTime()) / 86400000)
      if (diffDays >= plant.waterIntervalDays) {
        const should = await prefsService.shouldNotifyWaterToday(plant.id)
        if (should) {
          await notificationService.sendWaterReminder(plant.name)
          await prefsService.markWaterNotifiedToday(plant.id)
          const reminder: CareReminderInsert = {
            plantId: plant.id,
            reminderType: 'water',
            remindAt: new Date().toISOString(),
            isDone: 0
          }
          await dbService.insertReminder(reminder)
        }
      }
    }
  }

  healthColor(status: string): string {
    if (status === 'healthy') {
      return AppTheme.HEALTHY
    }
    if (status === 'warning') {
      return AppTheme.WARNING
    }
    return '#9E9E9E'
  }

  healthBg(status: string): string {
    if (status === 'healthy') {
      return '#E8F5E9'
    }
    if (status === 'warning') {
      return '#FFF3E0'
    }
    return '#F5F5F5'
  }

  waterUrgency(plant: Plant): string {
    if (!plant.lastWateredAt) {
      return '待记录浇水'
    }
    const diff = Math.floor((Date.now() - new Date(plant.lastWateredAt).getTime()) / 86400000)
    if (diff >= plant.waterIntervalDays) {
      return '该浇水了'
    }
    return `上次浇水 ${daysAgo(plant.lastWateredAt)}`
  }

  async quickWater(plant: Plant) {
    // 🌟 换成云端浇水
    const success = await apiService.waterPlant(plant.id)
    if (success) {
      promptAction.showToast({ message: `已为 ${plant.name} 浇水 💧` })
      this.loadPlants()
    } else {
      promptAction.showToast({ message: `记录失败，请重试` })
    }
  }

  @Builder
  PlantCard(plant: Plant, index: number) {
    Column({ space: 0 }) {
      Stack({ alignContent: Alignment.TopEnd }) {
        if (plant.cover_image) {
          Image(`data:image/jpeg;base64,${plant.cover_image}`)
            .width('100%')
            .height(140)
            .objectFit(ImageFit.Cover)
            .borderRadius({ topLeft: AppTheme.RADIUS_CARD, topRight: AppTheme.RADIUS_CARD })
        } else {
          Column() {
            Text('🌱').fontSize(48)
          }
          .width('100%')
          .height(140)
          .justifyContent(FlexAlign.Center)
          .backgroundColor('#E8F5E9')
          .borderRadius({ topLeft: AppTheme.RADIUS_CARD, topRight: AppTheme.RADIUS_CARD })
        }

        Text(getHealthLabel(plant.healthStatus))
          .fontSize(11)
          .fontColor(this.healthColor(plant.healthStatus))
          .backgroundColor(this.healthBg(plant.healthStatus))
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .borderRadius(12)
          .margin({ top: 8, right: 8 })
          .shadow({ radius: 4, color: 'rgba(0,0,0,0.1)', offsetY: 2 })
      }
      .width('100%')

      Column({ space: 6 }) {
        Text(plant.name)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text(plant.species || '品种待识别')
          .fontSize(12)
          .fontColor(AppTheme.MUTED)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Row({ space: 4 }) {
          Text('💧').fontSize(12)
          Text(this.waterUrgency(plant))
            .fontSize(11)
            .fontColor(diffDaysOverdue(plant) ? AppTheme.WARNING : AppTheme.MUTED)

          Blank()

          Button('浇水')
            .height(26)
            .fontSize(11)
            .backgroundColor(AppTheme.PRIMARY_LIGHT)
            .fontColor(AppTheme.PRIMARY_DARK)
            .borderRadius(13)
            .onClick((event) => {
              this.quickWater(plant)
            })
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
        .margin({ top: 4 })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .padding({ left: 14, right: 14, top: 12, bottom: 14 })
    }
    .width('100%')
    .backgroundColor(AppTheme.CARD)
    .borderRadius(AppTheme.RADIUS_CARD)
    .shadow(AppTheme.SHADOW)
    .opacity(this.isCardsAppeared[index] ? 1 : 0)
    .scale({ x: this.isCardsAppeared[index] ? 1 : 0.9, y: this.isCardsAppeared[index] ? 1 : 0.9 })
    .onAppear(() => {
      setTimeout(() => {
        animateTo({ duration: 500, curve: AnimationUtils.SPRING_HEAVY }, () => {
          this.isCardsAppeared[index] = true
        })
      }, AnimationUtils.getStaggerDelay(index, 60))
    })
    .onClick(() => {
      router.pushUrl({ url: 'pages/PlantDetailPage', params: { plantId: plant.id } })
    })
  }

  @Builder
  HealthMap() {
    if (this.plants.length > 0) {
      Row() {
        Row() {
          if (this.plants.filter(p => p.healthStatus === 'healthy').length > 0) {
            Column().width(`${(this.plants.filter(p => p.healthStatus === 'healthy').length / this.plants.length) * 100}%`).height('100%').backgroundColor(AppTheme.HEALTHY)
          }
          if (this.plants.filter(p => p.healthStatus === 'warning').length > 0) {
            Column().width(`${(this.plants.filter(p => p.healthStatus === 'warning').length / this.plants.length) * 100}%`).height('100%').backgroundColor(AppTheme.WARNING)
          }
        }
        .layoutWeight(1)
        .height(6)
        .borderRadius(3)
        .clip(true)
        .margin({ right: 12 })

        Text(`健康率 ${Math.round((this.plants.filter(p => p.healthStatus === 'healthy').length / this.plants.length) * 100)}%`)
          .fontSize(12)
          .fontColor(AppTheme.PRIMARY_DARK)
          .fontWeight(FontWeight.Medium)
      }
      .width('100%')
      .padding({ left: 16, right: 16, bottom: 8 })
    }
  }

  build() {
    Column() {
      Row() {
        Column({ space: 2 }) {
          Text('我的花园')
            .fontSize(26)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppTheme.PRIMARY_DARK)
          Text(`共 ${this.plants.length} 株植物`)
            .fontSize(13)
            .fontColor(AppTheme.MUTED)
        }
        .alignItems(HorizontalAlign.Start)

        Blank()

        Button('＋ 添加')
          .height(36)
          .fontSize(13)
          .backgroundColor(AppTheme.PRIMARY)
          .fontColor(Color.White)
          .borderRadius(18)
          .onClick(() => router.pushUrl({ url: 'pages/AddPlantPage' }))
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 56, bottom: 12 })

      this.HealthMap()

      Row({ space: 8 }) {
        Text('💡').fontSize(16)
        Text(this.dailyTip)
          .fontSize(13)
          .fontColor('#5D4037')
          .layoutWeight(1)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .width('100%')
      .backgroundColor(AppTheme.TIP_BG)
      .borderRadius(10)
      .padding({ left: 14, right: 14, top: 10, bottom: 10 })
      .margin({ left: 16, right: 16, bottom: 16 })

      Refresh({ refreshing: this.refreshing }) {
        if (this.loading) {
          Column() {
            LoadingProgress().width(48).height(48).color(AppTheme.PRIMARY)
            Text('加载中...').fontSize(14).fontColor(AppTheme.MUTED).margin({ top: 12 })
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
        } else if (this.plants.length === 0) {
          Column({ space: 16 }) {
            Text('🪴').fontSize(72)
            Text('花园还是空的').fontSize(18).fontColor('#666')
            Text('点击右上角添加你的第一株植物').fontSize(14).fontColor('#AAA')
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
        } else {
          Grid() {
            ForEach(this.plants, (plant: Plant, index: number) => {
              GridItem() {
                this.PlantCard(plant, index)
              }
            }, (plant: Plant) => `${plant.id}`)
          }
          .columnsTemplate('1fr 1fr')
          .columnsGap(12)
          .rowsGap(12)
          .padding({ left: 16, right: 16, bottom: 80 })
          .layoutWeight(1)
        }
      }
      .layoutWeight(1)
      .onRefreshing(() => this.onRefresh())
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppTheme.BG)
  }
}

function diffDaysOverdue(plant: Plant): boolean {
  if (!plant.lastWateredAt) {
    return false
  }
  const diff = Math.floor((Date.now() - new Date(plant.lastWateredAt).getTime()) / 86400000)
  return diff >= plant.waterIntervalDays
}