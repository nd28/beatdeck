-- beatdeck from neovim: a thin curl client over the /api endpoints that
-- vite.config.js serves. no bctl/wpctl here; the server owns all of that.
local M = {}

M.url = vim.g.beatdeck_url or 'http://localhost:5180'

-- <beatdeck>/nvim/lua/beatdeck/init.lua -> <beatdeck>
M.root = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h:h:h:h')

local L = vim.log.levels
local function notify(msg, level) vim.notify('beatdeck: ' .. msg, level or L.INFO) end
local function down() return 'server not reachable at ' .. M.url .. '  (:Beatdeck start)' end

-- GET /api/<path>, cb(data, err) on the main loop. play waits on bctl goto,
-- so the timeout is generous.
local function api(path, cb)
  vim.system({ 'curl', '-sS', '-m', '20', M.url .. '/api/' .. path }, { text = true }, function(r)
    vim.schedule(function()
      if r.code ~= 0 then return cb(nil, down()) end
      local ok, data = pcall(vim.json.decode, r.stdout)
      cb(ok and data or r.stdout)
    end)
  end)
end

local function up(cb)
  vim.system({ 'curl', '-sS', '-m', '2', M.url .. '/api/songs' }, {}, function(r)
    vim.schedule(function() cb(r.code == 0) end)
  end)
end

local function fmt(s)
  return ('%s  %s  [%s]  %s'):format(s.t, s.ch, s.g or '-', s.len or '')
end

local function clock(t)
  t = math.floor(tonumber(t) or 0)
  local h, m, s = math.floor(t / 3600), math.floor(t / 60) % 60, t % 60
  if h > 0 then return ('%d:%02d:%02d'):format(h, m, s) end
  return ('%d:%02d'):format(m, s)
end

-- songs.json rows as {i=<0-based index>, s=<row>, text=<title channel section>}
-- matching: every query word is a case-insensitive substring of text (so
-- "tay" doesn't hit "insTrumentAls ... You"); pure fuzzy only as a fallback.
local function rows(songs, q)
  local items = {}
  for i, s in ipairs(songs) do
    items[#items + 1] = { i = i - 1, s = s, text = s.t .. ' ' .. s.ch .. ' ' .. (s.g or '') }
  end
  if not q or q == '' then return items end
  local words = vim.split(q:lower(), '%s+', { trimempty = true })
  local function has_all(str)
    str = str:lower()
    for _, w in ipairs(words) do
      if not str:find(w, 1, true) then return false end
    end
    return true
  end
  local hits = vim.tbl_filter(function(it) return has_all(it.text) end, items)
  if #hits > 0 then
    -- title matches first, deck order within each group
    table.sort(hits, function(a, b)
      local ta, tb = has_all(a.s.t), has_all(b.s.t)
      if ta ~= tb then return ta end
      return a.i < b.i
    end)
    return hits
  end
  return vim.fn.matchfuzzy(items, q, { key = 'text' })
end

local function with_song(cur, cb)
  api('songs', function(songs)
    cb(type(songs) == 'table' and songs[(cur or 0) + 1] or nil)
  end)
end

-- ---------------------------------------------------------------- commands

function M.start()
  up(function(ok)
    if ok then return notify('already running at ' .. M.url) end
    local log = vim.fn.stdpath('log') .. '/beatdeck.log'
    vim.system({ 'sh', '-c', 'exec npm start >>"$1" 2>&1', 'beatdeck', log },
      { cwd = M.root, detach = true, stdin = false, stdout = false, stderr = false })
    notify('starting in ' .. M.root .. '  (log: ' .. log .. ')')
    local tries = 0
    local function poll()
      tries = tries + 1
      up(function(ok2)
        if ok2 then return notify('up at ' .. M.url) end
        if tries >= 20 then return notify('did not come up in 10s, see ' .. log, L.ERROR) end
        vim.defer_fn(poll, 500)
      end)
    end
    vim.defer_fn(poll, 500)
  end)
end

function M.status()
  api('status', function(st, err)
    if err then return notify(err, L.WARN) end
    with_song(st.cur, function(s)
      local what = s and (s.t .. ' - ' .. s.ch) or (st.url ~= '' and st.url or 'nothing loaded')
      local vol = (st.vol ~= nil and st.vol ~= vim.NIL) and (st.vol .. '%') or '?'
      notify(('%s  %s  %s / %s  vol %s'):format(
        st.paused and 'paused' or 'playing', what, clock(st.t), clock(st.d), vol))
    end)
  end)
end

function M.toggle()
  api('toggle', function(r, err)
    if err then return notify(err, L.WARN) end
    if r == 'none' then return notify('no video in the youtube tab', L.WARN) end
    -- bctl eval prints the python repr of the result, so "True"/"False"
    notify(tostring(r):lower() == 'true' and 'paused' or 'playing')
  end)
end

local function step(dir)
  api(dir, function(r, err)
    if err then return notify(err, L.WARN) end
    with_song(r.cur, function(s) notify('playing ' .. (s and fmt(s) or ('#' .. r.cur))) end)
  end)
end
function M.next() step('next') end
function M.prev() step('prev') end

function M.play_index(i, s)
  api('play?i=' .. i, function(_, err)
    if err then return notify(err, L.WARN) end
    notify('playing ' .. (s and fmt(s) or ('#' .. i)))
  end)
end

function M.pick(hits)
  if #hits == 0 then return notify('nothing matches', L.WARN) end
  vim.ui.select(hits, { prompt = 'beatdeck', format_item = function(h) return fmt(h.s) end },
    function(h) if h then M.play_index(h.i, h.s) end end)
end

-- play <query>: best fuzzy hit across title/channel/section plays right away.
-- no query: picker over the whole deck.
function M.play(q)
  api('songs', function(songs, err)
    if err then return notify(err, L.WARN) end
    local hits = rows(songs, q)
    if q and q ~= '' then
      if not hits[1] then return notify('no match for "' .. q .. '"', L.WARN) end
      return M.play_index(hits[1].i, hits[1].s)
    end
    M.pick(hits)
  end)
end

-- list [query]: picker, optionally narrowed
function M.list(q)
  api('songs', function(songs, err)
    if err then return notify(err, L.WARN) end
    M.pick(rows(songs, q))
  end)
end

function M.vol(v)
  v = tonumber(v)
  if not v then return notify('usage: :Beatdeck vol 0-100', L.WARN) end
  api('vol?v=' .. v, function(_, err)
    if err then return notify(err, L.WARN) end
    notify('volume ' .. v .. '%')
  end)
end

-- ---------------------------------------------------------------- completion

local cache = { at = 0, songs = {} }

-- synchronous, for cmdline completion. cheap: the server just reads songs.json
local function songs_sync()
  if vim.uv.now() - cache.at < 30000 then return cache.songs end
  local r = vim.system({ 'curl', '-sS', '-m', '1', M.url .. '/api/songs' }, { text = true }):wait(1500)
  if r.code == 0 then
    local ok, d = pcall(vim.json.decode, r.stdout)
    if ok and type(d) == 'table' then cache = { at = vim.uv.now(), songs = d } end
  end
  return cache.songs
end

function M.complete(q)
  return vim.tbl_map(function(h) return h.s.t end, rows(songs_sync(), q))
end

return M
