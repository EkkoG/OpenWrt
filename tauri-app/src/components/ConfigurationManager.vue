<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useConfigStore } from '@/stores/config'
import { useAppStore } from '@/stores/app'
import { open, save } from '@tauri-apps/plugin-dialog'

const configStore = useConfigStore()
const appStore = useAppStore()

const showDeleteDialog = ref(false)
const showDuplicateDialog = ref(false)
const showPreviewDialog = ref(false)
const selectedConfig = ref<any>(null)
const duplicateName = ref('')
const searchQuery = ref('')

const filteredConfigurations = computed(() => {
  if (!searchQuery.value) {
    return configStore.sortedConfigurations
  }
  
  const query = searchQuery.value.toLowerCase()
  return configStore.sortedConfigurations.filter(c => 
    c.name.toLowerCase().includes(query) || 
    c.description.toLowerCase().includes(query)
  )
})

onMounted(() => {
  configStore.loadConfigurations()
})


const loadConfiguration = async (config: any) => {
  try {
    await configStore.switchConfiguration(config.id)
    configStore.applyConfigToStore(config.config, appStore)
  } catch (error) {
    console.error('Failed to load configuration:', error)
  }
}

const deleteConfiguration = async () => {
  if (!selectedConfig.value) return
  
  try {
    await configStore.deleteConfiguration(selectedConfig.value.id)
    showDeleteDialog.value = false
    selectedConfig.value = null
  } catch (error) {
    console.error('Failed to delete configuration:', error)
  }
}

const duplicateConfiguration = async () => {
  if (!selectedConfig.value) return
  
  try {
    await configStore.duplicateConfiguration(
      selectedConfig.value.id,
      duplicateName.value
    )
    showDuplicateDialog.value = false
    duplicateName.value = ''
    selectedConfig.value = null
  } catch (error) {
    console.error('Failed to duplicate configuration:', error)
  }
}

const exportConfiguration = async (config: any) => {
  try {
    const path = await save({
      filters: [{
        name: 'JSON',
        extensions: ['json']
      }],
      defaultPath: `${config.name}.json`
    })
    
    if (path) {
      await configStore.exportConfiguration(config.id, path)
    }
  } catch (error) {
    console.error('Failed to export configuration:', error)
  }
}

const importConfiguration = async () => {
  try {
    const file = await open({
      filters: [{
        name: 'JSON',
        extensions: ['json']
      }],
      multiple: false
    })
    
    if (file) {
      await configStore.importConfiguration(file as string)
    }
  } catch (error) {
    console.error('Failed to import configuration:', error)
  }
}

const formatDate = (date: Date) => {
  return new Date(date).toLocaleString('zh-CN', {
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit'
  })
}

const openDeleteDialog = (config: any) => {
  selectedConfig.value = config
  showDeleteDialog.value = true
}

const openDuplicateDialog = (config: any) => {
  selectedConfig.value = config
  duplicateName.value = `${config.name} (副本)`
  showDuplicateDialog.value = true
}

const openPreviewDialog = (config: any) => {
  selectedConfig.value = config
  showPreviewDialog.value = true
}

// 生成配置的 JSON 预览
const generateConfigPreview = (config: any) => {
  if (!config) return ''
  
  // 直接返回格式化的 JSON
  return JSON.stringify(config, null, 2)
}

// 复制配置预览文本
const copyPreviewText = async () => {
  if (!selectedConfig.value) return
  
  const previewText = generateConfigPreview(selectedConfig.value)
  
  try {
    const { writeText } = await import('@tauri-apps/plugin-clipboard-manager')
    await writeText(previewText)
  } catch (error) {
    try {
      await navigator.clipboard.writeText(previewText)
    } catch (fallbackError) {
      console.error('Failed to copy preview text:', fallbackError)
    }
  }
}
</script>

