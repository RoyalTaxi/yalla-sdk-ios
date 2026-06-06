#import <Foundation/Foundation.h>

#if __has_attribute(swift_private)
#define AC_SWIFT_PRIVATE __attribute__((swift_private))
#else
#define AC_SWIFT_PRIVATE
#endif

/// The resource bundle ID.
static NSString * const ACBundleID AC_SWIFT_PRIVATE = @"yalla-sdk-ios.Resources";

/// The "accent_color1" asset catalog color resource.
static NSString * const ACColorNameAccentColor1 AC_SWIFT_PRIVATE = @"accent_color1";

/// The "accent_color2" asset catalog color resource.
static NSString * const ACColorNameAccentColor2 AC_SWIFT_PRIVATE = @"accent_color2";

/// The "accent_color3" asset catalog color resource.
static NSString * const ACColorNameAccentColor3 AC_SWIFT_PRIVATE = @"accent_color3";

/// The "accent_color4" asset catalog color resource.
static NSString * const ACColorNameAccentColor4 AC_SWIFT_PRIVATE = @"accent_color4";

/// The "accent_color5" asset catalog color resource.
static NSString * const ACColorNameAccentColor5 AC_SWIFT_PRIVATE = @"accent_color5";

/// The "accent_pink_sun" asset catalog color resource.
static NSString * const ACColorNameAccentPinkSun AC_SWIFT_PRIVATE = @"accent_pink_sun";

/// The "background_base" asset catalog color resource.
static NSString * const ACColorNameBackgroundBase AC_SWIFT_PRIVATE = @"background_base";

/// The "background_brand" asset catalog color resource.
static NSString * const ACColorNameBackgroundBrand AC_SWIFT_PRIVATE = @"background_brand";

/// The "background_secondary" asset catalog color resource.
static NSString * const ACColorNameBackgroundSecondary AC_SWIFT_PRIVATE = @"background_secondary";

/// The "background_tertiary" asset catalog color resource.
static NSString * const ACColorNameBackgroundTertiary AC_SWIFT_PRIVATE = @"background_tertiary";

/// The "border_disabled" asset catalog color resource.
static NSString * const ACColorNameBorderDisabled AC_SWIFT_PRIVATE = @"border_disabled";

/// The "border_error" asset catalog color resource.
static NSString * const ACColorNameBorderError AC_SWIFT_PRIVATE = @"border_error";

/// The "border_filled" asset catalog color resource.
static NSString * const ACColorNameBorderFilled AC_SWIFT_PRIVATE = @"border_filled";

/// The "border_white" asset catalog color resource.
static NSString * const ACColorNameBorderWhite AC_SWIFT_PRIVATE = @"border_white";

/// The "button_active" asset catalog color resource.
static NSString * const ACColorNameButtonActive AC_SWIFT_PRIVATE = @"button_active";

/// The "button_disabled" asset catalog color resource.
static NSString * const ACColorNameButtonDisabled AC_SWIFT_PRIVATE = @"button_disabled";

/// The "button_disabled_tertiary" asset catalog color resource.
static NSString * const ACColorNameButtonDisabledTertiary AC_SWIFT_PRIVATE = @"button_disabled_tertiary";

/// The "button_secondary" asset catalog color resource.
static NSString * const ACColorNameButtonSecondary AC_SWIFT_PRIVATE = @"button_secondary";

/// The "button_tertiary" asset catalog color resource.
static NSString * const ACColorNameButtonTertiary AC_SWIFT_PRIVATE = @"button_tertiary";

/// The "icon_base" asset catalog color resource.
static NSString * const ACColorNameIconBase AC_SWIFT_PRIVATE = @"icon_base";

/// The "icon_disabled" asset catalog color resource.
static NSString * const ACColorNameIconDisabled AC_SWIFT_PRIVATE = @"icon_disabled";

/// The "icon_red" asset catalog color resource.
static NSString * const ACColorNameIconRed AC_SWIFT_PRIVATE = @"icon_red";

/// The "icon_secondary" asset catalog color resource.
static NSString * const ACColorNameIconSecondary AC_SWIFT_PRIVATE = @"icon_secondary";

/// The "icon_subtle" asset catalog color resource.
static NSString * const ACColorNameIconSubtle AC_SWIFT_PRIVATE = @"icon_subtle";

