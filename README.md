# beatdeck

Phone remote for a list of long-form YouTube mixes playing in a Brave tab on
the desk machine. Currently three sections: instrumental hip-hop, Olivia Dean
live sets, and Taylor Swift mixes and full concerts.

One Vite process does both jobs: serves the page, and a tiny middleware in
`vite.config.js` shells out to `bctl` (Chrome DevTools driver) for the player
and `wpctl` (Linux/PipeWire) or `osascript` (macOS) for system volume. No
build, no backend framework.

## Run

```
npm i
npm start          # 0.0.0.0:5180
```

Open `http://<machine-ip>:5180` on the phone. Needs `bctl` on the PATH of the
machine running it (plus `wpctl` on Linux; macOS uses the built-in
`osascript`), and a Brave started with the debug port (`bctl start`). The
player lives in whichever tab's URL matches `youtube`; if there isn't one,
the first play opens it.

## Controls

- tap a row → plays that mix
- play/pause, prev, next
- volume 25 / 50 / 75 / 100 — sets the default sink, not the tab

## More than one machine

The chip next to the title picks which beatdeck server the page talks to.
The list (name + URL) lives in the browser's `localStorage`; "this host" is
the machine that served the page, if it's running the server. Each machine
runs its own `npm start` with its own `songs.json`, Brave and audio sink —
the page only decides where to send `/api` calls.

The page is also published to <https://nd28.github.io/beatdeck/> on every
push (`.github/workflows/pages.yml` runs `npm run build`; the repo's Pages
source must be set to "GitHub Actions" once). That copy has no server
behind it, so it opens the picker on first visit. Because it's HTTPS, the
targets must be HTTPS too — plain `http://192.168.x.x:5180` is mixed
content and the browser refuses it. Tailscale gives you that for free on
each machine:

```
tailscale serve --bg 5180        # https://<machine>.<tailnet>.ts.net → localhost:5180
tailscale serve status
```

Add `https://<machine>.<tailnet>.ts.net` in the picker. Only devices on your
tailnet can reach it; there is no auth on `/api`, so don't put it on the
public internet. The server already allows the Pages origin and `*.ts.net`
host names; extra page origins go in `BEATDECK_ORIGINS=https://a,https://b`
when starting it. `npm run preview` serves the built copy locally at
`/beatdeck/` for checking it.

## Neovim

The same remote from inside nvim, as a plugin that lives in `nvim/` here. It
only talks HTTP to the server above (`curl`), so nothing about bctl or volume
is duplicated. No plugin manager needed:

```lua
-- init.lua
vim.opt.runtimepath:append(vim.fn.expand('~/beatdeck/nvim'))
-- lazy.nvim users: { dir = '~/beatdeck/nvim' }
```

```
:Beatdeck                 status (bare call)
:Beatdeck start           spawn `npm start` here, detached, if 5180 isn't answering
:Beatdeck play <words>    best match on title/channel/section plays; <Tab> completes titles
:Beatdeck play            picker over the whole deck (vim.ui.select)
:Beatdeck list [words]    picker, optionally narrowed
:Beatdeck toggle | next | prev | vol 0-100
```

Matching: every word must appear (case-insensitive) somewhere in title, channel
or section; title hits rank first; fuzzy only kicks in when nothing matches
literally. `play` jumps by index, so it ignores where the queue currently is.

Keymaps under `<leader>b` (`bb` toggle, `bn`/`bp` next/prev, `bl` picker,
`bf` find-and-play, `bs` status, `bS` start). Set `vim.g.beatdeck_keymaps =
false` before the plugin loads to skip them; `vim.g.beatdeck_url` overrides
`http://localhost:5180`. Server output from `:Beatdeck start` goes to
`stdpath('log')/beatdeck.log`.

Track list is `songs.json` (YouTube ids). Edit that to change what's on deck —
the server re-reads it on change, so just reload the page. Each entry:

```json
{"g":"no vocals","id":"<youtube id>","t":"title","ch":"channel","len":"1:02:14"}
```

`g` is the section label the row is grouped under; drop it for an ungrouped row.
