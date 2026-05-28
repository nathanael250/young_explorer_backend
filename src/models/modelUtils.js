function httpError(statusCode, message) {
  const error = new Error(message);
  error.statusCode = statusCode;
  return error;
}

function requireFields(data, fields) {
  const missing = fields.filter((field) => !data[field]);

  if (missing.length) {
    throw httpError(400, `Missing required fields: ${missing.join(", ")}`);
  }
}

function requireUser(user) {
  if (!user) {
    throw httpError(401, "Authentication is required");
  }
}

function requireAdmin(user) {
  requireUser(user);

  if (user.role !== "admin") {
    throw httpError(403, "Admin access is required");
  }
}

function attachUploadedMainImage(data, file) {
  if (!file) {
    return data;
  }

  return {
    ...data,
    main_image: uploadedImagePath(file),
  };
}

function uploadedImagePath(file) {
  if (!file.mimetype || !file.mimetype.startsWith("image/")) {
    throw httpError(400, "Main image must be an image file");
  }

  return `/uploads/${file.filename}`;
}

async function queryAsExecute(query, sql, params) {
  const rows = await query(sql, params);
  return [rows];
}

module.exports = {
  httpError,
  requireFields,
  requireUser,
  requireAdmin,
  attachUploadedMainImage,
  uploadedImagePath,
  queryAsExecute,
};
