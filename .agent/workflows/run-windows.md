---
description: Run the app on Windows desktop
---
// turbo-all

## Run on Windows

1. Make sure dependencies are installed:
```bash
flutter pub get
```

2. Run on Windows:
```bash
flutter run -d windows
```

## Notes

- OAuth uses a local HTTP server on port **8765** for authentication callback
- Make sure `http://localhost:8765/auth/callback` is added to Cognito App Client callback URLs
- If you see auth errors, check Windows Firewall isn't blocking port 8765
