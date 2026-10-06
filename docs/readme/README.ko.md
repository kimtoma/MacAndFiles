# MacAndFiles

<img src="../../Resources/Icon/AppIcon-master.png" width="128" alt="MacAndFiles app icon">

[English](../../README.md) · [한국어](README.ko.md) · [简体中文](README.zh-Hans.md) · [繁體中文](README.zh-Hant.md) · [Español](README.es.md) · [Português](README.pt-BR.md) · [日本語](README.ja.md) · [Deutsch](README.de.md) · [Français](README.fr.md) · [Русский](README.ru.md) · [हिन्दी](README.hi.md) · [Bahasa Indonesia](README.id.md) · [العربية](README.ar.md)

Apple Silicon Mac용 SwiftUI 네이티브 Android USB 파일 전송 앱입니다. Google Android File Transfer를 대체하는 독립 앱이며, 기존 앱을 덮어쓰지 않습니다.

프로젝트 소스·스크립트·문서는 **MIT** 라이선스입니다. Android 마스코트 아트워크는 **CC BY 3.0**, 포함된 libmtp·libusb는 **LGPL-2.1-or-later** 조건을 유지합니다. [LICENSE](../../LICENSE)와 [별도 라이선스·출처](../../THIRD_PARTY_NOTICES.md)를 함께 확인하세요. Android는 Google LLC의 상표이며 이 앱은 Google과 제휴한 공식 앱이 아닙니다. 공개 배포 시 [배포 안내](../../docs/RELEASING.md)의 라이선스와 서명 요건을 유지하세요.

## 언어

앱은 macOS 시스템 언어와 시스템 설정 → 일반 → 언어 및 지역의 앱별 언어를 따릅니다. 언어를 변경하면 앱을 다시 실행하세요. 13개 언어를 지원하며 지원하지 않는 언어는 영어로 표시합니다. 날짜·크기·숫자는 지역 설정을 따르고 파일명과 기기가 제공한 이름은 그대로 유지합니다.

## 실행

`dist/MacAndFiles.app`을 실행하세요. 배포 파일에는 libmtp와 libusb가 포함되어 있어 실행할 때 Homebrew나 Android Studio가 필요 없습니다. 이 빌드의 최소 OS는 **macOS 14.0**이며 arm64 전용입니다. 실제 검증 OS·기기는 [검증 기록](../../VALIDATION.md)을 확인하세요. macOS 28은 해당 OS에서 실행해 보기 전까지 검증된 것으로 간주하지 않습니다.

1. Android를 데이터 전송 USB 케이블로 연결합니다.
2. 잠금을 해제하고 USB 알림에서 **파일 전송 / Android Auto**를 선택합니다.
3. 기존 Android File Transfer와 다른 MTP 앱을 종료합니다. Google의 백그라운드 `Android File Transfer Agent`도 USB를 점유할 수 있습니다.
4. **기기 검색** → 기기 선택 → **연결**을 누릅니다.
5. 폴더를 더블 클릭해 탐색합니다. 파일·폴더를 선택한 뒤 **Mac으로 저장**(⌘D)을 누르거나, **Android로 보내기**(⌘U)로 Mac 파일·폴더를 선택합니다. Finder의 파일·폴더를 파일 목록에 놓아 보낼 수도 있습니다.

USB 디버깅이나 ADB 설정은 필요 없습니다. 기본 사이드바는 너비 조절과 접기가 가능하며, 상단 도구 막대에 전송·새 폴더·검색이 모여 있습니다. 경로 표시줄로 상위 경로를 열거나 ⌘↑로 상위 폴더로 이동합니다. 새 폴더는 ⌘⇧N으로 만듭니다. 연결 도움말·연결 해제·진단 기록 저장은 ‘더 보기’ 메뉴에서 사용할 수 있습니다. 진단 기록에는 작업한 파일 이름과 오류가 포함될 수 있습니다.

