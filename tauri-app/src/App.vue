<script setup lang="ts">
import { onMounted } from 'vue'
import { useAppStore } from '@/stores/app'

const appStore = useAppStore()

onMounted(async () => {
  // 启动时检查 Docker 环境
  await appStore.checkDockerEnvironment()
  // 加载模块信息
  await appStore.loadModules()
})
</script>

<template>
  <v-app>
    <v-navigation-drawer
      permanent
      rail
      rail-width="72"
    >
      <v-list nav>
        <v-list-item
          prepend-icon="mdi-home"
          title="主页"
          value="home"
          to="/"
          rounded="xl"
        />
        <v-list-item
          prepend-icon="mdi-docker"
          title="Docker"
          value="docker"
          to="/docker"
          rounded="xl"
        />
        <v-list-item
          prepend-icon="mdi-package-variant"
          title="模块"
          value="modules"
          to="/modules"
          rounded="xl"
        />
        <v-list-item
          prepend-icon="mdi-hammer"
          title="构建"
          value="build"
          to="/build"
          rounded="xl"
        />
        <v-list-item
          prepend-icon="mdi-folder-cog"
          title="配置"
          value="config"
          to="/config"
          rounded="xl"
        />
      </v-list>

      <template v-slot:append>
        <v-list nav>
          <v-list-item
            prepend-icon="mdi-cog"
            title="设置"
            value="settings"
            to="/settings"
            rounded="xl"
          />
        </v-list>
      </template>
    </v-navigation-drawer>

    <v-app-bar
      flat
      density="comfortable"
    >
      <v-app-bar-title>
        <span class="text-h6 font-weight-bold">OpenWrt Builder GUI</span>
      </v-app-bar-title>

      <v-spacer />

      <v-chip
        v-if="appStore.dockerReady"
        color="success"
        variant="tonal"
        prepend-icon="mdi-check-circle"
      >
        Docker 就绪
      </v-chip>
      <v-chip
        v-else
        color="error"
        variant="tonal"
        prepend-icon="mdi-alert-circle"
      >
        Docker 未就绪
      </v-chip>

      <v-btn
        icon="mdi-theme-light-dark"
        @click="appStore.theme = appStore.theme === 'light' ? 'dark' : 'light'"
        class="ml-2"
      />
    </v-app-bar>

    <v-main>
      <v-container fluid>
        <router-view v-slot="{ Component }">
          <transition name="fade" mode="out-in">
            <component :is="Component" />
          </transition>
        </router-view>
      </v-container>
    </v-main>

    <v-snackbar
      v-if="appStore.isBuilding"
      :model-value="true"
      :timeout="-1"
      location="bottom"
      multi-line
    >
      <div class="d-flex align-center">
        <v-progress-circular
          indeterminate
          size="20"
          width="2"
          class="mr-3"
        />
        <span>正在构建固件...</span>
      </div>
      <template v-slot:actions>
        <v-btn
          color="error"
          variant="text"
          @click="appStore.cancelBuild()"
        >
          取消
        </v-btn>
      </template>
    </v-snackbar>
  </v-app>
</template>

<style>
.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.3s ease;
}

.fade-enter-from,
.fade-leave-to {
  opacity: 0;
}
</style>