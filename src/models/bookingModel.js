const { query, transaction } = require("../config/database");
const { httpError, requireAdmin, requireFields, requireUser, queryAsExecute } = require("./modelUtils");
const { findVendorByUserId, requireApprovedVendor } = require("./vendorModel");

async function createBooking(context) {
  requireUser(context.user);

  const data = context.body.data || {};
  const bookingType = data.booking_type === "vip" || data.is_vip === true ? "vip" : "standard";
  const requiredFields = bookingType === "vip" ? ["package_id", "total_people", "vip_request_details"] : ["package_id", "availability_id", "total_people"];
  requireFields(data, requiredFields);
  if (bookingType === "vip" && !data.vip_contact_email && !data.vip_contact_phone) {
    throw httpError(400, "VIP contact email or phone is required");
  }

  const totalPeople = Number(data.total_people);
  if (!Number.isInteger(totalPeople) || totalPeople < 1) {
    throw httpError(400, "Total people must be at least 1");
  }

  if (data.participants && !Array.isArray(data.participants)) {
    throw httpError(400, "Participants must be an array");
  }

  if (Array.isArray(data.participants) && data.participants.length > totalPeople) {
    throw httpError(400, "Participants cannot exceed total people");
  }

  if (bookingType === "vip") {
    return createVipBooking(context, data, totalPeople);
  }

  const booking = await transaction(async (connection) => {
    const [availabilityRows] = await connection.execute(
      `SELECT pa.id, pa.package_id, pa.total_seats, pa.reserved_seats, pa.confirmed_seats,
        pa.booking_cutoff_hours, pa.status, p.status AS package_status, v.approval_status AS vendor_status,
        (pa.total_seats - pa.reserved_seats - pa.confirmed_seats) AS remaining_seats
       FROM package_availability pa
       INNER JOIN packages p ON p.id = pa.package_id
       LEFT JOIN vendors v ON v.id = p.vendor_id
       WHERE pa.id = ? AND pa.package_id = ?
       FOR UPDATE`,
      [data.availability_id, data.package_id]
    );
    const availability = availabilityRows[0];

    if (!availability || availability.status !== "available") {
      throw httpError(400, "Selected departure date is not available");
    }

    if (availability.package_status !== "published") {
      throw httpError(404, "Package not found");
    }

    if (availability.vendor_status && availability.vendor_status !== "approved") {
      throw httpError(400, "This vendor is not accepting bookings");
    }

    const [cutoffRows] = await connection.execute(
      "SELECT NOW() >= DATE_SUB(CAST(start_date AS DATETIME), INTERVAL booking_cutoff_hours HOUR) AS is_closed FROM package_availability WHERE id = ? LIMIT 1",
      [data.availability_id]
    );
    const isClosedByCutoff = cutoffRows[0]?.is_closed;
    if (isClosedByCutoff) {
      throw httpError(400, "Booking is closed for this departure date");
    }

    if (availability.remaining_seats < totalPeople) {
      throw httpError(409, "Not enough seats are available");
    }

    const [packageRows] = await connection.execute("SELECT price_per_person FROM packages WHERE id = ? LIMIT 1", [
      data.package_id,
    ]);
    const packageRow = packageRows[0];

    if (!packageRow) {
      throw httpError(404, "Package not found");
    }

    const totalAmount = Number(packageRow.price_per_person || 0) * totalPeople;
    const bookingReference = `YE-${Date.now()}-${Math.floor(Math.random() * 1000)}`;

    const [bookingResult] = await connection.execute(
      `INSERT INTO bookings
        (booking_reference, user_id, package_id, availability_id, total_people, total_amount, special_request, booking_type, booking_status, payment_status)
       VALUES (?, ?, ?, ?, ?, ?, ?, 'standard', 'pending', 'unpaid')`,
      [
        bookingReference,
        context.user.id,
        data.package_id,
        data.availability_id,
        totalPeople,
        totalAmount,
        data.special_request || null,
      ]
    );

    for (const participant of data.participants || []) {
      await connection.execute(
        `INSERT INTO booking_participants
          (booking_id, first_name, last_name, gender, date_of_birth, passport_number, nationality, emergency_contact)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
        [
          bookingResult.insertId,
          participant.first_name || null,
          participant.last_name || null,
          participant.gender || null,
          participant.date_of_birth || null,
          participant.passport_number || null,
          participant.nationality || null,
          participant.emergency_contact || null,
        ]
      );
    }

    await connection.execute("UPDATE package_availability SET reserved_seats = reserved_seats + ? WHERE id = ?", [
      totalPeople,
      data.availability_id,
    ]);

    return findBookingById(bookingResult.insertId, connection);
  });

  return {
    statusCode: 201,
    message: "Booking created",
    data: booking,
  };
}

async function createVipBooking(context, data, totalPeople) {
  const booking = await transaction(async (connection) => {
    const [packageRows] = await connection.execute(
      `SELECT p.id, p.price_per_person, p.currency, p.status, p.vendor_id, v.approval_status AS vendor_status
       FROM packages p
       LEFT JOIN vendors v ON v.id = p.vendor_id
       WHERE p.id = ?
       LIMIT 1`,
      [data.package_id]
    );
    const packageRow = packageRows[0];

    if (!packageRow || packageRow.status !== "published") {
      throw httpError(404, "Package not found");
    }

    if (packageRow.vendor_status && packageRow.vendor_status !== "approved") {
      throw httpError(400, "This vendor is not accepting VIP requests");
    }

    const bookingReference = `YE-VIP-${Date.now()}-${Math.floor(Math.random() * 1000)}`;
    const [bookingResult] = await connection.execute(
      `INSERT INTO bookings
        (booking_reference, user_id, package_id, availability_id, total_people, total_amount, special_request,
         booking_type, vip_request_details, vip_contact_name, vip_contact_email, vip_contact_phone, vip_preferred_contact,
         quoted_amount, quoted_currency, booking_status, payment_status)
       VALUES (?, ?, ?, ?, ?, 0, ?, 'vip', ?, ?, ?, ?, ?, NULL, ?, 'quote_pending', 'unpaid')`,
      [
        bookingReference,
        context.user.id,
        data.package_id,
        data.availability_id || null,
        totalPeople,
        data.special_request || null,
        data.vip_request_details,
        data.vip_contact_name || null,
        data.vip_contact_email || null,
        data.vip_contact_phone || null,
        data.vip_preferred_contact || null,
        data.quoted_currency || packageRow.currency || "USD",
      ]
    );

    for (const participant of data.participants || []) {
      await connection.execute(
        `INSERT INTO booking_participants
          (booking_id, first_name, last_name, gender, date_of_birth, passport_number, nationality, emergency_contact)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
        [
          bookingResult.insertId,
          participant.first_name || null,
          participant.last_name || null,
          participant.gender || null,
          participant.date_of_birth || null,
          participant.passport_number || null,
          participant.nationality || null,
          participant.emergency_contact || null,
        ]
      );
    }

    return findBookingById(bookingResult.insertId, connection);
  });

  return {
    statusCode: 201,
    message: "VIP request submitted for pricing review",
    data: booking,
  };
}

