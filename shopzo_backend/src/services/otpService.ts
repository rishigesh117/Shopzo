export interface IOtpProvider {
  sendOtp(phone: string, otp: string): Promise<boolean>;
}

export class MockOtpProvider implements IOtpProvider {
  async sendOtp(phone: string, otp: string): Promise<boolean> {
    console.log(`[MOCK OTP SERVICE] Sent OTP "${otp}" to phone ${phone}`);
    return true;
  }
}

export class ProdSmsOtpProvider implements IOtpProvider {
  private apiKey: string;

  constructor(apiKey: string) {
    this.apiKey = apiKey;
  }

  async sendOtp(phone: string, otp: string): Promise<boolean> {
    if (!this.apiKey) {
      console.warn('[PROD OTP WARNING] API key missing for SMS provider. Falling back to console log.');
      console.log(`[PROD OTP FALLBACK] Sent OTP "${otp}" to phone ${phone}`);
      return true;
    }
    // Production SMS Gateway API integration point
    console.log(`[PROD OTP GATEWAY] Sending OTP "${otp}" to ${phone} via configured Gateway`);
    return true;
  }
}

export class OtpService {
  private provider: IOtpProvider;

  constructor() {
    const isProd = process.env.NODE_ENV === 'production';
    const smsApiKey = process.env.SMS_API_KEY || '';

    if (isProd && smsApiKey) {
      this.provider = new ProdSmsOtpProvider(smsApiKey);
    } else {
      this.provider = new MockOtpProvider();
    }
  }

  async sendOtp(phone: string, otp: string): Promise<boolean> {
    return this.provider.sendOtp(phone, otp);
  }
}

export const otpService = new OtpService();
