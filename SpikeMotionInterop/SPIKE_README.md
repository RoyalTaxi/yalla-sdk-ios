# Carto iOS motion-loop interop spike

**Goal:** measure on-device whether Kotlin/Native → Swift `setMarkerPose` calls, pushed **per marker
per frame at 30 Hz** from carto's commonMain motion loop, hold frame rate — or whether MapSurface
needs a batched `applyPoses`.

**This is throwaway.** Do not push/commit. Delete `SpikeMotionInterop/` and
`carto/.../spike/PoseDriver.kt` after deciding.

---

## ⚠️ VERIFIED BLOCKER — carto does not ship to iOS today

I confirmed (file checks, not a guess):
- `carto/src/` has **only `commonMain` + `commonTest`** — **no `iosMain`**, no iOS source set wired up.
- The only XCFramework iOS consumes is **`YallaComponents.xcframework`** (`Package.swift:34`).
- `components/build.gradle.kts` has **no dependency on `:carto`**, so carto is **not** re-exported
  into the `YallaComponents` umbrella either.

⇒ **`import YallaCarto` will not resolve, and no existing umbrella contains carto's symbols.** You
cannot run the real crossing until carto reaches iOS. That is itself a finding. The fastest unblock
for *this spike* (don't do this for production):

> **Temporarily put the Kotlin driver in `components`.** Move/copy `PoseDriver.kt` into
> `components/src/commonMain/kotlin/.../spike/` (it has zero carto deps — it uses only `kotlin.math`,
> so it compiles anywhere), rebuild `YallaComponents.xcframework`, and keep `import YallaComponents`
> in the Swift files (change the three `import YallaCarto` lines to `import YallaComponents`). This
> still crosses the **real Kotlin/Native→Swift boundary** — which is the entire point — it just rides
> the umbrella that already ships. The crossing cost is identical regardless of which framework hosts
> the symbol.

If/when carto gets its own iOS framework, the same `PoseDriver.kt` already living at
`carto/.../spike/` builds as `import YallaCarto` with no changes.

---

## Why this is the real risk (not a Swift simulation)

Today (`yalla-sdk-ios/Sources/Maps/MarkerMotionDriver.swift`): the **whole** motion loop runs in
Swift. CADisplayLink ticks Swift; Swift calls Kotlin `DriverMotionModel.sample()` (Swift→Kotlin,
cheap); Kotlin calls Swift `onFrame(poses)` **once per frame** with a batch dict
(`MarkerMotionDriver.swift:140`). One Kotlin→Swift crossing per frame, period.

After the carto refactor (`carto/.../capability/MotionCapability.kt:111-135`): the loop lives in
**commonMain**. `MotionHandle.tick()` iterates markers and calls
`surface.setMarkerPose(id, point, bearing)` **once per marker** (`:126`). On iOS, `surface` is a
Swift object behind the Kotlin/Native boundary, so that is **30 Hz × N** Kotlin→Swift crossings that
never existed. That is the thing under test. A pure-Swift loop would not measure it — so this spike
drives a **real Kotlin `PoseDriver`** (in `YallaCarto.framework`) that calls back into the Swift
`SpikeMapSurface` per frame, reproducing the exact production crossing.

---

## What I chose, and why

I added a tiny Kotlin **`PoseDriver`** + **`SpikeSurface`** interface in carto commonMain
(`carto/src/commonMain/kotlin/uz/yalla/carto/spike/PoseDriver.kt`) rather than making the Swift class
conform to the real `MapSurface` (which has ~30 methods — far too heavy for a spike, and most are
irrelevant to the crossing cost).

- `SpikeSurface` is a **Kotlin interface** that Swift conforms to — the **same proven pattern** the
  production code already uses: `LibreMapRenderer: NSObject, IosMapListener`
  (`LibreMapRenderer.swift:5`), `YallaSnackbarFactory: NSObject, SnackbarFactory`. Kotlin interface
  → ObjC protocol → Swift `NSObject` subclass.
- `PoseDriver.tick(frameMs)` is pumped by the Swift CADisplayLink at 30 Hz (same clock the real
  `FrameClock` is built on), so the boundary measured **is** the production boundary.
- Two modes: `PER_MARKER` (mirrors `MotionHandle.tick` — N crossings/frame) and `BATCHED` (one
  `applyPoses(ids, lats, lngs, bearings)` crossing/frame). Batched uses **parallel primitive arrays**,
  the cheapest possible payload — if even that does not beat per-marker, batching is not the fix.

Files:
- `carto/src/commonMain/kotlin/uz/yalla/carto/spike/PoseDriver.kt` — Kotlin driver + `SpikeSurface` + `SpikeMode`.
- `SpikeMotionInterop/SpikeMapSurface.swift` — MapLibre wrapper conforming to `SpikeSurface`.
- `SpikeMotionInterop/SpikeHarness.swift` — CADisplayLink + per-frame timing.
- `SpikeMotionInterop/SpikeViewController.swift` — runnable screen (map + N picker + Run + log).

---

## RUN

Two builds: get `PoseDriver` into a framework iOS links, then run the iOS app.

### 1. Get `PoseDriver` into a shippable framework

Per the BLOCKER above, carto has no iOS framework. Host the driver in `components` for the spike:

```bash
cd /Users/islom/StudioProjects/yalla-sdk
mkdir -p components/src/commonMain/kotlin/uz/yalla/spike
cp carto/src/commonMain/kotlin/uz/yalla/carto/spike/PoseDriver.kt \
   components/src/commonMain/kotlin/uz/yalla/spike/PoseDriver.kt
# edit the copy: change `package uz.yalla.carto.spike` -> `package uz.yalla.spike`
# (it has no carto imports — only kotlin.math — so it compiles in components unchanged otherwise)

# rebuild the umbrella iOS already consumes (use your project's actual task name; discover it with:)
./gradlew :components:tasks --all | grep -i xcframework
./gradlew :components:assembleYallaComponentsDebugXCFramework   # <- adjust to the real task name
ls components/build/XCFrameworks/debug/                          # YallaComponents.xcframework should be fresh
```

Then keep `import YallaComponents` in the three Swift files (change the `import YallaCarto` lines).
Verify the Kotlin symbols are exported: open the generated umbrella header and grep for `PoseDriver`:

```bash
find components/build -name '*.h' -path '*YallaComponents*' | xargs grep -l PoseDriver
```

If `PoseDriver`/`SpikeSurface`/`SpikeMode` don't appear, they weren't exported — check that the file
landed in `commonMain` (not a test source set) and that `components` has no `explicitApi` visibility
gate hiding them (they're already `public`).

> If carto has **no** iOS build at all yet (its `build.gradle.kts` declares `iosArm64`/
> `iosSimulatorArm64` via the convention plugin, but it may not be assembled into an xcframework you
> consume), that is itself a finding the spike surfaces: you cannot run the real crossing until carto
> ships to iOS. In that case the fastest path is to temporarily add `PoseDriver`/`SpikeSurface` to the
> `components` module (which already ships `YallaComponents`) and `import YallaComponents`.

### 2. Run the screen

This package is a library (`Package.swift` builds `Maps`/`Bridges` libs, not an app), so the spike
files are **not** auto-compiled. Two options:

- **Option A (host app):** create a throwaway single-view iOS app target in Xcode, add the three
  `SpikeMotionInterop/*.swift` files + the MapLibre and `YallaCarto`/`YallaComponents` dependencies,
  and set the root VC:
  ```swift
  // SceneDelegate or @main
  window?.rootViewController = SpikeViewController()
  ```
- **Option B:** add a `Spike` executable/app target to a local-only `Package.swift` variant and run
  on a **physical device** (not simulator — the simulator's CPU/GPU profile is not representative;
  Kotlin/Native interop and Metal both behave differently there).

Pick **N = 50** first, tap **Run both modes**, watch the log. Then 100, then 200, then 10.

---

## MEASURE

Each run prints one line per mode, e.g.:

```
PER_MARKER N=100  avg 4.20ms  p95 9.80ms  max 22.10ms  >16.6ms:6  >33.3ms:0  dropped:4  (frames 300)
BATCHED    N=100  avg 1.10ms  p95 1.90ms  max 3.40ms   >16.6ms:0  >33.3ms:0  dropped:0  (frames 300)
>>> VERDICT N=100: PER_MARKER janks, BATCHED holds -> ADD applyPoses to MapSurface.
```

Read these columns:
- **avg / p95 / max work (ms):** wall time spent inside the per-frame callback (Kotlin tick + Swift
  mutations). This is the crossing cost.
- **>16.6ms:** frames whose work exceeded one 60 Hz refresh. Any non-trivial count = visible jank on
  a 60 Hz device, even though the link is set to 30 Hz, because the work runs on the main thread.
- **>33.3ms:** frames that blew the 30 Hz budget outright.
- **dropped:** vsyncs the CADisplayLink skipped (callback overran). The hard signal.

Also glance at the map: markers should glide smoothly. Stutter you can see = the numbers are real.

**Run on a representative mid/low-end device, not just your newest iPhone** — the boundary cost is
relative to CPU. A Pro Max can hide a regression a base/older device exposes.

---

## DECIDE

> First answer the load-bearing question the whole decision hinges on: **how many drivers actually
> animate at once on screen in production?** If realistic N is ~5–20 and PER_MARKER holds there, the
> 200 case is academic. If the search/dispatch screen routinely shows 50–100+ cars, the high-N
> result governs.

Per N (10 / 50 / 100 / 200):

| Observation | Decision |
|---|---|
| PER_MARKER `>16.6ms` ≈ 0 and `dropped` = 0 at realistic N | **Keep the simple per-marker path.** No `applyPoses`. The crossing is cheap; commonMain owning the loop is fine. |
| PER_MARKER janks (`>16.6ms` frequent or `dropped` > 0) **and** BATCHED holds at the same N | **Add `applyPoses(ids, lats, lngs, bearings)` to the `MapSurface` contract** and have `MotionHandle.tick` build the batch once and make a single call. **Every** surface implements it: Android (Libre + Google) and iOS. |
| Both struggle at realistic N | The cost is the **loop/interp**, not the crossing — batching won't save it. Investigate moving interpolation off the main thread, throttling change-detection, or capping animated markers. |

If the decision is "add `applyPoses`": the production batched call should pass **parallel primitive
arrays** (as this spike does), not `List<Pose>` — a list of Kotlin objects re-boxes every element
across the boundary and partly defeats the point.

---

## EVERY interop uncertainty / assumption (I could not compile — verify each on first build)

0. **Build wiring (RESOLVED — see BLOCKER):** carto has no iOS framework and is not in any umbrella
   iOS links. Driver must be hosted in `components` for the spike; Swift imports `YallaComponents`.
   This is verified, not assumed.
1. **Symbol export under the umbrella:** that `PoseDriver`/`SpikeSurface`/`SpikeMode` actually appear
   in the regenerated `YallaComponents` ObjC header (they're `public`, in `commonMain` — they should,
   but `grep` the header to confirm, RUN step 1).
2. **`SpikeMode` enum projection:** Kotlin `enum class SpikeMode { PER_MARKER, BATCHED }` → Swift
   cases. I assumed `.perMarker` / `.batched` (Kotlin enum entries project to camelCase Swift enum
   cases). If the toolchain instead exposes `SpikeMode.perMarker` as a class with `.shared`-style
   accessors (as `MotionMode.RouteFollowing.shared` does in `LibreMapRenderer.swift:61` — those are
   **sealed-class objects**, not enum entries), adjust. Plain `enum class` entries normally project
   as Swift enum cases; sealed-class subtypes project as the `.shared` form. `SpikeMode` is a plain
   enum, so `.perMarker`/`.batched` is the expectation.
3. **`setMarkerPose` Swift selector + types:** assumed `setMarkerPose(id:lat:lng:bearing:)` with
   `bearing: Float`. Kotlin non-null `Float` value params project to Swift `Float` (NOT `KotlinFloat`
   — `KotlinFloat` only appears for **nullable** `Float?`, as in `MarkerMotionDriver.swift:63`
   `routeHint: KotlinFloat`). `id: String` ↔ Kotlin `String`. Confirm the exact protocol method
   signature Xcode generates; the Swift compiler error will give you the precise one to match.
4. **Primitive arrays in `applyPoses`:** Kotlin `DoubleArray`/`FloatArray` project to Swift as
   `KotlinDoubleArray`/`KotlinFloatArray`, indexed via `.get(index: Int32)` — **not** `[Double]`/
   `[Float]` and **not** subscriptable. `List<String>` projects to Swift `[String]`. The spike codes
   this assumption; if the projection differs (e.g. a newer K/N exposes `[Double]` directly), simplify
   the `applyPoses` body accordingly.
5. **`Int32` for marker count:** Kotlin `Int` ↔ Swift `Int32`. `PoseDriver(markerCount: Int32(...))`
   and `frameMs: Int64(...)` reflect that. Confirm.
6. **Style URL reachability:** `demotiles.maplibre.org` must be reachable on the device's network. An
   unreachable style leaves tiles blank but does **not** invalidate the measurement — annotations
   mutate regardless of whether tiles load. Swap in your real style URL for a realistic GPU load
   (tile rendering competes for the same main thread / GPU, so a blank map slightly *understates*
   real-world frame pressure).
7. **Main-thread assumption:** CADisplayLink fires on the main thread and `PoseDriver.tick` runs
   synchronously there, matching how the production surface must apply annotation mutations (MapLibre
   annotation mutation is main-thread-only). If the real carto loop runs on a background dispatcher
   and only hops to main for the Swift call, the per-call hop cost differs — but per-marker that hop
   is *also* per crossing, which would make PER_MARKER **worse**, not better, so this spike is a
   lower bound on the per-marker cost. Note it.
8. **Change-detection:** the real `MotionHandle.tick` skips `setMarkerPose` when a marker hasn't moved
   (`:119-127`). The spike moves **every** marker **every** frame (orbits them) to measure the worst
   case — all N crossing every frame. Real workloads cross fewer. So a PASS here is conservative
   (real is easier); a FAIL here might still be acceptable if few markers move per frame — judge with
   the realistic-N answer.
9. **`weak`/retain of the Swift surface by Kotlin:** `PoseDriver` holds a strong ref to the Swift
   `SpikeSurface`. In production you must avoid a Kotlin↔Swift retain cycle (Kotlin holding Swift
   holding Kotlin). Out of scope for the measurement, but flag for the real implementation.
