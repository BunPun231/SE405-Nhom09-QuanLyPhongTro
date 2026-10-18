package com.roomrental.common.service;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

@Service
public class SmsService {

    private static final Logger log = LoggerFactory.getLogger(SmsService.class);

    @Value("${app.sms.provider:DEV}")
    private String smsProvider;

    @Value("${app.sms.api-key:}")
    private String apiKey;

    public void sendOtpSms(String phone, String otp) {
        String message = "[Smart Room Rental] Ma OTP khoi phuc mat khau cua ban la: " + otp + ". Ma co hieu luc trong 5 phut.";

        try {
            if ("SPEEDSMS".equalsIgnoreCase(smsProvider)) {
                log.info("[SpeedSMS Integration] Sending OTP SMS to phone {}", phone);
                // Production SpeedSMS / Brandname SMS API integration point
            } else if ("TWILIO".equalsIgnoreCase(smsProvider)) {
                log.info("[Twilio Integration] Sending OTP SMS to phone {}", phone);
                // Production Twilio SMS integration point
            } else {
                log.info("[SMS SENT SUCCESS] Destination Phone: {} | Content: {}", phone, message);
            }
            log.info("[DEV OTP CODE FOR PHONE {}]: {}", phone, otp);
        } catch (Exception e) {
            log.error("Failed to send OTP SMS to {}: {}", phone, e.getMessage());
            log.warn("[DEV OTP FALLBACK FOR PHONE {}]: {}", phone, otp);
        }
    }
}
