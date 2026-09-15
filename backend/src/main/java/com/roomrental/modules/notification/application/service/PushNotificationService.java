package com.roomrental.modules.notification.application.service;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import com.google.firebase.messaging.FirebaseMessaging;
import com.google.firebase.messaging.Message;
import jakarta.annotation.PostConstruct;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.io.File;
import java.io.FileInputStream;
import java.io.InputStream;
import java.util.Map;

@Service
public class PushNotificationService {

    private static final Logger log = LoggerFactory.getLogger(PushNotificationService.class);
    private boolean initialized = false;

    @PostConstruct
    public void initFirebase() {
        try {
            if (FirebaseApp.getApps().isEmpty()) {
                String credentialsPath = System.getenv("FIREBASE_CREDENTIALS_PATH");
                InputStream serviceAccount = null;

                if (credentialsPath != null && !credentialsPath.isBlank()) {
                    File file = new File(credentialsPath);
                    if (file.exists()) {
                        serviceAccount = new FileInputStream(file);
                    }
                }

                if (serviceAccount == null) {
                    serviceAccount = getClass().getClassLoader().getResourceAsStream("firebase-service-account.json");
                }

                if (serviceAccount != null) {
                    FirebaseOptions options = FirebaseOptions.builder()
                            .setCredentials(GoogleCredentials.fromStream(serviceAccount))
                            .build();
                    FirebaseApp.initializeApp(options);
                    log.info("Firebase Admin SDK initialized successfully.");
                    this.initialized = true;
                } else {
                    log.warn("Firebase credentials not found (neither System env 'FIREBASE_CREDENTIALS_PATH' nor 'classpath:firebase-service-account.json'). FCM Push Notifications will be mocked/skipped.");
                }
            } else {
                this.initialized = true;
            }
        } catch (Exception e) {
            log.error("Failed to initialize Firebase Admin SDK. FCM Push notifications will be disabled.", e);
        }
    }

    public void sendPushNotification(String token, String title, String content, Map<String, String> data) {
        if (!initialized) {
            log.warn("Firebase not initialized. Skipped sending push notification to token: {}", token);
            return;
        }
        try {
            com.google.firebase.messaging.Notification fcmNotification =
                    com.google.firebase.messaging.Notification.builder()
                            .setTitle(title)
                            .setBody(content)
                            .build();

            Message.Builder messageBuilder = Message.builder()
                    .setToken(token)
                    .setNotification(fcmNotification);

            if (data != null && !data.isEmpty()) {
                messageBuilder.putAllData(data);
            }

            Message message = messageBuilder.build();
            String response = FirebaseMessaging.getInstance().send(message);
            log.debug("Successfully sent push message: {}", response);
        } catch (Exception e) {
            log.error("Error sending push notification to token: " + token, e);
            throw new RuntimeException("FCM delivery failed: " + e.getMessage(), e);
        }
    }
}
