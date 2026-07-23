const MasterModel = require("../models/masterModel");

async function handle(req, res, next) {
  try {
    normalizeMultipartBody(req);
    const body = normalizeCommandRequest(req);
    const files = normalizeUploadedFiles(req);

    const result = await MasterModel.handleCommand({
      body,
      file: files.file,
      files,
      user: req.user,
    });

    return res.status(result.statusCode || 200).json({
      ok: true,
      message: result.message || "Success",
      data: result.data || null,
    });
  } catch (error) {
    return next(error);
  }
}

function normalizeUploadedFiles(req) {
  const groupedFiles = req.files || {};
  const file = req.file || groupedFiles.file?.[0] || groupedFiles.image?.[0] || groupedFiles.rib_certificate?.[0] || null;
  const packageImages = [...(groupedFiles.package_images || []), ...(groupedFiles.images || [])];
  const destinationImages = [...(groupedFiles.destination_images || []), ...(groupedFiles.images || [])];

  return {
    ...groupedFiles,
    file,
    image: file,
    rib_certificate: groupedFiles.rib_certificate || [],
    package_images: packageImages,
    destination_images: destinationImages,
    images: groupedFiles.images || [],
  };
}

function normalizeMultipartBody(req) {
  parseJsonBodyField(req, "data");
  parseJsonBodyField(req, "filters");
  parseJsonBodyField(req, "categories");
  parseJsonBodyField(req, "category_ids");
  parseJsonBodyField(req, "participants");
}

function parseJsonBodyField(req, field) {
  if (typeof req.body[field] !== "string") {
    return;
  }

  const value = req.body[field].trim();
  if (!value.startsWith("{") && !value.startsWith("[")) {
    return;
  }

  try {
    req.body[field] = JSON.parse(value);
  } catch (error) {
    error.statusCode = 400;
    error.message = `Invalid JSON in ${field} field`;
    throw error;
  }
}

function normalizeCommandRequest(req) {
  const headers = req.headers || {};
  const rawBody = req.body || {};
  const command = headers.command || headers["x-command"] || rawBody.command;
  const body = {
    ...rawBody,
    command,
    resource: headers.resource || headers["x-resource"] || rawBody.resource,
    id: rawBody.id,
    slug: rawBody.slug,
    page: headers.page || rawBody.page,
    limit: headers.limit || rawBody.limit,
    search: headers.search || rawBody.search,
  };

  if (!body.data && shouldTreatBodyAsData(rawBody)) {
    body.data = rawBody;
  }

  return body;
}

function shouldTreatBodyAsData(body) {
  const metadataFields = new Set(["command", "resource", "id", "slug", "page", "limit", "search", "filters", "data"]);
  const fields = Object.keys(body || {});

  return fields.length > 0 && fields.some((field) => !metadataFields.has(field));
}

module.exports = {
  handle,
};
