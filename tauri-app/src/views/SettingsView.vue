<script setup lang="ts">
import { useAppStore } from '@/stores/app'
import { ref } from 'vue'
import { openUrl as tauriOpenUrl } from '@tauri-apps/plugin-opener'
import { useI18n } from 'vue-i18n'
import { saveLanguage } from '@/i18n'

const appStore = useAppStore()
const showSaveSuccess = ref(false)
const { t, locale } = useI18n()

const themes = ref([
  { title: t('settings.lightTheme'), value: 'light', icon: 'mdi-white-balance-sunny' },
  { title: t('settings.darkTheme'), value: 'dark', icon: 'mdi-weather-night' },
  { title: t('settings.autoTheme'), value: 'auto', icon: 'mdi-theme-light-dark' }
])

const languages = [
  { title: '简体中文', value: 'zh-CN', icon: 'mdi-translate' },
  { title: 'English', value: 'en-US', icon: 'mdi-translate' }
]

const currentLanguage = ref(locale.value)

const onLanguageChange = () => {
  locale.value = currentLanguage.value
  saveLanguage(currentLanguage.value)
  // Update dynamic theme titles
  themes.value = [
    { title: t('settings.lightTheme'), value: 'light', icon: 'mdi-white-balance-sunny' },
    { title: t('settings.darkTheme'), value: 'dark', icon: 'mdi-weather-night' },
    { title: t('settings.autoTheme'), value: 'auto', icon: 'mdi-theme-light-dark' }
  ]
}

const saveSettings = () => {
  // 保存设置到 store
  appStore.updateSettings({
    checkForUpdates: appStore.checkForUpdates,
    theme: appStore.theme
  })
  
  // 显示保存成功提示
  showSaveSuccess.value = true
  setTimeout(() => {
    showSaveSuccess.value = false
  }, 3000)
}

const resetSettings = () => {
  appStore.updateSettings({
    checkForUpdates: true,
    theme: 'light'
  })
}

const checkForUpdates = async () => {
  // TODO: 实现检查更新功能
  console.log('Checking for updates...')
}

const openUrl = (url: string) => tauriOpenUrl(url).catch(console.error)
</script>

<template>
  <v-container>
    <v-row>
      <v-col cols="12">
        <v-card>
          <v-card-title>
            <v-icon class="mr-2">mdi-cog</v-icon>
            {{ t('settings.title') }}
          </v-card-title>
          
          <v-card-text>
            <!-- 界面设置 -->
            <div class="text-h6 mb-4">{{ t('settings.appearance') }}</div>
            
            <v-select
              v-model="appStore.theme"
              :items="themes"
              :label="t('settings.themeMode')"
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
            
            <!-- 语言设置 -->
            <v-select
              v-model="currentLanguage"
              :items="languages"
              :label="t('settings.selectLanguage')"
              variant="outlined"
              density="compact"
              class="mb-4"
              @update:model-value="onLanguageChange"
            >
              <template v-slot:item="{ props, item }">
                <v-list-item v-bind="props">
                  <template v-slot:prepend>
                    <v-icon>{{ item.raw.icon }}</v-icon>
                  </template>
                </v-list-item>
              </template>
            </v-select>
            
            <v-divider class="my-6" />
            
            <!-- 更新设置 -->
            <div class="text-h6 mb-4">{{ t('settings.general') }}</div>
            <v-checkbox
              v-model="appStore.checkForUpdates"
              :label="t('settings.checkUpdates')"
              density="compact"
              class="mb-4"
            />
            
            <v-btn
              color="info"
              variant="tonal"
              @click="checkForUpdates"
            >
              <v-icon start>mdi-cloud-download</v-icon>
              {{ t('settings.checkForUpdates') }}
            </v-btn>
            
            <v-divider class="my-6" />
            
            <!-- 关于 -->
            <div class="text-h6 mb-4">{{ t('settings.about') }}</div>
            <v-list density="compact">
              <v-list-item>
                <v-list-item-title>{{ t('common.build') }}</v-list-item-title>
                <v-list-item-subtitle>OpenWrt Builder</v-list-item-subtitle>
              </v-list-item>
              <v-list-item>
                <v-list-item-title>{{ t('common.version') }}</v-list-item-title>
                <v-list-item-subtitle>0.1.0</v-list-item-subtitle>
              </v-list-item>
              <v-list-item @click="openUrl('https://github.com/EkkoG/OpenWrt')">
                <v-list-item-title>{{ t('settings.documentation') }}</v-list-item-title>
                <v-list-item-subtitle class="text-primary cursor-pointer">
                  https://github.com/EkkoG/OpenWrt
                </v-list-item-subtitle>
              </v-list-item>
              <v-list-item @click="openUrl('https://github.com/EkkoG')">
                <v-list-item-title>Developer</v-list-item-title>
                <v-list-item-subtitle class="text-primary cursor-pointer">
                  https://github.com/EkkoG
                </v-list-item-subtitle>
              </v-list-item>
              <v-list-item>
                <v-list-item-title>Tech Stack</v-list-item-title>
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
                {{ t('settings.resetSettings') }}
              </v-btn>
              
              <v-btn
                color="primary"
                variant="elevated"
                @click="saveSettings"
              >
                <v-icon start>mdi-content-save</v-icon>
                {{ t('common.save') }}
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
          {{ t('settings.resetSuccess') }}
        </v-snackbar>
      </v-col>
    </v-row>
  </v-container>
</template>