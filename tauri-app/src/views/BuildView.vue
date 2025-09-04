<script setup lang="ts">
import { useAppStore } from '@/stores/app'
import { ref, computed, nextTick, watch } from 'vue'
import ConfigQuickSelector from '@/components/ConfigQuickSelector.vue'
import AdvancedBuildOptions from '@/components/AdvancedBuildOptions.vue'
import ModulesView from '@/views/ModulesView.vue'
import { useI18n } from 'vue-i18n'

const appStore = useAppStore()
const logContainer = ref<HTMLElement | null>(null)
const copyNotification = ref({ show: false, message: '', color: 'success' })
const { t } = useI18n()

// 高级选项状态
const showAdvancedOptions = ref(false)
const repositories = [
  { title: 'OpenWrt Official', value: 'openwrt/imagebuilder' },
  { title: 'ImmortalWrt Official', value: 'immortalwrt/imagebuilder' },
  { title: 'OpenWrt Forks', value: 'ghcr.io/ekkog/openwrt-forks-imagebuilder' }
]

// 常用标签
const popularTagsMap = {
  'openwrt/imagebuilder': [
    'rockchip-armv8-v24.10.2',
    'rockchip-armv8-v23.05.5',
    'x86-64-v24.10.2',
    'x86-64-v23.05.5'
  ],
  'immortalwrt/imagebuilder': [
    'rockchip-armv8-openwrt-24.10.2',
    'rockchip-armv8-openwrt-23.05.4',
    'x86-64-openwrt-24.10.2',
    'x86-64-openwrt-23.05.4'
  ],
  'ghcr.io/ekkog/openwrt-forks-imagebuilder': [
    'lean-ramips-mt7621-snapshots'
  ]
    
}

const popularTags = computed(() => {
  return popularTagsMap[appStore.selectedRepository as keyof typeof popularTagsMap] || []
})

const buildCommand = computed(() => {
  const modules = appStore.enabledModules.map(m => m.name).join(' ')
  const tag = appStore.selectedImage || appStore.customImageTag
  const image = tag ? `${appStore.selectedRepository}:${tag}` : ''
  let command = `ENABLE_MODULES="${modules}"`
  if (appStore.outputDirectory) {
    command += ` OUTPUT_DIR="${appStore.outputDirectory}"`
  }
  command += ` ./run.sh --image=${image}`
  if (appStore.selectedProfile) {
    command += ` --profile=${appStore.selectedProfile}`
  }
  
  // 添加自定义模块路径
  if (appStore.customModulesPath) {
    command += ` --custom-modules=${appStore.customModulesPath}`
  }
  
  // 添加高级选项到显示命令
  if (appStore.advancedOptions.withPull) {
    command += ` --with-pull`
  }
  if (appStore.advancedOptions.rmFirst) {
    command += ` --rm-first`
  }
  if (appStore.advancedOptions.useMirror) {
    command += ` --use-mirror`
    if (appStore.advancedOptions.mirrorUrl) {
      command += ` --mirror=${appStore.advancedOptions.mirrorUrl}`
    }
  }
  
  return command
})

const canStartBuild = computed(() => {
  return appStore.dockerReady && 
    !appStore.isBuilding && 
    (appStore.selectedImage || appStore.customImageTag) &&
    appStore.outputDirectory
})

// 监听日志变化，自动滚动到底部显示最新日志
watch(() => appStore.buildLogs.length, async () => {
  await nextTick()
  if (logContainer.value) {
    logContainer.value.scrollTop = logContainer.value.scrollHeight
  }
})





// 切换仓库
const onRepositoryChange = () => {
  appStore.selectedImage = ''
  appStore.customImageTag = ''
}


// 选择输出目录
const selectOutputDirectory = async () => {
  console.log('selectOutputDirectory called')
  try {
    const { open } = await import('@tauri-apps/plugin-dialog')
    console.log('Dialog plugin imported successfully')
    
    const selected = await open({
      directory: true,
      multiple: false,
      title: t('build.selectFirmwareOutputDir')
    })
    
    console.log('Dialog result:', selected)
    
    if (selected && typeof selected === 'string') {
      appStore.outputDirectory = selected
      console.log('Directory set to:', selected)
    }
  } catch (error) {
    console.error('Failed to select directory:', error)
    // 失败时使用默认目录
    appStore.outputDirectory = '/tmp/openwrt-output'
  }
}

