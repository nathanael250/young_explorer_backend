const mysql = require("mysql2/promise");

const pool = mysql.createPool({
  host: process.env.DB_HOST || "127.0.0.1",
  port: Number(process.env.DB_PORT || 3306),
  user: process.env.DB_USER || "root",
  password: process.env.DB_PASSWORD || "",
  database: process.env.DB_NAME || "young_explorers",
  waitForConnections: true,
  connectionLimit: Number(process.env.DB_CONNECTION_LIMIT || 10),
  queueLimit: 0,
  namedPlaceholders: true,
});

async function query(sql, params = []) {
  const [rows] = await pool.execute(sql, params);
  return rows;
}

async function transaction(work) {
  const connection = await pool.getConnection();

  try {
    await connection.beginTransaction();
    const result = await work(connection);
    await connection.commit();
    return result;
  } catch (error) {
    await connection.rollback();
    throw error;
  } finally {
    connection.release();
  }
}

async function testConnection() {
  const connection = await pool.getConnection();
  connection.release();
}

async function seedDefaultDurations() {
  const defaults = [
    ["3 Days", 3],
    ["5 Days", 5],
    ["7 Days", 7],
    ["14 Days", 14],
  ];

  for (const [title, totalDays] of defaults) {
    await query(
      `INSERT INTO package_durations (title, total_days, status)
       SELECT ?, ?, 'active'
       WHERE NOT EXISTS (
         SELECT 1 FROM package_durations WHERE total_days = ?
       )`,
      [title, totalDays, totalDays]
    );
  }
}

async function checkSchema() {
  const requiredColumns = [
    ["packages", "price_per_person"],
    ["packages", "currency"],
    ["packages", "vendor_id"],
    ["destinations", "vendor_id"],
    ["package_availability", "remaining_seats"],
    ["package_availability", "booking_cutoff_hours"],
    ["bookings", "special_request"],
    ["bookings", "booking_type"],
    ["bookings", "vip_request_details"],
    ["bookings", "vip_contact_name"],
    ["bookings", "vip_contact_email"],
    ["bookings", "vip_contact_phone"],
    ["bookings", "vip_preferred_contact"],
    ["bookings", "quoted_amount"],
    ["bookings", "quoted_currency"],
  ];
  const requiredTables = ["package_images", "destination_images", "vendors", "categories", "package_categories"];
  const missing = [];

  for (const [table, column] of requiredColumns) {
    const rows = await query(
      `SELECT COUNT(*) AS total
       FROM INFORMATION_SCHEMA.COLUMNS
       WHERE TABLE_SCHEMA = DATABASE()
         AND TABLE_NAME = ?
         AND COLUMN_NAME = ?`,
      [table, column]
    );

    if (!rows[0].total) {
      missing.push(`${table}.${column}`);
    }
  }

  for (const table of requiredTables) {
    const rows = await query(
      `SELECT COUNT(*) AS total
       FROM INFORMATION_SCHEMA.TABLES
       WHERE TABLE_SCHEMA = DATABASE()
         AND TABLE_NAME = ?`,
      [table]
    );

    if (!rows[0].total) {
      missing.push(table);
    }
  }

  if (missing.length) {
    console.warn(`Missing database schema: ${missing.join(", ")}. Run the files in src/config/migrations.`);
  }
}

module.exports = {
  pool,
  query,
  transaction,
  testConnection,
  seedDefaultDurations,
  checkSchema,
};
