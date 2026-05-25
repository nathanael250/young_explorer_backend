require("dotenv").config();

const app = require("./app");
const { checkSchema, seedDefaultDurations, testConnection } = require("./config/database");

const port = process.env.PORT || 5000;

async function startServer() {
  try {
    await testConnection();
    await checkSchema();
    await seedDefaultDurations();

    app.listen(port, () => {
      console.log(`Young Explorers API running on port ${port}`);
    });
  } catch (error) {
    console.error("Failed to start server:", error.message);
    process.exit(1);
  }
}

startServer();
