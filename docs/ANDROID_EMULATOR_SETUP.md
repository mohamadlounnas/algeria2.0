# Android Emulator Network Configuration

## Issue

When running the Flutter app on an Android emulator, you may encounter connection errors like:

```
ClientException with SocketConnection refused
(OS Error: Connection refused, errno = 111),
address = localhost, port = 41610
```

This happens because `localhost` in the Android emulator refers to the emulator itself, not your host machine.

## Solution

The app automatically detects the platform and uses the correct URL:

- **Android Emulator**: Uses `http://10.0.2.2:3000` (maps to host machine's localhost)
- **iOS Simulator**: Uses `http://localhost:3000` (works directly)
- **Physical Devices**: Would need your machine's actual IP address

## Implementation

The fix is implemented in `app/lib/core/constants/api_constants.dart`:

```dart
import 'dart:io';

class ApiConstants {
  static String get baseUrl {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:3000';
    } else {
      return 'http://localhost:3000';
    }
  }
  // ...
}
```

## Testing

1. **Start the backend server:**
```bash
cd server
bun run dev
```

2. **Run the Flutter app on Android emulator:**
```bash
cd app
flutter run
```

3. **Verify connection:**
   - The app should now connect successfully
   - Sign in should work without connection errors

## For Physical Devices

If testing on a physical Android device, you'll need to:

1. **Find your machine's IP address:**
   - macOS/Linux: `ifconfig | grep "inet "`
   - Windows: `ipconfig`

2. **Update the base URL** (temporarily for testing):
   ```dart
   static String get baseUrl {
     if (Platform.isAndroid) {
       return 'http://YOUR_IP_ADDRESS:3000'; // e.g., 'http://192.168.1.100:3000'
     } else {
       return 'http://localhost:3000';
     }
   }
   ```

3. **Ensure firewall allows connections:**
   - Allow incoming connections on port 3000
   - Ensure device and computer are on same network

## Troubleshooting

### Still Getting Connection Errors?

1. **Verify backend is running:**
   ```bash
   curl http://localhost:3000
   ```

2. **Check emulator network:**
   - Ensure emulator has internet access
   - Try `adb shell ping 10.0.2.2`

3. **Verify port 3000 is accessible:**
   - Check if another service is using port 3000
   - Try changing the backend port

4. **Check AndroidManifest.xml:**
   - Ensure `<uses-permission android:name="android.permission.INTERNET"/>` is present

### Alternative: Use ADB Port Forwarding

You can also use ADB port forwarding:

```bash
adb reverse tcp:3000 tcp:3000
```

Then use `localhost:3000` in your app (works for both emulator and physical devices).

---

**Last Updated**: 2024

