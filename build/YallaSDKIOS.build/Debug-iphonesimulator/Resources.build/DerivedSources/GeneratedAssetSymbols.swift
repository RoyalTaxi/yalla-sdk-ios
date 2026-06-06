import Foundation
#if canImport(AppKit)
import AppKit
#endif
#if canImport(UIKit)
import UIKit
#endif
#if canImport(SwiftUI)
import SwiftUI
#endif
#if canImport(DeveloperToolsSupport)
import DeveloperToolsSupport
#endif

#if SWIFT_PACKAGE
private let resourceBundle = Foundation.Bundle.module
#else
private class ResourceBundleClass {}
private let resourceBundle = Foundation.Bundle(for: ResourceBundleClass.self)
#endif

// MARK: - Color Symbols -

@available(iOS 11.0, macOS 10.13, tvOS 11.0, *)
extension ColorResource {

    /// The "accent_color1" asset catalog color resource.
    static let accentColor1 = ColorResource(name: "accent_color1", bundle: resourceBundle)

    /// The "accent_color2" asset catalog color resource.
    static let accentColor2 = ColorResource(name: "accent_color2", bundle: resourceBundle)

    /// The "accent_color3" asset catalog color resource.
    static let accentColor3 = ColorResource(name: "accent_color3", bundle: resourceBundle)

    /// The "accent_color4" asset catalog color resource.
    static let accentColor4 = ColorResource(name: "accent_color4", bundle: resourceBundle)

    /// The "accent_color5" asset catalog color resource.
    static let accentColor5 = ColorResource(name: "accent_color5", bundle: resourceBundle)

    /// The "accent_pink_sun" asset catalog color resource.
    static let accentPinkSun = ColorResource(name: "accent_pink_sun", bundle: resourceBundle)

    /// The "background_base" asset catalog color resource.
    static let backgroundBase = ColorResource(name: "background_base", bundle: resourceBundle)

    /// The "background_brand" asset catalog color resource.
    static let backgroundBrand = ColorResource(name: "background_brand", bundle: resourceBundle)

    /// The "background_secondary" asset catalog color resource.
    static let backgroundSecondary = ColorResource(name: "background_secondary", bundle: resourceBundle)

    /// The "background_tertiary" asset catalog color resource.
    static let backgroundTertiary = ColorResource(name: "background_tertiary", bundle: resourceBundle)

    /// The "border_disabled" asset catalog color resource.
    static let borderDisabled = ColorResource(name: "border_disabled", bundle: resourceBundle)

    /// The "border_error" asset catalog color resource.
    static let borderError = ColorResource(name: "border_error", bundle: resourceBundle)

    /// The "border_filled" asset catalog color resource.
    static let borderFilled = ColorResource(name: "border_filled", bundle: resourceBundle)

    /// The "border_white" asset catalog color resource.
    static let borderWhite = ColorResource(name: "border_white", bundle: resourceBundle)

    /// The "button_active" asset catalog color resource.
    static let buttonActive = ColorResource(name: "button_active", bundle: resourceBundle)

    /// The "button_disabled" asset catalog color resource.
    static let buttonDisabled = ColorResource(name: "button_disabled", bundle: resourceBundle)

    /// The "button_disabled_tertiary" asset catalog color resource.
    static let buttonDisabledTertiary = ColorResource(name: "button_disabled_tertiary", bundle: resourceBundle)

    /// The "button_secondary" asset catalog color resource.
    static let buttonSecondary = ColorResource(name: "button_secondary", bundle: resourceBundle)

    /// The "button_tertiary" asset catalog color resource.
    static let buttonTertiary = ColorResource(name: "button_tertiary", bundle: resourceBundle)

    /// The "icon_base" asset catalog color resource.
    static let iconBase = ColorResource(name: "icon_base", bundle: resourceBundle)

    /// The "icon_disabled" asset catalog color resource.
    static let iconDisabled = ColorResource(name: "icon_disabled", bundle: resourceBundle)

    /// The "icon_red" asset catalog color resource.
    static let iconRed = ColorResource(name: "icon_red", bundle: resourceBundle)

    /// The "icon_secondary" asset catalog color resource.
    static let iconSecondary = ColorResource(name: "icon_secondary", bundle: resourceBundle)

    /// The "icon_subtle" asset catalog color resource.
    static let iconSubtle = ColorResource(name: "icon_subtle", bundle: resourceBundle)

