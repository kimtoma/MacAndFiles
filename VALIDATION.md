# Android Bridge 검증 기록

검증일: 2026-10-05 (Asia/Seoul)

## 환경

- Mac: Apple Silicon / arm64
- OS가 보고한 버전: macOS 27.2, 빌드 26B5091g
- 빌드: Swift 6.4, macOS 27.0 SDK, 최소 배포 버전 27.0
- 기기: 사용자 확인 Galaxy Z Fold7 / MTP 모델 응답 `SM-F966N`
- USB: Samsung VID 04e8 / PID 6860, MTP 파일 전송
- 전송 라이브러리: libmtp 1.1.23 / libusb 1.0.30, 앱 번들 내 동적 라이브러리

## 실기기 검사

최종 전송 코드의 `--verify-transfer` 결과: **PASS**.

| 검사 | 결과 |
| --- | --- |
| USB 기기 검색 및 MTP 세션 열기 | PASS |
| 내장 저장소 및 루트 19개 항목 조회 | PASS |
| 한글 이름 파일 78 bytes: Mac → Android → Mac | PASS, 원본 내용 및 SHA-256 일치 |
| 빈 파일 0 bytes 왕복 | PASS, 원본 내용 및 SHA-256 일치 |
| 한글 하위 폴더와 바이너리 5,242,880 bytes 왕복 | PASS, 원본 내용 및 SHA-256 일치 |
| 루트에 단일 파일 직접 업로드 및 다운로드 | PASS, 원본 내용 일치 |
| 검증용 UUID 폴더·파일 정리 및 루트에서 제거 확인 | PASS |

원본 JSON: `dist/device-verification.json`. 실제 테스트는 사용자 파일을 열거나 변경하지 않고 별도로 만든 검증 파일만 사용합니다.

초기 검사에서 다른 MTP 앱의 USB 점유로 접근이 거절됐습니다. 해당 앱을 종료한 뒤 정상 연결됐습니다. 루트 폴더 생성에 필요한 `0xFFFFFFFF` 부모 핸들을 보존하도록 수정했고 루트 파일 전송에도 동일한 명시적 루트 핸들을 사용합니다.

## 자동 안전 검사

`scripts/test.sh`: **11 / 11 PASS**. Command Line Tools만 있는 환경에서도 실행할 수 있도록 Foundation과 독립 실행 테스트 러너를 사용합니다.

- 한글 이름과 바이너리 내용 보존
- 경로 탈출·잘못된 이름 거절
- 기존 Mac 파일 덮어쓰기 방지
- USB 실패 후 임시 수신 파일 정리
- 크기 불일치 파일의 최종 이름 노출 방지
- 폴더 재귀 다운로드
- 취소된 작업의 쓰기 방지
- 업로드 충돌을 형제 항목 전체에서 미리 확인
- 심볼릭 링크 업로드 거절
- 폴더 재귀 업로드
- 원격 중복 이름 다운로드 거절

출력: `dist/tests.log`.

## 실행 및 패키지

SwiftUI 네이티브 창이 실제 실행되고 폴드7의 내장 저장소와 파일 목록이 표시되는 것을 확인했습니다. 최종 UI는 고정 초록색을 제거하고 macOS 시스템 강조색과 Finder 기본 폴더 아이콘을 사용합니다.

최종 앱을 `/Applications/Android Bridge.app`에 설치했습니다. 설치된 실행 파일로 왕복 검증을 다시 수행해 PASS를 확인했고, GUI의 연결 버튼 → 저장소 목록 → 폴더 선택 및 Return으로 열기 → 루트로 돌아가기까지 확인했습니다. 설치 앱과 배포 앱의 실행 파일 SHA-256은 `598b44c359987b2a9a813b322921bd0c559dc8f634d7150138fe2f4718917855`로 동일합니다. 앱을 폴드7에 연결된 상태로 열어 두었습니다. 최종 화면은 `dist/Android-Bridge-preview.png`입니다.

