**Repo:** praveensigo/saimpex-backend-new
**Title:** [customer-app] Vendor reject reason is never saved, so the customer can't see it (C-B23)

**Screen:** Customer app → My Orders → cancelled order detail (food, grocery, pharmacy, water, courier)
**Endpoint the app reads:** `GET customer/orderDetails?order_id=` → `timeline[]` entry with `status: 10` → `remark` (documented in SAIMPEX_V2_CUSTOMER_API.md)

**What happens now (dev, 3 Nov, journey E2E-15a):**
- The vendor rejected ORD-001492 with "Out of Stock" in the vendor app.
- The vendor app calls `GET vendorapp/cancelRestaurantOrder` with only `order_id` (`Saimpex_vendor-App/lib/controller/order_details_controller.dart:277`), so the reason is never sent.
- `android/vendorapp/OrderController::cancelRestaurantOrder` (and `cancelGroceryOrder`, `vendor/OrderController` the same) has no reason field and writes a fixed remark:
  ```
  "timeline":[{"status":10,"text":"Cancelled","remark":"Order Cancelled by Vendor", ...}]
  ```
- An Admin cancel works: ORD-001493 shows `"remark":"Customer unreachable"`.

**What's needed:**
1. The cancel/reject endpoints take an optional `reason` (string, max 500) and save it as the remark of the status-10 log, as `AdminCancellation::reason()` does. Pharmacy and water already use `$request->remark ?? '...'`.
2. The vendor app sends the reason the vendor picked (vendor app owner).
3. Optional: keep the fixed remark when no reason is given. The customer app already shows "Cancelled by the store" for it.

**Customer app side (done in branch `feature/cancel-reason`):** cancelled orders now show "Reason: …" from that remark. Fixed server remarks ("Order Cancelled by Vendor/pharmacy/water vendor", "Not accepted by vendor within 24 hours") are translated into EN/FR/AR, and a typed reason is shown as written. Once the backend saves the vendor's reason, it will show with no app change.

**Also:** `customer/service/booking` timeline entries aren't documented with `remark`. If car wash or laundry reject reasons should show the same way, please add `remark` there and to the doc.
