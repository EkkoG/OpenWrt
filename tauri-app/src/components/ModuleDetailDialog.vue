<script setup lang="ts">
import { ref, watch } from 'vue'
import { marked } from 'marked'

interface Props {
  modelValue: boolean
  moduleName: string
  moduleDescription: string
}

interface Emits {
  (e: 'update:modelValue', value: boolean): void
}

const props = defineProps<Props>()
const emit = defineEmits<Emits>()

const isLoading = ref(false)
const readmeContent = ref('')
const renderedHtml = ref('')
const error = ref('')

// 配置 marked 选项
marked.setOptions({
  breaks: true,
  gfm: true
})

// 监听对话框打开状态
watch(() => props.modelValue, async (isOpen) => {
  if (isOpen && props.moduleName) {
    await loadModuleReadme()
  }
})

// 加载模块 README 内容
const loadModuleReadme = async () => {
  if (!props.moduleName) return
  
  isLoading.value = true
  error.value = ''
  readmeContent.value = ''
  renderedHtml.value = ''
  
  try {
    const { invoke } = await import('@tauri-apps/api/core')
    const content = await invoke<string>('get_module_readme', { moduleName: props.moduleName })
    
    readmeContent.value = content
    renderedHtml.value = marked(content)
  } catch (err: any) {
    console.error('Failed to load module README:', err)
    error.value = err.toString()
  } finally {
    isLoading.value = false
  }
}

const closeDialog = () => {
  emit('update:modelValue', false)
}
</script>

<template>
  <v-dialog
    :model-value="modelValue"
    @update:model-value="closeDialog"
    max-width="900"
    scrollable
  >
    <v-card>
      <v-card-title class="d-flex align-center">
        <v-icon class="mr-3">mdi-package-variant</v-icon>
        <div>
          <div class="text-h6">{{ moduleName }}</div>
          <div class="text-caption text-medium-emphasis">模块详细介绍</div>
        </div>
        <v-spacer />
        <v-btn
          icon="mdi-close"
          variant="text"
          @click="closeDialog"
        />
      </v-card-title>

      <v-divider />

      <v-card-text style="height: 600px;">
        <!-- 加载状态 -->
        <div v-if="isLoading" class="text-center py-8">
          <v-progress-circular indeterminate size="48" />
          <div class="mt-4 text-body-2">正在加载模块文档...</div>
        </div>

        <!-- 错误状态 -->
        <v-alert
          v-else-if="error"
          type="error"
          variant="tonal"
          class="mb-4"
        >
          <div class="text-subtitle2">无法加载模块文档</div>
          <div class="text-body-2 mt-2">{{ error }}</div>
        </v-alert>

        <!-- Markdown 内容渲染 -->
        <div
          v-else-if="renderedHtml"
          class="markdown-content"
          v-html="renderedHtml"
        />

        <!-- 空状态 -->
        <v-empty-state
          v-else
          icon="mdi-file-document-outline"
          title="暂无文档"
          text="该模块暂时没有详细文档"
        />
      </v-card-text>

      <v-card-actions>
        <v-spacer />
        <v-btn
          color="primary"
          variant="text"
          @click="closeDialog"
        >
          关闭
        </v-btn>
      </v-card-actions>
    </v-card>
  </v-dialog>
</template>

<style scoped>
.markdown-content {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
  line-height: 1.6;
  color: rgb(var(--v-theme-on-surface));
}

.markdown-content :deep(h1),
.markdown-content :deep(h2),
.markdown-content :deep(h3),
.markdown-content :deep(h4),
.markdown-content :deep(h5),
.markdown-content :deep(h6) {
  margin-top: 24px;
  margin-bottom: 16px;
  font-weight: 600;
  line-height: 1.25;
}

.markdown-content :deep(h1) {
  font-size: 2rem;
  border-bottom: 1px solid rgb(var(--v-border-color));
  padding-bottom: 8px;
}

.markdown-content :deep(h2) {
  font-size: 1.5rem;
  border-bottom: 1px solid rgb(var(--v-border-color));
  padding-bottom: 8px;
}

.markdown-content :deep(h3) {
  font-size: 1.25rem;
}

.markdown-content :deep(p) {
  margin-bottom: 16px;
}

.markdown-content :deep(ul),
.markdown-content :deep(ol) {
  margin-bottom: 16px;
  padding-left: 24px;
}

.markdown-content :deep(li) {
  margin-bottom: 4px;
}

.markdown-content :deep(code) {
  background-color: rgb(var(--v-theme-surface-variant));
  color: rgb(var(--v-theme-on-surface-variant));
  padding: 2px 4px;
  border-radius: 4px;
  font-family: 'Courier New', Consolas, monospace;
  font-size: 0.875em;
}

.markdown-content :deep(pre) {
  background-color: rgb(var(--v-theme-surface-variant));
  color: rgb(var(--v-theme-on-surface-variant));
  padding: 16px;
  border-radius: 8px;
  overflow-x: auto;
  margin-bottom: 16px;
}

.markdown-content :deep(pre code) {
  background-color: transparent;
  padding: 0;
  font-size: 0.875rem;
}

.markdown-content :deep(blockquote) {
  border-left: 4px solid rgb(var(--v-theme-primary));
  margin: 16px 0;
  padding: 8px 16px;
  background-color: rgb(var(--v-theme-surface-variant));
  font-style: italic;
}

.markdown-content :deep(table) {
  border-collapse: collapse;
  margin-bottom: 16px;
  width: 100%;
}

.markdown-content :deep(th),
.markdown-content :deep(td) {
  border: 1px solid rgb(var(--v-border-color));
  padding: 8px 12px;
  text-align: left;
}

.markdown-content :deep(th) {
  background-color: rgb(var(--v-theme-surface-variant));
  font-weight: 600;
}

.markdown-content :deep(a) {
  color: rgb(var(--v-theme-primary));
  text-decoration: none;
}

.markdown-content :deep(a:hover) {
  text-decoration: underline;
}

.markdown-content :deep(hr) {
  border: none;
  border-top: 1px solid rgb(var(--v-border-color));
  margin: 24px 0;
}
</style>