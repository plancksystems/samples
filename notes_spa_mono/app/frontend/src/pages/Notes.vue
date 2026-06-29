<script setup>
import { ref, computed, onMounted, nextTick } from 'vue'
import { api } from '../composables/api.js'
import { useNotesFeed } from '../composables/sse.js'

const notes = ref([])
const tagFilter = ref(null)
const editingId = ref(null)
const draft = ref({ Title: '', Body: '', Tags: '' })
const newTitleInput = ref(null)

const sorted = computed(() =>
  [...notes.value].sort((a, b) => (b.UpdatedAt || b.CreatedAt) - (a.UpdatedAt || a.CreatedAt))
)

const allTags = computed(() => {
  const tags = new Set()
  for (const n of notes.value) splitTags(n.Tags).forEach((t) => tags.add(t))
  return [...tags].sort()
})

const filtered = computed(() => {
  if (!tagFilter.value) return sorted.value
  return sorted.value.filter((n) => splitTags(n.Tags).includes(tagFilter.value))
})

function splitTags(s) {
  return (s || '')
    .split(',')
    .map((t) => t.trim())
    .filter(Boolean)
}

function formatTime(ms) {
  if (!ms) return ''
  const d = new Date(ms)
  const today = new Date()
  const sameDay = d.toDateString() === today.toDateString()
  return sameDay
    ? d.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
    : d.toLocaleDateString([], { month: 'short', day: 'numeric' })
}

async function load() {
  notes.value = await api.get('/notes')
}

function startNew() {
  editingId.value = 'new'
  draft.value = { Title: '', Body: '', Tags: '' }
  nextTick(() => newTitleInput.value?.focus())
}

function startEdit(n) {
  editingId.value = n.NoteID
  draft.value = { Title: n.Title, Body: n.Body, Tags: n.Tags }
}

function cancel() {
  editingId.value = null
}

async function save() {
  const title = draft.value.Title.trim()
  if (!title) return
  const payload = {
    Title: title,
    Body: draft.value.Body.trim(),
    Tags: draft.value.Tags.trim(),
  }
  if (editingId.value === 'new') {
    await api.post('/notes', payload)
  } else {
    await api.put(`/notes/${editingId.value}`, payload)
  }
  editingId.value = null
}

async function remove(n) {
  if (!confirm(`Delete "${n.Title}"?`)) return
  await api.del(`/notes/${n.NoteID}`)
}

function upsertLocal(note) {
  const idx = notes.value.findIndex((x) => x.NoteID === note.NoteID)
  if (idx >= 0) notes.value[idx] = note
  else notes.value.push(note)
}

function removeLocal({ NoteID }) {
  notes.value = notes.value.filter((n) => n.NoteID !== NoteID)
}

onMounted(load)

useNotesFeed({
  onCreated: upsertLocal,
  onUpdated: upsertLocal,
  onDeleted: removeLocal,
})
</script>

