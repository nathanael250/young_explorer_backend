const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");
const { query, transaction } = require("../config/database");
const { httpError, requireAdmin, requireFields, requireUser } = require("./modelUtils");

async function registerVendor(context) {
  const data = context.body.data || {};
  requireFields(data, ["first_name", "last_name", "email", "password", "business_name"]);

  if (String(data.password).length < 8) {
    throw httpError(400, "Password must be at least 8 characters");
  }

  const existing = await query("SELECT id FROM users WHERE email = ? LIMIT 1", [data.email]);
  if (existing.length) {
    throw httpError(409, "Email is already registered");
  }

  const ribCertificate = context.file ? `/uploads/${context.file.filename}` : data.rib_certificate || null;
  if (!ribCertificate) {
    throw httpError(400, "RIB certificate is required");
  }

  const created = await transaction(async (connection) => {
    const password = await bcrypt.hash(data.password, 10);
    const [userResult] = await connection.execute(
      `INSERT INTO users
        (first_name, last_name, email, phone, password, role, profile_image, status)
       VALUES (?, ?, ?, ?, ?, 'vendor', ?, 'active')`,
      [
        data.first_name,
        data.last_name,
        data.email,
        data.phone || null,
        password,
        data.profile_image || null,
      ]
    );

    const [vendorResult] = await connection.execute(
      `INSERT INTO vendors
        (user_id, business_name, business_phone, business_email, business_address, rib_certificate, approval_status)
       VALUES (?, ?, ?, ?, ?, ?, 'pending')`,
      [
        userResult.insertId,
        data.business_name,
        data.business_phone || data.phone || null,
        data.business_email || data.email,
        data.business_address || null,
        ribCertificate,
      ]
    );

    return findVendorById(vendorResult.insertId, connection);
  });

  return {
    statusCode: 201,
    message: "Vendor registration submitted for admin review",
    data: {
      vendor: created,
      token: signToken(created.user),
    },
  };
}

async function listVendors(context) {
  requireAdmin(context.user);

  const filters = context.body.filters || {};
  const page = Math.max(Number(context.body.page || 1), 1);
  const limit = Math.min(Math.max(Number(context.body.limit || 20), 1), 100);
  const offset = (page - 1) * limit;
  const clauses = [];
  const params = [];

  if (filters.approval_status) {
    clauses.push("v.approval_status = ?");
    params.push(filters.approval_status);
  }

  if (context.body.search) {
    clauses.push("(v.business_name LIKE ? OR u.email LIKE ? OR u.first_name LIKE ? OR u.last_name LIKE ?)");
    params.push(...Array(4).fill(`%${context.body.search}%`));
  }

  const where = clauses.length ? ` WHERE ${clauses.join(" AND ")}` : "";
  const rows = await query(
    `SELECT v.*, u.first_name, u.last_name, u.email, u.phone, u.status AS user_status
     FROM vendors v
     INNER JOIN users u ON u.id = v.user_id
     ${where}
     ORDER BY v.id DESC
     LIMIT ${limit} OFFSET ${offset}`,
    params
  );
  const totals = await query(
    `SELECT COUNT(*) AS total
     FROM vendors v
     INNER JOIN users u ON u.id = v.user_id
     ${where}`,
    params
  );

  return {
    data: {
      rows,
      pagination: {
        page,
        limit,
        total: totals[0].total,
      },
    },
  };
}

async function getVendor(context) {
  requireUser(context.user);

  const id = context.body.id || context.body.data?.id;
  const vendor = context.user.role === "admin" && id
    ? await findVendorById(id)
    : await findVendorByUserId(context.user.id);

  if (!vendor) {
    throw httpError(404, "Vendor not found");
  }

  if (context.user.role !== "admin" && vendor.user_id !== context.user.id) {
    throw httpError(403, "You are not allowed to view this vendor");
  }

  return { data: vendor };
}

async function reviewVendor(context) {
  requireAdmin(context.user);

  const data = context.body.data || {};
  requireFields(data, ["vendor_id", "approval_status"]);

  if (!["approved", "rejected", "blocked", "pending"].includes(data.approval_status)) {
    throw httpError(400, "Invalid vendor approval status");
  }

  await query(
    `UPDATE vendors
     SET approval_status = ?, review_notes = ?, reviewed_by = ?, reviewed_at = NOW()
     WHERE id = ?`,
    [data.approval_status, data.review_notes || null, context.user.id, data.vendor_id]
  );

  const vendor = await findVendorById(data.vendor_id);
  if (!vendor) {
    throw httpError(404, "Vendor not found");
  }

  return {
    message: `Vendor ${data.approval_status}`,
    data: vendor,
  };
}

async function requireApprovedVendor(user) {
  requireUser(user);

  if (user.role === "admin") {
    return null;
  }

  if (user.role !== "vendor") {
    throw httpError(403, "Vendor access is required");
  }

  const vendor = await findVendorByUserId(user.id);
  if (!vendor) {
    throw httpError(403, "Vendor profile was not found");
  }

  if (vendor.approval_status !== "approved") {
    throw httpError(403, "Vendor account is not approved yet");
  }

  return vendor;
}

async function findVendorById(id, connection = null) {
  const runner = connection || { execute: async (sql, params) => [await query(sql, params)] };
  const [rows] = await runner.execute(
    `SELECT v.*, u.first_name, u.last_name, u.email, u.phone, u.role, u.profile_image, u.status AS user_status
     FROM vendors v
     INNER JOIN users u ON u.id = v.user_id
     WHERE v.id = ?
     LIMIT 1`,
    [id]
  );
  const vendor = rows[0] || null;

  if (!vendor) {
    return null;
  }

  return {
    ...vendor,
    user: {
      id: vendor.user_id,
      first_name: vendor.first_name,
      last_name: vendor.last_name,
      email: vendor.email,
      phone: vendor.phone,
      role: vendor.role,
      profile_image: vendor.profile_image,
      status: vendor.user_status,
    },
  };
}

async function findVendorByUserId(userId) {
  const rows = await query(
    `SELECT v.*, u.first_name, u.last_name, u.email, u.phone, u.role, u.profile_image, u.status AS user_status
     FROM vendors v
     INNER JOIN users u ON u.id = v.user_id
     WHERE v.user_id = ?
     LIMIT 1`,
    [userId]
  );
  const vendor = rows[0] || null;

  if (!vendor) {
    return null;
  }

  return {
    ...vendor,
    user: {
      id: vendor.user_id,
      first_name: vendor.first_name,
      last_name: vendor.last_name,
      email: vendor.email,
      phone: vendor.phone,
      role: vendor.role,
      profile_image: vendor.profile_image,
      status: vendor.user_status,
    },
  };
}

function signToken(user) {
  return jwt.sign(
    {
      id: user.id,
      email: user.email,
      role: user.role,
    },
    process.env.JWT_SECRET || "young_explorers_dev_secret",
    { expiresIn: process.env.JWT_EXPIRES_IN || "7d" }
  );
}

module.exports = {
  registerVendor,
  listVendors,
  getVendor,
  reviewVendor,
  requireApprovedVendor,
  findVendorById,
  findVendorByUserId,
};