`codesign --verify --deep --strict`로 앱 및 포함 라이브러리를 확인합니다. 실행 파일의 MTP 라이브러리 경로는 `@rpath/libmtp.9.dylib`, libmtp의 USB 라이브러리 경로는 `@rpath/libusb-1.0.0.dylib`이며 앱의 `Contents/Frameworks`를 참조합니다. 실행에 Homebrew 설치 경로를 사용하지 않습니다.

## 확인 범위

macOS 28, Intel Mac, 다른 Android 모델, 4GB 초과 단일 파일, 실제 케이블 분리 도중 복사, 대량 파일·장시간 전송은 검증하지 않았습니다. 취소·USB 실패에 대한 자동 테스트는 모의 전송 계층에서 수행했습니다. Apple Developer ID 서명과 공증은 수행하지 않은 로컬 ad-hoc 서명 빌드입니다.

## 아이콘 업데이트 (2026-10-05, 빌드 2)

아이콘을 실버 타일, 파란 폴더, 양방향 화살표, Android 기기 심볼로 교체했습니다. 원본 `Resources/Icon/AppIcon-master.png`는 1254×1254 RGBA PNG입니다. 16px부터 1024px까지 표준 ICNS 표현 10개를 생성했고, 32·64·128·256px를 밝은 배경과 어두운 배경에서 확인했습니다. 미리보기는 `Resources/Icon/Preview.png`입니다.

설치 앱과 배포 앱의 아이콘, ZIP 배포본을 갱신했습니다. 기존 설치 앱을 기반으로 아이콘과 번들 빌드 번호만 갱신하고 재서명했습니다. 실행 코드 `__TEXT,__text`의 SHA-256은 전후 모두 `fa3b36b1a9c31acc8c7aa0bc2230f477c5627beedf3d58358a75c4f7a97eab13`으로 동일합니다. 앱의 동작 및 전송 코드는 변경하지 않았고, 앞 절의 실행 파일 전체 해시는 아이콘 업데이트 전 빌드의 기록입니다.

새 `AppIcon.icns`의 SHA-256은 원본·설치 앱·배포 앱 모두 `115c52103b4ccb90da7e7b0f27f53f544c9060595c457ea2a6e053d07db96869`로 일치합니다. 설치 앱에 `codesign --verify --deep --strict`를 수행해 통과했고 Launch Services에 재등록했습니다. 원본 PNG 및 생성 프롬프트, 재생성 스크립트를 저장해 이미지 생성 서비스를 사용하지 않고 빌드할 수 있습니다.

## 최종 08 아이콘·오픈소스 배포 정리 (2026-10-05, 빌드 3)

사용자가 선택한 원래 08 Android Courier(파란 배경, 문서를 든 Android 캐릭터)를 최종 아이콘으로 적용했습니다. 08-B 폴더 버전과 08-C 화이트 버전은 적용하지 않았습니다. 표준 ICNS 표현 10개를 생성하고 작은 크기의 밝은/어두운 배경 미리보기를 확인했습니다.

프로젝트 소스·스크립트·문서용 MIT LICENSE, 별도 THIRD_PARTY_NOTICES.md, Android CC BY 3.0 전문, AGENT.md/AGENTS.md, CONTRIBUTING.md, 변경 기록과 공개 배포 안내를 추가했습니다. 바이너리에 포함하는 libmtp 1.1.23·libusb 1.0.30의 원본 소스 아카이브는 고정 SHA-256 검사에 통과했고, 앱 번들의 ThirdPartySources 폴더에 재빌드·교체 안내와 함께 넣었습니다. 라이선스와 네이티브 앱 정보용 Credits.rtf도 ZIP에 포함했습니다.