<template>
  <v-container fluid>
    <v-card>
      <v-card-title class="d-flex align-center">
        <v-icon class="mr-2">mdi-folder-cog</v-icon>
        配置管理
        
        <v-spacer />
        
        <v-text-field
          v-model="searchQuery"
          density="compact"
          variant="solo"
          placeholder="搜索配置..."
          prepend-inner-icon="mdi-magnify"
          single-line
          hide-details
          class="mx-4"
          style="max-width: 300px"
        />
        
        <v-btn
          color="info"
          @click="importConfiguration"
          prepend-icon="mdi-import"
        >
          导入配置
        </v-btn>
      </v-card-title>
      
      <v-card-text>
        <v-progress-linear
          v-if="configStore.isLoading"
          indeterminate
          color="primary"
        />
        
        <v-alert
          v-if="configStore.error"
          type="error"
          closable
          @click:close="configStore.error = null"
          class="mb-4"
        >
          {{ configStore.error }}
        </v-alert>
        
        <v-row v-if="filteredConfigurations.length === 0">
          <v-col cols="12" class="text-center py-8">
            <v-icon size="64" color="grey">mdi-folder-open-outline</v-icon>
            <p class="text-h6 mt-4 text-grey">暂无配置</p>
            <p class="text-body-2 text-grey">在构建页面保存配置或导入已有配置</p>
          </v-col>
        </v-row>
        
        <v-row v-else>
          <v-col
            v-for="config in filteredConfigurations"
            :key="config.id"
            cols="12"
            md="6"
            lg="4"
          >
            <v-card
              :variant="config.isActive ? 'elevated' : 'outlined'"
              :color="config.isActive ? 'primary' : undefined"
              class="h-100"
            >
              <v-card-title class="d-flex align-center">
                <v-icon v-if="config.isActive" class="mr-2">mdi-check-circle</v-icon>
                {{ config.name }}
              </v-card-title>
              
              <v-card-subtitle>
                {{ config.description || '无描述' }}
              </v-card-subtitle>
              
              <v-card-text>
                <v-list density="compact">
                  <v-list-item>
                    <template v-slot:prepend>
                      <v-icon size="small">mdi-source-repository</v-icon>
                    </template>
                    <v-list-item-title>
                      {{ config.config.selectedRepository || 'immortalwrt/imagebuilder' }}
                    </v-list-item-title>
                  </v-list-item>
                  
                  <v-list-item>
                    <template v-slot:prepend>
                      <v-icon size="small">mdi-docker</v-icon>
                    </template>
                    <v-list-item-title>
                      {{ config.config.selectedImage || config.config.customImageTag || '未选择镜像' }}
                    </v-list-item-title>
                  </v-list-item>
                  
                  <v-list-item>
                    <template v-slot:prepend>
                      <v-icon size="small">mdi-cube</v-icon>
                    </template>
                    <v-list-item-title>
                      {{ config.config.modules.filter(m => m.enabled).length }} 个模块已启用
                    </v-list-item-title>
                  </v-list-item>
                  
                  <v-list-item>
                    <template v-slot:prepend>
                      <v-icon size="small">mdi-clock-outline</v-icon>
                    </template>
                    <v-list-item-title>
                      更新于 {{ formatDate(config.updatedAt) }}
                    </v-list-item-title>
                  </v-list-item>
                </v-list>
              </v-card-text>
              
              <v-card-actions>
                <v-btn
                  v-if="!config.isActive"
                  color="primary"
                  variant="text"
                  @click="loadConfiguration(config)"
                >
                  加载
                </v-btn>
                
                <v-btn
                  variant="text"
                  @click="openPreviewDialog(config)"
                >
                  预览
                </v-btn>
                
                <v-btn
                  color="info"
                  variant="text"
                  @click="exportConfiguration(config)"
                >
                  导出
                </v-btn>
                
                <v-btn
                  variant="text"
                  @click="openDuplicateDialog(config)"
                >
                  复制
                </v-btn>
                
                <v-spacer />
                
                <v-btn
                  color="error"
                  variant="text"
                  icon="mdi-delete"
                  @click="openDeleteDialog(config)"
                />
              </v-card-actions>
            </v-card>
          </v-col>
        </v-row>
      </v-card-text>
    </v-card>
    
    <!-- 删除确认对话框 -->
    <v-dialog v-model="showDeleteDialog" max-width="400">
      <v-card>
        <v-card-title>确认删除</v-card-title>
        
        <v-card-text>
          确定要删除配置 "{{ selectedConfig?.name }}" 吗？此操作不可恢复。
        </v-card-text>
        
        <v-card-actions>
          <v-spacer />
          <v-btn @click="showDeleteDialog = false">取消</v-btn>
          <v-btn color="error" @click="deleteConfiguration">删除</v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>
    
    <!-- 复制配置对话框 -->
    <v-dialog v-model="showDuplicateDialog" max-width="500">
      <v-card>
        <v-card-title>复制配置</v-card-title>
        
        <v-card-text>
          <v-text-field
            v-model="duplicateName"
            label="新配置名称"
            variant="outlined"
            density="compact"
          />
        </v-card-text>
        
        <v-card-actions>
          <v-spacer />
          <v-btn @click="showDuplicateDialog = false">取消</v-btn>
          <v-btn
            color="primary"
            @click="duplicateConfiguration"
            :disabled="!duplicateName"
          >
            复制
          </v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>
    
    <!-- 配置预览对话框 -->
    <v-dialog v-model="showPreviewDialog" max-width="900" scrollable>
      <v-card>
        <v-card-title class="d-flex align-center">
          <v-icon class="mr-2">mdi-code-json</v-icon>
          配置 JSON - {{ selectedConfig?.name }}
          <v-spacer />
          <v-btn
            variant="text"
            @click="copyPreviewText"
            prepend-icon="mdi-content-copy"
          >
            复制 JSON
          </v-btn>
        </v-card-title>
        
        <v-card-text style="height: 600px;">
          <pre class="config-preview-text">{{ selectedConfig ? generateConfigPreview(selectedConfig) : '' }}</pre>
        </v-card-text>
        
        <v-card-actions>
          <v-spacer />
          <v-btn @click="showPreviewDialog = false">关闭</v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>
  </v-container>
</template>

<style scoped>
.config-preview-text {
  font-family: 'Courier New', monospace;
  font-size: 13px;
  line-height: 1.4;
  color: var(--v-theme-on-surface);
  background-color: var(--v-theme-surface-variant);
  padding: 16px;
  border-radius: 8px;
  overflow-x: auto;
  white-space: pre-wrap;
  word-wrap: break-word;
}
</style>