    /// The "icon_white" asset catalog color resource.
    static let iconWhite = ColorResource(name: "icon_white", bundle: resourceBundle)

    /// The "text_base" asset catalog color resource.
    static let textBase = ColorResource(name: "text_base", bundle: resourceBundle)

    /// The "text_link" asset catalog color resource.
    static let textLink = ColorResource(name: "text_link", bundle: resourceBundle)

    /// The "text_red" asset catalog color resource.
    static let textRed = ColorResource(name: "text_red", bundle: resourceBundle)

    /// The "text_subtle" asset catalog color resource.
    static let textSubtle = ColorResource(name: "text_subtle", bundle: resourceBundle)

    /// The "text_white" asset catalog color resource.
    static let textWhite = ColorResource(name: "text_white", bundle: resourceBundle)

}

// MARK: - Image Symbols -

@available(iOS 11.0, macOS 10.7, tvOS 11.0, *)
extension ImageResource {

    /// The "ic_add" asset catalog image resource.
    static let icAdd = ImageResource(name: "ic_add", bundle: resourceBundle)

    /// The "ic_add_in_circle" asset catalog image resource.
    static let icAddInCircle = ImageResource(name: "ic_add_in_circle", bundle: resourceBundle)

    /// The "ic_arrow_left" asset catalog image resource.
    static let icArrowLeft = ImageResource(name: "ic_arrow_left", bundle: resourceBundle)

    /// The "ic_arrow_right_in_circle" asset catalog image resource.
    static let icArrowRightInCircle = ImageResource(name: "ic_arrow_right_in_circle", bundle: resourceBundle)

    /// The "ic_brush" asset catalog image resource.
    static let icBrush = ImageResource(name: "ic_brush", bundle: resourceBundle)

    /// The "ic_calendar" asset catalog image resource.
    static let icCalendar = ImageResource(name: "ic_calendar", bundle: resourceBundle)

    /// The "ic_camera" asset catalog image resource.
    static let icCamera = ImageResource(name: "ic_camera", bundle: resourceBundle)

    /// The "ic_car_marker" asset catalog image resource.
    static let icCarMarker = ImageResource(name: "ic_car_marker", bundle: resourceBundle)

    /// The "ic_card_bonus" asset catalog image resource.
    static let icCardBonus = ImageResource(name: "ic_card_bonus", bundle: resourceBundle)

    /// The "ic_case" asset catalog image resource.
    static let icCase = ImageResource(name: "ic_case", bundle: resourceBundle)

    /// The "ic_cash_bonus" asset catalog image resource.
    static let icCashBonus = ImageResource(name: "ic_cash_bonus", bundle: resourceBundle)

    /// The "ic_check" asset catalog image resource.
    static let icCheck = ImageResource(name: "ic_check", bundle: resourceBundle)

    /// The "ic_check_circle" asset catalog image resource.
    static let icCheckCircle = ImageResource(name: "ic_check_circle", bundle: resourceBundle)

    /// The "ic_checked" asset catalog image resource.
    static let icChecked = ImageResource(name: "ic_checked", bundle: resourceBundle)

    /// The "ic_clock" asset catalog image resource.
    static let icClock = ImageResource(name: "ic_clock", bundle: resourceBundle)

    /// The "ic_destination" asset catalog image resource.
    static let icDestination = ImageResource(name: "ic_destination", bundle: resourceBundle)

    /// The "ic_double_check" asset catalog image resource.
    static let icDoubleCheck = ImageResource(name: "ic_double_check", bundle: resourceBundle)

    /// The "ic_expand" asset catalog image resource.
    static let icExpand = ImageResource(name: "ic_expand", bundle: resourceBundle)

    /// The "ic_flag" asset catalog image resource.
    static let icFlag = ImageResource(name: "ic_flag", bundle: resourceBundle)

    /// The "ic_flag_ru" asset catalog image resource.
    static let icFlagRu = ImageResource(name: "ic_flag_ru", bundle: resourceBundle)

    /// The "ic_flag_us" asset catalog image resource.
    static let icFlagUs = ImageResource(name: "ic_flag_us", bundle: resourceBundle)

    /// The "ic_flag_uz" asset catalog image resource.
    static let icFlagUz = ImageResource(name: "ic_flag_uz", bundle: resourceBundle)

    /// The "ic_focus_destination" asset catalog image resource.
    static let icFocusDestination = ImageResource(name: "ic_focus_destination", bundle: resourceBundle)

