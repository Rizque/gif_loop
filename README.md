<img src="assets/icon/app_icon.png" width="64" height="64" alt="GifLoop app icon">

# GifLoop

Search GIPHY with smart suggestions, browse a masonry grid of GIFs, take any GIF apart frame by frame in the **GIF Studio**, keep favorites offline in your **Library**, and make your own GIFs in the **Remix editor**.

Built as the Chili Labs Junior Mobile Developer test task. iOS and Android, portrait and landscape, light and dark.

## Screenshots

Screenshots and a demo recording live in [`docs/screenshots/`](docs/screenshots/).

| Explore | Detail + Studio | Remix editor | Library |
|---|---|---|---|
| `docs/screenshots/explore.png` | `docs/screenshots/details.png` | `docs/screenshots/remix.png` | `docs/screenshots/library.png` |

Demo: `docs/screenshots/demo.gif`

## Flutter version

```
Flutter 3.47.9 • channel stable • https://github.com/flutter/flutter.git
Framework • revision c197ca5199 (5 days ago) • 2026-10-29 10:10:20 -0400
Engine • hash 9e025265bef30b838c0c1b68cad19decf97048f2 (revision 89c39edfdf) (6 days ago) • 2026-10-27 19:51:20.000Z
Tools • Dart 3.13.7 • DevTools 2.60.0
```

The code uses Dart 3.13 syntax enforced by the lint set (`new(...)` constructors, private named parameters), so an older SDK will not compile it.

## Getting started

1. Create an app at <https://developers.giphy.com/dashboard/> and copy its API key.
2. Copy `.env.example` to `.env` and put the key in it (`.env` is git-ignored):
   ```sh
   cp .env.example .env
   ```
   ```
   GIPHY_API_KEY=your_key_here
   ```
3. Generate the config class and run:
   ```sh
   flutter pub get
   dart run build_runner build
   flutter run
   ```