- release 빌드 완료; scripts/test.sh 11/11 PASS.
- ZIP을 /tmp의 별도 디렉터리에 풀고 `codesign --verify --deep --strict` 통과.
- 추출한 실행 파일의 --diagnose로 macOS 27.2와 Samsung MTP USB 장치 검색 확인.
- libmtp 및 libusb 연결 경로가 @rpath이며 Homebrew 런타임 경로를 사용하지 않는 것을 otool로 확인.
- 설치 앱과 배포 앱의 아이콘 SHA-256: `18dc449aa471b81196cfc189ab9a6331bd63e5635515a4aa356b9a04ccc6dcc2`.
- 이전 설치 빌드와 새 release 실행 코드의 `__TEXT,__text` SHA-256은 모두 `fa3b36b1a9c31acc8c7aa0bc2230f477c5627beedf3d58358a75c4f7a97eab13`; 전송 구현은 변경하지 않았습니다.
- /Applications/Android Bridge.app 설치·재등록 후 실제 실행. 네이티브 앱 정보 창에서 새 아이콘, Version 1.0.0 (3), MIT·Android 출처 크레딧 표시를 확인했습니다. 스크린샷은 dist/Android-Bridge-build3-about.png입니다.
- 갤럭시 폴드7(SM-F966N)에 다시 연결해 내장 저장소 루트 19개 항목 표시를 확인했습니다. 이번 아이콘·패키지 업데이트에서 왕복 파일 쓰기 검사는 반복하지 않았으며, 앞 절의 실기기 왕복 PASS 기록과 변경 없는 실행 코드를 구분합니다.

공개 GitHub 업로드, Developer ID 공증, Google 브랜드 승인 또는 공개 앱명 변경은 수행하지 않았습니다. 현재 이름은 개발명이며 docs/RELEASING.md의 공개 명칭·브랜딩 안내를 확인해야 합니다. macOS 28 및 다른 기기 검증 범위도 앞 절과 같습니다.

## 미니멀 UI 업데이트 (2026-10-05, 빌드 4)

로컬 Claude 제작 Android Transfer 앱의 코드와 실행 화면을 읽어 기본 split-view 사이드바, 얇은 경로 표시줄, 도구 막대 구성을 참고했습니다. 해당 앱 소스는 복사하지 않고 SwiftUI 기본 컨트롤로 새로 구성했습니다. 큰 중복 제목·브랜딩·기기 카드·기술 설명을 제거하고, 보조 기능은 ‘더 보기’ 메뉴로 옮겼습니다. Finder 파일 형식 아이콘과 ⌘↑·⌘⇧N 단축키를 추가했습니다. USB 전송 계층과 AppModel 전송 동작은 변경하지 않았습니다.

- Release 빌드 완료, transfer-safety 11/11 PASS (`dist/tests-build4.log`).
- 배포 ZIP을 별도 임시 경로에 추출해 strict codesign 검사를 통과한 뒤 설치 앱을 업데이트했습니다. 설치 앱 strict 검사도 PASS이며 번들 버전은 1.0.0 (4)입니다.
- 추출 실행 파일의 `--diagnose`로 macOS 27.2와 Samsung MTP 장치 검색을 확인했습니다. 포함 libmtp 연결은 @rpath이며 런타임 Homebrew 경로를 사용하지 않습니다.
- 설치 앱 GUI에서 갤럭시 폴드7의 저장소 루트 19개 항목, 폴더 더블 클릭, ⌘↑ 상위 이동, 파일 검색, 파일 선택에 따른 Mac 저장 버튼 활성화를 확인했습니다. 저장 대화상자와 ⌘⇧N 새 폴더 대화상자는 열고 취소했으며 이번 UI 검증에서는 기기 파일을 쓰지 않았습니다.
- 기본 사이드바 가리기/보이기와 보조 메뉴(연결 해제·도움말·진단)를 확인했습니다. 실제 설치 화면은 `dist/Android-Bridge-build4-preview.png`에만 보관하며 공개 소스에는 포함하지 않습니다.
- 같은 ContentView와 합성 데이터를 사용한 별도 미리보기 앱에서 밝은/어두운 파일 탐색·연결 대기 화면을 확인했습니다. 이 모양 검증과 실기기 검증은 별개이며 미리보기는 기기 전송을 검증하지 않습니다. 임시 미리보기 소스와 화면은 dist/에 보관하고 공개 소스에는 포함하지 않습니다.
- 선택한 원래 08 아이콘 SHA-256은 이전과 같은 `18dc449aa471b81196cfc189ab9a6331bd63e5635515a4aa356b9a04ccc6dcc2`이며 원본/설치 앱이 일치합니다. MIT 코드 라이선스와 별도 아트워크·라이브러리 출처는 유지합니다.

