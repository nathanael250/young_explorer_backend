const { query, transaction } = require("../config/database");
const slugify = require("slugify");
const resources = require("./resources");
const { normalizeResourceData } = require("./resourceModel");
const { update, findById } = require("./dbHelpers");
const { httpError, requireAdmin, requireFields, attachUploadedMainImage, uploadedImagePath, queryAsExecute } = require("./modelUtils");
const { requireApprovedVendor, findVendorByUserId } = require("./vendorModel");

async function createPackageWithDays(context) {
  const vendor = await requirePackageManager(context.user);

  const imageFiles = getPackageImageFiles(context);
  const data = attachUploadedMainImage(context.body.data || {}, imageFiles[0]);
  requireFields(data, ["title", "duration_id"]);

  const createdPackage = await transaction(async (connection) => {
    const [durationRows] = await connection.execute(
      "SELECT id, total_days FROM package_durations WHERE id = ? AND status = 'active' LIMIT 1",
      [data.duration_id]
    );
    const duration = durationRows[0];

    if (!duration) {
      throw httpError(400, "Active package duration was not found. Use LIST_DURATIONS and send an active duration id.");
    }

    const packageData = normalizeResourceData(resources.packages, data, context.user);
    if (vendor) {
      packageData.vendor_id = vendor.id;
    } else if (!packageData.vendor_id) {
      packageData.vendor_id = 0;
    }
    const fields = Object.keys(packageData);
    const placeholders = fields.map(() => "?").join(", ");
    const values = fields.map((field) => packageData[field]);
    const [packageResult] = await connection.execute(
      `INSERT INTO packages (${fields.join(", ")}) VALUES (${placeholders})`,
      values
    );
    await insertPackageImages(connection, packageResult.insertId, imageFiles);
    await syncPackageCategories(connection, packageResult.insertId, data);

    for (let dayNumber = 1; dayNumber <= duration.total_days; dayNumber += 1) {
      await connection.execute(
        "INSERT INTO package_days (package_id, day_number, title, summary) VALUES (?, ?, ?, ?)",
        [packageResult.insertId, dayNumber, `Day ${dayNumber}`, ""]
      );
    }

    return findPackageDetailsById(packageResult.insertId, connection);
  });

  return {
    statusCode: 201,
    message: "Package created with itinerary days",
    data: createdPackage,
  };
}

async function getPackageDetails(context) {
  const id = context.body.id || context.body.data?.id;
  const slug = context.body.slug || context.body.data?.slug;

  if (!id && !slug) {
    throw httpError(400, "Package id or slug is required");
  }

  const packageRows = id
    ? await query("SELECT id FROM packages WHERE id = ? LIMIT 1", [id])
    : await query("SELECT id FROM packages WHERE slug = ? LIMIT 1", [slug]);

  if (!packageRows.length) {
    throw httpError(404, "Package not found");
  }

  const details = await findPackageDetailsById(packageRows[0].id);
  const vendor = context.user?.role === "vendor" ? await findVendorByUserId(context.user.id) : null;
  const isOwnerVendor = vendor && Number(details.vendor_id) === Number(vendor.id);
  if (context.user?.role !== "admin" && !isOwnerVendor && details.status !== "published") {
    throw httpError(404, "Package not found");
  }

  return { data: details };
}

async function updatePackage(context) {
  const vendor = await requirePackageManager(context.user);

  const id = context.body.id || context.body.data?.id;
  const imageFiles = getPackageImageFiles(context);
  const data = attachUploadedMainImage(context.body.data || {}, imageFiles[0]);

  if (!id) {
    throw httpError(400, "Package id is required");
  }

  const updatedPackage = await transaction(async (connection) => {
    const [existingRows] = await connection.execute("SELECT id, duration_id, vendor_id FROM packages WHERE id = ? LIMIT 1", [id]);
    const existing = existingRows[0];

    if (!existing) {
      throw httpError(404, "Package not found");
    }
    ensurePackageOwner(existing, vendor);

    const packageData = normalizeResourceData(resources.packages, data, context.user);
    delete packageData.id;
    if (vendor) {
      delete packageData.vendor_id;
    }

    if (Object.keys(packageData).length) {
      const fields = Object.keys(packageData);
      const assignments = fields.map((field) => `${field} = ?`).join(", ");
      const values = fields.map((field) => packageData[field]);
      await connection.execute(`UPDATE packages SET ${assignments} WHERE id = ?`, [...values, id]);
    }
    await insertPackageImages(connection, id, imageFiles);
    await syncPackageCategories(connection, id, data);

    if (data.duration_id && Number(data.duration_id) !== Number(existing.duration_id)) {
      await syncPackageDays(connection, id, data.duration_id);
    }

    return findPackageDetailsById(id, connection);
  });

  return {
    message: "Package updated",
    data: updatedPackage,
  };
}

