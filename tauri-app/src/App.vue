<script setup lang="ts">
import { onMounted, ref, watch, computed } from 'vue'
import { useTheme } from 'vuetify'
import { useAppStore } from '@/stores/app'
import { useConfigStore } from '@/stores/config'

const theme = useTheme()
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
          title="主页"
          value="home"
          to="/"
          rounded="xl"
        />
        <v-list-item
          prepend-icon="mdi-docker"
          title="Docker"
          value="docker"
          to="/docker"
          rounded="xl"
        />
        <v-list-item
          prepend-icon="mdi-package-variant"
          title="模块"
          value="modules"
          to="/modules"
          rounded="xl"
        />
        <v-list-item
          prepend-icon="mdi-hammer"
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
        <span class="text-h6 font-weight-bold">OpenWrt Builder GUI</span>
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

      <v-chip
        v-if="appStore.dockerReady"
        color="success"
        variant="tonal"
        prepend-icon="mdi-check-circle"
      >
        Docker 就绪
      </v-chip>
      <v-chip
        v-else
        color="error"
        variant="tonal"
        prepend-icon="mdi-alert-circle"
      >
        Docker 未就绪
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

    <v-snackbar
      v-if="appStore.isBuilding"
      :model-value="true"
      :timeout="-1"
      location="bottom"
      multi-line
    >
      <div class="d-flex align-center">
        <v-progress-circular
          indeterminate
          size="20"
          width="2"
          class="mr-3"
        />
        <span>正在构建固件...</span>
      </div>
      <template v-slot:actions>
        <v-btn
          color="error"
          variant="text"
          @click="appStore.cancelBuild()"
        >
          取消
        </v-btn>
      </template>
    </v-snackbar>
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