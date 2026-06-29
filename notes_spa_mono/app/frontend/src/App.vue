<script setup>
import { RouterView } from 'vue-router'
</script>

<template>
  <nav class="bg-white border-b border-slate-200 px-6 py-3 shadow-sm">
    <div class="max-w-6xl mx-auto flex items-center justify-between">
      <span class="text-base font-semibold text-slate-900 tracking-tight">
        Notes
      </span>
      <span class="text-xs text-slate-400">built on Planck</span>
    </div>
  </nav>
  <main class="flex-1 max-w-6xl mx-auto w-full px-6 py-8">
    <RouterView />
  </main>
</template>
