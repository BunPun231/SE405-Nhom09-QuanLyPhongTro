package com.roomrental.common.service;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.stereotype.Service;

@Service
public class EmailService {

    private static final Logger log = LoggerFactory.getLogger(EmailService.class);

    private final JavaMailSender mailSender;

    @Value("${spring.mail.username:noreply@roomrental.com}")
    private String fromEmail;

    public EmailService(JavaMailSender mailSender) {
        this.mailSender = mailSender;
    }

    public void sendOtpEmail(String toEmail, String otp) {
        try {
            SimpleMailMessage message = new SimpleMailMessage();
            if (fromEmail != null && !fromEmail.isBlank()) {
                message.setFrom(fromEmail);
            }
            message.setTo(toEmail);
            message.setSubject("[Smart Room Rental] Mã xác thực khôi phục mật khẩu (OTP)");
            message.setText("Xin chào,\n\nMã OTP khôi phục mật khẩu của bạn là: " + otp + 
                             "\n\nMã OTP này có hiệu lực trong 5 phút. Vui lòng không chia sẻ mã này với bất kỳ ai.");

            mailSender.send(message);
            log.info("Successfully sent OTP email to {}", toEmail);
        } catch (Exception e) {
            log.error("Failed to send OTP email to {}: {}", toEmail, e.getMessage());
            log.warn("[DEV OTP FALLBACK] OTP for {}: {}", toEmail, otp);
        }
    }
}
