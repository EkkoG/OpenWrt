<script setup lang="ts">
import { useAppStore } from '@/stores/app'
import { ref, computed, nextTick, watch } from 'vue'
import ConfigQuickSelector from '@/components/ConfigQuickSelector.vue'
import AdvancedBuildOptions from '@/components/AdvancedBuildOptions.vue'
import ModulesView from '@/views/ModulesView.vue'

const appStore = useAppStore()
const logContainer = ref<HTMLElement | null>(null)
const copyNotification = ref({ show: false, message: '', color: 'success' })

// 高级选项状态
const showAdvancedOptions = ref(false)
const repositories = [
  { title: 'OpenWrt Official', value: 'openwrt/imagebuilder' },
  { title: 'ImmortalWrt Official', value: 'immortalwrt/imagebuilder' }
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
  
  // 添加用户模块路径
  if (appStore.userModulesPath) {
    command += ` --user-modules=${appStore.userModulesPath}`
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
      title: '选择固件输出目录'
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
        user_modules_path: appStore.userModulesPath,
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
    appStore.buildLogs.push(`[构建失败: ${error}]`)
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
  console.log('开始复制日志...')
  console.log('日志数量:', appStore.buildLogs.length)
  
  if (appStore.buildLogs.length === 0) {
    copyNotification.value = {
      show: true,
      message: '没有可复制的日志',
      color: 'warning'
    }
    return
  }
  
  try {
    // 根据 Tauri v2 文档的正确导入方式
    const { writeText } = await import('@tauri-apps/plugin-clipboard-manager')
    const logText = appStore.buildLogs.join('\n')
    console.log('准备复制的文本长度:', logText.length)
    
    await writeText(logText)
    console.log('Tauri 剪贴板复制成功')
    
    copyNotification.value = {
      show: true,
      message: `已复制 ${appStore.buildLogs.length} 行日志到剪贴板`,
      color: 'success'
    }
  } catch (error) {
    console.error('Tauri 剪贴板复制失败:', error)
    console.log('尝试降级到浏览器剪贴板...')
    
    // 降级方案：使用浏览器的 navigator.clipboard
    try {
      const logText = appStore.buildLogs.join('\n')
      
      if (!navigator.clipboard) {
        console.error('浏览器不支持 navigator.clipboard')
        throw new Error('浏览器不支持剪贴板 API')
      }
      
      await navigator.clipboard.writeText(logText)
      console.log('浏览器剪贴板复制成功')
      
      copyNotification.value = {
        show: true,
        message: `已复制 ${appStore.buildLogs.length} 行日志到剪贴板`,
        color: 'success'
      }
    } catch (fallbackError) {
      console.error('浏览器剪贴板复制也失败:', fallbackError)
      copyNotification.value = {
        show: true,
        message: '复制日志失败，请手动选择复制',
        color: 'error'
      }
    }
  }
}

</script>

<template>
  <v-container>
    <!-- 配置快速选择器 -->
    <ConfigQuickSelector />
    
    <v-row>
      <!-- 配置区 -->
      <v-col cols="12">
        <v-card>
          <v-card-title>
            <v-icon class="mr-2">mdi-docker</v-icon>
            镜像选择
          </v-card-title>
          <v-card-text>
            <!-- 仓库选择 -->
            <v-select
              v-model="appStore.selectedRepository"
              :items="repositories"
              label="选择镜像仓库"
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
                <div class="text-subtitle-2 mb-2">常用镜像标签</div>
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
              label="或输入自定义标签"
              placeholder="例如: x86-64-v23.05.2"
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
            构建配置
            <v-spacer />
            <v-btn
              variant="text"
              size="small"
              @click="toggleAdvancedOptions"
              :color="showAdvancedOptions ? 'primary' : 'default'"
            >
              <v-icon>{{ showAdvancedOptions ? 'mdi-chevron-up' : 'mdi-chevron-down' }}</v-icon>
              高级选项
            </v-btn>
          </v-card-title>
          <v-card-text>
            <v-text-field
              v-model="appStore.selectedProfile"
              label="Profile (可选)"
              placeholder="例如: x86_64、rockchip_armv8 等"
              hint="部分镜像需要指定 profile，留空则使用默认配置"
              persistent-hint
              variant="outlined"
              density="compact"
              clearable
              class="mb-4"
            />
            
            <v-text-field
              v-model="appStore.outputDirectory"
              label="固件输出目录"
              variant="outlined"
              density="compact"
              readonly
              append-inner-icon="mdi-folder-open"
              @click="selectOutputDirectory"
              @click:append-inner="selectOutputDirectory"
            />
            
            <v-textarea
              v-model="appStore.globalEnvVars"
              label="全局环境变量"
              placeholder="KEY1=value1&#10;KEY2=value2&#10;KEY3=value3"
              hint="每行一个环境变量，格式：KEY=VALUE"
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
              {{ appStore.isBuilding ? '取消构建' : '开始构建' }}
            </v-btn>
            
            <v-alert
              v-if="!appStore.dockerReady"
              type="warning"
              variant="tonal"
              class="mt-3"
              density="compact"
            >
              请先确保 Docker 环境就绪
            </v-alert>
            
            <v-alert
              v-if="!appStore.selectedImage && !appStore.customImageTag"
              type="info"
              variant="tonal"
              class="mt-3"
              density="compact"
            >
              请选择或输入镜像标签
            </v-alert>
            
            <v-alert
              v-if="!appStore.outputDirectory"
              type="info"
              variant="tonal"
              class="mt-3"
              density="compact"
            >
              请选择固件输出目录
            </v-alert>
          </v-card-text>
        </v-card>
        
        <!-- 构建日志 -->
        <v-card class="mt-4">
          <v-card-title class="d-flex align-center">
            <v-icon class="mr-2">mdi-console</v-icon>
            构建日志
            <v-spacer />
            <v-btn
              size="small"
              variant="text"
              @click="copyLogs"
              :disabled="appStore.buildLogs.length === 0"
              class="mr-2"
            >
              <v-icon>mdi-content-copy</v-icon>
              <v-tooltip activator="parent" location="bottom">复制所有日志</v-tooltip>
            </v-btn>
            <v-btn
              size="small"
              variant="text"
              @click="clearLogs"
              :disabled="appStore.isBuilding"
            >
              <v-icon>mdi-delete</v-icon>
              <v-tooltip activator="parent" location="bottom">清空日志</v-tooltip>
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
              <div class="text-caption">构建命令预览:</div>
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
                暂无构建日志
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
                  上次构建{{ appStore.lastBuildStatus === 'success' ? '成功' : '失败' }}
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
          关闭
        </v-btn>
      </template>
    </v-snackbar>
  </v-container>
</template>