macOS 28·Intel·다른 기기 지원, 이번 빌드의 새 왕복 전송 검사 및 Developer ID 공증은 수행하지 않았습니다. 기존 왕복 전송 검증 범위는 앞 절을 참조하세요.

## Liquid Glass·검색창 수정 (2026-10-06, 빌드 5)

고정 너비 일반 TextField와 별도 검색 배경을 SwiftUI `.searchable`의 기본 macOS 도구 막대 검색으로 교체했습니다. ⌘F 포커스, 검색 결과 수 표시와 필터로 숨겨진 선택 해제를 추가했습니다. 도구 막대 그룹, 사이드바, 경로 표시줄 및 연결 버튼에 macOS 기본 Liquid Glass를 적용했습니다. 파일 목록은 기본 배경과 시스템 강조색을 유지합니다. 전송 계층은 변경하지 않았습니다.

- Release 빌드 완료 (`dist/build5.log`), 전송 안전 검사 **11/11 PASS** (`dist/tests-build5.log`). 이전 프로세스 생성 오류는 이번 재개 세션에서 해소됐습니다.
- 새 ZIP을 동기화 폴더 밖의 임시 경로에 추출해 strict codesign 검사를 통과한 뒤 `/Applications/Android Bridge.app`에 설치했습니다. 설치 앱의 strict 검사도 PASS이며 번들 버전은 **1.0.0 (5)**입니다.
- 설치 앱과 dist 앱 실행 파일 SHA-256은 `c633f1fe548925140ed933f8228c0ff3a211a1104f5f173df75986c674e128b7`로 일치합니다.
- 설치 GUI에서 갤럭시 폴드7(SM-F966N) 저장소 루트 19개 항목을 확인했습니다. Google Android File Transfer와 그 백그라운드 Agent의 USB 점유를 해제한 뒤 정상 연결됐습니다.
- ⌘F로 네이티브 검색창 포커스, Android 검색의 1개 결과, 한글 검색어 입력과 0개 결과 표시, 기본 지우기 버튼 및 Escape로 전체 목록 복귀를 확인했습니다. 한글 입력은 자동화 텍스트 입력으로 확인했으며 IME 조합 과정 자체를 검증한 것은 아닙니다.
- 파일을 선택한 상태에서 다른 이름으로 검색했을 때 선택이 해제되고 ‘Mac으로 저장’ 버튼이 비활성화되는 것을 확인했습니다.
- 검색 결과 폴더 더블 클릭 및 ⌘↑ 상위 이동 후 검색어 초기화, 연결 해제 때 검색창 제거, 재연결 때 빈 검색창과 루트 목록 복원을 확인했습니다.
- 창을 약 1030×646 pt로 줄여 검색창과 도구 막대가 잘리지 않는 것을 확인하고 이전 창 크기로 복원했습니다. 실제 검색 화면은 `dist/Android-Bridge-build5-search.png`, 최종 설치 화면은 `dist/Android-Bridge-build5-preview.png`입니다.
- 같은 ContentView와 합성 데이터를 사용하는 별도 임시 미리보기 앱으로 밝은/어두운 파일 탐색 및 연결 대기 화면을 확인했습니다. 화면 증거는 `dist/ui-previews/build5-*.png`입니다. 이 검사는 실기기 전송 검증과 구분하며 임시 앱은 검증 후 종료했습니다. 개인 기기 화면과 미리보기 도구는 공개 소스 아카이브에 포함하지 않습니다.
- 원래 08 아이콘은 원본·설치 앱 모두 SHA-256 `18dc449aa471b81196cfc189ab9a6331bd63e5635515a4aa356b9a04ccc6dcc2`로 유지됩니다. MIT 코드 라이선스, Android 아트워크 및 LGPL 라이브러리 출처도 유지합니다.
- 배포 ZIP과 최신 소스 아카이브, SHA256SUMS.txt를 갱신했습니다. 소스 아카이브에서 빌드 5 메타데이터와 수정 소스·문서가 일치하고 dist/.build/.git가 제외되는 것을 확인했습니다.

