import { initializeApp, getApps, getApp } from "firebase/app";
import { 
  getAuth, 
  RecaptchaVerifier, 
  signInWithPhoneNumber, 
  ConfirmationResult 
} from "firebase/auth";

// Firebase Configuration (Lấy từ Firebase Console -> Project Settings -> General -> Your apps -> Web app)
const firebaseConfig = {
  apiKey: import.meta.env.VITE_FIREBASE_API_KEY || "AIzaSyYOUR_FIREBASE_API_KEY",
  authDomain: import.meta.env.VITE_FIREBASE_AUTH_DOMAIN || "your-app.firebaseapp.com",
  projectId: import.meta.env.VITE_FIREBASE_PROJECT_ID || "your-app-id",
  storageBucket: import.meta.env.VITE_FIREBASE_STORAGE_BUCKET || "your-app.appspot.com",
  messagingSenderId: import.meta.env.VITE_FIREBASE_MESSAGING_SENDER_ID || "123456789",
  appId: import.meta.env.VITE_FIREBASE_APP_ID || "1:123456789:web:abcdef"
};

// Initialize Firebase App
const app = getApps().length > 0 ? getApp() : initializeApp(firebaseConfig);
export const firebaseAuth = getAuth(app);

/**
 * Khởi tạo Invisible reCAPTCHA của Firebase cho nút gửi OTP
 */
export function setupRecaptcha(buttonId: string): RecaptchaVerifier {
  if ((window as any).recaptchaVerifier) {
    (window as any).recaptchaVerifier.clear();
  }
  
  const recaptchaVerifier = new RecaptchaVerifier(firebaseAuth, buttonId, {
    size: "invisible",
    callback: () => {
      // reCAPTCHA solved
    }
  });

  (window as any).recaptchaVerifier = recaptchaVerifier;
  return recaptchaVerifier;
}

/**
 * Gửi mã SMS OTP tới số điện thoại người dùng qua Firebase Phone Auth
 * @param phone Số điện thoại định dạng quốc tế (ví dụ: +84912345678)
 * @param appVerifier Instance của RecaptchaVerifier
 */
export async function sendFirebaseSmsOtp(
  phone: string, 
  appVerifier: RecaptchaVerifier
): Promise<ConfirmationResult> {
  // Format phone to international format +84 if it starts with 0
  let formattedPhone = phone.trim();
  if (formattedPhone.startsWith("0")) {
    formattedPhone = "+84" + formattedPhone.slice(1);
  }
  
  return await signInWithPhoneNumber(firebaseAuth, formattedPhone, appVerifier);
}
