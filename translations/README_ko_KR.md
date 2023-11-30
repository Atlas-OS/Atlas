⚠️Note: This is a translated version of the original README.md, information here may not be accurate and can be outdated.
<h1 align="center">
  <a href="http://atlasos.net"><img src="https://github.com/Atlas-OS/branding/blob/main/github-banner.png" alt="Atlas" width="900" style="border-radius: 30px"></a>
</h1>
  <p align="center">
    <a href="https://github.com/Atlas-OS/Atlas/blob/main/LICENSE">
      <img alt="License" src="https://img.shields.io/github/license/atlas-os/atlas?style=for-the-badge&logo=github&color=1A91FF"/>
    </a>
    <a href="https://github.com/Atlas-OS/Atlas/graphs/contributors">
      <img alt="Contributors" src="https://img.shields.io/github/contributors/atlas-os/atlas?style=for-the-badge&color=1A91FF" />
    </a>
    <a href="https://github.com/Atlas-OS/Atlas/releases/latest">
      <img alt="Release" src="https://img.shields.io/github/release/atlas-os/atlas?style=for-the-badge&color=1A91FF" />
    </a>
    <a href="https://github.com/Atlas-OS/Atlas/releases">
      <img alt="Release Downloads" src="https://img.shields.io/github/downloads/Atlas-OS/Atlas/total?style=for-the-badge&logo=github&color=1A91FF" />
    </a>
  </p>
<h4 align="center">윈도우의 성능을 극대화 시키고 개인 정보를 보호하며, 대기 시간을 최적화 시키도록 설계 되었습니다.</h4>

<p align="center">
  <a href="https://atlasos.net">웹사이트</a>
  •
  <a href="https://docs.atlasos.net">문서</a>
  •
  <a href="https://discord.atlasos.net" target="_blank">디스코드</a>
  •
  <a href="https://forum.atlasos.net">포럼</a>
</p>

## 🤔 **Atlas란?**