<template>
  <div class="space-y-6">
    <header class="flex items-end justify-between">
      <div>
        <h1 class="text-3xl font-bold text-slate-900 tracking-tight">Notes</h1>
        <p class="text-sm text-slate-500 mt-1">
          {{ notes.length }} {{ notes.length === 1 ? 'note' : 'notes' }} · live-synced
        </p>
      </div>
      <button @click="startNew"
              class="px-4 py-2 rounded-lg bg-slate-900 hover:bg-slate-800 text-white text-sm font-medium shadow-sm transition">
        + New note
      </button>
    </header>

    <div v-if="allTags.length" class="flex flex-wrap gap-2 items-center">
      <span class="text-xs text-slate-400 uppercase tracking-wider mr-1">Filter</span>
      <button @click="tagFilter = null"
              :class="['px-2.5 py-1 rounded-full text-xs font-medium transition',
                       tagFilter === null
                         ? 'bg-slate-900 text-white'
                         : 'bg-white border border-slate-200 text-slate-600 hover:border-slate-300']">
        All
      </button>
      <button v-for="t in allTags" :key="t" @click="tagFilter = t"
              :class="['px-2.5 py-1 rounded-full text-xs font-medium transition',
                       tagFilter === t
                         ? 'bg-slate-900 text-white'
                         : 'bg-white border border-slate-200 text-slate-600 hover:border-slate-300']">
        {{ t }}
      </button>
    </div>

    <div v-if="editingId === 'new'"
         class="bg-white rounded-xl border border-slate-200 shadow-sm p-5 space-y-3">
      <input ref="newTitleInput" v-model="draft.Title" placeholder="Title"
             class="w-full text-lg font-semibold text-slate-900 placeholder-slate-300 focus:outline-none" />
      <textarea v-model="draft.Body" placeholder="Write something…" rows="4"
                class="w-full text-sm text-slate-700 placeholder-slate-300 focus:outline-none resize-none"></textarea>
      <input v-model="draft.Tags" placeholder="Tags (comma separated)"
             class="w-full text-xs text-slate-500 placeholder-slate-300 focus:outline-none" />
      <div class="flex justify-end gap-2 pt-2 border-t border-slate-100">
        <button @click="cancel"
                class="px-3 py-1.5 rounded-md text-sm text-slate-500 hover:text-slate-700">
          Cancel
        </button>
        <button @click="save"
                class="px-3 py-1.5 rounded-md bg-slate-900 hover:bg-slate-800 text-white text-sm font-medium">
          Save
        </button>
      </div>
    </div>

    <p v-if="filtered.length === 0 && editingId !== 'new'"
       class="text-slate-400 text-sm text-center py-16">
      {{ tagFilter ? `No notes tagged "${tagFilter}".` : 'No notes yet — create one above.' }}
    </p>

    <div class="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
      <article v-for="n in filtered" :key="n.NoteID"
               class="group bg-white rounded-xl border border-slate-200 shadow-sm hover:shadow-md hover:border-slate-300 transition overflow-hidden">
        <div v-if="editingId === n.NoteID" class="p-5 space-y-3">
          <input v-model="draft.Title" placeholder="Title"
                 class="w-full text-lg font-semibold text-slate-900 focus:outline-none" />
          <textarea v-model="draft.Body" rows="4"
                    class="w-full text-sm text-slate-700 focus:outline-none resize-none"></textarea>
          <input v-model="draft.Tags" placeholder="Tags (comma separated)"
                 class="w-full text-xs text-slate-500 focus:outline-none" />
          <div class="flex justify-end gap-2 pt-2 border-t border-slate-100">
            <button @click="cancel"
                    class="px-3 py-1.5 rounded-md text-sm text-slate-500 hover:text-slate-700">
              Cancel
            </button>
            <button @click="save"
                    class="px-3 py-1.5 rounded-md bg-slate-900 hover:bg-slate-800 text-white text-sm font-medium">
              Save
            </button>
          </div>
        </div>

        <div v-else class="p-5">
          <header class="flex items-start justify-between gap-3 mb-2">
            <h2 class="text-base font-semibold text-slate-900 leading-snug">{{ n.Title }}</h2>
            <div class="flex gap-1 opacity-0 group-hover:opacity-100 transition">
              <button @click="startEdit(n)" title="Edit"
                      class="p-1 text-slate-400 hover:text-slate-700 text-sm">
                ✎
              </button>
              <button @click="remove(n)" title="Delete"
                      class="p-1 text-slate-400 hover:text-red-500 text-sm">
                ✕
              </button>
            </div>
          </header>
          <p v-if="n.Body" class="text-sm text-slate-600 whitespace-pre-wrap leading-relaxed mb-3">
            {{ n.Body }}
          </p>
          <footer class="flex items-center justify-between text-xs">
            <div class="flex flex-wrap gap-1">
              <span v-for="t in splitTags(n.Tags)" :key="t"
                    class="px-2 py-0.5 rounded-full bg-slate-100 text-slate-600">
                {{ t }}
              </span>
            </div>
            <time class="text-slate-400">{{ formatTime(n.UpdatedAt || n.CreatedAt) }}</time>
          </footer>
        </div>
      </article>
    </div>
  </div>
</template>
