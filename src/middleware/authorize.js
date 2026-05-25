function authorize(...roles) {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({ ok: false, message: "Authentication is required" });
    }

    if (!roles.includes(req.user.role)) {
      return res.status(403).json({ ok: false, message: "You are not allowed to perform this action" });
    }

    return next();
  };
}

module.exports = authorize;