async function setPackageRules(context) {
  const vendor = await requirePackageManager(context.user);

  const data = context.body.data || {};
  requireFields(data, ["package_id"]);

  const rules = [
    ["package_inclusions", data.inclusions || []],
    ["package_exclusions", data.exclusions || []],
    ["package_required_items", data.required_items || []],
    ["package_not_allowed_items", data.not_allowed_items || []],
  ];

  const details = await transaction(async (connection) => {
    await assertPackageExists(connection, data.package_id, vendor);

    for (const [table, items] of rules) {
      if (!Array.isArray(items)) {
        throw httpError(400, `${table} must be an array`);
      }

      await connection.execute(`DELETE FROM ${table} WHERE package_id = ?`, [data.package_id]);

      for (const item of items) {
        const value = typeof item === "string" ? item : item.item;
        if (value) {
          await connection.execute(`INSERT INTO ${table} (package_id, item) VALUES (?, ?)`, [data.package_id, value]);
        }
      }
    }

    return findPackageDetailsById(data.package_id, connection);
  });

  return {
    message: "Package rules updated",
    data: details,
  };
}

async function createAvailability(context) {
  const vendor = await requirePackageManager(context.user);

  const data = context.body.data || {};
  requireFields(data, ["package_id", "start_date", "end_date", "total_seats"]);

  const totalSeats = Number(data.total_seats);
  if (!Number.isInteger(totalSeats) || totalSeats < 1) {
    throw httpError(400, "Total seats must be at least 1");
  }

  await assertPackageExists(null, data.package_id, vendor);

  const result = await query(
    `INSERT INTO package_availability
      (package_id, start_date, end_date, total_seats, reserved_seats, confirmed_seats, booking_cutoff_hours, status)
     VALUES (?, ?, ?, ?, 0, 0, ?, ?)`,
    [data.package_id, data.start_date, data.end_date, totalSeats, Number(data.booking_cutoff_hours || 24), data.status || "available"]
  );
  const row = await findById(resources.package_availability, result.insertId, ["*"]);

  return {
    statusCode: 201,
    message: "Availability created",
    data: row,
  };
}

async function updateAvailability(context) {
  const vendor = await requirePackageManager(context.user);

  const id = context.body.id || context.body.data?.id;
  const data = context.body.data || {};

  if (!id) {
    throw httpError(400, "Availability id is required");
  }

  const currentRows = await query(
    `SELECT pa.*, p.vendor_id
     FROM package_availability pa
     INNER JOIN packages p ON p.id = pa.package_id
     WHERE pa.id = ?
     LIMIT 1`,
    [id]
  );
  const current = currentRows[0];
  if (!current) {
    throw httpError(404, "Availability not found");
  }
  ensurePackageOwner(current, vendor);

  const allowed = ["start_date", "end_date", "total_seats", "reserved_seats", "confirmed_seats", "booking_cutoff_hours", "status"];
  const updates = {};

  for (const field of allowed) {
    if (Object.prototype.hasOwnProperty.call(data, field)) {
      updates[field] = data[field];
    }
  }

  if (!Object.keys(updates).length) {
    throw httpError(400, "No valid availability fields were provided");
  }

  await update("package_availability", id, updates);
  const row = await findById(resources.package_availability, id, ["*"]);

  if (!row) {
    throw httpError(404, "Availability not found");
  }

  return {
    message: "Availability updated",
    data: row,
  };
}

