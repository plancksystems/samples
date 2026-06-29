import { createRouter, createWebHistory } from 'vue-router'
import Notes from './pages/Notes.vue'

export const router = createRouter({
  history: createWebHistory(),
  routes: [
    { path: '/', component: Notes },
  ],
})
