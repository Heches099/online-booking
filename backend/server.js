const express = require("express");
const cors = require("cors");
const { createClient } = require("@supabase/supabase-js");
const path = require("path");
const axios = require("axios");
const crypto = require("crypto");
const { wrapper } = require("axios-cookiejar-support");
const tough = require("tough-cookie");

require("dotenv").config({ path: path.join(__dirname, ".env") });
require("dotenv").config({ path: path.join(__dirname, "..", ".env") });

const SUPABASE_URL = String(process.env.SUPABASE_URL || "").trim();
const SUPABASE_SERVICE_ROLE_KEY = String(process.env.SUPABASE_SERVICE_ROLE_KEY || process.env.SUPABASE_ANON_KEY || "").trim();

const supabase = createClient(
  SUPABASE_URL || "https://placeholder.supabase.co",
  SUPABASE_SERVICE_ROLE_KEY || "placeholder-key"
);

const isProduction = process.env.NODE_ENV === "production";
const allowedOrigins = String(process.env.ALLOWED_ORIGINS || "")
  .split(",")
  .map((value) => value.trim())
  .filter(Boolean);

// ZenoPay v2 Configuration
const ZENOPAY_API_KEY = String(process.env.ZENOPAY_API_KEY || "").trim();
const ZENOPAY_ACCOUNT_ID = String(process.env.ZENOPAY_ACCOUNT_ID || "").trim();
const ZENOPAY_WEBHOOK_SECRET = String(process.env.ZENOPAY_WEBHOOK_SECRET || "").trim();
const ZENOPAY_BASE_URL = String(process.env.ZENOPAY_BASE_URL || "https://zenopaymobile.com/api").trim().replace(/\/$/, "");

const PAYMENT_POLL_TTL_SECONDS = Number(process.env.PAYMENT_POLL_TTL_SECONDS || 60);
const PAYMENT_MAX_POLL_ATTEMPTS = Number(process.env.PAYMENT_MAX_POLL_ATTEMPTS || 12);

const app = express();

app.use(cors({
  origin: (origin, callback) => {
    if (!origin || !isProduction || allowedOrigins.length === 0 || allowedOrigins.includes(origin)) {
      return callback(null, true);
    }
    return callback(new Error("CORS policy violation"), false);
  },
}));

app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Reservation hold window (seconds)
const RESERVATION_HOLD_SECONDS = Number(process.env.RESERVATION_HOLD_SECONDS || 900);

/**
 * Authenticate Supabase auth token
 */
async function authenticateAppUser(req, res, next) {
  const authHeader = String(req.get("authorization") || "").trim();
  const match = authHeader.match(/^Bearer\s+(.+)$/i);

  if (!match) {
    return res.status(401).json({ status: "failed", message: "Missing auth token" });
  }

  try {
    const token = String(match[1] || "").trim();
    if (!token) {
      return res.status(401).json({ status: "failed", message: "Missing auth token" });
    }
    const { data: { user }, error } = await supabase.auth.getUser(token);
    if (error || !user) {
      return res.status(401).json({ status: "failed", message: "Invalid auth token" });
    }
    req.user = { uid: user.id, ...user };
    next();
  } catch (error) {
    console.error("❌ Auth Verification Error:", error);
    return res.status(401).json({ status: "failed", message: "Invalid auth token" });
  }
}

/**
 * Reserve seats atomically
 */