async function quoteVipBooking(context) {
  const managerVendor = await getBookingManagerVendor(context.user);
  const data = context.body.data || {};
  requireFields(data, ["booking_id", "quoted_amount"]);

  const quotedAmount = Number(data.quoted_amount);
  if (!Number.isFinite(quotedAmount) || quotedAmount < 0) {
    throw httpError(400, "Quoted amount must be a valid number");
  }

  const booking = await transaction(async (connection) => {
    const [rows] = await connection.execute(
      `SELECT b.id, b.booking_type, b.package_id, p.vendor_id
       FROM bookings b
       INNER JOIN packages p ON p.id = b.package_id
       WHERE b.id = ?
       FOR UPDATE`,
      [data.booking_id]
    );
    const current = rows[0];

    if (!current) {
      throw httpError(404, "Booking not found");
    }

    if (current.booking_type !== "vip") {
      throw httpError(400, "Only VIP bookings can be quoted");
    }

    if (managerVendor && Number(current.vendor_id) !== Number(managerVendor.id)) {
      throw httpError(403, "You are not allowed to quote this VIP booking");
    }

    await connection.execute(
      `UPDATE bookings
       SET quoted_amount = ?, quoted_currency = ?, total_amount = ?, booking_status = 'pending'
       WHERE id = ?`,
      [quotedAmount, data.quoted_currency || "USD", quotedAmount, data.booking_id]
    );

    return findBookingById(data.booking_id, connection);
  });

  return {
    message: "VIP booking invoice amount recorded",
    data: booking,
  };
}

async function markVipBookingPaid(context) {
  const managerVendor = await getBookingManagerVendor(context.user);
  const data = context.body.data || {};
  requireFields(data, ["booking_id"]);

  const paidAmount = data.paid_amount === undefined ? null : Number(data.paid_amount);
  if (paidAmount !== null && (!Number.isFinite(paidAmount) || paidAmount < 0)) {
    throw httpError(400, "Paid amount must be a valid number");
  }

  const booking = await transaction(async (connection) => {
    const [rows] = await connection.execute(
      `SELECT b.id, b.booking_type, b.total_amount, b.quoted_amount, b.quoted_currency, b.package_id, p.vendor_id
       FROM bookings b
       INNER JOIN packages p ON p.id = b.package_id
       WHERE b.id = ?
       FOR UPDATE`,
      [data.booking_id]
    );
    const current = rows[0];

    if (!current) {
      throw httpError(404, "Booking not found");
    }

    if (current.booking_type !== "vip") {
      throw httpError(400, "Only VIP bookings can be marked paid with this command");
    }

    if (managerVendor && Number(current.vendor_id) !== Number(managerVendor.id)) {
      throw httpError(403, "You are not allowed to mark this VIP booking as paid");
    }

    const finalAmount = paidAmount !== null ? paidAmount : Number(current.quoted_amount || current.total_amount || 0);
    await connection.execute(
      `UPDATE bookings
       SET total_amount = ?, quoted_amount = COALESCE(quoted_amount, ?), quoted_currency = ?,
           booking_status = 'confirmed', payment_status = 'paid'
       WHERE id = ?`,
      [finalAmount, finalAmount, data.currency || current.quoted_currency || "USD", data.booking_id]
    );

    return findBookingById(data.booking_id, connection);
  });

  return {
    message: "VIP booking marked as paid",
    data: booking,
  };
}

