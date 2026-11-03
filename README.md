# GifLoop

Search GIPHY, browse a masonry grid of GIFs, take any GIF apart frame by frame in the **GIF Studio**, and test yourself in **Guess the GIF**.

Built as the Chili Labs Junior Mobile Developer test task. iOS and Android, portrait and landscape, light and dark.

## Screenshots

Screenshots and a demo recording live in [`docs/screenshots/`](docs/screenshots/).

| Explore | Detail + Studio | Guess the GIF | Landscape |
|---|---|---|---|
| `docs/screenshots/explore.png` | `docs/screenshots/details.png` | `docs/screenshots/game.png` | `docs/screenshots/landscape.png` |

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
3. Run:
   ```sh
   flutter pub get
   flutter run --dart-define-from-file=.env
   ```

Without a key the app opens a "Missing API key" screen with these instructions instead of crashing.

Checks (the same ones CI runs):

```sh
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test --coverage
```

## What's different in this solution

- **GIF Studio.** The detail page doesn't just show an `Image.network`. It decodes every frame of the GIF and plays it with its own engine: play/pause, a frame scrubber, frame stepping, speeds from 0.25× to 2×, and forward, reverse and ping-pong loops. The engine is pure Dart and heavily unit tested.
- **Masonry + Hero + dominant color.** The grid keeps each GIF's real aspect ratio. A tile flies into the detail page with a Hero, and the page background fades to the GIF's dominant color, which is computed in an isolate. Text color is picked for contrast.
- **Guess the GIF.** A third GIPHY-powered screen. Each round shows a GIF found by a search term, and you pick the term from four options. It has ten rounds, score, streak and a persisted best score. The next round's data and image are prefetched, so rounds start instantly.
- **Offline first-class.** An animated banner appears on every screen while offline. When the connection returns, whatever failed because of the network (feed, load-more, detail, Studio, game) retries on its own.

## Requirements checklist

| Requirement | Status | Where / how |
|---|---|---|
| Search GIFs via GIPHY API | ✅ | `lib/features/gifs/data/giphy_api.dart`, `lib/features/gifs/data/gif_repository_impl.dart` |
| Auto search (no search button) with debounce | ✅ | `lib/features/feed/bloc/feed_bloc.dart` (400 ms debounce, restartable, request cancelling) |
| Pagination | ✅ | `FeedBloc._loadNextPage`, `lib/features/feed/widgets/feed_view.dart` (600 px threshold, fills tall screens) |
| Results in a grid | ✅ | `lib/features/feed/widgets/gif_masonry_grid.dart` (`SliverMasonryGrid`, columns from width) |
| Tapping an item opens a detail view | ✅ | `lib/features/details/gif_details_page.dart` via `AppCoordinator.showGifDetails` |
| At least 2 views use GIPHY data | ✅ | Explore (trending/search), Detail (by id), Game (search) |
| Loading indicators | ✅ | Feed skeleton (`feed_skeleton.dart`), load-more footer (`feed_footer.dart`), detail loader, Studio decode progress (`gif_studio_controls.dart`), game loader |
| Error handling with retry | ✅ | `lib/core/errors/` (`Failure`, `failure_mapper.dart`, `failure_presentation.dart`), `lib/core/widgets/error_view.dart`, inline load-more and Studio errors |
| Portrait and landscape | ✅ | No orientation lock; `AppShell` rail ≥ 600 px; side-by-side detail and game layouts; layout widget tests |
| Unit tests | ✅ | 162 tests in `test/` (see Testing) |
| State management | ✅ | BLoC/Cubit (`flutter_bloc`): `FeedBloc`, `GifDetailsCubit`, `GameCubit`, `ConnectivityCubit` |
| Platform guidelines (Material / Cupertino) | ✅ | `lib/core/platform/`: Cupertino search field, tab bar, sliding segmented control on iOS; Material 3 equivalents on Android; adaptive loaders, sliders, refresh |
| Bonus: Coordinator navigation | ✅ | `lib/app/router/app_coordinator.dart`, `go_router_coordinator.dart` (the only file that knows routes) |
| Bonus: Network availability handling | ✅ | `lib/core/connectivity/`, `lib/core/widgets/offline_banner.dart`, auto-retry in every feature |
| Bonus: Something unique | ✅ | GIF Studio, dominant-color detail page, Guess the GIF |
| API key not committed | ✅ | `--dart-define-from-file=.env`, `.env` git-ignored, `.env.example` committed |
| GIPHY attribution | ✅ | `lib/core/widgets/giphy_attribution.dart`, shown in the feed header, end of results and detail page |
| CI | ✅ | `.github/workflows/ci.yml` (format, analyze, test with coverage) |

