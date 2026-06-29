
import { onMounted, onBeforeUnmount } from 'vue'

const SSE_URL = 'http://127.0.0.1:4501/events'

export function useNotesFeed({ onCreated, onUpdated, onDeleted }) {
  let es = null

  function connect() {
    es = new EventSource(SSE_URL)
    if (onCreated) es.addEventListener('note-created', (e) => onCreated(JSON.parse(e.data)))
    if (onUpdated) es.addEventListener('note-updated', (e) => onUpdated(JSON.parse(e.data)))
    if (onDeleted) es.addEventListener('note-deleted', (e) => onDeleted(JSON.parse(e.data)))
    es.onerror = () => {  }
  }

  onMounted(connect)
  onBeforeUnmount(() => es?.close())
}
