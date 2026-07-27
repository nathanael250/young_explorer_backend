const nodemailer = require("nodemailer");
const { query } = require("../config/database");

const transporter = nodemailer.createTransport({
  host: process.env.SMTP_HOST || "smtp.gmail.com",
  port: Number(process.env.SMTP_PORT || 587),
  secure: false,
  auth: {
    user: process.env.SMTP_USER,
    pass: process.env.SMTP_PASS,
  },
});

async function sendEmail(to, subject, html) {
  if (!process.env.SMTP_USER) {
    console.warn("SMTP not configured, skipping email send");
    return { sent: false, reason: "smtp_not_configured" };
  }

  const info = await transporter.sendMail({
    from: process.env.SMTP_FROM || process.env.SMTP_USER,
    to,
    subject,
    html,
  });

  return { sent: true, messageId: info.messageId };
}

async function notifyNewPackage(packageData) {
  const subscribers = await query(
    "SELECT email FROM newsletter_subscribers WHERE status = 'active'"
  );

  const users = await query(
    "SELECT email FROM users WHERE status = 'active'"
  );

  const allEmails = [
    ...new Set([...subscribers.map((s) => s.email), ...users.map((u) => u.email)]),
  ];

  if (!allEmails.length) {
    return { notified: 0 };
  }

  const subject = `New Package Available: ${packageData.title}`;
  const html = `
    <h2>New Package Just Listed!</h2>
    <h3>${packageData.title}</h3>
    <p>${packageData.short_description}</p>
    <p><strong>Price:</strong> ${packageData.currency} ${packageData.price_per_person}/person</p>
    <p><strong>Duration:</strong> ${packageData.duration_title}</p>
    <p><strong>Age Range:</strong> ${packageData.age_range}</p>
    <hr>
    <p>Book now before seats run out!</p>
  `;

  let notified = 0;
  for (const email of allEmails) {
    try {
      await sendEmail(email, subject, html);
      notified++;
    } catch (error) {
      console.error(`Failed to send email to ${email}:`, error.message);
    }
  }

  return { notified, total: allEmails.length };
}

async function subscribe(email, userId = null) {
  const existing = await query(
    "SELECT id, status FROM newsletter_subscribers WHERE email = ? LIMIT 1",
    [email]
  );

  if (existing.length && existing[0].status === "active") {
    return { message: "Already subscribed" };
  }

  if (existing.length && existing[0].status === "unsubscribed") {
    await query(
      "UPDATE newsletter_subscribers SET status = 'active', unsubscribed_at = NULL WHERE email = ?",
      [email]
    );
    return { message: "Resubscribed successfully" };
  }

  await query(
    "INSERT INTO newsletter_subscribers (email, user_id) VALUES (?, ?)",
    [email, userId]
  );

  return { message: "Subscribed successfully" };
}

async function unsubscribe(email) {
  await query(
    "UPDATE newsletter_subscribers SET status = 'unsubscribed', unsubscribed_at = NOW() WHERE email = ?",
    [email]
  );
  return { message: "Unsubscribed successfully" };
}

module.exports = {
  sendEmail,
  notifyNewPackage,
  subscribe,
  unsubscribe,
};