/// The "icon_white" asset catalog color resource.
static NSString * const ACColorNameIconWhite AC_SWIFT_PRIVATE = @"icon_white";

/// The "text_base" asset catalog color resource.
static NSString * const ACColorNameTextBase AC_SWIFT_PRIVATE = @"text_base";

/// The "text_link" asset catalog color resource.
static NSString * const ACColorNameTextLink AC_SWIFT_PRIVATE = @"text_link";

/// The "text_red" asset catalog color resource.
static NSString * const ACColorNameTextRed AC_SWIFT_PRIVATE = @"text_red";

/// The "text_subtle" asset catalog color resource.
static NSString * const ACColorNameTextSubtle AC_SWIFT_PRIVATE = @"text_subtle";

/// The "text_white" asset catalog color resource.
static NSString * const ACColorNameTextWhite AC_SWIFT_PRIVATE = @"text_white";

/// The "ic_add" asset catalog image resource.
static NSString * const ACImageNameIcAdd AC_SWIFT_PRIVATE = @"ic_add";

/// The "ic_add_in_circle" asset catalog image resource.
static NSString * const ACImageNameIcAddInCircle AC_SWIFT_PRIVATE = @"ic_add_in_circle";

/// The "ic_arrow_left" asset catalog image resource.
static NSString * const ACImageNameIcArrowLeft AC_SWIFT_PRIVATE = @"ic_arrow_left";

/// The "ic_arrow_right_in_circle" asset catalog image resource.
static NSString * const ACImageNameIcArrowRightInCircle AC_SWIFT_PRIVATE = @"ic_arrow_right_in_circle";

/// The "ic_brush" asset catalog image resource.
static NSString * const ACImageNameIcBrush AC_SWIFT_PRIVATE = @"ic_brush";

/// The "ic_calendar" asset catalog image resource.
static NSString * const ACImageNameIcCalendar AC_SWIFT_PRIVATE = @"ic_calendar";

/// The "ic_camera" asset catalog image resource.
static NSString * const ACImageNameIcCamera AC_SWIFT_PRIVATE = @"ic_camera";

/// The "ic_car_marker" asset catalog image resource.
static NSString * const ACImageNameIcCarMarker AC_SWIFT_PRIVATE = @"ic_car_marker";

/// The "ic_card_bonus" asset catalog image resource.
static NSString * const ACImageNameIcCardBonus AC_SWIFT_PRIVATE = @"ic_card_bonus";

/// The "ic_case" asset catalog image resource.
static NSString * const ACImageNameIcCase AC_SWIFT_PRIVATE = @"ic_case";

/// The "ic_cash_bonus" asset catalog image resource.
static NSString * const ACImageNameIcCashBonus AC_SWIFT_PRIVATE = @"ic_cash_bonus";

/// The "ic_check" asset catalog image resource.
static NSString * const ACImageNameIcCheck AC_SWIFT_PRIVATE = @"ic_check";

/// The "ic_check_circle" asset catalog image resource.
static NSString * const ACImageNameIcCheckCircle AC_SWIFT_PRIVATE = @"ic_check_circle";

/// The "ic_checked" asset catalog image resource.
static NSString * const ACImageNameIcChecked AC_SWIFT_PRIVATE = @"ic_checked";

/// The "ic_clock" asset catalog image resource.
static NSString * const ACImageNameIcClock AC_SWIFT_PRIVATE = @"ic_clock";

/// The "ic_destination" asset catalog image resource.
static NSString * const ACImageNameIcDestination AC_SWIFT_PRIVATE = @"ic_destination";

/// The "ic_double_check" asset catalog image resource.
static NSString * const ACImageNameIcDoubleCheck AC_SWIFT_PRIVATE = @"ic_double_check";

/// The "ic_expand" asset catalog image resource.
static NSString * const ACImageNameIcExpand AC_SWIFT_PRIVATE = @"ic_expand";

/// The "ic_flag" asset catalog image resource.
static NSString * const ACImageNameIcFlag AC_SWIFT_PRIVATE = @"ic_flag";

/// The "ic_flag_ru" asset catalog image resource.
static NSString * const ACImageNameIcFlagRu AC_SWIFT_PRIVATE = @"ic_flag_ru";

