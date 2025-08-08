<script setup lang="ts">
import { useAppStore } from '@/stores/app'
import { useRouter } from 'vue-router'

const appStore = useAppStore()
const router = useRouter()
</script>

<template>
  <v-container>
    <v-row>
      <v-col cols="12">
        <v-card>
          <v-card-title class="text-h4 font-weight-bold">
            欢迎使用 OpenWrt Builder GUI
          </v-card-title>
          <v-card-subtitle class="text-subtitle-1 mt-2">
            一个用于构建自定义 OpenWrt 固件的桌面应用程序
          </v-card-subtitle>
          <v-card-text>
            <v-alert
              v-if="!appStore.dockerReady"
              type="warning"
              variant="tonal"
              class="mb-4"
            >
              <div class="d-flex align-center">
                <v-icon class="mr-2">mdi-alert</v-icon>
                <div>
                  <div class="font-weight-medium">Docker 环境未就绪</div>
                  <div class="text-caption">请先安装并启动 Docker，然后重新检查环境</div>
                </div>
              </div>
              <v-btn
                color="primary"
                variant="text"
                size="small"
                class="mt-2"
                @click="router.push('/docker')"
              >
                查看 Docker 状态
              </v-btn>
            </v-alert>

            <v-row class="mt-4">
              <v-col cols="12" md="3" sm="6">
                <v-card variant="tonal" color="primary" height="200">
                  <v-card-text class="text-center pa-6 d-flex flex-column justify-center align-center" style="height: 100%">
                    <v-icon size="48" class="mb-3">mdi-docker</v-icon>
                    <div class="text-h6 font-weight-medium">Docker 状态</div>
                    <v-chip
                      :color="appStore.dockerReady ? 'success' : 'error'"
                      variant="flat"
                      size="small"
                      class="mt-2"
                    >
                      {{ appStore.dockerReady ? '已就绪' : '未就绪' }}
                    </v-chip>
                  </v-card-text>
                </v-card>
              </v-col>

              <v-col cols="12" md="3" sm="6">
                <v-card variant="tonal" color="secondary" height="200">
                  <v-card-text class="text-center pa-6 d-flex flex-column justify-center align-center" style="height: 100%">
                    <v-icon size="48" class="mb-3">mdi-package-variant</v-icon>
                    <div class="text-h6 font-weight-medium">已启用模块</div>
                    <v-chip
                      color="primary"
                      variant="flat"
                      size="small"
                      class="mt-2"
                    >
                      {{ appStore.enabledModules.length }} 个
                    </v-chip>
                  </v-card-text>
                </v-card>
              </v-col>

              <v-col cols="12" md="3" sm="6">
                <v-card variant="tonal" color="info" height="200">
                  <v-card-text class="text-center pa-6 d-flex flex-column justify-center align-center" style="height: 100%">
                    <v-icon size="48" class="mb-3">mdi-hammer</v-icon>
                    <div class="text-h6 font-weight-medium">构建状态</div>
                    <v-chip
                      :color="appStore.isBuilding ? 'warning' : 'default'"
                      variant="flat"
                      size="small"
                      class="mt-2"
                    >
                      {{ appStore.isBuilding ? '构建中' : '空闲' }}
                    </v-chip>
                  </v-card-text>
                </v-card>
              </v-col>

              <v-col cols="12" md="3" sm="6">
                <v-card variant="tonal" color="success" height="200">
                  <v-card-text class="text-center pa-6 d-flex flex-column justify-center align-center" style="height: 100%">
                    <v-icon size="48" class="mb-3">mdi-check-circle</v-icon>
                    <div class="text-h6 font-weight-medium">上次构建</div>
                    <v-chip
                      :color="appStore.lastBuildStatus ? (appStore.lastBuildStatus === 'success' ? 'success' : 'error') : 'default'"
                      variant="flat"
                      size="small"
                      class="mt-2"
                    >
                      {{ appStore.lastBuildStatus ? (appStore.lastBuildStatus === 'success' ? '成功' : '失败') : '暂无' }}
                    </v-chip>
                  </v-card-text>
                </v-card>
              </v-col>
            </v-row>

            <v-divider class="my-6" />

            <div class="text-h6 mb-4">快速开始</div>
            <v-row>
              <v-col cols="12" md="4">
                <v-card
                  variant="outlined"
                  @click="router.push('/docker')"
                  style="cursor: pointer"
                  hover
                >
                  <v-card-text>
                    <div class="d-flex align-center">
                      <v-icon size="32" color="primary" class="mr-3">mdi-numeric-1-circle</v-icon>
                      <div>
                        <div class="font-weight-medium">检查 Docker 环境</div>
                        <div class="text-caption text-medium-emphasis">确保 Docker 已安装并运行</div>
                      </div>
                    </div>
                  </v-card-text>
                </v-card>
              </v-col>

              <v-col cols="12" md="4">
                <v-card
                  variant="outlined"
                  @click="router.push('/modules')"
                  style="cursor: pointer"
                  hover
                >
                  <v-card-text>
                    <div class="d-flex align-center">
                      <v-icon size="32" color="primary" class="mr-3">mdi-numeric-2-circle</v-icon>
                      <div>
                        <div class="font-weight-medium">配置模块</div>
                        <div class="text-caption text-medium-emphasis">选择并配置所需的功能模块</div>
                      </div>
                    </div>
                  </v-card-text>
                </v-card>
              </v-col>

              <v-col cols="12" md="4">
                <v-card
                  variant="outlined"
                  @click="router.push('/build')"
                  style="cursor: pointer"
                  hover
                >
                  <v-card-text>
                    <div class="d-flex align-center">
                      <v-icon size="32" color="primary" class="mr-3">mdi-numeric-3-circle</v-icon>
                      <div>
                        <div class="font-weight-medium">开始构建</div>
                        <div class="text-caption text-medium-emphasis">选择镜像并开始构建固件</div>
                      </div>
                    </div>
                  </v-card-text>
                </v-card>
              </v-col>
            </v-row>
          </v-card-text>
        </v-card>
      </v-col>
    </v-row>
  </v-container>
</template>