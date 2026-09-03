# Privacy — Dumpling Breath

Plain-language statement. Suitable verbatim for the App Store product page
("App Privacy" → "Privacy Policy" URL target) and the in-app **Privacy** screen.

---

## The short version

**Dumpling Breath collects nothing. There is no account. The app never connects
to the internet.**

Everything happens on your device, in the moment. When you close the app,
there is nothing left on a server — because there is no server.

---

## The slightly longer version

### No account, ever
You don't sign in. You don't give us an email, a phone number, or a name.
There is no "profile". The app works the first second you open it.

### No network
Dumpling Breath has no networking code and ships without permission to make
network requests. It cannot phone home, load ads, or sync to a cloud, because
none of that is built in. You can put your phone in Airplane Mode and the app
is exactly as complete.

### No analytics, no tracking, no advertising
There is no analytics SDK. No crash-reporting SDK. No advertising identifier
use. No third-party code of any kind. We do not know how many breaths you
take, when you open the app, or whether you finished a session. The App Store
privacy label is "Data Not Collected", and the bundled
`PrivacyInfo.xcprivacy` manifest declares no tracking and no collected data
types.

### No streaks, no history, no reminders
The app deliberately keeps no session history and no streak count, and it will
never send you a notification asking you to come back. The only things stored
on your device are three small preferences: which breathing pattern you last
chose, whether you use hold-to-breathe or tap-to-toggle, and whether you turned
on the optional Health logging below. They live in the system's standard
preferences store and never leave the device.

### Health logging is opt-in and local
If — and only if — you turn it on in **Settings → Privacy** inside the app,
Dumpling Breath can write a finished session to Apple's **Health** app as
**Mindful Minutes**, and optionally a **State of Mind** entry ("a moment of
calm"). This uses Apple's HealthKit and is governed by the permission sheet iOS
shows you. That data is written only to Health on your device; Dumpling Breath
still has no way to transmit it anywhere. You can turn it off at any time, and
you can revoke Health access entirely in the system Health app. Health data is
never used for tracking or advertising and is never shared with third parties.

### The widget, the Control Center control, and the Watch
The Lock Screen / Home Screen widget and the Control Center control store one
tiny thing in a shared on-device container: a "please start a session" flag and
a timestamp, so the app knows you tapped. It is cleared as soon as the app
reads it. The Apple Watch app runs entirely on your wrist and needs no phone.

### Children
Dumpling Breath is designed for all ages and collects no data from anyone, so
there is nothing to treat differently for children. It contains no ads, no
in-app purchases that pressure, no external links, and no user-generated
content.

### Changes
If a future version ever changes any of this, the change will be described here
and in the version's release notes before it ships. The design intent, written
into the project's North Star, is that it never does.

### Contact
Questions: avaresearchLLC@gmail.com
