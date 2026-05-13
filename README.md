# yalla-sdk-ios

Pure native iOS SDK for Yalla.

This repository is intentionally separate from the Kotlin Multiplatform SDK and
from the Compose Multiplatform UI package. iOS is a first-class native UI
consumer, with SwiftUI-facing design, resources, and components.

## Intended Layers

- `YallaDesignIOS`: SwiftUI design tokens and theme adapters.
- `YallaResourcesIOS`: SwiftPM resources, asset catalogs, fonts, and icons.
- `YallaComponentsIOS`: SwiftUI components.
- `YallaSDKIOS`: current starter Swift Package product.

The canonical design contract should live in platform-neutral token/resource
specs, then be implemented or generated into Android and iOS native adapters.

## Resources

Native iOS strings are generated from
[`RoyalTaxi/yalla-resources`](https://github.com/RoyalTaxi/yalla-resources) into
`Sources/YallaResourcesIOS/Resources/Localizable.xcstrings`.
Canonical SVG icons are synced into
`Sources/YallaResourcesIOS/Resources/Icons`.
PNG images, fonts, and JSON files are synced into
`Sources/YallaResourcesIOS/Resources/Drawables`,
`Sources/YallaResourcesIOS/Resources/Fonts`, and
`Sources/YallaResourcesIOS/Resources/Files`.

Do not edit generated resource files by hand. Change the canonical source in
`yalla-resources`, then run:

```bash
python3 tools/yalla_resources.py sync --no-cmp --no-android
```
