import { defineStore } from 'pinia'
import { ref, computed } from 'vue'

export const useAppStore = defineStore('app', () => {
  // Docker 环境状态
  const dockerInstalled = ref(false)
  const dockerVersion = ref('')
  const dockerComposeInstalled = ref(false)
  const dockerComposeVersion = ref('')
  const dockerRunning = ref(false)

  // 构建配置
  const selectedImage = ref('')
  const customImageTag = ref('')
  const selectedProfile = ref('')  // 添加 profile 字段
  const outputDirectory = ref('')
  const globalEnvVars = ref('')  // 全局环境变量
  
  // 模块配置
  const modules = ref<Array<{
    name: string
    enabled: boolean
    envVars: Record<string, string>
    description: string
    hasReadme: boolean
  }>>([])

  // 构建状态
  const isBuilding = ref(false)
  const buildProgress = ref(0)
  const buildLogs = ref<string[]>([])
  const lastBuildTime = ref<Date | null>(null)
  const lastBuildStatus = ref<'success' | 'failed' | 'cancelled' | null>(null)

  // 应用设置
  const checkForUpdates = ref(true)
  const theme = ref<'light' | 'dark' | 'auto'>('light')
  const language = ref('zh-CN')

  // 计算属性
  const dockerReady = computed(() => 
    dockerInstalled.value && dockerRunning.value
  )

  const canStartBuild = computed(() => 
    dockerReady.value && 
    !isBuilding.value && 
    (selectedImage.value || customImageTag.value) &&
    outputDirectory.value
  )

  const enabledModules = computed(() => 
    modules.value.filter(m => m.enabled)
  )

  // 方法
  const checkDockerEnvironment = async () => {
    try {
      const { invoke } = await import('@tauri-apps/api/core')
      const dockerInfo = await invoke<{
        installed: boolean
        running: boolean
        version: string
        compose_installed: boolean
        compose_version: string
      }>('check_docker_environment')
      
      dockerInstalled.value = dockerInfo.installed
      dockerRunning.value = dockerInfo.running
      dockerVersion.value = dockerInfo.version
      dockerComposeInstalled.value = dockerInfo.compose_installed
      dockerComposeVersion.value = dockerInfo.compose_version
      
      console.log('Docker environment check completed:', dockerInfo)
    } catch (error) {
      console.error('Failed to check Docker environment:', error)
      dockerInstalled.value = false
      dockerRunning.value = false
    }
  }

  const loadModules = async () => {
    try {
      const { invoke } = await import('@tauri-apps/api/core')
      const moduleList = await invoke<Array<{
        name: string
        path: string
        has_packages: boolean
        has_env_example: boolean
        has_readme: boolean
        has_files: boolean
        has_scripts: string[]
        env_vars: Array<{
          name: string
          value: string
          description: string
        }>
        description: string
      }>>('get_modules')
      
      // DEFAULT_MODULE_SET from build.sh
      const defaultModuleSet = new Set([
        'add-all-device-to-lan', 'add-feed-key', 'add-feed', 'ib', 
        'argon', 'base', 'opkg-mirror', 'prefer-ipv6-settings', 
        'statistics', 'system', 'tools'
      ])
      
      modules.value = moduleList.map(m => ({
        name: m.name,
        enabled: defaultModuleSet.has(m.name),
        envVars: m.env_vars.reduce((acc, v) => {
          acc[v.name] = v.value
          return acc
        }, {} as Record<string, string>),
        description: m.description,
        hasReadme: m.has_readme
      }))
      
      console.log('Modules loaded:', modules.value)
    } catch (error) {
      console.error('Failed to load modules:', error)
    }
  }

  const startBuild = async () => {
    if (!canStartBuild.value) return
    
    isBuilding.value = true
    buildProgress.value = 0
    buildLogs.value = []
    
    // 将在后续任务中实现具体构建逻辑
    console.log('Starting build...')
  }

  const cancelBuild = () => {
    if (!isBuilding.value) return
    
    isBuilding.value = false
    lastBuildStatus.value = 'cancelled'
    buildLogs.value.push('[构建已取消]')
  }

  const clearBuildLogs = () => {
    buildLogs.value = []
  }

  const updateSettings = (settings: Partial<{
    checkForUpdates: boolean
    theme: 'light' | 'dark' | 'auto'
    language: string
  }>) => {
    if (settings.checkForUpdates !== undefined) checkForUpdates.value = settings.checkForUpdates
    if (settings.theme) theme.value = settings.theme
    if (settings.language) language.value = settings.language
  }

  return {
    // 状态
    dockerInstalled,
    dockerVersion,
    dockerComposeInstalled,
    dockerComposeVersion,
    dockerRunning,
    selectedImage,
    customImageTag,
    selectedProfile,
    outputDirectory,
    globalEnvVars,
    modules,
    isBuilding,
    buildProgress,
    buildLogs,
    lastBuildTime,
    lastBuildStatus,
    checkForUpdates,
    theme,
    language,
    
    // 计算属性
    dockerReady,
    canStartBuild,
    enabledModules,
    
    // 方法
    checkDockerEnvironment,
    loadModules,
    startBuild,
    cancelBuild,
    clearBuildLogs,
    updateSettings
  }
})