async function updateItineraryDay(context) {
  const vendor = await requirePackageManager(context.user);

  const data = context.body.data || {};
  const id = await resolvePackageDayId(context.body.id || data.id, data);
  await assertPackageDayOwner(id, vendor);

  const allowed = ["title", "summary", "accommodation", "meals", "start_time", "end_time"];
  const updates = {};

  for (const field of allowed) {
    if (Object.prototype.hasOwnProperty.call(data, field)) {
      updates[field] = data[field];
    }
  }

  if (!Object.keys(updates).length) {
    throw httpError(400, "No valid day fields were provided");
  }

  await update("package_days", id, updates);
  const row = await findById(resources.package_days, id, ["*"]);

  if (!row) {
    throw httpError(404, "Package day not found");
  }

  return {
    message: "Itinerary day updated",
    data: row,
  };
}

async function resolvePackageDayId(id, data) {
  if (id) {
    return id;
  }

  if (!data.package_id || !data.day_number) {
    throw httpError(400, "Send package day id, or send package_id and day_number");
  }

  const rows = await query("SELECT id FROM package_days WHERE package_id = ? AND day_number = ? LIMIT 1", [
    data.package_id,
    data.day_number,
  ]);

  if (!rows.length) {
    throw httpError(404, "Package day not found for that package_id and day_number");
  }

  return rows[0].id;
}

