const slugify = require("slugify");
const { query, transaction } = require("../config/database");
const resources = require("./resources");
const { insert, update, findById } = require("./dbHelpers");
const { httpError, requireAdmin, attachUploadedMainImage, uploadedImagePath, queryAsExecute } = require("./modelUtils");
const { requireApprovedVendor, findVendorByUserId } = require("./vendorModel");

async function listResource(context) {
  const config = getResourceConfig(context.body.resource);
  ensureCanRead(config, context.user);

  if (config.table === "bookings" && context.user?.role === "vendor") {
    return listVendorBookings(context);
  }

  const vendor = await resolveVendorFilter(config, context.user);

  const filters = context.body.filters || {};
  if (config.ownerField && context.user?.role !== "admin") {
    filters[config.ownerField] = context.user.id;
  }
  if (config.vendorOwned && vendor) {
    filters.vendor_id = vendor.id;
  }
  if (config.publicStatusField && context.user?.role !== "admin" && !vendor) {
    filters[config.publicStatusField] = config.publicStatus;
  }

  const search = context.body.search || "";
  const page = Math.max(Number(context.body.page || 1), 1);
  const limit = Math.min(Math.max(Number(context.body.limit || 20), 1), 100);
  const offset = (page - 1) * limit;
  const where = buildWhere(config, filters, search);

  let rows = await query(
    `SELECT ${config.listFields.join(", ")} FROM ${config.table}${where.sql} ORDER BY id DESC LIMIT ${limit} OFFSET ${offset}`,
    where.params
  );
  rows = await attachRelatedData(config, rows);
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

  if (config.table === "bookings" && context.user?.role === "vendor") {
    return getVendorBooking(context, id);
  }

  const row = await findById(config, id, ["*"]);
  if (!row) {
    throw httpError(404, "Resource not found");
  }

  ensureCanReadRow(config, row, context.user);
  await ensureCanAccessVendorRow(config, row, context.user);

  if (config.table === "destinations") {
    return { data: await findDestinationById(id) };
  }

  return { data: row };
}

