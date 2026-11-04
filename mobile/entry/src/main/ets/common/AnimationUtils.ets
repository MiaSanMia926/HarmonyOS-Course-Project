// common/AnimationUtils.ets
import curves from '@ohos.curves'

export class AnimationUtils {
  // 🌟 全局弹簧曲线动画配置
  static readonly SPRING = curves.springCurve(0, 1, 228, 30)
  
  // 轻微弹性，适合按钮点击
  static readonly SPRING_LIGHT = curves.springCurve(0, 1, 300, 20)

  // 阻尼大一点，适合卡片翻转或展开
  static readonly SPRING_HEAVY = curves.springCurve(0, 1, 150, 25)

  // 平滑过度曲线
  static readonly SMOOTH = curves.cubicBezierCurve(0.25, 0.1, 0.25, 1.0)

  // 获取交错入场动画参数 (延迟时间)
  static getStaggerDelay(index: number, baseDelay: number = 50): number {
    return index * baseDelay
  }

  // 通用卡片点击缩放比例
  static readonly SCALE_NORMAL = 1.0
  static readonly SCALE_PRESSED = 0.95
  static readonly SCALE_HOVER = 1.02
}