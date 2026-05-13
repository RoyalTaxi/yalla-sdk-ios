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
