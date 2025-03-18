# flutter_local_notifications 패키지로 로컬 푸시 알림 구현

로컬 푸시 알림을 구현하면서, 정해진 시간에 푸시 알림을 예약해놓고, 앱이 완전히 종료되어도 등록된 시간에 푸시 알림이 올 수 있도록 하는 기능을 구현

## 기본 구현

1. 패키지 설치

```bash
$ dart pub add flutter_local_notifications
```

2. 코드 작성

injectable, get_it을 이용해 의존성 주입하는 방식으로 서비스를 구현

```dart
/// notification_service.dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:injectable/injectable.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;


@LazySingleton(as: NotificationService)
class NotificationServiceImpl implements NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifyPlugin =
      FlutterLocalNotificationsPlugin();

  /// 푸시 알림 권한 요청하는 메소드
  ///
  /// main.dart에서 호출
  @override
  Future<void> getPermissions() async {
    if (await Permission.notification.isDenied &&
        !await Permission.notification.isPermanentlyDenied) {
      await [Permission.notification, Permission.scheduleExactAlarm].request();
    }
  }

  /// 플러그인 및 타임존 초기화하는 메소드
  ///
  /// main.dart에서 호출
  @override
  Future<void> init() async {
    AndroidInitializationSettings android =
        const AndroidInitializationSettings("@mipmap/ic_launcher");
    DarwinInitializationSettings ios = const DarwinInitializationSettings(
      requestSoundPermission: false,
      requestBadgePermission: false,
      requestAlertPermission: false,
    );
    InitializationSettings settings =
        InitializationSettings(android: android, iOS: ios);
    await _localNotifyPlugin.initialize(settings);
    tz.initializeTimeZones();
  }

  /// 타임존에 맞게 스케쥴 시각 생성하는 메소드
  ///
  /// 지금 코드는 현재 시각 + 2분으로 설정
  tz.TZDateTime _timeZoneSetting() {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Seoul'));
    tz.TZDateTime target = tz.TZDateTime.now(tz.getLocation('Asia/Seoul'))
        .add(const Duration(minutes: 2));
    return target;
  }

  /// 알림 스케쥴을 등륵하는 메소드
  ///
  /// zonedSchedule() 함수를 활용
  @override
  Future<void> addTestNotifySchedule({required int id}) async {
    NotificationDetails details = const NotificationDetails(
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
      android: AndroidNotificationDetails(
        "1",
        "test",
        importance: Importance.max,
        priority: Priority.high,
      ),
    );

    tz.TZDateTime target = _timeZoneSetting();
    await _localNotifyPlugin.zonedSchedule(
      id,
      "테스트",
      "test notify $id",
      target,
      details,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle, // 이거 설정해야 저전력모드로 들어가도 알림 옴
    );
  }
}
```

```dart
/// main.dart
void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  await configureDependencies();
  final NotificationService notificationService = getIt<NotificationService>();
  await notificationService.getPermissions();
  await notificationService.init();
  runApp(const MainApp());
}
```


여기까지는 기본적인 flutter_local_notifications 코드 작성방법

## AndroidManifest.xml 파일에서 권한 설정

푸시알림 등 권한 설정 필요

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.INTERNET"/>
    <!-- local_notifications 관련 권한 추가 
    RECEIVE_BOOT_COMPLETED : 재부팅 시 스케쥴러 다시 등록하여 정상 동작하게끔
    VIBRATE, WAKE_LOCK : 진동, 화면 잠겨있어도 실행
    USE_FULL_SCREEN_INTENT : 전체 화면 알림 필요시(전화와 같은)
    SCHEDULE_EXACT_ALARM, USE_EXACT_ALARM : Android 버전에 따라 정확한 시각에 알림 동작하게끔 설정
    FOREGROUND_SERVICE : 포그라운드 서비스 권한
    자세한 내용은 패키지 README 참고
     -->
    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
    <uses-permission android:name="android.permission.VIBRATE" />
    <uses-permission android:name="android.permission.WAKE_LOCK" />
    <uses-permission android:name="android.permission.USE_FULL_SCREEN_INTENT" />
    <uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"
        android:maxSdkVersion="32" />
    <uses-permission android:name="android.permission.USE_EXACT_ALARM" />
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
    <!-- local_notifictaions 관련 권한 추가 -->

    <application
        android:label="청모"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:taskAffinity=""
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">
            <meta-data
              android:name="io.flutter.embedding.android.NormalTheme"
              android:resource="@style/NormalTheme"
              />
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>
        <!-- 푸시 알림을 화면에 출력 -->
        <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />
        <!-- 디바이스 재부팅시 알림 스케쥴 유지 -->
        <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver" >
            <intent-filter>
                <action android:name="android.intent.action.BOOT_COMPLETED"/>
                <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
                <action android:name="android.intent.action.QUICKBOOT_POWERON" />
                <action android:name="com.htc.intent.action.QUICKBOOT_POWERON"/>
            </intent-filter>
        </receiver>
        <meta-data
            android:name="flutterEmbedding"
            android:value="2" />
    </application>
    <queries>
        <intent>
            <action android:name="android.intent.action.PROCESS_TEXT"/>
            <data android:mimeType="text/plain"/>
        </intent>
    </queries>
    <queries>
        <intent>
            <action android:name="android.intent.action.VIEW" />
            <data android:scheme="http" />
        </intent>
        <intent>
            <action android:name="android.intent.action.VIEW" />
            <data android:scheme="https" />
        </intent>
    </queries>