Atlas는 윈도우의 수정으로, 게임 성능에 부정적인 영향을 미치는 윈도우의 거의 모든 단점을 제거합니다.
Atlas는 또한 시스템 지연, 네트워크 지연, 입력 지연을 줄이고 성능에 집중하면서 시스템을 비공개로 유지하는 좋은 선택입니다.
Atlas에 대해 자세히 알아보려면 공식 [웹사이트](https://atlasos.net)를 방문 하십시오.

## 📚 **목차**

- [기여 지침](https://docs.atlasos.net/contributions)

- 시작하기
  - [설치](https://docs.atlasos.net/getting-started/installation)
  - [다른 방법으로 설치](https://docs.atlasos.net/getting-started/other-installation-methods/no-usb)
  - [설치 후 사용](https://docs.atlasos.net/getting-started/post-installation/drivers)

- 문제 해결
  - [삭제된 기능](https://docs.atlasos.net/troubleshooting/removed-features)
  - [스크립트](https://docs.atlasos.net/troubleshooting/scripts)

- 자주 묻는 질문
  - [Atlas](https://atlasos.net/faq)
  - [알려진 문제](https://docs.atlasos.net/troubleshooting/common-issues/hyper-v/)

## 👀 **왜 Atlas를 사용해야 하나요?**

### 🔒 개인 정보 보호
기본 윈도우에는 귀하의 데이터를 수집하고 마이크로소프트로 업로드하는 추적 서비스가 포함되어 있습니다.
Atlas는 윈도우에 내장된 모든 종류의 추적을 제거하고 데이터 수집을 최소화하기 위해 수많은 그룹 정책을 구현하였습니다. 

하지만, Atlas는 윈도우의 범위 밖에 있는 것들(예: 브라우저 및 타사 응용 프로그램)의 보안은 보장할 수 없음을 유의하십시오.

### 🛡️ 보안 강화(커스텀 윈도우 iso보다 더 안전)
인터넷에서 수정된 윈도우 ISO를 다운로드하는 것은 위험합니다. 사람들이 윈도우에 포함된 수많은 바이너리/실행 파일 중 하나를 악의적으로 변경할 수 있을 뿐만 아니라 최신 보안 패치가 포함되지 않을 수 있으며, 이는 컴퓨터를 심각한 보안 위험에 노출시킬 수 있습니다. 

Atlas는 다릅니다. [AME 마법사](https://ameliorated.io)를 사용하여 Atlas를 설치하고, 모든 스크립트는 저희 GitHub 저장소에서 오픈 소스로 제공됩니다. 패키지된 Atlas 플레이북(`.apbx` AME 마법사 스크립트 패키지)을 아카이브로 볼 수 있습니다. 암호는 `malte`입니다.(AME 마법사 플레이북의 표준) 이는 바이러스 백신으로부터의 잘못된 플래그를 우회하기 위한 것입니다.

플레이북에 포함된 유일한 실행 파일은 [GPLv3](https://github.com/Atlas-OS/Atlas-Utilities/blob/main/LICENSE)에 따라, [이곳](https://github.com/Atlas-OS/Atlas-Utilities)에서 오픈 소스로 제공되며, 해시는 릴리스와 동일합니다. 그 외의 모든 것은 평문입니다.

Atlas를 설치하기 전에 최신 보안 업데이트를 설치할 수도 있습니다. 이는 시스템을 안전하게 보호하기 위해 권장되는 사항입니다.

현재 Atlas 0.2.0 버전은 보안 기능이 제거되거나 비활성화되어 **일반 윈도우보다 안전하지 않습니다.** 그러나 Atlas 0.3.0 버전에서는 대부분의 보안 기능이 선택적 기능으로 다시 추가됩니다. 자세한 내용은 [여기](https://docs.atlasos.net/troubleshooting/removed-features/)를 참조하십시오.

### 🚀 더 많은 여유 공간
Atlas는 사전 설치된 응용 프로그램 및 기타 중요하지 않은 구성 요소를 제거합니다. 이로 인해 설치 크기가 크게 줄어들고 시스템이 더 원활하게 작동합니다. 그러나 호환성 문제의 가능성이 있으므로 일부 기능(예 : 윈도우 디펜더)은 완전히 제거됩니다. 제거된 기능에 대한 자세한 내용은 [제거된 기능](https://docs.atlasos.net/troubleshooting/removed-features) 섹션을 참조하십시오.

### ✅ 향상된 성능
인터넷에 있는 일부 커스텀 윈도우는 윈도우를 너무 많이 수정하여 블루투스, 와이파이 등과 같은 주요 기능과의 호환성을 손상시켰습니다.
Atlas는 최적의 지점에 있습니다. 성능을 향상시키면서도 호환성 수준을 유지하는 것을 목표로 합니다.

윈도우를 개선하기 위해 우리가 한 많은 변경 사항 중 일부는 다음과 같습니다.
- 전용 전원 모드
- 서비스 및 드라이버 수 감소
- 오디오 독점 비활성화
- 필요하지 않은 장치 비활성화
- 절전 모드 비활성화
- 성능이 저하되는 보안 완화 비활성화
- 모든 장치에서 MSI 모드 자동 활성화
- 부팅 구성 최적화
- 프로세스 스케줄링 최적화

### 🔒 서비스 약관
많은 커스텀 윈도우는 수정된 윈도우 ISO를 제공하여 시스템을 배포합니다. 이는 [마이크로소프트의 서비스 약관](https://www.microsoft.com/en-us/Useterms/Retail/Windows/10/UseTerms_Retail_Windows_10_English.htm)을 위반할 뿐만 아니라 설치하기에도 안전하지 않습니다. 

Atlas는 Windows Ameliorated Team과 협력하여 사용자에게 더 안전하고 합법적인 설치 방법인 [AME 마법사](https://ameliorated.io)를 제공했습니다. 이를 통해 Atlas는 [마이크로소프트의 서비스 약관](https://www.microsoft.com/en-us/Useterms/Retail/Windows/10/UseTerms_Retail_Windows_10_English.htm)을 완전히 준수합니다.

## 🎨Translation Contributors (브랜드 키트)
무언가 영감이 떠올랐나요? 독창적인 디자인으로 자신만의 Atlas 배경 화면을 만들고 싶으신가요? 저희 브랜드 키트가 도와드릴 수 있습니다!
누구나 Atlas 브랜드 키트에 접근할 수 있습니다. [이곳](https://github.com/Atlas-OS/branding/archive/refs/heads/main.zip)에서 다운로드하여 멋진 것을 만들어 보세요!

우리는 또한 [포럼](https://forum.atlasos.net/t/art-showcase), 전용 영역을 가지고 있습니다. [여기](https://forum.atlasos.net/t/art-showcase)에서 다른 창의적인 천재들과 당신의 창작물을 공유하고 영감을 줄 수도 있습니다! 또한 다른 사용자가 공유하는 창의적인 배경 화면도 찾을 수 있습니다!

## ⚠️ Disclaimer (면책 조항)
https://github.com/Atlas-OS/Atlas/#%EF%B8%8F-disclaimer

## 번역 기여자
[앙시모사우루스](https://github.com/Angsimosaurus)
