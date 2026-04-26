---
description: Run the app for web development on port 3000
---

# Run Web Development Server

// turbo
1. Start the Flutter web development server on port 3000:
```bash
flutter run -d chrome --web-port=3000 --dart-define=APP_ENV=prod --dart-define=RAZORPAY_KEY_PROD=rzp_live_SFw9YPmFfp12PK
```

## Notes
- The OAuth redirect URI is configured for `http://localhost:3000/auth/callback`
- Make sure this URL is added to your AWS Cognito App Client's Allowed Callback URLs
- Keep `RAZORPAY_KEY_SECRET` on backend only (never pass it to Flutter web/mobile builds).
