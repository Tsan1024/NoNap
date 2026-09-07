# NoNap behavior contract

Both platform implementations follow these user-visible rules:

- The main switch controls whether the computer may keep running with its lid closed.
- Countdown accepts 0 through 24 hours. Zero means no time limit.
- Battery protection accepts 5% through 50% and applies only while discharging.
- Battery Saver or Low Power Mode stops an owned keep-awake session while on battery.
- Normal exit stops an owned session and restores the power settings that existed before it.
- Startup never silently enables a new session. A stale session journal is restored first.
- The UI reports the operating system's real state and reports failures honestly.
- English and Simplified Chinese are available, with first-launch language detection.

Platform implementations may use different native mechanisms and permission flows to meet
this contract. A managed-device policy can prevent NoNap from changing the required setting;
that condition must be shown as an error rather than reported as success.
