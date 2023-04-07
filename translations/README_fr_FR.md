## ⚠️WARNING! This translation is not yet updated with the main README.md, information here may be outdated.
<h1 align="center">
  <a href="http://atlasos.net"><img src="https://cdn.jsdelivr.net/gh/Atlas-OS/Atlas@main/img/banner.png" alt="Atlas" width="900" style="border-radius: 30px"></a>
</h1>

<h4 align="center">Un système d'exploitation Windows ouvert et respecteux de la vie privée, créé pour optimiser la performance et la latence.</h4>

<p align="center">
  <a href="https://github.com/Atlas-OS/Atlas/wiki/2.-Installing">Installation</a>
  •
  <a href="https://github.com/Atlas-OS/Atlas/wiki/1.-FAQ#contents">FAQ</a>
  •
  <a href="https://discord.atlasos.net" target="_blank">Discord</a>
  •
  <a href="https://forum.atlasos.net">Forum</a>
</p>

## 🤔 **Qu'est-ce qu'Atlas?**

Atlas est une version modifiée de Windows 10 qui supprime tous les défauts de Windows qui diminuent les performances de jeu. Nous sommes un projet Open Source respecteux de la vie privée et qui recherche l'égalité pour les joueurs, que tu ais un grille pain ou un véritable ordinateur de jeu.

Nous nous présentons également comme une excellente option pour réduire la latence du système, la latence du réseau, le décalage en entrée, pour garder votre système privé tout en nous concentrant principalement sur les performances.

## 📚 **Table des matières (Liens wiki en Anglais.)**

- [FAQ](https://github.com/Atlas-OS/Atlas/wiki/1.-FAQ)
  - [Qu'est-ce que le projet Atlas ?](https://github.com/Atlas-OS/Atlas/wiki/1.-FAQ#11-what-is-the-atlas-project)
  - [Comment installer Atlas ?](https://github.com/Atlas-OS/Atlas/wiki/1.-FAQ#12-how-do-i-install-atlas-os)
  - [Qu'est-ce qui est supprimé dans Atlas ?](https://github.com/Atlas-OS/Atlas/wiki/1.-FAQ#13-whats-removed-in-atlas-os)
- <a href="#windows-vs-atlas">Windows Vs. Atlas</a>
- [Installation](https://github.com/Atlas-OS/Atlas/wiki/2.-Installing)
- [Après l'installation](https://github.com/Atlas-OS/Atlas/wiki/3.-Post-Install)
- [Software](https://github.com/Atlas-OS/Atlas/wiki/4.-Software)
- [Kit pour la marque](https://raw.githubusercontent.com/Atlas-OS/Atlas/main/img/brand-kit.zip)
- [Legal](https://github.com/Atlas-OS/Atlas/wiki/Legal)

## 🆚 **Windows vs. Atlas**

### 🔒 Respect de la vie privée
Atlas supprime tous les types de traqueurs de suivi intégrés dans Windows et implémente de nombreuses <em>stratégies de groupe</em> pour minimiser la collecte de données. Pour les éléments hors de portée de Windows nous ne pouvons pas augmenter la confidentialité, comme par exemple pour les sites Web que vous visitez.

### 🛡️ Sécurité
Atlas vise être le plus sécurisé possible sans perte de performance. Nous y parvenons en désactivant les fonctionnalités qui peuvent causer une fuite de données ou qui peuvent être éxploitées. Il existe des éxceptions pour ça comme [Spectre](https://spectreattack.com/spectre.pdf) et [Meltdown](https://meltdownattack.com/meltdown.pdf). Ces atténuations sont désactivées pour améliorer les performances.

Si une mesure d'atténuation de la sécurité diminue les performances, elle sera désactivée.
Vous trouverez ci-dessous certaines fonctionnalités/atténuations qui ont été modifiées, si elles sont précédées d'un (P), ce sont des risques de sécurité qui ont été corrigés: (Les articles ci-dessous sont en anglais.)

- [Spectre](https://spectreattack.com/spectre.pdf)
- [Meltdown](https://meltdownattack.com/meltdown.pdf)
- [DMA Remapping](https://docs.microsoft.com/en-us/windows/security/information-protection/kernel-dma-protection-for-thunderbolt)
- (P) [ATMFD Exploit](https://msrc.microsoft.com/update-guide/en-US/vulnerability/CVE-2020-1020)
- (P) [Print Nightmare](https://us-cert.cisa.gov/ncas/current-activity/2021/06/30/printnightmare-critical-windows-print-spooler-vulnerability)
- [Remote Desktop](https://cve.mitre.org/cgi-bin/cvekey.cgi?keyword=Windows+Remote+Desktop)
- [NetBIOS](https://en.wikipedia.org/wiki/NetBIOS) (*Éxtraction de données possible*)

### 🚀 Nettoyage
Atlas est fortement dépouillé, les applications préinstallées et les autres composants système sont supprimés. Malgré la possibilité de problèmes de compatibilité, cela diminue considérablement la taille de l'ISO et de l'installation. Des fonctionnalités telles que Windows Defender ou similaires sont complètement supprimées.

Cette modification est axée sur le jeu pur, mais la plupart des applications de travail et d'éducation fonctionnent. Découvrez ce que nous avons supprimé d'autre dans notre [FAQ (en anglais)](https://github.com/Atlas-OS/Atlas/wiki/1.-FAQ#13-whats-removed-in-atlas-os)

### ✅ Performance
Atlas est pré-modifié. Tout en maintenant la compatibilité, mais aussi en recherchant les performances, nous avons intégré chaque dernière goutte de performance de nos ISO Windows.

Certains des nombreux changements que nous avons apportés pour améliorer Windows sont énumérés ci-dessous :

 - Schéma d'alimentation personnalisé
 - Réduction du nombre de services et de pilots
 - Audio désactivé
 - Appareils inutiles désactivés
 - Économies d'énergie désactivées
 - Atténuations de sécurité gourmandes en performances désactivées
 - Activation automatique du mode MSI sur tous les appareils
 - Optimisation de la configuration de démarrage
 - Planification optimisée des processus

## 🎨 Kit de la marque
Vous souhaitez créer votre propre fond d'écran Atlas ? Peut-être jouer avec notre logo pour créer votre propre design ? Nous rendons cela accessible au public pour susciter de nouvelles idées créatives au sein de la Communauté. [Découvrez notre kit de marque et créez quelque chose de spectaculaire.](https://cdn.jsdelivr.net/gh/Atlas-OS/Atlas@main/img/brand-kit.zip)

Nous avons également un espace dédié dans [l'onglet discussions](https://github.com/Atlas-OS/Atlas/discussions/categories/community-artwork), afin que vous puissiez partager vos créations avec d'autres génies créatifs et peut-être même susciter l'inspiration !

## ⚠️ Disclaimer
By downloading, modifying, or utilizing any of these images, you agree to [Microsoft's Terms](https://www.microsoft.com/en-us/Useterms/Retail/Windows/10/UseTerms_Retail_Windows_10_English.htm). None of these images are pre-activated, you **must** use a genuine key.

## Contributeurs à la traduction
[uncognic](https://github.com/uncognic) |
[MATsxm](https://github.com/MATsxm)
