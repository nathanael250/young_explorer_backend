const express = require("express");
const cors = require("cors");
const helmet = require("helmet");
const rateLimit = require("express-rate-limit");
const morgan = require("morgan");
const path = require("path");
const masterRoutes = require("./routers/master.routes");

const app = express();
const corsOrigins = process.env.CORS_ORIGIN
  ? process.env.CORS_ORIGIN.split(",").map((origin) => origin.trim()).filter(Boolean)
  : true;
const corsOptions = {
  origin: corsOrigins,
  credentials: true,
  methods: ["GET", "POST", "OPTIONS"],
  allowedHeaders: [
    "Content-Type",
    "Authorization",
    "Command",
    "X-Command",
    "Resource",
    "X-Resource",
    "Page",
    "Limit",
    "Search",
  ],
};

app.use(helmet());
app.use(morgan(process.env.NODE_ENV === "production" ? "combined" : "dev"));
app.use(cors(corsOptions));
app.options("*", cors(corsOptions));
app.use(
  rateLimit({
    windowMs: Number(process.env.RATE_LIMIT_WINDOW_MS || 15 * 60 * 1000),
    max: Number(process.env.RATE_LIMIT_MAX || 300),
    standardHeaders: true,
    legacyHeaders: false,
  })
);
app.use(express.json({ limit: "10mb" }));
app.use(express.urlencoded({ extended: true }));

app.use("/uploads", express.static(path.join(__dirname, "../uploads")));

app.get("/", (req, res) => {
  res.json({
    ok: true,
    service: "juniortravels-api",
    message: "Use POST / with a Command header to call the API.",
  });
});

app.get("/health", (req, res) => {
  res.json({ ok: true, service: "juniortravels-api" });
});

app.use("/", masterRoutes);

app.use((req, res) => {
  res.status(404).json({
    ok: false,
    message: "Unknown endpoint. Use POST / with a command.",
  });
});

app.use((err, req, res, next) => {
  const statusCode = err.statusCode || 500;
  const message = normalizeErrorMessage(err);

  if (process.env.NODE_ENV !== "test") {
    console.error(err);
  }

  res.status(statusCode).json({
    ok: false,
    message,
  });
});

function normalizeErrorMessage(err) {
  if (err?.code === "ER_NO_REFERENCED_ROW_2") {
    return "The request references a record that does not exist. Refresh your login token and verify the selected ids.";
  }

  if (err?.code === "ER_ROW_IS_REFERENCED_2") {
    return "This record cannot be changed because other records still depend on it.";
  }

  return err.message || "Internal server error";
}

module.exports = app;
