import { createRouter, createWebHistory } from 'vue-router'
import type { RouteRecordRaw } from 'vue-router'

const routes: RouteRecordRaw[] = [
  {
    path: '/',
    name: 'Home',
    component: () => import('@/views/HomeView.vue'),
    meta: {
      title: '主页'
    }
  },
  {
    path: '/modules',
    name: 'Modules',
    component: () => import('@/views/ModulesView.vue'),
    meta: {
      title: '模块配置'
    }
  },
  {
    path: '/build',
    name: 'Build',
    component: () => import('@/views/BuildView.vue'),
    meta: {
      title: '构建管理'
    }
  },
  {
    path: '/config',
    name: 'Config',
    component: () => import('@/views/ConfigView.vue'),
    meta: {
      title: '配置管理'
    }
  },
  {
    path: '/settings',
    name: 'Settings',
    component: () => import('@/views/SettingsView.vue'),
    meta: {
      title: '设置'
    }
  }
]

const router = createRouter({
  history: createWebHistory(),
  routes
})

router.beforeEach((to, _from, next) => {
  document.title = `${to.meta.title || 'OpenWrt Builder'} - OpenWrt Builder GUI`
  next()
})

export default router