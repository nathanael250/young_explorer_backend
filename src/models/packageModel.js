const { query, transaction } = require("../config/database");
const resources = require("./resources");
const { normalizeResourceData } = require("./resourceModel");
const { update, findById } = require("./dbHelpers");
const { httpError, requireAdmin, requireFields, queryAsExecute } = require("./modelUtils");

async function createPackageWithDays(context) {
  requireAdmin(context.user);

  const data = context.body.data || {};
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
    const fields = Object.keys(packageData);
    const placeholders = fields.map(() => "?").join(", ");
    const values = fields.map((field) => packageData[field]);
    const [packageResult] = await connection.execute(
      `INSERT INTO packages (${fields.join(", ")}) VALUES (${placeholders})`,
      values
    );

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
  if (context.user?.role !== "admin" && details.status !== "published") {
    throw httpError(404, "Package not found");
  }

  return { data: details };
}

async function updatePackage(context) {
  requireAdmin(context.user);

  const id = context.body.id || context.body.data?.id;
  const data = context.body.data || {};

  if (!id) {
    throw httpError(400, "Package id is required");
  }

  const updatedPackage = await transaction(async (connection) => {
    const [existingRows] = await connection.execute("SELECT id, duration_id FROM packages WHERE id = ? LIMIT 1", [id]);
    const existing = existingRows[0];

    if (!existing) {
      throw httpError(404, "Package not found");
    }

    const packageData = normalizeResourceData(resources.packages, data, context.user);
    delete packageData.id;

    if (Object.keys(packageData).length) {
      const fields = Object.keys(packageData);
      const assignments = fields.map((field) => `${field} = ?`).join(", ");
      const values = fields.map((field) => packageData[field]);
      await connection.execute(`UPDATE packages SET ${assignments} WHERE id = ?`, [...values, id]);
    }

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
  requireAdmin(context.user);

  const data = context.body.data || {};
  requireFields(data, ["package_id"]);

  const rules = [
    ["package_inclusions", data.inclusions || []],
    ["package_exclusions", data.exclusions || []],
    ["package_required_items", data.required_items || []],
    ["package_not_allowed_items", data.not_allowed_items || []],
  ];

  const details = await transaction(async (connection) => {
    await assertPackageExists(connection, data.package_id);

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
  requireAdmin(context.user);

  const data = context.body.data || {};
  requireFields(data, ["package_id", "start_date", "end_date", "total_seats"]);

  const totalSeats = Number(data.total_seats);
  if (!Number.isInteger(totalSeats) || totalSeats < 1) {
    throw httpError(400, "Total seats must be at least 1");
  }

  const result = await query(
    `INSERT INTO package_availability
      (package_id, start_date, end_date, total_seats, reserved_seats, confirmed_seats, status)
     VALUES (?, ?, ?, ?, 0, 0, ?)`,
    [data.package_id, data.start_date, data.end_date, totalSeats, data.status || "available"]
  );
  const row = await findById(resources.package_availability, result.insertId, ["*"]);

  return {
    statusCode: 201,
    message: "Availability created",
    data: row,
  };
}

async function updateAvailability(context) {
  requireAdmin(context.user);

  const id = context.body.id || context.body.data?.id;
  const data = context.body.data || {};

  if (!id) {
    throw httpError(400, "Availability id is required");
  }

  const allowed = ["start_date", "end_date", "total_seats", "reserved_seats", "confirmed_seats", "status"];
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
  requireAdmin(context.user);

  const data = context.body.data || {};
  const id = await resolvePackageDayId(context.body.id || data.id, data);

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
  requireAdmin(context.user);

  const data = context.body.data || {};
  requireFields(data, ["package_day_id", "destination_id"]);

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
  requireAdmin(context.user);

  const id = context.body.id || context.body.data?.id;
  if (!id) {
    throw httpError(400, "Itinerary destination id is required");
  }

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
    `SELECT id, package_id, start_date, end_date, total_seats, reserved_seats, confirmed_seats,
            (total_seats - reserved_seats - confirmed_seats) AS remaining_seats, status, created_at
     FROM package_availability
     WHERE package_id = ?
     ORDER BY start_date ASC`,
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
    inclusions,
    exclusions,
    required_items: requiredItems,
    not_allowed_items: notAllowedItems,
  };
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

async function assertPackageExists(connection, packageId) {
  const [rows] = await connection.execute("SELECT id FROM packages WHERE id = ? LIMIT 1", [packageId]);

  if (!rows.length) {
    throw httpError(404, "Package not found");
  }
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
