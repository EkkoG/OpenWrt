<script setup lang="ts">
import { useAppStore } from '@/stores/app'
import { ref, computed, onMounted } from 'vue'
import ModuleDetailDialog from '@/components/ModuleDetailDialog.vue'
// import { invoke } from '@tauri-apps/api/core'  // 使用动态导入

const appStore = useAppStore()
const searchQuery = ref('')
// const expandedModules = ref<string[]>([]) // Reserved for future expansion control
const isLoading = ref(false)

// 详细介绍对话框状态
const detailDialog = ref(false)
const selectedModule = ref({ name: '', description: '' })

const filteredModules = computed(() => {
  if (!searchQuery.value) {
    return appStore.modules
  }
  
  const query = searchQuery.value.toLowerCase()
  return appStore.modules.filter(m => 
    m.name.toLowerCase().includes(query) ||
    m.description.toLowerCase().includes(query)
  )
})

const toggleModule = (moduleName: string) => {
  const module = appStore.modules.find(m => m.name === moduleName)
  if (module) {
    module.enabled = !module.enabled
  }
}

// Removed unused toggleExpand and isExpanded functions
// expandedModules is kept for potential future use

const hasEnvVars = (module: any) => {
  return Object.keys(module.envVars || {}).length > 0
}

const showModuleDetail = (module: any) => {
  selectedModule.value = {
    name: module.name,
    description: module.description
  }
  detailDialog.value = true
}

const refreshModules = async () => {
  isLoading.value = true
  await appStore.loadModules()
  isLoading.value = false
}

const selectAll = () => {
  appStore.modules.forEach(m => {
    m.enabled = true
  })
}

const deselectAll = () => {
  appStore.modules.forEach(m => {
    m.enabled = false
  })
}

const selectUserModulesDirectory = async () => {
  try {
    const { invoke } = await import('@tauri-apps/api/core')
    const selectedPath = await invoke('select_user_modules_directory') as string
    if (selectedPath && typeof selectedPath === 'string') {
      // 验证路径
      const isValid = await invoke('validate_user_modules_path', { path: selectedPath })
      
      if (isValid) {
        // 直接更新 appStore 中的值
        appStore.userModulesPath = selectedPath
        
        // 重新加载模块
        await refreshModules()
        console.log('用户模块目录已更新:', selectedPath)
      } else {
        console.error('选择的路径无效')
      }
    }
  } catch (error) {
    console.error('选择用户模块目录失败:', error)
  }
}

onMounted(() => {
  if (appStore.modules.length === 0) {
    refreshModules()
  }
})
</script>

