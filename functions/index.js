const functions = require("firebase-functions/v2");
const admin = require("firebase-admin");
const nodemailer = require("nodemailer");

admin.initializeApp();

/**
 * ✅ Setup reusable email transporter (use App Password)
 */


/**
 * ✅ Helper function to send welcome email
 */
async function sendWelcomeEmail(email, firstName = "",senderEmail,senderPassword) {

const transporter = nodemailer.createTransport({
  service: "gmail",
  auth: {
    user: senderEmail,
    pass: senderPassword, // App-specific password (not your Gmail password)
  },
});

  const htmlContent = `
    <div style="font-family: Arial, sans-serif; line-height: 1.7; color: #333; max-width: 600px; margin: auto; background: #fafafa; padding: 20px; border-radius: 10px;">
      <h2>Hi ${firstName || "there"} 👋,</h2>
      <p>Welcome to <strong>LingoBuzz</strong>, the app that helps you learn new languages effortlessly, right from your home screen.</p>
      <p><strong>Here’s what to expect starting today:</strong></p>
      <ul style="list-style: none; padding-left: 0;">
        <li>🌍 <strong>Daily Words or Phrases:</strong> Learn naturally through smart widgets and gentle notifications.</li>
        <li>⭐ <strong>Personalised Experience:</strong> Choose your target language and how many words or phrases you want to learn each day.</li>
        <li>🎯 <strong>Track Your Progress:</strong> Stay motivated with quizzes and fun milestones.</li>
      </ul>
      <p>You’re already on your way to mastering a new language one buzz at a time. 🚀</p>
      <p>👉 <strong>Tip:</strong> Keep notifications turned on so you don’t miss your daily words.</p>
      <p style="color: #555;">This is a <strong>noreply</strong> email. If you ever have questions or feedback, just reach out at
        <a href="mailto:contact@lingobuzz.app" style="color: #007bff;">contact@lingobuzz.app</a>. We’d love to hear from you.</p>
      <p>Happy learning! 💬<br>— The LingoBuzz Team</p>
    </div>
  `;

  return await transporter.sendMail({
    from: `"LingoBuzz" <noreply@lingobuzz.app>`,
    to: email,
    subject: "🎉 Welcome to LingoBuzz!",
    html: htmlContent,
  });
}


/**
 * ✅ Cloud Function (v2 Callable)
 */
exports.sendWelcomeEmail = functions.https.onCall(async (request) => {
  console.log("📥 Data received from client:", request.data);

  const data = request.data || {};
  const email = data.email?.trim();
  const firstName = data.firstName?.trim() || "";
  const senderEmail = data.senderEmail;
  const senderPassword = data.senderPassword;

  if (!email || !email.includes("@")) {
    console.error("❌ Invalid email received:", email);
    throw new functions.https.HttpsError("invalid-argument", "Valid email is required");
  }

  if (!senderEmail || !senderPassword) {
    console.error("❌ Missing email credentials");
    throw new functions.https.HttpsError("invalid-argument", "Sender email and password required");
  }

  try {
    console.log(`📨 Sending welcome email to: ${email} (${firstName})`);
    await sendWelcomeEmail(email, firstName, senderEmail, senderPassword); // ✅ Pass credentials
    console.log("✅ Welcome email successfully sent to:", email);
    return { success: true };
  } catch (error) {
    console.error("❌ Email send failed:", error.message);
    throw new functions.https.HttpsError("internal", "Failed to send email: " + error.message);
  }
});