// 开始构建
const startBuild = async () => {
  if (!canStartBuild.value) return
  
  appStore.isBuilding = true
  appStore.buildLogs = []
  
  try {
    const { invoke } = await import('@tauri-apps/api/core')
    const { listen } = await import('@tauri-apps/api/event')
    
    // 添加开始构建日志
    appStore.buildLogs.push(t('build.logs.starting'))
    
    // 监听构建事件
    const unlisten = await listen('build-event', async (event: any) => {
      const buildEvent = event.payload
      
      if (buildEvent.event_type === 'log') {
        appStore.buildLogs.push(buildEvent.data)
        // 自动滚动到底部
        await nextTick()
        if (logContainer.value) {
          logContainer.value.scrollTop = logContainer.value.scrollHeight
        }
      } else if (buildEvent.event_type === 'complete') {
        appStore.buildLogs.push(buildEvent.data)
        appStore.lastBuildTime = new Date()
        appStore.lastBuildStatus = 'success'
        appStore.isBuilding = false
        await nextTick()
        if (logContainer.value) {
          logContainer.value.scrollTop = logContainer.value.scrollHeight
        }
        unlisten()
        
      } else if (buildEvent.event_type === 'error') {
        appStore.buildLogs.push(buildEvent.data)
        appStore.lastBuildStatus = 'failed'
        appStore.isBuilding = false
        await nextTick()
        if (logContainer.value) {
          logContainer.value.scrollTop = logContainer.value.scrollHeight
        }
        unlisten()
      }
    })
    
    // 准备环境变量
    const envVars = appStore.enabledModules.flatMap(module => 
      Object.entries(module.envVars).map(([key, value]) => ({
        key,
        value: value as string
      }))
    )
    
    // 调用构建命令
    const tag = appStore.selectedImage || appStore.customImageTag
    const fullImage = tag ? `${appStore.selectedRepository}:${tag}` : ''
    
    await invoke('start_build', {
      config: {
        image: fullImage,
        profile: appStore.selectedProfile || null,
        modules: appStore.enabledModules.map(m => m.name),
        output_dir: appStore.outputDirectory,
        env_vars: envVars,
        global_env_vars: appStore.globalEnvVars,
        custom_modules_path: appStore.customModulesPath,
        rootfs_part_size: appStore.rootfsPartSize,
        advanced_options: {
          with_pull: appStore.advancedOptions.withPull,
          rm_first: appStore.advancedOptions.rmFirst,
          use_mirror: appStore.advancedOptions.useMirror,
          mirror_url: appStore.advancedOptions.mirrorUrl,
          custom_args: ''
        }
      }
    })
  } catch (error) {
    appStore.lastBuildStatus = 'failed'
    appStore.buildLogs.push(`[${t('build.logs.failed', { error })}]`)
    appStore.isBuilding = false
  }
}

// 取消构建
const cancelBuild = async () => {
  try {
    const { invoke } = await import('@tauri-apps/api/core')
    await invoke('cancel_build')
    appStore.cancelBuild()
  } catch (error) {
    console.error('Failed to cancel build:', error)
  }
}

// 统一的构建按钮处理函数
const handleBuildAction = async () => {
  if (appStore.isBuilding) {
    await cancelBuild()
  } else {
    await startBuild()
  }
}

// 清除日志
const clearLogs = () => {
  appStore.clearBuildLogs()
}

// 切换高级选项显示
const toggleAdvancedOptions = () => {
  showAdvancedOptions.value = !showAdvancedOptions.value
}

// 复制日志
const copyLogs = async () => {
  console.log('Starting to copy logs...')
  console.log('Log count:', appStore.buildLogs.length)
  
  if (appStore.buildLogs.length === 0) {
    copyNotification.value = {
      show: true,
      message: t('messages.noLogsAvailable'),
      color: 'warning'
    }
    return
  }
  
  try {
    // 根据 Tauri v2 文档的正确导入方式
    const { writeText } = await import('@tauri-apps/plugin-clipboard-manager')
    const logText = appStore.buildLogs.join('\n')
    console.log('Text length to copy:', logText.length)
    
    await writeText(logText)
    console.log('Tauri clipboard copy successful')
    
    copyNotification.value = {
      show: true,
      message: t('build.logCopied'),
      color: 'success'
    }
  } catch (error) {
    console.error('Tauri clipboard copy failed:', error)
    console.log('Trying to fallback to browser clipboard...')
    
    // 降级方案：使用浏览器的 navigator.clipboard
    try {
      const logText = appStore.buildLogs.join('\n')
      
      if (!navigator.clipboard) {
        console.error('Browser does not support navigator.clipboard')
        throw new Error('Browser does not support clipboard API')
      }
      
      await navigator.clipboard.writeText(logText)
      console.log('Browser clipboard copy successful')
      
      copyNotification.value = {
        show: true,
        message: t('build.logCopied'),
        color: 'success'
      }
    } catch (fallbackError) {
      console.error('Browser clipboard copy also failed:', fallbackError)
      copyNotification.value = {
        show: true,
        message: t('messages.copyLogsFailed'),
        color: 'error'
      }
    }
  }
}

