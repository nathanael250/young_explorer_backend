const slugify = require("slugify");
const { query } = require("../config/database");
const resources = require("./resources");
const { insert, update, findById } = require("./dbHelpers");
const { httpError, requireAdmin } = require("./modelUtils");

async function listResource(context) {
  const config = getResourceConfig(context.body.resource);
  ensureCanRead(config, context.user);

  const filters = context.body.filters || {};
  if (config.ownerField && context.user?.role !== "admin") {
    filters[config.ownerField] = context.user.id;
  }
  if (config.publicStatusField && context.user?.role !== "admin") {
    filters[config.publicStatusField] = config.publicStatus;
  }

  const search = context.body.search || "";
  const page = Math.max(Number(context.body.page || 1), 1);
  const limit = Math.min(Math.max(Number(context.body.limit || 20), 1), 100);
  const offset = (page - 1) * limit;
  const where = buildWhere(config, filters, search);

  const rows = await query(
    `SELECT ${config.listFields.join(", ")} FROM ${config.table}${where.sql} ORDER BY id DESC LIMIT ${limit} OFFSET ${offset}`,
    where.params
  );
  const totals = await query(`SELECT COUNT(*) AS total FROM ${config.table}${where.sql}`, where.params);

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

async function getResource(context) {
  const config = getResourceConfig(context.body.resource);
  ensureCanRead(config, context.user);

  const id = context.body.id || context.body.data?.id;
  if (!id) {
    throw httpError(400, "Resource id is required");
  }

  const row = await findById(config, id, ["*"]);
  if (!row) {
    throw httpError(404, "Resource not found");
  }

  ensureCanReadRow(config, row, context.user);

  return { data: row };
}

async function createResource(context) {
  const config = getResourceConfig(context.body.resource);
  ensureCanCreate(config, context.user);

  const data = normalizeResourceData(config, context.body.data || {}, context.user);
  const result = await insert(config.table, data);
  const row = await findById(config, result.insertId, ["*"]);

  return {
    statusCode: 201,
    message: "Resource created",
    data: row,
  };
}

async function updateResource(context) {
  const config = getResourceConfig(context.body.resource);
  requireAdmin(context.user);

  const id = context.body.id || context.body.data?.id;
  if (!id) {
    throw httpError(400, "Resource id is required");
  }

  const data = normalizeResourceData(config, context.body.data || {}, context.user);
  delete data.id;

  if (!Object.keys(data).length) {
    throw httpError(400, "No valid fields were provided");
  }

  await update(config.table, id, data);
  const row = await findById(config, id, ["*"]);

  return {
    message: "Resource updated",
    data: row,
  };
}

async function deleteResource(context) {
  const config = getResourceConfig(context.body.resource);
  requireAdmin(context.user);

  const id = context.body.id || context.body.data?.id;
  if (!id) {
    throw httpError(400, "Resource id is required");
  }

  await query(`DELETE FROM ${config.table} WHERE id = ?`, [id]);

  return {
    message: "Resource deleted",
    data: { id },
  };
}

function normalizeResourceData(config, data, user) {
  const filtered = {};

  for (const field of config.writableFields) {
    if (Object.prototype.hasOwnProperty.call(data, field)) {
      filtered[field] = data[field];
    }
  }

  if (config.table === "packages") {
    if (filtered.title && !filtered.slug) {
      filtered.slug = slugify(filtered.title, { lower: true, strict: true });
    }

    if (user && !filtered.created_by) {
      filtered.created_by = user.id;
    }
  }

  if (config.table === "destinations" && filtered.name && !filtered.slug) {
    filtered.slug = slugify(filtered.name, { lower: true, strict: true });
  }

  if (config.table === "bookings" && !filtered.booking_reference) {
    filtered.booking_reference = `YE-${Date.now()}`;
  }

  if (config.table === "users" && filtered.password) {
    throw httpError(400, "Use REGISTER or a dedicated password command for passwords");
  }

  return filtered;
}

function buildWhere(config, filters, search) {
  const clauses = [];
  const params = [];

  for (const [field, value] of Object.entries(filters)) {
    if (!config.listFields.includes(field) || value === undefined || value === "") {
      continue;
    }

    clauses.push(`${field} = ?`);
    params.push(value);
  }

  if (search && config.searchableFields.length) {
    const searchClauses = config.searchableFields.map((field) => `${field} LIKE ?`);
    clauses.push(`(${searchClauses.join(" OR ")})`);
    params.push(...config.searchableFields.map(() => `%${search}%`));
  }

  return {
    sql: clauses.length ? ` WHERE ${clauses.join(" AND ")}` : "",
    params,
  };
}

function getResourceConfig(resource) {
  const config = resources[resource];

  if (!config) {
    throw httpError(400, "Unknown resource");
  }

  return config;
}

function ensureCanRead(config, user) {
  if (!config.publicList && !user) {
    throw httpError(401, "Authentication is required");
  }

  if (config.adminOnlyRead) {
    requireAdmin(user);
  }
}

function ensureCanReadRow(config, row, user) {
  if (config.adminOnlyRead) {
    requireAdmin(user);
  }

  if (config.ownerField && user?.role !== "admin" && row[config.ownerField] !== user?.id) {
    throw httpError(403, "You are not allowed to view this resource");
  }

  if (config.publicStatusField && user?.role !== "admin" && row[config.publicStatusField] !== config.publicStatus) {
    throw httpError(404, "Resource not found");
  }
}

function ensureCanCreate(config, user) {
  if (config.publicCreate) {
    return;
  }

  requireAdmin(user);
}

module.exports = {
  listResource,
  getResource,
  createResource,
  updateResource,
  deleteResource,
  normalizeResourceData,
};
