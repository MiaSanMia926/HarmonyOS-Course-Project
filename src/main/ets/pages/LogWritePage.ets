// pages/LogWritePage.ets
import { apiService } from '../service/ApiService'
import { fileService } from '../service/FileService'
import { pickSingleImage } from '../common/PhotoPickerUtil'
import { AppTheme } from '../common/AppTheme'
import router from '@ohos.router'
import promptAction from '@ohos.promptAction'
import { LengthMetrics } from '@kit.ArkUI';

const EMOTION_TAGS = ['🌱 茁壮成长', '🌸 开花了', '🍃 叶片饱满', '😟 状态不佳', '💧 刚浇水', '☀️ 晒太阳了']

interface LogWriteParams {
  plantId?: number
  plantName?: string
}

@Entry
@Component
struct LogWritePage {
  @State note: string = ''
  @State imagePath: string = ''
  @State selectedTag: string = ''
  @State aiAnalysis: string = ''
  @State analyzing: boolean = false
  @State saving: boolean = false
  private plantId: number = 0
  private plantName: string = ''

  aboutToAppear() {
    const params = router.getParams() as LogWriteParams
    this.plantId = params.plantId ?? 0
    this.plantName = params.plantName ?? ''
    this.loadPlant()
  }

  async loadPlant() {
    // 🌟 修复：不再去本地找植物名，而去云端找
    let rawId = AppStorage.get<number | string>('current_user_id')
    let currentUserId: number = Number(rawId) || 0
    const allPlants = await apiService.getUserPlants(currentUserId)
    const plant = allPlants.find(p => p.id === this.plantId)

    if (plant) {
      this.plantName = plant.name
    } else if (!this.plantName) {
      this.plantName = '植物'
    }
  }

  async pickImage() {
    const path = await pickSingleImage()
    if (path) {
      this.imagePath = path
      await this.runAIAnalysis()
    }
  }

  async runAIAnalysis() {
    if (!this.imagePath) return
    this.analyzing = true

    try {
      const base64 = await fileService.readImageAsBase64(this.imagePath)
      this.aiAnalysis = await apiService.analyzeHealth(this.plantId, base64)
    } catch (error) {
      this.aiAnalysis = '网络波动或 AI 请求失败，请稍后再试。'
      console.error('【AI诊断失败】', error)
    }

    this.analyzing = false
  }

  // 🌟 核心修改：正式抛弃本地 dbService，将日记发向云端
  async saveLog() {
    if (!this.note.trim() && !this.imagePath) {
      promptAction.showToast({ message: '请添加照片或文字记录', duration: 2000 })
      return
    }
    this.saving = true

    // 1. 本地照片转 Base64 字符串
    let base64 = ''
    if (this.imagePath) {
      base64 = await fileService.readImageAsBase64(this.imagePath)
    }

    // 2. 发送到 FastAPI 后端
    const success = await apiService.addPlantRecord(
      this.plantId,
      this.note.trim(),
      base64,
      this.selectedTag,
      this.aiAnalysis
    )

    if (success) {
      promptAction.showToast({ message: '日记保存成功 🌱', duration: 1500 })
      router.back() // 保存成功后返回详情页，详情页会自动拉取云端刷新！
    } else {
      promptAction.showToast({ message: '保存失败，请检查网络', duration: 2000 })
    }

    this.saving = false
  }

  build() {
    Column() {
      // 导航栏
      Row() {
        Button('取消')
          .backgroundColor(Color.Transparent).fontColor('#888').fontSize(15)
          .onClick(() => router.back())
        Text('记录成长').fontSize(18).fontWeight(FontWeight.Medium)
          .layoutWeight(1).textAlign(TextAlign.Center)
        Button(this.saving ? '保存中' : '保存')
          .backgroundColor(Color.Transparent).fontColor('#2E7D32').fontSize(15)
          .enabled(!this.saving)
          .onClick(() => this.saveLog())
      }
      .width('100%').height(56).padding({ left: 8, right: 8 })
      .backgroundColor(Color.White)

      Scroll() {
        Column({ space: 16 }) {
          // 图片选择
          Stack() {
            if (this.imagePath) {
              Image(this.imagePath)
                .width('100%').height(200)
                .objectFit(ImageFit.Cover)
                .borderRadius(14)
            } else {
              Column({ space: 8 }) {
                Text('📷').fontSize(40)
                Text('点击添加今日照片').fontSize(14).fontColor('#888')
              }
              .width('100%').height(160)
              .justifyContent(FlexAlign.Center)
              .backgroundColor('#E8F5E9')
              .borderRadius(14)
            }
            if (this.analyzing) {
              Column() {
                LoadingProgress().width(36).height(36).color(Color.White)
                Text('AI 分析中...').fontSize(13).fontColor(Color.White).margin({ top: 6 })
              }
              .width('100%').height(200)
              .justifyContent(FlexAlign.Center)
              .backgroundColor('#60000000').borderRadius(14)
            }
          }
          .onClick(() => this.pickImage())

          // AI 分析结果
          if (this.aiAnalysis) {
            Row({ space: 8 }) {
              Text('🤖').fontSize(16)
              Text(this.aiAnalysis).fontSize(13).fontColor('#555').layoutWeight(1).lineHeight(20)
            }
            .backgroundColor('#F3E5F5').borderRadius(10).padding(12)
          }

          // 心情标签
          Column({ space: 10 }) {
            Text('今天的状态').fontSize(14).fontColor('#555')
            Flex({
              wrap: FlexWrap.Wrap,
              space: {
                main: LengthMetrics.vp(8),
                cross: LengthMetrics.vp(8)
              }
            }) {
              ForEach(EMOTION_TAGS, (tag: string) => {
                Text(tag)
                  .fontSize(13)
                  .fontColor(this.selectedTag === tag ? AppTheme.PRIMARY_DARK : '#555')
                  .backgroundColor(this.selectedTag === tag ? '#C8E6C9' : '#F5F5F5')
                  .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                  .borderRadius(16)
                  .onClick(() => {
                    this.selectedTag = this.selectedTag === tag ? '' : tag
                  })
              }, (tag: string) => tag)
            }
          }
          .alignItems(HorizontalAlign.Start)
          .width('100%')

          // 文字记录
          Column({ space: 8 }) {
            Text('写下今天的故事').fontSize(14).fontColor('#555')
            TextArea({ placeholder: '今天植物有什么变化？有新叶片吗？还是开花了？...', text: this.note })
              .onChange((val) => { this.note = val })
              .height(140)
              .borderRadius(10)
              .backgroundColor('#F5F5F5')
              .fontSize(15)
          }
          .alignItems(HorizontalAlign.Start)
          .width('100%')

          Blank().height(40)
        }
        .padding({ left: 16, right: 16, top: 16, bottom: 40 })
      }
      .layoutWeight(1).backgroundColor('#F1F8E9')
    }
    .width('100%').height('100%')
  }
}