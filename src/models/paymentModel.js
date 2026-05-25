const { transaction } = require("../config/database");
const resources = require("./resources");
const { insert, findById } = require("./dbHelpers");
const { findBookingById, findBookingForUser } = require("./bookingModel");
const { httpError, requireAdmin, requireFields, requireUser } = require("./modelUtils");

async function submitPayment(context) {
  requireUser(context.user);

  const data = context.body.data || {};
  requireFields(data, ["booking_id", "amount", "payment_method", "transaction_reference"]);

  const booking = await findBookingForUser(data.booking_id, context.user);
  if (!booking) {
    throw httpError(404, "Booking not found");
  }

  const paymentProof = context.file ? `/uploads/${context.file.filename}` : data.payment_proof || null;
  const result = await insert("payments", {
    booking_id: data.booking_id,
    amount: data.amount,
    payment_method: data.payment_method,
    transaction_reference: data.transaction_reference,
    payment_proof: paymentProof,
    payment_status: "pending",
  });
  const payment = await findById(resources.payments, result.insertId, ["*"]);

  return {
    statusCode: 201,
    message: "Payment submitted for verification",
    data: payment,
  };
}

async function verifyPayment(context) {
  requireAdmin(context.user);

  const data = context.body.data || {};
  requireFields(data, ["payment_id", "status"]);

  if (!["verified", "rejected"].includes(data.status)) {
    throw httpError(400, "Payment status must be verified or rejected");
  }

  const result = await transaction(async (connection) => {
    const [paymentRows] = await connection.execute(
      `SELECT p.*, b.total_people, b.availability_id, b.booking_status
       FROM payments p
       INNER JOIN bookings b ON b.id = p.booking_id
       WHERE p.id = ?
       FOR UPDATE`,
      [data.payment_id]
    );
    const payment = paymentRows[0];

    if (!payment) {
      throw httpError(404, "Payment not found");
    }

    await connection.execute("UPDATE payments SET payment_status = ?, paid_at = IF(? = 'verified', NOW(), paid_at) WHERE id = ?", [
      data.status,
      data.status,
      data.payment_id,
    ]);

    if (data.status === "verified" && payment.booking_status !== "confirmed") {
      await connection.execute("UPDATE bookings SET booking_status = 'confirmed', payment_status = 'paid' WHERE id = ?", [
        payment.booking_id,
      ]);
      await connection.execute(
        `UPDATE package_availability
         SET reserved_seats = GREATEST(reserved_seats - ?, 0),
             confirmed_seats = confirmed_seats + ?
         WHERE id = ?`,
        [payment.total_people, payment.total_people, payment.availability_id]
      );
    }

    if (data.status === "rejected") {
      await connection.execute("UPDATE bookings SET payment_status = 'unpaid' WHERE id = ?", [payment.booking_id]);
    }

    return findBookingById(payment.booking_id, connection);
  });

  return {
    message: "Payment verification updated",
    data: result,
  };
}

module.exports = {
  submitPayment,
  verifyPayment,
};
