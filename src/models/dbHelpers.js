const { query } = require("../config/database");
const { httpError } = require("./modelUtils");

async function insert(table, data) {
  if (!Object.keys(data).length) {
    throw httpError(400, "No valid fields were provided");
  }

  const fields = Object.keys(data);
  const placeholders = fields.map(() => "?").join(", ");
  const values = fields.map((field) => data[field]);

  return query(`INSERT INTO ${table} (${fields.join(", ")}) VALUES (${placeholders})`, values);
}

async function update(table, id, data) {
  const fields = Object.keys(data);
  const values = fields.map((field) => data[field]);
  const assignments = fields.map((field) => `${field} = ?`).join(", ");

  return query(`UPDATE ${table} SET ${assignments} WHERE id = ?`, [...values, id]);
}

async function findById(config, id, fields) {
  const rows = await query(`SELECT ${fields.join(", ")} FROM ${config.table} WHERE id = ? LIMIT 1`, [id]);
  return rows[0] || null;
}

module.exports = {
  insert,
  update,
  findById,
};
