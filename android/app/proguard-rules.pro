# Release build (R8). ML Kit's model downloader still references the retired
# firebase-iid, which build.gradle.kts excludes (it clashes with
# firebase-messaging). The class is never used at runtime.
-dontwarn com.google.firebase.iid.FirebaseInstanceId