app.post('/api/reserve-seats', authenticateAppUser, async (req, res) => {
  const { busId, travelDate, seats, orderId } = req.body || {};

  if (!busId || !travelDate || !Array.isArray(seats) || seats.length === 0 || !orderId) {
    return res.status(400).json({ status: 'error', message: 'Missing busId, travelDate, seats, or orderId' });
  }

  try {
    const date = new Date(travelDate);
    if (isNaN(date.getTime())) {
      return res.status(400).json({ status: 'error', message: 'Invalid travelDate' });
    }
    const isoDate = date.toISOString().slice(0, 10);
    const reservedUntil = new Date(Date.now() + RESERVATION_HOLD_SECONDS * 1000);

    const ids = seats.map(seat => `${busId}_${isoDate}_${seat}`);
    const { data: existingSeats } = await supabase
      .from('seat_reservations')
      .select('*')
      .in('id', ids);

    const now = new Date();
    if (existingSeats && existingSeats.length > 0) {
      for (const item of existingSeats) {
        const status = (item.status || '').toString().toLowerCase();
        const until = item.reservedUntil ? new Date(item.reservedUntil) : null;
        if (status === 'booked') {
          throw new Error(`Seat ${item.seatNumber || 'selected'} already booked`);
        }
        if (status === 'reserved' && until && until > now) {
          throw new Error(`Seat ${item.seatNumber || 'selected'} currently reserved`);
        }
      }
    }

    const rows = seats.map(seat => ({
      id: `${busId}_${isoDate}_${seat}`,
      busId,
      travelDate: isoDate,
      seatNumber: seat,
      orderId,
      userId: req.user.uid || null,
      status: 'reserved',
      reservedAt: now.toISOString(),
      reservedUntil: reservedUntil.toISOString(),
      createdAt: now.toISOString(),
      updatedAt: now.toISOString(),
    }));

    const { error: upsertErr } = await supabase
      .from('seat_reservations')
      .upsert(rows);

    if (upsertErr) throw upsertErr;

    console.log(`[reserve-seats] reserved ${seats.length} seats for order=${orderId}`);
    return res.status(200).json({ status: 'success', message: 'Seats reserved', reservedUntil: reservedUntil.toISOString() });
  } catch (err) {
    console.error('❌ Seat reservation error:', err.message);
    return res.status(409).json({ status: 'failed', message: err.message || 'Seat reservation failed' });
  }
});

// ------------------- ABC UPPER CLASS REDIRECT INTEGRATION -------------------

const ABC_BASE_URL = 'https://www.abcupperclass.co.tz';

function getABCClient() {
  const jar = new tough.CookieJar();
  const client = wrapper(axios.create({
    jar,
    withCredentials: true,
    timeout: 15000,
    headers: {
      'User-Agent': 'Mozilla/5.0 (Linux; Android 11) AppleWebKit/537.36',
      'Referer': `${ABC_BASE_URL}/`,
      'X-Requested-With': 'XMLHttpRequest',
      'Content-Type': 'application/json',
      'Origin': ABC_BASE_URL,
    },
  }));
  return { client, jar };
}

function abcReservationId(fromId, toId, date, subId, seatId) {
  const key = [fromId, toId, date, subId, seatId].join('|');
  return `ABC_${crypto.createHash('sha256').update(key).digest('hex')}`;
}

app.post('/api/abc/lock-and-pay', authenticateAppUser, async (req, res) => {
  const { fromId, toId, date, subId, seatId } = req.body || {};

  if (!fromId || !toId || !date || !subId || !seatId) {
    return res.status(400).json({ status: 'error', message: 'Missing required ABC parameters' });
  }

  const reservationId = abcReservationId(fromId, toId, date, subId, seatId);

  try {
    const { client } = getABCClient();
    const payload = {
      from: Number(fromId),
      to: Number(toId),
      date: String(date),
      seat_id: String(seatId),
      sub_id: String(subId),
    };

    const response = await client.post(`${ABC_BASE_URL}/booking/lock-and-pay`, payload);
    const data = response.data || {};

    if (!data.status || data.error) {
      return res.status(409).json({ status: 'failed', message: data.message || 'ABC seat is unavailable' });
    }

    const paymentUrl = `${ABC_BASE_URL}${data.payment_url || '/booking/payment'}`;
    const now = new Date().toISOString();

    await supabase.from('seat_reservations').upsert({
      id: reservationId,
      busId: `ABC_${fromId}_${toId}`,
      travelDate: String(date),
      seatNumber: String(seatId),
      orderId: reservationId,
      userId: req.user.uid || null,
      status: 'reserved',
      reservedAt: now,
      createdAt: now,
      updatedAt: now,
    });

    await supabase.from('payments').upsert({
      orderId: `ABC-${reservationId.substring(4)}`,
      reservationId,
      userId: req.user.uid || null,
      status: 'pending_checkout',
      createdAt: now,
      updatedAt: now,
    });

    return res.status(200).json({
      status: 'success',
      reservationId,
      paymentUrl,
      fare: data.fare ? String(data.fare) : null,
    });
  } catch (error) {
    console.error('❌ ABC lock-and-pay error:', error.message);
    return res.status(500).json({ status: 'error', message: 'Could not communicate with ABC Upper Class.' });
  }
});

