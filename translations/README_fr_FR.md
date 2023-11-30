⚠️Note: This is a translated version of the original [README.md](https://github.com/Atlas-OS/Atlas/blob/main/README.md), information here may not be accurate and can be outdated.
<h1 align="center">
  <a href="http://atlasos.net"><img src="https://github.com/Atlas-OS/branding/blob/main/github-banner.png" alt="Atlas" width="900" style="border-radius: 30px"></a>
</h1>
  <p align="center">
    <a href="https://github.com/Atlas-OS/Atlas/blob/main/LICENSE">
      <img alt="Licence" src="https://img.shields.io/github/license/atlas-os/atlas?style=for-the-badge&logo=github&color=1A91FF&label=Licence"/>
    </a>
    <a href="https://github.com/Atlas-OS/Atlas/graphs/contributors">
      <img alt="Contributeurs" src="https://img.shields.io/github/contributors/atlas-os/atlas?style=for-the-badge&color=1A91FF&label=Contributeurs" />
    </a>
    <a href="https://github.com/Atlas-OS/Atlas/releases/latest">
      <img alt="Dernière version" src="https://img.shields.io/github/release/atlas-os/atlas?style=for-the-badge&color=1A91FF&label=Derni%C3%A8re%20version" />
    </a>
    <a href="https://github.com/Atlas-OS/Atlas/releases">
      <img alt="Téléchargements" src="https://img.shields.io/github/downloads/Atlas-OS/Atlas/total?style=for-the-badge&logo=github&color=1A91FF&label=T%C3%A9l%C3%A9chargements" />
    </a>
  </p>
<h4 align="center">Un système d'exploitation ouvert et transparent, conçu pour optimiser les performances, la confidentialité et la stabilité.</h4>

<p align="center">
  <a href="https://atlasos.net">Site web</a>
  •
  <a href="https://docs.atlasos.net">Documentation</a>
  •
  <a href="https://discord.atlasos.net" target="_blank">Discord</a>
  •
  <a href="https://forum.atlasos.net">Forum</a>
</p>

## 🤔 **Qu'est-ce que Atlas ?**

Atlas est une version modifiée de Windows 10 qui corrige presque tous les inconvénients de Windows qui affectent négativement les performances en jeu.
Atlas est également une bonne option pour réduire la latence du système, la latence du réseau, l'input lag, et protéger votre vie privée tout en se concentrant sur les performances.
Vous pouvez en savoir plus sur Atlas sur notre [site web](https://atlasos.net).

## 📚 **Table des matières**

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

## 👀 **Pourquoi Atlas ?**

### 🔒 Plus de confidentialité
Par défaut, Windows contient des services de suivi qui collectent vos données et les transmettent à Microsoft.
Atlas supprime tous les types de traçage intégrés à Windows et met en œuvre de nombreuses stratégies de groupe pour minimiser la collecte de données.

Notez qu'Atlas ne peut pas garantir la sécurité des éléments en dehors du champ d'application de Windows (tels que les navigateurs et les applications tierces).

### 🛡️ Plus sécurisé comparé à un ISO modifié
Le téléchargement d'un fichier ISO modifié sur internet est risqué. Non seulement des personnes peuvent facilement modifier de manière malveillante l'un des nombreux fichiers binaires/exécutables inclus dans Windows, mais il se peut également que l'ISO ne contienne pas les derniers correctifs de sécurité, ce qui peut exposer votre ordinateur à de graves risques de sécurité. 

Atlas est différent. Nous utilisons [AME Wizard](https://ameliorated.io) pour installer Atlas, et tous les scripts que nous utilisons sont open source ici dans notre dépôt GitHub. Vous pouvez ouvrir le playbook Atlas packagé (`.apbx` - scripts AME Wizard packagés) comme une archive, avec le mot de passe `malte` (le standard pour les playbooks AME Wizard). Le mot de passe existe seulement pour contourner les faux positifs des antivirus.

Les seuls exécutables inclus dans le playbook sont open source et visualisable [ici](https://github.com/Atlas-OS/Atlas-Utilities) sous licence [GPLv3](https://github.com/Atlas-OS/Atlas-Utilities/blob/main/LICENSE), les hashs étant identiques à ceux des releases. Tout le reste est en clair.

Vous pouvez également installer les dernières mises à jour de sécurité Windows avant d'installer Atlas, ce que nous recommandons pour garder votre système sécurisé.

Veuillez noter que jusqu'à la version 0.2.0, Atlas n'est **pas aussi sécurisé que Windows** en raison des fonctions de sécurité supprimées/désactivées, comme par exemple Windows Defender qui a été supprimé. Cependant, dans Atlas v0.3.0, la plupart de ces fonctions seront réintégrées en option. Voir [ici](https://docs.atlasos.net/troubleshooting/removed-features/) pour plus d'informations.

### 🚀 Plus léger
Les applications préinstallées et autres composants insignifiants sont supprimés avec Atlas. Malgré la possibilité de problèmes de compatibilité, cela réduit considérablement la taille de l'installation et rend votre système plus fluide. Par conséquent, certaines fonctionnalités (telles que Windows Defender) sont complètement supprimées.
Découvrez ce que nous avons supprimé dans notre [FAQ](https://docs.atlasos.net/troubleshooting/removed-features).

### ✅ Plus performant
Certains systèmes modifiés sur internet ont trop altéré Windows, rompant la compatibilité avec les fonctions principales telles que Bluetooth, Wi-Fi, etc.
Atlas vise un juste milieu : Obtenir plus de performances tout en maintenant un bon niveau de compatibilité.

Voici quelques-unes des nombreuses modifications que nous avons apportées pour améliorer Windows :
- Profil d'alimentation personnalisé
- Réduction du nombre de services et de pilotes
- Désactivation de l'exclusivité audio
- Désactivation des périphériques inutiles
- Désactivation de l'économie d'énergie (pour les ordinateurs portables)
- Désactivation de certains patchs de sécurité gourmands en performances
- Activation automatique du mode MSI sur tous les appareils
- Configuration de démarrage optimisée
- Optimisation de la planification des processus

### 🔒 Légal
De nombreux systèmes d'exploitation Windows personnalisés distribuent leurs systèmes en fournissant un fichier ISO modifié. Non seulement cela viole les [Conditions d'utilisation de Microsoft](https://www.microsoft.com/en-us/Useterms/Retail/Windows/10/UseTerms_Retail_Windows_10_French.htm), mais ce n'est pas non plus une méthode d'installation sûre.

Atlas s'est associé à l'équipe Windows Ameliorated pour offrir aux utilisateurs une méthode d'installation plus sûre et légale : l'[Assistant AME](https://ameliorated.io). Grâce à lui, Atlas respecte pleinement les [Conditions d'utilisation de Microsoft](https://www.microsoft.com/en-us/Useterms/Retail/Windows/10/UseTerms_Retail_Windows_10_French.htm).

## 🎨 Kit de marque
Vous vous sentez créatif ? Vous souhaitez créer votre propre fond d'écran Atlas avec des motifs créatifs originaux ? Notre kit de marque est là pour ça !
Tout le monde peut accéder au kit de marque Atlas - vous pouvez le télécharger [ici](https://github.com/Atlas-OS/branding/archive/refs/heads/main.zip) et créer quelque chose de spectaculaire !

Nous avons également un espace dédié sur notre [forum](https://forum.atlasos.net/t/art-showcase) pour que vous puissiez partager vos créations avec d'autres génies créatifs et peut-être même susciter de l'inspiration ! Vous pouvez également y trouver des fonds d'écran partagés par d'autres utilisateurs !

## ⚠️ Disclaimer (Clause de non-responsabilité)
https://github.com/Atlas-OS/Atlas#%EF%B8%8F-disclaimer

## Translation Contributors (Contributeurs à la traduction)
[uncognic](https://github.com/uncognic) |
[MATsxm](https://github.com/MATsxm) |
[jordanamr](https://github.com/jordanamr)
