import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";

// Initialize Firebase Admin (done once)
if (admin.apps.length === 0) {
  admin.initializeApp();
}

const db = admin.firestore();
const messaging = admin.messaging();

/**
 * Cloud Function that runs once daily to wake all devices for
 * notification scheduling.
 *
 * Flow:
 * 1. Query all active devices with FCM tokens
 * 2. Send silent FCM push to each device
 * 3. App wakes in background and schedules next 24h of notifications
 * 4. Handle token errors and mark devices inactive
 *
 * Runs at: Midnight UTC daily (00:00 UTC)
 * Cost: $0 (1 invocation/day within 2M free tier)
 */
export const dailyNotificationWakeup = functions
  .runWith({
    timeoutSeconds: 540, // 9 minutes max
    memory: "256MB",
  })
  .pubsub.schedule("0 0 * * *") // Every day at midnight UTC
  .timeZone("UTC")
  .onRun(async () => {
    const startTime = Date.now();

    functions.logger.info("=== Daily Notification Wake-Up Started ===");
    functions.logger.info(`Execution time: ${new Date().toISOString()}`);

    try {
      let totalDevices = 0;
      let totalSent = 0;
      let totalFailed = 0;
      let invalidTokensRemoved = 0;

      // Query all active devices with FCM tokens
      // Using hasFcmToken field (will be added in Phase 1)
      const devicesSnapshot = await db.collection("devices")
        .where("isActive", "==", true)
        .where("hasFcmToken", "==", true)
        .get();

      totalDevices = devicesSnapshot.size;

      if (totalDevices === 0) {
        functions.logger.info("No active devices with FCM tokens found");
        return {
          success: true,
          totalDevices: 0,
          totalSent: 0,
          totalFailed: 0,
        };
      }

      functions.logger.info(`Found ${totalDevices} active devices`);

      // Build FCM messages for all devices
      const messages: admin.messaging.Message[] = [];
      const deviceDocs: FirebaseFirestore.QueryDocumentSnapshot[] = [];

      for (const deviceDoc of devicesSnapshot.docs) {
        const device = deviceDoc.data();

        if (!device.fcmToken) {
          // Skip devices without token (shouldn't happen due to query)
          continue;
        }

        // Build silent data-only message
        const message: admin.messaging.Message = {
          token: device.fcmToken,
          data: {
            type: "daily_wakeup",
            timestamp: new Date().toISOString(),
          },
          // iOS-specific configuration for silent push
          apns: {
            headers: {
              "apns-priority": "5", // Low priority
              "apns-push-type": "background",
            },
            payload: {
              aps: {
                contentAvailable: true, // Wakes app in background
                // NO alert, sound, or badge = completely silent
              },
            },
          },
          // Android-specific configuration
          android: {
            priority: "high", // Required for background processing
            data: {
              type: "daily_wakeup",
              timestamp: new Date().toISOString(),
            },
          },
        };

        messages.push(message);
        deviceDocs.push(deviceDoc);
      }

      // Send messages in batches of 500 (FCM limit)
      const batchSize = 500;
      for (let i = 0; i < messages.length; i += batchSize) {
        const batch = messages.slice(i, i + batchSize);
        const batchDeviceDocs = deviceDocs.slice(i, i + batchSize);

        try {
          const response = await messaging.sendEach(batch);

          // Track successes
          totalSent += response.successCount;
          totalFailed += response.failureCount;

          // Handle individual failures
          const firestoreBatch = db.batch();
          let batchOperations = 0;

          response.responses.forEach((result, index) => {
            const deviceDoc = batchDeviceDocs[index];

            if (!result.success && result.error) {
              const error = result.error;

              functions.logger.warn(
                `FCM send failed for device ${deviceDoc.id}: ${error.code}`,
              );

              // Remove invalid tokens
              if (
                error.code === "messaging/invalid-registration-token" ||
                error.code === "messaging/registration-token-not-registered"
              ) {
                firestoreBatch.update(deviceDoc.ref, {
                  fcmToken: null,
                  hasFcmToken: false,
                  isActive: false,
                });
                batchOperations++;
                invalidTokensRemoved++;
                functions.logger.info(
                  `Marked device ${deviceDoc.id} inactive (invalid token)`,
                );
              }
            }
          });

          // Commit Firestore updates if any
          if (batchOperations > 0) {
            await firestoreBatch.commit();
          }
        } catch (error) {
          functions.logger.error("Batch send failed:", error);
          totalFailed += batch.length;
        }
      }

      // Log final summary
      const duration = Date.now() - startTime;
      functions.logger.info("=== Daily Notification Wake-Up Complete ===");
      functions.logger.info(`Total devices queried: ${totalDevices}`);
      functions.logger.info(`Messages sent successfully: ${totalSent}`);
      functions.logger.info(`Messages failed: ${totalFailed}`);
      functions.logger.info(`Invalid tokens removed: ${invalidTokensRemoved}`);
      functions.logger.info(`Execution duration: ${duration}ms`);

      return {
        success: true,
        totalDevices,
        totalSent,
        totalFailed,
        invalidTokensRemoved,
        durationMs: duration,
      };
    } catch (error) {
      functions.logger.error("Fatal error in dailyNotificationWakeup:", error);
      throw error; // Rethrow to mark function as failed
    }
  });