이번 UI 검증은 기기 목록 조회와 탐색만 수행했으며 새 왕복 파일 쓰기 검사는 반복하지 않았습니다. 기존 실기기 왕복 PASS 기록은 앞 절을 참조하세요. 검증 환경은 macOS 27.2 arm64이며 macOS 28·Intel·다른 기기·Developer ID 공증·GitHub 공개 업로드는 검증하거나 수행하지 않았습니다.

## macOS 네이티브 다국어·영어 기본 README (2026-10-06, 빌드 6)

앱 고정 문구를 Foundation 번들 지역화로 옮겼습니다. 영어 개발 언어와 한국어·중국어 간체/번체·스페인어·브라질 포르투갈어·일본어·독일어·프랑스어·러시아어·힌디어·인도네시아어·아랍어의 13개 `.lproj`를 포함합니다. 각 언어에는 일반 문구 105개와 복수형 메시지 9개가 있습니다. 메뉴·버튼·검색·파일 패널·도움말·작업 상태·앱 오류가 번역 대상입니다. 파일명과 기기 응답은 번역하지 않으며, 기존 Unicode 검증 파일 내용도 유지했습니다. 원래 08 아이콘과 전송 동작은 유지합니다.

- Release 빌드 완료 (`dist/build6.log`), 전송 안전 검사 **11/11 PASS** (`dist/tests-build6.log`). 문자열 지역화 외 전송 안전 규칙은 변경하지 않았습니다.
- `scripts/test-localization.sh` **17개 실행 시나리오 PASS** (`dist/localization-tests-build6.log`): 13개 언어 선택, 미지원 언어의 영어 fallback, 중국어 zh-CN/zh-TW 및 스페인어 es-MX의 native 매칭을 검사했습니다. 각 시나리오에서 105개 문자열의 placeholder 타입과 Unicode/% 문자가 든 데이터 보존, 9개 count 메시지에 0/1/2/5/11/21/101을 대입한 결과, 언어별 layout direction을 검사합니다. 영어 단복수, 러시아어 one/few/many 및 아랍어 zero/two에 별도 기대값을 확인했습니다.
- 영어·스페인어·독일어·중국어 간체·아랍어 합성 파일 탐색 화면을 별도 임시 앱에서 실행했습니다. 920×620 pt에서 검색·도구 막대·표·상태 표시를 확인했고, 스페인어 NSOpenPanel 제목/동작 버튼, 독일어 새 폴더 sheet, 중국어 0개 검색 결과, 아랍어 오류 안내의 Unicode 파일명과 RTL 배치를 확인했습니다. 대화상자는 취소했으며 실제 전송은 하지 않았습니다.
- 아랍어 미리보기는 테스트 프로세스에서만 AppleLanguages 및 native RTL 테스트 옵션(AppleTextDirection/NSForceRightToLeftWritingDirection)을 사용했습니다. 전역/사용자 언어 설정은 변경하지 않았습니다. 앱 코드에는 언어 설정 override가 없으며, 선택된 번들 언어의 Foundation characterDirection을 SwiftUI에 적용합니다. RTL 사이드바·열·경로·footer와 native toolbar를 확인했습니다. 이 검사는 시스템 설정 UI에서 앱별 언어를 직접 변경하는 검증과 구분합니다.
- 영어/아랍어 등 미리보기 증거는 `dist/ui-previews/build6-*.png`입니다. 임시 앱은 종료했고 소스/스크린샷은 공개 소스 아카이브에서 제외합니다. 새 번역은 자동 구조/실행 점검과 위 UI 검사를 거쳤으나 모든 언어의 원어민 감수는 수행하지 않았습니다.
- 배포 ZIP을 동기화 경로 밖으로 추출하여 strict codesign PASS, 13개 언어 파일이 소스와 동일함을 확인하고 `/Applications/Android Bridge.app`에 설치·재등록했습니다. 설치 앱 strict 검사도 PASS이며 버전은 **1.0.0 (6)**입니다. 실행 파일 SHA-256은 `0af109f867b510c88bb9ae0c041cfb072009550eef7aa176586a3301066e319f`입니다.
- 설치된 앱이 현재 Mac의 한국어 설정에 맞춰 시스템 메뉴, 앱 문구와 AppKit 연결 도움말을 표시하는 것을 확인했습니다. 설치 화면은 `dist/Android-Bridge-build6-preview.png`입니다. 이 시점에는 USB 검색에 기기가 없어서 새 실기기 연결/왕복 검사는 반복하지 않았습니다. 기존 폴드7 검증 범위는 앞 절과 구분합니다.
- README.md를 영어 원문으로 바꾸고 docs/readme/ 아래 12개 번역 문서를 연결했습니다. 상대 링크, 지역화 파일 key 집합과 필수 plural other 형식을 확인했습니다. docs/LOCALIZATION.md와 AGENT.md에 번역 수정·테스트 방법을 추가했습니다.
- ZIP, 최신 소스 아카이브와 SHA256SUMS.txt를 갱신했습니다. 소스 아카이브의 지역화 파일·문서·버전 6이 작업 소스와 일치하고 dist/.build/.git를 제외하는 것을 확인했습니다.

