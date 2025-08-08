<script setup lang="ts">
import { useAppStore } from '@/stores/app'
import { ref, computed, onMounted, nextTick, watch } from 'vue'
import ConfigQuickSelector from '@/components/ConfigQuickSelector.vue'

const appStore = useAppStore()
const isLoadingTags = ref(false)
const dockerTags = ref<string[]>([])
const selectedRepository = ref('immortalwrt/imagebuilder')
const logContainer = ref<HTMLElement | null>(null)
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
  return popularTagsMap[selectedRepository.value as keyof typeof popularTagsMap] || []
})

const buildCommand = computed(() => {
  const modules = appStore.enabledModules.map(m => m.name).join(' ')
  const tag = appStore.selectedImage || appStore.customImageTag
  const image = tag ? `${selectedRepository.value}:${tag}` : ''
  let command = `ENABLE_MODULES="${modules}" ./run.sh --image=${image}`
  if (appStore.selectedProfile) {
    command += ` --profile=${appStore.selectedProfile}`
  }
  if (appStore.outputDirectory) {
    command += ` --output="${appStore.outputDirectory}"`
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

// 获取 Docker Hub 镜像标签
const fetchDockerTags = async () => {
  isLoadingTags.value = true
  dockerTags.value = []
  
  try {
    // 调用 Docker Hub API 获取标签
    const response = await fetch(`https://hub.docker.com/v2/repositories/${selectedRepository.value}/tags?page_size=50&ordering=-last_updated`)
    const data = await response.json()
    
    if (data.results) {
      dockerTags.value = data.results
        .filter((tag: any) => tag.name !== 'latest')
        .map((tag: any) => tag.name)
        .slice(0, 30) // 限制显示前30个
    }
  } catch (error) {
    console.error('Failed to fetch Docker tags:', error)
    // 失败时使用预设标签
    dockerTags.value = popularTags.value
  } finally {
    isLoadingTags.value = false
  }
}

// 切换仓库
const onRepositoryChange = () => {
  appStore.selectedImage = ''
  appStore.customImageTag = ''
  fetchDockerTags()
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
  appStore.buildProgress = 0
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
      } else if (buildEvent.event_type === 'progress') {
        appStore.buildProgress = buildEvent.progress || 0
        appStore.buildLogs.push(buildEvent.data)
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
    const fullImage = tag ? `${selectedRepository.value}:${tag}` : ''
    
    await invoke('start_build', {
      config: {
        image: fullImage,
        profile: appStore.selectedProfile || null,
        modules: appStore.enabledModules.map(m => m.name),
        output_dir: appStore.outputDirectory,
        env_vars: envVars,
        global_env_vars: appStore.globalEnvVars
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

// 清除日志
const clearLogs = () => {
  appStore.clearBuildLogs()
}


onMounted(() => {
  fetchDockerTags()
})
</script>

<template>
  <v-container>
    <!-- 配置快速选择器 -->
    <ConfigQuickSelector />
    
    <v-row>
      <!-- 左侧配置区 -->
      <v-col cols="12" md="6">
        <v-card>
          <v-card-title>
            <v-icon class="mr-2">mdi-docker</v-icon>
            镜像选择
          </v-card-title>
          <v-card-text>
            <!-- 仓库选择 -->
            <v-select
              v-model="selectedRepository"
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
            
            <!-- Docker Hub 标签列表 -->
            <v-expansion-panels variant="accordion">
              <v-expansion-panel>
                <v-expansion-panel-title>
                  <div class="d-flex align-center">
                    <v-icon class="mr-2">mdi-tag-multiple</v-icon>
                    更多可用标签
                    <v-spacer />
                    <v-btn
                      icon="mdi-refresh"
                      size="x-small"
                      variant="text"
                      @click.stop="fetchDockerTags"
                      :loading="isLoadingTags"
                    />
                  </div>
                </v-expansion-panel-title>
                <v-expansion-panel-text>
                  <v-progress-circular
                    v-if="isLoadingTags"
                    indeterminate
                    size="24"
                    width="2"
                    class="ma-4"
                  />
                  <v-list v-else density="compact" max-height="300">
                    <v-list-item
                      v-for="tag in dockerTags"
                      :key="tag"
                      @click="appStore.selectedImage = tag; appStore.customImageTag = ''"
                      :active="appStore.selectedImage === tag"
                    >
                      <v-list-item-title>{{ tag }}</v-list-item-title>
                    </v-list-item>
                  </v-list>
                </v-expansion-panel-text>
              </v-expansion-panel>
            </v-expansion-panels>
          </v-card-text>
        </v-card>
        
        <!-- 构建配置 -->
        <v-card class="mt-4">
          <v-card-title>
            <v-icon class="mr-2">mdi-cog</v-icon>
            构建配置
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
            
          </v-card-text>
        </v-card>
        
        <!-- 构建按钮 -->
        <v-card class="mt-4">
          <v-card-text>
            <v-btn
              color="primary"
              size="large"
              block
              @click="startBuild"
              :disabled="!canStartBuild"
              :loading="appStore.isBuilding"
            >
              <v-icon start>mdi-hammer</v-icon>
              开始构建
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
      </v-col>
      
      <!-- 右侧日志区 -->
      <v-col cols="12" md="6">
        <v-card style="height: 100%">
          <v-card-title class="d-flex align-center">
            <v-icon class="mr-2">mdi-console</v-icon>
            构建日志
            <v-spacer />
            <v-btn
              icon="mdi-delete"
              size="small"
              variant="text"
              @click="clearLogs"
              :disabled="appStore.isBuilding"
            />
          </v-card-title>
          <v-card-text>
            <!-- 构建进度 -->
            <v-progress-linear
              v-if="appStore.isBuilding"
              :model-value="appStore.buildProgress"
              color="primary"
              height="20"
              rounded
              class="mb-4"
            >
              <template v-slot:default="{ value }">
                <strong>{{ value }}%</strong>
              </template>
            </v-progress-linear>
            
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
            
            <!-- 构建控制 -->
            <div v-if="appStore.isBuilding" class="mt-4">
              <v-btn
                color="error"
                block
                @click="cancelBuild"
              >
                <v-icon start>mdi-stop</v-icon>
                取消构建
              </v-btn>
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
  </v-container>
</template>