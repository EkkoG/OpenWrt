<script setup lang="ts">
import { computed } from 'vue'
import { useI18n } from 'vue-i18n'

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
const { t } = useI18n()

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


const mirrorPresets = computed(() => [
  { title: t('build.mirrors.tuna'), value: 'mirrors.tuna.tsinghua.edu.cn' },
  { title: t('build.mirrors.jlu'), value: 'mirrors.jlu.edu.cn' },
  { title: t('build.mirrors.ustc'), value: 'mirrors.ustc.edu.cn' },
  { title: t('build.mirrors.scut'), value: 'mirrors.scut.edu.cn' }
])

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
      <span class="text-subtitle-1 font-weight-medium">{{ t('build.advancedOptions') }}</span>
      <v-spacer />
      <v-btn
        variant="text"
        size="small"
        @click="resetOptions"
      >
        <v-icon>mdi-restore</v-icon>
        {{ t('common.reset') }}
      </v-btn>
    </div>

    <div>
      <v-row>
        <!-- Docker 选项 -->
        <v-col cols="12">
          <div class="text-subtitle-2 mb-3">{{ t('build.dockerOptions') }}</div>
          
          <v-switch
            v-model="withPull"
            :label="t('build.pullImage')"
            color="primary"
            hide-details
            class="mb-2"
          >
            <template v-slot:append>
              <v-tooltip location="right">
                <template v-slot:activator="{ props }">
                  <v-icon v-bind="props" size="small" color="info">mdi-help-circle-outline</v-icon>
                </template>
                <span>{{ t('build.pullImageTooltip') }}</span>
              </v-tooltip>
            </template>
          </v-switch>

          <v-switch
            v-model="rmFirst"
            :label="t('build.removeFirst')"
            color="primary"
            hide-details
            class="mb-3"
          >
            <template v-slot:append>
              <v-tooltip location="right">
                <template v-slot:activator="{ props }">
                  <v-icon v-bind="props" size="small" color="info">mdi-help-circle-outline</v-icon>
                </template>
                <span>{{ t('build.removeFirstTooltip') }}</span>
              </v-tooltip>
            </template>
          </v-switch>
        </v-col>

        <!-- 镜像源选项 -->
        <v-col cols="12">
          <div class="text-subtitle-2 mb-3">{{ t('build.mirrorSettings') }}</div>
          
          <v-switch
            v-model="useMirror"
            :label="t('build.useMirror')"
            color="primary"
            hide-details
            class="mb-3"
          >
            <template v-slot:append>
              <v-tooltip location="right">
                <template v-slot:activator="{ props }">
                  <v-icon v-bind="props" size="small" color="info">mdi-help-circle-outline</v-icon>
                </template>
                <span>{{ t('build.useMirrorTooltip') }}</span>
              </v-tooltip>
            </template>
          </v-switch>

          <v-expand-transition>
            <div v-if="useMirror">
              <v-text-field
                v-model="mirrorUrl"
                :label="t('build.mirrorUrl')"
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
                {{ t('build.mirrorUrlHint') }}
              </div>
            </div>
          </v-expand-transition>
        </v-col>

      </v-row>
    </div>
  </div>
</template>