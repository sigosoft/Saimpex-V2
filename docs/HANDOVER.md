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
| Android `applicationId` / `namespace` | applicationId `app.saimpex` (V1's, set in C17 for Firebase); namespace still `com.example.saimpex_v2` (`android/app/build.gradle.kts`) | Done for the ID. A device with V1 installed must uninstall it before a debug build installs (different signing key) until the V1 keystore is used (P2-8). |
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
- `GetMaterialApp` sets `translations`, `locale`, `fallbackLocale: en`, `supportedLocales` and the Flutter localisation delegates, so Arabic lays the app out right to left. Uneven left/right padding, `Positioned` offsets, `alignment:` values and `TextAlign.left/right` use the directional versions (`EdgeInsetsDirectional`, `PositionedDirectional`, `AlignmentDirectional`, `TextAlign.start/end`; `feature/translations-review`). Keep using them in new code. Even left/right values, gradients and custom painters stay as they are. Material arrow and chevron icons mirror by themselves.
- The language picker (`lib/views/widgets/language_selector.dart`) calls `customer/updateLanguage` (when logged in) and `AppLocale.change`. `apiLanguageCode()` returns `AppLocale.code`.
- Screen strings live in `lib/l10n/areas/` (`core`, `orders`, `pharmacy_water`, `services`, `stores`; key prefixes `core_`, `orders_`, `pw_`, `svc_`, `st_`), merged by `AppTranslations`. About 1,400 keys per language.
- `test/translations_test.dart` fails if FR/AR miss a key, drop an `@placeholder`, or the code uses an undefined key. Run `flutter test` after adding strings.
- Labels that code compares or sends to the API (e.g. account menu `label`, service card titles, home-cleaning room names, delivery slots, cancel reasons) stay English internally and are translated only when drawn.
- **Not translated on purpose:** server data, and sample/mock data still in some screens (to be replaced by real data, not translated).
- Error fallbacks in the repositories ("Request failed…"), courier statuses, provider-card tags and review messages are translated (`core_request_failed`, `core_status_1`…`10`, …).
- French and Arabic were reviewed key by key (AI review, not a native speaker), with consistent terms. French: livreur, prestataire, réservation, portefeuille, retrait (customer collects), collecte (courier/laundry pickup), programmer, noter.
- **Home section titles:** `homeHub` sends `title_en` only, so in FR/AR the app uses its own keys (`core_home_recent_orders`, `core_home_under_30`, …); a server `title_fr` / `title_ar` would win, and `title_en` is the last fallback (`GeneralRepository.homeSectionsFrom`, test `test/home_sections_test.dart`).
- **Still to do:** the client's native-speaker QA (16–25 Nov) and an RTL pass on a device (custom painters, gradients and maps were not changed).

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
| Gas | Done (unverified on device; dev has no gas items yet) | Home tile → suppliers (`serviceProviders`, vertical gas) → products (`serviceProvider`) → order: number of cylinders, required "hand back one empty cylinder per refill" confirmation (`return_empty_cylinder`), address, delivery time, cash/online/wallet (Admin switch respected), server price from `service/quote`; booked with `service/book`. No Figma screen: built in the services style. | `lib/views/services/gas_screen.dart`, `gas_order_screen.dart` |
| Courier | Done | Quote, create, orders list, order detail, live tracking are real. Customer picks the pickup point (C3); review total = quoted fee; Online opens Masrvi with retry (P1-6). | `lib/views/courier/courier_screen.dart`, `courier_review_booking_screen.dart`, `courier_order_detail_screen.dart`, `courier_track_order_screen.dart`, `lib/models/courier_repository.dart` |
| Car wash | Done | Providers, services, vehicles (all selected vehicles booked), station/home/workplace/other location (C13), slots, cart priced by `service/quote`, `service/book` with Masrvi for Online, My Bookings, booking detail from `service/booking`, cancel. | `lib/views/services/car_wash_*.dart`, `lib/views/services/service_booking_submit.dart`, `lib/models/service_repository.dart` |
| Home cleaning | Done | Providers, services, configure, property type + notes, slot, cart priced by `service/quote`, book with Masrvi for Online, booking detail from `service/booking` (spaces, extras, products, assigned cleaner, timeline, totals), cancel; the assigned cleaner shows on the booking and is rated separately when reviewing (`cleaner_rating`, C20). Gas bookings use the same detail screen with cylinders instead of spaces. | `lib/views/services/home_cleaning_*.dart` |
| Laundry | Done (balance payment waits on backend) | Providers, services, garments and prices from the provider (C18), pickup slot, cart priced by `service/quote`, book with Masrvi for Online, booking detail from `service/booking`, cancel. Matches Figma; editable pickup/delivery addresses; weigh-and-confirm block from the server. Dev has no laundry items yet. | `lib/views/services/laundry_*.dart` |
| Other services (plumbing, carpentry, electrical) | Not started ("Coming soon") | Tiles with no service behind them (plumbing, carpentry, electrical, home maintenance, vehicle, pet, CCTV, computer repair, both emergency cards) show a "Coming soon" label and say so on tap (`feature/services-coming-soon`). No Figma screen for the label; built in the Services screen style. Scope puts the services in later updates. | `lib/views/services/services_screen.dart` |
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
| My Schedules (pre-orders) | Done (C7) | Lists `GET customer/preorders` (soonest first) with filters All / Food / Grocery / Pharmacy, store, order code, total, status and the scheduled time; Cancel while the store hasn't started (status 1) and View Order. The Figma "Reschedule" button is replaced by View Order: there is no reschedule API. Order details show "Scheduled for …" on pre-orders. | `lib/views/my_schedules_screen.dart` |
| Chat with vendor | Done (unverified on device) | Conversations list, conversation, send text/image/voice note. `markAsRead` and `deleteConversation` are not used. | `lib/views/messages_screen.dart`, `lib/views/chat_screen.dart`, `lib/models/chat_repository.dart` |
| AI chatbot | Done (C15, unverified on device) | Floating head + chat UI wired to `chatbot/message` (API §6.19): keeps `conversation_id`, sends the delivery location, history sheet (`chatbot/conversations`), voice input (speech_to_text in the chat language), reads replies aloud only when the customer spoke and Admin turned `voice_output` on (flutter_tts). Server errors (not configured / daily limit / temporary failure) show as a red bubble. | `lib/views/chatbot_ai_chat_screen.dart`, `lib/views/widgets/chatbot_head.dart`, `lib/views/widgets/chatbot_welcome_sheet.dart` |
| Notifications | Done on Android (C17); iOS needs Xcode | In-app list and preferences, plus Firebase push (`lib/core/push/push_notifications.dart`): token to `customer/updateFcmToken` after login and on refresh, cleared before logout; foreground pushes shown on the `customer` channel; tapping `admin_message` opens the support thread, `chat` the Chat tab, `prescription` My Prescriptions, any other push opens Notifications (order pushes carry no data yet). | `lib/views/notifications_screen.dart`, `lib/views/app_preferences_screen.dart` |
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

**P0-7. Remove sample content customers can see.** ✅ Done (C5, `fix/remove-sample-content`): Under 30 minutes lists homeHub's `under_30_minutes` (empty state when none); My Schedules shows an empty state (no customer pre-order list endpoint yet); the rate screen's sample item cards (never submitted) are gone; the redeem sheet no longer shows "Lorem Ipsum" or a made-up reward value. The laundry garment list and the two store maps are real since C18 (P2-6, P2-7). The car wash, home cleaning/gas and laundry booking detail screens showed sample bookings (fixed dates, a made-up cleaner, fake totals and points); they now load `service/booking` (`feature/service-booking-details`).
 The rest went in `feature/remove-leftover-samples`: provider Reviews tabs load `GET reviews?type=provider` (no more Lorem ipsum reviews or made-up rating counts); the car wash services screen shows the picked catalog service with its per-vehicle prices and add-ons (the fixed Exterior/Interior/Full list, prices and "Engine Wash" add-on are gone); the laundry cart shows the selected address; Nearby Suppliers (water) lists `waterHome` nearby suppliers and opens the real supplier screen; order detail and both pharmacy order detail screens have no sample mode (real address, driver only when assigned, real items and steps); fake store names, default avatars and reward contents removed. An unused sample food customise sheet was deleted.
AC: no hard-coded stores/items/garments/images in `under_30_min_screen.dart`, `laundry_dry_cleaning_screen.dart`, `rate_order_screen.dart` (item cards), `my_schedules_screen.dart`, `store_map_screen.dart`, `express/express_store_map_screen.dart`; no "Lorem Ipsum" in `redeem_detail_sheet.dart`. Show real data or an empty state.

**P0-8. My Orders → Local Store tab.** ✅ Done (C5): loads `customer/orders/localStore` through the local-store `GroceryRepository` and shows the grocery order cards (detail, cancel, track, rate); also listed on the All tab.
AC: tab loads `customer/orders/localStore` (use the local-store `GroceryRepository`), with detail, cancel and rate like Grocery.

### P1 — client decisions for this phase

**P1-1. Localisation EN / FR / AR with RTL.** ✅ Done in code (`feat/translate-screens`, see 3.5); needs native-speaker review and an RTL pass on a device. Device pass (1 Nov 2026, Android emulator, Arabic): onboarding, language picker and login are correct right to left. Inner screens could not be reached: there is no dev test login (`OTP_TEST_NUMBERS` is empty in the backend `.env.example`), and guest browsing on `feature/ease-of-use` still sends guests to Login from `MainShellScreen.build` (`if (!isLoggedIn) return LoginScreen()`); with that check removed locally the home screen hit a framework assertion behind the guest login sheet. Needed: a dev test number, or guest browsing fixed and merged, then walk home, stores, cart, orders, bookings, services and account in Arabic.
AC: every visible string comes from translations (GetX `Translations` or Flutter `intl`/ARB — pick one and use it everywhere). `GetMaterialApp` sets `locale`, `fallbackLocale: en`, `supportedLocales`. Choosing Arabic flips layout to RTL (icons, paddings, back arrows, sliders). The choice is saved locally and sent with `updateLanguage`; it survives restart. API messages use the matching `message_xx`. The client reports wording issues later; do not wait for perfect copy.

**P1-2. Unified search.** ✅ Done (`feat/unified-search`): Home search (typed or voice) opens `AllSearchScreen`, which calls `GET customer/search` and lists stores by category (Food, Grocery, Local Store, Pharmacy, Water) then products; tapping opens that category's store screen (products open their store; opening the product sheet directly is not done yet). Laundry/car wash/home cleaning/gas store hits are not listed (no store screen to open from search).
AC: text and voice search from Home return stores and products across all categories, nearest first, only stores that deliver to the selected location. Tapping a product opens it in its store ready to add to cart.

**P1-3. Image search via Google Vision.** ✅ Done (`feat/unified-search`): the home camera photo goes to `POST image-recognition/analyze` without `type`; results show like a typed search. On-device ML Kit is no longer used by the home box.
AC: capture or upload a photo → backend identifies the product → list of stores with price, distance, rating → tap opens that product in the store. On-device ML Kit may stay only as a fallback if the backend is unreachable (confirm with the backend owner).

**P1-4. Wallet top-up and split payment.** ✅ Done (`feat/wallet-topup`): `WalletScreen` (built without a Figma screen; opened from the Home wallet pill and the Account WALLET card) shows balance and paged history (`GET wallet`) and tops up within the server limits (`POST wallet/topup` → Masrvi → polls `GET wallet/topup/{id}`). In the cart, Wallet with too little balance shows "Wallet X + Online Y" and sends `payment_type=2` + `use_wallet=1` (classic and catalog checkout). Service and courier checkouts still use wallet-only (type 3).
AC: Wallet screen with balance and transaction history; top-up 100 – 50,000 MRU (validate both limits in the app and expect server validation) paid via Masrvi WebView; balance refreshes after success. At checkout, if the wallet is short, the app shows "Wallet X + Online Y" and pays Y by Masrvi; never place an order the wallet cannot cover without that step.

**P1-5. Trusted customers / Pay After Delivery.** ✅ Done (`fix/pay-after-delivery`): the cart loads `GET customer/payAfterDelivery`; PAD is selectable only when `can_use`, otherwise it shows why (tap opens Pay Later when an order is unpaid); never the default (Wallet is); sends `payment_type=4`. **Pay Later** screen (Account → Pay Later, built without a Figma screen) lists `unpaid_orders` and pays them online (Masrvi) or from the wallet (`POST payAfterDelivery/orders/{id}/pay`).
AC: PAD appears only when the server says the customer is trusted. Order is placed with payment pending. The order shows "Pay now" and a 24-hour deadline; payment goes through Masrvi. If one PAD order is unpaid, PAD is hidden for new orders. Overdue status comes from the server.

**P1-6. Masrvi for courier and service bookings.** Courier ✅ done (`fix/courier-online-payment`): Online opens `payment_url` from `courier/create`; a failed or closed payment keeps the order and the pay button retries it with `POST orders/{id}/payOnline`; success only after payment. Review total = quoted delivery fee (fake points/tax removed). Services ✅ done (`feature/gas-refills`): car wash, home cleaning, laundry and gas bookings paid Online open `payment_url` from `service/book`; an unpaid booking is retried with `payOnline`.
AC: choosing Online on courier, car wash, home cleaning or laundry opens the Masrvi WebView, handles fail/cancel with retry of the same order (same pattern as `cart_screen.dart`), and shows success only after payment.

**P1-7. Pre-orders (Schedule for later).** Cart part ✅ done (`feat/pre-orders`): the sheet loads `GET customer/preorder/window`, offers only the days in the window and greys out slots whose start time falls outside it; the chosen slot's start time is sent as `scheduled_for` (ISO with offset) on `checkoutV2` and `catalog/checkout`; the card's ✕ goes back to "deliver now". My Schedules ✅ done (C7, `feature/my-schedules`): loads `GET customer/preorders`; Cancel (status 1) and View Order; food and item order details show a "Scheduled for …" banner from `is_preorder` / `scheduled_for`. Rescheduling is not offered (no API).
AC: the existing "Schedule for later" sheet in `cart_screen.dart` limits dates to the server's max days (default 7) and sends the chosen time. My Schedules lists real scheduled orders.

**P1-8. Grocery substitution.** ✅ Done (`feat/grocery-substitution`), except the push that opens it (P2-1): `OrderUpdatedDetailScreen` (Figma "Order Changes" layout) now loads `GET customer/orders/{id}/substitutions`, shows each line (original → substitute or unavailable, price change, status), a live countdown from `seconds_left`, and per-line Accept/Reject (`POST substitutions/{id}/respond`). An `amount_due` is paid in cash at the door by default or online with "Pay online now" (`POST orders/{id}/payDue`). My Orders → Grocery shows "Review changes" (instead of Cancel) on active orders with waiting proposals or an amount due. The Figma's single "Approve / Reject all" was replaced by per-line answers, because the API answers each proposal separately.
AC: when a vendor proposes a replacement, the customer gets a notification and the Figma "order updated" screen (`order_updated_detail_screen.dart`) with Accept / Reject and new totals; a visible 10-minute countdown; after 10 minutes the server auto-accepts and the app shows the accepted state.

**P1-9. Pharmacy per-item quote.** ✅ Done (C12, `feat/pharmacy-item-quote`): the quotation shows each line as available, partial ("only X of Y") or unavailable (0 MRU); alternatives (lines with `alternative_for`) show what they replace with Accept / Reject (`POST prescription/{id}/alternatives`), after which the screen reloads the server's `quote_amount`. Pay is blocked with a message while `pending_alternatives` > 0. Decline uses `prescription/{id}/decline`.
AC: quotation screen shows each item as available, partial or unavailable, any substitute with its price, and the new total; the customer accepts/rejects substitutes before paying (wallet or online only); a Decline action uses `prescription/{id}/decline`.

**P1-10. Car wash location types.** ✅ Done (C13, `feat/car-wash-locations`): the location screen offers At Wash Station, At Home, At Workplace and At Another Address (map picker); home/workplace use the delivery location. `place` (`station`/`home`/`workplace`/`other`) and the address/coordinates go to `service/book` (`placeServiceBooking` now takes optional `address`/`latitude`/`longitude`). The hard-coded "Ilot V" address and 150 MRU home-service fee were removed; the price is the server quote checked before booking. Instructions go in `notes`.
AC: `car_wash_service_location_screen.dart` offers Home, Workplace, Other and At Station; the address picker shows for the first three; the value is sent to quote and book; the home-service fee shown equals the server quote.

**P1-11. Catalog (food) coupons.** ✅ Done (C14, `feat/food-cart-coupons`): food carts now load `catalog/checkoutSummary` (item total, delivery charge, tax and `grand_total` from the server instead of the cart's built-in fee/tax guesses) with `coupon_code`; Apply checks the code there and a 422 shows the server's reason and drops the code; `catalog/checkout` sends `coupon_code`. Gas (rest of C14) ✅ done in `feature/gas-refills`: see the Gas row in the status table.
AC: coupons apply in the food cart and are sent to `catalog/checkout`; coupons are vendor-specific (a coupon for store A is rejected in store B with the server message).

**P1-12. AI chatbot (Claude).** ✅ Done (C15, `feature/ai-assistant`): canned replies and the fake order-tracking card are gone; every message goes to the server. Read-only by design (the app gives the assistant no actions). Until Admin sets the Anthropic key the server answers 503 and the chat shows that message.
AC: `chatbot_ai_chat_screen.dart` sends messages to the backend and shows answers; supports EN/FR/AR; can answer about the customer's own orders, wallet and points. The chat must not change the cart or place orders by itself (scope rule). No API key in the app.

**P1-13. Delivery fee display.** ✅ Done (C9, `fix/server-delivery-fee`): the cart's payment rows printed fixed values (delivery 5 MRU, tax 2 MRU, points 1 MRU) and sent `redeem_amount=1` with points on by default. Now delivery fee, tax and points come only from the checkout summary ("…" until it loads); a 0 fee shows "Free Delivery". The points card shows the server's `redeem_points_available` / `redeem_points_amount`, only when `is_reward_enabled` and the customer has points, is off by default, and sends `redeem_amount` = `redeem_points_amount`.
AC: checkout shows the per-km delivery fee from the server summary; Gold+ customers see "Free Delivery" and 0 MRU.

### P2 — completeness and polish

**P2-1. Push notifications.** ✅ Done on Android (C17, `feature/push-notifications`): `firebase_messaging` with V1's Firebase project `saimpex-customer` (`android/app/google-services.json`, copied from the V1 repo `Saimpex-SA`; applicationId is now V1's `app.saimpex`). The token is sent to `POST customer/updateFcmToken` (API §6.45) after login and on every refresh and cleared ("") before logout. Pushes while the app is open show on the `customer` channel (`flutter_local_notifications`). Tap: `admin_message` + `order_id` → that support thread; `chat` (+ `conversation_id`) → Chat tab; `prescription` (+ `prescription_id`) → My Prescriptions (backend `41739a8`); `order_status` / `substitution` (+ `order_id`, `order_type`, backend `c46b7bf`) → food: Order Details, grocery / pharmacy / local store: their order screen, other types: Orders tab; anything else → Notifications. **Still open:** (1) iOS: on a Mac add `GoogleService-Info.plist` from `Saimpex-SA/ios/Runner` to the Runner target, set the bundle ID to `app.saimpex`, enable Push Notifications + Background Modes (remote notifications) and upload the APNs key to Firebase; until then push is off on iOS and the app runs normally. (2) Tried on the Android emulator: Firebase starts and the notification permission prompt shows, but the emulator logged "FCM Registration failed" when fetching a token with the debug signing key; V1's Firebase key is probably restricted to V1's signing certificate, so check on a device with the V1 keystore (P2-8) or add the debug SHA-1 in Firebase. Token upload after login was not tried (no test login). (3) (2) Backend: order status, chat and substitution pushes send no `type`/`order_id`, so they can only open Notifications; asked in "Reporting API gaps".

**P2-2. Global 401 handling.** AC: any 401 during use clears the session and returns to Login once, instead of repeated error toasts. Add it in `DioClient`'s `onError`. ✅ Done (C17, `feature/session-expiry-chat-read`): `DioClient.onSessionExpired` (set in `main.dart`) fires on a 401 to a request sent with the current token (not logout, not OTP): clears the session, resets home, goes to Login and shows "Your session has expired" once.

**P2-3. Chat unread and delete.** AC: opening a conversation calls `chat/markAsRead`; the list shows unread counts; delete uses `chat/deleteConversation`. ✅ Done (C17): opening a chat calls `chat/markAsRead`; the bin icon asks first, then calls `chat/deleteConversation` and removes the row only if the server agreed. Unread counts come from `allConversations` (already shown).

**P2-4. Real tests.** AC: replace `test/widget_test.dart` with tests for `ApiEnvelope.parse`, payment type mapping and one repository mapper; `flutter test` passes. ✅ Done (`feature/analyzer-and-tests`): the template test is gone; `test/core_test.dart` covers `ApiEnvelope.parse` (languages, JSON strings, refusals, nested 422s), the payment-method rules, `ChatbotRepository` mapping and its translated errors (through a fake Dio), and `serviceSlotWindow`. `flutter test`: 17 passing.

**P2-5. Analyzer clean-up.** AC: 0 warnings (13 today: unused fields/imports, dead null-aware code in `grocery_screen.dart` and `grocery_details_screen.dart`). ✅ Done: 0 errors, 0 warnings (the remaining ~490 are info-level lints such as `withOpacity` deprecations, left for C19).

**P2-6. Laundry per Figma.** Replace the hard-coded dry-cleaning garment list with the backend list; match the Figma laundry screens. (No customer PDF upload — confirmed by Praveen.) ✅ Done (C18: `feature/laundry-store-map`, then `feature/laundry-figma`): the garment list and prices come from the provider's service item (`garments`) and are sent to `service/book`; the cart shows the server's subtotal/tax/total from `service/quote` and the unsupported express fee, coupon and points (fixed 300/50/10 MRU) are gone. Checked against Figma (file `ZCYkkdqmKm6Hn5Hcm12Mxg`, laundry flow): home, provider detail, Wash & Fold, Dry Cleaning, pickup time, cart, success, My Bookings and booking detail match. Fixed in `feature/laundry-figma`: provider cards show the rating by the name; the cart shows the service's Delivery Speed and lets the customer edit the pickup and delivery addresses (`delivery_address` on `service/book`); the My Bookings weigh block shows the server's estimated/actual kg, prices and balance (it was never shown, and had fixed numbers); Help opens Help & Support. **Not built, needs backend:** paying the balance after re-weighing, choosing Express (+fee) in the cart (speed is per service), and the "Pickup by" driver card (bookings have no driver). Dev has no laundry providers, so nothing was tried with data.

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

**Open requests (laundry, 1 Nov 2026), to send as `[customer-app] …` issues:**

1. **Pay the balance after re-weighing.** Screen: My Bookings laundry card / laundry booking detail → "Pay @amount". `service/booking` returns `additional_payment` > 0, but no customer endpoint takes it: `POST orders/{id}/payDue` reads `orders.amount_due` (re-weighing doesn't set it → 404 "Nothing is due"), and `payment_url` is null once the booking is paid. Needed: set `orders.amount_due` on re-weigh so `payDue` works, or `POST service/{orderId}/payBalance` → `{payment_url, topup_id, amount_due}`; and say whether cash bookings just collect the new total. The app shows "not available" until then.
2. **Choose Express in the cart.** Figma "Cart" (laundry): Standard (24 h) or Express (5–6 h, +300 MRU). `service/quote` / `service/book` take no speed; the speed is the service item's `processing`. Needed: a `turnaround` (`standard` | `express`) input with the Express fee in the quote and on the order. The app shows the service's own speed until then.
3. **Pickup driver on the booking.** Figma "Order Delivery Detail Page" → "Pickup by" (photo, name, rating, call). Service bookings have no `driver` block. Needed: the same `driver` shape as `trackOrder` (`name`, `image`, `rating`, `reviews`) on `service/bookings` and `service/booking` once a driver is assigned.

**Open request (push, 1 Nov 2026):**

4. **Push data for order, chat and substitution notifications.** Only `admin_message` pushes carry `type` and `order_id`; order status, chat and substitution pushes to the customer send only `type: "1"`, so a tap can only open the Notifications list. Needed in the push `data`: `type` (e.g. `order_status`, `chat_message`, `substitution`), `order_id`, `order_type`, and `vendor_id` for chat.

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
| R-13 | `test/widget_test.dart` is the template counter test and fails. | `test/widget_test.dart` | `flutter test` is red; CI (if added) fails. (P2-4) ✅ Fixed. |
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
| 31 Oct 2026 | Payment methods on/off (Admin): `GET customer/paymentMethods`; hide disabled methods at every checkout. ✅ Applied (`feature/payment-methods-switch`) to the food/grocery cart, courier, car wash, home cleaning, laundry, water subscription and prescription checkouts via `utils/payment_methods.dart`; a disabled choice falls back to the next enabled one (never Pay After Delivery); with none left the checkout says so and won't submit. If the list can't load, all methods show and the server's 422 explains. Not yet on dev when built (404). Wallet top-up and `payOnline`/`payDue` buttons still rely on the server's refusal. | §6.30 |
| 31 Oct 2026 | **All Phase 1 APIs ready on dev:** car wash locations (§6.13), water subscription payment (§6.14), pharmacy per-item quote + alternatives (§6.15), food-cart coupons (§6.16), gas empty-cylinder confirmation (§6.17), WhatsApp messages are server-side (§6.18), **AI assistant** `POST customer/chatbot/message` + transcript (§6.19). | Tasks C11–C15 are unblocked. |
| 31 Oct 2026 | **Delivery PIN:** `trackOrder` returns `delivery_pin`; for any order type `GET customer/orders/{id}/deliveryPin`. Show it big on the tracking screen: "Give this PIN to the driver" (EN/FR/AR). | §6.20 |
| 31 Oct 2026 | Minimum order per vendor: checkout summaries return `min_order_value` + `min_order_shortfall`; placing below it → 422. `restaurantDetails.min_order_value`. | Show "Minimum order X MRU" on the store page; in the cart disable Place order and show "Add Y MRU more" while the shortfall is > 0 (§6.22). |
| 31 Oct 2026 | **My Schedules:** `GET customer/preorders` lists open pre-orders (all types); `orderDetails`, `trackOrder`, `catalog/orderDetail` return `is_preorder` + `scheduled_for`. | Wire My Schedules to `GET preorders`; show "Scheduled for …" on order detail/tracking (§6.10). |
| 31 Oct 2026 | Checkout summaries return `delivery_fee_paid_by` (customer/vendor/saimpex) and `delivery_fee_full`. When it isn't `customer`, `delivery_charge` is 0. | Show "Free delivery" (optionally "paid by the store") instead of 0 MRU (§6.22). |
| 31 Oct 2026 | Service quotes (`service/quote`) return `tax`, `tax_percent`, `total` (= subtotal + tax); courier quotes return `tax`, `total` (= fee + tax). Prices are tax-exclusive. | Show a Tax line and charge `total` on service and courier checkout (§6.27). |
Car wash and home cleaning carts (`feature/car-wash-server-price`): like laundry, the fixed 10 MRU tax, 50 MRU points discount and the coupon field (none supported by `service/book`) are gone; subtotal, tax and total come from `service/quote` and are re-quoted when the slot (or, for home cleaning, who brings the products) changes.

Service bookings paid online (`feature/gas-refills`): laundry, car wash, home cleaning and gas bookings with Online used to be created and never paid (the cart ignored `payment_url`). `placeServiceBooking` now opens the payment page; if the customer doesn't finish, the booking is remembered and the next Pay reopens it with `orders/{id}/payOnline` instead of booking twice. Home hub tiles Gas, Laundry, Car wash and Home cleaning used to open the food category screen; they now open their own screens. My Bookings has a Gas filter.
| 31 Oct 2026 | Service quotes (`service/quote`) return `tax`, `tax_percent`, `total` (= subtotal + tax); courier quotes return `tax`, `total` (= fee + tax). Prices are tax-exclusive. | Show a Tax line and charge `total` on service and courier checkout (§6.27). |
| 31 Oct 2026 | **Payment methods on/off:** `GET customer/paymentMethods` → `payment_methods[]` with `enabled`. Admin can switch cash / online / wallet / Pay After Delivery off; the server refuses a disabled one (422 `payment_type_*`). | Load it on every checkout/booking screen and hide disabled methods (§6.30). |
| 31 Oct 2026 | **FAQ and policies:** `GET customer/getFaqs` (active FAQs + intro), `GET customer/getCancellationPolicy`, `GET customer/getRefundPolicy`. | Wire the Help / FAQ and policy screens to these (§6.32). |

### Update Required (Figma V2 Additions, 1 Nov) ✅
On start the app reads Admin → App versions (`GET customer/settings`: `play_store_version` / `app_store_version`, `…_update` = force, `…_link`) and compares with its own version (`package_info_plus`). Newer and forced → **Update SAIMPEX** screen that can't be left (`Get.offAll`, back disabled); newer, not forced → same screen with **Later**. "Update now" opens the store link (disabled while Admin hasn't set one). Files: `lib/core/update/app_update.dart`, `lib/views/update_required_screen.dart`. Bump `version:` in `pubspec.yaml` with each store release so this works.

### Server Down and Payment Failed (Figma V2 Additions, 1 Nov) ✅
- **Server Down** ("We'll be right back", `lib/views/server_down_screen.dart`): shown at start when Admin → Settings → Maintenance is on for this platform (`customer/settings` → `maintenance_android` / `maintenance_ios`, with the reason as the text), and whenever the server answers **503**. Retry checks again and closes the screen when the server is back.
- **Payment Failed** ("Payment not completed", `lib/views/payment_failed_screen.dart`): opens from the cart when Masrvi doesn't confirm. **Try again** restarts Masrvi for the same order; **Pay with cash instead** (hidden for prescription carts and pickup) and **Pay with Wallet** call `POST customer/orders/{id}/switchPayment` (API §6.59), then the success screen; Back leaves the order waiting for payment as before. The Figma note says 15 minutes, but the server's wait is configurable (default 30), so the text doesn't name a number.

### Gas Booking Details (Figma V2 Additions, 1 Nov) ✅
`lib/views/services/gas_booking_detail_screen.dart`, opened from My Bookings for gas (it used the home cleaning screen before). From `customer/service/booking`: booking number + status pill, supplier, slot; items ("2 × Butane refill 12 kg", subtotal) and **empty cylinders to hand over**; status steps Booked → Accepted by supplier → Driver on the way → Delivered, empties collected (with times from the timeline; Cancelled shows instead when cancelled); payment and total; **Chat with supplier** (vendor chat) and **Help** (Help sheet); Cancel while the booking can still be cancelled. The gas branches left in the home cleaning screen are no longer used for gas.

### Guest browsing fixed + release build (1 Nov, emulator Pixel 5 / Android 14, Arabic) ✅
- `MainShellScreen` no longer returns `LoginScreen` for guests; **Skip** on the slides and **Continue as guest** on Login both open Home. Logout and session expiry still open Login themselves.
- A guest's **background** loads that need an account (GET → `login_required`) fail quietly: no login sheet, no toast. **Actions** (non-GET) and the account tabs (Orders, Bookings, Chat, Profile) still show the **Log in to continue** sheet. This was the framework error behind the sheet on Home.
- **Version 2.0.0+100** (`pubspec.yaml`): V2 replaces V1 (`app.saimpex`) on the stores, so it must be above V1's 1.0.6; with 1.0.0 the Update screen blocked every build (dev Admin says 1.0.6, forced). **Check V1's last build number** before the Play upload; 100 must be higher.
- **Release build fixed:** `android/app/proguard-rules.pro` (`-dontwarn com.google.firebase.iid.FirebaseInstanceId`): ML Kit references the excluded firebase-iid and R8 stopped `flutter build apk --release`.
- Seen on the emulator: Arabic + Cairo + RTL on slides and Home; guest cart opens; Orders asks to log in. Not reached yet (needs a dev test number, `OTP_TEST_NUMBERS`): logged-in screens.

### Home cleaning ADD booked the previous service (`feature/home-cleaning-add-service`, 2 Nov) ✅
Found in the full test pass on the iOS simulator against dev (2 Nov). On a home cleaning provider, **ADD** on a service opened the configure screen without `selectService`, so the booking draft kept whatever service was picked before. Seen: after a laundry booking, the cart listed cleaning rooms (400 + 150 MRU) but showed **Pay 120 MRU**, because `service/quote` was sent as vertical laundry, vendor 72, item 21, 1 kg × 120. Tapping the card itself did select the service (home_cleaning, vendor 78, 1500 MRU).
- **Fix:** ADD and the card both call `_openService`, which runs `selectService(item)` and then opens the configure screen. Laundry, car wash and gas already selected the service on every tap.
- **Checked** (iOS simulator, dev, 2 Nov): ADD on laundry Express Wash & Iron, then ADD on Clean Home Nouakchott → Regular Clean (Apartment) → tomorrow 2–4 PM → the cart shows Total and Pay **1500 MRU** (home cleaning), not 120 MRU laundry. Stopped at Pay.

### Minimum order from the server (`fix/server-min-order`, 2 Nov) ✅
The cart blocked every order under a hard-coded 500 MRU (`cart_screen.dart`), so a 90 MRU water order asked for 410 MRU more and most water orders couldn't be placed; a store with a higher minimum got the server's 422 instead. The cart now reads `min_order_value` and `min_order_shortfall` from the checkout summary (classic and catalog, §6.22; see "Backend updates", 31 Oct). Place order shows the minimum-order sheet only while the shortfall is > 0, with the server's minimum and "add X MRU". If the summary didn't load, the order goes through and the server's 422 explains.
- **Checked** (iOS simulator, dev, 2 Nov): Pizzeria Atlantique (dev minimum is 150, not 500) with one Iced Tea (60) → server shortfall 90 → Pay shows "Minimum order: 150 MRU / Add 90 MRU more" and no checkout call is sent. One pizza (260) → shortfall 0, not blocked. Water 1.5 L pack (90 MRU) at Source Tevragh Zeina is no longer blocked; stopped at Pay.
- **Backend gap:** on dev, `checkoutSummaryV2` (classic carts: water, grocery, pharmacy, local store) returns no `min_order_value` / `min_order_shortfall`; only `catalog/checkoutSummary` does. Classic carts below a store's minimum get the server's 422 at checkout until the backend adds them.
- Not in this change: "Minimum order X MRU" on the store page (`restaurantDetails.min_order_value`).

### Water Subscribe opens the product's plans (`fix/water-subscribe-entry`, 2 Nov) ✅
Every way into a water store opens `WaterSupplierDetailsScreen`, whose Subscribe went to the general `WaterSubscriptionScreen`; its "Find a supplier" led back to the same store, so the plans screen (`WaterProductSubscriptionScreen`, P0-5 / C11) could not be reached. Subscribe on a product now opens `WaterProductSubscriptionScreen(product, supplier)`, as `WaterSupplierScreen` does.
- **Checked** (iOS simulator, dev, 2 Nov): Source Tevragh Zeina → 19 L Jug Refill and Aqua Ksar → 0.5 L pack: Subscribe opens the product's subscription screen and calls `water/plans?water_vendor_id=68` / `69` (200). Dev has **no plans** for either supplier (`data: []`), so the screen shows "This supplier has no subscription plans yet"; choosing a plan and paying could not be tried until dev has plans.

### Grocery home: fake "AI predictive" cards removed (`fix/hide-sample-ai-cards`, 2 Nov) ✅
Found in the French test pass on Android (2 Nov). The grocery home showed every customer a "SAIMPEX AI • PREDICTIVE" card ("Your weekly eggs order is due tomorrow… you saved 18%") and an "AI Tip: your usual milk + bread" row. Both were fixed text (`st_ai_*` in `l10n/areas/stores.dart`) and their Add buttons did nothing, which breaks the no-sample-content rule (P0-7). There is no prediction API, so both cards are removed from `grocery_screen.dart` until one exists.
- **Checked** (Android, dev, 2 Nov): Home → Grocery opens on the page title, search and categories with no AI cards.

### Order success: Back to home works after a cart-tab order (`fix/success-back-buttons`, 2 Nov) ✅
Found in the Arabic test pass on Android (2 Nov). An order placed from the bottom-bar Cart left the customer stuck on the success screen: the cart tab lives inside the shell, so `Get.off(OrderSuccessScreen)` replaced the shell, and "Back to home" popped to the first route, which was the success screen itself. "Back to home" and the top back button now call `BottomNavRouter.returnToShell(navHome)`, and "View order" opens the Orders tab the same way (it pushed a second My Orders screen above the stack), as the cancel and courier success screens already do.
- **Checked** (Android, dev, 2 Nov): cart tab → Pay → success → Back to home opens Home; again → View order opens the Orders tab.

### Store cards: distance, time, offer and points labels in AR/FR (`fix/store-card-labels`, 2 Nov) ✅
Found in the Arabic and French test passes on Android (2 Nov). Store and product cards built their labels in the models as fixed English ("1.2 Km", "9% OFF", "14 min", "0 Points Available"), and two models filled gaps with made-up values: grocery showed "200 Points Available" when the API sent no points, and food and grocery showed "30-35 min" when it sent no time. The labels now go through `lib/utils/store_labels.dart` (`core_unit_km`, `core_unit_min`, `core_percent_off`, `core_points_available` in EN/FR/AR), and the made-up values are gone (empty when the API sends nothing). The API also sends ready-made English texts (`delivery_time_text` "14-19 min", `distance` "1.2 Km", `offer_text` "9% OFF"); `localizedStoreText` rebuilds those plain forms in the app language and leaves any other text as sent (a translated API text is still the better fix: backend issue).
- **Checked** (Android, dev, 2 Nov): Home and Food store cards in Arabic and French show the translated units.

### My Orders: status chips in AR/FR (`fix/order-status-labels`, 2 Nov) ✅
Found in the Arabic test pass on Android (2 Nov). Food, grocery and water order cards showed the API's English `status_text` ("Placed", "Ready", "PLACED") in every language, while courier cards already translated the status code. The order lists send the code too (`status` 1–10), so the cards now show `core_status_N` through `lib/utils/order_status_label.dart` and keep the API text for anything else. Badge colours still follow the API text. Prescription cards keep their own statuses (not order codes).
- **Checked** (Android, dev, 2 Nov): Orders in Arabic shows the food, grocery and water chips in Arabic.

### Dead buttons wired or marked Coming soon (`fix/coming-soon-and-dead-buttons`, 2 Nov) ✅
Test-day sweep for buttons that did nothing (`onTap: () {}`) or showed a placeholder:
- **Track order** (food and grocery cards in My Orders) opened a sheet that only said "tracking fetched". It now opens the existing `TrackOrderScreen` (map, driver, status, help), which nothing linked to before. The placeholder `_TrackingSheet` is removed.
- **Help & Support:** Call now and Send mail open the phone and mail apps with the numbers from the API ("support contact not available" when empty).
- **Car wash booking detail:** Help opens the Help sheet with the booking code, like gas.
- **Cart:** Edit on the delivery address opens the location picker and re-prices the cart (summary and delivery check) after a change.
- **Reorder** on the Home and Grocery recent-order cards says "Coming soon": there is no reorder API.
Still open (not in this change): Gas has no entry point; paying the laundry balance after re-weighing waits on the backend (the button already says it isn't available yet).
- **Checked** (Android, dev, 2 Nov): Track order on a food order opens the tracking screen; Reorder shows Coming soon; analyzer clean, 22 tests pass.

### Client build polish: real wallet chips, water cart total, Coming soon for balance payment (`fix/client-build-polish`, 2 Nov) ✅
Before the client build (2 Nov):
- **Wallet chip (#31):** the Water, Express, Pharmacy and Local Store headers showed a fixed "300 MRU". They now show the customer's real SAIMPEX Wallet balance from `HomeController.walletLabel` (`lib/utils/wallet_chip.dart`), 0 MRU for guests, like the Grocery header.
- **Water cart bar (#32):** the bar showed the last added item's price (or a made-up "50 MRU"), not the cart. After each add it now reloads the server cart totals (`fetchCartTotals`) and shows the cart total.
- **Laundry balance after re-weighing:** paying it isn't in the API yet; the Pay button now says "Coming soon" like the other unfinished features (was "not available yet").
- **Checked** (Android, dev, 2 Nov): Water header shows the real balance; the water cart bar shows the cart total after adding two items.

### Device test pass, Arabic first (`feature/device-test-fixes`, [PR #36](https://github.com/sigosoft/Saimpex-V2/pull/36), 2 Nov) 🟡 in progress
Phone: vivo V2239, Android 15, debug build against dev, demo customer +222 95200003. Analyzer clean, 22 tests pass.
- **Fixed in this branch:**
  - Account: the phone number read "95200003 222+" in Arabic; it is now isolated left to right (+222 95200003), like the OTP screen.
  - Food menu: item ratings showed the API's raw "0.000000"; unrated items now show no rating, rated ones one decimal. The review count is a plain number (was English "12 reviews").
  - Food item sheets (`food_customize_sheet.dart`, `food_item_sheets.dart`): every item showed the same hard-coded "Slow-cooked Moroccan tagine…" description and a made-up 4.6 rating / "10k + reviews" when the API sent none. Now the item's own (translated) description and rating, hidden when empty.
  - Water product sheet and grocery product sheet: removed the made-up rating (4.6 / 4.5), "10k +" reviews, 50 / 100 MRU prices and default title/description.
  - Cart: "Balance: 1140 MRU" under SAIMPEX Wallet was English in FR/AR; new key `core_account_wallet_balance` (EN/FR/AR).
  - My Orders: store names were English in Arabic. The order lists (restaurant, grocery, local store, pharmacy, water) now send `language`, which the server needs to translate `vendor_name` (API change 2 Nov), and the restaurant card reads `vendor_name` first.
  - Home: the Trending and Under 30 minutes store cards did nothing when tapped; they now open the store (both sections are restaurants from `homeHub`), like the Food screen.
  - Order details: item and extra names were always English (`name_en`); now `name_<language>`, English when empty. The total said "Total paid" on unpaid cash orders; it now says "To pay" unless `payment_status` is 2 (paid).
  - Tracking: status chip and title were the server's English ("PLACED"); now the app's status texts (codes 1-10). The step time ("02 Nov 2026, 12:15 PM") was scrambled in Arabic ("Nov 2026, 12:15 02 PM"); it is now shown left to right.
- **Works (Arabic, RTL):** home, Food list, store menu, add to cart, cart totals from the server (260 + 50 delivery), Pay After Delivery blocked with "pay your previous order first", My Orders with Arabic statuses, language switch.
- **Open, not fixed:**
  - Currency: prices show "MRU" in most screens (built in about 20 places in the models) but "أوقية" in the cart totals, variants and Account card. Needs one decision (Praveen): MRU everywhere or the translated name everywhere.
  - More made-up fallbacks in grocery and water lists: rating 4.5 / 4.6, "Store", "Supermarket", "Hypermarket", "Recently", "15m", "30-35 min", "10 Km", "50% OFF" (`grocery_repository.dart`, `grocery_screen.dart`, `water_see_all_screen.dart`, `water_supplier_details_screen.dart`).
  - Fixed time texts not from the server: cart "Delivery 30-35 min", "Pickup ready in 15 min", cart bar "Ready in 15-20 min" (`core_restaurant_ready_in`), while the store says 14 min.
  - Dev server: `/storage/...` still answers 403 (`php artisan storage:link` not run); food item descriptions on dev are English only.
- **Orders placed on dev (2 Nov, demo customer +222 95200003):** ORD-001483 Pizzeria Atlantique, wallet, 310 MRU (wallet 1140 → 830, cart emptied, shows as paid); ORD-001484 same store, cash on delivery, 350 MRU (shows "to pay"). Both appear first in My Orders with details and tracking ("driver will be assigned soon"). Left open on dev; cancel them from the app if they get in the way.
- **Open, found while ordering:**
  - Order details and tracking show the store name in English: `catalog/orderDetail` (`CatalogOrderService::detail`, `v.name`) and `trackOrder` (`trackingVendor`, `vendor->name`) don't use `VendorName::of`. Backend issue to open (`[customer-app] order details and tracking: store name not translated`).
  - Backend `orderDetails` sends `payment_type` text "Online Payment" for every non-cash order, also wallet (3) and Pay After Delivery (4). The app doesn't show it today.
  - The success screen's "View order" opens My Orders, not that order.
  - The Pay button says "Pay 350 MRU" also for cash on delivery.
  - Tracking draws the rider icon on the store when no driver is assigned yet.
  - Seen once: a red debug error (`_dependents.isEmpty`) after tapping Orders → Track a few seconds after a relaunch; not reproduced with slower taps, no stack trace in logcat.
- **Not tested yet:** online payment (Masrvi), services, courier, pharmacy, water flows; French and English pass.

### Bottom bar: wave design, names under every item (`feature/nav-bar-polish`, [PR #38](https://github.com/sigosoft/Saimpex-V2/pull/38), merged 3 Nov) 🟡 needs Praveen's OK
**Not the Figma bar:** built from a reference picture chosen on 3 Nov (it replaced an earlier floating version, commit `7ea418f`). CLAUDE.md says Figma is the design, so Praveen should approve it, or ask for the Figma bar back (commit `255ee9f`: Figma shape with the same open-tab state and haptics).
- A full-width white bar on the bottom edge with a smooth dip around the raised Services button: solid orange disc in a pale orange ring (stronger when Services is open). Brand orange #FF5216 instead of the reference's red. Same total height as before, so screens' bottom spacing is unchanged.
- Each tab is an icon with its name under it, Services too (its name sits under the dip; English/French label now "Services", was "SERVICES"). The open tab's icon and name turn orange, the name bold. Before, no tab ever looked selected. Long names shrink to fit ("Réservations").
- Items press down on tap (`Pressable`, off with reduced motion). Haptics: light impact on a tab switch, medium on Services, a selection tick when re-tapping the open tab (Home still reloads). Names stay for screen readers (`Semantics`).
- **Checked** (vivo V2239, Android 15, dev, 3 Nov, English): Home, Orders and Services as the open tab, tab switching, the dip around the button; no error in a `flutter run` session; analyzer clean, 22 tests pass. Cart badge not seen (cart empty).
- **Seen three times, not from this change:** a red debug error (`_dependents.isEmpty`) on the first launch after installing an update (also on 2 Nov, before this change), once even after a force-stop; the next launch is fine. It did not happen under `flutter run`. No stack trace in logcat; needs `flutter run` to catch it.
- **To check, not from this change:** after installing this build the app came back in English although French was chosen before (language should persist, P1-1).

### Client build 3 Nov (`feature/client-build-3nov`) ✅
Release APK `2.0.0+100`, dev server, debug-signed (V1 keystore still missing, C19). Built from everything merged so far (PR #36 device test fixes, PR #38 bottom bar, PR #26 code boxes, PR #27 home titles) plus:
- **No invented values:** grocery, water, pharmacy and service screens no longer show made-up ratings (4.5/4.6), names ("Store", "Supermarket", "Hypermarket"), times ("15m", "30-35 min", "Ready in 15-20 min"), distances ("10 Km"), offers ("50% OFF"), points ("200 Points"), prices ("50 MRU", "— MRU", a lone "MRU") or "0 reviews"; the chip or line is hidden when the server sends nothing. The store cart bar shows the store's own delivery time.
- **Pharmacy cart bar:** showed "1" and the last item's price; now the server cart's count and total.
- **Cart button:** "Order now" for cash and Pay After Delivery (was "Pay 350 MRU").
- **My Bookings:** Completed and Cancelled in the app language (was the server's "CANCELLED").
- **Service providers:** "Open"/"Closed"/"Temporarily not accepting orders" and "1.4 km away" in the app language (server sends English).
- **Tracking:** no rider pin until the driver has a location; the store pin shows.
- **Bottom bar:** Arabic names at full size (label row taller for Cairo).
- **Payment failed:** Pending status in brand orange (last off-brand orange in `lib/`).
- **Coming soon** (unchanged, already in place): Reorder, laundry balance payment after re-weighing, call driver (masked calls), services without a vertical (plumbing, carpentry, electrical, …).
- **Checked** (vivo V2239, Android 15, release build, dev, 3 Nov): launch, Home, Bookings, Profile, language switch to Arabic and kept after reinstall, Home cleaning providers; analyzer clean, 27 tests pass. The red debug error does not occur in release builds (it is a debug-only assertion). Not checked in this build: online payment, courier, pharmacy order, water order.
- **Language reset (2 Nov note):** not reproduced; Arabic stayed after reinstalling.

### Retest 3 Nov: Sharvin's items (`feature/retest-3nov-fixes`) ✅
From `SAIMPEX-V2-retest-3nov.pdf` (retest of b662e01). Checked on vivo V2239, Android 15, debug build, dev, Arabic; analyzer clean, 29 tests pass.
- **C-B1 "Total paid" on an unpaid cash order:** already fixed by PR #36 (the retest build predates it); confirmed on ORD-001484: "To pay".
- **C-B2 Track Order:** fixed earlier (retest PASS).
- **C-B11 cancel always said "refunded":** the cancel screen now says "refunded to your wallet" only for paid orders, "Nothing was charged" for unpaid ones (cash, Pay After Delivery), and a careful text when the screen doesn't know (pharmacy, water, courier). Food and grocery details pass `payment_status`. Confirmed by cancelling test order ORD-001484 (cash).
- **C-B18 no delivery PIN for the customer:** tracking now shows `delivery_pin` in a "Delivery PIN" card ("give this code to the driver at the door") until the order is delivered or cancelled. Shared `TrackingSummary`, so food, grocery, pharmacy, water and courier tracking all show it. Confirmed: ORD-001484 shows 9956.
- **C-B9 raw time:** order details showed "2026-11-03 03:19:18"; now "03 Nov 2026, 03:19 AM" (month in the app language), like tracking. **Time zone not changed:** the server sends times without a zone (`APP_TIMEZONE`, default Asia/Kolkata in config). Mauritania is UTC, so if dev/live run UTC the times are right for customers; a tester in India sees UTC. Backend should send ISO 8601 with an offset if local conversion is wanted (issue to open).
- **C-B20 OTP boxes:** typing fast dropped digits (each box took one character, the next digit arrived before the focus moved) and a pasted/auto-filled code was lost. A box now takes several digits and spreads them over the next boxes; a full code fills all six. Resend already clears the boxes. Tests added (`test/otp_code_row_test.dart`).
- **C-B21 rated order still shows Rate:** the order lists have no "rated" flag. Rate now asks `GET customer/rating` first: if `vendor_rating` is set it says "You have already rated this order" and hides the button; rated orders are remembered on the phone (`lib/utils/rated_orders.dart`). **Backend issue to open:** add `is_rated` to the customer order lists so other phones hide the button without a tap. Not seen on the phone (no delivered order on the test account).
- **C-B19 new package name (`app.saimpex`, was `com.example.saimpex_v2`):** for Praveen to confirm before release (V1's id/keystore, C19). Testers must uninstall the old app.
- Map: no rider pin before the driver has a location (from the client build) also seen here.
- **Found while checking:** order details of a cancelled order still showed the steps at "placed" with Cancel and Track buttons (the list said Cancelled). It now says "Cancelled" and shows no buttons; delivered orders show no buttons either.
- **Cancelled order total:** says "Total" (was "To pay"). Not seen on the phone (it locked).
- **Language reset (3 Nov):** the phone had `app_language = en` saved while the login stayed, so the app wrote English itself. Could not reproduce: installing release over debug and over itself kept Arabic (screenshots at launch). Two paths could quietly set English and are closed: the language sheet started on English when the stored label didn't match (Continue then switched to English); now it starts on the current language by code. `AppLocale.codeFor` turned any unknown value into English; now it keeps the current language (`test/app_locale_test.dart`). Confirmed: Arabic kept after updating, the sheet opens on العربية. Watch for it in the next test round.

### Language pass AR/FR/EN on 24f42d1 (`fix/language-pass-3nov`, 3 Nov) ✅
All main screens checked in Arabic, French and English on the release build of 24f42d1 (vivo V2239, Android 15, dev): Home, Food list and store, Grocery, Pharmacy, Water, Courier, Express, Local Store, Services, Laundry, Orders, Bookings, Cart, Chat, Account, Settings, Wallet, Notifications. Fixed here:
- **Home / Grocery recent orders:** "1 Items" in English in every language and a raw date ("2026-11-02 12:22:12"); now the translated item count and "02 Nov 2026, 12:22 PM" with the month in the app language.
- **Item counts:** "1 items" / "1 articles"; a singular key (`orders_items_count_one`) now gives "1 item" / "1 article".
- **Notifications:** raw "2026-11-03 • 06:12:32"; now the same readable date.
- **Local Store cards:** rating "4.666667"; now "4.7" (`ratingLabel`).
- **Courier vehicles:** "— MRU" before pickup and drop-off are set; now empty until the fee is known.
- **Express stores:** the category chip used `name_en` ("Pharmacy" in Arabic/French); now `name_<language>`.
Helpers in `lib/utils/store_labels.dart` (`itemsCountLabel`, `ratingLabel`, `readableDateTime`, `localizedName`); test `test/store_labels_test.dart`.
**Open (not app code):** wallet history descriptions are English ("Order payment", "Service booking payment", "Admin adjustment: …") from the server; the French/Arabic notification for order #1440 says "a new order has been assigned to you" (the driver's text) while English says "assigned to delivery boy"; booking slot text ("03 Nov 2026, 8:00 AM – 10:00 AM") comes from the server in English; Home tile "Courrier" (French name from Admin, the courier screen says "Coursier"); water category names "Botttled" etc. from Admin; banner images contain English text. **Layout (P2):** pharmacy quick-category names overlap their images ("Vitamines et compléments", "Médicaments sur ordonnance"); French bottom bar shrinks "Réservations"/"Commandes" to a very small size.

### C-B19 app ID: decision needed from Praveen (3 Nov) 🟡
Facts checked 3 Nov:
- **Live V1 customer app:** Android `app.saimpex` on Google Play ("Saimpex", developer Sigosoft, 100+ installs, updated 11 Jun 2026, version 1.0.10 / versionCode 11 seen on a phone); iOS `app.saimpex` on the App Store ("Saimpex", seller Praveen S., version 1.1.0).
- **V2 today:** Android `applicationId = app.saimpex` (since C17, `0be0258`; Firebase `google-services.json` is registered for it), versionCode 100 (> 11), but signed with the **debug key**. iOS bundle is still the template `com.example.saimpexV2`, no `GoogleService-Info.plist`. Launcher name `saimpex_v2` (`AndroidManifest.xml`). The Kotlin package/namespace `com.example.saimpex_v2` is internal and can stay.
- `com.saimpex.customer` is taken on Google Play by another company (Apporio, "In time services"); the local `saimpex_customer` folder (`com.example.saimpex_customer`) is not the live app.
**Recommendation:** keep `app.saimpex` on both stores, so V2 ships as an update of V1 (same listing, installs, reviews; customers update instead of installing a second app). Needs: the V1 Android upload key (or a Play App Signing upload-key reset from Play Console), iOS bundle `app.saimpex` with V1's Apple account/certificates and a version above 1.1.0, `GoogleService-Info.plist` for `app.saimpex`. Alternative (new ID, e.g. `app.saimpex.customer`): new listings, V1 users must install again, new Firebase apps; only if V1's keys are lost.
**After the decision (app side, small):** iOS bundle ID, launcher name "Saimpex", release signing from `key.properties` outside git (C19). Testers with a debug V2 build must uninstall it before a release-signed build.

### C-B23: cancelled orders show why (`feature/cancel-reason`, 3 Nov) 🟡 backend part open
Journey E2E-15a (PDF "SAIMPEX V2 journeys, 3 Nov afternoon"): a vendor-rejected order showed only "Cancelled". Cancelled food, grocery, pharmacy, water and courier order details now show "Reason: …" under the status. The reason comes from the remark of the `status: 10` entry in `customer/orderDetails` `timeline[]` (documented). The food detail, whose `catalog/orderDetail` has no timeline, loads it with one extra call, and only for cancelled orders.
- A reason Admin typed is shown as written (ORD-001493 "Customer unreachable").
- Fixed server remarks are shown in EN/FR/AR: "Order Cancelled by Vendor/pharmacy/water vendor" → "Cancelled by the store"; "Not accepted by vendor within 24 hours" → "The store didn't accept the order in time".
- The customer's own cancel ("Order Cancelled") shows no note.
- Also: cancelled water, courier and pharmacy order details said "To Pay"/"Total paid"; they now say "Total", like food (`3fadd97`).
- Checked on the phone (English, 3 Nov): ORD-001461 food and ORD-001477 water show "Reason: The store didn't accept the order in time"; ORD-001484 (own cancel) shows no note.
- Also: order step times ("03 Nov 2026 10:00 AM" from the server) were English in FR/AR and jumbled in Arabic; `OrderTracking.timeOf`/`placedAt` now go through `readableServerTime` (month in the app language), so every order detail and tracking screen shows "03 nov. 2026, 10:00 AM" / "03 نوفمبر 2026، …".
- Checked on the phone in Arabic and French too: ORD-001461 and ORD-001480 (food, both auto-cancelled after 24 h) and ORD-001477 (water) show the reason note, "Total", and localized step dates.
- Code: `lib/utils/cancel_reason.dart`, `OrderTracking.cancelReason`, `lib/widgets/cancel_reason_note.dart`; tests in `test/cancel_reason_test.dart`.
**Open (backend + vendor app):** the vendor app sends no reason on reject (`cancelRestaurantOrder?order_id=` only), and the backend saves a fixed "Order Cancelled by Vendor", so "Out of Stock" can't reach the customer yet. Issue `[customer-app] Vendor reject reason is never saved…` for Praveen. It will show with no app change once the remark carries the reason. Service bookings (car wash, laundry) aren't covered, because their timeline has no documented `remark`.

### P2 layout: pharmacy category names, French bottom bar (`fix/p2-layout`, 3 Nov) ✅
- **Pharmacy quick categories:** names ran into the pictures (Cairo, the Arabic font, is taller than the 22 px left under the picture; long names wrapped). The name is now one line at a fixed height (ellipsis if too long), the picture stops 26 px above the tile bottom, and Admin's photos get rounded corners. The pop-out tile style (as on home) is kept.
- **Bottom bar in French:** every side item had an equal slot (~46 dp on a 412 dp phone), so "Réservations" and "Commandes" shrank to ~7 px. Each slot now takes the width its name needs, but never less than 52 dp, so English and Arabic keep equal slots; in French "Réservations", "Commandes" and "Discussion" now render at about 9 px (was about 7 px), the rest at full size. Services slot unchanged.
- Checked on the phone 3 Nov: pharmacy categories in Arabic (names clear of the pictures), bottom bar in AR, FR and EN.

### Home grid without Services, one icon weight in the bottom bar (`fix/home-grid-nav-weight`, 3 Nov) ✅
- **Home banner above the search bar:** comes only from Admin sliders of type **0 "Home"** (`SliderTypes::HOME`, active). Dev has none, so `homeHub` returns `sliders: []` and the carousel hides itself; vertical screens show their own slider types. No app change: Admin needs to add a Home slider (Admin → Sliders).
- **Home categories:** the Services tile is gone (the grid ends at Local Store); Services opens from the bottom bar's Services button.
- **Bottom-bar icon weight:** Orders, Cart and Profile are drawn at about 10 % of the icon size, Home was 6.6 %, Bookings and Chat 7.5 %. `Bottom Home.png` was thickened to Orders' weight (9 px dilation at 512 px, same shape) and the drawn icons use 10.2 %. Measured on the phone: every icon about 6 px.

### Delivery location from Home, Gas entry, courier offers (`fix/courier-offers-gas-entry`, 3 Nov) ✅
Checked on the phone (dev, English).
- **Change location from Home:** tapping "Deliver To ⌄" opens the picker. Fixed four problems there:
  - The picker re-created its controller on every rebuild, so after the keyboard opened, a picked place changed only the label; the map and pin stayed put. The controller now lives for the screen's whole life.
  - Continue saved the location but only closed the "Location updated" snackbar (`Get.back()` closes a snackbar first), so the picker stayed open. It now leaves first, then shows the toast.
  - "Current Location" covered the search suggestions. It now shows only at the bottom of the map and is hidden while suggestions are open. The keyboard no longer squeezes the map.
  - Search is limited to Mauritania (`components=country:mr`).
  - Result: picking "Las Palmas, Nouakchott" → Continue → Home shows "Las Palmas, Nou…" and reloads stores for that place.
- **Gas:** new tile in Services → All Service Categories (cylinder icon until there's artwork) → gas suppliers list from the API. Hidden when Admin switches gas off.
- **Courier offers:** the two sample "30% OFF" banners are hidden (the quote never applied a discount). They come back when the API sends courier sliders: [praveensigo/saimpex-backend-new#164](https://github.com/praveensigo/saimpex-backend-new/issues/164).
- **C-B23 backend is live on dev:** `orderDetails` returns `cancel_reason`, `cancelled_by`, `cancel_message`.

### Test report 4 Nov: Sharvin's open items (`fix/test-report-4nov`, [PR #44](https://github.com/sigosoft/Saimpex-V2/pull/44)) ✅
From `SAIMPEX-V2-full-report-4nov.pdf` (gas excluded). Analyzer clean, 38 tests pass (`test/test_report_4nov_test.dart`). Checked on vivo V2239, Android 15, debug build, dev, English, as test customer 95200021.
- **C-B25 delivered laundry still "Pay 120 MRU":** dev returns ORD-001499 as `status 9` "Delivered" (the "Waiting for Pickup" was the server's status at test time) with `additional_payment: 120` but `additional_payment_pending: false` (backend B-12). The app showed the balance from `additional_payment` alone. My Bookings and the laundry booking detail now hide the balance and Pay when the server says nothing is pending. **Phone:** LNX5TVFV shows Completed, 300 MRU, no Pay button.
- **C-B26 self-pickup shows "Delivered":** a finished self-pickup order now says "Picked up" / "Retirée" / "تم الاستلام" (`core_status_9_pickup`) in the order detail stepper, tracking, and the food, grocery and water order lists. **Phone:** ORD-001505 details show "Self Pickup … Picked up". The My Orders card still says "Delivery · Delivered", because `orders/restaurant`, `groceryOrdersList` and `waterOrdersList` don't send `is_self_pickup`; the app already reads it. **Pickup code:** the backend has none (`delivery_pin` is null for self-pickup by design), and the scope doesn't define one, so this needs a product decision. Both are in [praveensigo/saimpex-backend-new#166](https://github.com/praveensigo/saimpex-backend-new/issues/166).
- **C-B22 delivery address switched to the phone's GPS (India):** after every login the location picker opens in first-setup mode and moves to the phone's GPS; Continue then saved India to the profile. A GPS position outside Mauritania is now ignored ("SAIMPEX delivers in Mauritania only…", EN/FR/AR) and the picker stays on the saved spot (or Nouakchott); Continue refuses a spot outside Mauritania. **Phone (in India, location allowed):** after login the picker stayed on La Capitale, Nouakchott; Current Location showed the message and didn't move. 95200021's profile address is Nouakchott again on dev.
- **C-B3 wallet chosen at 0 MRU:** with an empty wallet the cart starts on Cash (Online when cash isn't offered); an empty wallet is the last fallback.
- **C-B4 "Pay 600 MRU" for cash:** already fixed in the 3 Nov client build ("Order now" for cash and Pay After Delivery).
- **C-B5 / C-B6 confirmation:** the success screen shows "Order ORD-… · 350 MRU", and View order opens that order's details (food: food detail; other carts: the shared detail) on top of My Orders.
- **C-B8 payment method in order details:** the food order detail shows a "Payment method" row (Cash on Delivery, Online payment, SAIMPEX Wallet, Pay After Delivery) from the numeric `payment_type`.
- **C-B12 / C-B13 after cancelling:** the "order cancelled" toast is gone (the cancelled screen says it), so it no longer covers Back to Home; errors still show a toast.
- **C-B14 distance:** Home showed the raw `distance_km` ("3.88 km") while lists round to one decimal; Home rounds now too. A 3.0 vs 3.7 gap can only come from the server (different coordinates per endpoint), not checked.
- **C-B16 "Reviews are not available here" after rating:** without a store to show, rating now goes back to the list instead of opening an empty reviews screen.
- **C-B17 rating tags in the comment:** needs an API field first: [praveensigo/saimpex-backend-new#167](https://github.com/praveensigo/saimpex-backend-new/issues/167).
- **C-B21 Rate on rated orders:** app part done 3 Nov; backend flag asked for in [praveensigo/saimpex-backend-new#165](https://github.com/praveensigo/saimpex-backend-new/issues/165) (`is_rated` on order lists and `orderDetails`).
- **C-B24 laundry balance payment:** still waits on [praveensigo/saimpex-backend-new#163](https://github.com/praveensigo/saimpex-backend-new/issues/163); the button stays "Coming soon".
- **C-B19 app ID:** decision with Praveen (section above).
- **Phone (4 Nov afternoon, test cash order ORD-001520 at Pizzeria Atlantique, then cancelled):**
  - C-B4: Cash shows "Order Now".
  - C-B5: success screen reads "Order ORD-001520 · 230 MRU".
  - C-B6: View Order opened ORD-001520's details.
  - C-B8: "Payment method: Cash on Delivery" (and "SAIMPEX Wallet" on ORD-001505).
  - C-B13: no toast on the cancelled screen. C-B12: Back to Home went straight to Home.
  - C-B14: Home cards show "2.1 Km", "3.1 Km".
  - C-B3: the wallet had 490 MRU, so the empty-wallet default couldn't be shown; Wallet was the default as expected.
- **C-B16 found broken on the phone and fixed:** rating ORD-001514 saved ("Rating submitted successfully" in the log), but the form stayed open, because the success toast opened first and `Get.back()` then only closed the toast; a second tap said "You already submitted rating". The form now leaves first, then shows the toast. **Rechecked on the phone (b0c0acd):** one Submit on ORD-001505 saved the rating, returned to My Orders with "Rating submitted successfully", and the Rate button is gone.
- **Cart bar "1 items":** "View Cart • 1 items" on restaurant, pharmacy and water cart bars now uses the singular/plural helper ("1 item", "1 article"). **Phone:** Pizzeria Atlantique shows "View Cart • 1 item".
- **Home store cards opened the restaurant screen for every section:** "Top Rated Suppliers" (water) showed "Chat with Restaurant" and "No items available" (Source Tevragh Zeina). Home now opens grocery cards in the grocery store screen, pharmacy cards in the pharmacy screen and water cards in the water supplier screen (`homeHub` sends the vendor id as `id` for every section). Analyzer clean, 38 tests pass. **Phone (0e59560):** Source Tevragh Zeina opens the water supplier screen with its products, Pharmacie Nour the pharmacy screen, Alimentation Tevragh Zeina the grocery store screen.
- **C-B14, server part (seen on the phone):** Home cards and store screens show different distances for the same store: Alimentation Tevragh Zeina "3.4 Km" on Home vs "3.09 Km" in the store, Pharmacie Nour "2.2 Km" vs "1.2 Km". Home shows `homeHub`'s `distance_km`; the store screens use their own endpoints. Needs the backend to use one point for both. The grocery store screen now shows one decimal from `distance_km` too.
- **Home → Recent Orders cards were blank (no picture, no store name):** `homeHub` sends `vendor_name_<lang>`, `vendor_image` and `items_summary_<lang>`; the app read `name_<lang>`, `image` and `item_name`. The cards now show the store name, logo and items.
- **Rating a self-pickup order asked to rate the delivery:** Rate now asks `orderDetails` for `is_self_pickup` (the order lists don't send it yet, backend #166) and hides the delivery card for self-pickup orders, so no driver rating is sent.
- These three fixes: analyzer clean, 38 tests pass. **Phone (88c1ada):**
  - Recent Orders shows "Eau Pure Arafat" with its logo, "19 L Jug Refill + Mineral Water…", 3 items, and "Pizzeria Atlantique, Caesar…".
  - Alimentation Tevragh Zeina shows "3.1 Km" (was "3.09 Km").
  - Rate on delivery order ORD-001512 calls `orderDetails` and still shows the delivery card (closed without submitting).
  - The self-pickup case couldn't be shown: the only delivered self-pickup order on 95200021 (ORD-001505) is already rated.
- **Test data left on dev:** ORD-001520 (cash, cancelled); 5-star ratings on ORD-001514 and ORD-001505.
- **Still to retest:** C-B10, C-B23 (fix pushed earlier).

### AI assistant: consent before the first message (`feature/ai-assistant-consent`, [PR #46](https://github.com/sigosoft/Saimpex-V2/pull/46)) ✅
Store release checklist: before the first message, say who processes it (Anthropic Claude) and ask for consent (Apple requires disclosure and consent before personal data goes to a third-party AI). No Figma screen, so it's built in the chat screen's own style.
- Until the customer agrees, the chat screen shows "Before you chat" instead of the chat: the assistant is an AI answered by Claude (Anthropic) through SAIMPEX; it uses their messages and voice transcripts, delivery location, and SAIMPEX orders, wallet and points; don't share passwords, card numbers, codes or health details; AI answers can be wrong. "Read the privacy policy" opens the Admin privacy page. "I agree, start chatting" shows the chat; "Not now" closes the screen.
- Nothing is sent before consent: the input bar, voice input, quick actions and history button are hidden or disabled, and `_sendMessage` refuses.
- Texts follow the chat language picked on the welcome sheet (EN/FR/AR, `core_chatbot_consent_*`).
- Consent is kept on the phone (`lib/utils/ai_assistant_consent.dart`, `ai_assistant_consent_v1`): the API has no consent field, so a new phone or a reinstall asks again. If the backend should record consent (date, version), that needs a new field.
- Analyzer clean, 39 tests pass (`test/ai_assistant_consent_test.dart`).
- **Phone (vivo V2239, dev, first build):** the notice shows in English and Arabic; "Read the privacy policy" opens the privacy page; no input bar before consent.
- **Fixed after the phone check:**
  - Arabic was laid out left to right when the app itself is in English, and lines starting with "SAIMPEX" came out in the wrong order. The notice now follows the chat language's direction.
  - The history button showed (disabled) before consent; it's hidden now.
  - **Header title "Saimpex Ai" was covered** by the history and language buttons on every chat screen (it was centred on a layer of its own). The header is now one row: back, title centred in the space left (shortened with "…" if needed), history, language.
  - **Phone (bc3a3aa):**
    - Arabic notice reads right to left, and lines starting with "SAIMPEX" are in order.
    - The header shows the full "Saimpex Ai" title clear of the buttons, before and after consent.
    - No history button before consent.
    - "Not now" returns to Home with no `chatbot/message` request.
    - "I agree" opens the chat; "Hello" was sent.
    - After a full app restart the assistant opens straight on the chat (consent remembered).
- **Dev has no assistant configured:** `chatbot/message` returns 503 "The assistant is not configured yet" (no Anthropic API key in Admin → Integrations; waiting on Praveen). The app shows that message in the chat. A real reply hasn't been seen yet.
- **Noticed, not changed:**
  - The Admin privacy policy text doesn't mention the AI assistant or Anthropic; the store checklist asks for that (Admin → CMS).
  - When the floating assistant head is resting (5 s after Home opens), the first tap only wakes it and a second tap opens it; customers may think the first tap did nothing.

### Water test report 5 Nov: Sharvin's items (`fix/water-test-report`, [PR #47](https://github.com/sigosoft/Saimpex-V2/pull/47)) 🟡 partly checked on the phone
From `SAIMPEX-V2-water-test-report.pdf` (customer main 703f82e). Analyzer clean, 39 tests pass.
- **W-05 subscriptions a dead end:** SUBSCRIBE now shows only on products whose supplier has an active plan for that product (`WaterRepository.planProductIds`, cached per supplier), on both supplier screens. The top banner ("Set Up Plan") opens the subscription page like the mid-page banner; "Explore Plans" → "Find supplier" was already there. "Late night" was already shown translated (the English value is only what's sent to the server). **Data:** Eau Pure Arafat now has plans #1 (weekly) and #2 (every 30 days) for Mineral Water 0.5 L (added 5 Nov); the Admin plan form has no Product field, so plans made there don't attach to a product (Kiran).
- **W-06 water search did nothing:** Enter in the water home search runs `waterSearchV2` and lists the matching suppliers, then products; "No results" otherwise.
- **W-09 "Total Paid" on an unpaid cash water order:** "View Order" on the success screen opened the shared grocery/pharmacy detail for every non-food order (from C-B6). It now asks `orderDetails` for `order_type` and opens the water order detail (which already says "To pay") for water. The shared detail also said "Total Paid" for every delivery order and showed "Redeemed points –" with none: cash is "To pay" until delivered, and the points row shows only when points were used (grocery too).
- **W-08 quantity limit:** at the limit, + now says "You can order up to N of this item." (EN/FR/AR) instead of doing nothing. **Backend:** `cart/water/add` allows 10, `cart/update` 5, item detail says 10; one limit is needed (Praveen).
- **W-10 unfinished cards:** the empty orange offer pill and the bare coin badge are hidden when there's no offer or points (the rating moves to the corner); "See All" suppliers showed the blue water-drop placeholder because the photo URL was loaded as an asset, now loaded from the network. **Not changed:** "0.0 · 0 reviews", stock photos and the "Water Jugs" picture are dev data; long names cut to one line ("Mineral Water 0.5 L (P…") is the fixed-height card from Figma.
- **W-11 Popular Products from one supplier:** server side: `waterHome` `popular_products` returns only Source Tevragh Zeina (68) and Test Water (43) items; the app shows what it gets (Praveen).
- **W-12 step times:** waits on the order-time decision (V-B9 / D-B10); no app change.
- **Phone (vivo V2239, dev, 2beee42):**
  - Water home supplier cards show only the rating (no empty pill or coin).
  - The "Set Up Plan" banner opens the Subscription page.
  - Searching "Arafat" lists Eau Pure Arafat, then its products, with photos.
  - On Eau Pure Arafat only Mineral Water 0.5 L shows SUBSCRIBE; the other four show a full-width ADD.
  - **Not seen on the phone:** W-09 (needs a new water order) and the W-08 limit message (needs the cart at its limit).
- **W-09 on the phone:** test cash order ORD-001532 at Eau Pure Arafat (Water 5 L + 19 L Jug Refill, 125 + 50 = 175 MRU). View Order opened the water order detail: "Payment: Cash", "To Pay 175 MRU", no empty points row. The order was cancelled afterwards.
- **Found while testing (not fixed here):**
  - **Water minimum order not shown before checkout:** Eau Pure Arafat has a 50 MRU minimum. A 45 MRU cart was refused at checkout with "Minimum order for this store is 50 MRU. Add 5 MRU more…", but the water cart summary (`checkoutSummaryV2`) has no `min_order_value` / `min_order_shortfall` (other carts do), so the app can't warn earlier (backend, Praveen).
  - **Order success screen for a water order shows "175 MRU" without the order code:** `checkoutV2` doesn't return `order_code` for this order; the app shows the code only when it gets one.

### Customer app test report 5 Nov: Sharvin's items (`fix/customer-test-report-5nov`, [PR #48](https://github.com/sigosoft/Saimpex-V2/pull/48)) ✅ checked on the phone (main items)
From `SAIMPEX-V2-customer-app-test-report.md` (main 703f82e). Backend c8f8e30 (live on dev) added prescription cancel, rating tags, store AR/FR names on the rating, variant labels and wallet titles. Analyzer clean, 39 tests pass.

**P1**
- **CA-19 Help on an order:** with no support numbers in Admin it only toasted; pharmacy/grocery Help showed a fake "Help center opened". The Help sheet now always offers **Message SAIMPEX support** for that order (`replySupportMessage`, opens the support thread), plus WhatsApp/Call when Admin → Branding has them. Admin should still fill `support_phone` / `support_whatsapp` (Kiran/Sajin).
- **CA-30 prescription Cancel:** the success screen's Cancel reopened the filled form. It now confirms and calls `POST prescription/{id}/cancel`; the upload screen is replaced by the success screen so Back doesn't reopen the form.

**P2 fixed in the app**
- CA-01 Android label "Saimpex" (permission prompts). CA-02 notification permission asked after login, not on the first screen. CA-03 onboarding shows the bundled image until the server's loads (no black half). CA-05 a guest is asked to log in before the wallet. CA-06 OTP boxes cleared after a wrong code. CA-07 the location subtitle is hidden when it repeats the title.
- CA-08 food item prices use the app's MRU format. CA-18 order progress line follows the real step. CA-20 "Late night" slot shows 10 PM–12 AM (EN/FR/AR).
- CA-22 rating form names the store and the driver. CA-23 tags go in `vendor_tags` / `driver_tags` (English text). CA-26 variants and cart lines show `variant_label` ("Size: 1 kg"). CA-40 wallet history shows the translated title that names the order.
- CA-27 grocery "Delivery in 15 minutes" reads `delivery_15_minutes`. CA-28 no empty Smart Bundles block. CA-29 no faded duplicate car on the Car Wash card.
- CA-34 prescription contact prefilled with the customer's number. CA-36 prescription progress line not half-filled. CA-15/CA-35 the scanner has a close button and a hint; if the in-app camera can't start, the shutter opens the phone's camera app (the black preview wasn't reproduced in code).
- CA-37 courier vehicles say "Set both addresses" before a price exists. CA-38 recipient phone digits only, 8 digits for +222, message on errors. CA-39 courier package size (Small/Medium/Large, re-quoted price) and description, sent to `courier/create`; no Figma screen, built in the screen's card style.
- CA-41 favourites card labels in the app language. CA-43 the address chosen at login is added to Saved addresses (once, if not already there). CA-46 Account shows the installed version. CA-47 tapping a language applies it.
- CA-14 search product rows use the store's AR/FR name once the API sends it.

**Waiting on the backend** ([praveensigo/saimpex-backend-new#177](https://github.com/praveensigo/saimpex-backend-new/issues/177), [#178](https://github.com/praveensigo/saimpex-backend-new/issues/178))
- CA-21 cancel reason: `cancelOrder` has no reason field (#177); the sheet's reason and an "Other" text box follow once documented.
- CA-10 tapping a notification: the list has no `order_id` / `type` (#178). CA-14 store AR/FR names in search (#178). CA-25 minimum order before checkout: `checkoutSummaryV2` has no `min_order_*` (#178; the cart already shows the reminder when it does). CA-27 grocery recent orders (#178). CA-22 store AR/FR name on the rating (#178).

**Not changed, and why**
- CA-04 onboarding page 3 "PREMIUM50" coupon and CA-32 English pharmacy/courier banners are text inside the Figma images: needs per-language artwork (designer) or Admin sliders, or create the PREMIUM50 coupon in Admin.
- CA-17 "Specify quantity here" box under the cart stepper has been there since the first build from the design; left until checked against Figma.
- CA-16 payment switching to Pay After Delivery after a coupon: no code path selects it on its own. Likely cause: the Pay After Delivery card appears above the others when its status loads, so a tap lands on it. Needs a repro on the phone.
- CA-44 chat bubbles on one side: the code decides "mine" from `is_mine` / `sender_type`; needs the tested conversation's response to find the cause.
- CA-45 French bottom bar: still tight with "Réservations" / "Commandes" (improved 3 Nov); needs shorter French labels from the design.
- Dev data / Admin: CA-09, CA-31, CA-33 test stores, duplicate categories (Sajin); CA-42 privacy policy text (Kiran/Praveen).
- **Phone (vivo V2239, dev, debug build of 795f022, 6 Nov):**
  - CA-19: Help on ORD-001542 opens "Need help?" with "Message SAIMPEX support"; the thread opens with a reply box (nothing sent). WhatsApp/Call stay hidden because dev has no numbers.
  - CA-18: the line stops at the order's step.
  - CA-46: Profile shows "V2.0.0".
  - CA-47: one tap on Français switched the app (switched back to English).
  - CA-37/38/39:
    - Courier vehicles say "Set both addresses", then 227 / 341 MRU.
    - The Package card shows; Large re-quoted to 427 MRU.
    - "Test9520" in the recipient phone kept only 9520, and Confirm said "Enter a valid phone number for the recipient (8 digits)" (nothing booked).
  - CA-34: prescription contact prefilled 95200021.
  - CA-01: the Android camera prompt says "Allow Saimpex…".
  - CA-15: the scanner shows the close button and the hint.
  - CA-35: the preview works once camera permission is granted (black before the prompt), so the report's black camera was likely the missing permission.
  - CA-36: only "Prescription Sent" is orange.
  - CA-30: prescription #20 sent to Test Pharmacy, then Cancel → "Cancel request" → server `status: cancelled`, back on Pharmacy (not the form).
  - Not seen on the phone: CA-02, 03, 05, 06, 07, 08, 20, 22, 23, 26, 27, 28, 29, 40, 41, 43. CA-16 not reproduced (needs a cart and a valid coupon; someone was placing orders on 95200021 at the time).
- **Debug-only red screen** (`_dependents.isEmpty`) seen twice: right after installing over a running app, and once on returning to the app. Same as the earlier notes above; restart clears it, and it hasn't been seen in release builds.
- **Test data left on dev:** prescription #20 (cancelled), at Test Pharmacy.
- **Follow-up (6 Nov evening):**
  - **CA-16 payment switching to Pay After Delivery:** no code path selects it on its own. The Pay After Delivery card is added above Wallet when its status loads, which pushed every card down; a tap meant for Wallet then picked Pay After Delivery. The card's place is now reserved while it loads, so nothing moves. Not reproduced on the phone: dev has no coupons for 95200021 (`customer/coupons` is empty) and the phone was in use.
  - **CA-44 chat bubbles on one side:** not a bug. The Eau Pure Arafat conversation (id 100) has 3 messages, all `sender_type: customer`; the store never replied, so every bubble is the customer's.
  - **CA-17 "Specify quantity here":** it is in the original design conversion of the cart (first commit, "Customize your quantity here"), so it comes from Figma. Left for a design decision.
  - **CA-45 French bottom bar:** needs shorter French labels from the design team ("Réservations", "Commandes"); not changed here.
  - Backend #177 / #178 not done yet (checked 6 Nov), so CA-10, 14, 21, 25, 27 (recent orders) still wait. CA-22 store AR/FR name is done: backend `c8f8e30` sends `vendor.name_ar` / `name_fr` on the rating form and the app already reads them.
- **Phone check, 6 Nov late (release build, V2239, 95200021, French):** CA-08 food prices "260 MRU" ✅; CA-27 "15-Min Delivery" lists stores ✅; CA-28 no Smart Bundles block ✅; CA-29 one car on the Lavage auto card ✅; CA-40 wallet history "Payment for order ORD-001539" / "Refund…" ✅; CA-41 favourites card "Restauration" ✅; CA-47 one tap on Français switches ✅. CA-26 not seen (the opened grocery item has no variants). Stopped there: the phone was needed for other work.
- **Found on the phone and fixed (same branch):**
  - **Pharmacy orders in French/Arabic showed "Cancelled" in English**, and cancelled orders and requests still had a **Cancel** button. `customer/orders/pharmacy` sends English `status_text`; the badge now comes from the codes (order `status` 1–10 through `orderStatusLabel`, request `prescription_status` through the `pw_*` keys). Cancel shows only while it's allowed: orders until delivered or cancelled, requests while `uploaded` / `under_review` / `reviewed` / `quoted` (the states `prescription/{id}/cancel` accepts).
  - **Cancel on a prescription request (no order yet) opened the order cancel sheet with no order id.** It now confirms and calls `POST prescription/{id}/cancel`, then reloads the list. Cancelling a pharmacy order also reloads the list now.
  - **The prescription row showed the stored file's random name** ("qf0YEePBZgCjQRi0…"); it now says "Prescription" (EN/FR/AR).
  - **Water orders:** delivered orders no longer offer "Track order" (same as food and grocery); the list shows "ORD-001521", not "#ORD-001521".
  - Not checked on the phone yet (built and installed; the phone was taken before the Orders tab opened).
- **Noticed, not changed:** the same store shows different distances on Home (2.1 Km), Favourites (1.2 km) and the store page (1.7 km), and "Km" vs "km". The distances come from different endpoints; worth one backend rule. Food orders in "Ready" still show Cancel (existing rule, not checked against the scope).
