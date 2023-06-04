⚠️Note: This is a translated version of the original [README.md](https://github.com/Atlas-OS/Atlas/blob/main/README.md), information here may not be accurate and can be outdated.
<h1 align="center">
  <a href="http://atlasos.net"><img src="https://gcore.jsdelivr.net/gh/Atlas-OS/Atlas@main/img/banner.png" alt="Atlas" width="900" style="border-radius: 30px"></a>
</h1>

<h4 align="center">Ett fridoms fullt Windows operativ system, designat för att optimisera och improvisera responstid.</h4>

<p align="center">
  <a href="https://github.com/Atlas-OS/Atlas/wiki/2.-Installing">Installation</a>
  •
  <a href="https://github.com/Atlas-OS/Atlas/wiki/1.-FAQ#contents">FAQ</a>
  •
  <a href="https://discord.atlasos.net" target="_blank">Discord</a>
  •
  <a href="https://forum.atlasos.net">Forum</a>
</p>

## 🤔 **Vad i hela tusan är Atlas?**

Jo det ska jag berätta för dig vettu. Atlas är en moddad version av Microsofts Windows 10. Men vad är fel med gammla fina Windows 10 då undrar du? Jo, det finns några nackdelar som slöar ner din spel prestanda. Det är just därför vi har gått o gjort Atlas, vi är allt om att alla ska får samma chans att spela både de gamers med sämre datorer o de med bättre datorer.

Vi är ett öppet och open-source projekt, så du vet att vi inte gömmer något från er alla. Vi har också implementerat fixar och improvisioner såsom mindre system lagg, snabbare internet hastighet, responstid och såklart din integritet. Vi är allt om att du ska ha den bästa prestandan och det är vårat fokus.

## 📚 **Lista av innehåll**

- [Contribution Guidelines](https://docs.atlasos.net/contributions)

- Getting Started
  - [Installation](https://docs.atlasos.net/getting-started/installation)
  - [Other installation methods](https://docs.atlasos.net/getting-started/other-installation-methods/no-usb)
  - [Post-Installation](https://docs.atlasos.net/getting-started/post-installation/drivers)

- Troubleshooting
  - [Removed Features](https://docs.atlasos.net/troubleshooting/removed-features)
  - [Scripts](https://docs.atlasos.net/troubleshooting/scripts)

- FAQ
  - [Atlas](https://atlasos.net/faq)
  - [Common Issues](https://docs.atlasos.net/troubleshooting/common-issues/hyper-v/)
## 🆚 **Windows vs. Atlas**

### 🔒 Integritet
Atlas tar bort all typ av spårning som finns i Windows och implementerar ett flertal grupppolicyer för att minimisera data kollektion. Saker utanför Windows kan vi inte improvisera integritet för, t.ex hemsidorna du besöker.

### 🛡️ Säkerhet
Atlas mål är att du ska vara så säker som möjligt utan att förlora prestanda. Vi gör detta genom att stänga av funktioner som kan läcka information eller funktioner som kan utnyttjas för dåliga handlingar. Det finns undantag till detta såsom [Spectre](https://spectreattack.com/spectre.pdf) och [Meltdown](https://meltdownattack.com/meltdown.pdf). Dessa begränsningar är avstängda för att improvisera prestanda.

Om en säkerhets begränsning försämrar prestanda blir avaktiverade.
Nedanför finns en lista på begränsningar/funktioner som har blivit ändrade, om det finns ett (P) i namnet tyder detta på att det finns säkerhets risker som såklart blivit fixade:

- [Spectre](https://spectreattack.com/spectre.pdf)
- [Meltdown](https://meltdownattack.com/meltdown.pdf)
- [DMA Remapping](https://docs.microsoft.com/en-us/windows/security/information-protection/kernel-dma-protection-for-thunderbolt)
- (P) [ATMFD Exploit](https://msrc.microsoft.com/update-guide/en-US/vulnerability/CVE-2020-1020)
- (P) [Print Nightmare](https://us-cert.cisa.gov/ncas/current-activity/2021/06/30/printnightmare-critical-windows-print-spooler-vulnerability)
- [Remote Desktop](https://cve.mitre.org/cgi-bin/cvekey.cgi?keyword=Windows+Remote+Desktop)
- [NetBIOS](https://en.wikipedia.org/wiki/NetBIOS) (*Möjlig informations hämtning*)

### 🚀 Rensning
Atlas är tungt rensat från onödiga funktioner, förinstallerade applikationer och andra komponenter är borttagna. Trots möjligheten av inkompabilitets problem, Atlas minskar ISO och installations storleken. Funktioner såsom Windows Defender är totalt strippade. Dessa modifikationer är fokuserade på ren gaming, men de flesta jobb och skol appar fungerar utan problem. [Kolla in andra grejer vi stängt av i vår FAQ](https://github.com/Atlas-OS/Atlas/wiki/1.-FAQ#13-whats-removed-in-atlas-os).

### ✅ Effektivitet
Atlas är för-tweakad. Vi behåller kompabilitet, men vi striver även för prestanda. Vi har tryckt ut varenda jädra droppe av prestanda som går in i Atlas.

Vissa av de många förändringar som vi har gjort för att improvisera Windows kan du hitta här nedanför vettu.

- Anpassat "Power Scheme"
- Reducerad mängd tjänster och drivrutiner
- Inaktiverat exklusivt ljud
- Avaktiverat onödiga enheter
- Inaktiverat strömspars läge
- Inaktiverat prestand-hungriga säkerhets återgärder
- Automatiskt aktiverar MSI läge på alla enheter
- Boot konfigurations optimisering
- Optimiserade processer
- Optimerad processplanering

## 🎨 Varumärkes Kit

Vill du göra din egna Atlas bakgrundsbild? Kanske leka runt lite med våran logga och göra din egna design? Vi har detta åtkomstbart till alla för att införa nya krativa idéer runt gemenskapen. [Ta en titt på vårat varumärkes kit och hitta på något spektakulärt.](https://cdn.jsdelivr.net/gh/Atlas-OS/Atlas@main/img/brand-kit.zip)

Vi har också en [dedikerad plats i våran diskussions plats](https://github.com/Atlas-OS/Atlas/discussions/categories/community-artwork), så att du kan dela med dig med dina kreativa idéer till andra kreativa smarton och kanske sprida lite inspiration!

## ⚠️ Disclaimer (Disclaimer)
https://github.com/Atlas-OS/Atlas#%EF%B8%8F-disclaimer

## Translation contributors (!!Translation contributor in the translated language)
[Contributor A](https://github.com/A) |
[Contributor B](https://github.com/B) |
[Contributor C](https://github.com/C)
