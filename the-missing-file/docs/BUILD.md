# Building and Installing The Missing File

## 1. Install the APK on your Android phone

1. Copy `the-missing-file-debug.apk` to the phone (USB cable, Google Drive, or send it to yourself by e-mail or chat).
2. On the phone, open the file from the **Files** app or your downloads.
3. Android will ask to allow installing from this source. Tap **Settings**, switch on **Allow from this source**, then go back.
4. Tap **Install**. If Play Protect warns that it does not recognise the developer, choose **Install anyway** (this is normal for an app that is not from the Play Store).
5. Open **The Missing File** from your app list.

Requirements: Android 7.0 or newer. No internet connection or permissions are needed.

To update to a newer debug build, install the new APK over the old one; your save is kept.

## 2. Debug build and release build: the difference

| | Debug build | Release build |
|---|---|---|
| Purpose | Testing on your own phone | Publishing (Play Store or public download) |
| Signed with | A throw-away debug key | **Your own private release key** |
| Size / speed | Larger, includes debugging helpers | Smaller, optimised |
| Play Store | Not accepted | Required (as an `.aab` bundle) |

Every APK produced so far is a **debug build**.

## 3. Rebuilding the APK yourself

You need, on a computer:

1. **Godot 4.6.2** (standard version, not .NET): https://godotengine.org/download
2. In Godot: **Editor → Manage Export Templates → Download and Install**.
3. **Android Studio** (it installs the Android SDK): https://developer.android.com/studio
4. In Godot: **Editor → Editor Settings → Export → Android** and set
   - *Java SDK Path* to the JDK folder (Android Studio ships one, JDK 17),
   - *Android SDK Path* to the SDK folder (shown in Android Studio under *Settings → Android SDK*).

Then open `the-missing-file/project.godot` in Godot and choose **Project → Export → Android → Export Project**, with *Export With Debug* ticked for a debug build.

From a terminal the same thing is `tools/build_apk.sh`, which also runs the automated tests first.

## 4. Release build and signing (for later)

A release build must be signed with a key that only you hold. Create it once:

```
keytool -genkeypair -v -keystore the-missing-file-release.keystore -alias themissingfile -keyalg RSA -keysize 2048 -validity 10000
```

- **Back this file and its password up somewhere safe.** If you lose it you can never publish an update of the same app.
- **Never commit it to the repository** (`.gitignore` already blocks `*.keystore` and `*.jks`).

In Godot: **Project → Export → Android → Keystore → Release**: choose the keystore file, alias and password. Untick *Export With Debug* and export. For the Play Store, switch *Export Format* to **AAB**.

## 5. Automated tests

```
godot --headless --path . res://tests/run_tests.tscn
```

Checks that every text exists in both English and Turkish, that all case data refers to things that exist, that every dialogue branch is reachable, and plays through the critical path without a screen.

## 6. Regenerating the art

```
python3 tools/make_art.py      # writes SVG sources to art_src/
node tools/render_art.js       # renders them to assets/ as PNG (needs Playwright)
```
