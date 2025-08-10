import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { invoke } from '@tauri-apps/api/core'

export interface ModuleConfig {
  name: string
  enabled: boolean
  envVars: Record<string, string>
}

export interface AdvancedBuildOptions {
  withPull: boolean
  rmFirst: boolean
  useMirror: boolean
  mirrorUrl: string
}

export interface BuildConfig {
  selectedImage: string
  customImageTag: string
  selectedRepository: string
  selectedProfile: string
  outputDirectory: string
  globalEnvVars: string
  modules: ModuleConfig[]
  advancedOptions?: AdvancedBuildOptions
  customModulesPath?: string
  rootfsPartSize?: number | null
}

export interface Configuration {
  id: string
  name: string
  description: string
  config: BuildConfig
  createdAt: Date
  updatedAt: Date
  isActive: boolean
}

export const useConfigStore = defineStore('config', () => {
  const configurations = ref<Configuration[]>([])
  const activeConfigId = ref<string | null>(null)
  const isLoading = ref(false)
  const error = ref<string | null>(null)

  const activeConfig = computed(() => 
    configurations.value.find(c => c.id === activeConfigId.value)
  )

  const sortedConfigurations = computed(() =>
    [...configurations.value].sort((a, b) => 
      b.updatedAt.getTime() - a.updatedAt.getTime()
    )
  )

  async function loadConfigurations() {
    isLoading.value = true
    error.value = null
    try {
      const configs = await invoke<Configuration[]>('get_configurations')
      configurations.value = configs.map(c => ({
        ...c,
        createdAt: new Date(c.createdAt),
        updatedAt: new Date(c.updatedAt)
      }))
      
      const active = configurations.value.find(c => c.isActive)
      if (active) {
        activeConfigId.value = active.id
      }
    } catch (e) {
      error.value = `加载配置失败: ${e}`
      console.error('Failed to load configurations:', e)
    } finally {
      isLoading.value = false
    }
  }

  async function saveConfiguration(name: string, description: string, config: BuildConfig) {
    isLoading.value = true
    error.value = null
    try {
      const newConfig = await invoke<Configuration>('save_configuration', {
        name,
        description,
        config
      })
      
      configurations.value.push({
        ...newConfig,
        createdAt: new Date(newConfig.createdAt),
        updatedAt: new Date(newConfig.updatedAt)
      })
      
      return newConfig
    } catch (e) {
      error.value = `保存配置失败: ${e}`
      console.error('Failed to save configuration:', e)
      throw e
    } finally {
      isLoading.value = false
    }
  }

  async function updateConfiguration(id: string, updates: Partial<Configuration>) {
    isLoading.value = true
    error.value = null
    try {
      const updated = await invoke<Configuration>('update_configuration', {
        id,
        updates
      })
      
      const index = configurations.value.findIndex(c => c.id === id)
      if (index !== -1) {
        configurations.value[index] = {
          ...updated,
          createdAt: new Date(updated.createdAt),
          updatedAt: new Date(updated.updatedAt)
        }
      }
      
      return updated
    } catch (e) {
      error.value = `更新配置失败: ${e}`
      console.error('Failed to update configuration:', e)
      throw e
    } finally {
      isLoading.value = false
    }
  }

  async function deleteConfiguration(id: string) {
    isLoading.value = true
    error.value = null
    try {
      await invoke('delete_configuration', { id })
      
      configurations.value = configurations.value.filter(c => c.id !== id)
      
      if (activeConfigId.value === id) {
        activeConfigId.value = null
      }
    } catch (e) {
      error.value = `删除配置失败: ${e}`
      console.error('Failed to delete configuration:', e)
      throw e
    } finally {
      isLoading.value = false
    }
  }

  async function switchConfiguration(id: string) {
    isLoading.value = true
    error.value = null
    try {
      await invoke('switch_configuration', { id })
      
      configurations.value.forEach(c => {
        c.isActive = c.id === id
      })
      
      activeConfigId.value = id
    } catch (e) {
      error.value = `切换配置失败: ${e}`
      console.error('Failed to switch configuration:', e)
      throw e
    } finally {
      isLoading.value = false
    }
  }

  async function duplicateConfiguration(id: string, newName: string) {
    isLoading.value = true
    error.value = null
    try {
      const original = configurations.value.find(c => c.id === id)
      if (!original) throw new Error('配置不存在')
      
      const duplicated = await invoke<Configuration>('duplicate_configuration', {
        id,
        newName
      })
      
      configurations.value.push({
        ...duplicated,
        createdAt: new Date(duplicated.createdAt),
        updatedAt: new Date(duplicated.updatedAt)
      })
      
      return duplicated
    } catch (e) {
      error.value = `复制配置失败: ${e}`
      console.error('Failed to duplicate configuration:', e)
      throw e
    } finally {
      isLoading.value = false
    }
  }

  async function exportConfiguration(id: string, path: string) {
    isLoading.value = true
    error.value = null
    try {
      await invoke('export_configuration', { id, path })
    } catch (e) {
      error.value = `导出配置失败: ${e}`
      console.error('Failed to export configuration:', e)
      throw e
    } finally {
      isLoading.value = false
    }
  }

  async function importConfiguration(path: string) {
    isLoading.value = true
    error.value = null
    try {
      const imported = await invoke<Configuration>('import_configuration', { path })
      
      configurations.value.push({
        ...imported,
        createdAt: new Date(imported.createdAt),
        updatedAt: new Date(imported.updatedAt)
      })
      
      return imported
    } catch (e) {
      error.value = `导入配置失败: ${e}`
      console.error('Failed to import configuration:', e)
      throw e
    } finally {
      isLoading.value = false
    }
  }

  function getCurrentBuildConfig(): BuildConfig | null {
    if (!activeConfig.value) return null
    return activeConfig.value.config
  }

  function applyConfigToStore(config: BuildConfig, appStore: any) {
    appStore.selectedImage = config.selectedImage
    appStore.customImageTag = config.customImageTag
    appStore.selectedRepository = config.selectedRepository || 'immortalwrt/imagebuilder'
    appStore.selectedProfile = config.selectedProfile
    appStore.outputDirectory = config.outputDirectory
    appStore.globalEnvVars = config.globalEnvVars
    // 恢复模块状态，保持原有的 description 和其他字段
    config.modules.forEach(configModule => {
      const currentModule = appStore.modules.find((m: any) => m.name === configModule.name)
      if (currentModule) {
        currentModule.enabled = configModule.enabled
        currentModule.envVars = { ...configModule.envVars }
      }
    })
    
    // 恢复自定义模块路径（现在是配置级别的设置）
    appStore.customModulesPath = config.customModulesPath || null
    
    // 恢复 RootFS 分区大小配置
    appStore.rootfsPartSize = config.rootfsPartSize === undefined ? null : config.rootfsPartSize
    
    // 恢复高级选项
    if (config.advancedOptions) {
      appStore.advancedOptions = { ...config.advancedOptions }
    }
  }

  function extractConfigFromStore(appStore: any): BuildConfig {
    // 确保 rootfsPartSize 是数字或 null
    const rootfsPartSize = appStore.rootfsPartSize === null || appStore.rootfsPartSize === undefined || appStore.rootfsPartSize === '' 
      ? null 
      : Number(appStore.rootfsPartSize)
    
    return {
      selectedImage: appStore.selectedImage,
      customImageTag: appStore.customImageTag,
      selectedRepository: appStore.selectedRepository || 'immortalwrt/imagebuilder',
      selectedProfile: appStore.selectedProfile,
      outputDirectory: appStore.outputDirectory,
      globalEnvVars: appStore.globalEnvVars,
      customModulesPath: appStore.customModulesPath || undefined,
      rootfsPartSize: rootfsPartSize,
      modules: appStore.modules.map((module: any) => ({
        name: module.name,
        enabled: module.enabled,
        envVars: module.envVars
        // 不保存 description 字段
      })),
      advancedOptions: appStore.advancedOptions ? { ...appStore.advancedOptions } : undefined
    }
  }

  // 取消激活当前配置并重置状态
  async function deactivateConfiguration(appStore: any) {
    isLoading.value = true
    error.value = null
    try {
      // 后端取消激活
      await invoke('deactivate_configuration')
      
      // 更新本地状态
      configurations.value.forEach(config => {
        config.isActive = false
      })
      activeConfigId.value = null
      
      // 重置应用状态到默认值（包括自定义模块路径）
      resetToDefaultState(appStore)
      
      // 重新加载模块（使用默认状态）
      await appStore.loadModules()
      
    } catch (e) {
      error.value = `取消激活配置失败: ${e}`
      console.error('Failed to deactivate configuration:', e)
      throw e
    } finally {
      isLoading.value = false
    }
  }

  // 重置应用状态到默认值
  function resetToDefaultState(appStore: any) {
    appStore.selectedImage = ''
    appStore.customImageTag = ''
    appStore.selectedRepository = 'immortalwrt/imagebuilder'
    appStore.selectedProfile = ''
    appStore.outputDirectory = ''
    appStore.globalEnvVars = ''
    appStore.customModulesPath = null
    appStore.rootfsPartSize = null  // 重置为默认值（由 ImageBuilder 决定）
    
    // 重置高级选项
    appStore.advancedOptions = {
      withPull: false,
      rmFirst: false,
      useMirror: false,
      mirrorUrl: ''
    }
    
    // 重置所有模块为禁用状态
    appStore.modules.forEach((module: any) => {
      module.enabled = false
      // 重置环境变量到默认值
      Object.keys(module.envVars || {}).forEach(key => {
        module.envVars[key] = ''
      })
    })
  }

  return {
    configurations,
    activeConfigId,
    activeConfig,
    sortedConfigurations,
    isLoading,
    error,
    
    loadConfigurations,
    saveConfiguration,
    updateConfiguration,
    deleteConfiguration,
    switchConfiguration,
    duplicateConfiguration,
    exportConfiguration,
    importConfiguration,
    getCurrentBuildConfig,
    deactivateConfiguration,
    resetToDefaultState,
    applyConfigToStore,
    extractConfigFromStore
  }
})