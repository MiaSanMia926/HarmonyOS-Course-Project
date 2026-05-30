// pages/AddPlantPage.ets
import { dbService } from '../service/DatabaseService'
import { apiService } from '../service/ApiService'
import picker from '@ohos.file.picker'
import fs from '@ohos.file.fs'
import util from '@ohos.util'
import { AICarePlan, PlantInsert } from '../model/PlantModel'
import { nowISOString } from '../utils/DateUtils'
import router from '@ohos.router'
// 🌟【新增】：引入提示框，用来给用户及时的交互反馈
import promptAction from '@ohos.promptAction'

interface AddPlantParams {
  imageUri?: string
  isHealthCheck?: boolean
}

@Entry
@Component
struct AddPlantPage {
  @State plantName: string = ''
  @State imagePath: string = ''
  @State currentBase64: string = ''
  @State carePlan: AICarePlan | null = null
  @State identifying: boolean = false
  @State saving: boolean = false
  @State tips: string = ''

  // 每日寄语状态
  @State dailyTip: string = '正在向 DeepSeek 召唤今日寄语...'
  @State isFetchingTip: boolean = false

  // 健康诊断状态
  @State healthImagePath: string = '' // 🌟【新增】：用来单独显示体检的照片
  @State healthResult: string = ''
  @State analyzingHealth: boolean = false

  // 🌟【修改】：改成 onPageShow，保证每次进入页面都会执行
  onPageShow() {
    // 如果寄语还没加载出来，就去加载
    if (this.dailyTip.includes('召唤')) {
      this.fetchDailyTip()
    }

    // 处理从工作台传过来的参数
    const params = router.getParams() as AddPlantParams | undefined
    if (params && params.imageUri) {
      if (params.isHealthCheck && !this.healthImagePath) {
        this.healthImagePath = params.imageUri
        this.processImage(params.imageUri, true)
      } else if (!params.isHealthCheck && !this.imagePath) {
        this.imagePath = params.imageUri
        this.processImage(params.imageUri, false)
      }
    }
  }

  async fetchDailyTip() {
    this.isFetchingTip = true
    try {
      let tip = await apiService.getDailyTip('你的植物小家', '绿植')
      this.dailyTip = tip
    } catch (e) {
      this.dailyTip = '今天也要记得给可爱的植物们浇浇水哦～ (网络可能有点慢)'
    }
    this.isFetchingTip = false
  }

  async processImage(uri: string, isForHealthCheck: boolean) {
    try {
      let file = fs.openSync(uri, fs.OpenMode.READ_ONLY)
      let stat = fs.statSync(file.fd)
      let buf = new ArrayBuffer(stat.size)
      fs.readSync(file.fd, buf)
      fs.closeSync(file)

      let helper = new util.Base64Helper()
      let base64 = helper.encodeToStringSync(new Uint8Array(buf))

      if (isForHealthCheck) {
        this.currentBase64 = base64
        this.healthResult = '图片已上传，千问 AI 正在努力诊断中，请稍候约10秒...'
        this.analyzingHealth = true
        try {
          // 🌟 核心修复：第一个参数传 0 代表“无档案快捷诊断”，第二个传 base64 图片
          let result = await apiService.analyzeHealth(0, base64)
          this.healthResult = result
        } catch (error) {
          this.healthResult = '诊断失败，请检查网络或后端是否开启'
        }
        this.analyzingHealth = false
        promptAction.showToast({ message: '健康诊断完成！' })
      } else {
        this.currentBase64 = base64
        await this.identifyPlant()
      }
    } catch (error) {
      promptAction.showToast({ message: '处理图片失败' })
      if (isForHealthCheck) this.analyzingHealth = false
    }
  }

  async pickImage(isForHealthCheck: boolean = false) {
    try {
      let documentSelectOptions = new picker.DocumentSelectOptions()
      documentSelectOptions.maxSelectNumber = 1
      documentSelectOptions.fileSuffixFilters = ['.png', '.jpg', '.jpeg']

      let documentViewPicker = new picker.DocumentViewPicker()
      let documentSelectResult = await documentViewPicker.select(documentSelectOptions)

      if (documentSelectResult && documentSelectResult.length > 0) {
        let selectedUri = documentSelectResult[0]
        if (isForHealthCheck) {
          this.healthImagePath = selectedUri
        } else {
          this.imagePath = selectedUri
        }
        await this.processImage(selectedUri, isForHealthCheck)
      }
    } catch (error) {
      promptAction.showToast({ message: '读取图片失败' })
      if(isForHealthCheck) {
        this.analyzingHealth = false
      } else {
        this.tips = '读取图片失败，请换一张图试试'
      }
    }
  }