<template>
  <v-card>
    <v-card-title class="d-flex align-center">
      <v-icon class="mr-2">mdi-package-variant</v-icon>
      模块配置
      <v-spacer />
      <v-btn
        color="primary"
        variant="text"
        size="small"
        @click="selectAll"
        :disabled="isLoading"
      >
        全选
      </v-btn>
      <v-btn
        color="secondary"
        variant="text"
        size="small"
        @click="deselectAll"
        :disabled="isLoading"
      >
        全不选
      </v-btn>
      <v-btn
        color="info"
        variant="outlined"
        size="small"
        @click="selectUserModulesDirectory"
        :disabled="isLoading"
        prepend-icon="mdi-folder-open"
        class="ml-4"
      >
        选择用户模块目录
      </v-btn>
      <v-btn
        color="primary"
        variant="tonal"
        size="small"
        @click="refreshModules"
        :loading="isLoading"
        prepend-icon="mdi-refresh"
        class="ml-4"
      >
        刷新
      </v-btn>
    </v-card-title>
    
    <v-card-text>
      <!-- 搜索栏 -->
      <v-text-field
        v-model="searchQuery"
        label="搜索模块"
        prepend-inner-icon="mdi-magnify"
        variant="outlined"
        density="compact"
        clearable
        class="mb-4"
      />
      
      <!-- 模块统计 -->
      <v-alert
        type="info"
        variant="tonal"
        density="compact"
        class="mb-4"
      >
        <div class="d-flex align-center">
          <span>
            共 {{ appStore.modules.length }} 个模块，
            已启用 {{ appStore.enabledModules.length }} 个
          </span>
        </div>
      </v-alert>
            
            <!-- 模块列表 -->
            <div 
              v-if="filteredModules.length > 0"
              style="max-height: 600px; overflow-y: auto; border-radius: 4px;"
              class="mb-4"
            >
              <v-expansion-panels
                variant="accordion"
              >
              <v-expansion-panel
                v-for="module in filteredModules"
                :key="module.name"
              >
                <v-expansion-panel-title>
                  <div class="d-flex align-center" style="width: 100%">
                    <v-checkbox
                      :model-value="module.enabled"
                      @update:model-value="toggleModule(module.name)"
                      @click.stop
                      density="compact"
                      hide-details
                      class="flex-grow-0 mr-3"
                    />
                    <div class="flex-grow-1">
                      <div class="font-weight-medium d-flex align-center">
                        {{ module.name }}
                        <v-chip
                          v-if="appStore.userModulesPath && module.source === 'user'"
                          size="x-small"
                          color="success"
                          variant="tonal"
                          class="ml-2"
                        >
                          用户
                        </v-chip>
                        <v-chip
                          v-if="appStore.userModulesPath && module.source === 'built'"
                          size="x-small"
                          color="info"
                          variant="tonal"
                          class="ml-2"
                        >
                          内置
                        </v-chip>
                      </div>
                      <div class="text-caption text-medium-emphasis">
                        {{ module.description }}
                      </div>
                    </div>
                    <v-chip
                      v-if="hasEnvVars(module)"
                      size="x-small"
                      color="primary"
                      variant="tonal"
                      class="ml-2"
                    >
                      需配置
                    </v-chip>
                    <v-btn
                      v-if="module.hasReadme"
                      size="x-small"
                      variant="text"
                      color="info"
                      class="ml-2"
                      @click.stop="showModuleDetail(module)"
                    >
                      <v-icon>mdi-information-outline</v-icon>
                      <v-tooltip activator="parent" location="top">查看详细介绍</v-tooltip>
                    </v-btn>
                  </div>
                </v-expansion-panel-title>
                
                <v-expansion-panel-text>
                  <div v-if="hasEnvVars(module)">
                    <div class="text-subtitle-2 mb-2">环境变量配置</div>
                    <v-text-field
                      v-for="(_, key) in module.envVars"
                      :key="key"
                      v-model="module.envVars[key]"
                      :label="key"
                      variant="outlined"
                      density="compact"
                      class="mb-2"
                    />
                  </div>
                  <div v-else class="text-body-2 text-medium-emphasis">
                    此模块无需额外配置
                  </div>
                </v-expansion-panel-text>
              </v-expansion-panel>
              </v-expansion-panels>
            </div>
            
            <!-- 空状态 -->
            <v-alert
              v-else-if="!isLoading"
              type="info"
              variant="tonal"
              class="text-center"
            >
              <v-icon size="48" class="mb-3">mdi-package-variant-closed</v-icon>
              <div class="text-h6">没有找到模块</div>
              <div class="text-caption">
                {{ searchQuery ? '尝试修改搜索条件' : '点击刷新按钮加载模块' }}
              </div>
            </v-alert>
            
            <!-- 加载中 -->
            <div v-if="isLoading" class="text-center pa-8">
              <v-progress-circular indeterminate color="primary" />
              <div class="text-caption mt-3">正在加载模块...</div>
            </div>
          </v-card-text>
        </v-card>

    <!-- 模块详细介绍对话框 -->
    <ModuleDetailDialog
      v-model="detailDialog"
      :module-name="selectedModule.name"
      :module-description="selectedModule.description"
    />
</template>