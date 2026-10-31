# SAIMPEX V2 — Development Handoff

Last updated: 30 October 2026. This document records the state of the SAIMPEX V2 work so it can continue on another machine: what was audited, what was fixed and where, what is still pending, and what has to happen before release.

> **Nothing below is merged or deployed.** Every change is on a pushed branch, waiting for review. **None of it has been run on a device or server** yet: Flutter apps were only checked with `flutter analyze`; PHP and Node were not installed on the development machine, so the backend and Vue changes are unverified.

---

## Contents

1. [Projects, repositories and servers](#1-projects-repositories-and-servers)
2. [Setting up on a new machine](#2-setting-up-on-a-new-machine)
3. [Pushed branches (review and merge)](#3-pushed-branches-review-and-merge)
4. [Security issues found and fixed](#4-security-issues-found-and-fixed)
5. [What was fixed, per app](#5-what-was-fixed-per-app)
6. [Pending development](#6-pending-development)
7. [Decisions needed](#7-decisions-needed)
8. [Deployment and release checklist](#8-deployment-and-release-checklist)
9. [Known issues found but not changed](#9-known-issues-found-but-not-changed)
10. [Reference links](#10-reference-links)

---

## 1. Projects, repositories and servers

### Repositories

| App | Tech | Repository | Default branch | Local path (original machine) |
|---|---|---|---|---|
| Customer app (V2) | Flutter | https://github.com/sigosoft/Saimpex-V2 | `main` | `D:\sigosoft\Saimpex-V2` |
| Vendor Android app | Flutter | https://github.com/sigosoft/Saimpex_vendor-App | `main` | `D:\sigosoft\Saimpex_vendor-App` |
| Delivery (driver) app | Flutter | https://github.com/sigosoft/Saimpex-Delivery | `master` | `D:\sigosoft\Saimpex-Delivery` |
| Kitchen app | Flutter | https://github.com/sigosoft/Saimpex-Kitchen-App | `master` | `D:\sigosoft\Saimpex-Kitchen-App` |
| Backend API | Laravel (PHP) | https://github.com/praveensigo/saimpex-backend-new | `main` | `D:\sigosoft\saimpex-backend-new` |
| Admin web panel | Vue 3 / Vite (Vuexy) | https://github.com/praveensigo/saimpex-admin-phase2 | `main` | `D:\sigosoft\saimpex-admin-phase2` |
| Vendor web panel | Vue 3 / Vite (Vuexy) | https://github.com/praveensigo/saimpex-vendor-phase2 | `main` | `D:\sigosoft\saimpex-vendor-phase2` |

The `praveensigo/*` repositories are private; the GitHub account `sharvin-sigosoft` was added as a collaborator.

### Servers

| Server | URL | Notes |
|---|---|---|
| **V2 target (dev)** | `https://dev.saimpexenterprise.com/api/` | Agreed V2 server. Customer and vendor apps already point here. |
| Live (V1) | `https://api.saimpexenterprise.com/api/` | Does **not** have the V2 endpoints (e.g. `customer/serviceHome` returns 404). |
| Media | `https://dev.saimpexenterprise.com/storage/` | |
| Admin panel (shared) | https://ourworks.co.in/saimpex-admin/ | |

API route files in the backend: `routes/customer.php` (`/api/customer/*`), `routes/vendorapp.php` (`/api/vendorapp/*`, vendor Android), `routes/vendor.php` (`/api/vendor/*`, vendor web), `routes/delivery.php`, `routes/kitchen.php`, `routes/desktop.php`, and `routes/api.php` (admin, no prefix). Customer API reference: `docs/SAIMPEX_V2_CUSTOMER_API.md` in the backend repo.

### Scope

The agreed scope is **`Saimpex_V2_Team_Scope.pdf`** (team handoff, 29 October 2026). It covers the Customer Android app, Vendor Android app and Admin web panel; it excludes a separate Driver app, the Windows POS/ERP and HRMS. The Delivery and Kitchen apps were audited anyway on request (see [Decisions](#7-decisions-needed)).

---

## 2. Setting up on a new machine

```bash
git clone https://github.com/sigosoft/Saimpex-V2.git
git clone https://github.com/sigosoft/Saimpex_vendor-App.git
git clone https://github.com/sigosoft/Saimpex-Delivery.git
git clone https://github.com/sigosoft/Saimpex-Kitchen-App.git
git clone https://github.com/praveensigo/saimpex-backend-new.git
git clone https://github.com/praveensigo/saimpex-admin-phase2.git
git clone https://github.com/praveensigo/saimpex-vendor-phase2.git
```

Then check out the branch you want to work on, e.g. `git checkout fix/customer-critical-flows`.

Tooling used: Flutter 3.44 (stable), Dart 3.12. Install **PHP 8.x + Composer** to run the backend and **Node 20+ with pnpm/npm** to build the web panels — neither was available on the original machine, so the backend and Vue changes still need a first run.

> **Local-only work on the original machine:** `D:\sigosoft\Saimpex-Delivery` has about 35 files (~1,760 lines) of the owner's **uncommitted, unpushed** Delivery app work. It is not in GitHub. Commit and push it before relying on another machine. The Delivery and Kitchen URL changes were made in separate git worktrees (`D:\sigosoft\_wt-delivery`, `D:\sigosoft\_wt-kitchen`) so that work was not touched.

> **Credentials:** GitHub personal access tokens were pasted into the chat during this work. Revoke them in GitHub → Settings → Developer settings → Personal access tokens if not already done. Use `GITHUB_PERSONAL_ACCESS_TOKEN` as an environment variable for the Claude GitHub plugin; never paste tokens into chat.

---

## 3. Pushed branches (review and merge)

All branches were cut from the default branch and pushed. Suggested merge order: **security fixes first**, then features, then the URL changes.

### 3.1 Backend — `praveensigo/saimpex-backend-new` (base `main`)

| Priority | Branch | Commits | What it does |
|---|---|---|---|
| 🔴 1 | [`fix/admin-routes-require-admin`](https://github.com/praveensigo/saimpex-backend-new/tree/fix/admin-routes-require-admin) | `ee5f81c` | Admin API only allows admin roles (1, 3, 4); moves public customer/vendor/staff lookups and `addSplashScreen` behind admin login. |
| 🔴 2 | [`fix/service-provider-data-leak`](https://github.com/praveensigo/saimpex-backend-new/tree/fix/service-provider-data-leak) | `0742856` | Public `customer/serviceProvider` no longer returns bank details, ID proofs, tax numbers, commission. |
| 🔴 3 | [`fix/customer-otp-security`](https://github.com/praveensigo/saimpex-backend-new/tree/fix/customer-otp-security) | `309842e` | Random 6-digit OTP, 10-minute expiry, 5-attempt lock for **customer and driver** login. `OTP_TEST_NUMBERS` keeps `123456` for listed numbers. |
| 🟠 4 | [`fix/driver-accept-race`](https://github.com/praveensigo/saimpex-backend-new/tree/fix/driver-accept-race) | `58e79b6` | Locks the order so two drivers can't accept the same order. |
| 🟢 5 | [`feat/vendor-profile-otp`](https://github.com/praveensigo/saimpex-backend-new/tree/feat/vendor-profile-otp) | `89ef74a`, `f539d9f` | New `POST vendorapp/profile/sendOtp` and `POST vendorapp/profile/update` (name, photo, OTP-verified phone change). Needed by the vendor app branch. |
| 🟢 6 | [`feat/admin-order-chat-history`](https://github.com/praveensigo/saimpex-backend-new/tree/feat/admin-order-chat-history) | `822770a` | New read-only `GET orderChatHistory?order=<code|id|CW-123>` for the admin panel. Needed by the admin chat branch. |

Branches 1 and 6 both edit `routes/api.php` in different places; expect a trivial or no conflict.

### 3.2 Customer app — `sigosoft/Saimpex-V2` (base `main`)

[`fix/customer-critical-flows`](https://github.com/sigosoft/Saimpex-V2/tree/fix/customer-critical-flows) — 18 commits:

| Commit | Change |
|---|---|
| `da51d50` | Failed/cancelled online payment handled; retry pays the same order (no duplicates); payment URL host from `ApiConstants`. |
| `3698963` | Order cancel calls `customer/cancelOrder`; success screen only after the server confirms. |
| `e831d9f` | Ratings submitted to `customer/submitRating`. |
| `99966e1` | Switching restaurants clears the old restaurant's cart lines. |
| `ab3afe3` | Sample orders removed from My Orders. |
| `2a95dfb` | Invented pharmacy pack sizes/prices removed. |
| `829729f` | Courier tab loads `customer/courier/orders`. |
| `3a768e2` | My Subscriptions loads water subscriptions; pause, resume, cancel wired. |
| `e54c313` | Car wash, home cleaning, laundry providers from `customer/serviceProviders`; adds `ServiceRepository`. |
| `33f422e` | My Bookings from `customer/service/bookings`; real cancel via `customer/service/cancel`. |
| `4d3a2e5` | iOS minimum raised to 15.5 (Google ML Kit) + `ios/Podfile`. |
| `1dc7612` | Provider detail screens load real services (`customer/serviceProvider`). |
| `629637f` | Home cleaning and car wash Pay → `customer/service/book`; car wash slot AM/PM bug fixed. |
| `a941a66` | Laundry Pay → `customer/service/book`; in-memory `CarWashBookingsStore` removed. |
| `f5755e8` | Local Store loads `customer/localStoreHome`, orders through the grocery store screen in local-store mode. |
| `ba49ff4` | Express loads `customer/expressHome`; vendors open their own vertical's store screen. |
| `26ea105` | Live tracking (`customer/trackOrder`, 15 s refresh) on the general Track Order screen. |
| `1a45d6c` | Live tracking for water and pharmacy orders. |

### 3.3 Vendor Android app — `sigosoft/Saimpex_vendor-App` (base `main`)

[`fix/save-item-variants-options`](https://github.com/sigosoft/Saimpex_vendor-App/tree/fix/save-item-variants-options):

| Commit | Change |
|---|---|
| `bdb7b23` | Add-item now sends variants, option groups (min/max), their images; fixes `images[]`, `extra_images[N]` and `serial_no` field names. |
| `fb08465` | Password in `flutter_secure_storage` (migrates and deletes the plain copy); tokens no longer logged; app section chosen from the server's `vendor_type`. |
| `706c74e` | Edit Profile uses the new OTP endpoints (needs backend `feat/vendor-profile-otp`). |

### 3.4 Web panels and driver/kitchen apps

| Repo | Branch | Commit | Change |
|---|---|---|---|
| admin-phase2 | [`fix/v2-dev-server`](https://github.com/praveensigo/saimpex-admin-phase2/tree/fix/v2-dev-server) | `a475bff` | `.env.production` → dev API/storage (builds used `127.0.0.1`). |
| admin-phase2 | [`fix/admin-services-report-chat`](https://github.com/praveensigo/saimpex-admin-phase2/tree/fix/admin-services-report-chat) | `b7d6bdd` | Real Services report (`/servicesReport`, PDF download); real order chat history, real phone numbers only; fake send box replaced by a note. Needs backend `feat/admin-order-chat-history`. |
| vendor-phase2 | [`fix/v2-dev-server`](https://github.com/praveensigo/saimpex-vendor-phase2/tree/fix/v2-dev-server) | `7bc743d4` | `.env.production` → dev API/storage. |
| Saimpex-Delivery | [`fix/v2-dev-server`](https://github.com/sigosoft/Saimpex-Delivery/tree/fix/v2-dev-server) | `6e74910` | Base URL → dev (live URL kept commented). |
| Saimpex-Kitchen-App | [`fix/v2-dev-server`](https://github.com/sigosoft/Saimpex-Kitchen-App/tree/fix/v2-dev-server) | `a61e68d` | Base URL → dev (live URL kept commented). |

---

## 4. Security issues found and fixed

Deploy these before any public release. All are on backend branches in [3.1](#31-backend--praveensigosaimpex-backend-new-base-main) unless noted.

| Issue | Impact | Fix |
|---|---|---|
| Admin routes only required `auth:sanctum` | Any customer/vendor/driver token could call admin endpoints (refunds, wallet adjustments, vendor management). | `EnsureAdmin` middleware (roles 1, 3, 4) on the admin group. |
| `listCustomersSearch` public | Returned every customer's **name and mobile** without login (132 on dev). `getCustomers`, `getDeliveryStaff`, `getVendors` exposed names; `addSplashScreen` was a public write. | Moved behind admin login. |
| `customer/serviceProvider` selected `v.*` | Public bank account number, IFSC, ID-proof paths, tax/registration numbers, commission. | Explicit customer-facing column list. |
| Login OTP hardcoded `123456`, no expiry | Anyone could log in as any customer or driver. | Random code, 10-minute expiry, 5-attempt lock, constant-time compare. `OTP_TEST_NUMBERS` for review accounts. |
| Driver accept had no lock | Two drivers could both accept one order. | `lockForUpdate` + already-assigned check + rollback on early returns. |
| Vendor app stored password in plain SharedPreferences, logged tokens | Credential exposure on device and in logs. | Secure storage + log lines removed (vendor app branch). |

---

## 5. What was fixed, per app

### Customer app
Payments (failure/retry), order cancel, ratings, restaurant cart switch, sample orders, pharmacy fake prices, courier orders list, water subscriptions, service providers / services / booking / My Bookings / cancel, Local Store, Express, live tracking (general, water, pharmacy), iOS deployment target.

New shared code worth knowing:
- `lib/models/service_repository.dart` — all `customer/service*` endpoints.
- `lib/controllers/service_booking_draft.dart` — provider + service picked on the detail screen, read by the carts.
- `lib/views/services/service_booking_submit.dart` — `placeServiceBooking()`, `serviceSlotWindow()`, `formatServiceSlotLabel()`.
- `lib/views/services/provider_services_mixin.dart`, `service_provider_list.dart`.
- `lib/models/grocery_repository.dart` — `GroceryRepository.localStore(...)` mode (local store API mirrors grocery's).
- `lib/views/express/express_stores.dart` — loads express vendors and routes to each vertical's screen.
- `lib/models/order_tracking.dart` + `lib/views/widgets/tracking_widgets.dart` — tracking parser, polling mixin, shared panel.

### Vendor Android app
Variants/option groups/images saved on add; secure credentials; route by server vendor type; real Edit Profile with OTP.

### Backend
Six branches above (security, driver race, vendor profile OTP, admin chat history).

### Admin panel
Real Services report; real order chat history; dev API config.

### Vendor web, Delivery, Kitchen
Point at the dev server.

---

## 6. Pending development

Ordered roughly by launch impact.

### 6.1 Vendor Android — service verticals (largest item)
- **Car Wash and Laundry sections don't exist**; laundry and car wash vendors are told to use the vendor web panel at login.
- **Home Cleaning is sample UI**: `lib/home_cleaning/view/home_cleaning_home.dart` (fake bookings), `add_service_view.dart` ("Add Service" just closes), `my_services_view.dart` (`defaultServices`).
- Backend routes already exist in `routes/vendorapp.php`: `serviceTypes`, `requestServiceType`, `serviceItems`, `add/update/deleteServiceItem`, `updateServiceItemStatus`, `serviceBookings`, `serviceBookingDetail`, `updateServiceBookingStatus`, `serviceHours`, `saveServiceHours`, `serviceAvailability`, `serviceDashboard`, `serviceEarnings`, `serviceProfile`, `serviceReport*`.
- The vendor **web** panel already implements these flows and can be used as the reference (`src/pages/home`, `carwash`, `laundry`, `src/composables/useHomeApp.js`, `useCarwashApp.js`, `useLaundryApp.js`).

### 6.2 Vendor Android — other gaps
- **Editing restaurant items** uses the old `updateRestaurantMenuItem` endpoint (`lib/controller/item_controller.dart`, `updateItemAfterEdit`), so variants/option groups can't be edited. Switch to `updateRestaurantCatalogItem` and load the item via `restaurantCatalogItemDetail`.
- Water coupons are local-only (`lib/water/view/account/coupons_view.dart`); water earnings show fake fallback amounts (`earnings_view.dart`); menu export/import call routes that don't exist (`menucontroller.dart`); local store, water plans, pharmacy category requests and many other `vendorapp` routes are unused (see the audit list in section 10).
- No 24-hour acceptance timeout handling.

### 6.3 Delivery (driver) app
- Handles **only food and grocery** orders (`OrderTypeSelectionDialog.dart`); no courier, water, pharmacy, local-store or service orders.
- Calls the customer's **real phone number** (`OrderDetailsController.dart`, `Utils.dart`) — scope requires a masked call.
- No delivery PIN check (backend generates `four_digit_pin`).
- `completeOrder` requires `delivery_proof` but the app can send JSON without it (422).
- Backend has `openPickupOrders` / `acceptOpenPickupOrder` with proper locking but **no route** in `routes/delivery.php`.
- ⚠️ Coordinate with the owner's uncommitted local work in this repo first (section 2).

### 6.4 Kitchen app
- One global Pusher channel: every vendor's tablet refreshes and plays the alert for every vendor's orders (`lib/config/pusherConfig.dart`, `home_controller.dart`). Needs a per-vendor channel on backend and app.
- Lists fetched with `limit 10` and no paging — busy kitchens lose orders beyond 10 per column.
- `prepareOrder` / `markAsReady` ignore `status: false`; receipt prints before success is confirmed.
- Logout doesn't clear the session if the server call fails; "Check for update" button is dead.
- Pusher key is hardcoded; confirm dev uses the same Pusher app as live.

### 6.5 Customer app — remaining
- **Courier order detail and tracking** are sample screens (`lib/views/courier/courier_order_detail_screen.dart`, `courier_track_order_screen.dart`).
- **Car wash with several vehicles** books only the first (`car_wash_selected_vehicles_screen.dart` uses `_vehicles.first`).
- **Store Map** is a painted sample map (`lib/views/store_map_screen.dart`, `express/express_store_map_screen.dart`).
- **Service booking payment**: bookings record a payment type but no Wallet or online payment step exists in the backend for services.
- Service booking price: options not in the provider's catalog are dropped, so the server price can differ from the cart total — show the server's quote (`customer/service/quote`) before Pay.
- **Saved addresses, favourites, rewards & referral, My Schedules, AI chatbot** have no backend (see Decisions).
- Masked driver call (button currently says "coming soon").
- Water order details screen (`water_order_details_screen.dart`) still shows sample store/driver/totals.
- Cart "Pay Later" design state has no implementation.

### 6.6 Admin panel
- **Sending chat messages** (admin ↔ customer/vendor/driver) — chat tables only store customer and vendor messages; needs schema design.
- Missing scope rules: "who pays the delivery fee", freelance driver %, vendor reminders for scheduled orders, payout receipt upload for pharmacy/water/service vendors, driver assignment for pharmacy/water/local store, live map is schematic (no tiles).
- Mock fallbacks remain in some components (`VendorOrderPayout.vue`, `VendorEarnings.vue`, `CatalogRequestList.vue`).
- `src/pages/baskets/local_store/add/index.vue` calls `/fetchLocalStoreMenus`, which doesn't exist.

### 6.7 Vendor web panel
- Grocery/Local Store bulk import/export call routes that don't exist under `/api/vendor`.
- Sales reports drop cancelled orders instead of listing them at 0.00 MRU (scope rule).
- "Total Sale Amount" on Payouts shows the pending balance.
- Committed `dist/` was built against localhost — rebuild.

### 6.8 Backend
- Masked calling provider integration.
- Per-vendor Pusher channel for kitchen/vendor order events.
- Route for `acceptOpenPickupOrder`.
- Vendor OTP endpoints are implemented; consider the same pattern for any other phone-change flows.

---

## 7. Decisions needed

| Topic | Question |
|---|---|
| Saved addresses, favourites, rewards & referral | Build backend support, or hide in the customer app for launch? |
| Delivery and Kitchen apps | Are they V2 deliverables? The scope excludes a separate Driver app and doesn't mention Kitchen. |
| Masked calls | Which telephony provider? |
| Admin messaging | Should admin send messages, and include drivers? |
| Car wash service location | Station only, or customer's home/workplace too? (scope: Open) |
| Laundry model | How small vs large laundries are defined; pickup/return and fees. (scope: Open) |
| Delivery fee | Who pays: customer, vendor or split? (scope rule not implemented) |
| Option groups | Final min/max selection rules and add-on images. |
| Provider report dates | Filter by order date instead of provider registration date? (affects all provider reports) |
| Vendor profile scope | Current endpoint allows name, photo, OTP-verified phone; business details stay with admin. Confirm. |

---

## 8. Deployment and release checklist

### Backend deploy (dev first)
1. Merge the backend branches in the order in 3.1.
2. Set `OTP_TEST_NUMBERS` (comma-separated, with country code, e.g. `+22212345678`) for store-review and QA accounts — **everyone else will need the real WhatsApp code**.
3. Confirm WhatsApp (Wabis) OTP delivery works on the server; without it nobody can log in.
4. `php artisan config:clear` (or `config:cache`) and `php artisan route:clear` after deploying.
5. Smoke test: admin login + a call with a customer token to an admin route must return 403; `listCustomersSearch` without login must return 401.

### Test data on dev
- Service providers (car wash, laundry, home cleaning) with services: spaces/vehicles, add-ons, garments, prices.
- Local stores with menus; express-enabled vendors in each vertical.
- A driver app sending location, to see live tracking move.

### Device testing (nothing has been run yet)
- Customer app on Android and iOS: payment failure/retry, cancel, rate, restaurant switch, subscriptions, service booking + cancel, local store and express orders, tracking.
- Vendor app: add item with variants/options/images; login migration of the stored password (install over the old build); edit profile with OTP.
- Admin panel build (`npm/pnpm build`) and the Services report + order chat pages.

### iOS
- Build on a Mac (`flutter build ios`); `ios/Podfile` pins iOS 15.5 because Google ML Kit requires it.

### Store upload (V2 replaces V1)
- Use **V1's** Android `applicationId`, iOS bundle ID and the **V1 Android signing keystore** — V2 must ship as an update, not a new app.
- Current placeholders: `com.example.saimpex_v2` (Android), `com.example.saimpexV2` (iOS).
- Version numbers must be higher than V1's live versions.
- When going live, switch app base URLs from dev to the live server (each app keeps the live URL commented next to the dev one).

---

## 9. Known issues found but not changed

- **Provider reports** (`app/Http/Controllers/admin/Phase2ReportController.php`, `vendorQuery`) filter by provider registration date (`u.created_at`), not order date; totals are all-time.
- **trackOrder** returns the driver's real phone number to the customer app (unused by the app, but visible in traffic).
- Customer app `HomeController` keeps the previous user's favourites/wallet after logout (no reset).
- No global 401 handling in the customer app — an expired session shows error toasts instead of returning to login.
- `CustomerSplitCheckoutService` keeps unpaid online orders pending for 30 minutes (`services.checkout.online_payment_pending_minutes`); the app now retries the same order instead of creating duplicates.
- Many leftover "copy" controller/route files in the backend (`OrderController copy.php`, `routes/customer copy.php`) — not loaded, but worth removing.

---

## 10. Reference links

### Designs
- Customer app Figma (V2): https://www.figma.com/design/gcPrdiT2s5VbO51zOdwT36/Saimpex-V2-Customer-App-UI?node-id=0-1
- Older Saimpex Figma file: https://www.figma.com/design/ZCYkkdqmKm6Hn5Hcm12Mxg/Saimpex?node-id=5502-6985 (Figma MCP Starter-plan limit reached on this file)
- Admin design: https://ourworks.co.in/saimpex-admin-design
- Vendor design: https://ourworks.co.in/saimpex-vendor-design/
- Vendor, Delivery, Kitchen and Admin Figma links were requested but not received.

### Documents
- Scope: `Saimpex_V2_Team_Scope.pdf` (29 Oct 2026) — sections 4 (Customer), 5 (Vendor), 6 (Admin), 8 (Open decisions).
- Backend API docs: `docs/SAIMPEX_V2_CUSTOMER_API.md`, `docs/SAIMPEX_V2_API_AND_MIGRATION.md` in the backend repo.
- Vendor web integration notes: `docs/*_INTEGRATION.md` in the vendor web repo.

### Branch compare links (open a PR from these)
- Customer: https://github.com/sigosoft/Saimpex-V2/compare/main...fix/customer-critical-flows
- Vendor app: https://github.com/sigosoft/Saimpex_vendor-App/compare/main...fix/save-item-variants-options
- Backend:
  - https://github.com/praveensigo/saimpex-backend-new/compare/main...fix/admin-routes-require-admin
  - https://github.com/praveensigo/saimpex-backend-new/compare/main...fix/service-provider-data-leak
  - https://github.com/praveensigo/saimpex-backend-new/compare/main...fix/customer-otp-security
  - https://github.com/praveensigo/saimpex-backend-new/compare/main...fix/driver-accept-race
  - https://github.com/praveensigo/saimpex-backend-new/compare/main...feat/vendor-profile-otp
  - https://github.com/praveensigo/saimpex-backend-new/compare/main...feat/admin-order-chat-history
- Admin: https://github.com/praveensigo/saimpex-admin-phase2/compare/main...fix/admin-services-report-chat and https://github.com/praveensigo/saimpex-admin-phase2/compare/main...fix/v2-dev-server
- Vendor web: https://github.com/praveensigo/saimpex-vendor-phase2/compare/main...fix/v2-dev-server
- Delivery: https://github.com/sigosoft/Saimpex-Delivery/compare/master...fix/v2-dev-server
- Kitchen: https://github.com/sigosoft/Saimpex-Kitchen-App/compare/master...fix/v2-dev-server
