<h1 align="center">
  <br>
  <a href="http://atlasos.net"><img src="https://i.imgur.com/xV08gIt.png" alt="Atlas" width="900"></a>
</h1>
<h4 align="center">Un système d'exploitation Windows ouvert et respecteux de la vie privée, créé pour optimiser la performance et la latence.</h4>

<p align="center">
  <a href="https://github.com/Atlas-OS/Atlas/wiki/2.-Installing">Installation</a>
  •
  <a href="https://github.com/Atlas-OS/Atlas/wiki/1.-FAQ#contents">FAQ</a>
  •
  <a href="https://discord.com/servers/atlas-795710270000332800" target="_blank">Discord</a>
  •
  <a href="https://forum.atlasos.net">Forum</a>
</p>


# Qu'est-ce Atlas ?

Atlas est une version modifiée de Windows 10 qui supprime tous les défauts de Windows qui diminuent les performances de jeu. Nous sommes un projet Open Source respecteux de la vie privée qui recherche l'égalité pour les joueurs, que tu ais une pomme de terre, ou un ordinateur de jeu.

Nous nous présentons également comme une excellente option pour réduire la latence du système, la latence du réseau, le décalage en entrée pour garder votre système privé tout en nous concentrant principalement sur les performances.

## Table des matières (Liens wiki en Anglais.)

- [FAQ](https://github.com/Atlas-OS/Atlas/wiki/1.-FAQ)
  - [Qu'est-ce le projet Atlas ?](https://github.com/Atlas-OS/Atlas/wiki/1.-FAQ#11-what-is-the-atlas-project)
  - [Comment installer Atlas ?](https://github.com/Atlas-OS/Atlas/wiki/1.-FAQ#12-how-do-i-install-atlas-os)
  - [Qu'est-ce qui est enlevé dans Atlas ?](https://github.com/Atlas-OS/Atlas/wiki/1.-FAQ#13-whats-removed-in-atlas-os)
- <a href="#windows-vs-atlas">Windows vs. Atlas</a>
- [Après l'installation](https://github.com/Atlas-OS/Atlas/wiki/3.-Post-Install)
- [Kit d'art](https://raw.githubusercontent.com/Atlas-OS/Atlas/main/img/brand-kit.zip)

## Windows vs. Atlas

### **Respect de la vie privée**

Atlas supprime tous les types de traqueurs de suivi intégrés dans Windows et implémente de nombreuses <em>stratégies de groupe</em> pour minimiser la collecte de données. Pour les éléments hors de portée de Windows nous ne pouvons pas augmenter la confidentialité, comme pour les sites Web que vous visitez.

### **Sécuriser**

Atlas vise être le plus sécurisé possible sans perte de performance. Nous y parvenons en désactivant les fonctionnalités qui peuvent causer une fuite de données ou qui peuvent être éxploités. Il y a des éxceptions pour ça comme [Spectre](https://spectreattack.com/spectre.pdf) et [Meltdown](https://meltdownattack.com/meltdown.pdf). Ces mesures sécuritaires sont supprimées pour améliorer les performances.
Si une mesure sécuritaire reduit la pérformance, elle va être enlevée. Ci-dessous des mesures sécuritaires qui ont été alterées ou enlevées, si elles ont un (P), ce sont des risques de sécurité qui ont été corrigés. (Les articles ci-dessous sont en Anglais.)

- [Spectre](https://spectreattack.com/spectre.pdf)
- [Meltdown](https://meltdownattack.com/meltdown.pdf)
- [DMA Remapping](https://docs.microsoft.com/en-us/windows/security/information-protection/kernel-dma-protection-for-thunderbolt)
- [(P) ATMFD Exploit](https://msrc.microsoft.com/update-guide/en-US/vulnerability/CVE-2020-1020)
- [(P) Print Nightmare](https://us-cert.cisa.gov/ncas/current-activity/2021/06/30/printnightmare-critical-windows-print-spooler-vulnerability)
- [Remote Desktop](https://cve.mitre.org/cgi-bin/cvekey.cgi?keyword=Windows+Remote+Desktop)
- [NetBIOS](https://en.wikipedia.org/wiki/NetBIOS) (_Éxtraction de données possible_)

### **Nettoyer**

Atlas est éxtrêmement nettoyé, les applications préinstallées sont enlevées, et d'autres composants du système sont enlevés. Même si cela peut casser certaines applications, cela réduit fortement la taille de l'ISO et de l'installation. Les fonctionnalités comme Windows Defender et similaires sont complètement retirés. Cette modification est purement centrée sur le jeu, mais la majorité des applications de travail et d'éducation fonctionnent. [Regardez ce que nous avons enlevées d'autres dans notre FAQ (En Anglais)](https://github.com/Atlas-OS/Atlas/wiki/1.-FAQ#13-whats-removed-in-atlas-os).

### **Performant**

Atlas est pré-optimisé. En gardant la compatibilité, mais aussi la recherche de performances. Nous avons epongé chaque goutte de performance de nos ISO Windows. Quelques changements que nous avons appliqué sont ci-dessous.

- Schéma d'alimentation personnalisé
- Nombre de services reduits
- Nombre de pilotes réduits
- Appareils inutiles désactivés
- Économies d'énergie désactivées
- Désactivation des mesures d'atténuation de sécurité gourmandes en performances
- Mode MSI activé automatiquement
- Optimisation de la configuration de démarrage
- Planification des processus optimisée

## Kit d'art

Vous voulez créer votre propre fond d'écran Atlas? Peut-être jouer avec notre logo pour créer votre propre conception? Nous avons cela accessible au public pour susciter de nouvelles idées créatives à travers la communauté. [Regardez notre Kit d'art et créez quelque-chose d'époustouflant.](https://github.com/Atlas-OS/Atlas/blob/main/img/brand-kit.zip?raw=true)

Nous avons aussi [une séctions dédiée dans l'onglet Communauté](https://github.com/Atlas-OS/Atlas/discussions/categories/community-artwork), pour que vous puissiez partager votre création avec d'autres artistes et susciter de l'inspiration.

## Disclaimer (Avertissement)

By downloading, modifying, or utilizing any of these images, you agree to [Microsoft's Terms.](https://www.microsoft.com/en-us/Useterms/Retail/Windows/10/UseTerms_Retail_Windows_10_English.htm) None of these images are pre-activated, you **must** use a genuine key.

## Translation contributors (Contributeurs à la traduction)

[uncognic](https://github.com/uncognic)
