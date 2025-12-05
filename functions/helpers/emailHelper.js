//const nodemailer = require("nodemailer");
//
///**
// * Helper class for handling email operations
// */
//class EmailHelper {
//  constructor() {
//    this.transporter = nodemailer.createTransport({
//      service: "gmail",
//      auth: {
//        user: "khawajafareed0320@gmail.com", // your sender email
//       // pass: "bcga gzjp vwog mbat",   // app-specific password (never real password)
//        pass: "icyo sbkf iwxq bjjf",   // app-specific password (never real password)
//      },
//    });
//  }
//
//  /**
//   * Sends a welcome email to a user
//   * @param {string} email - Recipient's email
//   * @param {string} firstName - Recipient's first name
//   */
//  async sendWelcomeEmail(email, firstName = "") {
//    const htmlContent = `
//      <div style="font-family: Arial, sans-serif; line-height: 1.6;">
//        <h2>Hi ${firstName || "there"} 👋,</h2>
//        <p>Welcome to <strong>LingoBuzz</strong> — your daily language companion!</p>
//        <p>Here’s what you can expect:</p>
//        <ul>
//          <li>🌍 <strong>Daily Words & Phrases</strong> — Learn naturally through widgets and gentle notifications.</li>
//          <li>⭐ <strong>Personalized Experience</strong> — Pick your language and pace.</li>
//          <li>🎯 <strong>Progress Tracking</strong> — Celebrate milestones as you improve.</li>
//        </ul>
//        <p>👉 <strong>Tip:</strong> Keep notifications turned ON to never miss your daily buzz!</p>
//        <p style="color: gray;">Need help? Reach out at <a href="mailto:contact@lingobuzz.app">contact@lingobuzz.app</a></p>
//        <p>Happy learning! 💬<br>— The LingoBuzz Team</p>
//      </div>
//    `;
//
//    try {
//      const info = await this.transporter.sendMail({
//        from: `"LingoBuzz" <noreply@lingobuzz.app>`,
//        to: email,
//        subject: "🎉 Welcome to LingoBuzz!",
//        html: htmlContent,
//      });
//      console.log("📧 Email sent:", info.messageId);
//    } catch (error) {
//      console.error("❌ sendWelcomeEmail() failed:", error);
//      throw new Error(error.message || "Unknown error while sending email");
//    }
//  }
//}
//
//module.exports = new EmailHelper();
