
const NOTES_BASE = 'http://127.0.0.1:3002'

async function request(method, path, body) {
  const url = NOTES_BASE + path
  const headers = { 'Accept': 'application/json' }
  if (body !== undefined) headers['Content-Type'] = 'application/json'

  const res = await fetch(url, {
    method,
    headers,
    body: body !== undefined ? JSON.stringify(body) : undefined,
  })
  if (!res.ok) throw new Error(`${method} ${url} → ${res.status}`)
  const ct = res.headers.get('Content-Type') || ''
  return ct.includes('application/json') ? res.json() : res.text()
}

export const api = {
  get:  (p)    => request('GET', p),
  post: (p, b) => request('POST', p, b ?? {}),
  put:  (p, b) => request('PUT',  p, b ?? {}),
  del:  (p)    => request('DELETE', p),
}