  async identifyPlant() {
    this.identifying = true
    this.tips = 'AI 正在识别并在云端建档...'
    try {
      // 🌟 1. 安全获取 userId 并强制转换为 number 类型（解决第一个报错）
      let rawId = AppStorage.get<number | string>('current_user_id')
      let currentUserId: number = Number(rawId) || 0

      // 🌟 2. 调用新版 API，注意参数顺序：(用户ID, 植物名字, 照片Base64)（解决第二个报错）
      let result = await apiService.identifyAndCreatePlant(
        currentUserId,
        this.plantName,
        this.currentBase64
      )

      // ArkTS 严格模式下，强转为页面的 AICarePlan 类型
      this.carePlan = result as AICarePlan
      this.tips = 'AI 识别并建档完成！'
    } catch (e) {
      this.tips = '网络请求失败，请稍后重试'
      console.error('【建档失败】', JSON.stringify(e))
    }
    this.identifying = false
  }

  async savePlant() {
    if (!this.plantName.trim()) {
      promptAction.showToast({ message: '请先给植物起个名字' })
      return
    }
    this.saving = true

    // 🌟 因为后端已经存好了，这里只需提示并返回即可
    promptAction.showToast({ message: '已同步至云端花园！' })
    router.back()

    this.saving = false
  }

  @Builder
  CarePlanCard() {
    if (this.carePlan) {
      Column({ space: 12 }) {
        Text(this.carePlan!.species ? `AI 识别：${this.carePlan!.species}` : 'AI 养护方案')
          .fontSize(15).fontWeight(FontWeight.Medium).fontColor('#2E7D32')
        Grid() {
          GridItem() { this.InfoTile('💧', '浇水', `每 ${this.carePlan!.waterDays} 天`) }
          GridItem() { this.InfoTile('☀️', '光照', this.carePlan!.sunlight) }
          GridItem() { this.InfoTile('🌿', '施肥', this.carePlan!.fertilize) }
          GridItem() { this.InfoTile('❤️', '健康值', `${this.carePlan!.healthScore}分`) }
        }
        .columnsTemplate('1fr 1fr')
        .rowsGap(8).columnsGap(8)

        Text(this.carePlan!.tips)
          .fontSize(13).fontColor('#555')
          .backgroundColor('#F9FBE7')
          .borderRadius(8)
          .padding(10)
          .width('100%')
      }
      .width('100%')
      .backgroundColor(Color.White)
      .borderRadius(14)
      .padding(16)
      .shadow({ radius: 6, color: '#0A000000', offsetX: 0, offsetY: 2 })
    }
  }

  @Builder
  InfoTile(icon: string, label: string, value: string) {
    Column({ space: 4 }) {
      Text(icon).fontSize(20)
      Text(label).fontSize(11).fontColor('#888')
      Text(value).fontSize(13).fontWeight(FontWeight.Medium).fontColor('#333')
    }
    .width('100%').padding(10)
    .backgroundColor('#F1F8E9').borderRadius(10)
    .alignItems(HorizontalAlign.Center)
  }

