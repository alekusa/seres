---
description: how to run the flutter app on the emulator or simulator
---

To run the application, follow these steps:

1. List available devices to ensure your emulator or simulator is connected:
```bash
flutter devices
```

2. Run the app on the desired device:
// turbo
```bash
flutter run
```

If you have multiple devices and want to target a specific one (like the iOS Simulator), use:
```bash
flutter run -d [DEVICE_ID]
```

Example for your current iOS Simulator:
// turbo
```bash
flutter run -d 66963229-ACB1-4BB7-B1A6-0D181DBD5080
```
