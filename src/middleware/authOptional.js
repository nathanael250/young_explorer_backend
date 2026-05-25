const jwt = require("jsonwebtoken");

function authOptional(req, res, next) {
  const header = req.headers.authorization || "";
  const token = header.startsWith("Bearer ") ? header.slice(7) : null;

  if (!token) {
    return next();
  }

  try {
    req.user = jwt.verify(token, process.env.JWT_SECRET || "young_explorers_dev_secret");
  } catch (error) {
    req.user = null;
  }

  return next();
}

module.exports = authOptional;
