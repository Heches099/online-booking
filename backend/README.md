# Online Booking Backend

Express backend for Firebase-authenticated Zenopay payments.

## Local Development

1. Copy `backend/.env.example` to `backend/.env`.
2. Fill in Firebase and Zenopay values.
3. Start the server:

```bash
npm install
npm start
```

The local server defaults to `http://localhost:3000`.

## ABC Upper Class Checkout

`POST /api/abc/lock-and-pay` requires a Firebase ID token. Send the ABC route IDs, travel date, seat ID, and preferably the selected `sub_id` so the first search result is not chosen accidentally:

```json
{
	"from_id": 1,
	"to_id": 26,
	"date": "2026-10-12",
	"seatId": "L-2-3-10",
	"sub_id": "ABC_TRIP_ID"
}
```

The ABC search response must include `sub_id`, `ukey`, `tdi_id`, `asi_id`, `lb_id`, and `pbi_id`; the route fails closed if those identifiers are absent. A successful response includes the fare, reservation ID, `paymentUrl` (with `?ukey=`), `ukey`, `useRedirect: true`, and session cookies. Treat `cookies` as a short-lived credential: send it only to the HTTPS ABC WebView session, and never log or persist it.

Mobile apps install `cookieDetails` into the WebView before opening `paymentUrl`. Flutter Web cannot set third-party ABC cookies (browser same-origin policy — the backend also cannot `Set-Cookie` for ABC's domain), so Web opens `paymentUrl` in a new tab and asks the user to press Thibitisha afterwards.

After the WebView returns (or the Web user presses Thibitisha), `POST /api/abc/confirm` accepts `{ "reservationId": "..." }` with the same Firebase authorization. A client-side URL is not payment proof, so this endpoint records `pending_confirmation`; it does not mark the seat booked or the payment completed. An ABC-authoritative payment/ticket confirmation integration is required before Heches can safely issue a confirmed ticket.

## Render Deployment

This repository includes a root `render.yaml` blueprint. In Render:

1. Create a new Blueprint from this Git repository.
2. Render will use `backend` as the service root directory.
3. Add the secret environment variables requested by the blueprint.
4. Deploy the service.
5. Copy the generated Render URL and update `ZENOPAY_WEBHOOK_URL` to:

```text
https://YOUR_RENDER_SERVICE.onrender.com/zenopay-webhook?token=YOUR_WEBHOOK_SECRET
```

Use the same value for `YOUR_WEBHOOK_SECRET` and `ZENOPAY_WEBHOOK_SECRET`.

For Firebase Admin, set `FIREBASE_SERVICE_ACCOUNT_BASE64` in Render:

1. In Firebase Console, open Project settings > Service accounts.
2. Generate a new private key and download the JSON file.
3. Base64-encode that JSON file:

```bash
base64 -w 0 path/to/service-account.json
```

4. Paste the output into Render's `FIREBASE_SERVICE_ACCOUNT_BASE64` environment variable.

If your `base64` command does not support `-w`, use:

```bash
base64 path/to/service-account.json | tr -d '\n'
```

For the Flutter app, build or run with the deployed backend URL:

```bash
flutter run --dart-define=BACKEND_URL=https://YOUR_RENDER_SERVICE.onrender.com
```
