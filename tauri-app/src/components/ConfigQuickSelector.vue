<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useConfigStore } from '@/stores/config'
import { useAppStore } from '@/stores/app'
import { useI18n } from 'vue-i18n'

const configStore = useConfigStore()
const appStore = useAppStore()
const { t } = useI18n()

const selectedConfigId = ref<string | null>(null)
const showSaveDialog = ref(false)
const configName = ref('')
const configDescription = ref('')
const isSaving = ref(false)
const saveError = ref<string | null>(null)
const isUpdatingExisting = ref(false)

onMounted(async () => {
  await configStore.loadConfigurations()
  if (configStore.activeConfig) {
    selectedConfigId.value = configStore.activeConfig.id
  }
})

const handleConfigChange = async (configId: string | null) => {
  if (!configId) {
    // 当清空选择时，取消激活配置并重置状态
    selectedConfigId.value = null
    try {
      await configStore.deactivateConfiguration(appStore)
    } catch (error) {
      console.error('Failed to deactivate configuration:', error)
    }
    return
  }
  
  const config = configStore.configurations.find(c => c.id === configId)
  if (!config) return
  
  try {
    await configStore.switchConfiguration(configId)
    configStore.applyConfigToStore(config.config, appStore)
  } catch (error) {
    console.error('Failed to switch configuration:', error)
  }
}

const openSaveDialog = () => {
  // 如果有当前选中的配置，使用其名称和描述
  if (configStore.activeConfig) {
    configName.value = configStore.activeConfig.name
    configDescription.value = configStore.activeConfig.description
    isUpdatingExisting.value = true
  } else {
    // 否则使用默认的新配置名称
    configName.value = `${t('config.configName')} - ${new Date().toLocaleString('zh-CN', { 
      year: 'numeric',
      month: '2-digit', 
      day: '2-digit',
      hour: '2-digit',
      minute: '2-digit'
    })}`
    configDescription.value = ''
    isUpdatingExisting.value = false
  }
  showSaveDialog.value = true
}

const saveQuickConfig = async () => {
  if (!configName.value.trim() || isSaving.value) return
  
  isSaving.value = true
  saveError.value = null
  
  const config = configStore.extractConfigFromStore(appStore)
  
  try {
    let savedConfig
    
    // 如果有当前激活的配置且名称相同，则更新该配置
    if (configStore.activeConfig && configStore.activeConfig.name === configName.value.trim()) {
      console.log('Updating existing configuration:', configStore.activeConfig.id)
      
      savedConfig = await configStore.updateConfiguration(configStore.activeConfig.id, {
        description: configDescription.value || t('config.defaultDescription'),
        config: config
      })
      
      console.log('Configuration updated successfully:', savedConfig)
    } else {
      // 否则创建新配置
      console.log('Creating new configuration with data:', { name: configName.value, description: configDescription.value, config })
      
      savedConfig = await configStore.saveConfiguration(
        configName.value.trim(),
        configDescription.value || t('config.defaultDescription'),
        config
      )
      
      console.log('Configuration created successfully:', savedConfig)
      
      // 新建配置后切换到它
      selectedConfigId.value = savedConfig.id
      await configStore.switchConfiguration(savedConfig.id)
    }
    
    showSaveDialog.value = false
    configName.value = ''
    configDescription.value = ''
    saveError.value = null
  } catch (error: any) {
    console.error('Failed to save configuration:', error)
    saveError.value = error?.message || error?.toString() || t('config.saveFailed')
  } finally {
    isSaving.value = false
  }
}
</script>

