## 청모 앱 개발 로그 - 개발자의 관점에서

### 들어가며

청모라는 앱을 만들어서 1.0.0 버전을 플레이 스토어에 올려놓았습니다. 아직 검토 승인이 되진 않았지만, 개발하는 과정에서 고민하고 문제를 해결했던 흐름을 정리해서 공유합니다.

### 문제 인식 : 청모는 어떻게 탄생했는가?

20대 후반이 되어가면서 주변에 결혼하는 분들이 많이 있습니다. 종이 청첩장도 좋지만 받는 입장에서 일정을 확인할 때 보통 모바일 청첩장을 많이 보게 되더라구요.
청첩장을 받자마자 캘린더에 일정과 장소, 필요하면 계좌 정보까지 부지런히 저장하면 편하겠지만, 그렇지 않았던 적이 더 많습니다..^_^
캘린더에 저장해놓지 않았을 때, 매번 카톡 채팅방에 들어가서 모바일 청첩장을 찾고 들어가서 일정을 확인하는 일이 참 많았습니다.
다른 분들도 저와 비슷한 경험을 많이 하셨을거라 생각합니다. 

여기서 식별한 문제점은 2개가 있었는데,
1. 모바일 청첩장이 채팅방 마다 흩어져있으니, 찾는게 어렵다. 모여져 있으면 좋겠다.
2. 매번 모바일 청첩장을 받고 일정/장소 등 정보를 저장하기 귀찮다. 알아서 저장되면 좋겠다.

이런 문제점을 인식하여 "청모" 앱을 기획하게 되었습니다. 

### 문제 해결 : 청모는 어떻게 문제를 해결하는가?

앞서 식별한 2개의 문제점을 "청모" 앱은 아래와 같이 해결합니다.
1. 모바일 청첩장 링크를 입력하여 저장, 모아서 볼 수 있다.
2. 모바일 청첩장을 "알아서" 파싱하여, 일정/장소 정보를 캘린더에 저장한다.

첫번째 문제에 대한 해결은 비교적 간단하고 뻔합니다. 모바일 청첩장 전용 메모앱을 만들겠다는 것이죠.
이 자체로도 누군가에겐 의미가 있을 수 있으나, 문제를 완전히 해결했다고 보기 어렵습니다.
모바일 청첩장의 내용을 "알아서" 파싱하여 일정 정보를 저장하는 것이 "청모"의 "킥"이라고 할 수 있겠습니다.

### 개념 증명 : GPT API가 "알아서" 모바일 청첩장을 파싱할 수 있을까?

여기서 "알아서"는 GPT API가 맡아주었습니다.
몇번의 프롬프트 테스트를 통해, GPT API에게 모바일 청첩장 웹 페이지 리소스를 전달하면, 100%에 가까운 정확도로 일정 정보를 파싱한다는 것을 확인했습니다.

초기에는 GPT에게 모바일 청첩장 링크를 전달했습니다. 여기서 일정 정보를 파싱해달라고 했었죠.
하지만 GPT API는 웹 페이지 접근과 같은 인터렉션에 매우 제한적이었습니다.

그 다음 시도로는 html 페이지 리소스를 python의 requests를 통해 가져온 다음, 해당 데이터를 GPT에게 전달했습니다.
이때 GPT는 놀랍게도 일정 정보를 파싱할 수 있었습니다. 아주 높은 정확도로 말이죠.

여기까지만으로도 GPT API는 모바일 청첩장 내용 파싱이라는 임무를 수행할 수 있었지만, 좀 더 개선이 필요했습니다.
왜냐하면 html 페이지 리소스에는 불필요한 정보가 너무 많았고, 중복된 텍스트도 많이 있었습니다.
특히 여러 애니메이션, 디자인 리소스가 포함되는 모바일 청첩장의 특성상 html 페이지 전체를 GPT에게 input으로 전달하면 그 속도가 많이 느려진다는 것을 체감했습니다.