새 범용 파일 작업 CLI나 MCP 서버는 구현하지 않았습니다. 기존 진단 명령은 유지합니다. macOS 28·Intel·다른 기기, Developer ID 공증과 GitHub 공개 업로드는 이번 변경의 검증/실행 범위에 포함하지 않습니다.

## Android File Transfer·에이전트 CLI (2026-10-06, 빌드 7)

공개 표시 이름, 창/메뉴, 앱 번들 실행 파일, 진단 메타데이터와 배포 파일명을 Android File Transfer로 변경했습니다. 내부 Swift 타깃 및 번들 식별자는 기존 설정의 연속성을 위해 유지합니다. 선택된 원래 08 아이콘, Liquid Glass UI, 13개 언어는 유지했습니다.

- `aft` 네이티브 CLI: devices, storages, ls, upload, download, mkdir, help, version. stdout의 단일 JSON envelope(schemaVersion 1), 안정적인 오류 코드와 종료 상태, 선택적 stderr 파일 진행률을 제공합니다. 파일명 덮어쓰기·삭제 명령은 없습니다.
- GUI/CLI/기기 검증이 같은 TransferEngine과 기기별 advisory lock을 공유합니다. SIGINT/SIGTERM은 협조적 취소를 요청하며 완료 항목과 부분 파일 가능성을 보고합니다. 업로드 파일 영수증은 parentID, 다운로드와 생성된 폴더는 objectID로 구분합니다.
- 전송 안전 **11/11 PASS** (`dist/tests-build7.log`), CLI **14/14 PASS** (`dist/cli-tests-build7.log`), 지역화 **17개 시나리오 PASS** (`dist/localization-tests-build7.log`). CLI 검사는 잘못된 인자/ID, 경로 traversal, Unicode/중복 이름, 저장소 선택, 세션 해제, 업로드/다운로드 영수증, 부분 폴더 실패, 취소와 잠금 경합을 모의 백엔드 및 실제 파일/잠금으로 확인했습니다. 물리적 USB 전송 검증과 구분합니다.
- 설치된 `~/.local/bin/aft`에서 인자 없는 help, help/version/devices, 잘못된 명령/옵션/ID/경로, 없는 기기의 **10개 프로세스 시나리오**를 실행하여 stdout JSON 및 종료 코드를 검사했습니다. CLI 설치 반복 실행 및 기존 다른 aft 파일 보존도 PASS (`dist/cli-smoke-build7.log`).
- arm64 release 빌드 및 앱/네이티브 aft/LGPL 라이브러리 strict codesign PASS. 번들 내부 shell 실행 스크립트의 서명 실패를 네이티브 C launcher로 해결하고 최종 ZIP을 다시 빌드했습니다. ZIP을 동기화 폴더 밖으로 추출해 strict codesign 및 standalone CLI 실행을 확인했습니다.
- `/Applications/Android File Transfer.app`에 설치했습니다. 기존 Google 앱은 `/Applications/Android File Transfer (Google Legacy).app`으로 보관했고, 기존 자체 빌드 6 앱은 ignored dist/backups에 보관했습니다. CLI는 PATH에 포함된 `~/.local/bin/aft`에서 바로 실행됩니다.
- 최종 설치/추출 실행 파일 SHA-256 동일: `c2a2aa5e16a964fe0523721889888f4cacbb6319fb221c334818094f4cbfa48b`. 포함된 13개 번역 리소스는 소스와 바이트 단위로 일치하며, 아이콘 SHA-256은 기존 `18dc449aa471b81196cfc189ab9a6331bd63e5635515a4aa356b9a04ccc6dcc2`입니다.
- 배포 앱 GUI의 한국어 연결 대기 화면, Android File Transfer 창/메뉴 이름 및 About의 1.0.0 (7)/원래 아이콘/라이선스 크레딧을 확인했습니다 (`dist/Android-File-Transfer-build7-about.png`). 설치 앱 프로세스도 확인했습니다. UI 도구가 같은 경로의 예전 Google 번들 정보를 캐시하여 배포 앱 경로에서 화면을 검증했으며, 설치본과 배포본 실행 파일이 동일함을 별도 확인했습니다.
- 영어 기본 README 및 12개 번역에 새 이름과 CLI 안내를 반영했습니다. docs/CLI.md는 명령/JSON/오류/취소/부분 실패 계약을 설명합니다. AGENT.md에 구조, CLI 수정/검증 규칙을 추가했습니다. 앱 ZIP, 일치하는 소스 아카이브와 SHA256SUMS.txt를 갱신했습니다.