    /// The "ic_focus_location" asset catalog image resource.
    static let icFocusLocation = ImageResource(name: "ic_focus_location", bundle: resourceBundle)

    /// The "ic_focus_origin" asset catalog image resource.
    static let icFocusOrigin = ImageResource(name: "ic_focus_origin", bundle: resourceBundle)

    /// The "ic_focus_route" asset catalog image resource.
    static let icFocusRoute = ImageResource(name: "ic_focus_route", bundle: resourceBundle)

    /// The "ic_gallery" asset catalog image resource.
    static let icGallery = ImageResource(name: "ic_gallery", bundle: resourceBundle)

    /// The "ic_headset" asset catalog image resource.
    static let icHeadset = ImageResource(name: "ic_headset", bundle: resourceBundle)

    /// The "ic_home" asset catalog image resource.
    static let icHome = ImageResource(name: "ic_home", bundle: resourceBundle)

    /// The "ic_humo" asset catalog image resource.
    static let icHumo = ImageResource(name: "ic_humo", bundle: resourceBundle)

    /// The "ic_info_in_circle" asset catalog image resource.
    static let icInfoInCircle = ImageResource(name: "ic_info_in_circle", bundle: resourceBundle)

    /// The "ic_language" asset catalog image resource.
    static let icLanguage = ImageResource(name: "ic_language", bundle: resourceBundle)

    /// The "ic_location" asset catalog image resource.
    static let icLocation = ImageResource(name: "ic_location", bundle: resourceBundle)

    /// The "ic_location_flag" asset catalog image resource.
    static let icLocationFlag = ImageResource(name: "ic_location_flag", bundle: resourceBundle)

    /// The "ic_logo" asset catalog image resource.
    static let icLogo = ImageResource(name: "ic_logo", bundle: resourceBundle)

    /// The "ic_logo_transparent" asset catalog image resource.
    static let icLogoTransparent = ImageResource(name: "ic_logo_transparent", bundle: resourceBundle)

    /// The "ic_logout" asset catalog image resource.
    static let icLogout = ImageResource(name: "ic_logout", bundle: resourceBundle)

    /// The "ic_menu" asset catalog image resource.
    static let icMenu = ImageResource(name: "ic_menu", bundle: resourceBundle)

    /// The "ic_menu_in_square" asset catalog image resource.
    static let icMenuInSquare = ImageResource(name: "ic_menu_in_square", bundle: resourceBundle)

    /// The "ic_messages" asset catalog image resource.
    static let icMessages = ImageResource(name: "ic_messages", bundle: resourceBundle)

    /// The "ic_more" asset catalog image resource.
    static let icMore = ImageResource(name: "ic_more", bundle: resourceBundle)

    /// The "ic_notification" asset catalog image resource.
    static let icNotification = ImageResource(name: "ic_notification", bundle: resourceBundle)

    /// The "ic_options" asset catalog image resource.
    static let icOptions = ImageResource(name: "ic_options", bundle: resourceBundle)

    /// The "ic_origin" asset catalog image resource.
    static let icOrigin = ImageResource(name: "ic_origin", bundle: resourceBundle)

    /// The "ic_phone" asset catalog image resource.
    static let icPhone = ImageResource(name: "ic_phone", bundle: resourceBundle)

    /// The "ic_pin_shadow" asset catalog image resource.
    static let icPinShadow = ImageResource(name: "ic_pin_shadow", bundle: resourceBundle)

    /// The "ic_places" asset catalog image resource.
    static let icPlaces = ImageResource(name: "ic_places", bundle: resourceBundle)

    /// The "ic_safety" asset catalog image resource.
    static let icSafety = ImageResource(name: "ic_safety", bundle: resourceBundle)

    /// The "ic_scan" asset catalog image resource.
    static let icScan = ImageResource(name: "ic_scan", bundle: resourceBundle)

    /// The "ic_send" asset catalog image resource.
    static let icSend = ImageResource(name: "ic_send", bundle: resourceBundle)

    /// The "ic_setting" asset catalog image resource.
    static let icSetting = ImageResource(name: "ic_setting", bundle: resourceBundle)

    /// The "ic_star" asset catalog image resource.
    static let icStar = ImageResource(name: "ic_star", bundle: resourceBundle)

    /// The "ic_task_list" asset catalog image resource.
    static let icTaskList = ImageResource(name: "ic_task_list", bundle: resourceBundle)

    /// The "ic_telegram" asset catalog image resource.
    static let icTelegram = ImageResource(name: "ic_telegram", bundle: resourceBundle)