따라서 여기서 한번 더 개선을 해냈습니다. html에서 불필요한 태그, 스크립트를 미리 BeautifulSoup과 같은 전통적인 파서로 제거하고, 텍스트, 이미지 링크 등 주요 정보만 남겨서 GPT에게 input으로 전달했습니다.
이때 응답속도가 확연히 빨라지는 것을 확인했고, GPT API를 활용할 때 성능 개선을 할 수 있었습니다.

최근에 받은 모바일 청첩장 서비스 업체들이 모두 달라서 마침 잘 되었다 싶어 테스트 했을 때, 모든 종류의 웹 페이지에 대해 GPT가 잘 동작함을 확인했습니다.

### 서비스 기획 : "청모 앱"의 시작

여기까지의 과정을 통해 명확히 사용자들에게 일어나고 있는 문제와, 문제를 해결하기 위한 방법을 도출했습니다.
또한 그 미지의 해결방법이 잘 동작하는 것까지 확인했었죠.
따라서 무언가를 만들 준비는 모두 끝났다고 보았고, 앱 개발을 시작했습니다.

### 기능 요구사항 정리

첫번째 스크럼의 기능 요구사항은 다음과 같습니다.
1. 사용자가 모바일 청첩장 링크를 복사/붙여넣기 하여 입력하면, 이를 서버로 전송하여 파싱된 응답을 받아와 보여주기
2. 파싱된 응답을 로컬 DB에 저장
3. 자체 캘린더 위젯에서는 로컬 DB에 저장된 일정들을 불러와서 보여주기
4. 해당 일정을 선택하면 상세 보기 페이지로 이동
5. GPT가 잘못 파싱할 가능성을 고려해 일정에 대한 수정기능 제공
6. 각 일정의 전날, 푸시 알림을 통해 다음날 일정을 알려주기

위와 같은 기능 요구사항을 정리하면서 사용자가 최대한 귀찮지 않게 하고, 빠른 개발을 위해 최소한의 기능만을 구현하기로 목표하였습니다.

### 기술 스택 선택 : Firebase functions, GetX, flutter_local_notifications, 그리고 클린 아키텍처

앞서 정리한 기능 요구사항을 바탕으로 어떤 기술을 선택할지 결정할 수 있었습니다. 결정 과정에서 고민했던 내용을 공유합니다.

#### 1. 서버가 필요한가?

이 프로젝트에서는 GPT API를 사용합니다. 앱 레벨에서 GPT API를 직접 호출해도 될까요?
기능적으로는 크게 문제는 없지만 보안적인 문제가 존재합니다. API KEY가 노출된다는 것입니다.
또한 앞서 연구했던 것과 같이 링크를 GPT API에 바로 전달하는게 아니라 html을 한 차례 가공한다는 공정이 있기 때문에, 적절한 규모의 서버가 필요하다고 느꼈습니다.

클래식한 방식의 서버, 함수 단위의 서버리스 방식 중에선 함수 방식으로 빠르게 결정되었습니다.
이런 의사결정을 한 것에는 1. 이 앱에는 서버에서 저장/관리할 데이터가 없다. 2. 단 하나의 API만 필요하다. 3. 인증/로그인과 같은 기능이 당장 필요 없다.
이렇게 3가지 근거에 있었습니다.

또한 함수 단위의 서버리스 방식은 확장하기도 용이합니다.
새로운 API 기능이 필요하면, 새로운 함수를 작성하여 올리면 되기 때문입니다.
따라서 잠재적으로 추가해야 하는 기능에 대한 고민도 덜 수 있었습니다.

AWS Lambda, Firebase Functions와 같은 도구들 중에서, 적은 사용자를 대상으로 무료로 쓸 수 있고 사용하는데 익숙하며 간편한 Firebase Functions를 채택했습니다.

#### 2. DB는 필요한가?

앞선 질문에서 저장/관리할 데이터가 없다는 결론이 있었습니다만, 그것은 서버 단에서 저장할 것이 없다는 것이었죠.
클라이언트 앱의 입장에서는 일정을 저장하고 때론 수정도 해야 합니다. 언제든 불러올 수도 있어야 하죠.
이런 관점에서 Hive와 같은 단순한 방식의 데이터 저장소 / sqflite와 같은 클래식한 경량화 DB 중에서는 sqflite를 선택했습니다.

