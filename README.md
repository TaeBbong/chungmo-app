# *chungmo* project with clean architecture

![previewed](./designs/previews/brand.jpeg)

모바일 청첩장 링크를 첨부하면 GPT가 일정을 파싱하여 캘린더에 등록하는 앱입니다.

<a href="">
<img src="https://img.shields.io/badge/appstore-0D96F6?style=for-the-badge&logo=appstore&logoColor=white" >
</a>
<a href="">
<img src="https://img.shields.io/badge/google play-414141?style=for-the-badge&logo=googleplay&logoColor=white">
</a>

## Features

![merged](./designs/previews/merged.jpeg)

1) CreatePage : 사용자가 링크를 입력하면 -> 서버에 링크를 보내 컨텐츠를 파싱/분석하며 그동안 로딩 애니메이션 보여줌 -> 서버로부터 결과 나오면 결과를 보여주며 해당 결과를 로컬 저장소(db)에 저장
2) CalendarPage : CreatePage 왼쪽 상단 달력 아이콘 버튼을 통해 접근됨.
달력 위젯으로 채워진 페이지 -> 로컬 저장소에 저장된 일정 정보를 바탕으로 달력 위젯에 보여줌 -> 우측 상단 버튼을 통해 달력 <-> 목록으로 보여주는 방식 전환 가능 -> 날짜를 탭하면 해당 날짜에 등록된 간략한 일정 정보(ListTile)를 bottom sheet으로 보여줌 -> 각 일정을 탭하면 DetailPage로 이동
3) DetailPage : 일정에 대한 자세한 정보를 제공 -> 우측상단 수정하기 버튼을 통해 일정을 수정 가능
4) 그 외 : 푸시알림 기능을 통해 일정이 임박했을 때(전날) 앱 푸시 알림을 제공

### App Screenshots

| ![](./designs/screenshots/splash.jpg) | ![](./designs/screenshots/permission.jpg) | ![](./designs/screenshots/main.jpg) | ![](./designs/screenshots/loading.jpg) |
|----------------------|----------------------|----------------------|----------------------|
| ![](./designs/screenshots/result.jpg) | ![](./designs/screenshots/done.jpg) | ![](./designs/screenshots/calendar.jpg) | ![](./designs/screenshots/list.jpg) ||----------------------|----------------------|----------------------|----------------------|
| ![](./designs/screenshots/detail.jpg) | ![](./designs/screenshots/edit.jpg) | ![]() | ![]() |


## Get Started

### env.dart

임시방편 : env.dart, static을 통한 전역 변수화
```dart
/// core/env.dart
/// Temporary way to seperate environments.
/// TODO: Apply Flavor to native env
enum Environ { local, dev, production }

class Env {
  static late final Environ env;
  static late final String url;

  static void init(Environ environment) {
    env = environment;
    switch (environment) {
      case Environ.local:
        url = 'https://local-api.example.com';
        break;
      case Environ.dev:
        url = 'https://dev-api.example.com';
        break;
      case Environ.production:
        url = 'https://api.example.com';
        break;
    }
  }
}
```

## Project Architecture

Based on clean architecture

```css
📂 core/
   ├── utils/       (공통 유틸 함수)
   ├── errors/      (예외 처리)
   ├── network/     (네트워크 관련 설정)

📂 data/  
   ├── datasources/ (로컬, 원격 데이터 소스)
   ├── repositories/ (Repository 구현체)
   ├── models/      (데이터 모델)

📂 domain/
   ├── entities/    (순수 도메인 모델)
   ├── repositories/ (추상 Repository)
   ├── usecases/    (비즈니스 로직)

📂 presentation/  (UI 계층)
   ├── controllers/ (GetX의 Controller 또는 ViewModel)
   ├── pages/       (화면 UI)
   ├── widgets/     (재사용 가능한 UI 컴포넌트)
   ├── themes/      (앱 테마 관리)

📂 di/              (의존성 주입)
📂 main.dart
```

```txt
┌────────────────────────── UI (MVVM) ──────────────────────────┐
│  View (StatelessWidget)                                        │
│     ├──> ViewModel (Controller, GetX)                         │
│     │     ├──> UseCase (Business Logic)                       │
│     │     │     ├──> Repository (Interface)                   │
│     │     │     │     ├──> Remote Data Source (API, Firebase) │
│     │     │     │     ├──> Local Data Source (SQLite, Hive)   │
│     │     │     │     ├──> Cache (SharedPrefs, SecureStorage) │
│     │     │     │                                              │
└───────> Dependency Injection (get_it + injectable) ───────────┘
```

## Todo

- [x] push notification 클릭 후 넘어오는 페이지(detail) 설정
- [x] splash page 좀 더 길게..

## Release Note

### Versioning

1(major) . 0(minor) . 0(maintain) + 1(version code)
여기서 version code는 계속 증가해야 함(안드로이드에 한하여)

## Depends on

사용중인 패키지

## License

오픈소스 라이센스