[envied](https://pub.dev/packages/envied) compiles the key from `.env` into `lib/core/config/env.g.dart` (obfuscated, git-ignored). Run `dart run build_runner build` again after changing `.env`. Without a key the app opens a "Missing API key" screen with these instructions instead of crashing.

Checks (the same ones CI runs, after `build_runner`):

```sh
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test --coverage
```

## What's different in this solution

- **Smart search.** As you type (2+ characters) you get up to 6 autocomplete suggestions, debounced and cached, with the matching prefix in bold. Trending search terms show as chips above the trending grid. Recent searches (max 10) appear when the empty field is focused. Each recent can be removed, and "Clear all" removes them all.
- **Library with offline favorites.** A heart on the detail page saves the GIF's metadata and both renditions (grid preview and full GIF) to the device. Favorites, their detail page and the Studio then work fully offline. The heart fills immediately and rolls back if the download fails.
- **Remix editor.** Trim with a range slider, change speed (0.25×–2×) and loop mode (forward, reverse, ping-pong), and add top and bottom captions. A live preview plays exactly what will be exported, captions included. Export encodes a real GIF in a background isolate with progress and Cancel, then saves it to Library → My remixes, where you can share or delete it.
- **GIF Studio.** The detail page decodes every frame and plays it with its own engine: play/pause, a frame scrubber, frame stepping, speed and loop modes.
- **Masonry + Hero + dominant color.** Tiles keep each GIF's real aspect ratio and fly into the detail page with a Hero. The detail background fades to the GIF's dominant color, computed in an isolate.
- **Offline first-class.** An animated banner shows on every screen while offline. Whatever failed because of the network (feed, load-more, detail, Studio, editor source) retries when the connection returns. Suggestions and trending chips hide while offline.

## Requirements checklist

| Requirement | Status | Where / how |
|---|---|---|
| Search GIFs via GIPHY API | ✅ | `lib/features/gifs/data/giphy_api.dart`, `gif_repository_impl.dart` |
| Auto search with debounce | ✅ | `lib/features/feed/bloc/feed_bloc.dart` (400 ms, restartable, request cancelling) |
| Pagination | ✅ | `FeedBloc._loadNextPage`, `lib/features/feed/widgets/feed_view.dart` |
| Results in a grid | ✅ | `lib/features/gifs/widgets/gif_masonry_grid.dart`, `masonry_grid_sliver.dart` |
| Tapping an item opens a detail view | ✅ | `lib/features/details/gif_details_page.dart` via `AppCoordinator.showGifDetails` |
| At least 2 views use GIPHY data | ✅ | Explore (trending, search, suggestions, trending searches), Detail (by id) |
| Loading indicators | ✅ | Feed skeleton, load-more footer, detail loader, Studio/editor decode progress, export progress dialog |
| Error handling with retry | ✅ | `lib/core/errors/`, `ErrorView`, inline load-more, Studio and export errors |
| Portrait and landscape | ✅ | Side-by-side layouts for detail, editor and viewer; rail ≥ 600 px; layout widget tests |
| Unit tests | ✅ | 251 tests in `test/` |
| State management | ✅ | BLoC/Cubit: `FeedBloc`, `SuggestionsCubit`, `RecentSearchesCubit`, `TrendingSearchesCubit`, `GifDetailsCubit`, `FavoritesCubit`, `RemixesCubit`, `RemixEditorCubit`, `ConnectivityCubit` |
| Platform guidelines (Material / Cupertino) | ✅ | `lib/core/platform/`: Cupertino search field, tab bar, segmented control, list rows and dialog actions on iOS; Material 3 on Android |
| Bonus: Coordinator navigation | ✅ | `lib/app/router/app_coordinator.dart`, `go_router_coordinator.dart` (the only file that knows routes) |
| Bonus: Network availability handling | ✅ | `lib/core/connectivity/`, `offline_banner.dart`, auto-retry on every screen |
| Bonus: Something unique | ✅ | Smart search, offline Library, Remix editor, GIF Studio, dominant color |
| API key not committed | ✅ | `lib/core/config/env.dart` (envied, obfuscated); `.env` and `env.g.dart` git-ignored, `.env.example` committed |
| GIPHY attribution | ✅ | `lib/core/widgets/giphy_attribution.dart` in the feed header, end of results and detail page |
| CI | ✅ | `.github/workflows/ci.yml` |

## Architecture

```
lib/
  main.dart, app/            bootstrap, DI (get_it), router + coordinator, adaptive shell
  core/                      config, connectivity, errors, media (download, share),
                             network, platform helpers, theme, shared widgets, strings
  features/
    gifs/                    domain models, GifRepository, GIPHY API + DTOs, grid widgets
    feed/                    Explore tab: FeedBloc, search field, grid
    search/                  suggestions, trending searches, recent searches
    details/                 detail page, dominant color, favorite heart
    studio/                  PlaybackEngine, frame loader/decoder, controller, player
    library/                 LibraryRepository (+ local impl), favorites, remixes, Library tab
    remix/                   RemixPlan, export pipeline, editor, viewer
```

**Data flow:** Widget → Bloc/Cubit → repository → API / storage. Repositories return a sealed `Result<T>` and never throw into the UI. Widgets never touch Dio, go_router or get_it. They get blocs through `BlocProvider` and navigate through `AppCoordinator`.

**LibraryRepository** is an abstract domain interface with a local implementation. It is the seam for a future cloud-synced library: the UI and cubits only talk to the interface.

**Export pipeline:** the caption overlay is drawn on the main isolate (it needs Flutter's text engine) by the same `CaptionPainter` the preview uses, and read back as straight-alpha RGBA. Then `Isolate.spawn` runs `encodeRemix` (pure Dart, `image` package). The isolate decodes the source, resizes each used frame once, composites the overlay and encodes the GIF, sending progress through a `SendPort`. Cancel kills the isolate, and only a finished GIF is written to disk.

**Why BLoC, Coordinator, no use-case layer.** BLoC's event transformers handle debounce, restartable and droppable logic declaratively and test well. The coordinator keeps routes and navigation details out of pages. A use-case layer would only add one-line pass-throughs at this size.

## Key decisions and trade-offs

- **shared_preferences instead of a database.** The Library holds tens to a few hundred small records, so JSON lists in `SharedPreferencesAsync` are simpler and fast enough. A database is worth it only with querying or much larger data.
- **File names, not paths.** Only file names are stored. Paths are resolved against the documents directory at runtime, because the iOS app container path changes between installs and updates.
- **GIF timing rules.** GIF delays are stored in 10 ms units and many viewers play delays below 20 ms at 100 ms. `RemixPlan` normalizes source frames like the Studio (< 20 ms → 100 ms), divides by speed, rounds to 10 ms with error carry, and never outputs < 20 ms. Instead it merges consecutive frames, so the overall speed stays correct.
- **Export limits.** Output width ≤ 480 px (never upscaled) and ≤ 150 frames (`RemixLimits`). Above that, export is disabled with "Shorten the selection (max 150 frames)".
- **Suggestion errors are silent.** Suggestions and trending chips are conveniences, so the feed's own error UI stays the single source of errors.
- **No auth.** The app is guest-only by design. There is no account to sync favorites or remixes.
- **Search details.** 400 ms feed debounce, 300 ms suggestion debounce, page size 30, de-duplication by id, rating `pg`, max offsets 4999 (search) and 499 (trending) per the GIPHY docs. Autocomplete uses `GET /v1/gifs/search/tags`, whose items only have `name`. Trending searches use `GET /v1/trending/searches`, which returns a plain string array.
- **Rate limits.** Beta keys allow about 100 requests per hour. HTTP 429 shows "GIPHY request limit reached, try again later". Debouncing, cancelling, caching suggestions and loading trending searches once per session all help stay under the limit.
- **Studio memory budget.** All frames are decoded within 120 MB and scaled down if needed.
- **Reduce motion.** When the system asks to reduce motion (`MediaQuery.disableAnimationsOf`), the GIF Studio (detail page, remix viewer) and the remix editor preview start paused on the first frame with a visible play button. Grid tiles keep animating, because they are the content being browsed rather than decorative motion.
- **App icon and splash.** Generated from `assets/icon/` with `flutter_launcher_icons` (Android adaptive icon with monochrome layer, iOS icon without alpha) and `flutter_native_splash` (including the Android 12+ splash API), configured in their own yaml files.

## Testing

251 tests (`flutter test`): DTO parsing, failure mapping, repository; `FeedBloc` (debounce, stale responses, pagination, retry, reconnect); `SuggestionsCubit` (min length, debounce, cache, silent errors, clearing); recent searches (order, de-duplication, cap, remove, clear, persistence); trending searches (once per session, failure); `PlaybackEngine`; `RemixPlan` (trim, order, ping-pong ends, speed, rounding, merging, single frame, cap); caption fitting; encoder integration (real GIF in, frames, delays, size and overlay pixels out); exporter isolate (progress, cancel, errors); remix storage (save, delete, file names only, no orphan on failure); `LibraryRepository` favorites (temp dir, fake downloader, rollback); `FavoritesCubit`, `RemixEditorCubit` (export, cancel saves nothing); and widget tests for feed, smart search, detail, heart toggle, Library, editor (info, frame cap, discard dialog), remix viewer and the adaptive shell. Layout tests render the screens at 360×640, 640×360 and 1280×800 in light and dark at 1.5× text scale, with the keyboard open, and the new screens are checked against the Android tap-target guideline.

## Known limitations / what I'd do next

- **No account or cloud sync.** It is designed for one via `LibraryRepository`, but not built.
- **GIPHY terms.** GIPHY's API Best Practices say "Do not cache API responses or media URLs or cache or store copies of GIPHY's media assets". Offline favorites and exported remixes store copies on the device, which conflicts with that wording. The developer docs say nothing about modifying GIFs or derivative works, and the API Terms of Service page could not be fetched to check (it refused automated access). A production release would need GIPHY's approval or would drop offline copies and remix export.
- **iOS not built or run.** It was developed on Windows. The iOS project needs nothing extra, but iOS was never verified on a device.
- **Device verification is partial.** An Android emulator ran the earlier version (live grid and detail with a real key). The remix export, sharing to other apps and offline favorites after a restart are covered by tests but were not exercised on a device. On the last attempt the emulator's System UI kept stalling.
- **Export time on large GIFs.** The `image` package encodes in pure Dart. Long or large GIFs can take noticeably long, though the UI stays responsive (background isolate with progress and cancel). Decoding also holds all source frames in the isolate's memory.
- **The Studio decodes all frames into memory** (bounded by the 120 MB budget).
- **Search field semantics.** Material's `SearchBar` exposes a 24 px tall text-field semantics node inside its 56 px bar, so the feed screen is not checked against the tap-target guideline.
- **No integration tests, no GIPHY analytics pingbacks, English only.**
