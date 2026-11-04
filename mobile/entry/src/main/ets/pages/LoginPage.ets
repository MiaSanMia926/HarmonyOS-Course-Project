import http from '@ohos.net.http';
import promptAction from '@ohos.promptAction';
import router from '@ohos.router';
import { Constants } from '../common/Constants';

class LoginRequest {
  id: number = 0;
  name: string = '';
  pwd: string = '';
  memo: string = '';
}

class LoginResponse {
  code: number = 0;
  msg: string = '';
  data: string = '';
  userId: number = 0;
}

// 【修复点 1】：专门定义一个类来存储悬浮物位置，解决 ArkTS 不能使用对象字面量作为类型的报错
class DecorPos {
  x: number;
  y: number;
  angle: number;

  constructor(x: number, y: number, angle: number) {
    this.x = x;
    this.y = y;
    this.angle = angle;
  }
}

@Entry
@Component
struct LoginPage {
  @State name: string = '';
  @State pwd: string = '';
  @State isLoading: boolean = false;

  // 使用新定义的 DecorPos 类进行初始化
  @State decorPos1: DecorPos = new DecorPos(40, 120, 0);
  @State decorPos2: DecorPos = new DecorPos(300, 450, 0);

  login() {
    if (!this.name || !this.pwd) {
      promptAction.showToast({ message: '账号和密码不能为空' });
      return;
    }

    this.isLoading = true;
    let httpRequest = http.createHttp();

    let requestBody: LoginRequest = {
      id: 0,
      name: this.name,
      pwd: this.pwd,
      memo: ""
    };

    httpRequest.request(
      `${Constants.BASE_URL}/user/login`,
      {
        method: http.RequestMethod.POST,
        header: { 'Content-Type': 'application/json' },
        extraData: JSON.stringify(requestBody),
        readTimeout: 10000,
        connectTimeout: 10000
      }
    ).then((data) => {
      this.isLoading = false;
      if (data.responseCode === 200) {
        let res = JSON.parse(data.result as string) as LoginResponse;
        if (res.code === 0 || res.code === 200) {
          promptAction.showToast({ message: '登录成功！' });
          AppStorage.setOrCreate('jwt_token', res.data);
          AppStorage.setOrCreate('current_user_id', res.userId);
          router.replaceUrl({ url: 'pages/Index' });
        } else {
          promptAction.showToast({ message: '登录失败: ' + res.msg });
        }
      } else {
        promptAction.showToast({ message: '服务器异常' });
      }
    }).catch((err: Error) => {
      this.isLoading = false;
      promptAction.showToast({ message: '网络请求失败' });
    });
  }

  build() {
    Stack({ alignContent: Alignment.Top }) {
      // 1. 底层：你的原版背景图
      Image($r('app.media.bg_login'))
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Cover)

      // 2. 中层：纯代码悬浮装饰 (Emoji + 动画)
      Text('✨')
        .fontSize(24)
        .position({ x: this.decorPos1.x, y: this.decorPos1.y })
        .rotate({ z: 1, angle: this.decorPos1.angle })
        .onAppear(() => {
          animateTo({ duration: 4000, curve: Curve.Linear, iterations: -1 }, () => {
            this.decorPos1 = new DecorPos(60, 150, 360); // 缓慢移动并旋转
          })
        })

      Text('☁️')
        .fontSize(36)
        .position({ x: this.decorPos2.x, y: this.decorPos2.y })
        .onAppear(() => {
          animateTo({ duration: 6000, curve: Curve.EaseInOut, iterations: -1, playMode: PlayMode.Alternate }, () => {
            this.decorPos2 = new DecorPos(280, 420, 0); // 缓慢漂浮
          })
        })

      // 3. 上层：UI 交互内容
      Column({ space: 20 }) {
        Text('欢迎登录')
          .fontSize(32)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 100, bottom: 40 })
          .fontColor('#5C6B73')

        // 用户名输入框
        Row() {
          Text('👤').fontSize(18).margin({ left: 16 })
          TextInput({ placeholder: '请输入用户名' })
            .onChange((value: string) => { this.name = value; })
            .width('80%').height(50)
            .backgroundColor(Color.Transparent)
        }
        .width('80%').height(50)
        .backgroundColor('#CCFFFFFF')
        .borderRadius(25)
        .stateStyles({
          focused: { .border({ width: 2, color: '#AEEEEE' }) },
          normal: { .border({ width: 0 }) }
        })

        // 密码输入框
        Row() {
          Text('🔒').fontSize(18).margin({ left: 16 })
          TextInput({ placeholder: '请输入密码' })
            .type(InputType.Password)
            .onChange((value: string) => { this.pwd = value; })
            .width('80%').height(50)
            .backgroundColor(Color.Transparent)
        }
        .width('80%').height(50)
        .backgroundColor('#CCFFFFFF')
        .borderRadius(25)
        .stateStyles({
          focused: { .border({ width: 2, color: '#AEEEEE' }) },
          normal: { .border({ width: 0 }) }
        })

        // 登录按钮
        Button() {
          Row() {
            if (this.isLoading) {
              LoadingProgress().width(24).height(24).color(Color.White).margin({ right: 8 })
              Text('正在登录...').fontColor(Color.White).fontSize(16).fontWeight(FontWeight.Medium)
            } else {
              Text('登 录').fontColor(Color.White).fontSize(16).fontWeight(FontWeight.Medium)
            }
          }
        }
        .width('80%').height(50).margin({ top: 20 })
        .onClick(() => { this.login(); })
        .enabled(!this.isLoading)
        .backgroundColor('#B0C4DE')
        .borderRadius(25)
        // 【修复点 2】：去除 stateStyles 内部属性之间的逗号，使用标准写法
        .stateStyles({
          pressed: {
            .scale({ x: 0.96, y: 0.96 })
            .backgroundColor('#9BAEC8')
          },
          normal: {
            .scale({ x: 1, y: 1 })
            .backgroundColor('#B0C4DE')
          }
        })

        // 注册入口
        Row() {
          Text('还没有账号？').fontSize(14).fontColor('#666')
          Text('点击注册')
            .fontSize(14)
            .fontColor('#7CA8A6')
            .fontWeight(FontWeight.Medium)
            .onClick(() => { router.pushUrl({ url: 'pages/RegisterPage' }) })
        }.margin({ top: 16 })

      }.width('100%').height('100%')
    }.width('100%').height('100%')
  }
}