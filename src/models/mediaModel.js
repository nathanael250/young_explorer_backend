const resources = require("./resources");
const { insert, findById } = require("./dbHelpers");
const { httpError, requireAdmin } = require("./modelUtils");

async function uploadMedia(context) {
  requireAdmin(context.user);

  if (!context.file) {
    throw httpError(400, "File is required");
  }

  const relativePath = `/uploads/${context.file.filename}`;
  const result = await insert("media_files", {
    file_name: context.file.originalname,
    file_path: relativePath,
    file_type: context.file.mimetype,
    uploaded_by: context.user.id,
  });
  const row = await findById(resources.media_files, result.insertId, ["*"]);

  return {
    statusCode: 201,
    message: "File uploaded",
    data: row,
  };
}

module.exports = {
  uploadMedia,
};
