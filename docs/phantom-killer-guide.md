# Keep Hermes Alive in the Background (Android 12+)

Android kills background processes to save battery. This includes Termux. If you see `[Process completed (signal 9) - press Enter]`, Android just killed your Hermes.

This guide fixes it. Takes about 2 minutes, one time only.

## Step 1: Acquire Wake Lock

Pull down the notification bar, find the Termux notification, tap **Acquire wakelock**.

This prevents Android from suspending Termux.

## Step 2: Disable Battery Optimization

1. Go to Settings > Battery > Battery optimization
2. Find Termux
3. Set it to **Not optimized** (or **Unrestricted**)

The exact path varies by phone manufacturer. Search your settings for "battery optimization" if you can't find it.

## Step 3: Disable Phantom Process Killer (Android 12+)

This is the main one. Android 12 and above kills background child processes automatically. You need ADB to disable it.

**Enable Wireless Debugging:**
1. Go to Settings > Developer options
2. Turn on **Wireless debugging**
3. Tap **Pair device with pairing code**

**Pair with ADB (in Termux):**

```sh
pkg install -y android-tools
adb pair localhost:<PAIRING_PORT> <PAIRING_CODE>
```

**Connect:**

```sh
adb connect localhost:<CONNECTION_PORT>
```

**Disable Phantom Killer:**

```sh
adb shell "settings put global settings_enable_monitor_phantom_procs false"
```

Verify it worked:

```sh
adb shell "settings get global settings_enable_monitor_phantom_procs"
```

If it says `false`, you're done. This setting persists across reboots. You only need to do this once.

You can turn off Wireless debugging after this. It won't affect the setting.

## Step 4: Battery Protection (optional but recommended)

Keeping your phone plugged in 24/7 at 100% can swell the battery. Limit max charge to 80%:

- **Samsung:** Settings > Battery > Battery Protection > Maximum 80%
- **Google Pixel:** Settings > Battery > Battery Protection > ON

## Troubleshooting

If Hermes still gets killed after all these steps:

- Some manufacturers (Samsung, Xiaomi, Huawei) apply extra aggressive battery optimization
- Check https://dontkillmyapp.com for device-specific guides
- Make sure Termux is excluded from "Auto-start" or "App launch" restrictions
