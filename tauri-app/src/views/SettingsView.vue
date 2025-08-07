<script setup lang="ts">
import { useAppStore } from '@/stores/app'
import { ref } from 'vue'

const appStore = useAppStore()
const showSaveSuccess = ref(false)

const themes = [
  { title: '浅色主题', value: 'light', icon: 'mdi-white-balance-sunny' },
  { title: '深色主题', value: 'dark', icon: 'mdi-weather-night' },
  { title: '跟随系统', value: 'auto', icon: 'mdi-theme-light-dark' }
]

const languages = [
  { title: '简体中文', value: 'zh-CN' },
  { title: 'English', value: 'en' }
]

const saveSettings = () => {
  // 保存设置到 store
  appStore.updateSettings({
    autoOpenOutput: appStore.autoOpenOutput,
    checkForUpdates: appStore.checkForUpdates,
    theme: appStore.theme,
    language: appStore.language
  })
  
  // 显示保存成功提示
  showSaveSuccess.value = true
  setTimeout(() => {
    showSaveSuccess.value = false
  }, 3000)
}

const resetSettings = () => {
  appStore.updateSettings({
    autoOpenOutput: true,
    checkForUpdates: true,
    theme: 'light',
    language: 'zh-CN'
  })
}

const checkForUpdates = async () => {
  // TODO: 实现检查更新功能
  console.log('Checking for updates...')
}
</script>

<template>
  <v-container>
    <v-row>
      <v-col cols="12">
        <v-card>
          <v-card-title>
            <v-icon class="mr-2">mdi-cog</v-icon>
            应用设置
          </v-card-title>
          
          <v-card-text>
            <!-- 构建设置 -->
            <div class="text-h6 mb-4">构建设置</div>
            <v-checkbox
              v-model="appStore.autoOpenOutput"
              label="构建完成后自动打开输出目录"
              density="compact"
              class="mb-4"
            />
            
            <v-text-field
              v-model="appStore.buildScriptPath"
              label="构建脚本路径"
              variant="outlined"
              density="compact"
              placeholder="../run.sh"
              class="mb-4"
            />
            
            <v-divider class="my-6" />
            
            <!-- 界面设置 -->
            <div class="text-h6 mb-4">界面设置</div>
            
            <v-select
              v-model="appStore.theme"
              :items="themes"
              label="主题"
              variant="outlined"
              density="compact"
              class="mb-4"
            >
              <template v-slot:item="{ props, item }">
                <v-list-item v-bind="props">
                  <template v-slot:prepend>
                    <v-icon>{{ item.raw.icon }}</v-icon>
                  </template>
                </v-list-item>
              </template>
            </v-select>
            
            <v-select
              v-model="appStore.language"
              :items="languages"
              label="语言"
              variant="outlined"
              density="compact"
              class="mb-4"
            />
            
            <v-divider class="my-6" />
            
            <!-- 更新设置 -->
            <div class="text-h6 mb-4">更新设置</div>
            <v-checkbox
              v-model="appStore.checkForUpdates"
              label="自动检查更新"
              density="compact"
              class="mb-4"
            />
            
            <v-btn
              color="info"
              variant="tonal"
              @click="checkForUpdates"
            >
              <v-icon start>mdi-cloud-download</v-icon>
              立即检查更新
            </v-btn>
            
            <v-divider class="my-6" />
            
            <!-- 关于 -->
            <div class="text-h6 mb-4">关于</div>
            <v-list density="compact">
              <v-list-item>
                <v-list-item-title>应用名称</v-list-item-title>
                <v-list-item-subtitle>OpenWrt Builder GUI</v-list-item-subtitle>
              </v-list-item>
              <v-list-item>
                <v-list-item-title>版本</v-list-item-title>
                <v-list-item-subtitle>0.1.0</v-list-item-subtitle>
              </v-list-item>
              <v-list-item>
                <v-list-item-title>开发者</v-list-item-title>
                <v-list-item-subtitle>OpenWrt Builder Team</v-list-item-subtitle>
              </v-list-item>
              <v-list-item>
                <v-list-item-title>技术栈</v-list-item-title>
                <v-list-item-subtitle>Tauri + Vue 3 + Vuetify 3</v-list-item-subtitle>
              </v-list-item>
            </v-list>
            
            <v-divider class="my-6" />
            
            <!-- 操作按钮 -->
            <div class="d-flex justify-space-between">
              <v-btn
                color="secondary"
                variant="outlined"
                @click="resetSettings"
              >
                <v-icon start>mdi-restore</v-icon>
                恢复默认设置
              </v-btn>
              
              <v-btn
                color="primary"
                variant="elevated"
                @click="saveSettings"
              >
                <v-icon start>mdi-content-save</v-icon>
                保存设置
              </v-btn>
            </div>
          </v-card-text>
        </v-card>
        
        <!-- 保存成功提示 -->
        <v-snackbar
          v-model="showSaveSuccess"
          :timeout="3000"
          color="success"
        >
          <v-icon start>mdi-check-circle</v-icon>
          设置已保存
        </v-snackbar>
      </v-col>
    </v-row>
  </v-container>
</template>