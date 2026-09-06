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
`osascript`), and a Brave tab whose URL matches `youtube`
(`bctl open https://www.youtube.com` if there isn't one).

## Controls

- tap a row → plays that mix
- play/pause, prev, next
- volume 25 / 50 / 75 / 100 — sets the default sink, not the tab

Track list is `songs.json` (YouTube ids). Edit that to change what's on deck —
the server re-reads it on change, so just reload the page. Each entry:

```json
{"g":"no vocals","id":"<youtube id>","t":"title","ch":"channel","len":"1:02:14"}
```

`g` is the section label the row is grouped under; drop it for an ungrouped row.
