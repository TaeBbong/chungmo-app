# 청무 앱 (Chungmoo App)

[![Flutter Version](https://img.shields.io/badge/Flutter-3.10.0-blue.svg)](https://flutter.dev/)
[![Dart Version](https://img.shields.io/badge/Dart-3.0.0-blue.svg)](https://dart.dev/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

클라이언트(을)의 요청으로 제작된 포트폴리오용 애플리케이션입니다. 이 문서는 프로젝트의 개요, 기술 스택, 아키텍처 및 시작 가이드를 제공합니다.

## 🌟 주요 기능

- **회원 관리**: 사용자의 회원가입, 로그인, 정보 수정 기능을 제공합니다.
- **콘텐츠 관리**: 특정 데이터를 조회하고 관리하는 기능을 포함합니다.
- **푸시 알림**: FCM을 통해 사용자에게 중요한 정보를 알림으로 보냅니다.
- **외부 서비스 연동**: 다양한 API와 통신하여 데이터를 동기화합니다.

## 🛠️ 기술 스택 및 아키텍처

이 프로젝트는 다음과 같은 기술과 아키텍처 패턴을 사용하여 개발되었습니다.

### 기술 스택

- **프레임워크**: Flutter
- **언어**: Dart
- **상태 관리**: Provider (GetIt을 통한 의존성 주입 포함)
- **네트워킹**: Dio
- **로컬 저장소**: shared_preferences
- **알림**: firebase_messaging (FCM)
- **기타 주요 라이브러리**:
  - `freezed`: 불변(Immutable) 클래스 생성을 위함
  - `json_serializable`: JSON 직렬화/역직렬화를 위함
  - `cached_network_image`: 네트워크 이미지 캐싱 처리
  - `flutter_secure_storage`: 보안 데이터 저장을 위함

### 아키텍처

이 프로젝트는 클린 아키텍처(Clean Architecture)의 원칙을 기반으로 한 **계층형 아키텍처(Layered Architecture)**를 따릅니다. 각 계층은 명확한 책임을 가지며, 의존성 규칙을 통해 유연하고 확장 가능한 구조를 지향합니다.

- **Presentation Layer**: UI와 상태 관리를 담당합니다. (Widgets, ViewModels/Providers)
- **Domain Layer**: 애플리케이션의 핵심 비즈니스 로직을 포함합니다. (Entities, UseCases, Repositories Interfaces)
- **Data Layer**: 데이터 소스(원격 API, 로컬 DB)와의 통신을 담당합니다. (DataSources, Repositories Implementations, DTOs)

## 🚀 시작하기

### 사전 요구사항

- [Flutter SDK](https://flutter.dev/docs/get-started/install) (버전 3.10.0 이상 권장)
- [Android Studio](https://developer.android.com/studio) 또는 [Visual Studio Code](https://code.visualstudio.com/)

### 설치 및 실행

1.  **저장소 복제**:
    ```bash
    git clone https://github.com/your-repository/chungmo-app.git
    cd chungmo-app
    ```

2.  **의존성 설치**:
    ```bash
    flutter pub get
    ```

3.  **코드 생성 (Code Generation)**:
    `freezed`와 같은 코드 생성 라이브러리를 사용하므로, 아래 명령어를 실행해야 합니다.
    ```bash
    flutter pub run build_runner build --delete-conflicting-outputs
    ```

4.  **애플리케이션 실행**:
    ```bash
    flutter run
    ```

## 📁 프로젝트 구조

```
lib/
├── app/                  # 앱의 공통 설정 (라우팅, 테마 등)
├── core/                 # 핵심 유틸리티 및 공통 위젯
├── data/                 # 데이터 소스, 레포지토리 구현
│   ├── datasources/
│   ├── models/           # DTOs (Data Transfer Objects)
│   └── repositories/
├── domain/               # 비즈니스 로직
│   ├── entities/
│   ├── repositories/     # 레포지토리 인터페이스
│   └── usecases/
├── presentation/         # UI 및 상태 관리
│   ├── pages/            # 각 화면
│   └── viewmodels/       # Provider를 사용한 뷰모델
└── main.dart             # 앱 시작점
```

## 🎨 디자인 및 리소스

- **Figma**: [디자인 시안 링크](https://www.figma.com/file/your-figma-file-id)
- **API 문서**: [API 명세서 링크](https://www.notion.so/your-api-docs)