/// The "ic_flag_us" asset catalog image resource.
static NSString * const ACImageNameIcFlagUs AC_SWIFT_PRIVATE = @"ic_flag_us";

/// The "ic_flag_uz" asset catalog image resource.
static NSString * const ACImageNameIcFlagUz AC_SWIFT_PRIVATE = @"ic_flag_uz";

/// The "ic_focus_destination" asset catalog image resource.
static NSString * const ACImageNameIcFocusDestination AC_SWIFT_PRIVATE = @"ic_focus_destination";

/// The "ic_focus_location" asset catalog image resource.
static NSString * const ACImageNameIcFocusLocation AC_SWIFT_PRIVATE = @"ic_focus_location";

/// The "ic_focus_origin" asset catalog image resource.
static NSString * const ACImageNameIcFocusOrigin AC_SWIFT_PRIVATE = @"ic_focus_origin";

/// The "ic_focus_route" asset catalog image resource.
static NSString * const ACImageNameIcFocusRoute AC_SWIFT_PRIVATE = @"ic_focus_route";

/// The "ic_gallery" asset catalog image resource.
static NSString * const ACImageNameIcGallery AC_SWIFT_PRIVATE = @"ic_gallery";

/// The "ic_headset" asset catalog image resource.
static NSString * const ACImageNameIcHeadset AC_SWIFT_PRIVATE = @"ic_headset";

/// The "ic_home" asset catalog image resource.
static NSString * const ACImageNameIcHome AC_SWIFT_PRIVATE = @"ic_home";

/// The "ic_humo" asset catalog image resource.
static NSString * const ACImageNameIcHumo AC_SWIFT_PRIVATE = @"ic_humo";

/// The "ic_info_in_circle" asset catalog image resource.
static NSString * const ACImageNameIcInfoInCircle AC_SWIFT_PRIVATE = @"ic_info_in_circle";

/// The "ic_language" asset catalog image resource.
static NSString * const ACImageNameIcLanguage AC_SWIFT_PRIVATE = @"ic_language";

/// The "ic_location" asset catalog image resource.
static NSString * const ACImageNameIcLocation AC_SWIFT_PRIVATE = @"ic_location";

/// The "ic_location_flag" asset catalog image resource.
static NSString * const ACImageNameIcLocationFlag AC_SWIFT_PRIVATE = @"ic_location_flag";

/// The "ic_logo" asset catalog image resource.
static NSString * const ACImageNameIcLogo AC_SWIFT_PRIVATE = @"ic_logo";

/// The "ic_logo_transparent" asset catalog image resource.
static NSString * const ACImageNameIcLogoTransparent AC_SWIFT_PRIVATE = @"ic_logo_transparent";

/// The "ic_logout" asset catalog image resource.
static NSString * const ACImageNameIcLogout AC_SWIFT_PRIVATE = @"ic_logout";

/// The "ic_menu" asset catalog image resource.
static NSString * const ACImageNameIcMenu AC_SWIFT_PRIVATE = @"ic_menu";

/// The "ic_menu_in_square" asset catalog image resource.
static NSString * const ACImageNameIcMenuInSquare AC_SWIFT_PRIVATE = @"ic_menu_in_square";

/// The "ic_messages" asset catalog image resource.
static NSString * const ACImageNameIcMessages AC_SWIFT_PRIVATE = @"ic_messages";

/// The "ic_more" asset catalog image resource.
static NSString * const ACImageNameIcMore AC_SWIFT_PRIVATE = @"ic_more";

/// The "ic_notification" asset catalog image resource.
static NSString * const ACImageNameIcNotification AC_SWIFT_PRIVATE = @"ic_notification";

/// The "ic_options" asset catalog image resource.
static NSString * const ACImageNameIcOptions AC_SWIFT_PRIVATE = @"ic_options";

/// The "ic_origin" asset catalog image resource.
static NSString * const ACImageNameIcOrigin AC_SWIFT_PRIVATE = @"ic_origin";

/// The "ic_phone" asset catalog image resource.
static NSString * const ACImageNameIcPhone AC_SWIFT_PRIVATE = @"ic_phone";

