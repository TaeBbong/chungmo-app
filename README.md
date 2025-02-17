# chungmo project with clean architecture

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

## 프로젝트 주요 기능(앱)

1) CreatePage : 사용자가 링크를 입력하면 -> 서버에 링크를 보내 컨텐츠를 파싱/분석하며 그동안 로딩 애니메이션 보여줌 -> 서버로부터 결과 나오면 결과를 보여주며 해당 결과를 로컬 저장소(db or hive)에 저장
2) CalendarPage : CreatePage 왼쪽 상단 달력 아이콘 버튼을 통해 접근됨.
달력 위젯으로 채워진 페이지 -> 로컬 저장소에 저장된 일정 정보를 바탕으로 달력 위젯에 보여줌 -> 우측 상단 버튼을 통해 달력 <-> 목록으로 보여주는 방식 전환 가능 -> 날짜를 탭하면 해당 날짜에 등록된 간략한 일정 정보(ListTile)를 bottom sheet으로 보여줌 -> 각 일정을 탭하면 DetailPage로 이동
3) DetailPage : 일정에 대한 자세한 정보를 제공 -> 우측상단 수정하기 버튼을 통해 일정을 수정 가능
4) 그 외 : 푸시알림 기능을 통해 일정이 임박했을 때(전날) 앱 푸시 알림을 제공



### 비고

```dart
import 'package:your_project/data/mappers/schedule_mapper.dart';
import 'package:your_project/domain/entities/schedule.dart';
import 'package:your_project/data/models/schedule_model.dart';

// 도메인 엔터티를 데이터 모델로 변환
Schedule schedule = // ... 도메인 엔터티 생성
ScheduleModel scheduleModel = ScheduleMapper.toModel(schedule);

// 데이터 모델을 도메인 엔터티로 변환
ScheduleModel model = // ... 데이터 모델 생성
Schedule entity = ScheduleMapper.toEntity(model);
```