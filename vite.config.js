import { defineConfig } from 'vite'
import { execFile } from 'node:child_process'
import { readFileSync, statSync } from 'node:fs'

let cur = 0

// re-read on mtime change, so editing these needs no server restart
const json = url => {
  const f = new URL(url, import.meta.url)
  let val, at = 0
  return () => {
    const t = statSync(f).mtimeMs
    if (t !== at) { at = t; val = JSON.parse(readFileSync(f)) }
    return val
  }
}
const load = json('./songs.json')
const pkg = json('./package.json')

const run = (cmd, args) => new Promise(res =>
  execFile(cmd, args, { timeout: 15000 }, (e, out, err) => res({ ok: !e, out: e ? (err || e.message).trim() : out.trim() })))
const sh = async (cmd, args) => (await run(cmd, args)).out

// the deck owns one tab, tracked by devtools target id. `bctl --match youtube`
// would grab whichever youtube tab is listed first, so a second youtube tab
// (a search, something else playing) could get steered instead of ours.
const cdp = `http://127.0.0.1:${process.env.BCTL_PORT || 9222}`
let tabId = null

// same filter bctl uses for its tab indices, so --tab N lines up
const pages = async () => {
  try {
    const ts = await (await fetch(`${cdp}/json`)).json()
    return ts.filter(t => t.type === 'page' && !t.url.startsWith('devtools://'))
  } catch { return [] }
}

// index of our tab in bctl's list, or -1. if the remembered tab is gone
// (server restarted, tab closed) adopt one: prefer a youtube tab playing
// something from songs.json, else the first youtube tab.
const tab = async () => {
  const ps = await pages()
  let i = tabId ? ps.findIndex(t => t.id === tabId) : -1
  if (i < 0) {
    const ids = new Set(load().map(s => s.id))
    const yt = t => /youtube\.com/.test(t.url)
    const ours = t => yt(t) && ids.has((t.url.match(/v=([^&]+)/) || [])[1])
    i = ps.findIndex(ours)
    if (i < 0) i = ps.findIndex(yt)
    tabId = i >= 0 ? ps[i].id : null
    if (tabId) console.log(`beatdeck: adopted tab ${tabId} ${ps[i].url}`)
  }
  return i
}

const bctl = async (...a) => {
  const i = await tab()
  return i < 0 ? '' : sh('bctl', [...a, '--tab', String(i)])
}
const ev = js => bctl('eval', js)

// navigate our tab; if there isn't one, open a fresh one and remember it.
// a tab made through devtools starts hidden and youtube won't load media
// until it's visible, so bring it to the front too.
const goto = async url => {
  const i = await tab()
  if (i >= 0) {
    const r = await run('bctl', ['goto', url, '--tab', String(i)])
    if (r.ok) return
  }
  console.log('beatdeck: no youtube tab, opening one')
  const id = (await run('bctl', ['open', url])).out
  if (id) { tabId = id; await fetch(`${cdp}/json/activate/${id}`).catch(() => { }) }
}

// system volume, 0-100. linux = pipewire via wpctl, mac = osascript
const volume = process.platform === 'darwin' ? {
  get: async () => parseInt(await sh('osascript', ['-e', 'output volume of (get volume settings)'])),
  set: v => sh('osascript', ['-e', `set volume output volume ${v}`]),
} : {
  get: async () => { const m = (await sh('wpctl', ['get-volume', '@DEFAULT_AUDIO_SINK@'])).match(/[\d.]+/); return m ? Math.round(parseFloat(m[0]) * 100) : NaN },
  set: v => sh('wpctl', ['set-volume', '@DEFAULT_AUDIO_SINK@', String(v / 100)]),
}

const play = async i => {
  const songs = load()
  cur = (i + songs.length) % songs.length
  await goto(`https://www.youtube.com/watch?v=${songs[cur].id}`)
  setTimeout(() => ev('var v=document.querySelector("video");if(v){v.volume=1;v.muted=false;v.play()}'), 4000)
  return { cur }
}

const status = async () => {
  const raw = await ev('(function(){var v=document.querySelector("video");return JSON.stringify({paused:v?v.paused:true,t:v?v.currentTime:0,d:v?v.duration:0,url:location.href})})()')
  let s = { paused: true, t: 0, d: 0, url: '' }
  try { s = JSON.parse(raw) } catch { }
  const m = s.url.match(/v=([^&]+)/)
  if (m) { const i = load().findIndex(x => x.id === m[1]); if (i >= 0) cur = i }
  const vol = await volume.get()
  return { ...s, cur, vol: Number.isFinite(vol) ? vol : null }
}

const api = {
  songs: async () => load(),
  status,
  toggle: () => ev('(function(){var v=document.querySelector("video");if(!v)return"none";v.paused?v.play():v.pause();return v.paused})()'),
  next: () => play(cur + 1),
  prev: () => play(cur - 1),
  play: q => play(parseInt(q.get('i') || '0')),
  vol: async q => { await volume.set(Math.max(0, Math.min(100, parseInt(q.get('v')) || 0))); return { ok: 1 } },
}

export default defineConfig({
  server: { host: '0.0.0.0', port: 5180, strictPort: true },
  plugins: [{
    name: 'beatdeck-api',
    transformIndexHtml: html => html.replaceAll('%APP_VERSION%', pkg().version),
    configureServer(s) {
      s.middlewares.use(async (req, res, next) => {
        const u = new URL(req.url, 'http://x')
        const m = u.pathname.match(/^\/api\/(\w+)$/)
        if (!m || !api[m[1]]) return next()
        const out = await api[m[1]](u.searchParams)
        res.setHeader('content-type', 'application/json')
        res.end(JSON.stringify(out))
      })
    }
  }]
})