## Architecture

```
lib/
  main.dart                  entry point, missing-key guard
  app/
    app.dart                 MaterialApp.router, themes, app-wide providers
    di.dart                  get_it registrations (composition root)
    missing_api_key_app.dart
    router/                  AppCoordinator, GoRouterCoordinator, routes
    shell/                   adaptive bottom bar / tab bar / rail
  core/
    config/                  Env (API key), GIPHY constants, breakpoints
    connectivity/            ConnectivityCubit, ReconnectListener
    errors/                  Failure, Result, mapping, user-facing messages
    formatting/              byte sizes
    media/                   image prefetching
    network/                 Dio factory, CancellationToken
    platform/                adaptive helpers
    theme/                   theme, spacing/durations, palettes
    widgets/                 ErrorView, EmptyView, OfflineBanner, Shimmer, ...
    strings.dart             every user-facing string
  features/
    gifs/                    domain models, repository contract, GIPHY API + DTOs
    feed/                    Explore tab: FeedBloc, search field, masonry grid
    details/                 detail page, GifDetailsCubit, dominant color
    studio/                  PlaybackEngine, frame loader/decoder, controller, player
    game/                    GameCubit, terms, best score, game UI
```

**Data flow:** Widget → Bloc/Cubit → `GifRepository` → `GiphyApi` → Dio. The repository turns DTOs into immutable domain models. It returns a sealed `Result<T>` (`Success` / `Err(Failure)`) and never throws into the UI. Widgets never touch Dio, go_router or get_it. They get blocs through `BlocProvider` and navigate through `AppCoordinator`.

**Why BLoC.** The feed is event-driven: keystrokes, submits, scrolls, refreshes and reconnects. bloc's event transformers handle the hard parts declaratively (debounce, restartable, droppable), and `bloc_test` makes all of it easy to verify. The simpler screens use Cubits.

**Why a Coordinator over raw go_router.** Pages say *what* should happen (`showGifDetails(gif)`), never *how*. `GoRouterCoordinator` is the only file that knows route paths, `extra`, root vs. shell navigators and how pages get their blocs. Swapping the router or adding deep links does not touch any page. Widget tests just verify calls on a mock coordinator.

**Why no use-case layer.** Each use case here would be a one-line pass-through to the repository. For an app this size, a use-case layer adds files without adding decisions. The repository interface is already the seam that tests mock.

## Key decisions and trade-offs

- **Debounce 400 ms.** This is long enough to skip intermediate keystrokes and short enough to feel live. The keyboard search action skips it. A new query restarts the handler *and* cancels the in-flight HTTP request (`CancellationToken` → Dio `CancelToken`), so stale results can never overwrite fresh ones.
- **Page size 30.** It fills two screens of a phone grid per request, which matters with the beta rate limit.
- **De-duplication.** GIPHY can return the same GIF on several pages, so items are de-duplicated by id when appending. Paging still advances by GIPHY's own `count`.
- **End of results.** Paging stops at `total_count` or at GIPHY's max offset. The docs give **4999 for search and 499 for trending** (the trending limit is lower than the 4999 the task mentioned, so I followed the docs).
- **API details verified against the docs.** `lang=en` is sent only to search, because trending does not accept it. GIPHY's documented "synthetic response" (status 200, empty `response_id`, empty body) is treated as an error. All numbers in `images` arrive as strings and are parsed with `int.tryParse`.
- **Rating.** The feed uses `pg`. The game uses `g`.
- **Rate limits.** Beta keys allow about 100 requests per hour. HTTP 429 maps to `RateLimitedFailure` ("GIPHY request limit reached, try again later"). Debounce, cancelling and the page size all help stay under the limit. The game uses **one request per round** (plus the prefetch of the next one), so a full game costs about 10 requests.
- **Studio memory budget.** Every frame is decoded into memory (`frames × width × height × 4` bytes). If that would exceed **120 MB**, the GIF is decoded at a smaller width that fits, keeping the aspect ratio. Frames shorter than 20 ms play at 100 ms, like browsers do. All `ui.Image`s are disposed when the page closes, and also when decoding finishes after the page is gone.
- **Shared image cache.** The grid, Studio, dominant color and game prefetch all use the same `flutter_cache_manager` cache, so a GIF opened from the grid is often already on disk.
- **Hero across tabs.** The shell keeps both tabs alive. Inactive branches are wrapped in `HeroMode(enabled: false)` so a hidden tab's tile can't hijack a Hero flight.
- **Connectivity limitations.** `connectivity_plus` only reports network interfaces, not real internet access. A Dio connection error is therefore always treated as `NoConnectionFailure`, whatever the cubit says. Auto-retry fires on the offline → online transition and only retries connection or timeout failures, never 401 or 429.
- **Attribution.** GIPHY requires "Powered by GIPHY". It is shown as text (no logo asset) in the feed header, at the end of results and on the detail page.