</manifest>
```

## iOS 권한 설정

iOS는 테스트 후 추가

## 앱 종료되어도 실행되게 하는 방법

기본적으로 zonedSchedule 기능을 사용하여 OS 레벨에서 스케쥴 등록을 하게 되면, 앱이 완전히 종료되어도 알림이 와야 함.
위에까지 작성하면 debug 모드로 실행한 앱을 완전 종료해도 알림이 발생하지만, 실제 기기에 release 모드로 빌드한 앱을 설치하면 알림이 안 옴.

이는 앱을 release 모드로 빌드하는 과정에서 누락 사항들이 생기기 때문.
앱을 release 모드로 빌드하면 Proguard에 의해 앱이 경량화됨.
이때 정확한 원인은 모르겠으나, 이 과정에서 경량화되는 내용 중에 알림 관련하여 크리티컬한 내용이 있는 듯.
일단 notification에서 사용되는 mipmap/ic_launcher.png 같은 파일도 삭제됨. 이거 하나 때문은 아니겠지만...

암튼 그래서 해결하려면,

android/app/proguard-rules.pro 파일 생성

```pro
# Note: This file is not required for flutter_local_notifications v19 and higher

## Gson rules
# Gson uses generic type information stored in a class file when working with fields. Proguard
# removes such information by default, so configure it to keep all of it.
-keepattributes Signature

# For using GSON @Expose annotation
-keepattributes *Annotation*

# Gson specific classes
-dontwarn sun.misc.**
#-keep class com.google.gson.stream.** { *; }

# Prevent proguard from stripping interface information from TypeAdapter, TypeAdapterFactory,
# JsonSerializer, JsonDeserializer instances (so they can be used in @JsonAdapter)
-keep class * extends com.google.gson.TypeAdapter
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# Prevent R8 from leaving Data object members always null
-keepclassmembers,allowobfuscation class * {
  @com.google.gson.annotations.SerializedName <fields>;
}

# Retain generic signatures of TypeToken and its subclasses with R8 version 3.0 and higher.
-keep,allowobfuscation,allowshrinking class com.google.gson.reflect.TypeToken
-keep,allowobfuscation,allowshrinking class * extends com.google.gson.reflect.TypeToken
```

android/app/build.gradle 파일 수정

```cfg
android {
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_1_8
    }

    defaultConfig {
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.debug
            proguardFiles "${project.rootDir}/app/proguard-rules.pro" // 이거 추가
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.1.4' // 이거 추가
}
```

android/app/src/main/res/keep.xml 생성

```xml
<?xml version="1.0" encoding="utf-8"?>
<resources xmlns:tools="http://schemas.android.com/tools"
    tools:keep="@drawable/*, @mipmap/*" />
```

그리고 빌드 과정에서 notification init 하는 코드를 찾아갈 수 있도록 entry point를 main.dart에 지정
사실 이건 의미가 있나 싶긴 한데 일단 되긴 함.

```dart
@pragma('vm:entry-point')
void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  await configureDependencies();
  final NotificationService notificationService = getIt<NotificationService>();
  await notificationService.getPermissions();
  await notificationService.init();
  runApp(const MainApp());
}
```