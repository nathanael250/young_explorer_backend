const express = require("express");
const masterController = require("../controllers/masterController");
const authOptional = require("../middleware/authOptional");
const upload = require("../middleware/uploads");

const router = express.Router();

router.post("/", authOptional, upload.single("file"), masterController.handle);

module.exports = router;
