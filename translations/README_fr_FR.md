<h1 align="center">
  <br>
  <a href="http://atlasos.net"><img src="https://i.imgur.com/xV08gIt.png" alt="Atlas" width="900"></a>
</h1>
<h4 align="center">Un système operationnel Windows ouvert et privé, crée pour optimiser la performance et la latence.</h4>

<p align="center">
  <a href="https://github.com/Atlas-OS/Atlas/wiki/2.-Installing">Installation</a>
  •
  <a href="https://github.com/Atlas-OS/Atlas/wiki/1.-FAQ#contents">FAQ</a>
  •
  <a href="https://discord.com/servers/atlas-795710270000332800" target="_blank">Discord</a>
  •
  <a href="https://forum.atlasos.net/">Forum</a>
</p>


# Qu'est-ce Atlas?

Atlas est une version modifiée de Windows qui enlève tous les points negatifs de Windows, qui diminuent la performance de jeu. Nous sommes un projet source ouvert et privé qui vise pour l'égalité pour les joueurs, que tu aies une pomme de terre, ou un ordinateur de jeu.

Même si notre concentration est sur la performance, nous sommes aussi un très bon choix pour réduire la latence système, la latence de reseau, la latence d'entrée, et pour garder votre système privé.

## Table des contenus (Liens wiki, alors c'est en Anglais.)

- [FAQ](https://github.com/Atlas-OS/Atlas/wiki/1.-FAQ)
  - [Qu'est-ce le projet Atlas?](https://github.com/Atlas-OS/Atlas/wiki/1.-FAQ#11-what-is-the-atlas-project)
  - [Comment j'installe Atlas?](https://github.com/Atlas-OS/Atlas/wiki/1.-FAQ#12-how-do-i-install-atlas-os)
  - [Qu'est-ce enlevé dans Atlas?](https://github.com/Atlas-OS/Atlas/wiki/1.-FAQ#13-whats-removed-in-atlas-os)
- <a href="#windows-vs-atlas">Windows vs. Atlas</a>
- [Après installation](https://github.com/Atlas-OS/Atlas/wiki/3.-Post-Install)
- [Kit d'art](https://github.com/Atlas-OS/Atlas/blob/main/img/brand-kit.zip?raw=true)

## Windows vs. Atlas

### **Privé**

Atlas enlève toutes les types d'éspionnage dans Windows et enforce des centaines de <em>group policies</em> pour minimizer la collecte de données. Les choses en-dehors Windows nous pouvons pas rendre plus privé, comme les sites Web que vous visitez.

### **Sécuritaire**

Atlas vise être le plus sécuritaire qui est possible sans perdre de la performance. Nous faisons ça en eteignant les caractéristiques que peuvent causer une fuite de données ou qui peuvent être éxploités. Il y a des éxceptions pour ça comme [Spectre](https://spectreattack.com/spectre.pdf) et [Meltdown](https://meltdownattack.com/meltdown.pdf). Ces mesures sécuritaires sont enlevées pour monter la performance.
Si une mesure sécuritaire reduit la pérformance, ils vont être enlevées. Ci-dessous sont des mesures sécuritaires qui ont étés alterés ou enlevées, si ils ont un (P), ce sont des risques de sécurité qui ont été réparés. (Les articles ci-dessous sont en Anglais.)

- [Spectre](https://spectreattack.com/spectre.pdf)
- [Meltdown](https://meltdownattack.com/meltdown.pdf)
- [DMA Remapping](https://docs.microsoft.com/en-us/windows/security/information-protection/kernel-dma-protection-for-thunderbolt)
- [(P) ATMFD Exploit](https://msrc.microsoft.com/update-guide/en-US/vulnerability/CVE-2020-1020)
- [(P) Print Nightmare](https://us-cert.cisa.gov/ncas/current-activity/2021/06/30/printnightmare-critical-windows-print-spooler-vulnerability)
- [Remote Desktop](https://cve.mitre.org/cgi-bin/cvekey.cgi?keyword=Windows+Remote+Desktop)
- [NetBIOS](https://en.wikipedia.org/wiki/NetBIOS) (_Éxtraction de données possible_)

### **Nettoyé**

Atlas est éxtrêmement réduit à l'éssentiel, les applications préinstallées sont enlevées, et d'autres composantes du système sont enlevées. Même si cela peut briser certaines applications, ça réduit éxtrêmement le ISO et la grandeur d'installation. Les fonctionnalités comme Windows Defender, et ceux-ci sont enlevées complètement. Cette modification est concentrée sur purement le jeu, mais la majorité des applications de travail et d'éducation marchent. [Regardez quoi d'autre nous avons enlevées dans notre FAQ (En Anglais)](https://github.com/Atlas-OS/Atlas/wiki/1.-FAQ#13-whats-removed-in-atlas-os).

### **Performant**

Atlas est optimisé pré-installation. En gardant la compatibilité, mais aussi s'aspire pour la performance. Nous avons epongé chaque goutté de performance dans nos ISO Windows. Quelques changements que nous avons appliqué sont ci-dessous.

- Schéma d'alimentation personnalisé
- Services minimisés
- Pilotes réduits
- Appareils inutiles désactivés
- Économies d'énergie désactivées
- Désactivation des mesures d'atténuation de la sécurité gourmandes en performances
- Mode MSI activé automatiquement
- Optimisation de la configuration de démarrage
- Planification optimisée des processus

## Kit d'art

Vous voulez créer votre propre fond d'écran Atlas? Peut-être jouer avec notre logo pour créers votre propre design? Nous avons ça accessible au public pour allumer de l'inspiration créative autour de la communauté [Regardez notre Kit d'art et créez quelque-chose d'époustouflant.](https://github.com/Atlas-OS/Atlas/blob/main/img/brand-kit.zip?raw=true)

Nous avons aussi [une séctions dédiée dans l'onglet Communauté](https://github.com/Atlas-OS/Atlas/discussions/categories/community-artwork), pour que vous pourrez partager votre design avec d'autres artistes at créer de l'inspiration.

## Disclaimer (Avertissement)

By downloading, modifying, or utilizing any of these images, you agree to [Microsoft's Terms.](https://www.microsoft.com/en-us/Useterms/Retail/Windows/10/UseTerms_Retail_Windows_10_English.htm) None of these images are pre-activated, you **must** use a genuine key.

## Translation contributors (Contributeurs à la traduction)

[uncognic](https://github.com/uncognic)
