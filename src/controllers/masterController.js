const MasterModel = require("../models/masterModel");

async function handle(req, res, next) {
  try {
    normalizeMultipartBody(req);
    const body = normalizeCommandRequest(req);

    const result = await MasterModel.handleCommand({
      body,
      file: req.file,
      files: req.files,
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

function normalizeMultipartBody(req) {
  if (typeof req.body.data === "string") {
    try {
      req.body.data = JSON.parse(req.body.data);
    } catch (error) {
      error.statusCode = 400;
      error.message = "Invalid JSON in data field";
      throw error;
    }
  }

  if (typeof req.body.filters === "string") {
    try {
      req.body.filters = JSON.parse(req.body.filters);
    } catch (error) {
      error.statusCode = 400;
      error.message = "Invalid JSON in filters field";
      throw error;
    }
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
