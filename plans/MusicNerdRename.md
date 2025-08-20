# **Music Nerd Rename Checklist**

Renaming bundle identifier from com.xdjs.TrackNerd → com.xdjs.musicnerd.

## **1\) GitHub repo \+ local**

✅ Rename repo on GitHub to MusicNerd (Settings → General → Repository name).  
✅ Update local remote (if URL changed): git remote set-url origin git@github.com:\<org-or-user\>/MusicNerd.git  
✅ Update README/title/badges to “MusicNerd”.

## **2\) Xcode project rename items**

✅ Target display name (user-facing): Info.plist → CFBundleDisplayName \= Music Nerd.  
✅ Scheme name: Product → Scheme → Manage Schemes → rename to MusicNerd.  
✅ Product Name: Target → Build Settings → Packaging → Product Name \= Music Nerd.  
✅ Bundle Identifier: Target → Signing & Capabilities → com.xdjs.musicnerd (App/UITests/UnitTests/Extensions if present).

## **3\) Apple developer / signing**

✅ If using Automatic Signing: let Xcode create new profiles for com.xdjs.musicnerd.  
* If using fastlane match: run fastlane match appstore & fastlane match development.  
* Verify the correct Team under Signing for all targets.

## **4\) App Store Connect**

* Create new app record for com.xdjs.musicnerd.  
* Fill required metadata (subtitle, category, privacy policy, data collection).  
* Reconfigure TestFlight (internal testers carry over; external testers need re-invite or new public link).

## **5\) URL schemes & identifiers**

✅ Update custom URL schemes (e.g., musicnerd://).  
✅ Update Associated Domains, Push, Keychain Groups, App Groups if bundle-ID bound.

## **6\) Codebase find/replace**

* Search for TrackNerd → replace with MusicNerd where appropriate (logs, analytics, UI strings, configs).  
* Keep class/type names unless full rename desired.

## **7\) Fastlane / CI**

* Update Appfile: app\_identifier "com.xdjs.musicnerd".  
* Update Fastfile: scheme: "MusicNerd", replace old bundle IDs.  
* Run lanes: fastlane tests\_local, fastlane beta.

## **8\) ShazamKit / MusicKit / Info.plist**

* Verify usage strings still exist: NSMicrophoneUsageDescription, NSAppleMusicUsageDescription.  
* No additional changes needed for APIs.

## **9\) Verify the archive**

* Archive in Xcode.  
* Inspect archive Info.plist: CFBundleIdentifier \= com.xdjs.musicnerd, CFBundleDisplayName \= Music Nerd.  
* Upload to App Store Connect, re-add external testers or regenerate public link.

## **10\) Post-merge cleanup**

* Update issues/PR templates with new name.  
* Update TestFlight What to Test \+ Discord copy.  
* Tag release noting rename \+ new bundle ID.

## **Quick rollback plan**

* Create a backup tag before rename: git tag before-rename.  
* Switch bundle ID back to com.xdjs.TrackNerd temporarily if hotfix needed.
