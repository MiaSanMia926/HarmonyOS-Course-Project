// pages/Index.ets
import { dbService } from '../service/DatabaseService'
import { fileService } from '../service/FileService'
import { prefsService } from '../service/PreferencesService'
import GardenPage from './GardenPage'
import RecordsPage from './RecordsPage'
import EncyclopediaPage from './EncyclopediaPage'
import ProfilePage from './ProfilePage'
import WorkbenchPage from './WorkbenchPage' // 🌟 新增导入
import { AppTheme } from '../common/AppTheme'
import router from '@ohos.router'
import common from '@ohos.app.ability.common'

@Entry
@Component
struct Index {
  @State currentTab: number = 0
  @State updateTrigger: number = 0 // 🌟 新增：全局刷新触发器

  onPageShow() {
    // 当从其他页面（如添加植物、详情页）返回到主页时，触发所有子组件的刷新
    this.updateTrigger++
  }

  aboutToAppear() {
    const context = getContext(this) as common.UIAbilityContext
    dbService.init(context)
    fileService.init(context)
    prefsService.init(context)
  }

  @Builder
  TabIcon(icon: string, label: string, idx: number) {
    Column({ space: 4 }) {
      Text(icon)
        .fontSize(22)
        .opacity(this.currentTab === idx ? 1 : 0.45)
      Text(label)
        .fontSize(11)
        .fontColor(this.currentTab === idx ? AppTheme.PRIMARY : AppTheme.MUTED)
    }
    .width('100%')
    .justifyContent(FlexAlign.Center)
  }

  build() {
    Tabs({ barPosition: BarPosition.End, index: this.currentTab }) {

      TabContent() {
        GardenPage({ updateTrigger: this.updateTrigger })
      }
      .tabBar(this.TabIcon('🌿', '花园', 0))

      TabContent() {
        // 🌟 修改：通过神经线把当前 Tab 索引传给 RecordsPage
        RecordsPage({ currentTabIndex: this.currentTab, updateTrigger: this.updateTrigger })
      }
      .tabBar(this.TabIcon('📝', '记录', 1))

      TabContent() {
        WorkbenchPage({ currentTabIndex: this.currentTab, updateTrigger: this.updateTrigger })
      }
      .tabBar(this.TabIcon('➕', '工作台', 2))

      TabContent() {
        EncyclopediaPage()
      }
      .tabBar(this.TabIcon('📖', '百科', 3))

      TabContent() {
        ProfilePage({ currentTabIndex: this.currentTab, updateTrigger: this.updateTrigger })
      }
      .tabBar(this.TabIcon('👤', '我的', 4))
    }
    .onChange((index: number) => {
      this.currentTab = index
    })
    .barHeight(64)
    .backgroundColor('#FAFAFA')
  }
}