async function addItineraryDestination(context) {
  const vendor = await requirePackageManager(context.user);

  const data = context.body.data || {};
  requireFields(data, ["package_day_id", "destination_id"]);
  await assertItineraryDestinationAllowed(data.package_day_id, data.destination_id, vendor);

  const result = await query(
    `INSERT INTO package_day_destinations
      (package_day_id, destination_id, visit_order, activity_title, activity_description, arrival_time, departure_time, notes)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
    [
      data.package_day_id,
      data.destination_id,
      data.visit_order || 1,
      data.activity_title || null,
      data.activity_description || null,
      data.arrival_time || null,
      data.departure_time || null,
      data.notes || null,
    ]
  );
  const row = await findById(resources.package_day_destinations, result.insertId, ["*"]);

  return {
    statusCode: 201,
    message: "Destination added to itinerary day",
    data: row,
  };
}

async function removeItineraryDestination(context) {
  const vendor = await requirePackageManager(context.user);

  const id = context.body.id || context.body.data?.id;
  if (!id) {
    throw httpError(400, "Itinerary destination id is required");
  }
  await assertPackageDayDestinationOwner(id, vendor);

  await query("DELETE FROM package_day_destinations WHERE id = ?", [id]);

  return {
    message: "Destination removed from itinerary day",
    data: { id },
  };
}

async function findPackageDetailsById(packageId, connection = null) {
  const runner = connection || { execute: (sql, params) => queryAsExecute(query, sql, params) };
  const [packageRows] = await runner.execute(
    `SELECT p.*, pd.title AS duration_title, pd.total_days
     FROM packages p
     LEFT JOIN package_durations pd ON pd.id = p.duration_id
     WHERE p.id = ?
     LIMIT 1`,
    [packageId]
  );
  const packageRow = packageRows[0];

  if (!packageRow) {
    throw httpError(404, "Package not found");
  }

  const [days] = await runner.execute("SELECT * FROM package_days WHERE package_id = ? ORDER BY day_number ASC", [
    packageId,
  ]);
  const dayIds = days.map((day) => day.id);
  let dayDestinations = [];

  if (dayIds.length) {
    const placeholders = dayIds.map(() => "?").join(", ");
    const [rows] = await runner.execute(
      `SELECT pdd.*, d.name AS destination_name, d.slug AS destination_slug, d.main_image AS destination_image
       FROM package_day_destinations pdd
       INNER JOIN destinations d ON d.id = pdd.destination_id
       WHERE pdd.package_day_id IN (${placeholders})
       ORDER BY pdd.package_day_id ASC, pdd.visit_order ASC`,
      dayIds
    );
    dayDestinations = rows;
  }

  const [availability] = await runner.execute(
    `SELECT id, package_id, start_date, end_date, total_seats, reserved_seats, confirmed_seats, booking_cutoff_hours,
            (total_seats - reserved_seats - confirmed_seats) AS remaining_seats, status, created_at
     FROM package_availability
     WHERE package_id = ?
     ORDER BY start_date ASC`,
    [packageId]
  );
  const [images] = await runner.execute(
    "SELECT id, package_id, image_path, sort_order, created_at FROM package_images WHERE package_id = ? ORDER BY sort_order ASC, id ASC",
    [packageId]
  );
  const [categories] = await runner.execute(
    `SELECT c.id, c.name, c.slug
     FROM package_categories pc
     INNER JOIN categories c ON c.id = pc.category_id
     WHERE pc.package_id = ? AND c.status = 'active'
     ORDER BY c.name ASC`,
    [packageId]
  );

  const [inclusions] = await runner.execute("SELECT id, item FROM package_inclusions WHERE package_id = ? ORDER BY id ASC", [
    packageId,
  ]);
  const [exclusions] = await runner.execute("SELECT id, item FROM package_exclusions WHERE package_id = ? ORDER BY id ASC", [
    packageId,
  ]);
  const [requiredItems] = await runner.execute(
    "SELECT id, item FROM package_required_items WHERE package_id = ? ORDER BY id ASC",
    [packageId]
  );
  const [notAllowedItems] = await runner.execute(
    "SELECT id, item FROM package_not_allowed_items WHERE package_id = ? ORDER BY id ASC",
    [packageId]
  );

  const destinationsByDayId = dayDestinations.reduce((grouped, destination) => {
    grouped[destination.package_day_id] = grouped[destination.package_day_id] || [];
    grouped[destination.package_day_id].push(destination);
    return grouped;
  }, {});

  return {
    ...packageRow,
    days: days.map((day) => ({
      ...day,
      destinations: destinationsByDayId[day.id] || [],
    })),
    availability,
    images,
    categories,
    inclusions,
    exclusions,
    required_items: requiredItems,
    not_allowed_items: notAllowedItems,
  };
}

function getPackageImageFiles(context) {
  const galleryFiles = context.files?.package_images || context.files?.images || [];
  const files = galleryFiles.length ? galleryFiles : [context.file].filter(Boolean);

  files.forEach((file) => uploadedImagePath(file));
  return files;
}

async function insertPackageImages(connection, packageId, files) {
  for (let index = 0; index < files.length; index += 1) {
    await connection.execute("INSERT INTO package_images (package_id, image_path, sort_order) VALUES (?, ?, ?)", [
      packageId,
      uploadedImagePath(files[index]),
      index + 1,
    ]);
  }
}

async function syncPackageDays(connection, packageId, durationId) {
  const [durationRows] = await connection.execute(
    "SELECT total_days FROM package_durations WHERE id = ? AND status = 'active' LIMIT 1",
    [durationId]
  );
  const duration = durationRows[0];

  if (!duration) {
    throw httpError(400, "Active package duration was not found");
  }

  const [dayRows] = await connection.execute("SELECT id, day_number FROM package_days WHERE package_id = ? ORDER BY day_number", [
    packageId,
  ]);
  const existingDays = new Set(dayRows.map((day) => Number(day.day_number)));

  for (let dayNumber = 1; dayNumber <= duration.total_days; dayNumber += 1) {
    if (!existingDays.has(dayNumber)) {
      await connection.execute(
        "INSERT INTO package_days (package_id, day_number, title, summary) VALUES (?, ?, ?, ?)",
        [packageId, dayNumber, `Day ${dayNumber}`, ""]
      );
    }
  }
}

async function assertPackageExists(connection, packageId, vendor = null) {
  const runner = connection || { execute: (sql, params) => queryAsExecute(query, sql, params) };
  const [rows] = await runner.execute("SELECT id, vendor_id FROM packages WHERE id = ? LIMIT 1", [packageId]);

  if (!rows.length) {
    throw httpError(404, "Package not found");
  }

  ensurePackageOwner(rows[0], vendor);
}

async function requirePackageManager(user) {
  if (user?.role === "vendor") {
    return requireApprovedVendor(user);
  }

  requireAdmin(user);
  return null;
}

function ensurePackageOwner(packageRow, vendor) {
  if (!vendor) {
    return;
  }

  if (Number(packageRow.vendor_id) !== Number(vendor.id)) {
    throw httpError(403, "You are not allowed to manage this package");
  }
}

async function syncPackageCategories(connection, packageId, data) {
  const categoryIds = await resolveCategoryIds(connection, data);
  if (!categoryIds) {
    return;
  }

  await connection.execute("DELETE FROM package_categories WHERE package_id = ?", [packageId]);

  for (const categoryId of categoryIds) {
    await connection.execute("INSERT IGNORE INTO package_categories (package_id, category_id) VALUES (?, ?)", [
      packageId,
      categoryId,
    ]);
  }
}

async function resolveCategoryIds(connection, data) {
  if (!Object.prototype.hasOwnProperty.call(data, "category_ids") && !Object.prototype.hasOwnProperty.call(data, "categories")) {
    return null;
  }

  const ids = Array.isArray(data.category_ids) ? data.category_ids.map(Number).filter(Boolean) : [];
  const names = Array.isArray(data.categories) ? data.categories : [];

  for (const name of names) {
    const categoryName = typeof name === "string" ? name : name.name;
    if (!categoryName) {
      continue;
    }

    const slug = slugify(categoryName, { lower: true, strict: true });
    const [rows] = await connection.execute("SELECT id FROM categories WHERE slug = ? AND status = 'active' LIMIT 1", [slug]);
    if (!rows.length) {
      throw httpError(400, `Unknown package category: ${categoryName}. Categories must be created by admin first.`);
    }
    ids.push(rows[0].id);
  }

  const uniqueIds = [...new Set(ids)];
  if (!uniqueIds.length) {
    return [];
  }

  const placeholders = uniqueIds.map(() => "?").join(", ");
  const [activeRows] = await connection.execute(
    `SELECT id FROM categories WHERE id IN (${placeholders}) AND status = 'active'`,
    uniqueIds
  );
  const activeIds = new Set(activeRows.map((row) => Number(row.id)));
  const invalidIds = uniqueIds.filter((id) => !activeIds.has(Number(id)));

  if (invalidIds.length) {
    throw httpError(400, `Invalid or inactive package category ids: ${invalidIds.join(", ")}`);
  }

  return uniqueIds;
}

async function assertPackageDayOwner(packageDayId, vendor) {
  if (!vendor) {
    return;
  }

  const rows = await query(
    `SELECT p.vendor_id
     FROM package_days pd
     INNER JOIN packages p ON p.id = pd.package_id
     WHERE pd.id = ?
     LIMIT 1`,
    [packageDayId]
  );

  if (!rows.length) {
    throw httpError(404, "Package day not found");
  }

  ensurePackageOwner(rows[0], vendor);
}

async function assertItineraryDestinationAllowed(packageDayId, destinationId, vendor) {
  if (!vendor) {
    return;
  }

  const rows = await query(
    `SELECT p.vendor_id AS package_vendor_id, d.vendor_id AS destination_vendor_id
     FROM package_days pd
     INNER JOIN packages p ON p.id = pd.package_id
     INNER JOIN destinations d ON d.id = ?
     WHERE pd.id = ?
     LIMIT 1`,
    [destinationId, packageDayId]
  );

  if (!rows.length) {
    throw httpError(404, "Package day or destination not found");
  }

  if (Number(rows[0].package_vendor_id) !== Number(vendor.id) || Number(rows[0].destination_vendor_id) !== Number(vendor.id)) {
    throw httpError(403, "Vendors can only use their own destinations in itineraries");
  }
}

async function assertPackageDayDestinationOwner(packageDayDestinationId, vendor) {
  if (!vendor) {
    return;
  }

  const rows = await query(
    `SELECT p.vendor_id
     FROM package_day_destinations pdd
     INNER JOIN package_days pd ON pd.id = pdd.package_day_id
     INNER JOIN packages p ON p.id = pd.package_id
     WHERE pdd.id = ?
     LIMIT 1`,
    [packageDayDestinationId]
  );

  if (!rows.length) {
    throw httpError(404, "Itinerary destination not found");
  }

  ensurePackageOwner(rows[0], vendor);
}

module.exports = {
  createPackageWithDays,
  updatePackage,
  getPackageDetails,
  setPackageRules,
  createAvailability,
  updateAvailability,
  updateItineraryDay,
  addItineraryDestination,
  removeItineraryDestination,
  findPackageDetailsById,
};