async function listVendorBookings(context) {
  const vendor = await requireApprovedVendor(context.user);

  const search = context.body.search || "";
  const filters = context.body.filters || {};
  const page = Math.max(Number(context.body.page || 1), 1);
  const limit = Math.min(Math.max(Number(context.body.limit || 20), 1), 100);
  const offset = (page - 1) * limit;
  const clauses = ["p.vendor_id = ?"];
  const params = [vendor.id];

  for (const field of ["booking_status", "payment_status", "package_id", "availability_id"]) {
    if (filters[field]) {
      clauses.push(`b.${field} = ?`);
      params.push(filters[field]);
    }
  }

  if (search) {
    clauses.push("(b.booking_reference LIKE ? OR b.booking_status LIKE ? OR b.payment_status LIKE ?)");
    params.push(`%${search}%`, `%${search}%`, `%${search}%`);
  }

  const where = ` WHERE ${clauses.join(" AND ")}`;
  const rows = await query(
    `SELECT b.id, b.booking_reference, b.user_id, b.package_id, b.availability_id, b.total_people,
            b.total_amount, b.special_request, b.booking_type, b.vip_request_details,
            b.quoted_amount, b.quoted_currency, b.booking_status, b.payment_status, b.booked_at
     FROM bookings b
     INNER JOIN packages p ON p.id = b.package_id
     ${where}
     ORDER BY b.id DESC
     LIMIT ${limit} OFFSET ${offset}`,
    params
  );
  const totals = await query(
    `SELECT COUNT(*) AS total
     FROM bookings b
     INNER JOIN packages p ON p.id = b.package_id
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

async function getVendorBooking(context, id) {
  const vendor = await requireApprovedVendor(context.user);

  const rows = await query(
    `SELECT b.*
     FROM bookings b
     INNER JOIN packages p ON p.id = b.package_id
     WHERE b.id = ? AND p.vendor_id = ?
     LIMIT 1`,
    [id, vendor.id]
  );

  if (!rows.length) {
    throw httpError(404, "Booking not found");
  }

  return { data: rows[0] };
}

async function createResource(context) {
  const config = getResourceConfig(context.body.resource);
  const vendor = await ensureCanCreate(config, context.user);

  if (config.table === "destinations") {
    return createDestination(context, config, vendor);
  }

  const rawData = withUploadedMainImage(config, context.body.data || {}, context.file);
  const data = normalizeResourceData(config, rawData, context.user);
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
  const vendor = await ensureCanModify(config, context.user);

  const id = context.body.id || context.body.data?.id;
  if (!id) {
    throw httpError(400, "Resource id is required");
  }

  const existing = await findById(config, id, ["*"]);
  if (!existing) {
    throw httpError(404, "Resource not found");
  }
  ensureVendorOwnsRow(config, existing, vendor);

  const rawData = withUploadedMainImage(config, context.body.data || {}, context.file);
  const data = normalizeResourceData(config, rawData, context.user);
  delete data.id;
  if (vendor && config.vendorOwned) {
    delete data.vendor_id;
  }

  if (config.table === "destinations" && data.slug) {
    await ensureDestinationSlugIsAvailable(data.slug, existing.vendor_id || data.vendor_id || null, id);
  }

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
  const vendor = await ensureCanModify(config, context.user);

  const id = context.body.id || context.body.data?.id;
  if (!id) {
    throw httpError(400, "Resource id is required");
  }

  const existing = await findById(config, id, ["*"]);
  if (!existing) {
    throw httpError(404, "Resource not found");
  }
  ensureVendorOwnsRow(config, existing, vendor);

  await query(`DELETE FROM ${config.table} WHERE id = ?`, [id]);

  return {
    message: "Resource deleted",
    data: { id },
  };
}

async function createDestination(context, config, vendor = null) {
  const imageFiles = getDestinationImageFiles(context);
  const rawData = {
    ...attachUploadedMainImage(context.body.data || {}, imageFiles[0]),
    ...(vendor ? { vendor_id: vendor.id } : {}),
  };
  const data = normalizeResourceData(config, rawData, context.user);
  await ensureDestinationSlugIsAvailable(data.slug, data.vendor_id || null);

  const row = await transaction(async (connection) => {
    const fields = Object.keys(data);
    if (!fields.length) {
      throw httpError(400, "No valid fields were provided");
    }

    const placeholders = fields.map(() => "?").join(", ");
    const values = fields.map((field) => data[field]);
    const [result] = await connection.execute(
      `INSERT INTO destinations (${fields.join(", ")}) VALUES (${placeholders})`,
      values
    );

    await insertDestinationImages(connection, result.insertId, imageFiles);

    return findDestinationById(result.insertId, connection);
  });

  return {
    statusCode: 201,
    message: "Resource created",
    data: row,
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

function withUploadedMainImage(config, data, file) {
  if (!file || !config.writableFields.includes("main_image")) {
    return data;
  }

  return attachUploadedMainImage(data, file);
}

async function attachRelatedData(config, rows) {
  if (!rows.length) {
    return rows;
  }

  if (config.table === "destinations") {
    return attachDestinationImages(rows);
  }

  if (config.table !== "packages") {
    return rows;
  }

  const packageIds = rows.map((row) => row.id);
  const placeholders = packageIds.map(() => "?").join(", ");
  const images = await query(
    `SELECT id, package_id, image_path, sort_order, created_at
     FROM package_images
     WHERE package_id IN (${placeholders})
     ORDER BY sort_order ASC, id ASC`,
    packageIds
  );
  const imagesByPackageId = images.reduce((grouped, image) => {
    grouped[image.package_id] = grouped[image.package_id] || [];
    grouped[image.package_id].push(image);
    return grouped;
  }, {});
  const categories = await query(
    `SELECT pc.package_id, c.id, c.name, c.slug
     FROM package_categories pc
     INNER JOIN categories c ON c.id = pc.category_id
     WHERE pc.package_id IN (${placeholders}) AND c.status = 'active'
     ORDER BY c.name ASC`,
    packageIds
  );
  const categoriesByPackageId = categories.reduce((grouped, category) => {
    grouped[category.package_id] = grouped[category.package_id] || [];
    grouped[category.package_id].push({
      id: category.id,
      name: category.name,
      slug: category.slug,
    });
    return grouped;
  }, {});

  return rows.map((row) => ({
    ...row,
    images: imagesByPackageId[row.id] || [],
    categories: categoriesByPackageId[row.id] || [],
  }));
}

async function attachDestinationImages(rows) {
  const destinationIds = rows.map((row) => row.id);
  const placeholders = destinationIds.map(() => "?").join(", ");
  const images = await query(
    `SELECT id, destination_id, image_path, sort_order, created_at
     FROM destination_images
     WHERE destination_id IN (${placeholders})
     ORDER BY sort_order ASC, id ASC`,
    destinationIds
  );
  const imagesByDestinationId = images.reduce((grouped, image) => {
    grouped[image.destination_id] = grouped[image.destination_id] || [];
    grouped[image.destination_id].push(image);
    return grouped;
  }, {});

  return rows.map((row) => ({
    ...row,
    images: imagesByDestinationId[row.id] || [],
  }));
}

async function findDestinationById(destinationId, connection = null) {
  const runner = connection || { execute: (sql, params) => queryAsExecute(query, sql, params) };
  const [rows] = await runner.execute("SELECT * FROM destinations WHERE id = ? LIMIT 1", [destinationId]);
  const row = rows[0];

  if (!row) {
    throw httpError(404, "Destination not found");
  }

  const [images] = await runner.execute(
    "SELECT id, destination_id, image_path, sort_order, created_at FROM destination_images WHERE destination_id = ? ORDER BY sort_order ASC, id ASC",
    [destinationId]
  );

  return {
    ...row,
    images,
  };
}

function getDestinationImageFiles(context) {
  const galleryFiles = context.files?.destination_images || context.files?.images || [];
  const files = galleryFiles.length ? galleryFiles : [context.file].filter(Boolean);

  files.forEach((file) => uploadedImagePath(file));
  return files;
}

async function insertDestinationImages(connection, destinationId, files) {
  for (let index = 0; index < files.length; index += 1) {
    await connection.execute("INSERT INTO destination_images (destination_id, image_path, sort_order) VALUES (?, ?, ?)", [
      destinationId,
      uploadedImagePath(files[index]),
      index + 1,
    ]);
  }
}

async function ensureDestinationSlugIsAvailable(slug, vendorId, excludeId = null) {
  if (!slug) {
    return;
  }

  const params = [slug];
  let sql = "SELECT id FROM destinations WHERE slug = ?";

  if (vendorId) {
    sql += " AND vendor_id = ?";
    params.push(vendorId);
  } else {
    sql += " AND vendor_id IS NULL";
  }

  if (excludeId) {
    sql += " AND id <> ?";
    params.push(excludeId);
  }

  sql += " LIMIT 1";
  const rows = await query(sql, params);

  if (rows.length) {
    throw httpError(409, "This vendor already has a destination with that name");
  }
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
    return null;
  }

  if (config.vendorOwned && user?.role === "vendor") {
    return requireApprovedVendor(user);
  }

  requireAdmin(user);
  return null;
}

async function ensureCanModify(config, user) {
  if (config.vendorOwned && user?.role === "vendor") {
    return requireApprovedVendor(user);
  }

  requireAdmin(user);
  return null;
}

async function resolveVendorFilter(config, user) {
  if (!config.vendorOwned || user?.role !== "vendor") {
    return null;
  }

  return requireApprovedVendor(user);
}

async function ensureCanAccessVendorRow(config, row, user) {
  if (!config.vendorOwned || user?.role !== "vendor") {
    return;
  }

  const vendor = await findVendorByUserId(user.id);
  ensureVendorOwnsRow(config, row, vendor);
}

function ensureVendorOwnsRow(config, row, vendor) {
  if (!config.vendorOwned || !vendor) {
    return;
  }

  if (Number(row.vendor_id) !== Number(vendor.id)) {
    throw httpError(403, "You are not allowed to modify this resource");
  }
}

module.exports = {
  listResource,
  getResource,
  createResource,
  updateResource,
  deleteResource,
  normalizeResourceData,
};
