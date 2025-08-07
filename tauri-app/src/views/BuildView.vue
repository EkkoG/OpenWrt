<script setup lang="ts">
import { useAppStore } from '@/stores/app'

const appStore = useAppStore()
</script>

<template>
  <v-container>
    <v-row>
      <v-col cols="12">
        <v-card>
          <v-card-title>构建管理</v-card-title>
          <v-card-text>
            <div class="text-center pa-8 text-medium-emphasis">
              构建管理功能将在后续任务中实现
            </div>
          </v-card-text>
        </v-card>
      </v-col>
    </v-row>
  </v-container>
</template>