이 고민을 시작하면서 프로젝트에 사용될 모델을 정의해보았는데,

```dart
@freezed
class Schedule with _$Schedule {
  const factory Schedule({
    required String link, // 모바일 청첩장 링크
    required String thumbnail, // 대표 이미지
    required String groom, // 신랑 이름
    required String bride, // 신부 이름
    required String date, // 일정
    required String location, // 장소
  }) = _Schedule;
}
```

이렇게 6개의 컬럼이 필요했고, 캘린더에 표시하기 위해 일정을 기준으로 필터링하는 기능이 필요했습니다.
따라서 데이터를 읽어오고 편집하는데 용이하려면 Hive와 같은 Key-Value 방식보다 관계형 DB가 더 적합하다고 판단했습니다.

#### 3. 상태 관리 도구는 뭘 쓸까?

플러터에는 상태 관리 도구 3대장이 있습니다. BloC, Provider, GetX가 그것입니다.
~~Riverpod도 심심찮게 보이지만, 아직 제게 익숙치는 않습니다.~~

각 상태 관리 도구는 개성이 강하고 장단점이 명확한데,
먼저 BloC은 현재, 그리고 앞으로도 Stream을 사용할 계획이 없고, 프로젝트 규모를 고려했을 때 하나의 상태 관리를 위해 너무 많은 파일이 생긴다고 판단해 제외하였습니다.
Provider와 GetX는 둘다 상태 관리를 위해 사용하기에는 간단하고 좋은 방법들입니다.
둘 중에서는 이후 라우팅이나 다이얼로그, 스낵바 생성에 큰 도움을 받을 수 있는 GetX를 채택하였습니다.
이는 어떻게 보면 상태 관리 도구로써 선택했다기보단 하나의 프레임워크로 선택했다고 보는게 더 적합하겠네요.
어디까지나 빠른 기능 개발을 목표로 했기에, 라우팅과 UI 영역에서의 GetX의 장점을 놓치기엔 아쉬웠습니다.

#### 4. 푸시 알림은 어떻게?

푸시 알림 기능을 구현하는 것은 이번이 처음이었습니다. 
따라서 어떤 기술들로 구현할 수 있는지 먼저 조사해보았는데,
크게 나누면 로컬 푸시 알림과 서버 푸시 알림으로 나눌 수 있었습니다.
푸시 알림을 보내는 주체가 누구냐에 따라 나뉘는데, 기본적으로 이 앱에서 스케쥴 데이터는 서버가 아닌 로컬 DB에 저장되기 때문에 당연히 로컬 푸시 알림을 먼저 고려하게 되었습니다.

제가 기획한 푸시 알림은 모바일 청첩장의 결혼식 일정 전날 11시쯤 "다음날 OOO님의 결혼식이 있어요!"와 같은 푸시 알림을 제공하는 것이었습니다.
당연히 이 푸시 알림은 앱이 종료되어도 발생하여야 합니다.

최초에 생각했던 방식은 매일 11시에 DB를 조회하여 다음날로 저장된 일정을 찾으면 푸시 알림을 제공하는 방식으로 생각했었어요.
이 방식을 구현하기 위해서는 백그라운드로 돌아가는 "서비스"를 구현해야 하고, 이 서비스가 정해진 시각에 작업을 하도록 예약해야 했습니다.

백그라운드 서비스를 구현하기 위해 알아본 플러터 레벨의 패키지는 WorkManager였습니다.
WorkManager는 플러터에서 네이티브 백그라운드 서비스를 구현하기 위해 최선의 선택지였습니다만, 현재 패키지의 동작에 이슈가 있었습니다.
이후에 직접 패키지를 활용해 구현했을 때에도 제대로 동작하지 않았습니다.
~~이때 푸시 알림을 때려칠까 고민 많이 했습니다만..~~
다른 방식의 푸시 알림을 고민하게 되었습니다.

