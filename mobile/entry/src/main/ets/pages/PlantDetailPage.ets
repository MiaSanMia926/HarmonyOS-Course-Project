// pages/PlantDetailPage.ets — 植物详情与成长轨迹
import { Plant, GrowthLog, AICarePlan } from '../model/PlantModel'
import { formatDate, formatDateTime, daysAgo } from '../utils/DateUtils'
import { AppTheme } from '../common/AppTheme'
import router from '@ohos.router'
import promptAction from '@ohos.promptAction'
import { apiService } from '../service/ApiService'

interface PlantDetailParams {
  plantId?: number
}

@Entry
@Component
struct PlantDetailPage {
  @State plant: Plant | null = null
  @State logs: GrowthLog[] = []
  @State loading: boolean = true
  @State carePlan: AICarePlan | null = null
  private plantId: number = 0

  aboutToAppear(): void {
    const params = router.getParams() as PlantDetailParams
    this.plantId = params.plantId ?? 0
    this.loadData()
  }

  onPageShow(): void {
    this.loadData()
  }

  async loadData(): Promise<void> {
    this.loading = true

    let rawId = AppStorage.get<number | string>('current_user_id')
    let currentUserId: number = Number(rawId) || 0

    try {
      const allPlants = await apiService.getUserPlants(currentUserId)
      const p = allPlants.find(item => item.id === this.plantId)

      if (p) {
        this.plant = p

        if (p.aiCarePlan) {
          try {
            this.carePlan = JSON.parse(p.aiCarePlan) as AICarePlan
          } catch (e) {
            this.carePlan = null
          }
        }

        try {
          this.logs = await apiService.getPlantRecords(this.plantId)
        } catch (error) {
          this.logs = []
          console.error('获取成长记录失败')
        }
      }
    } catch (error) {
      console.error('网络请求失败', error)
    }

    this.loading = false
  }

  deletePlant(): void {
    promptAction.showDialog({
      title: '删除植物',
      message: '确定要将这株植物及其所有成长记录彻底删除吗？该操作不可恢复。',
      buttons: [
        { text: '取消', color: '#888888' },
        { text: '确定删除', color: '#E53935' }
      ]
    }).then(async (data) => {
      if (data.index === 1) {
        // 🌟 换成云端删除
        const success = await apiService.deletePlant(this.plantId)
        if (success) {
          promptAction.showToast({ message: '植物档案已安全移除 🪴', duration: 1500 })
          router.back()
        } else {
          promptAction.showToast({ message: '移除失败，请检查网络', duration: 1500 })
        }
      }
    })
  }

  async doWater(): Promise<void> {
    if (!this.plant) return
    // 🌟 换成云端浇水
    const success = await apiService.waterPlant(this.plantId)
    if (success) {
      promptAction.showToast({ message: '已记录本次浇水 💧', duration: 1500 })
      this.loadData()
    } else {
      promptAction.showToast({ message: '浇水记录失败，请检查网络', duration: 1500 })
    }
  }

