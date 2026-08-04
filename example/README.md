# hit example

One-page demo of the patterns you use day-to-day:

1. **`HitLayer`** — small paint, larger hit (icon, chip ×, resize grip, window edge, list action, slider thumb)
2. **`Hit.defer`** — control hanging outside its parent
3. **`Hit.defer(paintOnTop: true)`** / **`Hit.before`** — deferred paint above or under the scoped subtree
4. **Common mistakes** — scope too small, clip above `HitScope`, missing `HitScope` (Wrong vs Right)

Toggle **Use hit** / **Show hit areas** from the settings gear.

```bash
cd example
flutter run
```

Live demo: [https://hit-one-snowy.vercel.app/](https://hit-one-snowy.vercel.app/)
