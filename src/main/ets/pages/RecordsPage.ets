// pages/RecordsPage.ets — 全局成长记录时间线
import { dbService } from '../service/DatabaseService'
import { apiService } from '../service/ApiService' // 🌟 引入云端 API
import { GrowthLogItem } from '../model/PlantModel'
import { formatDateTime } from '../utils/DateUtils'
import { AppTheme } from '../common/AppTheme'
import { AnimationUtils } from '../common/AnimationUtils'
import router from '@ohos.router'

interface PlantStat {
  name: string
  count: number
  maxCount: number
}

@Component
export default struct RecordsPage {
  @State logs: GrowthLogItem[] = []
  @State loading: boolean = true
  @State refreshing: boolean = false
  @State totalLogCount: number = 0

  // 数据看板相关状态
  @State aiAnalysisCount: number = 0
  @State emotionData: number[] = []
  @State plantLogStats: PlantStat[] = []
  @State showDashboard: boolean = true

  // 动画状态
  @State isLogsAppeared: boolean[] = []

  @Prop @Watch('onTabActivated') currentTabIndex: number = 0
  @Prop @Watch('onUpdateTriggered') updateTrigger: number = 0

  onUpdateTriggered() {
    this.loadLogs()
  }

  onTabActivated() {
    if (this.currentTabIndex === 1) {
      this.loadLogs()
    }
  }

  aboutToAppear() {
    this.loadLogs()
  }

  async loadLogs() {
    this.loading = true

    let rawId = AppStorage.get<number | string>('current_user_id')
    let currentUserId: number = Number(rawId) || 0

    // 1. 从云端拉取用户的所有植物
    const plants = await apiService.getUserPlants(currentUserId)
    let allLogs: GrowthLogItem[] = []

    // 2. 遍历拉取云端记录（🌟 修复：不再使用 ...log 对象展开，手动赋值）
    for (const plant of plants) {
      const records = await apiService.getPlantRecords(plant.id)
      const items: GrowthLogItem[] = records.map((log) => {
        let item: GrowthLogItem = {
          id: log.id,
          plantId: log.plantId,
          note: log.note,
          imagePath: log.imagePath,
          aiAnalysis: log.aiAnalysis,
          emotionTag: log.emotionTag,
          recordedAt: log.recordedAt,
          plantName: plant.name
        }
        return item
      })
      allLogs.push(...items) // 数组的展开是允许的
    }

    // 3. 按时间倒序排列
    allLogs.sort((a, b) => new Date(b.recordedAt).getTime() - new Date(a.recordedAt).getTime())

    this.logs = allLogs
    this.totalLogCount = allLogs.length

    // 📊 计算统计数据供数据看板使用
    let aiCount = 0
    let emotionMap = new Map<string, number>()
    let plantLogMap = new Map<string, number>()

    this.logs.forEach(log => {
      if (log.aiAnalysis) { aiCount++ }
      let emotion = log.emotionTag || '日常'
      emotionMap.set(emotion, (emotionMap.get(emotion) || 0) + 1)
      let plant = log.plantName || '未知'
      plantLogMap.set(plant, (plantLogMap.get(plant) || 0) + 1)
    })

    this.aiAnalysisCount = aiCount
    let eData: number[] = []
    emotionMap.forEach((val) => eData.push(val))
    this.emotionData = eData.length > 0 ? eData : [1]

    let pStats: PlantStat[] = []
    let maxCount = 1
    plantLogMap.forEach((val, key) => {
      if (val > maxCount) { maxCount = val }
      // 🌟 修复：明确声明对象的类型为 PlantStat
      let stat: PlantStat = { name: key, count: val, maxCount: 0 }
      pStats.push(stat)
    })

    pStats.sort((a, b) => b.count - a.count)
    this.plantLogStats = pStats.slice(0, 5).map(item => {
      item.maxCount = maxCount
      return item
    })

    // 入场动画逻辑
    if (this.isLogsAppeared.length === 0) {
      this.isLogsAppeared = new Array(this.logs.length).fill(false)
    } else {
      this.isLogsAppeared = new Array(this.logs.length).fill(true)
    }

    this.loading = false
  }

  async onRefresh() {
    this.refreshing = true
    await this.loadLogs()
    this.refreshing = false
  }