  @Builder
  InfoGridItem(icon: string, label: string, value: string): void {
    Column({ space: 4 }) {
      Text(icon).fontSize(22)
      Text(label).fontSize(11).fontColor(AppTheme.MUTED)
      Text(value).fontSize(13).fontWeight(FontWeight.Medium).fontColor('#333')
    }
    .width('100%')
    .padding(12)
    .backgroundColor('#F1F8E9')
    .borderRadius(10)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  LogTimelineRow(item: GrowthLog): void {
    Row() {
      Column() {
        Circle({ width: 10, height: 10 }).fill(AppTheme.PRIMARY)
        Line().width(2).layoutWeight(1).backgroundColor('#E0E0E0').margin({ top: 4, bottom: 4 })
      }
      .margin({ right: 12 })
      .alignItems(HorizontalAlign.Center)

      Column({ space: 8 }) {
        Row() {
          Text(formatDate(item.recordedAt))
            .fontSize(12)
            .fontColor(AppTheme.MUTED)
          Blank()
          if (item.emotionTag) {
            Text(item.emotionTag)
              .fontSize(11)
              .fontColor(AppTheme.PRIMARY)
              .backgroundColor('#E8F5E9')
              .padding({ left: 6, right: 6, top: 2, bottom: 2 })
              .borderRadius(6)
          }
        }
        .width('100%')

        if (item.imagePath) {
          Image(item.imagePath)
            .width('100%')
            .height(120)
            .objectFit(ImageFit.Cover)
            .borderRadius(8)
        }

        if (item.note) {
          Text(item.note)
            .fontSize(14)
            .fontColor('#444')
            .lineHeight(20)
        }

        if (item.aiAnalysis) {
          Row({ space: 4 }) {
            Text('🤖').fontSize(12)
            Text(item.aiAnalysis)
              .fontSize(12)
              .fontColor('#555')
              .layoutWeight(1)
              .lineHeight(18)
          }
          .width('100%')
          .backgroundColor(AppTheme.AI_BG)
          .borderRadius(6)
          .padding(8)
        }
      }
      .layoutWeight(1)
      .backgroundColor(Color.White)
      .borderRadius(10)
      .padding(12)
      .shadow({ radius: 4, color: '#05000000', offsetY: 1 })
      .margin({ bottom: 16 })
    }
    .width('100%')
    .alignItems(VerticalAlign.Top)
  }

  build() {
    Column() {
      Row() {
        Button('←')
          .backgroundColor(Color.Transparent)
          .fontColor('#333')
          .fontSize(22)
          .onClick(() => {
            router.back()
          })
        Text(this.plant?.name ?? '植物详情')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
        Button('🗑️')
          .backgroundColor(Color.Transparent)
          .fontColor('#E53935')
          .fontSize(18)
          .onClick(() => {
            this.deletePlant()
          })
      }
      .width('100%')
      .height(56)
      .padding({ left: 8, right: 12 })
      .backgroundColor(Color.White)

      if (this.loading && !this.plant) {
        Column() {
          LoadingProgress().width(40).height(40).color(AppTheme.PRIMARY)
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else if (!this.plant) {
        Column() {
          Text('未找到该植物档案').fontSize(14).fontColor(AppTheme.MUTED)
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        Scroll() {
          Column({ space: 16 }) {
            Column() {
              if (this.plant!.cover_image) {
                // ✅ 修复：拼上 base64 前缀
                Image(`data:image/jpeg;base64,${this.plant!.cover_image}`)
                  .width('100%')
                  .height(200)
                  .objectFit(ImageFit.Cover)
                  .borderRadius({ topLeft: 14, topRight: 14 })
              }

              Column({ space: 6 }) {
                Row() {
                  Text(this.plant!.name)
                    .fontSize(20)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(AppTheme.PRIMARY_DARK)
                  Blank()
                  Text(this.plant!.healthStatus === 'healthy' ? '🟢 健康' : '🟡 注意')
                    .fontSize(12)
                    .fontWeight(FontWeight.Medium)
                    .fontColor(this.plant!.healthStatus === 'healthy' ? AppTheme.HEALTHY : AppTheme.WARNING)
                    .backgroundColor(this.plant!.healthStatus === 'healthy' ? '#E8F5E9' : '#FFF3E0')
                    .padding({ left: 8, right: 8, top: 4, bottom: 4 })
                    .borderRadius(10)
                }
                .width('100%')

                if (this.plant!.species) {
                  Text(`学名/品种：${this.plant!.species}`)
                    .fontSize(13)
                    .fontColor(AppTheme.MUTED)
                    .width('100%')
                }
              }
              .padding(16)
              .width('100%')
            }
            .backgroundColor(Color.White)
            .borderRadius(14)
            .shadow(AppTheme.SHADOW)

            Column({ space: 12 }) {
              Text('智能养护指标')
                .fontSize(14)
                .fontWeight(FontWeight.Medium)
                .fontColor(AppTheme.PRIMARY_DARK)
                .width('100%')

              Column({ space: 8 }) {
                Row({ space: 8 }) {
                  Column() {
                    this.InfoGridItem('💧', '浇水周期', `每 ${this.plant!.waterIntervalDays} 天`)
                  }.layoutWeight(1)

                  Column() {
                    this.InfoGridItem('⏰', '状态更新', daysAgo(this.plant!.lastWateredAt ? this.plant!.lastWateredAt : this.plant!.createdAt) + (this.plant!.lastWateredAt ? '浇过水' : '建档'))
                  }.layoutWeight(1)
                }
                .width('100%')

                Row({ space: 8 }) {
                  Column() {
                    this.InfoGridItem('☀️', '推荐光照', this.carePlan?.sunlight ?? '适中')
                  }.layoutWeight(1)

                  Column() {
                    this.InfoGridItem('🌿', '推荐施肥', this.carePlan?.fertilize ?? '按季')
                  }.layoutWeight(1)
                }
                .width('100%')
              }
              .width('100%')

              if (this.carePlan?.tips) {
                Text(`💡 养护建议：${this.carePlan!.tips}`)
                  .fontSize(13)
                  .fontColor('#555')
                  .lineHeight(20)
                  .backgroundColor(AppTheme.TIP_BG)
                  .padding(12)
                  .borderRadius(10)
                  .width('100%')
              }
            }
            .backgroundColor(Color.White)
            .borderRadius(14)
            .padding(14)
            .shadow(AppTheme.SHADOW)

            Row({ space: 12 }) {
              Button('💧 记录浇水')
                .layoutWeight(1)
                .height(46)
                .backgroundColor(AppTheme.PRIMARY)
                .fontColor(Color.White)
                .borderRadius(12)
                .onClick(() => {
                  this.doWater()
                })

              Button('🤖 生长对比')
                .layoutWeight(1)
                .height(46)
                .backgroundColor('#FFF')
                .fontColor(AppTheme.PRIMARY)
                .border({ width: 1, color: AppTheme.PRIMARY })
                .borderRadius(12)
                .onClick(() => {
                  router.pushUrl({ url: 'pages/AIAnalysisPage', params: { plantId: this.plantId } })
                })
            }
            .width('100%')

            Column({ space: 12 }) {
              Row() {
                Text('成长轨迹时间线')
                  .fontSize(15)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(AppTheme.PRIMARY_DARK)
                Blank()
                Button('＋ 写日记')
                  .height(28)
                  .fontSize(12)
                  .backgroundColor('#E8F5E9')
                  .fontColor(AppTheme.PRIMARY)
                  .borderRadius(14)
                  .onClick(() => {
                    router.pushUrl({
                      url: 'pages/LogWritePage',
                      params: { plantId: this.plantId, plantName: this.plant?.name }
                    })
                  })
              }
              .width('100%')
              .margin({ bottom: 4 })

              if (this.logs.length === 0) {
                Column({ space: 8 }) {
                  Text('📭').fontSize(32)
                  Text('还没有留下成长脚印').fontSize(12).fontColor(AppTheme.MUTED)
                }
                .width('100%')
                .padding({ top: 20, bottom: 20 })
                .alignItems(HorizontalAlign.Center)
              } else {
                ForEach(this.logs, (item: GrowthLog) => {
                  this.LogTimelineRow(item)
                }, (item: GrowthLog) => `${item.id}`)
              }
            }
            .width('100%')

            Blank().height(40)
          }
          .padding(16)
        }
        .layoutWeight(1)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppTheme.BG)
  }
}