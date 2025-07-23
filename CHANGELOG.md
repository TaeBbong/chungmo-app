# 변경 이력 (Changelog)

이 파일은 프로젝트의 모든 주요 변경 사항을 기록합니다.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] - 2023-05-25

### ✨ Added

- 회원가입 기능 구현
- 프로필 이미지 등록 기능 추가
- Dio 라이브러리를 이용한 네트워크 모듈 리팩토링

### 🐛 Fixed

- 로그인 시 간헐적으로 발생하던 API 오류 수정

## [1.0.0] - 2023-05-10

### 🎉 Initial Release

- 프로젝트 초기 설정
- 로그인 기능 구현
- 메인 화면 UI 구성

=====================

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
