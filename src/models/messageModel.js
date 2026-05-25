const resources = require("./resources");
const { insert, findById } = require("./dbHelpers");
const { requireFields } = require("./modelUtils");

async function sendContactMessage(context) {
  const data = context.body.data || {};
  requireFields(data, ["full_name", "email", "subject", "message"]);

  const result = await insert("messages", {
    full_name: data.full_name,
    email: data.email,
    subject: data.subject,
    message: data.message,
  });
  const row = await findById(resources.messages, result.insertId, ["*"]);

  return {
    statusCode: 201,
    message: "Message sent",
    data: row,
  };
}

module.exports = {
  sendContactMessage,
};
