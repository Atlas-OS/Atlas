## ⚠️WARNING! This translation is not yet updated with the main README.md, information here may be outdated.
<h1 align="center">
  <a href="http://atlasos.net"><img src="https://cdn.jsdelivr.net/gh/Atlas-OS/Atlas@main/img/banner.png" alt="Atlas" width="900" style="border-radius: 30px"></a>
</h1>

<h4 align="center">Un sistema operativo Windows lleno de libertad, diseñado para optimizar el rendimiento y disminuir la latencia.</h4>

<p align="center">
  <a href="https://atlasos.net">Website</a>
  •
  <a href="https://docs.atlasos.net/FAQ/Installation/">FAQ</a>
  •
  <a href="https://discord.com/invite/atlasos" target="_blank">Discord</a>
  •
  <a href="https://forum.atlasos.net">Forum</a>
</p>

## 🤔 **¿Qué es Atlas?** 
  
Atlas OS es una versión modificada de Windows 10 que soluciona todos los inconvenientes negativos de Windows que afectan adversamente el rendimiento. Somos un proyecto transparente y de código abierto que se esfuerza por la igualdad de los jugadores, ya sea si posees un PC de gama baja o un PC para gaming.
  
También somos una buena opción para reducir la latencia en el sistema, el retraso de la conexión, el input lag y mantener tu sistema privado, siempre enfocándonos en el rendimiento.

You can learn more about Atlas in our official [Website](https://atlasos.net)

## 📚 **Table of contents**
- FAQ
  - [Install](https://docs.atlasos.net/FAQ/Installation/)
  - [Contribute](https://docs.atlasos.net/FAQ/Contribute/)

- Getting Started
  - [Installation](https://docs.atlasos.net/Getting%20started/Installation/)
  - [Other install methods](https://docs.atlasos.net/Getting%20started/Other%20installation%20methods/Install%20with%20no%20USB/)
  - [Post Install](https://docs.atlasos.net/Getting%20started/Post-Installation/Drivers/)

- Troubleshooting
  - [Removed Features](https://docs.atlasos.net/Troubleshooting/Removed%20features/)
  - [Scripts](https://docs.atlasos.net/Troubleshooting/Scripts/)

- <a href="#windows-vs-atlas">Windows vs. Atlas</a>
- [Branding kit](https://cdn.jsdelivr.net/gh/Atlas-OS/Atlas@main/img/brand-kit.zip)

## 🆚 **Windows vs. Atlas**

### 🔒 Mayor privacidad
Atlas elimina todo tipo de rastreo integrado en Windows e implementa varias directrices de grupo para minimizar la recolección de datos. Ten en cuenta que no podemos hacer nada en cuanto a los sitios web que visitas, por ejemplo, pero te cubriremos donde podamos.

### 🛡️ Seguridad reforzada
Atlas apunta a ser lo más seguro posible, sin perder rendimiento. Logramos esto deshabilitando o mitigando funciones que podrían filtrar información o ser vulneradas. Podría haber un par de excepciones a esto, como lo son [Meltdown](https://meltdownattack.com/meltdown.pdf) y [Spectre](https://spectreattack.com/spectre.pdf); las mitigaciones a estos exploits fueron quitadas para mejorar el rendimiento.
Si una medida de seguridad o mitigación ralentiza tu sistema, entonces la quitaremos/revertiremos.

Aquí te dejamos la lista de vulnerabilidades mitigadas que alteramos; si una de ellas está marcada con una "(P)" al lado, significa que neutralizamos sus mitigaciones pero fueron solucionadas.

- [Spectre](https://spectreattack.com/spectre.pdf)
- [Meltdown](https://meltdownattack.com/meltdown.pdf)
- [DMA Remapping](https://docs.microsoft.com/en-us/windows/security/information-protection/kernel-dma-protection-for-thunderbolt)
- (P) [ATMFD Exploit](https://msrc.microsoft.com/update-guide/en-US/vulnerability/CVE-2020-1020)
- (P) [Print Nightmare](https://us-cert.cisa.gov/ncas/current-activity/2021/06/30/printnightmare-critical-windows-print-spooler-vulnerability)
- [Remote Desktop](https://cve.mitre.org/cgi-bin/cvekey.cgi?keyword=Windows+Remote+Desktop)
- [NetBIOS](https://en.wikipedia.org/wiki/NetBIOS) (*Posible recuperación de información*)

### 🚀 Desinflado
Atlas ha sido intensamente desinflado; las aplicaciones preinstaladas y otros componentes innecesarios (bloatware) han sido eliminados. A pesar de la posibilidad de problemas de compatibilidad, hacer esto reduce significativamente el peso de la ISO y de la instalación. Funciones como Windows Defender y similares se eliminan por completo.

Esta modificación está centrada puramente en el gaming, pero la mayoría de aplicaciones de estudio y trabajo funcionan perfectamente. Revisa qué más hemos removido del sistema en [nuestra sección de Preguntas Frecuentes](https://github.com/Atlas-OS/Atlas/wiki/1.-FAQ#13-what-is-removed-in-atlas-os).

### ✅ Eficiente
Atlas está premodificado. Manteniendo la compatibilidad, pero también esforzándonos por el rendimiento, hemos buscado exprimir hasta la última gota del mismo en nuestras ISO de Windows.

A continuación, algunos de los cambios que hemos hecho para mejorar Windows:

- Plan de energía personalizado
- Reducción de servicios y drivers
- Audio exclusivo desactivado
- Dispositivos innecesarios desactivados
- Ahorro de energía desactivado
- Mitigaciones de seguridad que afectan el rendimiento anuladas
- Modo MSI habilitado en todos los dispositivos
- Configuración de arranque optimizada
- Programación de procesos optimizada

## 🎨 Kit de marca
¿Te gustaría crear tu propio fondo de pantalla de Atlas? ¿Quieres jugar un poco con nuestro logo para crear tu propio diseño? Tenemos esto a disposición al público para despertar ideas creativas en toda la comunidad. ¡Revisa nuestro [kit de marca](https://cdn.jsdelivr.net/gh/Atlas-OS/Atlas@main/img/brand-kit.zip) y crea algo impresionante!

También tenemos una [área dedicada en el apartado de discusiones](https://github.com/Atlas-OS/Atlas/discussions/categories/community-artwork) para que puedas compartir tus ideas y creaciones con otros. ¡Quizás y encuentres algo que te inspire a poner a volar tu imaginación!

## ⚠️ Disclaimer
By downloading, modifying, or utilizing any of these images, you agree to [Microsoft's Terms](https://www.microsoft.com/en-us/Useterms/Retail/Windows/10/UseTerms_Retail_Windows_10_English.htm). None of these images are pre-activated, you **must** use a genuine key.

## Translation contributors (Colaboradores de traducción)
[Bryan Rivalyr](https://github.com/Rivalyr) | 
[Naxitoo](https://github.com/naxitoo)
