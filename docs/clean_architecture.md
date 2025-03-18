# *chungmo* project with clean architecture

## 프로젝트 구조

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

## 아키텍처 주요 개념

1. domain/entities : 순수 도메인 모델로, fromJson 등 데이터 소스와 연관되는 기능은 전혀 구현되지 않고, 오직 모델 구성요소만 포함된 말그대로 모델
2. data/models : domain/entities를 상속받으며, fromJson와 같은 데이터 소스와 연결되는 기능을 포함하는 등 기능적 관점에서의 모델
3. domain/repositories : 추상 단계의 레포지토리로, 도메인 영역에서 추상화시켜놓고 data/repositories에서 실제 구현
4. data/repositories : 실제 레포지토리로, 데이터 소스와 연결되어 도메인 영역으로 데이터를 제공
5. domain/usecases : 도메인 영역에서 제공되는 비즈니스 로직으로, 데이터 영역에서 전달받은 데이터를 각 용도에 맞게 presentation 계층으로 전달

6. abstract, 추상화 : 클래스 또는 메소드를 구현없이 선언만 해놓는 것
이를 통해 어떤 기능이 필요하다는 것까지는 정의하지만, 실제 구현은 다른 곳에서 정의

왜 이렇게 하냐?? 답은 관심사 분리에 있었다..
예를 들어 getSchedule이라는 기능을 abstract를 통해 선언했다면,
위젯 입장에서는 getSchedule이라는 함수가 있다는 것, 인자와 리턴 타입 정도만 알고 있으면 아무튼 이렇게 쓰면 되겠지.. 하면서 쓰면 된다는거.
실제 구현은 다른 곳에서 하게 되며(implements),

getSchedule <-> widget
getScheduleImpl -> getSchedule <-> widget
이렇게 한 레이어를 더 두게 되면 파일은 많아지고 복잡해보이지만,
위젯 입장에서 getSchedule의 구현체(Impl)와 상관 없이 getSchedule 인터페이스만 참고하면 되며,
getScheduleImpl이 바뀌게 되더라도 getSchedule 인터페이스가 안변하면 위젯 입장에선 알빠노이기 때문에 관심사 분리에서 유리하다.

근데 자세히 공부해보려니 인터페이스랑 추상화가 좀 다른 개념인거 같다..
✅ 인터페이스: "구현 없이 메서드 시그니처만 정의하고, implements를 통해 모든 메서드를 강제 구현해야 하는 구조"
✅ 추상 클래스: "일부 구현이 가능하며, extends를 통해 상속받거나, implements를 통해 인터페이스처럼 사용할 수 있는 클래스"
일단 그렇다고 함.. 

추상 클래스(abstract) : 상속을 위한 부모 클래스, 오버라이드와 같이 선언된 메소드를 재구현할 수 있고, 확장할 수 있음
인터페이스(implement) : 클래스 간 규약(프로토콜)/요구사항이라고 보면 되며, 이 클래스를 기반으로 한 클래스는 반드시 이런 메소드를 구현해야 한다..

7. 의존성 주입(injectable, get_it)

8. flavor를 통한 dev/staging/production 환경 분리
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

## Versioning

1(major) . 0(minor) . 0(maintain) + 1(version code)
여기서 version code는 계속 증가해야 함(안드로이드에 한하여)

## 프로젝트 주요 기능(앱)

1) CreatePage : 사용자가 링크를 입력하면 -> 서버에 링크를 보내 컨텐츠를 파싱/분석하며 그동안 로딩 애니메이션 보여줌 -> 서버로부터 결과 나오면 결과를 보여주며 해당 결과를 로컬 저장소(db or hive)에 저장
2) CalendarPage : CreatePage 왼쪽 상단 달력 아이콘 버튼을 통해 접근됨.
달력 위젯으로 채워진 페이지 -> 로컬 저장소에 저장된 일정 정보를 바탕으로 달력 위젯에 보여줌 -> 우측 상단 버튼을 통해 달력 <-> 목록으로 보여주는 방식 전환 가능 -> 날짜를 탭하면 해당 날짜에 등록된 간략한 일정 정보(ListTile)를 bottom sheet으로 보여줌 -> 각 일정을 탭하면 DetailPage로 이동
3) DetailPage : 일정에 대한 자세한 정보를 제공 -> 우측상단 수정하기 버튼을 통해 일정을 수정 가능
4) 그 외 : 푸시알림 기능을 통해 일정이 임박했을 때(전날) 앱 푸시 알림을 제공

