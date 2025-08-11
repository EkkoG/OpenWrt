import { createI18n } from 'vue-i18n'
import zhCN from './locales/zh-CN'
import enUS from './locales/en-US'

// 获取系统语言
function getSystemLanguage(): string {
  const systemLang = navigator.language || 'zh-CN'
  // 将系统语言映射到支持的语言
  if (systemLang.startsWith('zh')) {
    return 'zh-CN'
  } else if (systemLang.startsWith('en')) {
    return 'en-US'
  }
  return 'zh-CN' // 默认中文
}

// 从 localStorage 获取保存的语言设置
function getSavedLanguage(): string | null {
  return localStorage.getItem('language')
}

// 保存语言设置到 localStorage
export function saveLanguage(lang: string) {
  localStorage.setItem('language', lang)
}

// 创建 i18n 实例
const i18n = createI18n({
  legacy: false, // 使用 Composition API 模式
  locale: getSavedLanguage() || getSystemLanguage(),
  fallbackLocale: 'zh-CN',
  messages: {
    'zh-CN': zhCN,
    'en-US': enUS
  }
})

export default i18n