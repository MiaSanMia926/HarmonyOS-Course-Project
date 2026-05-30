import { apiService } from '../service/ApiService'
import { dbService } from '../service/DatabaseService'
import { Plant } from '../model/PlantModel'
import router from '@ohos.router'

// 🌟 新增：导入与 AddPlantPage 相同的强大底层工具
import picker from '@ohos.file.picker'
import fs from '@ohos.file.fs'
import util from '@ohos.util'

interface AIAnalysisParams {
  plantId?: number
}

interface ImageExtractResult {
  path: string;
  base64: string;
}

// 🌟 将原本的 @Builder 升级为独立的 Component，彻底解决状态不刷新的问题
@Component
struct PhotoSlot {
  @Prop label: string = '';
  @Prop path: string = '';
  onTap: () => void = () => {};

  build() {
    Column({ space: 6 }) {
      Text(this.label).fontSize(13).fontColor('#555')
      Stack() {
        if (this.path) {
          Image(this.path)
            .width('100%').height(160)
            .objectFit(ImageFit.Cover)
            .borderRadius(12)
        } else {
          Column({ space: 6 }) {
            Text('📷').fontSize(32)
            Text('点击选择').fontSize(13).fontColor('#AAA')
          }
          .width('100%').height(160)
          .justifyContent(FlexAlign.Center)
          .backgroundColor('#E8F5E9')
          .borderRadius(12)
        }
      }
      .onClick(this.onTap)
    }
    .alignItems(HorizontalAlign.Start)
  }
}

@Entry
@Component
struct AIAnalysisPage {
  @State plant: Plant | null = null

  // 用于在屏幕上展示的图片路径
  @State beforeImagePath: string = ''
  @State afterImagePath: string = ''

  // 🌟 新增：专门用来保管榨出来的两张图的 Base64
  @State beforeBase64: string = ''
  @State afterBase64: string = ''

  @State analysisResult: string = ''
  @State analyzing: boolean = false
  private plantId: number = 0

  aboutToAppear() {
    const params = router.getParams() as AIAnalysisParams
    this.plantId = params.plantId ?? 0
    dbService.getPlantById(this.plantId).then(p => { this.plant = p })
  }

  // 🌟 核心通用选图与转码逻辑
  // 🌟 修改点 1：返回类型换成定义好的 interface
  async pickImageAndExtractBase64(): Promise<ImageExtractResult | null> {
    try {
      let documentSelectOptions = new picker.DocumentSelectOptions()
      documentSelectOptions.maxSelectNumber = 1
      documentSelectOptions.fileSuffixFilters = ['.png', '.jpg', '.jpeg']

      let documentViewPicker = new picker.DocumentViewPicker()
      let documentSelectResult = await documentViewPicker.select(documentSelectOptions)

      if (documentSelectResult && documentSelectResult.length > 0) {
        let selectedUri = documentSelectResult[0]

        let file = fs.openSync(selectedUri, fs.OpenMode.READ_ONLY)
        let stat = fs.statSync(file.fd)
        let buf = new ArrayBuffer(stat.size)
        fs.readSync(file.fd, buf)
        fs.closeSync(file)

        let helper = new util.Base64Helper()
        let base64Str = helper.encodeToStringSync(new Uint8Array(buf))

        console.info(`【DEBUG-对比分析】成功提取Base64，长度：${base64Str.length}`)

        // 🌟 修改点 2：将结果显式声明为该 interface 类型再返回
        let res: ImageExtractResult = { path: selectedUri, base64: base64Str }
        return res
      }
    } catch (error) {
      console.error('选择文件或转码失败:', JSON.stringify(error))
    }
    return null
  }

  // 点击选择第一张图
  async pickBeforeImage() {
    let result = await this.pickImageAndExtractBase64()
    if (result) {
      this.beforeImagePath = result.path
      this.beforeBase64 = result.base64
    }
  }

  // 点击选择第二张图
  async pickAfterImage() {
    let result = await this.pickImageAndExtractBase64()
    if (result) {
      this.afterImagePath = result.path
      this.afterBase64 = result.base64
    }
  }

  // 触发 AI 对比
  async runCompare() {
    // 🌟 校验是否两张图的 Base64 都已经准备好
    if (!this.beforeBase64 || !this.afterBase64) {
      this.analysisResult = '请先选择前后两张照片'
      return
    }

    this.analyzing = true
    this.analysisResult = ''

    try {
      // 🌟 核心修复：按新接口的顺序，第一个参数传入从路由拿到的 plantId
      this.analysisResult = await apiService.compareGrowth(
        this.plantId,
        this.beforeBase64,
        this.afterBase64
      )
    } catch (error) {
      this.analysisResult = '网络波动或 AI 请求失败，请稍后再试。'
      console.error('【AI对比失败】', error)
    }

    this.analyzing = false
  }

  build() {
    Column() {
      Row() {
        Button('←')
          .backgroundColor(Color.Transparent).fontColor('#333').fontSize(20)
          .onClick(() => router.back())
        Text('AI 生长对比分析').fontSize(18).fontWeight(FontWeight.Medium)
          .layoutWeight(1).textAlign(TextAlign.Center)
        Blank().width(52)
      }
      .width('100%').height(56).padding({ left: 8, right: 8 })
      .backgroundColor(Color.White)

      Scroll() {
        Column({ space: 20 }) {
          // 说明
          Text('选择同一株植物在不同时间拍摄的两张照片（支持从系统文件中选择），AI 将对比分析它的生长变化。')
            .fontSize(14).fontColor('#666').lineHeight(22)
            .backgroundColor('#F1F8E9').borderRadius(10).padding(14)

          // 两张照片
          Row({ space: 12 }) {
            Column() {
              PhotoSlot({
                label: '拍摄于早期',
                path: this.beforeImagePath,
                onTap: () => { this.pickBeforeImage(); }
              })
            }.layoutWeight(1)

            Column() {
              PhotoSlot({
                label: '拍摄于近期',
                path: this.afterImagePath,
                onTap: () => { this.pickAfterImage(); }
              })
            }.layoutWeight(1)
          }
          .width('100%')

          // 分析按钮
          Button(this.analyzing ? '🤖 AI 分析中...' : '🤖 开始对比分析')
            .width('100%').height(50)
            .backgroundColor(this.analyzing ? '#A5D6A7' : '#2E7D32')
            .fontColor(Color.White).borderRadius(14).fontSize(16)
            .enabled(!this.analyzing)
            .onClick(() => this.runCompare())

          if (this.analyzing) {
            Column({ space: 8 }) {
              LoadingProgress().width(40).height(40).color('#2E7D32')
              Text('AI 正在认真比对两张照片...').fontSize(13).fontColor('#888')
            }
            .width('100%').alignItems(HorizontalAlign.Center).padding({ top: 8 })
          }

          // 分析结果
          if (this.analysisResult) {
            Column({ space: 12 }) {
              Row({ space: 8 }) {
                Text('🤖').fontSize(18)
                Text('AI 分析结果').fontSize(16).fontWeight(FontWeight.Medium).fontColor('#1B5E20')
              }
              Text(this.analysisResult)
                .fontSize(15).fontColor('#333').lineHeight(26)
            }
            .width('100%')
            .backgroundColor(Color.White)
            .borderRadius(14)
            .padding(16)
            .shadow({ radius: 8, color: '#0A000000', offsetX: 0, offsetY: 2 })
          }

          Blank().height(40)
        }
        .padding({ left: 16, right: 16, top: 16, bottom: 40 })
      }
      .layoutWeight(1).backgroundColor('#F1F8E9')
    }
    .width('100%').height('100%')
  }
}