도구 막대·사이드바·경로 표시줄에는 macOS 기본 Liquid Glass를 사용하며, 파일 목록은 읽기 쉬운 기본 배경을 유지합니다. **⌘F**로 현재 폴더 검색에 포커스를 옮깁니다. 검색은 현재 폴더의 이름을 필터링하며 하위 폴더 전체를 검색하지 않습니다. 검색창의 지우기 버튼이나 Escape로 검색을 해제하고, 폴더를 이동하면 검색어가 초기화됩니다. 검색으로 가려진 항목은 선택에서 제외됩니다.

## 전송 동작

- 같은 이름의 항목이 있으면 덮어쓰지 않고 해당 작업을 중단합니다.
- Mac으로 받을 때 임시 파일에 기록하고 크기를 확인한 뒤 최종 이름으로 옮깁니다. 실패한 임시 파일은 정리합니다.
- Android로 보낸 뒤 기기가 보고한 파일 크기를 확인합니다. 일반 전송은 크기를 확인하며, 기기 검증 명령은 왕복 파일 내용과 SHA-256까지 비교합니다.
- 취소·실패 시 이미 완료된 파일과 생성한 폴더는 유지됩니다. Android에는 부분 파일이 남을 수 있으므로 목록을 새로고침하고 확인하세요.
- 폴더는 재귀적으로 복사합니다. 심볼릭 링크와 특수 파일은 전송하지 않으며, 최대 폴더 깊이는 128입니다. 폴더 전송 중 후속 파일에 문제가 발생하면 먼저 복사된 내용은 유지됩니다.
- 전체 폴더와 작업의 파일 수·완료 수·바이트를 합산해 진행률을 표시합니다.
- Android가 MTP로 노출하는 파일만 접근합니다. 앱 전용 데이터와 일부 보호 폴더는 Android 정책에 따라 보이지 않을 수 있습니다.
- 파일 삭제·이름 변경·Finder 볼륨 마운트 기능은 이 버전에 포함되어 있지 않습니다.

앱은 로컬 개발용 ad-hoc 서명입니다. Apple Developer ID 서명과 공증은 수행하지 않았습니다. 이 Mac의 로컬 실행은 검증하며, 다운로드로 전달받는 다른 Mac의 Gatekeeper 통과를 보장하지 않습니다.

## 빌드와 검증

필요 조건: Apple Silicon, macOS 26+ SDK를 포함한 Command Line Tools, Swift 6.2+, pkg-config. 빌드 스크립트가 libmtp 1.1.23와 libusb 1.0.30을 검증된 소스에서 macOS 14 대상으로 컴파일합니다.

```sh
brew install pkg-config
scripts/build-app.sh
scripts/test.sh
scripts/package-source.sh
```

`scripts/build-app.sh`은 release 실행 파일과 동적 라이브러리를 `.app`에 포함하고 로딩 경로를 `@rpath`로 바꾼 뒤 ad-hoc 서명합니다. `dist/MacAndFiles-macOS-arm64.zip`도 생성합니다.

릴리스 빌드는 SHA-256이 고정된 해당 버전 소스를 내려받고 라이브러리를 컴파일한 뒤 대응 소스와 함께 앱에 포함합니다. 버전을 변경할 때는 소스 URL·해시·표기·빌드 안내도 함께 변경해야 합니다. `scripts/package-source.sh`는 빌드 산출물, Git 메타데이터와 개인 진단 기록을 제외한 `dist/MacAndFiles-source.tar.gz`를 만듭니다.

아이콘 원본은 [Resources/Icon/AppIcon-master.png](../../Resources/Icon/AppIcon-master.png)이며, 디자인과 생성 프롬프트는 [아이콘 문서](../../Resources/Icon/README.md)에 있습니다. `scripts/build-icon.sh`는 원본 PNG로부터 16px–1024px의 아이콘 세트와 `Resources/AppIcon.icns`를 재생성합니다. macOS AppKit과 `iconutil`만 사용하며, 빌드에 이미지 생성 서비스나 API 키는 필요 없습니다.

실기기 진단 명령:

```sh
"dist/MacAndFiles.app/Contents/MacOS/MacAndFiles" --diagnose
"dist/MacAndFiles.app/Contents/MacOS/MacAndFiles" --probe
"dist/MacAndFiles.app/Contents/MacOS/MacAndFiles" --verify-transfer --report dist/device-verification.json
```

