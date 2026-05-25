const fs = require("fs");
const path = require("path");
const multer = require("multer");

const uploadDir = path.resolve(process.cwd(), process.env.UPLOAD_DIR || "uploads");

fs.mkdirSync(uploadDir, { recursive: true });

const storage = multer.diskStorage({
  destination(req, file, cb) {
    cb(null, uploadDir);
  },
  filename(req, file, cb) {
    const safeName = file.originalname.replace(/[^a-zA-Z0-9._-]/g, "_");
    cb(null, `${Date.now()}-${safeName}`);
  },
});

const allowedTypes = new Set([
  "image/jpeg",
  "image/png",
  "image/webp",
  "image/gif",
  "application/pdf",
]);

function fileFilter(req, file, cb) {
  if (!allowedTypes.has(file.mimetype)) {
    return cb(new Error("Unsupported file type"));
  }

  return cb(null, true);
}

const upload = multer({
  storage,
  fileFilter,
  limits: {
    fileSize: Number(process.env.MAX_FILE_SIZE_MB || 5) * 1024 * 1024,
  },
});

module.exports = upload;
