const { onValueUpdated } = require('firebase-functions/v2/database');
const { initializeApp }  = require('firebase-admin/app');
const { getDatabase }    = require('firebase-admin/database');
const { getMessaging }   = require('firebase-admin/messaging');

initializeApp();

/**
 * Triggered whenever /classroom/status changes in Realtime Database.
 * Sends a push notification to all registered devices when status
 * transitions INTO "CRITICAL" from any other state.
 *
 * Duplicate prevention:
 *   - Only fires when the NEW value is CRITICAL
 *   - AND the OLD value was NOT already CRITICAL
 *   - So repeated CRITICAL readings do not spam notifications
 */
exports.notifyOnCritical = onValueUpdated(
  {
    ref: '/classroom/status',
    region: 'asia-southeast1',   // match your RTDB region
    instance: 'kalmado-appdev-default-rtdb',
  },
  async (event) => {
    const before = (event.data.before.val() || '').toUpperCase();
    const after  = (event.data.after.val()  || '').toUpperCase();

    console.log(`Status changed: ${before} → ${after}`);

    // Only notify on transition INTO CRITICAL
    if (after !== 'CRITICAL' || before === 'CRITICAL') {
      console.log('No notification needed.');
      return null;
    }

    // Read all saved FCM tokens from /fcm_tokens
    const db     = getDatabase();
    const snap   = await db.ref('/fcm_tokens').once('value');
    const tokens = [];

    snap.forEach((child) => {
      if (child.key) tokens.push(child.key);
    });

    if (tokens.length === 0) {
      console.log('No FCM tokens found — no notification sent.');
      return null;
    }

    console.log(`Sending critical alert to ${tokens.length} device(s)...`);

    // Send notification to all registered devices
    const response = await getMessaging().sendEachForMulticast({
      tokens,
      notification: {
        title: '⚠️ KALMADO Critical Alert',
        body: 'Classroom environment is CRITICAL. Immediate attention required.',
      },
      android: {
        priority: 'high',
        notification: {
          channelId: 'kalmado_critical',
          sound: 'default',
        },
      },
      data: {
        screen: 'alerts',
        status: 'CRITICAL',
      },
    });

    console.log(
      `Sent: ${response.successCount} success, ${response.failureCount} failed`
    );

    // Clean up invalid tokens
    const invalidTokens = [];
    response.responses.forEach((res, i) => {
      if (!res.success) {
        const code = res.error?.code;
        if (
          code === 'messaging/invalid-registration-token' ||
          code === 'messaging/registration-token-not-registered'
        ) {
          invalidTokens.push(tokens[i]);
        }
      }
    });

    if (invalidTokens.length > 0) {
      console.log(`Removing ${invalidTokens.length} invalid token(s)...`);
      const removes = invalidTokens.map((t) =>
        db.ref(`/fcm_tokens/${t}`).remove()
      );
      await Promise.all(removes);
    }

    return null;
  }
);
