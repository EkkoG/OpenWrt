<script setup lang="ts">
import { onMounted, ref, watch, computed } from 'vue'
import { useTheme } from 'vuetify'
import { useRouter } from 'vue-router'
import { useAppStore } from '@/stores/app'
import { useConfigStore } from '@/stores/config'

const theme = useTheme()
const router = useRouter()
const appStore = useAppStore()
const configStore = useConfigStore()
const appModeInfo = ref<any>(null)
const isDebugMode = ref(false)

// 检测是否是调试模式（开发环境）
if (import.meta.env.DEV) {
  isDebugMode.value = true
}

// 监听主题变化
watch(() => appStore.theme, (newTheme) => {
  if (newTheme === 'auto') {
    // 自动主题：根据系统主题设置
    const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches
    theme.global.name.value = prefersDark ? 'dark' : 'light'
  } else {
    theme.global.name.value = newTheme
  }
}, { immediate: true })

// 监听系统主题变化（当设置为自动时）
const mediaQuery = window.matchMedia('(prefers-color-scheme: dark)')
mediaQuery.addEventListener('change', (e) => {
  if (appStore.theme === 'auto') {
    theme.global.name.value = e.matches ? 'dark' : 'light'
  }
})

// 主题切换逻辑
const toggleTheme = () => {
  const themeOrder: ('light' | 'dark' | 'auto')[] = ['light', 'dark', 'auto']
  const currentIndex = themeOrder.indexOf(appStore.theme)
  const nextIndex = (currentIndex + 1) % themeOrder.length
  appStore.theme = themeOrder[nextIndex]
}

// 获取主题图标
const getThemeIcon = computed(() => {
  switch (appStore.theme) {
    case 'light':
      return 'mdi-white-balance-sunny'
    case 'dark':
      return 'mdi-moon-waning-crescent'
    case 'auto':
      return 'mdi-theme-light-dark'
    default:
      return 'mdi-theme-light-dark'
  }
})

// 获取主题提示文本
const getThemeTooltip = computed(() => {
  switch (appStore.theme) {
    case 'light':
      return '浅色模式'
    case 'dark':
      return '深色模式'
    case 'auto':
      return '跟随系统'
    default:
      return '主题切换'
  }
})

// 跳转到构建页面
const goToBuildPage = () => {
  router.push('/build')
}

onMounted(async () => {
  // 加载保存的设置（包括主题）
  appStore.loadSettings()
  
  // 启动时检查 Docker 环境
  await appStore.checkDockerEnvironment()
  // 加载保存的配置
  await configStore.loadConfigurations()
  if (configStore.activeConfig) {
    configStore.applyConfigToStore(configStore.activeConfig.config, appStore)
  }
  // 加载模块信息（需要在配置恢复后进行，因为需要用户模块路径）
  await appStore.loadModules()
  
  // 在调试模式下获取应用模式信息
  if (isDebugMode.value) {
    try {
      const { invoke } = await import('@tauri-apps/api/core')
      appModeInfo.value = await invoke('get_app_mode_info')
      console.log('App Mode Info:', appModeInfo.value)
    } catch (error) {
      console.error('Failed to get app mode info:', error)
    }
  }
})
</script>

<template>
  <v-app>
    <v-navigation-drawer
      permanent
      rail
      rail-width="72"
    >
      <v-list nav>
        <v-list-item
          prepend-icon="mdi-home"
          title="构建"
          value="build"
          to="/build"
          rounded="xl"
        />
        <v-list-item
          prepend-icon="mdi-folder-cog"
          title="配置"
          value="config"
          to="/config"
          rounded="xl"
        />
      </v-list>

      <template v-slot:append>
        <v-list nav>
          <v-list-item
            prepend-icon="mdi-cog"
            title="设置"
            value="settings"
            to="/settings"
            rounded="xl"
          />
        </v-list>
      </template>
    </v-navigation-drawer>

    <v-app-bar
      flat
      density="comfortable"
    >
      <v-app-bar-title>
        <span class="text-h6 font-weight-bold">OpenWrt Builder</span>
      </v-app-bar-title>

      <v-spacer />

      <!-- Debug 模式显示应用模式信息 -->
      <v-chip
        v-if="isDebugMode && appModeInfo"
        color="info"
        variant="tonal"
        prepend-icon="mdi-bug"
        class="mr-2"
      >
        {{ appModeInfo.mode }}
        <v-tooltip activator="parent" location="bottom" max-width="400">
          <div class="text-caption">
            <strong>{{ appModeInfo.description }}</strong><br>
            资源路径: {{ appModeInfo.resource_path }}<br>
            工作目录: {{ appModeInfo.working_directory }}
          </div>
        </v-tooltip>
      </v-chip>

      <!-- 构建状态指示器 -->
      <v-chip
        v-if="appStore.isBuilding"
        color="warning"
        variant="tonal"
        class="mr-2"
        @click="goToBuildPage"
        style="cursor: pointer"
      >
        <v-progress-circular
          size="16"
          width="2"
          indeterminate
          class="mr-2"
        />
        构建中
        <v-tooltip activator="parent" location="bottom">
          正在构建固件，点击查看详情
        </v-tooltip>
      </v-chip>

      <v-chip
        :color="appStore.dockerReady ? 'success' : 'error'"
        variant="tonal"
        :prepend-icon="appStore.dockerReady ? 'mdi-check-circle' : 'mdi-alert-circle'"
        class="mr-2"
      >
        Docker
        <v-tooltip activator="parent" location="bottom" max-width="350">
          <div class="text-caption">
            <div><strong>状态:</strong> {{ appStore.dockerReady ? '就绪' : '未就绪' }}</div>
            <div><strong>安装状态:</strong> {{ appStore.dockerInstalled ? '已安装' : '未安装' }}</div>
            <div><strong>运行状态:</strong> {{ appStore.dockerRunning ? '运行中' : '未运行' }}</div>
            <div v-if="appStore.dockerInstalled"><strong>版本:</strong> {{ appStore.dockerVersion }}</div>
            <div v-if="appStore.dockerComposeInstalled"><strong>Compose:</strong> {{ appStore.dockerComposeVersion }}</div>
            <div v-if="!appStore.dockerInstalled" class="text-error">
              <strong>问题:</strong> Docker 未安装<br>
              <small>请访问 https://docker.com 下载安装 Docker Desktop</small>
            </div>
            <div v-if="appStore.dockerInstalled && !appStore.dockerRunning" class="text-error">
              <strong>问题:</strong> Docker 未运行<br>
              <small>请启动 Docker Desktop 应用程序</small>
            </div>
          </div>
        </v-tooltip>
      </v-chip>

      <v-btn
        icon
        @click="toggleTheme"
        class="ml-2"
      >
        <v-icon>{{ getThemeIcon }}</v-icon>
        <v-tooltip activator="parent" location="bottom">
          {{ getThemeTooltip }}
        </v-tooltip>
      </v-btn>
    </v-app-bar>

    <v-main>
      <v-container fluid>
        <router-view v-slot="{ Component }">
          <transition name="fade" mode="out-in">
            <component :is="Component" />
          </transition>
        </router-view>
      </v-container>
    </v-main>

  </v-app>
</template>

<style>
.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.3s ease;
}

.fade-enter-from,
.fade-leave-to {
  opacity: 0;
}
</style>