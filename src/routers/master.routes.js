const express = require("express");
const masterController = require("../controllers/masterController");
const authOptional = require("../middleware/authOptional");
const upload = require("../middleware/uploads");

const router = express.Router();

router.post(
  "/",
  authOptional,
  upload.fields([
    { name: "file", maxCount: 1 },
    { name: "images", maxCount: 10 },
    { name: "package_images", maxCount: 10 },
  ]),
  masterController.handle
);

module.exports = router;
