# _chungmo_ project with clean architecture

![previewed](./designs/previews_android/brand.jpeg)

모바일 청첩장 링크를 첨부하면 GPT가 일정을 파싱하여 캘린더에 등록하는 앱입니다.

<a href="">
<img src="https://img.shields.io/badge/appstore-0D96F6?style=for-the-badge&logo=appstore&logoColor=white" >
</a>
<a href="https://play.google.com/store/apps/details?id=com.taebbong.chungmo">
<img src="https://img.shields.io/badge/google play-414141?style=for-the-badge&logo=googleplay&logoColor=white">
</a>

## Features

![merged](./designs/previews_android/merged.jpeg)

1. CreatePage : 사용자가 링크를 입력하면 -> 서버에 링크를 보내 컨텐츠를 파싱/분석하며 그동안 로딩 애니메이션 보여줌 -> 서버로부터 결과 나오면 결과를 보여주며 해당 결과를 로컬 저장소(db)에 저장
2. CalendarPage : CreatePage 왼쪽 상단 달력 아이콘 버튼을 통해 접근됨.
   달력 위젯으로 채워진 페이지 -> 로컬 저장소에 저장된 일정 정보를 바탕으로 달력 위젯에 보여줌 -> 우측 상단 버튼을 통해 달력 <-> 목록으로 보여주는 방식 전환 가능 -> 날짜를 탭하면 해당 날짜에 등록된 간략한 일정 정보(ListTile)를 bottom sheet으로 보여줌 -> 각 일정을 탭하면 DetailPage로 이동
3. DetailPage : 일정에 대한 자세한 정보를 제공 -> 우측상단 수정하기 버튼을 통해 일정을 수정 가능
4. 그 외 : 푸시알림 기능을 통해 일정이 임박했을 때(전날) 앱 푸시 알림을 제공

### App Screenshots

| ![](./designs/screenshots/splash.jpg) | ![](./designs/screenshots/permission.jpg) | ![](./designs/screenshots/main.jpg)     | ![](./designs/screenshots/loading.jpg) |
| ------------------------------------- | ----------------------------------------- | --------------------------------------- | -------------------------------------- |
| ![](./designs/screenshots/result.jpg) | ![](./designs/screenshots/done.jpg)       | ![](./designs/screenshots/calendar.jpg) | ![](./designs/screenshots/list.jpg)    |
| ![](./designs/screenshots/detail.jpg) | ![](./designs/screenshots/edit.jpg)       |                                         |                                        |

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

### refact

- [x] pages 정리(about 등)
- [x] controller에서 initial fetch 하는 방법 바꾸기(Stateful => controller의 onInit)
  - onInit은 Get.put 시점에 실행됨 => 위젯 빌드보다 먼저 호출됨(왜냐면 Get.put의 시점 => 위젯 클래스 객체 생성 시점)
  - Worker의 ever, debounce 이런거는 용도에 맞게 나중에 써보자
  - GetX 문서, 레포를 좀 더 공부해볼 필요가 있을듯.. 이걸 다 하면 GetX 졸업
- [ ] 객체지향 컨셉 좀 더 적극적으로 써보기
  - https://velog.io/@ximya_hf 이걸 참고해라..
  - [ ] mixin(상속 없이 객체 기능 추가)
  - [ ] factory(비슷한 위젯),
  - [x] single import,
  - [x] extension type
  - [ ] part/extension(viewmodel 분할)
  - [x] static util 클래스에 abstract, private constructor 적용
  - [ ] baseview, baseviewmodel 만들기?
  - [x] base usecase도 만들 수 있겠지?(abstract interface, implements)
- [ ] Isolate 활용(어디서?)
  - 복잡한 위젯 빌드와 대용량 이미지 로드할 때 적용함(보통의 경우 불필요)
  - 그래도 걍 적용해보자(lottie랑 api call 동시에 해야하는 CreatePage / 이미지들 로드 해야하는 CalendarPage)
- 리팩토링 건마다 블로그 하나씩?
- [x] 1차 리팩토링 완료

### Features

- [ ] 백엔드 요청 안정화
  - [ ] 백엔드에서 요청 오래 걸릴 때(에러, cold state이거나) 빠르게 끊고 새로 요청 보내는 로직
- [ ] 테스트 코드 재작성
  - [ ] Stream 기반 테스트 코드 재작성

## Release

### 1.0.1+2 배포 준비

- [x] entity의 date는 DateTime으로 정리, mapper에서 string <-> DateTime 수행하게끔
- [x] showcaseview 기반 온보딩 튜토리얼 만들기
- [ ] 메인 페이지에서 등록된 일정 일부 보여지게끔
- [ ] 푸시 알림 권한 강조 요청
- [x] iOS 배포를 위한 테스트

### 1.0.2+3 배포 준비

- [x] hotfix: 일정 등록 후 제대로 안나오는 것 해결(stream 적용하기)

## Release Note

### Versioning

- [1.0.2+3]() 출시 완료(25.05.18.) / hotfix 적용
- [1.0.1+2]() 출시 완료(25.05.12.) / playstore, appstore 배포 완료
- [1.0.0+1]() 출시 완료(25.03.27.)

## Depends on

사용중인 패키지

## License

오픈소스 라이센스
