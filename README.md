# beatdeck

Phone remote for a list of instrumental hip-hop mixes (no vocals) playing on
YouTube in a Brave tab on the desk machine.

One Vite process does both jobs: serves the page, and a tiny middleware in
`vite.config.js` shells out to `bctl` (Chrome DevTools driver) for the player
and `wpctl` for system volume. No build, no backend framework.

## Run

```
npm i
npm start          # 0.0.0.0:5180
```

Open `http://<machine-ip>:5180` on the phone. Needs `bctl` and `wpctl` on the
PATH of the machine running it, and a Brave tab whose URL matches `youtube`
(`bctl open https://www.youtube.com` if there isn't one).

## Controls

- tap a row → plays that mix
- play/pause, prev, next
- volume 25 / 50 / 75 / 100 — sets the default sink, not the tab

Track list is `songs.json` (YouTube ids). Edit that to change what's on deck.
