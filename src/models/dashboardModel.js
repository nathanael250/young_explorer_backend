const { query } = require("../config/database");
const { requireAdmin } = require("./modelUtils");

async function getDashboardStats(context) {
  requireAdmin(context.user);

  const [totals, upcomingTours, recentBookings] = await Promise.all([
    query(`
      SELECT
        (SELECT COUNT(*) FROM packages) AS total_packages,
        (SELECT COUNT(*) FROM bookings) AS total_bookings,
        (SELECT COUNT(*) FROM users) AS total_users,
        (SELECT COUNT(*) FROM payments) AS total_payments,
        (SELECT COUNT(*) FROM messages) AS total_messages
    `),
    query(`
      SELECT pa.id, pa.package_id, p.title, pa.start_date, pa.end_date, pa.total_seats,
             pa.reserved_seats, pa.confirmed_seats,
             (pa.total_seats - pa.reserved_seats - pa.confirmed_seats) AS remaining_seats
      FROM package_availability pa
      INNER JOIN packages p ON p.id = pa.package_id
      WHERE pa.start_date >= CURDATE() AND pa.status = 'available'
      ORDER BY pa.start_date ASC
      LIMIT 10
    `),
    query(`
      SELECT b.id, b.booking_reference, b.total_people, b.total_amount, b.booking_status,
             b.payment_status, b.booked_at, p.title AS package_title,
             u.first_name, u.last_name
      FROM bookings b
      LEFT JOIN packages p ON p.id = b.package_id
      LEFT JOIN users u ON u.id = b.user_id
      ORDER BY b.id DESC
      LIMIT 10
    `),
  ]);

  return {
    data: {
      totals: totals[0],
      upcoming_tours: upcomingTours,
      recent_bookings: recentBookings,
    },
  };
}

module.exports = {
  getDashboardStats,
};