`--diagnose`는 USB 장치를 검색합니다. `--probe`는 한 기기를 열어 저장소와 루트 목록 조회를 확인합니다. `--verify-transfer`는 연결된 기기가 정확히 하나일 때 UUID가 포함된 **AndroidBridge-Test-…** 폴더를 만들어 한글 파일, 0바이트 파일, 하위 폴더의 5 MiB 바이너리를 왕복 복사합니다. 내용과 SHA-256을 확인한 뒤 그 테스트 폴더만 정리합니다. 루트 단일 파일도 별도로 왕복 비교하고 정리합니다. 실패하면 남을 수 있는 테스트 항목을 오류에 표시합니다. GUI 앱의 USB 연결을 해제하고 실행하세요.

## 오픈소스 구성 요소

- [libmtp](https://github.com/libmtp/libmtp) 1.1.23 — LGPL 2.1. USB MTP 세션 및 파일 전송.
- [libusb](https://github.com/libusb/libusb) 1.0.30 — LGPL 2.1. macOS USB 접근.

두 라이브러리는 교체 가능한 동적 라이브러리로 배포합니다. 라이선스 전문은 `Resources/Licenses`와 앱의 `Contents/Resources/Licenses`에 있습니다. libmtp 헤더에는 원저작권 표기가 포함되어 있습니다. 버전별 소스는 각 프로젝트의 릴리스 태그에서 확인할 수 있습니다.

배포 앱의 `Contents/Resources/ThirdPartySources`에 두 라이브러리의 소스 아카이브와 [재빌드·교체 안내](../../docs/THIRD_PARTY_BUILD.md)를 포함합니다. macOS 기본 앱 정보 창에서도 프로젝트·마스코트·라이브러리 크레딧을 확인할 수 있습니다.

## 수정 및 기여

[AGENT.md](../../AGENT.md)에 파일별 역할, 수정 지점, 전송 안전 규칙, 빌드·검증 방법을 정리했습니다. 코딩 도구가 자동으로 찾는 [AGENTS.md](../../AGENTS.md)도 같은 안내를 가리킵니다. 기여자는 [CONTRIBUTING.md](../../CONTRIBUTING.md), 공개 릴리스 담당자는 [docs/RELEASING.md](../../docs/RELEASING.md)를 확인하세요. GitHub 저장소나 릴리스 업로드는 아직 수행하지 않았습니다.

## 터미널과 에이전트

앱 설치 후 `scripts/install-cli.sh`로 `maf`를 설치하세요. `maf devices`로 기기 ID, `maf storages --device "ID"`로 저장소 ID를 확인합니다. 파일 목록·업로드·다운로드·폴더 생성은 `maf help`와 [CLI 안내](../CLI.md)를 참조하세요. 결과는 JSON, 실패는 오류 코드와 종료 상태로 반환합니다. CLI를 사용하기 전에 GUI의 기기 연결을 해제하세요.

```sh
maf help
maf devices
maf storages --device "DEVICE_ID"
maf ls --device "DEVICE_ID" --storage 65537 --path /Download
```

## 1.0.0 (9)

macOS 14 이상을 대상으로 빌드했습니다. macOS 27.2에서 검증했으며 이전 버전의 실기기 검증은 남아 있습니다. Liquid Glass는 macOS 26 이상에서 적용됩니다.

전체·완료 파일 수, 전체 진행률, 평균 속도와 예상 남은 시간을 확인하세요. 전송이 중단되어도 완료된 파일은 보존됩니다.

앱의 더 보기 → 터미널 및 에이전트에서 maf를 설치하세요. 필요한 경우 ~/.local/bin을 PATH에 추가하세요. CLI 파일 작업 전에는 GUI 연결을 해제하세요.

maf CLI는 같은 전송 엔진을 사용합니다. JSON 결과, 안정적인 오류 코드와 USB 점유 상태로 스크립트와 에이전트의 작업을 돕습니다.

[MacAndFiles](https://kimtoma.github.io/MacAndFiles/ko/) · [CLI](../CLI.md) · [Release](../RELEASING.md)