    /// The "ic_theme" asset catalog image resource.
    static let icTheme = ImageResource(name: "ic_theme", bundle: resourceBundle)

    /// The "ic_theme_dark" asset catalog image resource.
    static let icThemeDark = ImageResource(name: "ic_theme_dark", bundle: resourceBundle)

    /// The "ic_theme_light" asset catalog image resource.
    static let icThemeLight = ImageResource(name: "ic_theme_light", bundle: resourceBundle)

    /// The "ic_theme_system" asset catalog image resource.
    static let icThemeSystem = ImageResource(name: "ic_theme_system", bundle: resourceBundle)

    /// The "ic_ticket_discount" asset catalog image resource.
    static let icTicketDiscount = ImageResource(name: "ic_ticket_discount", bundle: resourceBundle)

    /// The "ic_timer" asset catalog image resource.
    static let icTimer = ImageResource(name: "ic_timer", bundle: resourceBundle)

    /// The "ic_trash" asset catalog image resource.
    static let icTrash = ImageResource(name: "ic_trash", bundle: resourceBundle)

    /// The "ic_unchecked" asset catalog image resource.
    static let icUnchecked = ImageResource(name: "ic_unchecked", bundle: resourceBundle)

    /// The "ic_uzcard" asset catalog image resource.
    static let icUzcard = ImageResource(name: "ic_uzcard", bundle: resourceBundle)

    /// The "ic_warning" asset catalog image resource.
    static let icWarning = ImageResource(name: "ic_warning", bundle: resourceBundle)

    /// The "ic_x" asset catalog image resource.
    static let icX = ImageResource(name: "ic_x", bundle: resourceBundle)

    /// The "ic_x_in_circle" asset catalog image resource.
    static let icXInCircle = ImageResource(name: "ic_x_in_circle", bundle: resourceBundle)

    /// The "ic_x_in_octagon" asset catalog image resource.
    static let icXInOctagon = ImageResource(name: "ic_x_in_octagon", bundle: resourceBundle)

    /// The "ic_x_in_square" asset catalog image resource.
    static let icXInSquare = ImageResource(name: "ic_x_in_square", bundle: resourceBundle)

    /// The "img_active_order_car" asset catalog image resource.
    static let imgActiveOrderCar = ImageResource(name: "img_active_order_car", bundle: resourceBundle)

    /// The "img_arrow_up" asset catalog image resource.
    static let imgArrowUp = ImageResource(name: "img_arrow_up", bundle: resourceBundle)

    /// The "img_avatar_placeholder" asset catalog image resource.
    static let imgAvatarPlaceholder = ImageResource(name: "img_avatar_placeholder", bundle: resourceBundle)

    /// The "img_banner_bonus" asset catalog image resource.
    static let imgBannerBonus = ImageResource(name: "img_banner_bonus", bundle: resourceBundle)

    /// The "img_banner_gradient" asset catalog image resource.
    static let imgBannerGradient = ImageResource(name: "img_banner_gradient", bundle: resourceBundle)

    /// The "img_banner_ride" asset catalog image resource.
    static let imgBannerRide = ImageResource(name: "img_banner_ride", bundle: resourceBundle)

    /// The "img_blurry_logo" asset catalog image resource.
    static let imgBlurryLogo = ImageResource(name: "img_blurry_logo", bundle: resourceBundle)

    /// The "img_car_business" asset catalog image resource.
    static let imgCarBusiness = ImageResource(name: "img_car_business", bundle: resourceBundle)

    /// The "img_car_cancelled" asset catalog image resource.
    static let imgCarCancelled = ImageResource(name: "img_car_cancelled", bundle: resourceBundle)

    /// The "img_car_comfort" asset catalog image resource.
    static let imgCarComfort = ImageResource(name: "img_car_comfort", bundle: resourceBundle)

    /// The "img_car_cropped" asset catalog image resource.
    static let imgCarCropped = ImageResource(name: "img_car_cropped", bundle: resourceBundle)

    /// The "img_car_delivery" asset catalog image resource.
    static let imgCarDelivery = ImageResource(name: "img_car_delivery", bundle: resourceBundle)

    /// The "img_car_economy" asset catalog image resource.
    static let imgCarEconomy = ImageResource(name: "img_car_economy", bundle: resourceBundle)

    /// The "img_car_finish" asset catalog image resource.
    static let imgCarFinish = ImageResource(name: "img_car_finish", bundle: resourceBundle)

