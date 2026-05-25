const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");
const { query } = require("../config/database");
const resources = require("./resources");
const { insert, findById } = require("./dbHelpers");
const { httpError, requireAdmin, requireFields, requireUser } = require("./modelUtils");

async function register(data) {
  requireFields(data, ["first_name", "last_name", "email", "password"]);

  if (String(data.password).length < 8) {
    throw httpError(400, "Password must be at least 8 characters");
  }

  const existing = await query("SELECT id FROM users WHERE email = ? LIMIT 1", [data.email]);
  if (existing.length) {
    throw httpError(409, "Email is already registered");
  }

  const password = await bcrypt.hash(data.password, 10);
  const wantsAdmin = data.role === "admin";
  if (wantsAdmin && data.admin_registration_token !== process.env.ADMIN_REGISTRATION_TOKEN) {
    throw httpError(403, "Admin registration is not allowed");
  }
  const role = wantsAdmin ? "admin" : "explorer";

  const result = await insert("users", {
    first_name: data.first_name,
    last_name: data.last_name,
    email: data.email,
    phone: data.phone || null,
    password,
    role,
    profile_image: data.profile_image || null,
    status: "active",
  });

  const user = await findById(resources.users, result.insertId, resources.users.listFields);

  return {
    statusCode: 201,
    message: "Account created",
    data: { user, token: signToken(user) },
  };
}

async function login(data) {
  requireFields(data, ["email", "password"]);

  const rows = await query("SELECT * FROM users WHERE email = ? LIMIT 1", [data.email]);
  const user = rows[0];

  if (!user || !(await bcrypt.compare(data.password, user.password))) {
    throw httpError(401, "Invalid email or password");
  }

  if (user.status !== "active") {
    throw httpError(403, "Account is not active");
  }

  delete user.password;

  return {
    message: "Logged in",
    data: { user, token: signToken(user) },
  };
}

async function getCurrentUser(user) {
  requireUser(user);

  const rows = await query(`SELECT ${resources.users.listFields.join(", ")} FROM users WHERE id = ? LIMIT 1`, [user.id]);

  if (!rows.length) {
    throw httpError(404, "User not found");
  }

  return { data: rows[0] };
}

async function updateProfile(context) {
  requireUser(context.user);

  const data = context.body.data || {};
  const allowed = ["first_name", "last_name", "phone", "profile_image"];
  const updates = {};

  for (const field of allowed) {
    if (Object.prototype.hasOwnProperty.call(data, field)) {
      updates[field] = data[field];
    }
  }

  if (!Object.keys(updates).length) {
    throw httpError(400, "No valid profile fields were provided");
  }

  const fields = Object.keys(updates);
  const assignments = fields.map((field) => `${field} = ?`).join(", ");
  const values = fields.map((field) => updates[field]);
  await query(`UPDATE users SET ${assignments} WHERE id = ?`, [...values, context.user.id]);

  return getCurrentUser(context.user);
}

async function changePassword(context) {
  requireUser(context.user);

  const data = context.body.data || {};
  requireFields(data, ["current_password", "new_password"]);

  if (String(data.new_password).length < 8) {
    throw httpError(400, "New password must be at least 8 characters");
  }

  const rows = await query("SELECT id, password FROM users WHERE id = ? LIMIT 1", [context.user.id]);
  const user = rows[0];

  if (!user || !(await bcrypt.compare(data.current_password, user.password))) {
    throw httpError(401, "Current password is incorrect");
  }

  const password = await bcrypt.hash(data.new_password, 10);
  await query("UPDATE users SET password = ? WHERE id = ?", [password, context.user.id]);

  return { message: "Password updated" };
}

async function setUserStatus(context) {
  requireAdmin(context.user);

  const data = context.body.data || {};
  requireFields(data, ["user_id", "status"]);

  if (!["active", "inactive", "blocked"].includes(data.status)) {
    throw httpError(400, "Invalid user status");
  }

  await query("UPDATE users SET status = ? WHERE id = ?", [data.status, data.user_id]);
  const user = await findById(resources.users, data.user_id, resources.users.listFields);

  if (!user) {
    throw httpError(404, "User not found");
  }

  return {
    message: "User status updated",
    data: user,
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
  register,
  login,
  getCurrentUser,
  updateProfile,
  changePassword,
  setUserStatus,
};