// ------------------- ZENOPAY V2 INTEGRATION -------------------

app.post("/api/payments/initialize", authenticateAppUser, async (req, res) => {
  const { amount, phone, orderId, busId, travelDate, seats } = req.body;

  if (!amount || !phone || !orderId || !busId || !travelDate || !Array.isArray(seats) || seats.length === 0) {
    return res.status(400).json({ status: "error", message: "Missing required booking details" });
  }

  try {
    if (!ZENOPAY_API_KEY || !ZENOPAY_ACCOUNT_ID) {
      return res.status(503).json({
        status: "failed",
        message: "ZenoPay is not configured on the backend",
      });
    }

    let formattedPhone = phone.trim().replace(/^\+/, '');
    if (formattedPhone.startsWith('0')) {
      formattedPhone = '255' + formattedPhone.substring(1);
    }

    const payload = {
      create_order: 1,
      order_id: orderId,
      buyer_email: req.user?.email || "customer@example.com",
      buyer_name: req.user?.name || "App Customer",
      buyer_phone: formattedPhone,
      amount: String(Math.round(Number(amount))),
      account_id: ZENOPAY_ACCOUNT_ID,
      webhook_url: `${req.protocol}://${req.get('host')}/zenopay-webhook?token=${ZENOPAY_WEBHOOK_SECRET || ''}`,
      metadata: { busId, travelDate, seats }
    };

    const response = await axios.post(`${ZENOPAY_BASE_URL}/payments/mobile_money_tanzania`, payload, {
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': ZENOPAY_API_KEY
      },
      timeout: 20000
    });

    const data = response.data;

    if (data.status === "success" && data.order_id) {
      const zenoOrderId = data.order_id;
      const now = new Date().toISOString();
      const pollDeadline = new Date(Date.now() + PAYMENT_POLL_TTL_SECONDS * 1000).toISOString();

      await supabase.from("payments").upsert({
        userId: req.user.uid,
        orderId,
        zenoOrderId,
        amount: Number(amount),
        phone: formattedPhone,
        busId,
        travelDate,
        seats,
        status: "pending",
        pollAttempts: 0,
        pollDeadline,
        createdAt: now,
        updatedAt: now
      });

      startImmediatePolling(orderId, zenoOrderId);

      return res.status(200).json({
        status: "pending",
        message: "USSD push sent. Please check your phone and enter PIN.",
        orderId,
        zenoOrderId
      });
    }

    throw new Error(data.message || "ZenoPay order creation failed");
  } catch (error) {
    console.error("❌ ZenoPay initialization error:", error.response?.data || error.message);
    return res.status(500).json({
      status: "failed",
      message: "Payment gateway error. Please try again."
    });
  }
});

async function startImmediatePolling(orderId, zenoOrderId, attempt = 1) {
  const MAX_ATTEMPTS = 12;
  const DELAY_MS = 5000;

  if (attempt > MAX_ATTEMPTS) {
    console.log(`[ImmediatePoll] Order ${orderId} timed out after ${MAX_ATTEMPTS} attempts.`);
    const { data: doc } = await supabase.from("payments").select("*").eq("orderId", orderId).maybeSingle();
    if (doc && doc.status === 'pending') {
      await supabase.from("payments").update({ status: 'failed', failReason: 'poll_timeout', updatedAt: new Date().toISOString() }).eq("orderId", orderId);
      await updateSeatReservationsForOrder(orderId, 'cancelled');
    }
    return;
  }

  setTimeout(async () => {
    try {
      const url = `${ZENOPAY_BASE_URL}/payments/order-status?order_id=${zenoOrderId}`;
      const response = await axios.get(url, {
        headers: { 'x-api-key': ZENOPAY_API_KEY },
        timeout: 10000
      });

      const remoteStatus = String(response.data?.payment_status || response.data?.status || "").toLowerCase();
      let finalStatus = null;
      if (["success", "completed", "paid"].includes(remoteStatus)) finalStatus = "completed";
      else if (["failed", "declined", "cancelled", "expired", "error"].includes(remoteStatus)) finalStatus = "failed";

      if (finalStatus) {
        await supabase.from("payments").update({ status: finalStatus, updatedAt: new Date().toISOString() }).eq("orderId", orderId);
        if (finalStatus === "completed") {
          await updateSeatReservationsForOrder(orderId, 'booked');
          console.log(`✅ Payment completed for order ${orderId}`);
        } else {
          await updateSeatReservationsForOrder(orderId, 'cancelled');
          console.log(`❌ Payment failed/cancelled for order ${orderId}`);
        }
        return;
      }

      startImmediatePolling(orderId, zenoOrderId, attempt + 1);
    } catch (err) {
      console.error(`[ImmediatePoll] Error checking status for order ${orderId}:`, err.message);
      startImmediatePolling(orderId, zenoOrderId, attempt + 1);
    }
  }, DELAY_MS);
}