  build() {
    Column() {
      Row() {
        Button('←')
          .backgroundColor(Color.Transparent).fontColor('#333').fontSize(20)
          .onClick(() => router.back())
        Text('AI 工作台').fontSize(18).fontWeight(FontWeight.Medium).layoutWeight(1).textAlign(TextAlign.Center)
        Blank().width(40) // 占位保持居中
      }
      .width('100%').height(56)
      .padding({ left: 8, right: 8 })
      .backgroundColor(Color.White)

      Scroll() {
        Column({ space: 16 }) {

          // ================= 模块 1：每日寄语 =================
          Row() {
            Text('💡').fontSize(24).margin({ right: 10 })
            Text(this.dailyTip)
              .fontSize(14).fontColor('#4CAF50').layoutWeight(1).fontStyle(FontStyle.Italic)

            // 🌟【新增】：刷新按钮，如果卡住了可以手动点一下
            Button('🔁')
              .fontSize(18).backgroundColor(Color.Transparent)
              .enabled(!this.isFetchingTip)
              .onClick(() => this.fetchDailyTip())
          }
          .width('100%').padding(15).backgroundColor('#E8F5E9').borderRadius(12)
          .shadow({ radius: 4, color: '#0A000000', offsetX: 0, offsetY: 2 })


          // ================= 模块 2：AI 健康诊断 =================
          Column({space: 10}) {
            Text('快捷健康诊断').fontSize(16).fontWeight(FontWeight.Bold).width('100%')

            // 🌟【新增】：显示选中的诊断照片
            if (this.healthImagePath) {
              Image(this.healthImagePath)
                .width('100%').height(160)
                .objectFit(ImageFit.Cover).borderRadius(10)
            }

            Row() {
              Button(this.analyzingHealth ? 'AI 诊断中，请稍候...' : '📸 选取照片进行诊断')
                .backgroundColor(this.analyzingHealth ? '#BDBDBD' : '#FF9800')
                .fontColor(Color.White).layoutWeight(1).height(40)
                .enabled(!this.analyzingHealth)
                .onClick(() => this.pickImage(true))
            }.width('100%')

            if (this.healthResult) {
              Text(this.healthResult)
                .fontSize(13).fontColor('#555').padding(10)
                .backgroundColor('#FFF3E0').borderRadius(8).width('100%')
            }
          }.width('100%').padding(15).backgroundColor(Color.White).borderRadius(12)
          .shadow({ radius: 4, color: '#0A000000', offsetX: 0, offsetY: 2 })


          // ================= 模块 3：完整添加植物流程 =================
          Column({space: 16}) {
            Text('记录新植物').fontSize(16).fontWeight(FontWeight.Bold).width('100%')

            Stack() {
              if (this.imagePath) {
                Image(this.imagePath).width('100%').height(220).objectFit(ImageFit.Cover).borderRadius(14)
              } else {
                Column({ space: 8 }) {
                  Text('🌿').fontSize(48)
                  Text('点击选择植物照片').fontSize(14).fontColor('#888')
                }
                .width('100%').height(220).justifyContent(FlexAlign.Center).backgroundColor('#F5F5F5').borderRadius(14)
              }
              if (this.identifying) {
                Column() {
                  LoadingProgress().width(40).height(40).color(Color.White)
                  Text('AI 识别中...').fontSize(13).fontColor(Color.White).margin({ top: 8 })
                }
                .width('100%').height(220).justifyContent(FlexAlign.Center).backgroundColor('#60000000').borderRadius(14)
              }
            }
            .width('100%')
            .onClick(() => this.pickImage(false))

            Column({ space: 8 }) {
              TextInput({ placeholder: '给植物起个名字 (例如：小绿...)', text: this.plantName })
                .onChange((val) => { this.plantName = val }).borderRadius(10).backgroundColor('#F5F5F5').fontSize(15)
            }
            .alignItems(HorizontalAlign.Start).width('100%')

            Button(this.identifying ? 'AI 识别中...' : '🤖 识别品种并生成方案')
              .width('100%').height(44).backgroundColor('#2E7D32').fontColor(Color.White)
              .borderRadius(12).fontSize(15).enabled(!this.identifying)
              .onClick(() => this.identifyPlant())

            if (this.tips) { Text(this.tips).fontSize(13).fontColor('#888') }

            this.CarePlanCard()

            Button(this.saving ? '保存中...' : '保存至我的花园')
              .width('100%').height(44).backgroundColor('#4CAF50').fontColor(Color.White)
              .borderRadius(12).fontSize(15).enabled(!this.saving).margin({top: 10})
              .onClick(() => this.savePlant())

          }.width('100%').padding(15).backgroundColor(Color.White).borderRadius(12)
          .shadow({ radius: 4, color: '#0A000000', offsetX: 0, offsetY: 2 })

          Blank().height(32)
        }
        .padding({ left: 16, right: 16, top: 16, bottom: 40 })
      }
      .layoutWeight(1)
      .backgroundColor('#F8F9FA')
    }
    .width('100%').height('100%')
  }
}