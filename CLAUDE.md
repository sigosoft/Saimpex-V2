# CLAUDE.md — SAIMPEX V2 Customer app

Owner: Sharvin. Working branch: `fix/customer-critical-flows`. Launch: **1 December 2026**.

## Read before doing anything
1. Complete scope (what to build, every rule): https://github.com/praveensigo/saimpex-backend-new/blob/integration/v2/docs/V2_COMPLETE_SCOPE.md
2. This repo's handover: `docs/HANDOVER.md` (setup, architecture, status, pending work with acceptance criteria, "Backend updates" table at the end).
3. Your task queue: https://github.com/praveensigo/saimpex-backend-new/blob/integration/v2/docs/TEAM_ASSIGNMENTS.md (section for Sharvin).
4. API changes, newest first: https://github.com/praveensigo/saimpex-backend-new/blob/integration/v2/docs/API_CHANGELOG.md — check entries tagged `[customer]` at the start of every session.
5. API contracts: https://github.com/praveensigo/saimpex-backend-new/blob/integration/v2/docs/SAIMPEX_V2_CUSTOMER_API.md

If you have the backend repo cloned next to this one (`../saimpex-backend-new`, branch `integration/v2`), read the docs there and `git pull` it first.

## Rules
- **Figma is the design and must not be edited.** File `gcPrdiT2s5VbO51zOdwT36`. A required feature with no Figma screen is built in the same style and noted in the handover.
- **The client's written requirements are final** (SPX-ADM-02 and the scope doc). Don't invent business rules; if something is unclear, ask the owner, who asks Praveen.
- **Never build against a guessed API.** If an endpoint is missing or doesn't match the doc, open a GitHub issue in `praveensigo/saimpex-backend-new` titled `[customer-app] <short description>` (screen, endpoint, request, response, what's needed), then move to the next task.
- English, French and Arabic for every user-facing string (Arabic right-to-left). No hard-coded English in screens.
- No secrets in code, commits or logs (don't log tokens). Keystores and `.env` stay out of git.
- Test against the **dev server running `integration/v2`**, never production.
- One task = one branch (`feature/<short-name>`) = one pull request into `fix/customer-critical-flows`. Commit messages say what changed and why.
- After finishing a task: tick it in `docs/HANDOVER.md` (status table / pending list) in the same PR.
- Done means: matches Figma and the scope; EN/FR/AR; wired to the real API (no mock data); `flutter analyze --no-pub` must show no new errors; run on a device or emulator against the dev server.

## Project notes
- State: GetX. Networking: Dio repositories; `ApiEnvelope` unwraps `data`. Base URL: `lib/core/network/api_constants.dart`.
- Payment types: 1 cash, 2 online (Masrvi WebView via `payment_url`), 3 wallet, 4 Pay After Delivery (only when `GET customer/payAfterDelivery` says `can_use`).
- API envelope: `{status, data, message: {message_en, message_fr, message_ar}}`.
