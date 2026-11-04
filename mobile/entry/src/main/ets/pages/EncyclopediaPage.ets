// pages/EncyclopediaPage.ets

import { webview } from '@kit.ArkWeb'

@Component
export default struct EncyclopediaPage {
  @State searchQuery: string = ''
  @State currentUrl: string = 'https://baike.baidu.com/item/植物'
  @State progress: number = 0 // 🌟 新增：加载进度
  private controller: webview.WebviewController = new webview.WebviewController()

  build() {
    Column() {
      // 搜索栏
      Row({ space: 10 }) {
        TextInput({ placeholder: '搜索植物品种...', text: this.searchQuery })
          .layoutWeight(1)
          .height(40)
          .borderRadius(20)
          .backgroundColor('#F5F5F5')
          .fontSize(14)
          .onChange((val) => { this.searchQuery = val })
          .onSubmit(() => { // 🌟 新增：支持回车搜索
            if (this.searchQuery.trim()) {
              this.currentUrl = `https://baike.baidu.com/item/${encodeURIComponent(this.searchQuery.trim())}`
              this.controller.loadUrl(this.currentUrl)
            }
          })
        Button('搜索')
          .height(40).width(64).fontSize(14)
          .backgroundColor('#2E7D32').fontColor(Color.White).borderRadius(20)
          .onClick(() => {
            if (this.searchQuery.trim()) {
              this.currentUrl = `https://baike.baidu.com/item/${encodeURIComponent(this.searchQuery.trim())}`
              this.controller.loadUrl(this.currentUrl)
            }
          })
      }
      .width('100%')
      .padding({ left: 14, right: 14, top: 12, bottom: 10 })
      .backgroundColor(Color.White)

      // 快捷入口
      Row({ space: 10 }) {
        ForEach(['多肉植物', '蕨类', '兰花', '仙人掌'], (name: string) => {
          Text(name)
            .fontSize(12).fontColor('#2E7D32')
            .backgroundColor('#E8F5E9')
            .padding({ left: 12, right: 12, top: 5, bottom: 5 })
            .borderRadius(12)
            .onClick(() => {
              this.searchQuery = name
              this.currentUrl = `https://baike.baidu.com/item/${encodeURIComponent(name)}`
              this.controller.loadUrl(this.currentUrl)
            })
        })
      }
      .padding({ left: 14, right: 14, bottom: 10 })
      .backgroundColor(Color.White)

      // 🌟 新增：网页加载进度条
      if (this.progress < 100) {
        Progress({ value: this.progress, total: 100, type: ProgressType.Linear })
          .width('100%')
          .color('#2E7D32')
          .backgroundColor('#E8F5E9')
      }

      // WebComponent
      Web({ src: this.currentUrl, controller: this.controller })
        .layoutWeight(1)
        .javaScriptAccess(true)
        .zoomAccess(true)
        .domStorageAccess(true)
        .onProgressChange((event) => { // 🌟 新增：监听加载进度
          if (event) {
            this.progress = event.newProgress
          }
        })
    }
    .width('100%').height('100%')
  }
}
