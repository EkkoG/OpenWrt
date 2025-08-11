import { defineStore } from 'pinia'
import { ref, computed, watch } from 'vue'

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
  const selectedRepository = ref('immortalwrt/imagebuilder')  // 镜像仓库
  const selectedProfile = ref('')  // 添加 profile 字段
  const outputDirectory = ref('')
  const globalEnvVars = ref('')  // 全局环境变量
  const customModulesPath = ref<string | null>(null)  // 自定义模块路径
  
  // ImageBuilder 配置选项
  const rootfsPartSize = ref<number | null>(null)  // CONFIG_TARGET_ROOTFS_PARTSIZE，留空由 ImageBuilder 决定
  
  // 高级构建选项
  const advancedOptions = ref({
    withPull: false,
    rmFirst: false,
    useMirror: false,
    mirrorUrl: ''
  })
  
  // 模块配置
  const modules = ref<Array<{
    name: string
    enabled: boolean
    envVars: Record<string, string>
    description: string
    hasReadme: boolean
    source: 'built' | 'custom'
  }>>([])

  // 构建状态
  const isBuilding = ref(false)
  const buildLogs = ref<string[]>([])
  const lastBuildTime = ref<Date | null>(null)
  const lastBuildStatus = ref<'success' | 'failed' | 'cancelled' | null>(null)

  // 应用设置
  const checkForUpdates = ref(true)
  const theme = ref<'light' | 'dark' | 'auto'>('light')
  const language = ref<string>('zh-CN')

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
        source: string
      }>>('get_modules', { customModulesPath: customModulesPath.value })
      
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
        hasReadme: m.has_readme,
        source: m.source as 'built' | 'custom'
      }))
      
    } catch (error) {
      console.error('Failed to load modules:', error)
    }
  }


  const loadActiveConfiguration = async () => {
    try {
      const { invoke } = await import('@tauri-apps/api/core')
      const configurations = await invoke<Array<{
        id: string
        name: string
        description: string
        config: {
          selectedImage: string
          customImageTag: string
          selectedRepository: string
          selectedProfile: string
          outputDirectory: string
          globalEnvVars: string
          rootfsPartSize: number | null
          modules: Array<{
            name: string
            enabled: boolean
            envVars: Record<string, string>
          }>
          advancedOptions?: {
            withPull: boolean
            rmFirst: boolean
            useMirror: boolean
            mirrorUrl: string
          }
        }
        createdAt: string
        updatedAt: string
        isActive: boolean
      }>>('get_configurations')
      
      // 找到当前活跃的配置
      const activeConfig = configurations.find(c => c.isActive)
      if (activeConfig) {
        // 恢复构建设置
        selectedImage.value = activeConfig.config.selectedImage
        customImageTag.value = activeConfig.config.customImageTag
        selectedRepository.value = activeConfig.config.selectedRepository || 'immortalwrt/imagebuilder'
        selectedProfile.value = activeConfig.config.selectedProfile
        outputDirectory.value = activeConfig.config.outputDirectory
        globalEnvVars.value = activeConfig.config.globalEnvVars
        rootfsPartSize.value = activeConfig.config.rootfsPartSize || null
        
        // 恢复高级选项
        if (activeConfig.config.advancedOptions) {
          advancedOptions.value = { ...activeConfig.config.advancedOptions }
        }
        
        // 恢复模块状态
        activeConfig.config.modules.forEach(savedModule => {
          const currentModule = modules.value.find(m => m.name === savedModule.name)
          if (currentModule) {
            currentModule.enabled = savedModule.enabled
            currentModule.envVars = { ...currentModule.envVars, ...savedModule.envVars }
          }
        })
        
        console.log('Active configuration loaded:', activeConfig.name)
      } else {
        console.log('No active configuration found, using defaults')
      }
    } catch (error) {
      console.error('Failed to load active configuration:', error)
    }
  }

  const startBuild = async () => {
    if (!canStartBuild.value) return
    
    isBuilding.value = true
    buildLogs.value = []
    
    // 将在后续任务中实现具体构建逻辑
    console.log('Starting build...')
  }

  const cancelBuild = () => {
    if (!isBuilding.value) return
    
    isBuilding.value = false
    lastBuildStatus.value = 'cancelled'
    buildLogs.value.push('[Build cancelled]')
  }

  const clearBuildLogs = () => {
    buildLogs.value = []
  }

  const loadSettings = () => {
    try {
      const savedTheme = localStorage.getItem('app-theme')
      if (savedTheme && ['light', 'dark', 'auto'].includes(savedTheme)) {
        theme.value = savedTheme as 'light' | 'dark' | 'auto'
      }
      
      const savedCheckUpdates = localStorage.getItem('app-check-updates')
      if (savedCheckUpdates) {
        checkForUpdates.value = savedCheckUpdates === 'true'
      }
      
      const savedLanguage = localStorage.getItem('language')
      if (savedLanguage) {
        language.value = savedLanguage
      }
    } catch (error) {
      console.error('Failed to load settings:', error)
    }
  }

  const saveSettings = () => {
    try {
      localStorage.setItem('app-theme', theme.value)
      localStorage.setItem('app-check-updates', checkForUpdates.value.toString())
      localStorage.setItem('language', language.value)
    } catch (error) {
      console.error('Failed to save settings:', error)
    }
  }

  const updateSettings = (settings: Partial<{
    checkForUpdates: boolean
    theme: 'light' | 'dark' | 'auto'
    language: string
  }>) => {
    if (settings.checkForUpdates !== undefined) checkForUpdates.value = settings.checkForUpdates
    if (settings.theme) theme.value = settings.theme
    if (settings.language) language.value = settings.language
    saveSettings()
  }

  // 自动保存设置变化
  watch([theme, checkForUpdates, language], () => {
    saveSettings()
  })

  return {
    // 状态
    dockerInstalled,
    dockerVersion,
    dockerComposeInstalled,
    dockerComposeVersion,
    dockerRunning,
    selectedImage,
    customImageTag,
    selectedRepository,
    selectedProfile,
    outputDirectory,
    globalEnvVars,
    customModulesPath,
    rootfsPartSize,
    advancedOptions,
    modules,
    isBuilding,
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
    loadActiveConfiguration,
    startBuild,
    cancelBuild,
    clearBuildLogs,
    loadSettings,
    saveSettings,
    updateSettings
  }
})