이번 세션의 실제 `aft devices`는 빈 목록을 반환했습니다. 폴드7 연결 요청을 전달했으나 기기가 검색되지 않아 **빌드 7 CLI의 물리적 업로드·다운로드·GUI/CLI USB 경합은 미검증**입니다. 이전 폴드7 왕복 기록과 모의 CLI 테스트를 새 실기기 성공으로 간주하지 않습니다. macOS 27.2 arm64에서 검증했으며 macOS 28·Intel·다른 기기, Developer ID 공증 및 GitHub 업로드는 이번 실행 범위에 포함하지 않습니다.

## MacAndFiles 브랜드·maf CLI (2026-10-06, 빌드 8)

사용자가 선택한 MacAndFiles를 앱 이름, 실행 파일, Swift package/target 및 Sources/MacAndFiles에 반영했습니다. CLI의 기본 명령은 maf이며 aft는 호환 별칭으로 유지합니다. JSON schemaVersion 1, 명령/오류/종료 코드 계약은 유지하며 app 메타데이터만 새 브랜드로 바뀝니다. 기존 macOS 언어/창 설정 및 이전 버전과의 USB 잠금 연속성을 위해 local.androidbridge.mac 식별자와 잠금 디렉터리는 유지합니다. 역사적 UUID 검증 fixture 이름과 검증 바이트도 유지합니다.