    /// The "img_car_intercity" asset catalog image resource.
    static let imgCarIntercity = ImageResource(name: "img_car_intercity", bundle: resourceBundle)

    /// The "img_car_minivan" asset catalog image resource.
    static let imgCarMinivan = ImageResource(name: "img_car_minivan", bundle: resourceBundle)

    /// The "img_car_premium" asset catalog image resource.
    static let imgCarPremium = ImageResource(name: "img_car_premium", bundle: resourceBundle)

    /// The "img_car_standard" asset catalog image resource.
    static let imgCarStandard = ImageResource(name: "img_car_standard", bundle: resourceBundle)

    /// The "img_car_tow_truck" asset catalog image resource.
    static let imgCarTowTruck = ImageResource(name: "img_car_tow_truck", bundle: resourceBundle)

    /// The "img_card" asset catalog image resource.
    static let imgCard = ImageResource(name: "img_card", bundle: resourceBundle)

    /// The "img_cash" asset catalog image resource.
    static let imgCash = ImageResource(name: "img_cash", bundle: resourceBundle)

    /// The "img_close_circle" asset catalog image resource.
    static let imgCloseCircle = ImageResource(name: "img_close_circle", bundle: resourceBundle)

    /// The "img_coin" asset catalog image resource.
    static let imgCoin = ImageResource(name: "img_coin", bundle: resourceBundle)

    /// The "img_default_photo" asset catalog image resource.
    static let imgDefaultPhoto = ImageResource(name: "img_default_photo", bundle: resourceBundle)

    /// The "img_flag_uz_square" asset catalog image resource.
    static let imgFlagUzSquare = ImageResource(name: "img_flag_uz_square", bundle: resourceBundle)

    /// The "img_login" asset catalog image resource.
    static let imgLogin = ImageResource(name: "img_login", bundle: resourceBundle)

    /// The "img_logo_splash" asset catalog image resource.
    static let imgLogoSplash = ImageResource(name: "img_logo_splash", bundle: resourceBundle)

    /// The "img_logout" asset catalog image resource.
    static let imgLogout = ImageResource(name: "img_logout", bundle: resourceBundle)

    /// The "img_map_pin" asset catalog image resource.
    static let imgMapPin = ImageResource(name: "img_map_pin", bundle: resourceBundle)

    /// The "img_no_service_pin" asset catalog image resource.
    static let imgNoServicePin = ImageResource(name: "img_no_service_pin", bundle: resourceBundle)

    /// The "img_notification" asset catalog image resource.
    static let imgNotification = ImageResource(name: "img_notification", bundle: resourceBundle)

    /// The "img_notification_mute" asset catalog image resource.
    static let imgNotificationMute = ImageResource(name: "img_notification_mute", bundle: resourceBundle)

    /// The "img_order_history" asset catalog image resource.
    static let imgOrderHistory = ImageResource(name: "img_order_history", bundle: resourceBundle)

    /// The "img_order_search" asset catalog image resource.
    static let imgOrderSearch = ImageResource(name: "img_order_search", bundle: resourceBundle)

    /// The "img_photo_upload" asset catalog image resource.
    static let imgPhotoUpload = ImageResource(name: "img_photo_upload", bundle: resourceBundle)

    /// The "img_safety" asset catalog image resource.
    static let imgSafety = ImageResource(name: "img_safety", bundle: resourceBundle)

    /// The "img_sensitive_background" asset catalog image resource.
    static let imgSensitiveBackground = ImageResource(name: "img_sensitive_background", bundle: resourceBundle)

    /// The "img_service_delivery" asset catalog image resource.
    static let imgServiceDelivery = ImageResource(name: "img_service_delivery", bundle: resourceBundle)

    /// The "img_service_delivery_small" asset catalog image resource.
    static let imgServiceDeliverySmall = ImageResource(name: "img_service_delivery_small", bundle: resourceBundle)

    /// The "img_service_intercity" asset catalog image resource.
    static let imgServiceIntercity = ImageResource(name: "img_service_intercity", bundle: resourceBundle)

    /// The "img_service_intercity_small" asset catalog image resource.
    static let imgServiceIntercitySmall = ImageResource(name: "img_service_intercity_small", bundle: resourceBundle)

    /// The "img_service_mail" asset catalog image resource.
    static let imgServiceMail = ImageResource(name: "img_service_mail", bundle: resourceBundle)