/// The "ic_pin_shadow" asset catalog image resource.
static NSString * const ACImageNameIcPinShadow AC_SWIFT_PRIVATE = @"ic_pin_shadow";

/// The "ic_places" asset catalog image resource.
static NSString * const ACImageNameIcPlaces AC_SWIFT_PRIVATE = @"ic_places";

/// The "ic_safety" asset catalog image resource.
static NSString * const ACImageNameIcSafety AC_SWIFT_PRIVATE = @"ic_safety";

/// The "ic_scan" asset catalog image resource.
static NSString * const ACImageNameIcScan AC_SWIFT_PRIVATE = @"ic_scan";

/// The "ic_send" asset catalog image resource.
static NSString * const ACImageNameIcSend AC_SWIFT_PRIVATE = @"ic_send";

/// The "ic_setting" asset catalog image resource.
static NSString * const ACImageNameIcSetting AC_SWIFT_PRIVATE = @"ic_setting";

/// The "ic_star" asset catalog image resource.
static NSString * const ACImageNameIcStar AC_SWIFT_PRIVATE = @"ic_star";

/// The "ic_task_list" asset catalog image resource.
static NSString * const ACImageNameIcTaskList AC_SWIFT_PRIVATE = @"ic_task_list";

/// The "ic_telegram" asset catalog image resource.
static NSString * const ACImageNameIcTelegram AC_SWIFT_PRIVATE = @"ic_telegram";

/// The "ic_theme" asset catalog image resource.
static NSString * const ACImageNameIcTheme AC_SWIFT_PRIVATE = @"ic_theme";

/// The "ic_theme_dark" asset catalog image resource.
static NSString * const ACImageNameIcThemeDark AC_SWIFT_PRIVATE = @"ic_theme_dark";

/// The "ic_theme_light" asset catalog image resource.
static NSString * const ACImageNameIcThemeLight AC_SWIFT_PRIVATE = @"ic_theme_light";

/// The "ic_theme_system" asset catalog image resource.
static NSString * const ACImageNameIcThemeSystem AC_SWIFT_PRIVATE = @"ic_theme_system";

/// The "ic_ticket_discount" asset catalog image resource.
static NSString * const ACImageNameIcTicketDiscount AC_SWIFT_PRIVATE = @"ic_ticket_discount";

/// The "ic_timer" asset catalog image resource.
static NSString * const ACImageNameIcTimer AC_SWIFT_PRIVATE = @"ic_timer";

/// The "ic_trash" asset catalog image resource.
static NSString * const ACImageNameIcTrash AC_SWIFT_PRIVATE = @"ic_trash";

/// The "ic_unchecked" asset catalog image resource.
static NSString * const ACImageNameIcUnchecked AC_SWIFT_PRIVATE = @"ic_unchecked";

/// The "ic_uzcard" asset catalog image resource.
static NSString * const ACImageNameIcUzcard AC_SWIFT_PRIVATE = @"ic_uzcard";

/// The "ic_warning" asset catalog image resource.
static NSString * const ACImageNameIcWarning AC_SWIFT_PRIVATE = @"ic_warning";

/// The "ic_x" asset catalog image resource.
static NSString * const ACImageNameIcX AC_SWIFT_PRIVATE = @"ic_x";

/// The "ic_x_in_circle" asset catalog image resource.
static NSString * const ACImageNameIcXInCircle AC_SWIFT_PRIVATE = @"ic_x_in_circle";

/// The "ic_x_in_octagon" asset catalog image resource.
static NSString * const ACImageNameIcXInOctagon AC_SWIFT_PRIVATE = @"ic_x_in_octagon";

/// The "ic_x_in_square" asset catalog image resource.
static NSString * const ACImageNameIcXInSquare AC_SWIFT_PRIVATE = @"ic_x_in_square";

/// The "img_active_order_car" asset catalog image resource.
static NSString * const ACImageNameImgActiveOrderCar AC_SWIFT_PRIVATE = @"img_active_order_car";

/// The "img_arrow_up" asset catalog image resource.
static NSString * const ACImageNameImgArrowUp AC_SWIFT_PRIVATE = @"img_arrow_up";

/// The "img_avatar_placeholder" asset catalog image resource.
static NSString * const ACImageNameImgAvatarPlaceholder AC_SWIFT_PRIVATE = @"img_avatar_placeholder";

