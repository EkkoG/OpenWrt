<script setup lang="ts">
import { computed } from 'vue'

interface AdvancedOptions {
  withPull: boolean
  rmFirst: boolean
  useMirror: boolean
  mirrorUrl: string
}

interface Props {
  modelValue: AdvancedOptions
}

interface Emits {
  (e: 'update:modelValue', value: AdvancedOptions): void
}

const props = defineProps<Props>()
const emit = defineEmits<Emits>()

// 为每个属性创建独立的计算属性
const withPull = computed({
  get: () => props.modelValue.withPull,
  set: (value: boolean) => emit('update:modelValue', { ...props.modelValue, withPull: value })
})

const rmFirst = computed({
  get: () => props.modelValue.rmFirst,
  set: (value: boolean) => emit('update:modelValue', { ...props.modelValue, rmFirst: value })
})

const useMirror = computed({
  get: () => props.modelValue.useMirror,
  set: (value: boolean) => emit('update:modelValue', { ...props.modelValue, useMirror: value })
})

const mirrorUrl = computed({
  get: () => props.modelValue.mirrorUrl,
  set: (value: string) => emit('update:modelValue', { ...props.modelValue, mirrorUrl: value })
})


const mirrorPresets = [
  { title: '清华大学镜像源', value: 'mirrors.tuna.tsinghua.edu.cn' },
  { title: '吉林大学镜像源', value: 'mirrors.jlu.edu.cn' },
  { title: '中科大镜像源', value: 'mirrors.ustc.edu.cn' },
  { title: '华南理工镜像源', value: 'mirrors.scut.edu.cn' }
]

const selectMirrorPreset = (preset: string) => {
  mirrorUrl.value = preset
}

const resetOptions = () => {
  emit('update:modelValue', {
    withPull: false,
    rmFirst: false,
    useMirror: false,
    mirrorUrl: ''
  })
}
</script>

<template>
  <div>
    <div class="d-flex align-center mb-4">
      <v-icon class="mr-2">mdi-tune</v-icon>
      <span class="text-subtitle-1 font-weight-medium">高级构建选项</span>
      <v-spacer />
      <v-btn
        variant="text"
        size="small"
        @click="resetOptions"
      >
        <v-icon>mdi-restore</v-icon>
        重置
      </v-btn>
    </div>

    <div>
      <v-row>
        <!-- Docker 选项 -->
        <v-col cols="12">
          <div class="text-subtitle-2 mb-3">Docker 选项</div>
          
          <v-switch
            v-model="withPull"
            label="构建前拉取最新镜像"
            color="primary"
            hide-details
            class="mb-2"
          >
            <template v-slot:append>
              <v-tooltip location="right">
                <template v-slot:activator="{ props }">
                  <v-icon v-bind="props" size="small" color="info">mdi-help-circle-outline</v-icon>
                </template>
                <span>--with-pull: 确保使用最新的 ImageBuilder 镜像</span>
              </v-tooltip>
            </template>
          </v-switch>

          <v-switch
            v-model="rmFirst"
            label="构建前删除现有容器"
            color="primary"
            hide-details
            class="mb-3"
          >
            <template v-slot:append>
              <v-tooltip location="right">
                <template v-slot:activator="{ props }">
                  <v-icon v-bind="props" size="small" color="info">mdi-help-circle-outline</v-icon>
                </template>
                <span>--rm-first: 清理可能冲突的容器</span>
              </v-tooltip>
            </template>
          </v-switch>
        </v-col>

        <!-- 镜像源选项 -->
        <v-col cols="12">
          <div class="text-subtitle-2 mb-3">镜像源设置</div>
          
          <v-switch
            v-model="useMirror"
            label="使用镜像源加速下载"
            color="primary"
            hide-details
            class="mb-3"
          >
            <template v-slot:append>
              <v-tooltip location="right">
                <template v-slot:activator="{ props }">
                  <v-icon v-bind="props" size="small" color="info">mdi-help-circle-outline</v-icon>
                </template>
                <span>--use-mirror: 使用国内镜像源加速软件包下载</span>
              </v-tooltip>
            </template>
          </v-switch>

          <v-expand-transition>
            <div v-if="useMirror">
              <v-text-field
                v-model="mirrorUrl"
                label="镜像源地址"
                placeholder="mirrors.tuna.tsinghua.edu.cn"
                variant="outlined"
                density="compact"
                hide-details="auto"
                class="mb-3"
              >
                <template v-slot:append-inner>
                  <v-menu>
                    <template v-slot:activator="{ props }">
                      <v-btn
                        v-bind="props"
                        icon="mdi-chevron-down"
                        size="small"
                        variant="text"
                      />
                    </template>
                    <v-list density="compact">
                      <v-list-item
                        v-for="preset in mirrorPresets"
                        :key="preset.value"
                        @click="selectMirrorPreset(preset.value)"
                      >
                        <v-list-item-title>{{ preset.title }}</v-list-item-title>
                        <v-list-item-subtitle>{{ preset.value }}</v-list-item-subtitle>
                      </v-list-item>
                    </v-list>
                  </v-menu>
                </template>
              </v-text-field>

              <div class="text-caption text-medium-emphasis mb-3">
                提示：不要包含 http:// 或 https:// 前缀
              </div>
            </div>
          </v-expand-transition>
        </v-col>

      </v-row>
    </div>
  </div>
</template>