const jwt = require("jsonwebtoken");

function auth(req, res, next) {
  const header = req.headers.authorization || "";
  const token = header.startsWith("Bearer ") ? header.slice(7) : null;

  if (!token) {
    return res.status(401).json({ ok: false, message: "Authentication token is required" });
  }

  try {
    req.user = jwt.verify(token, process.env.JWT_SECRET || "young_explorers_dev_secret");
    return next();
  } catch (error) {
    return res.status(401).json({ ok: false, message: "Invalid or expired token" });
  }
}

module.exports = auth;
