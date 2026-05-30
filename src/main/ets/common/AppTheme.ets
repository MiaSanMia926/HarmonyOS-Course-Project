// 1. 先定义阴影的结构接口
export interface ThemeShadow {
  radius: number;
  color: string;
  offsetX: number;
  offsetY: number;
}

export class AppTheme {
  // 🌟 自然主义色彩系统
  static readonly PRIMARY = '#4CAF50' // 主绿
  static readonly PRIMARY_DARK = '#2E7D32' // 深绿
  static readonly PRIMARY_LIGHT = '#A5D6A7' // 浅绿
  static readonly ACCENT = '#FFCA28' // 辅色：土黄/阳光
  static readonly MUTED = '#9E9E9E'
  static readonly CARD = '#FFFFFF'
  static readonly BG = '#F8FAF8' // 极浅的自然米绿底色
  static readonly TIP_BG = '#F1F8E9'
  static readonly WARNING = '#FF9800'
  static readonly DANGER = '#E53935'
  static readonly HEALTHY = '#4CAF50'
  static readonly AI_BG = '#E8F5E9'
  
  static readonly RADIUS_CARD = 16
  static readonly RADIUS_BTN = 12

  // 2. 在这里明确加上 : ThemeShadow 类型声明
  static readonly SHADOW: ThemeShadow = {
    radius: 12,
    color: 'rgba(46, 125, 50, 0.08)', // 带有绿色基调的阴影
    offsetX: 0,
    offsetY: 4
  }

  static readonly SHADOW_HOVER: ThemeShadow = {
    radius: 20,
    color: 'rgba(46, 125, 50, 0.15)',
    offsetX: 0,
    offsetY: 8
  }
}