    /// The "img_service_mail_small" asset catalog image resource.
    static let imgServiceMailSmall = ImageResource(name: "img_service_mail_small", bundle: resourceBundle)

    /// The "img_service_taxi" asset catalog image resource.
    static let imgServiceTaxi = ImageResource(name: "img_service_taxi", bundle: resourceBundle)

    /// The "img_service_taxi_small" asset catalog image resource.
    static let imgServiceTaxiSmall = ImageResource(name: "img_service_taxi_small", bundle: resourceBundle)

    /// The "img_shield_check" asset catalog image resource.
    static let imgShieldCheck = ImageResource(name: "img_shield_check", bundle: resourceBundle)

    /// The "img_spinner" asset catalog image resource.
    static let imgSpinner = ImageResource(name: "img_spinner", bundle: resourceBundle)

    /// The "img_tariff_card" asset catalog image resource.
    static let imgTariffCard = ImageResource(name: "img_tariff_card", bundle: resourceBundle)

    /// The "img_toggle" asset catalog image resource.
    static let imgToggle = ImageResource(name: "img_toggle", bundle: resourceBundle)

    /// The "img_trash_can" asset catalog image resource.
    static let imgTrashCan = ImageResource(name: "img_trash_can", bundle: resourceBundle)

    /// The "img_upload_photo" asset catalog image resource.
    static let imgUploadPhoto = ImageResource(name: "img_upload_photo", bundle: resourceBundle)

    /// The "img_wifi" asset catalog image resource.
    static let imgWifi = ImageResource(name: "img_wifi", bundle: resourceBundle)

}

// MARK: - Backwards Deployment Support -

/// A color resource.
struct ColorResource: Swift.Hashable, Swift.Sendable {

    /// An asset catalog color resource name.
    fileprivate let name: Swift.String

    /// An asset catalog color resource bundle.
    fileprivate let bundle: Foundation.Bundle

    /// Initialize a `ColorResource` with `name` and `bundle`.
    init(name: Swift.String, bundle: Foundation.Bundle) {
        self.name = name
        self.bundle = bundle
    }

}

/// An image resource.
struct ImageResource: Swift.Hashable, Swift.Sendable {

    /// An asset catalog image resource name.
    fileprivate let name: Swift.String

    /// An asset catalog image resource bundle.
    fileprivate let bundle: Foundation.Bundle

    /// Initialize an `ImageResource` with `name` and `bundle`.
    init(name: Swift.String, bundle: Foundation.Bundle) {
        self.name = name
        self.bundle = bundle
    }

}

#if canImport(AppKit)
@available(macOS 10.13, *)
@available(macCatalyst, unavailable)
extension AppKit.NSColor {

    /// Initialize a `NSColor` with a color resource.
    convenience init(resource: ColorResource) {
        self.init(named: NSColor.Name(resource.name), bundle: resource.bundle)!
    }

}

protocol _ACResourceInitProtocol {}
extension AppKit.NSImage: _ACResourceInitProtocol {}

@available(macOS 10.7, *)
@available(macCatalyst, unavailable)
extension _ACResourceInitProtocol {

    /// Initialize a `NSImage` with an image resource.
    init(resource: ImageResource) {
        self = resource.bundle.image(forResource: NSImage.Name(resource.name))! as! Self
    }

}
#endif

#if canImport(UIKit)
@available(iOS 11.0, tvOS 11.0, *)
@available(watchOS, unavailable)
extension UIKit.UIColor {

    /// Initialize a `UIColor` with a color resource.
    convenience init(resource: ColorResource) {
#if !os(watchOS)
        self.init(named: resource.name, in: resource.bundle, compatibleWith: nil)!
#else
        self.init()
#endif
    }

}

@available(iOS 11.0, tvOS 11.0, *)
@available(watchOS, unavailable)
extension UIKit.UIImage {

    /// Initialize a `UIImage` with an image resource.
    convenience init(resource: ImageResource) {
#if !os(watchOS)
        self.init(named: resource.name, in: resource.bundle, compatibleWith: nil)!
#else
        self.init()
#endif
    }

}
#endif

#if canImport(SwiftUI)
@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension SwiftUI.Color {

    /// Initialize a `Color` with a color resource.
    init(_ resource: ColorResource) {
        self.init(resource.name, bundle: resource.bundle)
    }

}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension SwiftUI.Image {

    /// Initialize an `Image` with an image resource.
    init(_ resource: ImageResource) {
        self.init(resource.name, bundle: resource.bundle)
    }

}
#endif