const { onDocumentCreated, onDocumentUpdated } = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");

admin.initializeApp();

const db = admin.firestore();

// Helper: Normalize phone numbers (stripping country code and non-digits)
function normalizePhone(phone) {
  if (!phone) return "";
  return phone.toString().replace(/[^0-9]/g, "");
}

function isSamePhone(p1, p2) {
  const d1 = normalizePhone(p1);
  const d2 = normalizePhone(p2);
  if (!d1 || !d2) return false;
  if (d1 === d2) return true;
  if (d1.length >= 10 && d2.length >= 10) {
    return d1.slice(-10) === d2.slice(-10);
  }
  return false;
}

/**
 * Trigger 1: Whenever a notification is added to any family
 * (e.g. SOS alert, new expense, income, loan, EMI, custom message)
 * Delivers push notification even when recipient apps are TERMINATED.
 */
exports.sendFamilyNotificationPush = onDocumentCreated(
  "families/{familyId}/notifications/{notifId}",
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const data = snap.data();
    const familyId = event.params.familyId;
    const title = data.title || "পারিবারিক নোটিফিকেশন";
    const body = data.body || "";
    const senderPhone = data.senderPhone || data.memberPhone || "";
    const receiverId = (data.receiverId || "").trim();

    console.log(`[Cloud Function] New notification in family ${familyId}: "${title}" from ${senderPhone}`);

    // Gather destination FCM tokens (strictly excluding sender)
    const tokens = new Set();

    try {
      const isAll = !receiverId || receiverId === "all" || receiverId.includes("সবাই") || receiverId.includes("সকল");

      if (isAll) {
        // Query members subcollection
        const membersSnap = await db.collection("families").doc(familyId).collection("members").get();
        for (const doc of membersSnap.docs) {
          const memberPhone = doc.id;
          if (isSamePhone(memberPhone, senderPhone)) continue;

          let token = doc.data().fcmToken;
          if (!token) {
            const userDoc = await db.collection("users").doc(normalizePhone(memberPhone)).get();
            if (userDoc.exists) token = userDoc.data().fcmToken;
          }
          if (token && typeof token === "string" && token.trim()) {
            tokens.add(token.trim());
          }
        }

        // Query users where activeFamilyId == familyId
        const usersSnap = await db.collection("users").where("activeFamilyId", "==", familyId).get();
        for (const doc of usersSnap.docs) {
          const uPhone = doc.data().phoneNumber || doc.id;
          if (isSamePhone(uPhone, senderPhone)) continue;
          const token = doc.data().fcmToken;
          if (token && typeof token === "string" && token.trim()) {
            tokens.add(token.trim());
          }
        }
      } else {
        // Single receiver
        const cleanReceiver = normalizePhone(receiverId);
        if (cleanReceiver && !isSamePhone(cleanReceiver, senderPhone)) {
          const userDoc = await db.collection("users").doc(cleanReceiver).get();
          if (userDoc.exists && userDoc.data().fcmToken) {
            tokens.add(userDoc.data().fcmToken.trim());
          }
        }
      }

      const tokenList = Array.from(tokens);
      if (tokenList.length === 0) {
        console.log(`[Cloud Function] No destination tokens found for family ${familyId}.`);
        return;
      }

      console.log(`[Cloud Function] Sending FCM push to ${tokenList.length} device tokens...`);

      const message = {
        tokens: tokenList,
        notification: {
          title: title,
          body: body,
        },
        android: {
          priority: "high",
          notification: {
            channelId: "srh_family_channel",
            sound: "default",
            clickAction: "FLUTTER_NOTIFICATION_CLICK",
          },
        },
        apns: {
          payload: {
            aps: {
              sound: "default",
              badge: 1,
            },
          },
        },
        data: {
          title: title,
          body: body,
          familyId: familyId,
          type: data.type || "family_notification",
          click_action: "FLUTTER_NOTIFICATION_CLICK",
        },
      };

      const response = await admin.messaging().sendEachForMulticast(message);
      console.log(`[Cloud Function] FCM push dispatched: ${response.successCount} success, ${response.failureCount} failed.`);
    } catch (err) {
      console.error("[Cloud Function] Error sending family push:", err);
    }
  }
);

/**
 * Trigger 2: When an invitation is created (Invite sent)
 */
exports.sendInvitationCreatedPush = onDocumentCreated(
  "family_invitations/{inviteId}",
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const data = snap.data();
    const targetPhone = normalizePhone(data.targetPhone || "");
    const inviterName = data.inviterName || "পারিবারিক অ্যাডমিন";
    const familyName = data.familyName || "পারিবারিক খতিয়ান";

    if (!targetPhone) return;

    try {
      const userDoc = await db.collection("users").doc(targetPhone).get();
      if (!userDoc.exists || !userDoc.data().fcmToken) return;

      const token = userDoc.data().fcmToken.trim();
      const title = "পারিবারিক আমন্ত্রণ 💌";
      const body = `${inviterName} আপনাকে "${familyName}" পরিবারে যুক্ত হওয়ার আমন্ত্রণ জানিয়েছেন।`;

      await admin.messaging().send({
        token: token,
        notification: { title, body },
        android: {
          priority: "high",
          notification: {
            channelId: "srh_family_channel",
            sound: "default",
          },
        },
        data: {
          title,
          body,
          type: "family_invite",
          familyId: data.familyId || "",
        },
      });
      console.log(`[Cloud Function] Invitation push sent to ${targetPhone}`);
    } catch (err) {
      console.error("[Cloud Function] Error sending invitation push:", err);
    }
  }
);

/**
 * Trigger 3: When invitation status updates to accepted or rejected
 */
exports.sendInvitationResponsePush = onDocumentUpdated(
  "family_invitations/{inviteId}",
  async (event) => {
    const before = event.data.before.data();
    const after = event.data.after.data();

    if (before.status === after.status) return;

    const inviterPhone = normalizePhone(after.inviterPhone || "");
    const memberName = after.targetName || after.targetPhone || "সদস্য";
    const familyName = after.familyName || "পারিবারিক খতিয়ান";

    if (!inviterPhone) return;

    try {
      const userDoc = await db.collection("users").doc(inviterPhone).get();
      if (!userDoc.exists || !userDoc.data().fcmToken) return;

      const token = userDoc.data().fcmToken.trim();
      let title = "";
      let body = "";

      if (after.status === "accepted") {
        title = "আমন্ত্রণ গ্রহণ করা হয়েছে 🎉";
        body = `${memberName} "${familyName}" পরিবারে যুক্ত হওয়ার আমন্ত্রণ গ্রহণ করেছেন!`;
      } else if (after.status === "rejected") {
        title = "আমন্ত্রণ প্রত্যাখ্যান ℹ️";
        body = `${memberName} "${familyName}" পরিবারের আমন্ত্রণ গ্রহণ করেননি।`;
      } else {
        return;
      }

      await admin.messaging().send({
        token: token,
        notification: { title, body },
        android: {
          priority: "high",
          notification: {
            channelId: "srh_family_channel",
            sound: "default",
          },
        },
        data: {
          title,
          body,
          type: `invite_${after.status}`,
          familyId: after.familyId || "",
        },
      });
      console.log(`[Cloud Function] Invite response (${after.status}) push sent to ${inviterPhone}`);
    } catch (err) {
      console.error("[Cloud Function] Error sending invitation response push:", err);
    }
  }
);
