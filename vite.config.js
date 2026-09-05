import { defineConfig } from 'vite'
import { execFile } from 'node:child_process'
import { readFileSync } from 'node:fs'

const songs = JSON.parse(readFileSync(new URL('./songs.json', import.meta.url)))
let cur = 0

const sh = (cmd, args) => new Promise(res =>
  execFile(cmd, args, { timeout: 15000 }, (e, out, err) => res(e ? (err || e.message) : out.trim())))

const bctl = (...a) => sh('bctl', [...a, '--match', 'youtube'])
const ev = js => bctl('eval', js)

const play = async i => {
  cur = (i + songs.length) % songs.length
  await bctl('goto', `https://www.youtube.com/watch?v=${songs[cur].id}`)
  setTimeout(() => ev('var v=document.querySelector("video");if(v){v.volume=1;v.muted=false;v.play()}'), 4000)
  return { cur }
}

const status = async () => {
  const raw = await ev('(function(){var v=document.querySelector("video");return JSON.stringify({paused:v?v.paused:true,t:v?v.currentTime:0,d:v?v.duration:0,url:location.href})})()')
  let s = { paused: true, t: 0, d: 0, url: '' }
  try { s = JSON.parse(raw) } catch { }
  const m = s.url.match(/v=([^&]+)/)
  if (m) { const i = songs.findIndex(x => x.id === m[1]); if (i >= 0) cur = i }
  const vol = (await sh('wpctl', ['get-volume', '@DEFAULT_AUDIO_SINK@'])).match(/[\d.]+/)
  return { ...s, cur, vol: vol ? Math.round(parseFloat(vol[0]) * 100) : null }
}

const api = {
  songs: async () => songs,
  status,
  toggle: () => ev('(function(){var v=document.querySelector("video");if(!v)return"none";v.paused?v.play():v.pause();return v.paused})()'),
  next: () => play(cur + 1),
  prev: () => play(cur - 1),
  play: q => play(parseInt(q.get('i') || '0')),
  vol: async q => { await sh('wpctl', ['set-volume', '@DEFAULT_AUDIO_SINK@', String(parseInt(q.get('v')) / 100)]); return { ok: 1 } },
}

export default defineConfig({
  server: { host: '0.0.0.0', port: 5180, strictPort: true },
  plugins: [{
    name: 'beatdeck-api',
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
