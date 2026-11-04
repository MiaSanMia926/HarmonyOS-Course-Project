import http from '@ohos.net.http';
import promptAction from '@ohos.promptAction';
import router from '@ohos.router';
import { Constants } from '../common/Constants';

class RegisterRequest {
  id: number = 0;
  name: string = '';
  pwd: string = '';
  memo: string = '';
}
class RegisterResponse {
  code: number = 0;
  msg: string = '';
  data: string = '';
}

// 同样的 DecorPos 类
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
struct RegisterPage {
  @State name: string = '';
  @State pwd: string = '';
  @State pwdConfirm: string = '';
  @State isLoading: boolean = false;

  @State decorPos1: DecorPos = new DecorPos(280, 150, 0);
  @State decorPos2: DecorPos = new DecorPos(50, 500, 0);

  register() {
    if (!this.name || !this.pwd) {
      promptAction.showToast({ message: '账号和密码不能为空' });
      return;
    }
    if (this.pwd !== this.pwdConfirm) {
      promptAction.showToast({ message: '两次输入的密码不一致' });
      return;
    }

    this.isLoading = true;
    let httpRequest = http.createHttp();

    let requestBody: RegisterRequest = {
      id: 0,
      name: this.name,
      pwd: this.pwd,
      memo: "App端注册"
    };

    httpRequest.request(
      `${Constants.BASE_URL}/user/register`,
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
        let res = JSON.parse(data.result as string) as RegisterResponse;
        if (res.code === 200) {
          promptAction.showToast({ message: '注册成功，请登录！' });
          router.back();
        } else {
          promptAction.showToast({ message: '注册失败: ' + res.msg });
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
      Image($r('app.media.bg_login'))
        .width('100%').height('100%').objectFit(ImageFit.Cover)

      Text('✨')
        .fontSize(24)
        .position({ x: this.decorPos1.x, y: this.decorPos1.y })
        .rotate({ z: 1, angle: this.decorPos1.angle })
        .onAppear(() => {
          animateTo({ duration: 5000, curve: Curve.Linear, iterations: -1 }, () => {
            this.decorPos1 = new DecorPos(260, 180, -360);
          })
        })

      Text('🧸')
        .fontSize(30)
        .position({ x: this.decorPos2.x, y: this.decorPos2.y })
        .onAppear(() => {
          animateTo({ duration: 4000, curve: Curve.EaseInOut, iterations: -1, playMode: PlayMode.Alternate }, () => {
            this.decorPos2 = new DecorPos(60, 480, 0);
          })
        })

      Column({ space: 20 }) {
        Row() {
          Button() {
            Row() {
              Text('⬅️').fontSize(16).margin({ right: 4 })
              Text('返回').fontColor('#5C6B73').fontSize(16).fontWeight(FontWeight.Medium)
            }
          }
          .backgroundColor(Color.Transparent)
          .onClick(() => router.back())
          .stateStyles({
            pressed: { .scale({ x: 0.9, y: 0.9 }) },
            normal: { .scale({ x: 1, y: 1 }) }
          })
          Blank()
        }.width('100%').padding(16).margin({ top: 30 })

        Text('注册新账号')
          .fontSize(32).fontWeight(FontWeight.Bold).margin({ bottom: 20 }).fontColor('#5C6B73')

        Row() {
          Text('👤').fontSize(18).margin({ left: 16 })
          TextInput({ placeholder: '请输入用户名' }).onChange((v) => { this.name = v; }).width('80%').height(50).backgroundColor(Color.Transparent)
        }.width('80%').height(50).backgroundColor('#CCFFFFFF').borderRadius(25)
        .stateStyles({ focused: { .border({ width: 2, color: '#AEEEEE' }) }, normal: { .border({ width: 0 }) } })

        Row() {
          Text('🔒').fontSize(18).margin({ left: 16 })
          TextInput({ placeholder: '请输入密码' }).type(InputType.Password).onChange((v) => { this.pwd = v; }).width('80%').height(50).backgroundColor(Color.Transparent)
        }.width('80%').height(50).backgroundColor('#CCFFFFFF').borderRadius(25)
        .stateStyles({ focused: { .border({ width: 2, color: '#AEEEEE' }) }, normal: { .border({ width: 0 }) } })

        Row() {
          Text('🔒').fontSize(18).margin({ left: 16 })
          TextInput({ placeholder: '请再次确认密码' }).type(InputType.Password).onChange((v) => { this.pwdConfirm = v; }).width('80%').height(50).backgroundColor(Color.Transparent)
        }.width('80%').height(50).backgroundColor('#CCFFFFFF').borderRadius(25)
        .stateStyles({ focused: { .border({ width: 2, color: '#AEEEEE' }) }, normal: { .border({ width: 0 }) } })

        Button() {
          Row() {
            if (this.isLoading) {
              LoadingProgress().width(24).height(24).color(Color.White).margin({ right: 8 })
              Text('正在注册...').fontColor(Color.White).fontSize(16).fontWeight(FontWeight.Medium)
            } else {
              Text('注 册').fontColor(Color.White).fontSize(16).fontWeight(FontWeight.Medium)
            }
          }
        }
        .width('80%').height(50).margin({ top: 20 })
        .onClick(() => { this.register(); })
        .enabled(!this.isLoading)
        .backgroundColor('#B0C4DE')
        .borderRadius(25)
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
      }.width('100%').height('100%')
    }.width('100%').height('100%')
  }
}