async function updateSeatReservationsForOrder(orderId, newStatus) {
  if (!orderId) return;
  const now = new Date().toISOString();
  const updates = { status: newStatus, updatedAt: now };
  if (newStatus === 'booked') updates.bookedAt = now;

  await supabase
    .from('seat_reservations')
    .update(updates)
    .eq('orderId', orderId);
}

async function checkZenoPayStatusAndUpdate(orderDoc) {
  const { data: paymentData } = await supabase.from('payments').select('*').eq('orderId', orderDoc.orderId).maybeSingle();
  if (!paymentData) return null;

  const currentStatus = (paymentData.status || '').toLowerCase();
  if (currentStatus !== 'pending') return currentStatus;

  try {
    const url = `${ZENOPAY_BASE_URL}/payments/order-status?order_id=${paymentData.zenoOrderId}`;
    const response = await axios.get(url, {
      headers: { 'x-api-key': ZENOPAY_API_KEY },
      timeout: 15000
    });

    const remoteStatus = String(response.data?.payment_status || response.data?.status || "").toLowerCase();
    let computedStatus = 'pending';
    if (["success", "completed", "paid"].some(s => remoteStatus.includes(s))) computedStatus = 'completed';
    else if (["failed", "declined", "error", "cancelled", "expired"].some(s => remoteStatus.includes(s))) computedStatus = 'failed';

    const now = new Date().toISOString();
    const updates = {
      lastPolledAt: now,
      pollAttempts: (paymentData.pollAttempts || 0) + 1,
      updatedAt: now,
    };
    if (computedStatus !== 'pending') updates.status = computedStatus;

    await supabase.from('payments').update(updates).eq('orderId', paymentData.orderId);

    if (computedStatus !== 'pending') {
      if (computedStatus === 'completed') {
        await updateSeatReservationsForOrder(paymentData.orderId, 'booked');
      } else {
        await updateSeatReservationsForOrder(paymentData.orderId, 'cancelled');
      }
      return computedStatus;
    }

    if ((paymentData.pollAttempts || 0) + 1 >= PAYMENT_MAX_POLL_ATTEMPTS) {
      await supabase.from('payments').update({ status: 'failed', failReason: 'poll_exhausted', updatedAt: now }).eq('orderId', paymentData.orderId);
      await updateSeatReservationsForOrder(paymentData.orderId, 'cancelled');
      return 'failed';
    }
    return 'pending';
  } catch (err) {
    console.error("Status check error:", err.message);
    const now = new Date().toISOString();
    await supabase.from('payments').update({ pollAttempts: (paymentData.pollAttempts || 0) + 1, lastPolledAt: now }).eq('orderId', paymentData.orderId);
    return paymentData.status;
  }
}

app.post('/api/cancel-order', authenticateAppUser, async (req, res) => {
  const { orderId, reason } = req.body || {};
  if (!orderId) {
    return res.status(400).json({ status: 'error', message: 'Missing orderId' });
  }

  try {
    const { data: doc } = await supabase.from('payments').select('*').eq('orderId', orderId).maybeSingle();
    if (!doc) return res.status(404).json({ status: 'failed', message: 'Order not found' });

    if (doc.status === 'completed') {
      return res.status(400).json({ status: 'failed', message: 'Order already completed' });
    }

    await supabase.from('payments').update({
      status: 'cancelled',
      cancelReason: reason || 'user_cancelled',
      updatedAt: new Date().toISOString()
    }).eq('orderId', orderId);

    await updateSeatReservationsForOrder(orderId, 'cancelled');
    return res.status(200).json({ status: 'success', message: 'Order cancelled' });
  } catch (err) {
    console.error('❌ /api/cancel-order error:', err.message);
    return res.status(500).json({ status: 'error', message: 'Failed to cancel order' });
  }
});

