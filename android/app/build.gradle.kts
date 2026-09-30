plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// 앱과 같은 설정 파일(프로젝트 루트의 dart_defines.json)에서 카카오 키를 읽습니다
val dartDefines: Map<*, *> = rootProject.file("../dart_defines.json").let { file ->
    if (file.exists()) groovy.json.JsonSlurper().parse(file) as Map<*, *> else emptyMap<String, String>()
}

android {
    namespace = "com.example.habl"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.habl"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // 카카오 로그인 후 앱으로 돌아오는 스킴 (kakao{네이티브 앱 키})
        manifestPlaceholders["kakaoNativeAppKey"] =
            dartDefines["KAKAO_NATIVE_APP_KEY"]?.toString() ?: ""
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
