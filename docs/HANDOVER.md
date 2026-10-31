# SAIMPEX V2 Customer App — Developer Handover

> **Read first:** the complete V2 scope, [`praveensigo/saimpex-backend-new` → `docs/V2_COMPLETE_SCOPE.md`](https://github.com/praveensigo/saimpex-backend-new/blob/integration/v2/docs/V2_COMPLETE_SCOPE.md). Then this handover, then the API change log.
> **Owner:** **Sharvin**. Week-by-week task list to the 1 Dec launch: [`docs/TEAM_ASSIGNMENTS.md`](https://github.com/praveensigo/saimpex-backend-new/blob/integration/v2/docs/TEAM_ASSIGNMENTS.md).

Last updated: 31 October 2026. Branch at time of writing: `fix/customer-critical-flows` (26 commits ahead of `main`, all pushed to `origin`).

This document lets a developer on a new computer clone the Customer app and keep building without asking questions. It was written by reading the code on this branch, the backend repo (`integration/v2`) and the scope texts. Where something could not be confirmed from code, it says **unverified**.

---


## Team communication (read first)

Five computers build SAIMPEX V2 in parallel: backend API (Praveen's Mac), customer app, vendor app, delivery + kitchen apps, admin panel. They stay in sync through two shared files in the backend repo:

| What | Where | When to read it |
|---|---|---|
| **Complete final scope — read first** | [`docs/V2_COMPLETE_SCOPE.md`](https://github.com/praveensigo/saimpex-backend-new/blob/integration/v2/docs/V2_COMPLETE_SCOPE.md) | Before you start building anything; it describes every app and rule |
| **API change log** — every API change, which apps must act, where it's documented | [`praveensigo/saimpex-backend-new` → `docs/API_CHANGELOG.md`](https://github.com/praveensigo/saimpex-backend-new/blob/integration/v2/docs/API_CHANGELOG.md) (branch `integration/v2`) | Every day before you start; look for `[customer]` |
| **Client decisions + build plan** | [`docs/V2_DECISIONS_AND_PLAN.md`](https://github.com/praveensigo/saimpex-backend-new/blob/integration/v2/docs/V2_DECISIONS_AND_PLAN.md) | Before building any feature; it overrides the scope PDF |
| **API contracts** | [`docs/SAIMPEX_V2_CUSTOMER_API.md`](https://github.com/praveensigo/saimpex-backend-new/blob/integration/v2/docs/SAIMPEX_V2_CUSTOMER_API.md) | When wiring an endpoint |

This file's **"Backend updates since this handover"** table (at the end) repeats the entries that concern this app.

**Need something from the backend?** Open a GitHub issue in `praveensigo/saimpex-backend-new` titled `[customer-app] <short description>`: the screen, the endpoint, what you sent, what you got, what you need. Don't build against a guessed contract. Product questions go to Praveen; answers are recorded in the decisions doc.

**Changing something other teams depend on** (e.g. a push payload this app sends or expects, a shared asset)? Add a line to the change log via the backend owner, or mention it in an issue, so every team sees it.

## Contents

1. [Purpose and overview](#1-purpose-and-overview)
2. [Setup on a new machine](#2-setup-on-a-new-machine)
3. [Architecture](#3-architecture)
4. [Feature status](#4-feature-status)
5. [API map](#5-api-map)
6. [Pending work (prioritised)](#6-pending-work-prioritised)
7. [Conventions](#7-conventions)
8. [Known issues and risks](#8-known-issues-and-risks)

---

## 1. Purpose and overview

SAIMPEX is a multi-vendor delivery and services marketplace in Mauritania (currency MRU). This repo is the **Customer app**, written in Flutter. Customers browse and order from restaurants (Food), grocery stores, pharmacies, water suppliers and local shops; send parcels by courier; and book services (car wash, home cleaning, laundry). They pay by cash, online (Masrvi) or SAIMPEX Wallet, track orders live, chat with vendors, and collect store-specific loyalty points, tiers, missions and referral rewards. All data comes from the Laravel backend under `/api/customer/*`.

### Binding sources

| Source | Where | Rule |
|---|---|---|
| **Client decisions and API phase plan** | `praveensigo/saimpex-backend-new/docs/V2_DECISIONS_AND_PLAN.md` (branch `integration/v2`) | **Wins over** the scope PDF, the FRD and V1 behaviour. Read it first. |
| **Figma (design source)** | https://www.figma.com/design/gcPrdiT2s5VbO51zOdwT36/Saimpex-V2-Customer-App-UI — page **"Saimpex V2 Customer App UI"** | **Do not edit Figma.** Build screens as designed. If a required feature has no Figma screen, build it in the same visual style and list it as "built without a Figma screen" in your handover notes. |
| Customer API reference | `praveensigo/saimpex-backend-new/docs/SAIMPEX_V2_CUSTOMER_API.md` | Envelope, locked response keys, screen → API map. |
| Customer routes | `praveensigo/saimpex-backend-new/routes/customer.php` | The truth for which endpoints exist. |
| Team scope (background) | `V2_TEAM_SCOPE.txt`, `FUNCTIONAL_REQUIREMENTS.txt` (scope folder, not in this repo) | Background only; the decisions doc overrides them. |
| Previous handoff | [`docs/V2_HANDOFF.md`](V2_HANDOFF.md) | 30 Oct audit across all apps. Parts of its "Customer app — remaining" list are now done (see section 4). |

### What the decisions doc means for this app

- **Languages:** English, French, Arabic. Arabic must be right-to-left. API messages come as `message_en`, `message_fr`, `message_ar`.
- **Payment types:** `1` cash (COD), `2` online (Masrvi), `3` SAIMPEX Wallet. Wallet is a payment method in **every** checkout and works at any store.
- **Wallet top-up:** 100 – 50,000 MRU per top-up, paid through Masrvi.
- **Split payment:** if the wallet does not cover the order, the rest is paid by Masrvi.
- **Loyalty points are store-specific** (earned and spent at the same vendor). Food orders earn points too. Points are credited only after delivery and confirmed payment; the success screen may show a preview only.
- **Tiers:** Bronze 0 / Silver 500 / Gold 1500 / Platinum 3000 points. Gold and above get free delivery. Admin-managed.
- **Referral:** referrer and referee each get 100 MRU wallet credit after the referee's first delivered order (admin-editable).
- **Pay After Delivery (PAD):** trusted customers only (admin-marked, or 5 paid orders, or Gold+). Order placed with payment pending; customer pays online later; max 1 unpaid PAD order; pay within 24 h.
- **Prescription orders:** online or wallet only. No cash.
- **Self-pickup:** prepaid only, no COD (backend rule `732936e Enforce payment and cancellation rules`).
- **Delivery fee:** set per vendor (free / fixed / % / per km) with who pays (customer / vendor / split); the checkout shows what the server returns. Gold+ = free delivery. *(Updated 31 Oct: client's SPX-ADM-02 is final.)*
- **Masked customer ↔ driver calls ARE required** (client's SPX-ADM-02 item 15, final). Keep the call-driver button and wire it to the masked-call API when it lands (backend Phase 3).
- **Pre-orders:** up to 7 days ahead (admin can change).
- **Grocery substitution:** vendor proposes a replacement; auto-accepted after 10 minutes without a customer answer.
- **Car wash location:** home, workplace, other, or at the station.
- **Laundry:** per Figma. Customers do not upload PDFs (the PDF note meant the client may send the design as a PDF).
- **Search:** text and voice across all categories (stores + products, nearest first, only stores that deliver to the customer).
- **Image search uses Google Vision** on the backend (key managed in Admin).
- **AI chatbot (this phase):** uses Claude, on the backend. Answers about SAIMPEX, vendors, and **the asking customer's own data only**.
- **API-first:** APIs are built on the backend owner's Mac first. **Do not build against a guessed contract.** If an endpoint is not documented, ask the backend owner (section 7).

---

## 2. Setup on a new machine

### 2.1 Tooling

| Tool | Version | Notes |
|---|---|---|
| Flutter | **3.44 stable** (team baseline). Also works on **3.47** (3.47.9 is installed on the backend owner's Mac and `flutter analyze` runs clean of errors there). | `pubspec.yaml` requires Dart SDK `^3.12.2`. |
| Dart | 3.12+ | Comes with Flutter. |
| Android Studio + Android SDK | SDK 36 installed | `compileSdk = 36`, `targetSdk = 34` in `android/app/build.gradle.kts`. |
| JDK | 17 (recommended for current Android Gradle Plugin) | unverified exact requirement; use the JDK bundled with Android Studio. |
| Xcode + CocoaPods | Only for iOS | iOS minimum is **15.5** (Google ML Kit needs it). iOS is outside the Android scope PDF unless separately approved. |

### 2.2 Clone and run

```bash
git clone https://github.com/sigosoft/Saimpex-V2.git
cd Saimpex-V2
git checkout fix/customer-critical-flows   # current work; main is 26 commits behind
flutter pub get
flutter analyze                             # expect 0 errors, ~13 warnings, ~520 infos
flutter run                                 # pick an Android device/emulator
```

iOS:

```bash
cd ios && pod install && cd ..
flutter run -d <ios-simulator-or-device>
```

### 2.3 API base URL / environment

There are **no flavors and no `--dart-define`**. The server is a constant in one file:

`lib/core/network/api_constants.dart`

```dart
static const String baseUrl = 'https://dev.saimpexenterprise.com/api/';
static const String mediaBaseUrl = 'https://dev.saimpexenterprise.com/storage/';
```

| Server | URL | Use |
|---|---|---|
| V2 dev (current target) | `https://dev.saimpexenterprise.com/api/` | All development. |
| Live V1 | `https://api.saimpexenterprise.com/api/` | Does **not** have the V2 endpoints. Do not point the app here until V2 is deployed. |

To use a local backend, change `baseUrl` and `mediaBaseUrl` locally and **do not commit** that change. Android emulator reaches the host Mac at `http://10.0.2.2:8000/api/`; a cleartext (`http://`) URL needs a network security config on Android and an ATS exception on iOS (not set up in this repo).

Other values derived from `baseUrl`:
- Masrvi payment page: `'<origin>/pay/masrvi/payment/session?order_id=…'` (`_apiOrigin` in `lib/views/cart_screen.dart`).
- Image URLs: `ApiConstants.mediaUrl(path)` prefixes relative paths with `mediaBaseUrl`.

**Which backend code runs on dev is unverified.** Wallet payment (type 3), addresses, favourites, loyalty and courier tracking need the backend branch `integration/v2`. If dev still runs older code, those calls fail with 404/422. Ask the backend owner what is deployed before you debug the app.

### 2.4 Login for testing

Login is phone + WhatsApp OTP (`customer/sendOtp`, `customer/verifyOtp`). The backend now generates a random 6-digit OTP with a 10-minute expiry. Numbers listed in the backend `OTP_TEST_NUMBERS` setting keep the fixed test code. Ask the backend owner for a test number; never put real OTPs or tokens in commits or chat. There is also a "Continue as Guest" button (`LoginController.loginAsGuest()` in `lib/controllers/login_controller.dart`).

### 2.5 Signing and identifiers

| Item | Current value | Required before store release |
|---|---|---|
| Android `applicationId` / `namespace` | `com.example.saimpex_v2` (`android/app/build.gradle.kts`) | Use **V1's** applicationId so V2 ships as an update. |
| Android release signing | Signs with the **debug** key (`signingConfig = signingConfigs.getByName("debug")`) | Add V1's upload keystore via an untracked `key.properties`. Never commit the keystore or passwords. |
| Android app label | `saimpex_v2` (`android/app/src/main/AndroidManifest.xml`) | Real app name. |
| iOS bundle ID | `com.example.saimpexV2` (`ios/Runner.xcodeproj/project.pbxproj`) | V1's bundle ID. |
| Version | `1.0.0+1` (`pubspec.yaml`) | Must be higher than V1's live version. |
| Google Maps key | Hard-coded in `android/app/src/main/AndroidManifest.xml` (`com.google.android.geo.API_KEY`) and `ios/Runner/AppDelegate.swift` (`GMSServices.provideAPIKey`) | See risk R-6. Restrict the key to the app IDs in Google Cloud. |

### 2.6 Tests

```bash
flutter analyze
flutter test
```

`test/widget_test.dart` is the **unchanged Flutter template counter test**. It looks for a counter that does not exist and will fail; it also needs `AppDependencies.init()` before `MyApp`. There are no real tests. Until real tests exist, the release check is `flutter analyze` (0 errors) plus a manual run of the flows in section 6.

---

## 3. Architecture

### 3.1 Folder structure

```
lib/
  main.dart                    App entry: AppDependencies.init(), GetMaterialApp, theme, start screen
  core/
    app_dependencies.dart      Registers SessionStore, DioClient and all repositories with Get.put
    network/
      api_constants.dart       Base URL, media URL, every endpoint path
      dio_client.dart          Dio instance, Bearer token interceptor, debug logging
      api_message.dart         ApiEnvelope (unwraps `data`), asJsonMap, resolveApiMessage
      api_exception.dart       ApiException.fromDio (localised message + status code)
    storage/
      session_store.dart       Token + user in SharedPreferences
  models/                      Repositories (one per domain) + small models
  controllers/                 GetX controllers (home, login, otp, onboarding, location, profile)
  navigation/
    bottom_nav_router.dart     Return to the shell and select a bottom-nav tab
  utils/                       api_language.dart, wallet_balance.dart, toast_helper.dart
  constants/                   colors.dart, text_styles.dart, country_codes.dart
  views/                       Screens, grouped by vertical (courier/, express/, grocery/,
                               local_store/, pharmacy/, services/, water/) + shared views/widgets/
  widgets/                     App-wide widgets (bottom nav, back button, no-internet guard, ...)
  assets/images/               Image assets (declared in pubspec.yaml)
```

Note: "models" holds **repositories** (API classes), not plain data classes. Most screens work with `Map<String, dynamic>` rows produced by repository mappers.

### 3.2 State management (GetX)

- Package `get: ^4.6.6`. The app uses `GetMaterialApp`, `Get.put` / `Get.find`, `.obs` and `Obx`.
- Repositories and the session are registered once as permanent singletons in `lib/core/app_dependencies.dart`. Look them up with `Get.find<XRepository>()`.
- `ChatRepository` is **not** registered there; `lib/views/messages_screen.dart` and `lib/views/chat_screen.dart` `Get.put` it on first use.
- `GroceryRepository` is registered twice: default (grocery) and tagged `GroceryRepository.localStoreTag` (local store mode, same API shape under `customer/localStore/*`).
- Main controllers:
  - `lib/controllers/home_controller.dart` — bottom-nav index (`navHome`…`navProfile`), home hub data (`customer/homeHub`), wallet balance, favourites, `resetForLogout()`.
  - `lib/controllers/select_location_controller.dart` — current delivery location (static fields, persisted in SharedPreferences), Google Maps picking, `updateLocation`.
  - `lib/controllers/onboarding_controller.dart` — splash slides and the **selected language** (`selectedLanguage`).
  - `lib/controllers/login_controller.dart`, `otp_controller.dart`, `edit_profile_controller.dart`.
  - `lib/controllers/service_booking_draft.dart` — provider + service picked on a service detail screen, read by the service carts.
- Many screens are `StatefulWidget`s that call repositories directly in `initState` and keep state locally. Follow the existing pattern in the file you edit.

### 3.3 Networking

- `DioClient` (`lib/core/network/dio_client.dart`): base URL from `ApiConstants`, 30 s timeouts, `Accept: application/json`, adds `Authorization: Bearer <token>` to every request except `sendOtp`/`verifyOtp`. Debug builds log full requests and responses (including the token — see risk R-7).
- **Envelope.** The backend returns `{ "status": true|false, "data": {...}, "message": { "message_en": [...], "message_fr": [...], "message_ar": [...] } }`. Repositories wrap each call in a private `_send(...)` helper that calls `ApiEnvelope.parse(body, language)`:
  - `status != true` → throws `FormatException(message)` with the message in the current language;
  - otherwise returns `ApiEnvelope(data: map['data'], message: …)`.
  - Dio errors are turned into `ApiException.fromDio(error, language)`, which keeps the HTTP `statusCode`.
- Exception: `GET restaurant/getMenuItemVariants` (and grocery's) returns a non-standard shape. Prefer `restaurant/item/detail`.
- Screens catch `ApiException` and show `showAppToast(error.message, ...)` (`lib/utils/toast_helper.dart`).
- Pass the language with `apiLanguageCode()` (`lib/utils/api_language.dart`) → `en` / `fr` / `ar`.
- New endpoint checklist: add the path to `ApiConstants`, add a method to the right repository using `_send` + `ApiEnvelope`, map the response to the shape the screen already uses, catch `ApiException` in the screen.

### 3.4 Routing

- No named routes. Navigation is imperative: `Get.to(() => Screen())`, `Get.off`, `Get.offAll`, `Get.back(result: ...)`.
- Start screen (`lib/main.dart`): `MainShellScreen` if a token is stored, else `OnboardingScreen`. After start, `customerCheck` validates the token in the background and clears the session on 401/403.
- `lib/views/main_shell_screen.dart` hosts the bottom-nav tabs (indices in `HomeController`: 0 Home, 1 Chat, 2 Bookings, 3 Services, 4 Orders, 5 Cart, 6 Profile).
- From deep screens, use `BottomNavRouter.go(index)` or `BottomNavRouter.returnToShell(tabIndex:, ordersCategoryIndex:)` (`lib/navigation/bottom_nav_router.dart`) instead of pushing a new shell.
- `NoInternetGuard` (`lib/widgets/no_internet_guard.dart`) wraps the whole app via `GetMaterialApp.builder`.

### 3.5 Localisation (EN / FR / AR + RTL)

**Current state: foundation in place; most existing screens still have English strings.**

- `lib/l10n/app_locale.dart` (`AppLocale`) holds the language (`en`/`fr`/`ar`), saves it in SharedPreferences (survives restart) and switches it with `Get.updateLocale`.
- `lib/l10n/app_translations.dart` (`AppTranslations`, GetX `Translations`) has the EN/FR/AR strings. Use `'key'.tr` / `'key'.trParams({...})`; **add every new string there in all three languages.**
- `GetMaterialApp` sets `translations`, `locale`, `fallbackLocale: en`, `supportedLocales` and the Flutter localisation delegates, so Arabic lays the app out right to left. Screens built with `EdgeInsets.fromLTRB` / `Alignment.centerLeft` don't flip yet: use `EdgeInsetsDirectional` / `AlignmentDirectional` when converting a screen.
- The language picker (`lib/views/widgets/language_selector.dart`) calls `customer/updateLanguage` (when logged in) and `AppLocale.change`. `apiLanguageCode()` returns `AppLocale.code`.
- Screen strings live in `lib/l10n/areas/` (`core`, `orders`, `pharmacy_water`, `services`, `stores`; key prefixes `core_`, `orders_`, `pw_`, `svc_`, `st_`), merged by `AppTranslations`. About 1,400 keys per language.
- `test/translations_test.dart` fails if FR/AR miss a key, drop an `@placeholder`, or the code uses an undefined key. Run `flutter test` after adding strings.
- Labels that code compares or sends to the API (e.g. account menu `label`, service card titles, home-cleaning room names, delivery slots, cancel reasons) stay English internally and are translated only when drawn.
- **Not translated on purpose:** server data, and sample/mock data still in some screens (to be replaced by real data, not translated).
- **Still to do:** review by a native Arabic/French speaker (client QA, 16–25 Nov); finish RTL on screens with custom painters, gradients and maps (only mechanical directional swaps were made).

See pending item P1-1.

### 3.6 Theming

- Light theme only (`themeMode: ThemeMode.light` in `lib/main.dart`). Primary orange `#FF5E00`, background `#FAF6F0`, Material 3.
- Colours: `lib/constants/colors.dart` (`AppColors.primaryOrange`, `gradientYellow #FFAE00`, …). Many widgets also use inline `Color(0x…)` values copied from Figma.
- Typography: `lib/constants/text_styles.dart` (`AppTextStyles.heading/title/subtitle`) using Google Fonts **Outfit** (`google_fonts`, downloaded at runtime).
- Orange→yellow gradient buttons are the standard primary action.

### 3.7 Key shared code

| File | What it gives you |
|---|---|
| `lib/utils/wallet_balance.dart` | `paymentTypeCash = '1'`, `paymentTypeOnline = '2'`, `paymentTypeWallet = '3'`; `walletBalanceSubtitle()` → "Balance: 1,250 MRU" from `HomeController`. **Use these constants in every checkout.** |
| `lib/utils/api_language.dart` | `apiLanguageCode()` / `currentApiLanguage()`. |
| `lib/utils/toast_helper.dart` | `showAppToast(message, backgroundColor:)`. |
| `lib/models/order_tracking.dart` | `OrderTracking` parser, `loadOrderDetail(orderId)`, `OrderTrackingMixin` (polls `customer/trackOrder`). |
| `lib/views/widgets/tracking_widgets.dart` | Shared tracking panel (map, driver card, timeline). |
| `lib/views/services/service_booking_submit.dart` | `placeServiceBooking()` (quote check + `service/book`), `serviceSlotWindow()`, `formatServiceSlotLabel()`. |
| `lib/views/services/provider_services_mixin.dart`, `service_provider_list.dart` | Load providers/services for car wash, home cleaning, laundry. |
| `lib/views/express/express_stores.dart` | Loads Express vendors (`expressHome`) and opens each vertical's store screen. |
| `lib/views/widgets/search_camera_button.dart` | `SearchCameraButton`, `labelScannedImage()` (on-device ML Kit labels). |
| `lib/views/widgets/home_search_box.dart` | Home search field with voice (speech_to_text) and camera. |
| `lib/views/payment_webview_screen.dart` | Masrvi WebView; returns `true` on `/payment/success`, `false` on `/payment/failed`. |
| `lib/widgets/app_bottom_nav_bar.dart`, `app_back_button.dart`, `cancel_order_bottom_sheet.dart`, `cancel_booking_bottom_sheet.dart`, `replace_cart_item_dialog.dart` | Reusable UI pieces. |

---

## 4. Feature status

Legend: **Done** = wired to a real API end to end in code (not device-tested unless stated). **Partial** = some parts real, some sample/missing. **Not started** = UI only or absent. Nothing has been confirmed on a device by the author of this document.

| Feature | Status | What works / what is missing | Main files |
|---|---|---|---|
| Onboarding, splash, login (OTP), guest | Done | Splash slides from `customer/splash`; OTP login; token stored; background `customerCheck`. | `lib/views/onboarding_screen.dart`, `lib/views/login_screen.dart`, `lib/views/otp_screen.dart`, `lib/controllers/login_controller.dart`, `lib/controllers/otp_controller.dart`, `lib/models/auth_repository.dart` |
| Home (All) | Partial | Hub data from `customer/homeHub` (banners, stores, wallet). **Home search box does nothing on submit** (no `onSubmitted`). "Under 30 minutes" screen is hard-coded sample data. | `lib/views/home_screen.dart`, `lib/controllers/home_controller.dart`, `lib/views/widgets/home_search_box.dart`, `lib/views/under_30_min_screen.dart` |
| Food (restaurants) | Done | Home (`restaurantHomeV2`, `foodVendorCategories`), search, store page, item detail/portions, catalog cart, checkout, orders, cancel, rate. Store Map is a painted sample. | `lib/views/category_screen.dart`, `lib/views/restaurant_details_screen.dart`, `lib/views/restaurant_search_screen.dart`, `lib/views/widgets/restaurant_food_customize_sheet.dart`, `lib/models/food_repository.dart`, `lib/views/store_map_screen.dart` |
| Grocery | Done (substitution not started) | Home, stores, store detail, items, cart, checkout V2 with fallback, orders. **Substitution** screen `order_updated_detail_screen.dart` is static UI and is not opened from anywhere. | `lib/views/grocery/grocery_screen.dart`, `lib/views/grocery/grocery_stores_screen.dart`, `lib/views/grocery/grocery_details_screen.dart`, `lib/models/grocery_repository.dart`, `lib/views/order_updated_detail_screen.dart` |
| Local Store | Partial | Home and store/items via `GroceryRepository.localStore`; ordering through the grocery store screen. **My Orders → Local Store tab shows "No orders"** (not loaded). | `lib/views/local_store/local_store_screen.dart`, `lib/views/my_orders_screen.dart` |
| Express | Partial | Vendors from `customer/expressHome`; open each vertical's store. Express Store Map is a sample. | `lib/views/express/express_screen.dart`, `lib/views/express/express_stores.dart`, `lib/views/express/express_store_map_screen.dart` |
| Pharmacy | Done (per-item quote pending) | Home, categories, stores, items, search, cart, prescription upload, attach to cart, quotation accept/pay, orders, tracking. Per-item available/partial/substitute quote is Phase 1 backend. `prescription/{id}/decline` exists but is not used. | `lib/views/pharmacy/` (e.g. `pharmacy_screen.dart`, `upload_prescription_screen.dart`, `quotation_detail_screen.dart`, `prescription_checkout_screen.dart`), `lib/models/pharmacy_repository.dart` |
| Water (one-off orders) | Done | Home, suppliers, products, add to cart (`cart/water/add`), checkout via main cart, orders, order details, live tracking. Supplier screens block "sample" items without a server id. | `lib/views/water/water_screen.dart`, `water_supplier_screen.dart`, `water_supplier_details_screen.dart`, `water_order_details_screen.dart`, `water_track_order_screen.dart`, `lib/models/water_repository.dart` |
| Water subscriptions | Partial | My Subscriptions list + pause/resume/cancel are real. **Buying a subscription is fake**: `WaterSubscriptionScreen → WaterNearbySuppliersScreen` (hard-coded suppliers) → `WaterSubscriptionCartScreen` "Pay" goes straight to the success screen without calling `water/subscribe`. `water/plans` is in the repo but unused. | `lib/views/my_subscriptions_screen.dart`, `lib/views/water/water_subscription_screen.dart`, `water_nearby_suppliers_screen.dart`, `water_product_subscription_screen.dart`, `water_subscription_cart_screen.dart` |
| Gas | Not started | No gas screens or code. | — |
| Courier | Partial | Quote, create, orders list, order detail, live tracking are real. **Pickup point is hard-coded** (`_pickupAddress = 'Marhaba Supermarket, Nouakchott'`). Review screen adds fake numbers (`redeemedPointsDiscount = 1`, `tax = 2`) to the shown total. Online payment does not open Masrvi. | `lib/views/courier/courier_screen.dart`, `courier_review_booking_screen.dart`, `courier_order_detail_screen.dart`, `courier_track_order_screen.dart`, `lib/models/courier_repository.dart` |
| Car wash | Partial | Providers, services, vehicles (all selected vehicles booked), slots, server quote check, `service/book`, My Bookings, cancel. Location screen offers only **"At Wash Station" / "At Home/Workplace"** (decision: home, workplace, other, station). Online payment has no Masrvi step. | `lib/views/services/car_wash_*.dart`, `lib/views/services/service_booking_submit.dart`, `lib/models/service_repository.dart` |
| Home cleaning | Done (payment step pending) | Providers, services, configure, property type + notes, slot, quote, book, cancel. Online payment has no Masrvi step. | `lib/views/services/home_cleaning_*.dart` |
| Laundry | Partial | Providers, services, pickup slot, book, cancel. Dry-cleaning garment list is **hard-coded** (`laundry_dry_cleaning_screen.dart`). | `lib/views/services/laundry_*.dart` |
| Other services (plumbing, carpentry, electrical) | Not started | Tiles on the Services screen do nothing. Scope puts them in later updates. | `lib/views/services/services_screen.dart` |
| Cart and checkout | Partial | Catalog cart (food) and classic cart (grocery/pharmacy/water/local store); coupons on classic cart; points redeem; Wallet/Online/COD; Masrvi WebView with retry of the same order. Pay After Delivery (type 4) only when the server allows it; Wallet is the default. "Schedule for later" UI is not sent to the API. Coupons are not sent for catalog (food) checkout. | `lib/views/cart_screen.dart`, `lib/models/cart_repository.dart`, `lib/models/order_repository.dart`, `lib/views/payment_webview_screen.dart` |
| Wallet | Partial | Balance shown (home, account, every checkout); pay with wallet (type 3). **No top-up, no split payment, no transaction history.** | `lib/utils/wallet_balance.dart`, `lib/controllers/home_controller.dart`, `lib/views/account_screen.dart` |
| Rewards / loyalty | Done (copy cleanup) | Tier, missions (claim), referral (apply), store points, reward baskets, redeem, history, success-screen points preview. Redeem sheet falls back to "Lorem Ipsum" text when the reward has no description. | `lib/views/rewards_referral_screen.dart`, `lib/views/redeem_detail_sheet.dart`, `lib/views/order_success_screen.dart`, `lib/models/profile_repository.dart` |
| Saved addresses | Done | List / save / delete (`customer/addresses*`). | `lib/views/saved_addresses_screen.dart`, `lib/views/select_location_screen.dart` |
| Favourites | Done | Heart any card; saved with `favourites/toggle`; list from `favourites`; cleared on logout. | `lib/views/my_favourites_screen.dart`, `lib/controllers/home_controller.dart` |
| Search (text) | Partial | Per-vertical search works (restaurants, grocery, pharmacy, water, local store, in-store item search). **No global search** across categories; home search box is not wired. | `lib/views/restaurant_search_screen.dart`, `lib/views/pharmacy/pharmacy_search_screen.dart`, `lib/views/widgets/home_search_box.dart` |
| Voice search | Partial | Speech-to-text fills the home search box, which then does nothing. | `lib/views/widgets/home_search_box.dart` |
| Image search | Partial | Camera → **on-device** Google ML Kit label → text in the search field. Decision requires **Google Vision on the backend** and a store/price/distance result list. | `lib/views/home_scanner_screen.dart`, `lib/views/widgets/search_camera_button.dart` |
| Orders and tracking | Partial | My Orders tabs Food, Grocery, Pharmacy, Water, Courier are real; Local Store tab empty. Order detail, cancel, rate, live tracking (15 s polling) for general, water, pharmacy, courier. Rate screen shows hard-coded sample item cards but submits the real rating. | `lib/views/my_orders_screen.dart`, `lib/views/order_detail_screen.dart`, `lib/views/track_order_screen.dart`, `lib/views/rate_order_screen.dart`, `lib/models/order_tracking.dart` |
| My Bookings (services) | Done | `service/bookings`, detail, cancel, rate. | `lib/views/my_bookings_screen.dart` |
| My Schedules (pre-orders) | Not started | Hard-coded list. No backend yet. | `lib/views/my_schedules_screen.dart` |
| Chat with vendor | Done (unverified on device) | Conversations list, conversation, send text/image/voice note. `markAsRead` and `deleteConversation` are not used. | `lib/views/messages_screen.dart`, `lib/views/chat_screen.dart`, `lib/models/chat_repository.dart` |
| AI chatbot | Done (C15, unverified on device) | Floating head + chat UI wired to `chatbot/message` (API §6.19): keeps `conversation_id`, sends the delivery location, history sheet (`chatbot/conversations`), voice input (speech_to_text in the chat language), reads replies aloud only when the customer spoke and Admin turned `voice_output` on (flutter_tts). Server errors (not configured / daily limit / temporary failure) show as a red bubble. | `lib/views/chatbot_ai_chat_screen.dart`, `lib/views/widgets/chatbot_head.dart`, `lib/views/widgets/chatbot_welcome_sheet.dart` |
| Notifications | Partial | In-app list (`customer/notifications`) and preferences. **No push notifications** (no Firebase/FCM package). | `lib/views/notifications_screen.dart`, `lib/views/app_preferences_screen.dart` |
| Profile / account | Done | Profile, edit profile, language, help/support, terms, privacy, about, delete account, logout (resets home data). | `lib/views/account_screen.dart`, `lib/views/edit_profile_screen.dart`, `lib/views/help_support_screen.dart`, `lib/views/terms_conditions_screen.dart` |
| Coupons screen | Done (unverified) | Lists `customer/coupons`. | `lib/views/coupons_screen.dart` |
| Reviews | Done (unverified) | `customer/reviews`. | `lib/views/rating_reviews_screen.dart` |
| Localisation EN/FR/AR + RTL | Not started (UI) | Only API language is passed. See 3.5. | `lib/views/widgets/language_selector.dart`, `lib/utils/api_language.dart` |
| Driver call button | Keep; wire to masked call | Shows "Calling your driver from the app is coming soon". Masked calls are required (SPX-ADM-02 item 15); API pending (Phase 3). | `lib/views/widgets/tracking_widgets.dart`, `lib/views/courier/courier_order_detail_screen.dart`, `lib/views/water/water_order_details_screen.dart` |

---

## 5. API map

All paths are under `/api/customer/` (constants in `lib/core/network/api_constants.dart`). Auth = Sanctum Bearer token.

### 5.1 Used today

| Screen / feature | Endpoints | Repository |
|---|---|---|
| Splash / onboarding | `GET splash` | `GeneralRepository.fetchSplash` |
| Login | `POST sendOtp`, `POST verifyOtp`, `GET customerCheck`, `POST logout` | `AuthRepository` |
| Home (All) | `POST homeHub` | `GeneralRepository.fetchHome` |
| Location | `POST updateLocation`, `GET fetchLocation`, `POST checkDeliveryAvailability` | `ProfileRepository`, `OrderRepository.checkDelivery` |
| Saved addresses | `GET addresses`, `POST addresses/save`, `POST addresses/delete` | `ProfileRepository` |
| Favourites | `GET favourites`, `POST favourites/toggle` | `ProfileRepository` |
| Food home / search | `POST restaurantHomeV2`, `POST foodVendorCategories`, `POST restaurantSearchV2`, `GET getRestaurantTags`, `GET getRestaurantMenuTags` | `FoodRepository` |
| Restaurant page | `GET restaurant/details`, `GET restaurant/categories`, `POST restaurant/items`, `POST restaurant/items/search`, `POST restaurant/items/barcode/search`, `GET restaurant/item/detail`, `GET restaurant/getMenuItemVariants` | `FoodRepository` |
| Grocery | `POST groceryHomeV2`, `POST groceryHomeCategories`, `POST groceryVendorCategories`, `POST grocerySearchV2`, `POST groceryBarcodeSearch`, `GET grocery/details`, `GET grocery/categories`, `GET grocery/subCategories`, `POST grocery/items`, `POST grocery/items/search`, `POST grocery/items/barcode/search`, `GET grocery/item/detail`, `GET grocery/getMenuItemVariants`, `GET getGroceryTags`, `GET getGroceryMenuTags`, `POST cart/grocery/add`, `POST cart/grocery/remove` | `GroceryRepository` |
| Local store | `POST localStoreHome`, `GET localStore/details`, `GET localStore/categories`, `GET localStore/subCategories`, `POST localStore/items`, `POST localStore/items/search`, `POST localStore/items/barcode/search`, `GET localStore/item/detail`, `GET localStore/getMenuItemVariants`, `POST cart/localStore/add`, `POST cart/localStore/remove` | `GroceryRepository.localStore` |
| Express | `POST expressHome` | via `lib/views/express/express_stores.dart` |
| Pharmacy | `POST pharmacyHome`, `POST pharmacyHomeCategories`, `POST pharmacySearchV2`, `GET/POST pharmacy/store`, `GET pharmacy/details`, `GET pharmacy/categories`, `POST pharmacy/items`, `POST pharmacy/category/items`, `POST pharmacy/category/pharmacies`, `GET pharmacy/item/detail`, `GET/POST prescription/pharmacies`, `POST prescription/upload`, `GET prescriptions`, `GET prescription/{id}`, `POST prescription/{id}/accept`, `POST prescription/{id}/pay`, `POST cart/pharmacy/add`, `POST cart/pharmacy/attachPrescription` | `PharmacyRepository`, `CartRepository` |
| Water | `POST waterHome`, `POST waterSearchV2`, `GET water/categories`, `POST water/items`, `POST cart/water/add`, `GET water/subscriptions`, `POST water/subscription/pause`, `.../resume`, `.../cancel` | `WaterRepository` |
| Courier | `POST courier/quote`, `POST courier/create`, `GET courier/orders` | `CourierRepository` |
| Services | `GET serviceProviders`, `GET serviceProvider`, `GET serviceSlots`, `POST service/quote`, `POST service/book`, `GET service/bookings`, `GET service/booking`, `POST service/cancel` | `ServiceRepository` |
| Cart (classic) | `GET cart/list`, `GET cart/listAll`, `GET cart/replace`, `POST cart/update`, `POST cart/item/delete` | `CartRepository` |
| Cart (catalog, food) | `POST catalog/cart/add`, `GET catalog/cart/list`, `POST catalog/cart/update`, `POST catalog/cart/item/delete` | `CartRepository` |
| Checkout | `POST checkoutSummaryV2` → fallback `checkoutSummary`; `POST checkoutV2` → fallback `checkout` (on 404/405); `POST catalog/checkout`; `GET payments/masrvi/session`; `POST payments/masrvi/init`; WebView `GET /pay/masrvi/payment/session?order_id=` | `OrderRepository` |
| Coupons | `GET coupons`, `POST applyCoupon` | `OrderRepository` |
| Orders | `GET orders/restaurant`, `GET orders/grocery`, `GET orders/pharmacy`, `GET orders/water`, `GET catalog/orderDetail`, `GET orderDetails`, `POST cancelOrder`, `GET trackOrder` | `FoodRepository`, `GroceryRepository`, `PharmacyRepository`, `WaterRepository`, `OrderRepository` |
| Ratings / reviews | `GET rating`, `POST submitRating`, `GET reviews` | `OrderRepository`, `GeneralRepository` |
| Rewards / loyalty | `GET loyalty`, `POST referral/apply`, `POST missions/claim`, `GET userPoints`, `GET rewardList`, `POST redeemBasket`, `GET transactionHistory` | `ProfileRepository` |
| Notifications | `GET notifications`, `GET/POST notification/preference` | `ProfileRepository` |
| Chat | `GET chat/allConversations`, `POST chat/getConversation`, `POST chat/sendMessage` | `ChatRepository` |
| Profile | `GET profile`, `POST updateProfile`, `POST updateLanguage`, `GET delete` | `ProfileRepository` |
| Static pages | `GET getAbout`, `GET getPrivacyPolicy`, `GET getTermsandConditions`, `GET getContact` | `GeneralRepository` |

### 5.2 Exist on the backend but not used by the app yet

| Endpoint | Use it for |
|---|---|
| `POST water/subscribe`, `GET water/plans` | Buying a water subscription (Phase 1 may revise the contract — confirm first). |
| `GET orders/localStore` | My Orders → Local Store tab (constant `localStoreOrders` exists; the local-store repository maps grocery orders to it). |
| `GET orders/courier` | Alternative courier list (app uses `courier/orders`). |
| `POST prescription/{id}/decline` | Decline a pharmacy quotation. |
| `POST chat/markAsRead`, `GET chat/deleteConversation` | Unread badges, delete conversation. |
| `POST scan-image` / `POST image-recognition/analyze` | Server-side image recognition (see planned image search below). |
| `GET settings`, `GET verticals` | App settings / vertical list (unverified response shapes). |
| `GET localStore/bundles`, `POST localStore/map` | Local store bundles and map (could replace the sample Store Map). |

### 5.3 Planned — **contract pending from backend**

These come from Phase 0/1 of the plan in `V2_DECISIONS_AND_PLAN.md`. **Do not build against a guessed request/response.** Build UI behind the existing Figma screens, and wire it when the backend owner publishes the contract in `saimpex-backend-new/docs/SAIMPEX_V2_CUSTOMER_API.md`.

| Feature | Expected endpoint(s) | Status |
|---|---|---|
| **Unified search** (stores + products, nearest first, only stores that deliver) | `GET customer/search?q=&latitude=&longitude=` returning `stores[]` + `products[]` | **Ready** on backend `integration/v2` (738ecc6). Contract: `saimpex-backend-new/docs/SAIMPEX_V2_CUSTOMER_API.md` §6.7. Image search: send the photo to `POST customer/image-recognition/analyze` without `type` to get `stores[]` + `products[]` from Google Vision. |
| **Image search** via Google Vision | Backend endpoint taking an image and returning matching products/stores (likely an evolution of `scan-image`) | **Contract pending from backend.** |
| **Wallet top-up** (100 – 50,000 MRU via Masrvi) | `GET wallet`, `POST wallet/topup`, `GET wallet/topup/{id}` | **Ready** on backend `integration/v2` (62c3c64). Contract: backend `docs/SAIMPEX_V2_CUSTOMER_API.md` §6.8. |
| **Split payment** (wallet + Masrvi remainder) | `use_wallet=1` with `payment_type=2` on `checkoutV2` / `catalog/checkout`; response `wallet_amount`, `online_amount` | **Ready** (62c3c64), §6.8. |
| **Trusted customer / Pay After Delivery** | trusted flag on profile/checkout; PAD payment type or flag; pay-later endpoint for a pending order | **Contract pending from backend.** |
| **Masrvi for courier and services** | payment session for courier orders and service bookings | **Contract pending from backend.** |
| **Pre-orders** (up to 7 days) | scheduled time on checkout; list of scheduled orders | **Contract pending from backend.** |
| **Grocery substitution** | list proposals, accept/reject; auto-accept after 10 min | **Contract pending from backend.** |
| **Pharmacy per-item quote** | item lines with available / partial / unavailable / substitute + price | **Contract pending from backend.** |
| **Car wash location types** | `place` values home / workplace / other / station on `service/book` and `service/quote` | **Contract pending from backend.** |
| **Water subscriptions** (Phase 1 rework) | subscribe / plans / schedule | **Contract pending from backend.** |
| **Catalog cart coupons / totals** | coupon on `catalog/checkoutSummary` and `catalog/checkout` | **Contract pending from backend.** |
| **AI chatbot** (Claude, customer's own data only) | `chatbot/message`, `chatbot/conversations` | ✅ Wired (C15). |

---

## 6. Pending work (prioritised)

Each item has acceptance criteria (AC) that follow the client decisions. "Blocked" means it needs a backend contract first (section 5.3).

### P0 — wrong behaviour today (fix first, no backend needed)

**P0-1. Pay After Delivery must not post as cash.** ✅ Done (`fix/pay-after-delivery`, with P1-5).
`lib/views/cart_screen.dart` shows "Pay After Delivery", makes it the default for food/grocery (`selectedPaymentIndex = widget.isFoodOrGrocery ? 3 : 0`), and sends `paymentTypeCash`.
AC: PAD is hidden until the backend exposes the trusted flag (P1-4). Default selection is a real method (Wallet or Online). No order is ever placed as cash when the customer picked something else.

**P0-2. Prescription checkout must not offer cash.** ✅ Done (C2, `feature/prescription-payment-methods`): Wallet and Online only, and only the ones Admin has switched on (`GET customer/paymentMethods`, API §6.30; if the list can't load both stay and the server's translated 422 is shown). With both off the Pay button is disabled with a message. The delivery note is now sent (`notes`/`order_note`); the fake "tomorrow 10–11 AM" schedule card was removed (`prescription/{id}/pay` has no scheduled time).
`lib/views/pharmacy/prescription_checkout_screen.dart` shows "Cash on Delivery" but silently sends online.
AC: Only Wallet and Online are shown for prescription orders. What the customer picks is what is sent.

**P0-3. Keep the driver call button for masked calls.**
Masked calls are required (SPX-ADM-02 item 15). AC: the call-driver button in `tracking_widgets.dart`, `courier_order_detail_screen.dart`, `water_order_details_screen.dart`. starts a masked call through the backend API once it lands; until then keep the button and its \"coming soon\" message.

**P0-4. Courier pickup must be the customer's choice.** ✅ Done (pickup picker; fake totals removed in `fix/courier-online-payment`).
`lib/views/courier/courier_screen.dart` hard-codes the pickup. AC: customer picks pickup on the map/saved addresses (same picker as drop-off); quote and create use that point. Remove the fake `redeemedPointsDiscount = 1` and `tax = 2` in `courier_review_booking_screen.dart`; the total shown equals the server quote.

**P0-5. Water subscription purchase must not fake success.** ✅ Done (C11, `feat/water-subscription-payment`): the plan comes from `water/plans`; the cart offers cash on the first delivery (default), online or wallet and sends `payment_type` + `quantity` (1–50) to `water/subscribe`; total = plan price × quantity. Online opens `payment_url`, polls `wallet/topup/{topup_id}` and shows success only when paid; a failed/closed payment reopens the same payment page instead of buying again.
AC: until the subscribe contract is confirmed, the Pay button is disabled with a clear message, or it calls `water/subscribe` and shows success only when the server says so. The nearby-suppliers list comes from the API, not the hard-coded list in `water_nearby_suppliers_screen.dart`.

**P0-6. Home search must search.** ✅ Done (P1-2, P1-3).
AC: submitting the home search box (typed, voice or camera label) opens a results screen. Until unified search ships (P1-2), it may route to the Food search; after, it uses `customer/search`.

**P0-7. Remove sample content customers can see.** Mostly done (C5, `fix/remove-sample-content`): Under 30 minutes lists homeHub's `under_30_minutes` (empty state when none); My Schedules shows an empty state (no customer pre-order list endpoint yet); the rate screen's sample item cards (never submitted) are gone; the redeem sheet no longer shows "Lorem Ipsum" or a made-up reward value. **Still sample:** the laundry dry-cleaning garment list and the two store maps (C18 / P2-6, P2-7).
AC: no hard-coded stores/items/garments/images in `under_30_min_screen.dart`, `laundry_dry_cleaning_screen.dart`, `rate_order_screen.dart` (item cards), `my_schedules_screen.dart`, `store_map_screen.dart`, `express/express_store_map_screen.dart`; no "Lorem Ipsum" in `redeem_detail_sheet.dart`. Show real data or an empty state.

**P0-8. My Orders → Local Store tab.** ✅ Done (C5): loads `customer/orders/localStore` through the local-store `GroceryRepository` and shows the grocery order cards (detail, cancel, track, rate); also listed on the All tab.
AC: tab loads `customer/orders/localStore` (use the local-store `GroceryRepository`), with detail, cancel and rate like Grocery.

### P1 — client decisions for this phase

**P1-1. Localisation EN / FR / AR with RTL.** ✅ Done in code (`feat/translate-screens`, see 3.5); needs native-speaker review and an RTL pass on a device.
AC: every visible string comes from translations (GetX `Translations` or Flutter `intl`/ARB — pick one and use it everywhere). `GetMaterialApp` sets `locale`, `fallbackLocale: en`, `supportedLocales`. Choosing Arabic flips layout to RTL (icons, paddings, back arrows, sliders). The choice is saved locally and sent with `updateLanguage`; it survives restart. API messages use the matching `message_xx`. The client reports wording issues later; do not wait for perfect copy.

**P1-2. Unified search.** ✅ Done (`feat/unified-search`): Home search (typed or voice) opens `AllSearchScreen`, which calls `GET customer/search` and lists stores by category (Food, Grocery, Local Store, Pharmacy, Water) then products; tapping opens that category's store screen (products open their store; opening the product sheet directly is not done yet). Laundry/car wash/home cleaning/gas store hits are not listed (no store screen to open from search).
AC: text and voice search from Home return stores and products across all categories, nearest first, only stores that deliver to the selected location. Tapping a product opens it in its store ready to add to cart.

**P1-3. Image search via Google Vision.** ✅ Done (`feat/unified-search`): the home camera photo goes to `POST image-recognition/analyze` without `type`; results show like a typed search. On-device ML Kit is no longer used by the home box.
AC: capture or upload a photo → backend identifies the product → list of stores with price, distance, rating → tap opens that product in the store. On-device ML Kit may stay only as a fallback if the backend is unreachable (confirm with the backend owner).

**P1-4. Wallet top-up and split payment.** ✅ Done (`feat/wallet-topup`): `WalletScreen` (built without a Figma screen; opened from the Home wallet pill and the Account WALLET card) shows balance and paged history (`GET wallet`) and tops up within the server limits (`POST wallet/topup` → Masrvi → polls `GET wallet/topup/{id}`). In the cart, Wallet with too little balance shows "Wallet X + Online Y" and sends `payment_type=2` + `use_wallet=1` (classic and catalog checkout). Service and courier checkouts still use wallet-only (type 3).
AC: Wallet screen with balance and transaction history; top-up 100 – 50,000 MRU (validate both limits in the app and expect server validation) paid via Masrvi WebView; balance refreshes after success. At checkout, if the wallet is short, the app shows "Wallet X + Online Y" and pays Y by Masrvi; never place an order the wallet cannot cover without that step.

**P1-5. Trusted customers / Pay After Delivery.** ✅ Done (`fix/pay-after-delivery`): the cart loads `GET customer/payAfterDelivery`; PAD is selectable only when `can_use`, otherwise it shows why (tap opens Pay Later when an order is unpaid); never the default (Wallet is); sends `payment_type=4`. **Pay Later** screen (Account → Pay Later, built without a Figma screen) lists `unpaid_orders` and pays them online (Masrvi) or from the wallet (`POST payAfterDelivery/orders/{id}/pay`).
AC: PAD appears only when the server says the customer is trusted. Order is placed with payment pending. The order shows "Pay now" and a 24-hour deadline; payment goes through Masrvi. If one PAD order is unpaid, PAD is hidden for new orders. Overdue status comes from the server.

**P1-6. Masrvi for courier and service bookings.** Courier ✅ done (`fix/courier-online-payment`): Online opens `payment_url` from `courier/create`; a failed or closed payment keeps the order and the pay button retries it with `POST orders/{id}/payOnline`; success only after payment. Review total = quoted delivery fee (fake points/tax removed). Services (car wash, home cleaning, laundry): pending.
AC: choosing Online on courier, car wash, home cleaning or laundry opens the Masrvi WebView, handles fail/cancel with retry of the same order (same pattern as `cart_screen.dart`), and shows success only after payment.

**P1-7. Pre-orders (Schedule for later).** Cart part ✅ done (`feat/pre-orders`): the sheet loads `GET customer/preorder/window`, offers only the days in the window and greys out slots whose start time falls outside it; the chosen slot's start time is sent as `scheduled_for` (ISO with offset) on `checkoutV2` and `catalog/checkout`; the card's ✕ goes back to "deliver now". **Still open:** My Schedules (`my_schedules_screen.dart`) is a hard-coded list; there is no customer endpoint listing pre-orders yet (only `vendorapp/preorders`). Ask the backend for one (or `is_preorder` / `scheduled_for` on the orders lists).
AC: the existing "Schedule for later" sheet in `cart_screen.dart` limits dates to the server's max days (default 7) and sends the chosen time. My Schedules lists real scheduled orders.

**P1-8. Grocery substitution.** ✅ Done (`feat/grocery-substitution`), except the push that opens it (P2-1): `OrderUpdatedDetailScreen` (Figma "Order Changes" layout) now loads `GET customer/orders/{id}/substitutions`, shows each line (original → substitute or unavailable, price change, status), a live countdown from `seconds_left`, and per-line Accept/Reject (`POST substitutions/{id}/respond`). An `amount_due` is paid in cash at the door by default or online with "Pay online now" (`POST orders/{id}/payDue`). My Orders → Grocery shows "Review changes" (instead of Cancel) on active orders with waiting proposals or an amount due. The Figma's single "Approve / Reject all" was replaced by per-line answers, because the API answers each proposal separately.
AC: when a vendor proposes a replacement, the customer gets a notification and the Figma "order updated" screen (`order_updated_detail_screen.dart`) with Accept / Reject and new totals; a visible 10-minute countdown; after 10 minutes the server auto-accepts and the app shows the accepted state.

**P1-9. Pharmacy per-item quote.** ✅ Done (C12, `feat/pharmacy-item-quote`): the quotation shows each line as available, partial ("only X of Y") or unavailable (0 MRU); alternatives (lines with `alternative_for`) show what they replace with Accept / Reject (`POST prescription/{id}/alternatives`), after which the screen reloads the server's `quote_amount`. Pay is blocked with a message while `pending_alternatives` > 0. Decline uses `prescription/{id}/decline`.
AC: quotation screen shows each item as available, partial or unavailable, any substitute with its price, and the new total; the customer accepts/rejects substitutes before paying (wallet or online only); a Decline action uses `prescription/{id}/decline`.

**P1-10. Car wash location types.** ✅ Done (C13, `feat/car-wash-locations`): the location screen offers At Wash Station, At Home, At Workplace and At Another Address (map picker); home/workplace use the delivery location. `place` (`station`/`home`/`workplace`/`other`) and the address/coordinates go to `service/book` (`placeServiceBooking` now takes optional `address`/`latitude`/`longitude`). The hard-coded "Ilot V" address and 150 MRU home-service fee were removed; the price is the server quote checked before booking. Instructions go in `notes`.
AC: `car_wash_service_location_screen.dart` offers Home, Workplace, Other and At Station; the address picker shows for the first three; the value is sent to quote and book; the home-service fee shown equals the server quote.

**P1-11. Catalog (food) coupons.** ✅ Done (C14, `feat/food-cart-coupons`): food carts now load `catalog/checkoutSummary` (item total, delivery charge, tax and `grand_total` from the server instead of the cart's built-in fee/tax guesses) with `coupon_code`; Apply checks the code there and a 422 shows the server's reason and drops the code; `catalog/checkout` sends `coupon_code`. Gas empty-cylinder confirmation (rest of C14) is not done: the app has no gas screens.
AC: coupons apply in the food cart and are sent to `catalog/checkout`; coupons are vendor-specific (a coupon for store A is rejected in store B with the server message).

**P1-12. AI chatbot (Claude).** ✅ Done (C15, `feature/ai-assistant`): canned replies and the fake order-tracking card are gone; every message goes to the server. Read-only by design (the app gives the assistant no actions). Until Admin sets the Anthropic key the server answers 503 and the chat shows that message.
AC: `chatbot_ai_chat_screen.dart` sends messages to the backend and shows answers; supports EN/FR/AR; can answer about the customer's own orders, wallet and points. The chat must not change the cart or place orders by itself (scope rule). No API key in the app.

**P1-13. Delivery fee display.** ✅ Done (C9, `fix/server-delivery-fee`): the cart's payment rows printed fixed values (delivery 5 MRU, tax 2 MRU, points 1 MRU) and sent `redeem_amount=1` with points on by default. Now delivery fee, tax and points come only from the checkout summary ("…" until it loads); a 0 fee shows "Free Delivery". The points card shows the server's `redeem_points_available` / `redeem_points_amount`, only when `is_reward_enabled` and the customer has points, is off by default, and sends `redeem_amount` = `redeem_points_amount`.
AC: checkout shows the per-km delivery fee from the server summary; Gold+ customers see "Free Delivery" and 0 MRU.

### P2 — completeness and polish

**P2-1. Push notifications.** Needs a decision on FCM and a backend token endpoint (contract pending). AC: order status, chat and substitution notifications open the right screen. **Blocked (C17):** the app has no Firebase files (`android/app/google-services.json`, `ios/Runner/GoogleService-Info.plist` for the existing V1 app IDs, Firebase project `saimpex-customer`), and the backend only takes the token at login (`verifyOtp` → `fcm_token`); a token refresh endpoint is still needed. The data payload (type + id per notification) also needs documenting so each push can open the right screen.

**P2-2. Global 401 handling.** AC: any 401 during use clears the session and returns to Login once, instead of repeated error toasts. Add it in `DioClient`'s `onError`. ✅ Done (C17, `feature/session-expiry-chat-read`): `DioClient.onSessionExpired` (set in `main.dart`) fires on a 401 to a request sent with the current token (not logout, not OTP): clears the session, resets home, goes to Login and shows "Your session has expired" once.

**P2-3. Chat unread and delete.** AC: opening a conversation calls `chat/markAsRead`; the list shows unread counts; delete uses `chat/deleteConversation`. ✅ Done (C17): opening a chat calls `chat/markAsRead`; the bin icon asks first, then calls `chat/deleteConversation` and removes the row only if the server agreed. Unread counts come from `allConversations` (already shown).

**P2-4. Real tests.** AC: replace `test/widget_test.dart` with tests for `ApiEnvelope.parse`, payment type mapping and one repository mapper; `flutter test` passes.

**P2-5. Analyzer clean-up.** AC: 0 warnings (13 today: unused fields/imports, dead null-aware code in `grocery_screen.dart` and `grocery_details_screen.dart`).

**P2-6. Laundry per Figma.** Replace the hard-coded dry-cleaning garment list with the backend list; match the Figma laundry screens. (No customer PDF upload — confirmed by Praveen.) 🟡 Partly done (C18, `feature/laundry-store-map`): the garment list and prices come from the provider's service item (`garments`) and are sent to `service/book`; the cart shows the server's subtotal/tax/total from `service/quote` and the unsupported express fee, coupon and points (fixed 300/50/10 MRU) are gone. **Not checked against Figma** (no Figma access in that session), and dev has no laundry service items yet, so the garment screen is untested with data.

**P2-7. Store Map.** AC: Store Map / Express Store Map show real stores on Google Maps (e.g. from `localStore/map` or the home lists) instead of a painted image. ✅ Done (C18): one `StoreMapScreen` on Google Maps for both; food uses the restaurant home's `map_stores` (else the listed restaurants), Express uses the `expressHome` vendors (now with coordinates). Pins and cards stay in sync; the search box filters by name; tapping a card opens the store. The painted `ExpressStoreMapScreen` was removed.

**P2-8. Release identifiers and signing.** AC: V1 applicationId / bundle ID, V1 keystore, version above V1, real app label, base URL switched to live only when the V2 backend is live (section 2.5).

---

## 7. Conventions

### Git

- **Commit identity:** use your own name and work email. Recent commits on this branch are by `Praveen Soman <praveen@sigosoft.com>`; earlier ones by `sharvin-sigosoft` and `Stephy`.
- **Commit style (current):** one change per commit; subject is a plain imperative sentence in sentence case, no prefix, no trailing full stop (e.g. `Pay with the SAIMPEX Wallet in every checkout`, `Saved addresses and favourites backed by the API`). The body explains what was wrong and what now happens, as short bullets. Older commits like `commit after api integration` are the style to **avoid**.
- Commits made with Claude Code end with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
- **Branches:** `fix/<short-topic>` for corrections, `feat/<short-topic>` for new features (same convention as the backend: `fix/customer-otp-security`, `feat/vendor-profile-otp`). Branch from `fix/customer-critical-flows` until it is merged, then from `main`.
- **Never merge to `main` or release without Praveen's go-ahead.** Open a PR and wait.
- **Never commit secrets:** no tokens, OTPs, passwords, keystores, `key.properties`, or new API keys. Do not commit a changed `baseUrl` pointing at your local machine. `android/local.properties` and `android/gradle.properties` are machine files.
- **Figma is read-only** for developers.

### Code

- Endpoint paths only in `ApiConstants`. API calls only in repositories. Screens never call Dio directly.
- Use `paymentTypeCash/Online/Wallet` from `lib/utils/wallet_balance.dart`; never hard-code `'1'`, `'2'`, `'3'`.
- Always pass `apiLanguageCode()` to the API.
- Show server messages (`ApiException.message`) instead of invented text; never show success before the server confirms.
- No sample data in shipped screens. If data is missing, show an empty state.
- Keep Figma layouts. A feature with no Figma screen: same style, and list it in your handover notes as "built without a Figma screen".
- Run `flutter analyze` before every commit (0 errors).

### Reporting API gaps to the backend owner

The backend owner is **Praveen Soman** (praveen@sigosoft.com); APIs are built on his Mac first (`praveensigo/saimpex-backend-new`, branch `integration/v2`). When the app needs something the API does not provide:

1. Check `saimpex-backend-new/routes/customer.php` and `saimpex-backend-new/docs/SAIMPEX_V2_CUSTOMER_API.md` on `integration/v2` first.
2. Send one message per gap with: screen (Figma frame name), endpoint (or "new"), the request you need, the response fields you need (with types), and the error cases.
3. Do not invent the contract in the app. Build the UI with an empty/disabled state and leave a short code comment such as `// Waiting for customer/search contract`.
4. When the contract lands in the API doc, wire it and note the backend commit in your commit body.

---

## 8. Known issues and risks

| # | Issue | Where | Impact |
|---|---|---|---|
| R-1 | Pay After Delivery is the default for food/grocery and posts as cash. | `lib/views/cart_screen.dart` | Orders recorded as COD against the PAD rule. (P0-1) |
| R-2 | Prescription checkout shows a cash option that silently sends online. | `lib/views/pharmacy/prescription_checkout_screen.dart` | Confusing; customer may expect to pay cash. (P0-2) |
| R-3 | Water subscription purchase shows success without any API call. | `lib/views/water/water_subscription_cart_screen.dart` | Customer believes they subscribed; nothing is created. (P0-5) |
| R-4 | Courier pickup is a fixed address; review total adds invented numbers. | `lib/views/courier/courier_screen.dart`, `courier_review_booking_screen.dart` | Wrong pickup for every courier order; displayed total differs from charge. (P0-4) |
| R-5 | Online payment for courier and service bookings has no payment step. | `courier_review_booking_screen.dart`, `lib/views/services/service_booking_submit.dart` | Booking created as "online" but never paid. (P1-6) |
| R-6 | Google Maps API key is committed in `AndroidManifest.xml` and `ios/Runner/AppDelegate.swift`. | — | Key can be abused if unrestricted. Restrict it to the app IDs/bundle IDs in Google Cloud; consider moving it to an untracked config. Do not copy it into docs or chat. |
| R-7 | Debug logging prints the full Bearer token and bodies. | `lib/core/network/dio_client.dart` | Only in debug builds (`kDebugMode`), but tokens end up in shared logs/screenshots. Mask the token. ✅ Masked (C17): logs show `Bearer …` plus the last 6 characters. |
| R-8 | No global 401 handling. | `lib/core/network/dio_client.dart` | Expired session shows error toasts instead of returning to login. (P2-2) ✅ Fixed (C17). |
| R-9 | No UI translations and no RTL. Language resets on restart. | `lib/main.dart`, `lib/controllers/onboarding_controller.dart` | French/Arabic users see English UI. (P1-1) |
| R-10 | Home search, voice search and image search fill a field that triggers nothing. | `lib/views/widgets/home_search_box.dart` | Headline feature appears broken. (P0-6) |
| R-11 | Release build signs with the debug key; placeholder app IDs. | `android/app/build.gradle.kts`, `ios/Runner.xcodeproj/project.pbxproj` | Cannot ship as a V1 update until fixed. (P2-8) |
| R-12 | Dev server code version is unknown. | — | Wallet type 3, addresses, favourites, loyalty need backend `integration/v2`. Confirm deployment before debugging. |
| R-13 | `test/widget_test.dart` is the template counter test and fails. | `test/widget_test.dart` | `flutter test` is red; CI (if added) fails. (P2-4) |
| R-14 | `checkoutV2`/`checkoutSummaryV2` fall back to V1 routes on 404/405. | `lib/views/cart_screen.dart`, `lib/models/order_repository.dart` | Hides a missing V2 route; V1 `checkout` may ignore payment type 3. Remove the fallback once dev is on `integration/v2`. |
| R-15 | `scratch_grocery.json` (empty) and `android/gradle.properties` are tracked though `.gitignore` lists `android/gradle.properties`. | repo root, `android/` | Clutter; machine-specific Gradle memory settings (`-Xmx8G`) may not suit every machine. |
| R-16 | Very large screen files (e.g. `cart_screen.dart` ~3,400 lines, `home_screen.dart` ~2,100). | `lib/views/` | Edits risk regressions; change carefully and test each flow. |
| R-17 | Many deprecated `withOpacity` calls (analyzer infos). | across `lib/` | Not breaking now; will need `withValues` on newer Flutter. |
| R-19 | `docs/V2_HANDOFF.md` section 6.5 lists items that are now done (courier detail/tracking, car wash multi-vehicle, water order details, addresses, favourites, rewards). | `docs/V2_HANDOFF.md` | Use this document for the customer app's current state. |

### Not verified

- No flow in this document was run on a device or emulator while writing it; status comes from reading code and `flutter analyze` (Flutter 3.47.9: 0 errors, 13 warnings).
- Which backend branch runs on `dev.saimpexenterprise.com`.
- Chat voice notes and images end to end; coupons screen and reviews screen response shapes.
- Whether the language is restored from the profile on login.
- Exact JDK / Gradle requirements on a fresh machine.

### Switched-off services (`fix/disabled-services`)

- Home tabs come from `homeHub.verticals`; rows with `is_enabled: false` are dropped when parsed, so `HomeController.isVerticalEnabled(slug)` is true only for listed slugs (and for everything before Home has loaded).
- The Services screen hides Home cleaning, Car wash and Laundry when their vertical is off (the grid closes up); search results and Express vendors skip switched-off categories.
- Checkout and booking show the server's 422 message (e.g. "service unavailable") through `ApiException.message`; `resolveApiMessage` also reads messages nested under a field name (`{"field": {"message_en": [...]}}`). The 422 itself is not on `integration/v2` yet, so it wasn't tried against the server.

### Checkout refusals: used-up coupon, hidden product (`fix/checkout-refusals`)

When checkout answers 422 the cart shows the server's message, then re-checks the applied coupon with `applyCoupon` (read-only on the server). If the coupon is refused (4xx), it's removed with a note. The cart and totals then reload, so a product the store hid is no longer shown as orderable. It doesn't depend on a specific error code. The backend change wasn't on GitHub when this was written, so it wasn't tried against the server; if the cart list still returns hidden products, the backend should drop or flag them there.

## Backend updates since this handover

| Date | What's ready | Contract |
|---|---|---|
| 31 Oct 2026 | Unified search + image search (`GET customer/search`, image analyze without `type`) | backend API doc §6.7 |
| 31 Oct 2026 | Wallet screen, top-up 100–50,000 MRU, split payment (`use_wallet=1`) | §6.8 |
| 31 Oct 2026 | Pay After Delivery (`payment_type=4`, `GET payAfterDelivery`, pay later online/wallet). Replace the current "PAD sent as cash" behaviour: show PAD only when `can_use` is true, never as the default. | §6.9 |
| 31 Oct 2026 | Pre-orders: time picker bounded by `GET customer/preorder/window`; send `scheduled_for` (ISO with offset) on checkout. | §6.10 |
| 31 Oct 2026 | Grocery substitution: show proposals with a countdown on the order screen, accept/reject. `GET customer/orders/{id}/substitutions`, `POST customer/substitutions/{id}/respond`. Push arrives when the store proposes. | §6.11 |
| 31 Oct 2026 | Substitution extra: when a pricier substitute is accepted on a prepaid order, the wallet pays first and the rest is `amount_due`. Send `pay_rest` = `cash` or `online` with the answer; online returns `payment_url`. Later: `POST customer/orders/{id}/payDue`. Show `amount_due` on the order screen. | §6.11 |
| 31 Oct 2026 | Courier and service bookings can be paid online: `payment_type=2` returns `payment_url`; retry with `POST customer/orders/{id}/payOnline`. Remove the hard-coded courier pickup and made-up review totals while wiring this. | §6.12 |
| 31 Oct 2026 | **Client's SPX-ADM-02 is final:** masked customer↔driver calls are required (keep the call button; API in Phase 3); delivery fee is per vendor (free / fixed / % / per km) with who pays — show the server's fee. | `V2_COMPLETE_SCOPE.md` §13.2 |