## Testing

162 tests, all passing (`flutter test`):

- **Parsing:** full responses, missing user/webp/bitly_url, string numbers, null renditions, synthetic responses (`test/features/gifs/`, fixtures in `test/fixtures/`).
- **Failure mapping:** timeouts, connection errors, 401/403/404/429/500, malformed JSON, media errors.
- **Repository:** endpoints, query params, cancellation, `Success`/`Err` results (Dio mocked with mocktail).
- **FeedBloc:** debounce (rapid typing results in a single request), submit bypasses the debounce, trending for an empty query, stale responses ignored, cancellation, append and de-duplication, `total_count` and max offset, no parallel load-more, first-page and load-more failures, retry, refresh, auto-retry on reconnect.
- **PlaybackEngine:** forward wrap-around, reverse, ping-pong at both ends, speeds, elapsed time spanning frames and whole cycles, seek and step bounds, zero-duration frames, single-frame GIFs.
- **Studio:** memory budget, controller playback, pausing on seek, stepping, app lifecycle pause/resume, frame disposal.
- **Dominant color:** solid, black/white dominated, transparent, mixed images.
- **GameCubit:** seeded `Random` determinism, four unique options with the answer exactly once, scoring, streak, prefetch, end of game, best score persistence (`SharedPreferences.setMockInitialValues`), failures and reconnect.
- **Connectivity:** cubit, offline banner in/out, reconnect listener.
- **Widget tests:** feed loader to grid, error/empty/footer states, search input, detail info/actions/Studio controls with a mocked decoder, game interactions, adaptive shell. Layout tests render the feed, detail and game at 360×640, 640×360 and 1280×800 with 1.5× text scale and fail on any overflow. One real overflow was caught and fixed this way.

## Known limitations / what I'd do next

- **iOS not run.** This was built on Windows, so the iOS app was never built or run. The iOS project needs nothing extra for `url_launcher` (https) or `share_plus`, and the share sheet passes `sharePositionOrigin` for iPad, but both are unverified on a device.
- **Android checked on an emulator only, without a real GIPHY key.** `flutter build apk --debug` succeeds. On an API 33 emulator I checked the shell, tab switching, the landscape NavigationRail and the error views against the live API, which rejected the dummy key with 401/403. The happy paths (grid, Studio playback, game rounds) are covered by tests but still need a run with a real key. That emulator's software GPU could not compile Impeller shaders, so it ran with `--ez enable-impeller false`. This is an emulator limitation, not app code.
- **No integration tests.** I would add `integration_test` flows (search → detail → Studio, a full game) running against a fake GIPHY server.
- **The Studio holds all frames in memory.** The 120 MB budget keeps this safe, but a streaming decoder with a small frame window would scale better for very long GIFs.
- **Tiles that failed while offline don't reload by themselves.** The data retries on reconnect, but `cached_network_image` keeps an image error until the tile is rebuilt (scroll or refresh).
- **GIPHY analytics pingbacks** (`onload`/`onclick`) are not sent. A production app should send them.
- **GIPHY's best practices discourage caching media.** Images are cached on disk for smooth scrolling and the Studio. For production I'd review the cache lifetime against GIPHY's terms.
- **English only.** Strings live in one file (`core/strings.dart`), so moving to `intl`/ARB is mechanical.
