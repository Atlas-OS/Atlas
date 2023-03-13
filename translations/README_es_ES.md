<h1 align="center">
    <br>
    <a href="http://atlasos.net"><img src="https://i.imgur.com/xV08gIt.png" alt="Atlas" width="900"></a>
  </h1>
  <h4 align="center">Atlas, El sistema diseñado al rendimiento y baja latencia. Bienvenido a Atlas
  <p align="center">
    <a href="https://github.com/Atlas-OS/Atlas/wiki/2.-Installing">Instalación</a>
    •
    <a href="https://github.com/Atlas-OS/Atlas/wiki/1.-FAQ#contents">Preguntas (FAQ)</a>
    •
    <a href="https://discord.com/servers/atlas-795710270000332800" target="_blank">Discord</a>
    •
    <a href="https://forum.atlasos.net">Foro</a>
  </p>
  
  # Qué es Atlas? 
  
  Atlas es una versión modificada de Windows que remueve todas los problemas de Windows, que pueden afectar negativamente el rendimiento en Gaming. Somos un proyecto abierto y transparente que nos esforzamos por la igualdad de los jugadores, tanto si se trata de un PC de Gama baja como un PC Gaming.
  
  Tambien somos una gran opción para reducir la latencia en el sistema, retraso de la conexión, Input lag y mantener el sistema seguro mientras nos enfocamos en el rendimiento.
  
  ## Table of contents
  
  - [FAQ](https://github.com/Atlas-OS/Atlas/wiki/1.-FAQ)
    - [Qué es el proyecto Atlas?](https://github.com/Atlas-OS/Atlas/wiki/1.-FAQ#11-what-is-the-atlas-project)
    - [Comó instalo Atlas?](https://github.com/Atlas-OS/Atlas/wiki/1.-FAQ#12-how-do-i-install-atlas-os)
    - [Que ha sido eliminado en Atlas?](https://github.com/Atlas-OS/Atlas/wiki/1.-FAQ#13-whats-removed-in-atlas-os)
  - <a href="#windows-vs-atlas">Windows vs. Atlas</a>
  - [Despues de instalar](https://github.com/Atlas-OS/Atlas/wiki/3.-Post-Install)
  - [Kit de marca](https://raw.githubusercontent.com/Atlas-OS/Atlas/main/img/brand-kit.zip)
  
 ## Windows vs. Atlas

### **Privacidad**

Atlas elimina todo tipo de rastreo integrado en Windows e implementa directrices de grupo para minimizar la recolección de datos. Cosas fuera del ambiente de Windows a las que no podemos aumentar la privacidad. Como las páginas que visitas

### **Seguridad**

Atlas apunta a ser lo más seguro posible sin perder rendimiento. Hacemos esto deshabilitando funciones que pueden filtrar información o ser explotadas. Hay un par de excepciones a esto como lo son [Spectre](https://spectreattack.com/spectre.pdf), y también [Meltdown](https://meltdownattack.com/meltdown.pdf). Estas mitigaciones están deshabilitadas para mejorar el rendimiento.
Si una medida de mitigación reduce el rendimiento, esta será deshabilitada.
Abajo hay algunas funciones/mitigaciones que han sido alteradas; Si su etiqueta contienen una (P) son riesgos de seguridad que han sido solucionados:

- [Spectre](https://spectreattack.com/spectre.pdf)
- [Meltdown](https://meltdownattack.com/meltdown.pdf)
- [DMA Remapping](https://docs.microsoft.com/en-us/windows/security/information-protection/kernel-dma-protection-for-thunderbolt)
- [(P) ATMFD Exploit](https://msrc.microsoft.com/update-guide/en-US/vulnerability/CVE-2020-1020)
- [(P) Print Nightmare](https://us-cert.cisa.gov/ncas/current-activity/2021/06/30/printnightmare-critical-windows-print-spooler-vulnerability)
- [Remote Desktop](https://cve.mitre.org/cgi-bin/cvekey.cgi?keyword=Windows+Remote+Desktop)
- [NetBIOS](https://en.wikipedia.org/wiki/NetBIOS) (_Posible recuperación de información_)

### **Reducción**

Atlas ha sido intensamente reducido, aplicaciones pre-instaladas y otros componentes han sido eliminados. A pesar de la posibilidad de problemas de compatibilidad, esto reduce significativamente el peso de la ISO y la instalación. Funciones como Windows Defender, y similares se eliminan por completo. Esta modificación esta centrada puramente en Gaming, pero la mayoria de aplicaciones de estudio y trabajo funcionan perfectamente. [Revisa qué más ha sido eliminado de atlas en Preguntas Frecuentes(FAQ)](https://github.com/Atlas-OS/Atlas/wiki/1.-FAQ#13-whats-removed-in-atlas-os).

### **Rendimiento**

Atlas está pre-modificado. Mientras mantiene la compatibilidad, pero también por el rendimiento, hemos buscado exprimir hasta la última gota de rendimiento en nuestras ISO de Windows. Algunos de los muchos cambios que hemos hecho para mejorar Windows son:

- Plan de energía personalizado.
- Reducción de servicios y drivers.
- Audio exclusivo desactivado.
- Dispositivos innecesarios desactivados.
- Ahorro de energía desactivado.
- Mitigaciones de seguridad que afectan el rendimiento deshabilitadas.
- Modo MSI habilitado en todos los dispositivos.
- Configuración de booteo
- Programación de procesos optimizada.

## La creatividad no tiene limites

Te gustaría crear tu propio fondo de pantalla de Atlas? Quieres jugar un poco con nuestro logo para crear tu propio diseño? Tenemos esto a disposición al público para despertar ideas creativas en toda la comunidad. [Revisa nuestro kit de marca para que puedas crear algo impresionante.](https://raw.githubusercontent.com/Atlas-OS/Atlas/main/img/brand-kit.zip)

También tenemos una [area de discuciones e ideas](https://github.com/Atlas-OS/Atlas/discussions/categories/community-artwork), Para que puedas compartir tus ideas y creaciones con otros. ¡También quizás y encuentres algo que te inspire a poner a volar la imaginación!

## Disclaimer


By downloading, modifying, or utilizing any of these images, you agree to [Microsoft's Terms](https://www.microsoft.com/en-us/Useterms/Retail/Windows/10/UseTerms_Retail_Windows_10_English.htm). None of these images are pre-activated, you **must** use a genuine key.
