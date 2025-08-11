import { createRouter, createWebHistory } from 'vue-router'
import type { RouteRecordRaw } from 'vue-router'
import i18n from '@/i18n'

const routes: RouteRecordRaw[] = [
  {
    path: '/',
    redirect: '/build'
  },
  {
    path: '/build',
    name: 'Build',
    component: () => import('@/views/BuildView.vue'),
    meta: {
      titleKey: 'build.pageTitle'
    }
  },
  {
    path: '/config',
    name: 'Config',
    component: () => import('@/views/ConfigView.vue'),
    meta: {
      titleKey: 'config.title'
    }
  },
  {
    path: '/settings',
    name: 'Settings',
    component: () => import('@/views/SettingsView.vue'),
    meta: {
      titleKey: 'settings.title'
    }
  }
]

const router = createRouter({
  history: createWebHistory(),
  routes
})

router.beforeEach((to, _from, next) => {
  const titleKey = to.meta.titleKey as string
  const title = titleKey ? i18n.global.t(titleKey) : 'OpenWrt Builder'
  document.title = `${title} - OpenWrt Builder`
  next()
})

export default router