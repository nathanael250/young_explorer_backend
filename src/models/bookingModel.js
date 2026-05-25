const { query, transaction } = require("../config/database");
const { httpError, requireAdmin, requireFields, requireUser, queryAsExecute } = require("./modelUtils");

async function createBooking(context) {
  requireUser(context.user);

  const data = context.body.data || {};
  requireFields(data, ["package_id", "availability_id", "total_people"]);

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

  const booking = await transaction(async (connection) => {
    const [availabilityRows] = await connection.execute(
      `SELECT id, package_id, total_seats, reserved_seats, confirmed_seats, status,
        (total_seats - reserved_seats - confirmed_seats) AS remaining_seats
       FROM package_availability
       WHERE id = ? AND package_id = ?
       FOR UPDATE`,
      [data.availability_id, data.package_id]
    );
    const availability = availabilityRows[0];

    if (!availability || availability.status !== "available") {
      throw httpError(400, "Selected departure date is not available");
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
        (booking_reference, user_id, package_id, availability_id, total_people, total_amount, booking_status, payment_status)
       VALUES (?, ?, ?, ?, ?, ?, 'pending', 'unpaid')`,
      [bookingReference, context.user.id, data.package_id, data.availability_id, totalPeople, totalAmount]
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
  cancelBooking,
  expirePendingBookings,
  findBookingById,
  findBookingForUser,
};