- 전송 안전 **11/11 PASS**, CLI **14/14 PASS**, 지역화 **17개 시나리오 PASS**. 로그는 ignored dist의 tests-build8.log, cli-tests-build8.log, localization-tests-build8.log에 있습니다.
- arm64 release 빌드 완료. 배포 ZIP을 동기화 폴더 밖에 추출하여 strict codesign PASS 및 번들 CLI 독립 실행을 확인했습니다. 설치본 strict codesign PASS. 설치/추출 실행 파일 SHA-256 동일: `7b1b391781a85e06d5c84376da70811c1a4735884326e7914bd050e493c2405d`; maf launcher: `153d557018d29ea7732840705b513f3364da5bc965b1633a63114350d071bf8c`.
- 설치된 maf의 인자 없는 help, help/version/devices, 잘못된 명령/옵션/ID/경로 및 없는 기기 등 **10개 프로세스 시나리오 PASS**. aft 별칭, 설치 반복 실행, maf/aft 각각의 기존 다른 도구 보존 및 두 명령 사전 검사에 따른 부분 설치 방지도 PASS (dist/cli-smoke-build8.log).
- MacAndFiles.app을 Applications에 설치했고 이전 자체 빌드 7은 ignored dist/backups에 보관했습니다. 기존 Google 앱은 별도 이름으로 계속 보존합니다. 네이티브 UI 도구로 실제 설치본의 MacAndFiles 창/메뉴 이름, About의 **1.0.0 (8)** 및 라이선스 크레딧/원래 08 아이콘을 확인했습니다. 화면은 ignored dist/MacAndFiles-build8-about.png에 보관합니다.
- 13개 지역화 리소스가 추출본과 소스 사이에 바이트 단위로 일치합니다. 아이콘 SHA-256은 기존 `18dc449aa471b81196cfc189ab9a6331bd63e5635515a4aa356b9a04ccc6dcc2`로 동일합니다. MIT 프로젝트 코드, Android 아트워크 CC BY 및 라이브러리 LGPL 고지/소스 제공을 유지합니다.
- 영어 기본 README와 12개 번역, AGENT.md, CLI/지역화/배포 가이드 및 배포 파일명을 새 브랜드와 maf에 맞췄습니다. 로컬 Git description은 MacAndFiles이며 사용자가 로컬 변경만 선택하여 GitHub 원격 생성/변경/업로드는 수행하지 않았습니다.
- 실제 maf devices는 삼성 MTP 기기 1개를 검색했습니다. 이어진 읽기 전용 storages는 “저장소 정보를 읽을 수 없습니다.”(transfer_failed, exit 1)로 실패했습니다. 이번 빌드에서 USB 저장소 탐색·업로드·다운로드 성공을 주장하지 않으며, 기존 폴드7 왕복 기록 및 모의 CLI 검사와 구분합니다. 기기 파일을 쓰지 않았습니다.

검증 환경은 macOS 27.2 arm64입니다. 이번 변경은 브랜드/패키지/설치 경로 변경이며 전송 로직은 유지합니다. macOS 28·Intel·다른 기기 및 Developer ID 공증은 검증하지 않았습니다.

## Build 9 — 2026-10-06

arm64 application, launcher and rebuilt libmtp/libusb target macOS 14. Actual runtime/hardware verification uses macOS 27.2 and SM-F966N (Galaxy Z Fold7). macOS 14–26 and Intel are not runtime-verified.

- CLI Unicode, empty file and nested 5 MiB round trip: PASS; contents and SHA-256 match.
- CLI 4,296,015,872-byte (4 GiB + 1 MiB) round trip: PASS; SHA-256 matches. Upload 140.23 s; download 131.13 s in this single run.
- CLI 2,000 small files: PASS; all individual hashes match. Upload 8.85 s; download 4.74 s.
- CLI upload cancellation: PASS, exit 130; Android partials may remain.
- Initial download cancellation: FAILED due to blocking session close. After avoiding a second CloseSession on CLI cancellation, retry returned exit 130 with zero completed files and no final/temporary Mac file. This took 61.37 s; device protocol recovery/reconnection remains a limitation.
- Cable-disconnection test and fixture cleanup: pending until observed and recorded.
- Safety tests: 11; CLI contract tests: 14; aggregate progress tests: 5; localization tests: 17; installer tests: 4. See scripts/test*.
- Website: all 13 complete language documents pass static asset/link/RTL checks. English desktop, Korean mobile and Arabic language switching were inspected in the browser. Public deployment is a separate acceptance check.
- Default package: ad-hoc signed. No Developer ID Application certificate is available in the tested environment, so notarization was not performed.

Raw device evidence and private diagnostics remain under ignored dist/hardware. Public screenshots contain synthetic sample files. These timings are observations from one USB session, not general performance claims.

Extracted build 9 ZIP passed strict signature verification, native CLI version, 13 bundled locales, unchanged original 08 icon hash and all four Mach-O minimum versions (14.0). Dependency validation found and fixed path parsing in a workspace containing spaces; all shipped library paths now use @rpath or system paths. The verified ZIP was installed locally, preserving build 8 in ignored backups.
