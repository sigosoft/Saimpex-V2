# Customer app vs Figma: remaining screens and languages (12 Nov 2026, afternoon)

Follows `figma-comparison-full-2026-11-12.md`, which left out closed-store states, a few account and order screens, the courier booking flow, and French and Arabic inner screens.

Figma: `ZCYkkdqmKm6Hn5Hcm12Mxg`, page "Customer App Version 2 UI" (view only, frames opened with Find).
Phone: Samsung M11 (360 dp wide), release build of `main` + open PRs #52, #54, #55, #58, #59, #60, dev server, test customer 95200021. English, then Arabic, then French.
Screenshots: `screenshots-2026-11-12/`.

Legend: ✅ matches · 🟡 small difference · 🔴 bug / clear difference · 📦 dev data or backend · 🔧 fixed in `fix/figma-pass-rest`.

## 1. Store states
| Screen | Result | Notes |
|---|---|---|
| Closed store card ("Closed · Opens 10 AM") | 🔴🔧 | Figma: grey card, red "Closed" pill with the opening time. The app had the pill, but every closed store said **"Opens 10 AM"**: the store lists send no opening time, so the time was made up (home, food, grocery, local store, pharmacy, water, Under 30 min). The "Opens …" line now shows only when the server sends a time; otherwise the pill just says "Closed". |
| Temporarily not accepting orders | ✅ | Orange speech bubble on a greyed card, as in Figma. |

## 2. Account
| Screen | Result | Notes |
|---|---|---|
| Account | ✅ | Header, wallet and points cards, Quick Actions, settings, socials. |
| ⋮ → Delete Account, confirmation sheet | ✅ | Yes grey / No orange, as in Figma. |
| Logout sheet | ✅ | No grey / Yes orange, as in Figma. |
| 🔴 Version footer | 🔴🔧 | "V2.0.0 · Check for update" sat **under the Services button** (the list's bottom padding didn't count the phone's navigation area). Figma shows the version and "Check for update" on two lines above the bar. Now two lines and clear of the bar. |
| 🔴 "Check for update" | 🔴🔧 | Plain text that did nothing. It now runs the update check (Admin → App versions): opens the Update screen when a newer version is listed, else says "You have the latest version." (EN/FR/AR). |
| 🟡 Edit Profile | 🟡🔧 | Figma: orange→yellow header with a white title and the photo (white ring) on its bottom edge. The app had a plain title bar. Rebuilt to match. |

## 3. Orders and rating
| Screen | Result | Notes |
|---|---|---|
| 🟡 "Delivered" chip | 🟡🔧 | Figma: green. The app drew delivered food, grocery and pharmacy orders in orange (water was already green). Now green. |
| 🟡 Cancelled / rated cards | 🟡🔧 | Cards without buttons kept an empty band above "View Order Status & Details". Removed. (Figma has no cancelled card.) |
| Reorder on delivered cards | 🟡 | Figma shows Reorder + Rate. No reorder API; Reorder is "Coming soon" elsewhere and not on the cards. Unchanged. |
| Rate Your Order | ✅ | Store and delivery ratings with tags, review box, Submit. Figma's "Rate Ordered Items" (per-item stars) is not built: the API has no per-item rating (removed on purpose in C5). Already-rated orders hide Rate after the check (C-B21). |

## 4. Courier booking
| Screen | Result | Notes |
|---|---|---|
| Courier home | ✅ | Offers banner hidden until backend #164. Vehicle cards show distance + price (Figma: time + price). |
| 🟡 Select Pickup / Recipient Location | 🟡🔧 | The address repeated itself as its own subtitle. Hidden when it repeats the title (same rule as CA-07). |
| Delivery Details & Guidelines | ✅ | Pickup/drop-off, Recipient, Confirm Pickup, Safety Guidelines, Restricted Items. Package card added on purpose (CA-39). |
| 🔴 "View Full Courier Policy" | 🔴🔧 | Did nothing. Opens Admin's Terms & Conditions (there is no courier-only policy in the API). |
| Review Booking | ✅ | Figma's "OTP Verification" shows a made-up code; the app explains that the delivery PIN appears on tracking after booking (real PIN, C-B18). Figma's coupon and points rows are not offered: `courier/create` takes neither. |
| 🔴 "Schedule for Later" (courier) | 🔴🔧 | Did nothing. `courier/create` has no pickup time, so the card now says "Coming soon" and explains on tap. Backend #184. |

## 5. Arabic (right to left)
| Screen | Result | Notes |
|---|---|---|
| Account, settings, bottom bar | ✅ | Mirrored correctly; currency "أوقية". |
| My Orders | ✅ | Statuses and details line in Arabic. |
| Order details | ✅ | Steps, items, payment card. 📦 Store name in English ("Le Méchoui du Ksar", backend). |
| Restaurant page | ✅ | Includes the new "الحد الأدنى للطلب: 150 أوقية" (PR #60). 📦 Store banner image 403 on dev. |
| 🔴 Home "Deliver to" | 🔴🔧 | A Latin address was cut at its start ("…32PC+9MV, La Capi"). It now runs in its own direction. |
| 🔴 Bell badge | 🔴🔧 | "+99" instead of "99+". Fixed. |
| 🔴 Edit Profile phone | 🔴🔧 | "222+" instead of "+222" (also in the country pickers). Fixed. |
| 🔴 Rating filter chips | 🔴🔧 | "+4.0 تقييم" instead of "4.0+". The number is now an isolated left-to-right run in the Arabic strings. |

## 6. French
| Screen | Result | Notes |
|---|---|---|
| Language sheet | ✅ | Cancel now plain text (PR #59). |
| Services, car wash list | ✅ | "Bientôt disponible", "Ouvert", "À partir de", "Voir les services". |
| 🟡 Account → My Schedules tile | 🟡🔧 | "Mes commandes p…" was cut off; the tile now says "Commandes programmées" (fits two lines). |

## 7. Fixes checked on the phone (release build with all fixes, 12:25–12:28)
- Account footer on two lines above the bar; "Check for update" → "Vous avez la dernière version." (French).
- Edit Profile: orange header, photo with white ring on its edge (French).
- My Orders: green "Livrée" chips; cancelled cards without the empty band (French).
- Arabic Home: "32PC+9MV, La Capi…" (starts correctly), bell "99+"; restaurant rating chip "تقييم 4.0+".
- Arabic empty cart: icon, "سلتك فارغة", hint, "ابدأ التسوق" opens Home.
- Not seen on the phone: the closed-store change (no closed store on dev), the courier links (code only), the French tile rename (built after), "+222" in Arabic Edit Profile.
- The phone was set back to English afterwards.

## Not covered
- Store Map, Redeem detail, Scan, Replace item, Cart Pay Later, Subscription Cart (no water plans on dev), Prescription Cart / Quotation / Success: frames found in Figma, not walked on the phone this pass.
- French and Arabic on cart and checkout, pharmacy and water flows.
- Success screens after a real payment (nothing was paid or booked).

## Backend / data
- Courier: no scheduled pickup time on `courier/create`: [praveensigo/saimpex-backend-new#184](https://github.com/praveensigo/saimpex-backend-new/issues/184).
- Store lists: no opening time for closed stores (the app no longer invents one): [praveensigo/saimpex-backend-new#185](https://github.com/praveensigo/saimpex-backend-new/issues/185).
- Unchanged from earlier reports: store names in English on order details (#178 area), dev images 403, no water plans on dev.