async function getBookingManagerVendor(user) {
  if (user?.role === "vendor") {
    return requireApprovedVendor(user);
  }

  requireAdmin(user);
  return null;
}

async function cancelBooking(context) {
  requireUser(context.user);

  const id = context.body.id || context.body.data?.id;
  if (!id) {
    throw httpError(400, "Booking id is required");
  }

  const booking = await transaction(async (connection) => {
    const [rows] = await connection.execute("SELECT * FROM bookings WHERE id = ? FOR UPDATE", [id]);
    const current = rows[0];

    if (!current) {
      throw httpError(404, "Booking not found");
    }

    if (context.user.role !== "admin" && current.user_id !== context.user.id) {
      throw httpError(403, "You are not allowed to cancel this booking");
    }

    if (["cancelled", "completed", "expired"].includes(current.booking_status)) {
      return findBookingById(id, connection);
    }

    if (current.booking_status === "pending") {
      await connection.execute(
        "UPDATE package_availability SET reserved_seats = GREATEST(reserved_seats - ?, 0) WHERE id = ?",
        [current.total_people, current.availability_id]
      );
    }

    if (current.booking_status === "confirmed") {
      await connection.execute(
        "UPDATE package_availability SET confirmed_seats = GREATEST(confirmed_seats - ?, 0) WHERE id = ?",
        [current.total_people, current.availability_id]
      );
    }

    await connection.execute("UPDATE bookings SET booking_status = 'cancelled' WHERE id = ?", [id]);

    return findBookingById(id, connection);
  });

  return {
    message: "Booking cancelled",
    data: booking,
  };
}

async function expirePendingBookings(context) {
  requireAdmin(context.user);

  const hours = Math.max(Number(context.body.data?.hours || 48), 1);
  const expired = await transaction(async (connection) => {
    const [rows] = await connection.execute(
      `SELECT id, availability_id, total_people
       FROM bookings
       WHERE booking_status = 'pending'
         AND booked_at < DATE_SUB(NOW(), INTERVAL ? HOUR)
       FOR UPDATE`,
      [hours]
    );

    for (const booking of rows) {
      await connection.execute(
        "UPDATE package_availability SET reserved_seats = GREATEST(reserved_seats - ?, 0) WHERE id = ?",
        [booking.total_people, booking.availability_id]
      );
      await connection.execute("UPDATE bookings SET booking_status = 'expired' WHERE id = ?", [booking.id]);
    }

    return rows;
  });

  return {
    message: "Pending bookings expired",
    data: {
      expired_count: expired.length,
      bookings: expired,
    },
  };
}

async function findBookingById(bookingId, connection = null) {
  const runner = connection || { execute: (sql, params) => queryAsExecute(query, sql, params) };
  const [bookingRows] = await runner.execute(
    `SELECT b.*, p.title AS package_title, pa.start_date, pa.end_date
     FROM bookings b
     LEFT JOIN packages p ON p.id = b.package_id
     LEFT JOIN package_availability pa ON pa.id = b.availability_id
     WHERE b.id = ?
     LIMIT 1`,
    [bookingId]
  );
  const booking = bookingRows[0];

  if (!booking) {
    throw httpError(404, "Booking not found");
  }

  const [participants] = await runner.execute("SELECT * FROM booking_participants WHERE booking_id = ? ORDER BY id ASC", [
    bookingId,
  ]);
  const [payments] = await runner.execute("SELECT * FROM payments WHERE booking_id = ? ORDER BY id DESC", [bookingId]);

  return {
    ...booking,
    participants,
    payments,
  };
}

async function findBookingForUser(bookingId, user) {
  const rows = await query("SELECT * FROM bookings WHERE id = ? AND (user_id = ? OR ? = 'admin') LIMIT 1", [
    bookingId,
    user.id,
    user.role,
  ]);

  return rows[0] || null;
}

module.exports = {
  createBooking,
  quoteVipBooking,
  markVipBookingPaid,
  cancelBooking,
  expirePendingBookings,
  findBookingById,
  findBookingForUser,
};