app.get("/api/payments/status/:orderId", authenticateAppUser, async (req, res) => {
  const { orderId } = req.params;

  try {
    const { data: doc } = await supabase.from("payments").select("*").eq("orderId", orderId).maybeSingle();

    if (!doc) {
      return res.status(404).json({ status: "error", message: "Order records not found" });
    }

    let currentStatus = doc.status;
    if (currentStatus === "pending") {
      currentStatus = await checkZenoPayStatusAndUpdate(doc);
    }

    return res.status(200).json({ status: "success", orderId, paymentStatus: currentStatus });
  } catch (error) {
    console.error("❌ Polling fetch error:", error);
    return res.status(500).json({ status: "error", message: "Failed to resolve payment status" });
  }
});

app.post('/zenopay-webhook', async (req, res) => {
  const token = String(req.query.token || '').trim();
  if (ZENOPAY_WEBHOOK_SECRET && token !== ZENOPAY_WEBHOOK_SECRET) {
    console.warn('⚠️ Webhook rejected: invalid token');
    return res.status(403).json({ status: 'error', message: 'Invalid webhook token' });
  }

  const body = req.body || {};
  const zenoOrderId = String(body.order_id || body.zenoOrderId || '').trim();
  const remoteStatus = String(body.payment_status || body.status || '').toLowerCase();

  if (!zenoOrderId) {
    console.warn('⚠️ Webhook missing order_id');
    return res.status(400).json({ status: 'error', message: 'Missing order_id' });
  }

  let computedStatus = 'pending';
  if (["completed", "success", "paid"].includes(remoteStatus)) computedStatus = 'completed';
  else if (["failed", "declined", "error", "cancelled", "expired"].includes(remoteStatus)) computedStatus = 'failed';

  const { data: payments } = await supabase.from('payments').select('*').eq('zenoOrderId', zenoOrderId).limit(1);
  if (!payments || payments.length === 0) {
    console.warn(`⚠️ Webhook: no payment record for order ${zenoOrderId}`);
    return res.status(200).json({ status: 'ignored' });
  }

  const paymentData = payments[0];
  if (paymentData.status === computedStatus) {
    return res.status(200).json({ status: 'ok', message: 'No change' });
  }

  await supabase.from('payments').update({ status: computedStatus, updatedAt: new Date().toISOString() }).eq('orderId', paymentData.orderId);
  if (computedStatus === 'completed') await updateSeatReservationsForOrder(paymentData.orderId, 'booked');
  else if (['failed', 'cancelled'].includes(computedStatus)) await updateSeatReservationsForOrder(paymentData.orderId, 'cancelled');

  return res.status(200).json({ status: 'ok', message: 'processed' });
});

app.get('/', (req, res) => {
  res.status(200).json({ status: 'ok', service: 'online-booking-backend', timestamp: new Date().toISOString() });
});

async function cleanupExpiredReservations() {
  try {
    const now = new Date().toISOString();
    const { data } = await supabase
      .from('seat_reservations')
      .update({ status: 'cancelled', updatedAt: now })
      .eq('status', 'reserved')
      .lte('reservedUntil', now)
      .select();

    if (data && data.length > 0) {
      console.log(`✅ Cleaned ${data.length} expired reservations`);
      return data.length;
    }
    return 0;
  } catch (err) {
    console.error('❌ cleanupExpiredReservations error:', err.message);
    return -1;
  }
}

setInterval(async () => {
  try { await cleanupExpiredReservations(); } catch (err) { console.error('Periodic cleanup failed:', err.message); }
}, 60000);

const PORT = process.env.PORT || 10000;
const HOST = process.env.HOST || "0.0.0.0";
app.listen(PORT, HOST, () => {
  console.log(`🚀 Server running on ${HOST}:${PORT}`);
});