이후에 선택한 방식은 새로운 스케쥴이 등록될 때마다 푸시 알림을 보낼 날짜를 계산하여 푸시 알림을 예약하는 것이었습니다.
이는 스케쥴 등록 뿐만 아니라 스케쥴 수정 때에도 기존 푸시 알림 예약을 취소하고 새로 날짜를 계산하여 등록하는 방식으로 동일하게 동작시킬 수 있었습니다.
여기서 푸시 알림을 예약하는 기능은 flutter_local_notifications 패키지로 구현했습니다.
해당 패키지는 각 네이티브 기기의 알림 스케쥴러를 활용할 수 있고, 개발하는 입장에서 백그라운드 서비스 구현 없이 네이티브한 방식으로 푸시 알림 예약 기능을 구현할 수 있었습니다.
이렇게 하면 백그라운드 서비스를 구현할 필요가 없고, 심지어 앱이 백그라운드에서 매일 같은 시각에(푸시 알림을 보낼만한 스케쥴이 있을지 없을지도 모르는데) 일하는 것을 방지할 수 있습니다.
푸시 알림을 구현하면서 많은 삽질을 했었는데, 아래에서 좀 더 자세히 공유하겠습니다.

#### 5. 클린 아키텍처

사실 이 프로젝트의 또다른 목적은 클린 아키텍처 공부였습니다.
다양한 플러터 오픈소스 프로젝트들을 보면 클린 아키텍처를 많이 적용하는데, 이해가 없으니 코드가 잘 안읽혔습니다.
이에 대한 공부와 실습을 위해 "청모" 앱은 클린 아키텍처로 구성하여 개발하였습니다.

처음 아키텍처를 공부하면서 느꼈던 것은, 어떤 정답이 있는게 아니라 철학을 지키면 된다는 것입니다.
보통 클린 아키텍처를 구성하는 폴더와 파일, 레이어가 있지만 꼭 이것에 국한될 필요는 없겠다고 생각했습니다.
~~물론 아직 잘 모르는 입장에서는 건방진 소리일 수도..~~
그래서 가장 중요하게 거론되는 철학 1. 가장 안쪽의 레이어는 엔티티, 비즈니스 로직으로 구성되며 이들은 외부 의존성이 없거나 최소가 되어야 한다, 2. 이를 위해 추상화로 의존성 역전을 발생시킨다, 3. 각 파일/클래스는 한가지 책임을 가지게 하여 결합도를 낮춘다 를 우선적으로 지키게끔 설계하고 개발했습니다.

최종적으로 선택한 프로젝트 구조는 다음과 같은데,

```css
📂 core/
   ├── di/             (의존성 주입)
   ├── services/       (앱 전역에서 사용되는 서비스(Push Notifications))
   ├── utils/          (공통 유틸 함수)
   ├── env.dart        (각종 설정 값 파일)

📂 data/  
   ├── mapper/         (데이터 모델 <-> 엔티티 변환기)
   ├── models/         (데이터 모델)
   ├── repositories/   (Repository 구현체)
   ├── sources/        (로컬, 원격 데이터 소스)

📂 domain/
   ├── entities/       (순수 도메인 모델)
   ├── repositories/   (추상 Repository)
   ├── usecases/       (비즈니스 로직)

📂 presentation/
   ├── controllers/    (GetX ViewModel)
   ├── pages/          (화면 UI)
   ├── widgets/        (재사용 가능한 UI 컴포넌트)
   ├── themes/         (앱 테마 관리)

main.dart
```

나름 정석적인 아키텍처를 적용하게 되었습니다.

여기서 고민된 부분이 몇 가지 있었습니다.