/// The "img_banner_bonus" asset catalog image resource.
static NSString * const ACImageNameImgBannerBonus AC_SWIFT_PRIVATE = @"img_banner_bonus";

/// The "img_banner_gradient" asset catalog image resource.
static NSString * const ACImageNameImgBannerGradient AC_SWIFT_PRIVATE = @"img_banner_gradient";

/// The "img_banner_ride" asset catalog image resource.
static NSString * const ACImageNameImgBannerRide AC_SWIFT_PRIVATE = @"img_banner_ride";

/// The "img_blurry_logo" asset catalog image resource.
static NSString * const ACImageNameImgBlurryLogo AC_SWIFT_PRIVATE = @"img_blurry_logo";

/// The "img_car_business" asset catalog image resource.
static NSString * const ACImageNameImgCarBusiness AC_SWIFT_PRIVATE = @"img_car_business";

/// The "img_car_cancelled" asset catalog image resource.
static NSString * const ACImageNameImgCarCancelled AC_SWIFT_PRIVATE = @"img_car_cancelled";

/// The "img_car_comfort" asset catalog image resource.
static NSString * const ACImageNameImgCarComfort AC_SWIFT_PRIVATE = @"img_car_comfort";

/// The "img_car_cropped" asset catalog image resource.
static NSString * const ACImageNameImgCarCropped AC_SWIFT_PRIVATE = @"img_car_cropped";

/// The "img_car_delivery" asset catalog image resource.
static NSString * const ACImageNameImgCarDelivery AC_SWIFT_PRIVATE = @"img_car_delivery";

/// The "img_car_economy" asset catalog image resource.
static NSString * const ACImageNameImgCarEconomy AC_SWIFT_PRIVATE = @"img_car_economy";

/// The "img_car_finish" asset catalog image resource.
static NSString * const ACImageNameImgCarFinish AC_SWIFT_PRIVATE = @"img_car_finish";

/// The "img_car_intercity" asset catalog image resource.
static NSString * const ACImageNameImgCarIntercity AC_SWIFT_PRIVATE = @"img_car_intercity";

/// The "img_car_minivan" asset catalog image resource.
static NSString * const ACImageNameImgCarMinivan AC_SWIFT_PRIVATE = @"img_car_minivan";

/// The "img_car_premium" asset catalog image resource.
static NSString * const ACImageNameImgCarPremium AC_SWIFT_PRIVATE = @"img_car_premium";

/// The "img_car_standard" asset catalog image resource.
static NSString * const ACImageNameImgCarStandard AC_SWIFT_PRIVATE = @"img_car_standard";

/// The "img_car_tow_truck" asset catalog image resource.
static NSString * const ACImageNameImgCarTowTruck AC_SWIFT_PRIVATE = @"img_car_tow_truck";

/// The "img_card" asset catalog image resource.
static NSString * const ACImageNameImgCard AC_SWIFT_PRIVATE = @"img_card";

/// The "img_cash" asset catalog image resource.
static NSString * const ACImageNameImgCash AC_SWIFT_PRIVATE = @"img_cash";

/// The "img_close_circle" asset catalog image resource.
static NSString * const ACImageNameImgCloseCircle AC_SWIFT_PRIVATE = @"img_close_circle";

/// The "img_coin" asset catalog image resource.
static NSString * const ACImageNameImgCoin AC_SWIFT_PRIVATE = @"img_coin";

/// The "img_default_photo" asset catalog image resource.
static NSString * const ACImageNameImgDefaultPhoto AC_SWIFT_PRIVATE = @"img_default_photo";

/// The "img_flag_uz_square" asset catalog image resource.
static NSString * const ACImageNameImgFlagUzSquare AC_SWIFT_PRIVATE = @"img_flag_uz_square";

/// The "img_login" asset catalog image resource.
static NSString * const ACImageNameImgLogin AC_SWIFT_PRIVATE = @"img_login";

/// The "img_logo_splash" asset catalog image resource.
static NSString * const ACImageNameImgLogoSplash AC_SWIFT_PRIVATE = @"img_logo_splash";

/// The "img_logout" asset catalog image resource.
static NSString * const ACImageNameImgLogout AC_SWIFT_PRIVATE = @"img_logout";