<template>
  <v-card variant="outlined" class="mb-4">
    <v-card-text>
      <v-row align="center">
        <v-col cols="auto">
          <v-icon color="primary">mdi-folder-cog</v-icon>
        </v-col>
        
        <v-col>
          <v-select
            v-model="selectedConfigId"
            :items="configStore.sortedConfigurations"
            item-title="name"
            item-value="id"
            :label="t('config.selectConfig')"
            :placeholder="t('config.selectSavedConfig')"
            variant="outlined"
            density="compact"
            @update:model-value="handleConfigChange"
            clearable
            hide-details
          >
            <template v-slot:item="{ props, item }">
              <v-list-item v-bind="props">
                <template v-slot:prepend>
                  <v-icon v-if="item.raw.isActive" color="primary">
                    mdi-check-circle
                  </v-icon>
                </template>
                <template v-slot:subtitle>
                  {{ item.raw.description || t('config.noDescription') }}
                </template>
              </v-list-item>
            </template>
          </v-select>
        </v-col>
        
        <v-col cols="auto">
          <v-tooltip :text="t('config.saveCurrentConfig')">
            <template v-slot:activator="{ props }">
              <v-btn
                v-bind="props"
                variant="tonal"
                color="primary"
                @click="openSaveDialog"
              >
                <v-icon>mdi-content-save</v-icon>
              </v-btn>
            </template>
          </v-tooltip>
        </v-col>
        
        <v-col cols="auto">
          <v-tooltip :text="t('config.manageConfig')">
            <template v-slot:activator="{ props }">
              <v-btn
                v-bind="props"
                icon="mdi-cog"
                variant="tonal"
                to="/config"
              />
            </template>
          </v-tooltip>
        </v-col>
      </v-row>
      
      <v-alert
        v-if="configStore.activeConfig"
        type="info"
        density="compact"
        variant="tonal"
        class="mt-3"
      >
        <div class="d-flex align-center">
          {{ t('config.currentConfig') }}: {{ configStore.activeConfig.name }}
          <v-spacer />
          <small class="text-caption">
            {{ t('config.updatedAt') }} {{ new Date(configStore.activeConfig.updatedAt).toLocaleString() }}
          </small>
        </div>
      </v-alert>
    </v-card-text>
  </v-card>
  
  <!-- 保存配置对话框 -->
  <v-dialog v-model="showSaveDialog" max-width="500">
    <v-card>
      <v-card-title>
        <v-icon class="mr-2">mdi-content-save</v-icon>
        {{ isUpdatingExisting ? t('config.updateConfig') : t('config.saveNewConfig') }}
      </v-card-title>
      
      <v-card-text>
        <v-alert
          v-if="saveError"
          type="error"
          density="compact"
          closable
          @click:close="saveError = null"
          class="mb-4"
        >
          {{ saveError }}
        </v-alert>
        
        <v-text-field
          v-model="configName"
          :label="t('config.configName')"
          :placeholder="t('config.configNamePlaceholder')"
          variant="outlined"
          density="compact"
          class="mb-4"
          :rules="[v => !!v.trim() || t('config.validation.nameRequired')]"
          :disabled="isSaving"
          :hint="isUpdatingExisting ? (configStore.activeConfig?.name === configName ? t('config.willUpdateCurrent') : t('config.changeNameWillCreate')) : ''"
          persistent-hint
        />
        
        <v-textarea
          v-model="configDescription"
          :label="t('config.configDescriptionOptional')"
          :placeholder="t('config.descriptionPlaceholder')"
          variant="outlined"
          density="compact"
          rows="3"
          :disabled="isSaving"
        />
      </v-card-text>
      
      <v-card-actions>
        <v-spacer />
        <v-btn 
          variant="text"
          @click="showSaveDialog = false"
          :disabled="isSaving"
        >
          {{ t('common.cancel') }}
        </v-btn>
        <v-btn
          color="primary"
          variant="elevated"
          @click="saveQuickConfig"
          :disabled="!configName.trim() || isSaving"
          :loading="isSaving"
        >
          {{ isUpdatingExisting && configStore.activeConfig?.name === configName ? t('common.update') : t('common.save') }}
        </v-btn>
      </v-card-actions>
    </v-card>
  </v-dialog>
</template>