  @Builder
  DashboardCard() {
    if (this.showDashboard && this.totalLogCount > 0) {
      Column({ space: 16 }) {
        Row() {
          Text('📊 数据看板')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppTheme.PRIMARY_DARK)
          Blank()
          Text('收起')
            .fontSize(13)
            .fontColor(AppTheme.MUTED)
            .onClick(() => this.showDashboard = false)
        }
        .width('100%')

        Row({ space: 12 }) {
          // 左侧：状态环形图
          Column({ space: 8 }) {
            Text('记录分布').fontSize(12).fontColor(AppTheme.MUTED)
            DataPanel({ values: this.emotionData, max: this.totalLogCount, type: DataPanelType.Circle })
              .width(70).height(70)
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Center)

          // 右侧：AI 诊断次数
          Column({ space: 8 }) {
            Text('AI 参与诊断').fontSize(12).fontColor(AppTheme.MUTED)
            Row({ space: 4 }) {
              Text(`${this.aiAnalysisCount}`).fontSize(28).fontWeight(FontWeight.Bold).fontColor(AppTheme.PRIMARY)
              Text('次').fontSize(12).fontColor(AppTheme.MUTED).margin({ bottom: 4 })
            }.alignItems(VerticalAlign.Bottom)
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Center)
        }
        .width('100%')
        .padding(16)
        .backgroundColor('#F1F8E9')
        .borderRadius(12)

        // 活跃植物柱状图
        if (this.plantLogStats.length > 0) {
          Column({ space: 12 }) {
            Text('近期最受宠 (记录次数)').fontSize(12).fontColor(AppTheme.MUTED).width('100%')
            Row() {
              ForEach(this.plantLogStats, (stat: PlantStat) => {
                Column({ space: 6 }) {
                  Stack({ alignContent: Alignment.Bottom }) {
                    Column()
                      .width(16).height(60)
                      .backgroundColor('#E8F5E9').borderRadius(8)
                    Column()
                      .width(16).height(Math.max(8, (stat.count / stat.maxCount) * 60))
                      .backgroundColor(AppTheme.PRIMARY).borderRadius(8)
                  }
                  Text(`${stat.count}`).fontSize(11).fontColor('#333').fontWeight(FontWeight.Medium)
                  Text(stat.name)
                    .fontSize(10)
                    .fontColor(AppTheme.MUTED)
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .width(40)
                    .textAlign(TextAlign.Center)
                }
              }, (stat: PlantStat) => stat.name)
            }
            .width('100%')
            .justifyContent(FlexAlign.SpaceAround)
          }
          .width('100%')
          .padding(16)
          .backgroundColor(Color.White)
          .borderRadius(12)
          .shadow({ radius: 4, color: '#05000000', offsetY: 2 })
        }
      }
      .width('100%')
      .padding(16)
      .backgroundColor(AppTheme.CARD)
      .borderRadius(AppTheme.RADIUS_CARD)
      .shadow(AppTheme.SHADOW)
      .margin({ bottom: 16 })
    }
  }

  @Builder
  LogCard(item: GrowthLogItem, index: number) {
    Row() {
      // 时间轴：图钉 + 手账风虚线
      Column() {
        Text('📍')
          .fontSize(18)
          .margin({ top: 4, right: 2 })
        Line()
          .width(2)
          .layoutWeight(1)
          .strokeDashArray([6, 4])
          .stroke('#D7CCC8')
          .strokeWidth(2)
          .margin({ top: 6, bottom: 4 })
      }
      .margin({ right: 12 })
      .alignItems(HorizontalAlign.Center)

      // 卡片主体
      Column({ space: 14 }) {
        Row() {
          Column({ space: 4 }) {
            Text(item.plantName)
              .fontSize(17)
              .fontWeight(FontWeight.Bold)
              .fontColor('#4E342E')
            Text(formatDateTime(item.recordedAt))
              .fontSize(11)
              .fontColor('#8D6E63')
          }
          .alignItems(HorizontalAlign.Start)

          Blank()

          // 不规则情绪贴纸
          if (item.emotionTag) {
            Text(item.emotionTag)
              .fontSize(11)
              .fontColor('#FFF')
              .backgroundColor('#FFAB91')
              .padding({ left: 10, right: 10, top: 5, bottom: 5 })
              .borderRadius({ topLeft: 12, bottomRight: 12, topRight: 4, bottomLeft: 4 })
          }
        }
        .width('100%')

        // 拍立得相框 + 半透明和纸胶带
        if (item.imagePath) {
          Stack({ alignContent: Alignment.Top }) {
            Column() {
              Image(item.imagePath)
                .width('100%')
                .height(160)
                .objectFit(ImageFit.Cover)
            }
            .padding({ left: 8, right: 8, top: 8, bottom: 24 })
            .backgroundColor(Color.White)
            .shadow({ radius: 4, color: '#1A000000', offsetX: 2, offsetY: 2 })

            Row()
              .width(64)
              .height(14)
              .backgroundColor('#66B2DFEE')
              .offset({ y: -6 })
              .rotate({ angle: index % 2 === 0 ? -4 : 3 })
          }
          .margin({ top: 4, bottom: 4 })
          .rotate({ angle: index % 2 === 0 ? 2 : -2 })
        }

        // 米黄色便利贴
        if (item.note) {
          Text(item.note)
            .fontSize(14)
            .fontColor('#5D4037')
            .lineHeight(22)
            .padding(14)
            .width('100%')
            .backgroundColor('#FFF8E1')
            .borderRadius(4)
            .border({ width: 1, color: '#FFECB3', style: BorderStyle.Dashed })
        }

        // AI 高光批注框
        if (item.aiAnalysis) {
          Row({ space: 8 }) {
            Text('🤖💡').fontSize(14)
            Text(item.aiAnalysis)
              .fontSize(13)
              .fontColor('#6D4C41')
              .layoutWeight(1)
              .lineHeight(20)
          }
          .width('100%')
          .backgroundColor('#F9FBE7')
          .borderRadius(8)
          .padding(12)
        }
      }
      .layoutWeight(1)
      .backgroundColor('#FAFAFA')
      .borderRadius(14)
      .padding(16)
      .shadow({ radius: 8, color: '#08000000', offsetX: 0, offsetY: 3 })
      .opacity(this.isLogsAppeared[index] ? 1 : 0)
      .translate({ y: this.isLogsAppeared[index] ? 0 : 30 })
      .onAppear(() => {
        setTimeout(() => {
          animateTo({ duration: 600, curve: AnimationUtils.SMOOTH }, () => {
            this.isLogsAppeared[index] = true
          })
        }, AnimationUtils.getStaggerDelay(index, 80))
      })
      .onClick(() => {
        router.pushUrl({ url: 'pages/PlantDetailPage', params: { plantId: item.plantId } })
      })
    }
    .width('100%')
    .alignItems(VerticalAlign.Top)
  }

  build() {
    Column() {
      Row() {
        Column({ space: 2 }) {
          Text('成长记录')
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppTheme.PRIMARY_DARK)
          Text(`共 ${this.totalLogCount} 条动态`)
            .fontSize(13)
            .fontColor(AppTheme.MUTED)
        }
        .alignItems(HorizontalAlign.Start)

        Blank()

        if (!this.showDashboard && this.totalLogCount > 0) {
          Button('📊 数据看板')
            .height(32)
            .fontSize(12)
            .backgroundColor('#E8F5E9')
            .fontColor(AppTheme.PRIMARY)
            .borderRadius(16)
            .onClick(() => this.showDashboard = true)
        }
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 56, bottom: 12 })

      Refresh({ refreshing: $$this.refreshing }) {
        Column() {
          if (this.loading && !this.refreshing) {
            Column() {
              LoadingProgress().width(40).height(40).color(AppTheme.PRIMARY)
              Text('加载中...').fontSize(13).fontColor(AppTheme.MUTED).margin({ top: 10 })
            }
            .layoutWeight(1)
            .justifyContent(FlexAlign.Center)
            .width('100%')
          } else if (this.logs.length === 0) {
            Column({ space: 12 }) {
              Text('📷').fontSize(56)
              Text('还没有任何记录').fontSize(16).fontColor('#666')
              Text('在植物详情页写下第一篇成长日记吧').fontSize(13).fontColor(AppTheme.MUTED)
            }
            .layoutWeight(1)
            .justifyContent(FlexAlign.Center)
            .width('100%')
          } else {
            List({ space: 12 }) {
              ListItem() {
                this.DashboardCard()
              }
              ForEach(this.logs, (item: GrowthLogItem, index: number) => {
                ListItem() {
                  this.LogCard(item, index)
                }
              }, (item: GrowthLogItem) => `${item.id}`)
            }
            .layoutWeight(1)
            .padding({ left: 16, right: 16, bottom: 80 })
            .width('100%')
          }
        }
        .width('100%')
        .height('100%')
      }
      .onRefreshing(() => {
        this.onRefresh()
      })
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppTheme.BG)
  }
}