</script>

<template>
  <v-container>
    <!-- 欢迎语 -->
    <v-card class="mb-4" variant="tonal" color="primary">
      <v-card-text class="text-center py-6">
        <v-icon size="48" class="mb-3 text-primary">mdi-router-wireless</v-icon>
        <h2 class="text-h4 font-weight-bold mb-2 text-primary">{{ t('build.welcomeTitle') }}</h2>
        <p class="text-body-1 text-medium-emphasis mb-0">
          {{ t('build.welcomeSubtitle') }}
        </p>
      </v-card-text>
    </v-card>

    <!-- 配置快速选择器 -->
    <ConfigQuickSelector />
    
    <v-row>
      <!-- 配置区 -->
      <v-col cols="12">
        <v-card>
          <v-card-title>
            <v-icon class="mr-2">mdi-docker</v-icon>
            {{ t('build.imageSelection') }}
          </v-card-title>
          <v-card-text>
            <!-- 仓库选择 -->
            <v-select
              v-model="appStore.selectedRepository"
              :items="repositories"
              :label="t('build.repository')"
              variant="outlined"
              density="compact"
              @update:model-value="onRepositoryChange"
              class="mb-4"
            />
            
            <!-- 预设镜像选择 -->
            <v-radio-group
              v-model="appStore.selectedImage"
              @update:model-value="appStore.customImageTag = ''"
            >
              <template v-slot:label>
                <div class="text-subtitle-2 mb-2">{{ t('build.popularTags') }}</div>
              </template>
              <v-radio
                v-for="tag in popularTags"
                :key="tag"
                :label="tag"
                :value="tag"
                density="compact"
              />
            </v-radio-group>
            
            <v-divider class="my-4" />
            
            <!-- 自定义镜像输入 -->
            <v-text-field
              v-model="appStore.customImageTag"
              :label="t('build.customTag')"
              :placeholder="t('build.customTagPlaceholder')"
              variant="outlined"
              density="compact"
              @update:model-value="appStore.selectedImage = ''"
            />
            
          </v-card-text>
        </v-card>
        
        <!-- 构建配置 -->
        <v-card class="mt-4">
          <v-card-title class="d-flex align-center">
            <v-icon class="mr-2">mdi-cog</v-icon>
            {{ t('common.config') }}
            <v-spacer />
            <v-btn
              variant="text"
              size="small"
              @click="toggleAdvancedOptions"
              :color="showAdvancedOptions ? 'primary' : 'default'"
            >
              <v-icon>{{ showAdvancedOptions ? 'mdi-chevron-up' : 'mdi-chevron-down' }}</v-icon>
              {{ t('build.advancedOptions') }}
            </v-btn>
          </v-card-title>
          <v-card-text>
            <v-text-field
              v-model="appStore.selectedProfile"
              :label="t('build.deviceProfile')"
              :placeholder="t('build.profilePlaceholder')"
              :hint="t('build.profilePlaceholder')"
              persistent-hint
              variant="outlined"
              density="compact"
              clearable
              class="mb-4"
            />
            
            <v-text-field
              v-model="appStore.outputDirectory"
              :label="t('build.outputDirectory')"
              variant="outlined"
              density="compact"
              readonly
              append-inner-icon="mdi-folder-open"
              @click="selectOutputDirectory"
              @click:append-inner="selectOutputDirectory"
            />
            
            <v-text-field
              :model-value="appStore.rootfsPartSize"
              @update:model-value="(val: string) => appStore.rootfsPartSize = val === '' ? null : Number(val)"
              :label="t('build.rootfsSize')"
              type="number"
              :min="64"
              :max="2048"
              :hint="t('build.rootfsSizeHint')"
              persistent-hint
              variant="outlined"
              density="compact"
              clearable
              class="mt-4"
            />
            
            <v-textarea
              v-model="appStore.globalEnvVars"
              :label="t('modules.globalEnvVars')"
              placeholder="KEY1=value1&#10;KEY2=value2&#10;KEY3=value3"
              :hint="t('modules.globalEnvVarsHint')"
              persistent-hint
              variant="outlined"
              density="compact"
              rows="3"
              class="mt-4"
            />

            <!-- 高级选项 -->
            <v-expand-transition>
              <div v-if="showAdvancedOptions" class="mt-4">
                <v-divider class="mb-4" />
                <AdvancedBuildOptions v-model="appStore.advancedOptions" />
              </div>
            </v-expand-transition>
            
          </v-card-text>
        </v-card>
        
        <!-- 模块配置 -->
        <div class="mt-4">
          <ModulesView />
        </div>
        
        <!-- 构建按钮 -->
        <v-card class="mt-4">
          <v-card-text>
            <v-btn
              :color="appStore.isBuilding ? 'error' : 'primary'"
              size="large"
              block
              @click="handleBuildAction"
              :disabled="!appStore.isBuilding && !canStartBuild"
            >
              <v-icon start>{{ appStore.isBuilding ? 'mdi-stop' : 'mdi-hammer' }}</v-icon>
              {{ appStore.isBuilding ? t('build.cancelBuild') : t('build.startBuild') }}
            </v-btn>
            
            <v-alert
              v-if="!appStore.dockerReady"
              type="warning"
              variant="tonal"
              class="mt-3"
              density="compact"
            >
              {{ t('messages.dockerRequired') }}
            </v-alert>
            
            <v-alert
              v-if="!appStore.selectedImage && !appStore.customImageTag"
              type="info"
              variant="tonal"
              class="mt-3"
              density="compact"
            >
              {{ t('messages.selectImageFirst') }}
            </v-alert>
            
            <v-alert
              v-if="!appStore.outputDirectory"
              type="info"
              variant="tonal"
              class="mt-3"
              density="compact"
            >
              {{ t('messages.selectOutputFirst') }}
            </v-alert>
          </v-card-text>
        </v-card>
        
        <!-- 构建日志 -->
        <v-card class="mt-4">
          <v-card-title class="d-flex align-center">
            <v-icon class="mr-2">mdi-console</v-icon>
            {{ t('build.buildLog') }}
            <v-spacer />
            <v-btn
              size="small"
              variant="text"
              @click="copyLogs"
              :disabled="appStore.buildLogs.length === 0"
              class="mr-2"
            >
              <v-icon>mdi-content-copy</v-icon>
              <v-tooltip activator="parent" location="bottom">{{ t('build.copyLog') }}</v-tooltip>
            </v-btn>
            <v-btn
              size="small"
              variant="text"
              @click="clearLogs"
              :disabled="appStore.isBuilding"
            >
              <v-icon>mdi-delete</v-icon>
              <v-tooltip activator="parent" location="bottom">{{ t('build.clearLog') }}</v-tooltip>
            </v-btn>
          </v-card-title>
          <v-card-text>
            
            <!-- 构建命令预览 -->
            <v-alert
              v-if="!appStore.isBuilding && (appStore.selectedImage || appStore.customImageTag)"
              type="info"
              variant="tonal"
              density="compact"
              class="mb-4"
            >
              <div class="text-caption">{{ t('build.commandPreview') }}:</div>
              <code class="text-caption">{{ buildCommand }}</code>
            </v-alert>
            
            <!-- 日志内容 -->
            <div
              ref="logContainer"
              class="log-container"
              style="height: 500px; overflow-y: auto; background-color: #212121; border-radius: 4px; padding: 12px; font-family: monospace"
            >
              <div
                v-if="appStore.buildLogs.length === 0"
                class="text-center text-medium-emphasis"
                style="color: #999"
              >
                {{ t('messages.noLogsAvailable') }}
              </div>
              <div
                v-for="(log, index) in appStore.buildLogs"
                :key="index"
                class="text-caption"
                style="white-space: pre-wrap; color: #e0e0e0"
              >
                {{ log }}
              </div>
            </div>
            
            
            <!-- 上次构建状态 -->
            <v-alert
              v-if="appStore.lastBuildStatus && !appStore.isBuilding"
              :type="appStore.lastBuildStatus === 'success' ? 'success' : 'error'"
              variant="tonal"
              class="mt-4"
              density="compact"
            >
              <div class="d-flex align-center">
                <div>
                  {{ appStore.lastBuildStatus === 'success' ? t('build.buildSuccess') : t('build.buildFailed') }}
                  <span v-if="appStore.lastBuildTime" class="text-caption">
                    ({{ new Date(appStore.lastBuildTime).toLocaleString() }})
                  </span>
                </div>
              </div>
            </v-alert>
          </v-card-text>
        </v-card>
      </v-col>
    </v-row>
    
    <!-- 复制通知 -->
    <v-snackbar
      v-model="copyNotification.show"
      :color="copyNotification.color"
      timeout="3000"
      location="bottom"
    >
      {{ copyNotification.message }}
      <template v-slot:actions>
        <v-btn
          variant="text"
          @click="copyNotification.show = false"
        >
          {{ t('common.close') }}
        </v-btn>
      </template>
    </v-snackbar>
  </v-container>
</template>