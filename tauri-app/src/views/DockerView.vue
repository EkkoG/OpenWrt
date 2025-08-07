<script setup lang="ts">
import { useAppStore } from '@/stores/app'
import { onMounted, ref } from 'vue'

const appStore = useAppStore()
const isChecking = ref(false)

const checkDocker = async () => {
  isChecking.value = true
  await appStore.checkDockerEnvironment()
  isChecking.value = false
}

onMounted(() => {
  checkDocker()
})
</script>

<template>
  <v-container>
    <v-row>
      <v-col cols="12">
        <v-card>
          <v-card-title class="d-flex align-center">
            <v-icon class="mr-2">mdi-docker</v-icon>
            Docker 环境状态
            <v-spacer />
            <v-btn
              color="primary"
              variant="tonal"
              size="small"
              @click="checkDocker"
              :loading="isChecking"
              prepend-icon="mdi-refresh"
            >
              刷新状态
            </v-btn>
          </v-card-title>
          
          <v-card-text>
            <v-row>
              <!-- Docker 主状态 -->
              <v-col cols="12" md="6">
                <v-card variant="outlined">
                  <v-card-text>
                    <div class="text-h6 mb-3">Docker 引擎</div>
                    
                    <v-list density="comfortable">
                      <v-list-item>
                        <template v-slot:prepend>
                          <v-icon 
                            :color="appStore.dockerInstalled ? 'success' : 'error'"
                            size="small"
                          >
                            {{ appStore.dockerInstalled ? 'mdi-check-circle' : 'mdi-close-circle' }}
                          </v-icon>
                        </template>
                        <v-list-item-title>安装状态</v-list-item-title>
                        <v-list-item-subtitle>
                          {{ appStore.dockerInstalled ? '已安装' : '未安装' }}
                        </v-list-item-subtitle>
                      </v-list-item>
                      
                      <v-list-item v-if="appStore.dockerInstalled">
                        <template v-slot:prepend>
                          <v-icon 
                            :color="appStore.dockerRunning ? 'success' : 'warning'"
                            size="small"
                          >
                            {{ appStore.dockerRunning ? 'mdi-play-circle' : 'mdi-pause-circle' }}
                          </v-icon>
                        </template>
                        <v-list-item-title>运行状态</v-list-item-title>
                        <v-list-item-subtitle>
                          {{ appStore.dockerRunning ? '运行中' : '未运行' }}
                        </v-list-item-subtitle>
                      </v-list-item>
                      
                      <v-list-item v-if="appStore.dockerVersion">
                        <template v-slot:prepend>
                          <v-icon size="small">mdi-tag</v-icon>
                        </template>
                        <v-list-item-title>版本</v-list-item-title>
                        <v-list-item-subtitle>
                          {{ appStore.dockerVersion }}
                        </v-list-item-subtitle>
                      </v-list-item>
                    </v-list>

                    <v-alert 
                      v-if="!appStore.dockerInstalled"
                      type="error"
                      variant="tonal"
                      class="mt-3"
                    >
                      <div class="font-weight-medium mb-1">Docker 未安装</div>
                      <div class="text-caption">
                        请访问 
                        <a href="https://www.docker.com/get-started" target="_blank">Docker 官网</a>
                        下载并安装 Docker Desktop
                      </div>
                    </v-alert>

                    <v-alert 
                      v-else-if="!appStore.dockerRunning"
                      type="warning"
                      variant="tonal"
                      class="mt-3"
                    >
                      <div class="font-weight-medium mb-1">Docker 未运行</div>
                      <div class="text-caption">
                        请启动 Docker Desktop 应用程序
                      </div>
                    </v-alert>
                  </v-card-text>
                </v-card>
              </v-col>

              <!-- Docker Compose 状态 -->
              <v-col cols="12" md="6">
                <v-card variant="outlined">
                  <v-card-text>
                    <div class="text-h6 mb-3">Docker Compose</div>
                    
                    <v-list density="comfortable">
                      <v-list-item>
                        <template v-slot:prepend>
                          <v-icon 
                            :color="appStore.dockerComposeInstalled ? 'success' : 'error'"
                            size="small"
                          >
                            {{ appStore.dockerComposeInstalled ? 'mdi-check-circle' : 'mdi-close-circle' }}
                          </v-icon>
                        </template>
                        <v-list-item-title>安装状态</v-list-item-title>
                        <v-list-item-subtitle>
                          {{ appStore.dockerComposeInstalled ? '已安装' : '未安装' }}
                        </v-list-item-subtitle>
                      </v-list-item>
                      
                      <v-list-item v-if="appStore.dockerComposeVersion">
                        <template v-slot:prepend>
                          <v-icon size="small">mdi-tag</v-icon>
                        </template>
                        <v-list-item-title>版本</v-list-item-title>
                        <v-list-item-subtitle>
                          {{ appStore.dockerComposeVersion }}
                        </v-list-item-subtitle>
                      </v-list-item>
                    </v-list>

                    <v-alert 
                      v-if="appStore.dockerInstalled && !appStore.dockerComposeInstalled"
                      type="info"
                      variant="tonal"
                      class="mt-3"
                    >
                      <div class="font-weight-medium mb-1">Docker Compose 未安装</div>
                      <div class="text-caption">
                        Docker Compose 通常随 Docker Desktop 一起安装
                      </div>
                    </v-alert>
                  </v-card-text>
                </v-card>
              </v-col>
            </v-row>

            <!-- 总体状态摘要 -->
            <v-alert
              v-if="appStore.dockerReady"
              type="success"
              variant="tonal"
              class="mt-4"
              prominent
            >
              <div class="d-flex align-center">
                <v-icon class="mr-3">mdi-check-circle</v-icon>
                <div>
                  <div class="text-h6">Docker 环境就绪</div>
                  <div class="text-caption">所有必需的组件都已正确安装并运行，可以开始构建 OpenWrt 固件</div>
                </div>
              </div>
            </v-alert>
          </v-card-text>
        </v-card>
      </v-col>
    </v-row>
  </v-container>
</template>