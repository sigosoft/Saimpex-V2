Hi Praveen / Kiran,

Customer app status, 12 Nov: every app-side item is done in code. These are the backend fixes still open for the customer app. Where the app can work around a gap, it already does; that workaround should be removed once the field arrives.

**Needs the backend (the app can't do these)**

1. **#163 Laundry: pay the balance after re-weighing.** `service/booking` returns `additional_payment`, but no endpoint takes the payment (`orders/{id}/payDue` answers "Nothing is due"). Needed: set `orders.amount_due` on re-weigh so `payDue` works, or `POST service/{orderId}/payBalance` → `{payment_url, topup_id, amount_due}`. App: the button says "Coming soon".
2. **#177 Cancel reason.** `cancelOrder` has no reason field, so the reason the customer picks is lost. Needed: `reason` (text) on `cancelOrder`, saved as the timeline remark. App: ready to send it once documented.
3. **#184 Courier "Schedule for Later".** `courier/create` takes no pickup time. Needed: optional `scheduled_for` (ISO 8601 with offset), the allowed window (reuse `preorder/window`), a 422 outside it, and `is_preorder` / `scheduled_for` on courier orders. App: the card says "Coming soon".
4. **#164 Courier offers.** No courier sliders in the API, so Figma's "Exclusive Offers" banners are hidden. Needed: courier slider type (or `sliders[]` on the courier home). Showing banners without the quote applying the discount would advertise prices customers don't get.
5. **#178 Missing fields (5 Nov report):**
   - notifications list: `order_id`, `type`, `order_type` per row, so a tap opens the order;
   - search: store `name_ar` / `name_fr` on product rows;
   - `checkoutSummaryV2` (water, grocery, pharmacy, local store carts): `min_order_value` + `min_order_shortfall` like `catalog/checkoutSummary`, so the cart warns before checkout;
   - `homeHub` recent orders for grocery.
6. **#185 Closed stores: opening time.** Store lists send `is_open` but not when the store opens, so Figma's "Closed · Opens 10 AM" can't be shown. Needed: `opens_at` (ISO 8601 with offset, next opening from working hours) on store rows in `homeHub`, `restaurantHomeV2`, grocery, local store, pharmacy and water lists. App: shows just "Closed" until then (it used to show a made-up "Opens 10 AM").
7. **Push data for order / chat / substitution notifications** (handover request 4): `type`, `order_id`, `order_type` (and `vendor_id` for chat) in the push `data`.

**Worked around in the app (please still fix, the workaround costs extra requests)**

8. **#165 Rated flag.** Add `is_rated` (bool) to the customer order lists and `orderDetails`. App meanwhile: calls `GET customer/rating` once per delivered order (newest 20), remembers the answer on the phone, and hides Rate on rated orders.
9. **#166 Self-pickup on order lists.** Add `is_self_pickup` to `orders/restaurant`, grocery, local store and water lists. App meanwhile: calls `orderDetails` once per order (newest 20) to learn it, and shows "Pickup · Picked up". Pickup code for self-pickup: needs a product decision (none is defined today).
10. **#183 Notifications read flag.** `unread_notifications` is the total. Needed: a read flag per notification and a mark-read call (or `last_seen_at`). App meanwhile: counts what's new since Notifications was last opened on this phone (resets on a new phone or reinstall).

**Found in the static-content sweep (12 Nov afternoon)**

12. **Support hours.** Help showed a fixed "Available 9 AM – 10 PM"; no endpoint has support hours, so the row is hidden. Needed: `support_hours_en/fr/ar` in Admin → Branding (sent with the support contacts).
13. **Service catalog names in AR/FR.** Home cleaning `spaces` / `addons` and car wash `vehicles` on `customer/serviceProvider` have only `name`. Needed: `name_ar` / `name_fr` like laundry garments (#170), so Arabic and French customers read them translated.
14. **Dev data:** an active slider per service vertical (Admin → Sliders, types 7 laundry, 8 car wash, 9 home cleaning) so the service home banners show Admin images; car wash services on dev list no `vehicles`.

**Please confirm and close**

15. **#167 Rating tags.** `vendor_tags` / `driver_tags` shipped in c8f8e30 (5 Nov) and the app sends them. If nothing else is missing, the issue can be closed.

**Not code, for Praveen**

- Telephony provider for masked customer↔driver calls (the call button says "Coming soon").
- Release: V1 keystore (or Play upload-key reset) and the app ID decision (`app.saimpex`), iOS bundle and `GoogleService-Info.plist`.
- Design calls: bottom bar 7 items vs Figma's 5 (PR #38), Local Store search icons, grocery "AI predictive" cards, the cart's "Specify quantity" box, shorter French bottom-bar labels.

Customer app PRs waiting for review, in merge order: #58 → #59 → #60 → #61 → (order-list workarounds), plus #52, #54, #55.

Thanks,
Stephy