/// The "img_map_pin" asset catalog image resource.
static NSString * const ACImageNameImgMapPin AC_SWIFT_PRIVATE = @"img_map_pin";

/// The "img_no_service_pin" asset catalog image resource.
static NSString * const ACImageNameImgNoServicePin AC_SWIFT_PRIVATE = @"img_no_service_pin";

/// The "img_notification" asset catalog image resource.
static NSString * const ACImageNameImgNotification AC_SWIFT_PRIVATE = @"img_notification";

/// The "img_notification_mute" asset catalog image resource.
static NSString * const ACImageNameImgNotificationMute AC_SWIFT_PRIVATE = @"img_notification_mute";

/// The "img_order_history" asset catalog image resource.
static NSString * const ACImageNameImgOrderHistory AC_SWIFT_PRIVATE = @"img_order_history";

/// The "img_order_search" asset catalog image resource.
static NSString * const ACImageNameImgOrderSearch AC_SWIFT_PRIVATE = @"img_order_search";

/// The "img_photo_upload" asset catalog image resource.
static NSString * const ACImageNameImgPhotoUpload AC_SWIFT_PRIVATE = @"img_photo_upload";

/// The "img_safety" asset catalog image resource.
static NSString * const ACImageNameImgSafety AC_SWIFT_PRIVATE = @"img_safety";

/// The "img_sensitive_background" asset catalog image resource.
static NSString * const ACImageNameImgSensitiveBackground AC_SWIFT_PRIVATE = @"img_sensitive_background";

/// The "img_service_delivery" asset catalog image resource.
static NSString * const ACImageNameImgServiceDelivery AC_SWIFT_PRIVATE = @"img_service_delivery";

/// The "img_service_delivery_small" asset catalog image resource.
static NSString * const ACImageNameImgServiceDeliverySmall AC_SWIFT_PRIVATE = @"img_service_delivery_small";

/// The "img_service_intercity" asset catalog image resource.
static NSString * const ACImageNameImgServiceIntercity AC_SWIFT_PRIVATE = @"img_service_intercity";

/// The "img_service_intercity_small" asset catalog image resource.
static NSString * const ACImageNameImgServiceIntercitySmall AC_SWIFT_PRIVATE = @"img_service_intercity_small";

/// The "img_service_mail" asset catalog image resource.
static NSString * const ACImageNameImgServiceMail AC_SWIFT_PRIVATE = @"img_service_mail";

/// The "img_service_mail_small" asset catalog image resource.
static NSString * const ACImageNameImgServiceMailSmall AC_SWIFT_PRIVATE = @"img_service_mail_small";

/// The "img_service_taxi" asset catalog image resource.
static NSString * const ACImageNameImgServiceTaxi AC_SWIFT_PRIVATE = @"img_service_taxi";

/// The "img_service_taxi_small" asset catalog image resource.
static NSString * const ACImageNameImgServiceTaxiSmall AC_SWIFT_PRIVATE = @"img_service_taxi_small";

/// The "img_shield_check" asset catalog image resource.
static NSString * const ACImageNameImgShieldCheck AC_SWIFT_PRIVATE = @"img_shield_check";

/// The "img_spinner" asset catalog image resource.
static NSString * const ACImageNameImgSpinner AC_SWIFT_PRIVATE = @"img_spinner";

/// The "img_tariff_card" asset catalog image resource.
static NSString * const ACImageNameImgTariffCard AC_SWIFT_PRIVATE = @"img_tariff_card";

/// The "img_toggle" asset catalog image resource.
static NSString * const ACImageNameImgToggle AC_SWIFT_PRIVATE = @"img_toggle";

/// The "img_trash_can" asset catalog image resource.
static NSString * const ACImageNameImgTrashCan AC_SWIFT_PRIVATE = @"img_trash_can";

/// The "img_upload_photo" asset catalog image resource.
static NSString * const ACImageNameImgUploadPhoto AC_SWIFT_PRIVATE = @"img_upload_photo";

/// The "img_wifi" asset catalog image resource.
static NSString * const ACImageNameImgWifi AC_SWIFT_PRIVATE = @"img_wifi";

#undef AC_SWIFT_PRIVATE