##### 1. usecase는 필요한가??
usecase는 repository에 선언된 기능 하나를 실행하여 presentation 레이어로 전달하는 역할을 수행합니다.
파일 관점에서 보면 불필요한 파일이 하나 더 생기는 느낌이 있는데, UI에서 원하는 데이터의 용도를 명확히 한다는 점에서 의미가 있다고 결국 판단했습니다.
적용된 사례를 살펴보면,
```dart
import '../../entities/schedule.dart';
import '../../repositories/schedule_repository.dart';

@injectable
class AnalyzeLinkUsecase {
    final ScheduleRepository repository;

    AnalyzeLinkUsecase(this.repository);

    Future<Schedule> execute(String link) {
        return repository.analyzeLink(link);
    }
}
```
여기서 ScheduleRepository는,
```dart
import '../entities/schedule.dart';

abstract class ScheduleRepository {
/// Request to remote server with user input string `url`,
///
/// Response `schedule` json data.
Future<Schedule> analyzeLink(String url);

/// Save Schedule `schedule` into local sqflite db by type ScheduleModel.
///
/// Add notify schedule if `date` is after today.
Future<void> saveSchedule(Schedule schedule);

/// Get a `schedule` from local sqflite db by key `link` for routing `/detail`.
Future<Schedule?> getScheduleByLink(String link);

/// Get all `schedules` from local sqflite db for `ListView`
Future<List<Schedule>> getSchedules();

/// Get monthly `schedules` from local sqflite db for `CalendarView`
Future<Map<DateTime, List<Schedule>>> getSchedulesForMonth(DateTime date);

/// Edit `schedule` from local sqflite db.
///
/// Change notify schedule if `date` changed.
Future<void> editSchedule(Schedule schedule);

/// Delete `schedule` from local sqflite db.
///
/// Delete notify schedule.
Future<void> deleteSchedule(String link);
}
```
이와 같이 Schedule과 관련된 모든 데이터 처리/가공 기능을 구현합니다.
이를 실제로 사용하는 부분은 controllers인데,
```dart
import '../../core/services/notification_service.dart';
import '../../domain/entities/schedule.dart';
import '../../domain/usecases/schedule/get_schedule_by_link_usecase.dart';
import '../../domain/usecases/schedule/analyze_link_usecase.dart';
import '../../domain/usecases/schedule/save_schedule_usecase.dart';

class CreateController extends GetxController {
final AnalyzeLinkUsecase analyzeLinkUseCase = getIt<AnalyzeLinkUsecase>();
final SaveScheduleUsecase saveScheduleUseCase = getIt<SaveScheduleUsecase>();
final NotificationService notificationService = getIt<NotificationService>();

/// `analyzeLink` executes `analyzeLinkUseCase`
/// then executes `saveScheduleUseCase`.
Future<void> analyzeLink(String url) async {
    isLoading(true);
    isError(false);
    try {
        final Schedule scheduleFromRemote = await analyzeLinkUseCase.execute(url);
        ...
```
이와 같이 필요한 곳에서 용도를 명확히 한다는 것이 usecase의 장점이라고 판단했습니다.
usecase를 통해 데이터의 흐름과 용도가 읽기 쉽게 정리되었습니다.

또한 controller에서 repository를 직접 참조하게 되면 data 영역에서의 변화가 presentation 영역에 영향을 미치게 됩니다.
repository_impl(data) -> repository(domain) <- usecase(domain) <- controller(presentation)와 같은 구조에서,
repository_impl(data) -> repository(domain) <- controller(presentation) 이와 같이 presentation을 한 차례 더 보호해주는 usecase가 없다면, repository의 변화가 presentation에 바로 영향을 주기 때문에 usecase는 있는게 더 낫겠다 판단했습니다.

이는 반대로 presentation 영역에서의 변화에도 적용됩니다.
지금은 usecase에서 어떤 가공 작업도 하지 않기 때문에 더욱 불필요하다고 느껴집니다.
만약 repository에서 생산된 데이터를 사용하는 곳이 여러 곳이라고 가정해보면, 이를 각 presentation 사용처에서 사용할 수 있게 가공하는 역할이 필요합니다.
이를 repository에서 구현하면 불필요한 코드가 반복되며, usecase에서 가공하는 것이 더 합리적입니다.

여기까지의 내용으로 냉정하게 판단하면 현재 코드 구조에서는 usecase가 없어도 괜찮습니다.
그러나 1. 여러 곳에서 하나의 데이터가 쓰이게 될 상황, 2. repository와 presentation의 변화 상황을 고려하면 usecase를 지금 도입하는게 부담은 아니라고 최종 판단했습니다.

##### 2. data/model과 domain/entity의 구분은 필요한가??