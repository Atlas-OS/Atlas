### Atlas Manager: French (fr). Preview translation, revised on 6 September 2026 from the en-GB source (i18n/en-GB/atlas.ftl).
###
### Conventions pour cette langue : vouvoiement ; espace insécable (U+00A0) avant
### « : ; ? ! » et à l'intérieur des guillemets « » ; apostrophe typographique (’) ;
### boutons à l'infinitif ; titres et libellés sans point final ; « relancer »
### désigne l'application Atlas, « redémarrer » désigne le PC ou Windows.

## Partagé

app-name = Atlas Manager
common-done = Terminé
common-cancel = Annuler
common-back = Retour
common-next = Continuer
common-dismiss = Ignorer
# Lien à côté d'une ligne de résumé qui ramène à ce choix.
common-change = Modifier
common-copy = Copier
# Affiché lorsqu'une liste d'options est vide.
common-none = Aucune
# Description accessible d'un contrôle désactivé.
common-not-available = Indisponible pour le moment
# Nom accessible de la flèche de retour sur les pages Installation et Paramètres.
common-back-to-home = Retour à l’accueil
# Nom accessible du bouton d'engrenage dans la barre de titre.
common-settings = Paramètres
common-close-settings = Fermer les paramètres
common-open-windows-security = Ouvrir Sécurité Windows
common-restart-as-administrator = Relancer en tant qu’administrateur
common-try-again = Réessayer
common-read-the-docs = Lire le guide Atlas
common-show-details = Afficher les détails
common-hide-details = Masquer les détails
common-open-log-file = Ouvrir le fichier journal
# Nom accessible du bouton Copier à côté du journal d'installation.
common-copy-install-log = Copier le journal d’installation
common-install-log = Journal d’installation
# Libellés de ligne dans les cartes de résumé.
common-windows = Windows
common-options = Options
common-package = Fichiers d’installation
common-installed-as = Type d’installation
common-installed = Installé
common-checking = Vérification en cours
# Sépare deux éléments d'une liste : « Brave, Firefox ». Les accolades conservent l'espace.
list-separator = { ", " }
# Relie deux alternatives : « 26100 ou 26200 ».
list-or = { $a } ou { $b }

## Fenêtre

# Boîte de dialogue affichée si la fenêtre est fermée pendant une installation.
window-close-title = Fermer la fenêtre pendant l’installation ?
window-close-message = L’installation continue en arrière-plan. Rouvrez Atlas pour suivre sa progression et voir le résultat. Laissez votre PC allumé jusqu’à la fin.
window-close-keep = Garder la fenêtre ouverte
window-close-close = Fermer la fenêtre
# Titre du sélecteur de fichier pour un fichier playbook (.apbx).
file-dialog-open-playbook = Ouvrir un playbook Atlas (.apbx)
# Message affiché par Windows dans sa notification de redémarrage.
shutdown-comment = Atlas est installé. Windows redémarre pour terminer la configuration.

## Système

# « Windows 11 Professionnel, version 25H2 (build 26200.1234) ». Les trois valeurs sont du texte.
system-description = { $product }, version { $version } (build { $build })

## Page d'accueil

home-not-installed = Bienvenue dans Atlas
# Le titre lorsqu'Atlas est installé. $version est du texte.
home-version = Atlas { $version }
# $date est une date formatée.
home-installed-on = Installé le { $date }
home-status-checking = Recherche de mises à jour
home-status-offline = Impossible de rechercher les mises à jour
home-status-not-checked = Recherche de mises à jour non effectuée
home-status-update = Atlas { $version } est disponible
home-status-up-to-date = À jour
home-status-newest = Dernière version : Atlas { $version }
home-check-again = Vérifier à nouveau
# Bouton principal pendant qu'une installation est en cours ou en attente.
home-show-install = Voir la progression
home-continue-installing = Reprendre la configuration
home-update-to = Mettre à jour vers Atlas { $version }
home-reinstall = Réinstaller Atlas
home-install = Installer Atlas
home-start-over = Recommencer
home-security-reminder-title = Réactivez votre protection
home-security-reminder-message = Aucune installation n’est en cours. Ouvrez Sécurité Windows et réactivez la protection contre les falsifications, la protection en temps réel, la protection dans le cloud et l’envoi automatique d’un échantillon.
home-elevation-title = Atlas a besoin d’une autorisation pour lancer l’installation
home-state-error-title = Impossible de lire les informations sur votre installation d’Atlas
home-whats-new = Nouveautés d’Atlas { $version }
home-view-release = Voir les notes de version sur GitHub
home-released = Publié le { $date }
home-show-less = Afficher moins
home-show-full-notes = Afficher toutes les notes de version
home-your-install = Votre configuration Atlas
# Libellé de ligne : comment Atlas a été mis en place.
home-set-up = Méthode de configuration
home-set-up-during-oobe = Pendant l’installation de Windows
home-history = Historique des installations
# Une ligne d'historique. $version est du texte, $mode l'un des messages history-mode-*, $date une date et heure formatées.
home-history-entry = Atlas { $version } · { $mode } · { $date }
home-how-it-works = Préparons votre PC pour Atlas
home-step-1-title = Vérifiez votre PC
home-step-1-detail = Atlas vérifie Windows et télécharge les fichiers d’installation. Vos paramètres Windows restent inchangés.
home-step-2-title = Faites vos choix
home-step-2-detail = Choisissez comment Windows gère la protection et les mises à jour, puis ajoutez si vous le souhaitez des applications ou des réglages supplémentaires.
home-step-3-title = Suspendez la protection antivirus
home-step-3-detail = Atlas vous guide pour désactiver quatre paramètres de Sécurité Windows afin qu’ils ne bloquent pas l’installation.
home-step-4-title = Installez et redémarrez
home-step-4-detail =
    { $minutes ->
        [one] Environ une minute.
       *[other] Environ { $minutes } minutes.
    }
# Nom accessible d'une étape numérotée.
home-step-a11y = Étape { $number } : { $title }
home-github = Voir Atlas sur GitHub
home-discord = Rejoindre Atlas sur Discord
home-report-problem = Signaler un problème sur GitHub

## Comment une installation a été faite (d'après le document d'état)

mode-fresh = Première installation
mode-upgrade = Mise à jour depuis une version antérieure
mode-reapply = Réinstallation de la même version
mode-unknown = Installation
# Formes en minuscules utilisées dans une ligne d'historique.
history-mode-fresh = première installation
history-mode-upgrade = mise à jour
history-mode-reapply = réinstallation
history-mode-unknown = installation

## Avis sur la page d'accueil

notice-settings-reset-title = Atlas utilise ses paramètres par défaut
# $error est un message d'erreur brut (texte).
notice-settings-unreadable = Atlas n’a pas pu lire les paramètres enregistrés de l’application. Vos paramètres Windows n’ont pas changé. Détails : { $error }
# $file est un nom de fichier (texte).
notice-settings-damaged-kept = Le fichier de paramètres de l’application était endommagé et a été réinitialisé. Une copie de l’ancien fichier est conservée sous le nom { $file }. Détails : { $error }
notice-settings-damaged = Le fichier de paramètres de l’application était endommagé. Atlas utilise les valeurs par défaut pour le moment. Détails : { $error }
notice-settings-not-saved-title = Impossible d’enregistrer les paramètres de l’application
notice-session-unreadable-title = Impossible de vérifier l’installation précédente
# $path est un chemin de fichier (texte).
notice-session-unreadable-message = Atlas ne peut pas lire { $path } et doit savoir si une installation est encore en cours. En cas de doute, demandez de l’aide à la communauté Atlas avant de supprimer ce fichier. Ne le supprimez et ne réessayez qu’après avoir confirmé qu’aucune installation n’est en cours. Détails : { $error }

## Élévation administrateur

elevation-declined = L’autorisation n’a pas été accordée. Réessayez et choisissez Oui lorsque Windows demande si Atlas peut apporter des modifications.
elevation-declined-continue = L’autorisation n’a pas été accordée. Réessayez et choisissez Oui lorsque Windows demande si Atlas peut apporter des modifications. Vos choix de configuration sont enregistrés.
elevation-draft-not-saved = Atlas n’a pas pu enregistrer vos choix de configuration et n’a donc pas été relancé. Réessayez. Détails : { $error }

## Le parcours d'installation

step-ready = Préparation
step-options = Vos choix
step-security = Sécurité Windows
step-install = Installation
install-title = Configurer Atlas
# Nom accessible de la rangée d'étapes.
stepper-label = Étapes de la configuration d’Atlas
# Nom accessible d'une étape. $status est l'un des messages stepper-status-*.
stepper-step-a11y = Étape { $number } sur { $total }, { $title }, { $status }
stepper-status-completed = terminée
stepper-status-current = en cours
stepper-status-upcoming = à venir
# En-tête au-dessus du contenu de chaque étape.
step-heading = Étape { $number } sur { $total } : { $title }

## Étape 1 : Préparation

ready-banner-busy-title = Préparation de votre PC
ready-banner-busy-message = Atlas vérifie votre PC et prépare les fichiers d’installation.
ready-banner-blocked-title = Votre PC a besoin d’un peu de préparation
ready-banner-blocked-message = Suivez les instructions ci-dessous, puis choisissez Vérifier à nouveau.
ready-banner-no-package-title = Téléchargez Atlas pour continuer
ready-banner-no-package-message = Téléchargez la dernière version ci-dessous ou ouvrez un playbook Atlas (.apbx) déjà enregistré.
ready-banner-warnings-title = Quelques points à vérifier
ready-banner-warnings-message = Lisez les remarques ci-dessous et suivez les recommandations avant de continuer.
ready-banner-ok-title = Vous pouvez passer à vos choix
ready-banner-ok-message = Les vérifications ont réussi et vos fichiers d’installation sont prêts.

# Titre de carte et nom accessible de la liste des vérifications.
ready-this-pc = Vérifications du PC
ready-check-again = Vérifier à nouveau

package-title = Fichiers d’installation
# $received et $total sont des nombres de mégaoctets formatés (texte).
package-downloading = Téléchargement d’Atlas { $version } · { $received } sur { $total } Mo
package-unpacking-progress =
    { $total ->
        [one] Extraction · { $done } fichier sur { $total }
       *[other] Extraction · { $done } sur { $total } fichiers
    }
package-unpacking = Extraction
package-looking = Recherche de la dernière version d’Atlas.
package-none = Aucun fichier d’installation pour le moment. Un playbook (.apbx) contient les instructions et les fichiers dont Atlas a besoin.
# Mots d'état courts à côté du titre de la carte.
package-status-downloading = Téléchargement
package-status-unpacking = Extraction
package-status-failed = Échec de la préparation
package-status-ready = Prêts
package-status-checking = Vérification
package-status-missing = Non téléchargés
# Nom accessible de la barre de progression.
package-progress = Progression des fichiers d’installation
package-download-again = Télécharger à nouveau
package-download-version = Télécharger Atlas { $version }
package-download-newest = Télécharger la dernière version
package-open-file = Ouvrir un fichier playbook
# Provenance du package. $file est un nom de fichier, $path un chemin de dossier (texte).
package-from-release = Atlas { $version } a été téléchargé depuis GitHub et est prêt à être installé.
package-from-file = Atlas { $version } a été chargé depuis { $file } et est prêt à être installé.
package-unpacked = Atlas { $version } est prêt à être installé.
package-at = Fichiers d’installation : { $path }
package-none-yet = Aucun fichier d’installation sélectionné
acquire-no-asset = Atlas { $version } ne propose aucun fichier playbook à télécharger. Ouvrez un playbook Atlas (.apbx) déjà enregistré pour continuer.
acquire-unsupported = Cette application installe Atlas 0.6.0 et versions ultérieures. Pour installer Atlas { $version }, utilisez plutôt AME Wizard.
acquire-failed = Impossible de préparer les fichiers d’installation. Réessayez le téléchargement ou ouvrez un autre playbook Atlas (.apbx). Détails : { $error }

## Vérifications du système

check-administrator = Autorisation d’installer
check-supported-build = Compatibilité de Windows
check-pending-updates = Mises à jour Windows
check-pending-reboot = Redémarrage en attente
check-third-party-antivirus = Autre logiciel antivirus
check-internet = Connexion Internet
check-power = Alimentation
check-activation = Activation de Windows
# Nom accessible d'une ligne de vérification. $state est l'un des messages check-state-*.
check-a11y = { $title } : { $state }
# Fragments invariables : le titre qui précède peut être masculin ou féminin.
check-state-checking = vérification en cours
check-state-passed = vérification réussie
check-state-warning = attention requise
check-state-failed-blocking = action requise avant l’installation
check-state-failed = attention requise
check-state-unknown = vérification impossible
check-fix-windows-update = Ouvrir Windows Update
check-fix-network = Ouvrir les paramètres réseau
check-fix-power = Ouvrir les paramètres d’alimentation
check-fix-activation = Ouvrir les paramètres d’activation
# Cases que l'utilisateur coche lorsqu'une vérification n'a pas pu s'exécuter.
check-ack-updates = J’ai vérifié dans Windows Update : aucune mise à jour n’est en attente d’installation
check-ack-reboot = J’ai redémarré Windows et aucun autre redémarrage n’est nécessaire
check-ack-internet = Ce PC est connecté à Internet
check-ack-generic = J’ai vérifié ce point moi-même

detail-admin-ok = Atlas a l’autorisation d’apporter les modifications nécessaires à l’installation.
detail-admin-missing = Relancez Atlas en tant qu’administrateur, puis choisissez Oui lorsque Windows demande l’autorisation.
# $builds est une liste de numéros de build comme « 26100 ou 26200 » ; $build est celle de ce PC (texte).
detail-build-unsupported = Cette version d’Atlas nécessite la build Windows { $builds }. Votre PC utilise la build { $build }. Installez une version compatible de Windows avant de continuer.
detail-updates-none = Aucune mise à jour Windows n’est en attente d’installation.
# $titles liste jusqu'à deux noms de mises à jour (texte) ; $count est le total.
detail-updates-pending =
    { $count ->
        [1] Installez d’abord cette mise à jour : { $titles }.
        [2] Installez d’abord ces mises à jour : { $titles }.
       *[other] Installez d’abord { $count } mises à jour, dont { $titles }.
    }
detail-updates-unknown = Impossible de rechercher les mises à jour Windows. Ouvrez Windows Update puis, si aucune mise à jour n’est en attente, confirmez-le ci-dessous. ({ $error })
detail-reboot-none = Windows n’a pas besoin de redémarrer pour le moment.
detail-reboot-pending = Redémarrez votre PC pour terminer les modifications en attente, puis rouvrez Atlas et vérifiez à nouveau.
detail-reboot-unknown = Impossible de vérifier si Windows doit redémarrer. Redémarrez votre PC, puis rouvrez Atlas et vérifiez à nouveau. ({ $error })
detail-antivirus-none = Aucun autre logiciel antivirus n’a été détecté.
# $products est une liste de noms de produits (texte).
detail-antivirus-found = Un logiciel antivirus peut bloquer l’installation : { $products }. Désinstallez ce logiciel avant de continuer.
detail-antivirus-unknown = Impossible de vérifier la présence d’autres antivirus. Vérifiez vos applications installées avant de continuer. ({ $error })
detail-internet-ok = Ce PC est connecté à Internet. Conservez cette connexion pendant qu’Atlas télécharge et installe des logiciels.
detail-internet-missing = Connectez-vous à Internet, puis vérifiez à nouveau.
detail-power-mains = Votre PC est branché sur le secteur. Laissez-le branché jusqu’à la fin de l’installation.
detail-power-battery = Branchez votre PC sur le secteur pour qu’il reste allumé pendant toute l’installation.
detail-power-unknown = Impossible de vérifier l’alimentation. Si vous utilisez un ordinateur portable, branchez-le avant de continuer.
detail-activation-ok = Windows est activé. Atlas n’y changera rien.
detail-activation-missing = Windows n’est pas activé. Vous pouvez continuer, mais Atlas n’activera pas Windows à votre place.
detail-activation-no-licence = Windows n’a signalé aucune licence. Vous pouvez continuer ; Atlas ne modifiera pas l’état d’activation.
detail-activation-unknown = Impossible de vérifier l’activation de Windows. Vous pouvez continuer ; Atlas ne modifiera pas l’état d’activation. ({ $error })

## Étape 2 : Vos choix

options-progress = Choix { $number } sur { $total }
options-progress-extras = Choix { $number } sur { $total } : options facultatives
# Noms courts de chaque décision (lignes de résumé) et question posée par chaque écran.
screen-defender-title = Microsoft Defender
screen-defender-question = Conserver la protection antivirus ?
screen-mitigations-title = Sécurité du processeur
screen-mitigations-question = Conserver les protections du processeur intégrées à Windows ?
screen-updates-title = Windows Update
screen-updates-question = Comment Windows doit-il installer les mises à jour ?
screen-browser-title = Navigateur
screen-power-title = Alimentation et sécurité
screen-apps-title = Applications
screen-optional-apps-title = Applications facultatives
screen-choose-one-title = Choisissez une option
screen-extras-title = Options facultatives
screen-extras-question = Choisissez les options qui vous intéressent
# Question pour un choix obligatoire pour lequel cette application n'a pas de formulation spécifique.
screen-generic-question = Choisissez une option pour { $title }
learn-more-defender = En savoir plus sur Microsoft Defender
learn-more-mitigations = En savoir plus sur la sécurité du processeur
learn-more-updates = En savoir plus sur Windows Update
learn-more-browser = En savoir plus sur les navigateurs
learn-more-power = En savoir plus sur l’alimentation et la sécurité
learn-more-apps = En savoir plus sur les applications
learn-more-eclean = Comment eclean fonctionne avec AtlasOS
learn-more-generic = Lire le guide de configuration
# Une ligne sous la réponse choisie : ce que cela implique pour le PC.
consequence-defender-enable = Conserve l’antivirus intégré à Windows pour aider à protéger votre PC contre les virus et autres menaces.
consequence-defender-disable = Supprime Microsoft Defender. Votre PC n’aura aucune protection antivirus tant que vous n’aurez pas installé un autre antivirus.
consequence-mitigations-default = Conserve les protections par défaut de Windows contre les attaques qui exploitent le fonctionnement de votre processeur.
consequence-mitigations-disable = Désactive ces protections et réduit la sécurité. Les performances dépendent de votre processeur et peuvent se dégrader.
consequence-auto-updates-disable = Vous devrez ouvrir Windows Update et installer les mises à jour vous-même. Les notifications de mise à jour restent activées.
consequence-auto-updates-default = Windows installera les mises à jour automatiquement, y compris les correctifs de sécurité.

## Texte du playbook
## Le package playbook contient son propre texte anglais pour chaque option. Ces
## libellés et explications ne sont utilisés que si le texte du package correspond
## à i18n/playbook-source.ftl. Un futur package formulé autrement conserve ses
## propres mots plutôt que de recevoir une description peut-être obsolète.

playbook-option-defender-enable = Conserver Microsoft Defender (recommandé)
playbook-option-defender-disable = Supprimer Microsoft Defender
playbook-option-mitigations-default = Conserver les protections par défaut (recommandé)
playbook-option-mitigations-disable = Désactiver les protections du processeur
playbook-option-auto-updates-disable = Installer les mises à jour moi-même
playbook-option-auto-updates-default = Installer les mises à jour automatiquement
playbook-option-disable-hibernation = Désactiver la mise en veille prolongée
playbook-option-disable-power-saving = Désactiver les économies d’énergie
playbook-option-disable-core-isolation = Désactiver la sécurité basée sur la virtualisation (VBS)
playbook-option-remove-snipping-tool = Supprimer l’Outil Capture d’écran
playbook-option-uninstall-edge = Supprimer Microsoft Edge
playbook-option-install-another-browser = Installer un navigateur
playbook-option-install-toolbox = Installer Atlas Toolbox
playbook-option-browser-brave = Brave
playbook-option-browser-librewolf = LibreWolf
playbook-option-browser-firefox = Firefox
playbook-option-browser-chrome = Chrome
playbook-page-defender-enable-description = Microsoft Defender est l’antivirus intégré à Windows. Il est recommandé de le conserver. Ne le supprimez que si vous comprenez les risques et prévoyez d’utiliser un autre antivirus.
playbook-page-mitigations-default-description = Ces protections, aussi appelées atténuations de sécurité, aident à se défendre contre les vulnérabilités du processeur. Il est recommandé de conserver les paramètres par défaut de Windows.
playbook-page-auto-updates-disable-description = Les mises à jour Windows incluent des correctifs de sécurité. Windows peut les installer automatiquement, ou vous pouvez les installer vous-même.
consequence-install-toolbox = Ajoutez Atlas Toolbox pour gérer plus facilement vos paramètres Atlas. Toolbox est en version bêta : certaines fonctionnalités peuvent être inachevées.
playbook-page-browser-brave-description = Choisissez un navigateur à installer. Atlas ne modifiera pas les paramètres de votre navigateur.

## Étape 3 : Sécurité Windows

security-banner-reading-title = Vérification de Sécurité Windows
security-banner-reading-message = Atlas vérifie les quatre paramètres de protection ci-dessous.
security-banner-off-title = Les quatre paramètres de protection sont désactivés
security-banner-off-message = Vous pouvez maintenant revoir vos choix avant l’installation.
security-banner-readable-off-title = Les paramètres qu’Atlas a pu vérifier sont désactivés
security-banner-readable-off-message = Vérifiez les autres paramètres dans Sécurité Windows.
security-banner-on-title = Désactivez temporairement la protection antivirus
security-banner-on-message = Ces protections peuvent bloquer les modifications qu’Atlas doit apporter.
# Le nom de la page dans Sécurité Windows.
security-list-title = Paramètres de protection contre les virus et menaces
security-switch-off = Désactivé
security-switch-on = Activé
security-switch-unreadable = Vérification impossible
security-switch-reading = Vérification
security-all-off = Tous désactivés
# Nom accessible d'une ligne de paramètre. $state est l'un des messages security-switch-*.
security-a11y = { $title } : { $state }
# Éléments du résumé « 2 encore activés, 1 non vérifiable ».
security-count-still-on =
    { $count ->
        [one] { $count } encore activé
       *[other] { $count } encore activés
    }
security-count-unreadable =
    { $count ->
        [one] { $count } non vérifiable
       *[other] { $count } non vérifiables
    }
security-count-join = { $a }, { $b }
security-unknown-title = Confirmez les paramètres qu’Atlas n’a pas pu vérifier
security-unknown-message = Après avoir vérifié dans Sécurité Windows que les quatre paramètres sont désactivés, confirmez-le ci-dessous.
security-acknowledge = J’ai vérifié dans Sécurité Windows que les quatre paramètres sont désactivés
security-unknown-unelevated-title = Atlas a besoin d’une autorisation pour vérifier la protection
security-unknown-unelevated-message = Relancez Atlas en tant qu’administrateur pour qu’il puisse lire les paramètres de Microsoft Defender.
# Les quatre paramètres, nommés exactement comme dans Sécurité Windows.
protection-tamper = Protection contre les falsifications
protection-tamper-why = Désactivez-la en premier pour que Defender autorise la modification de ses paramètres de protection.
protection-realtime = Protection en temps réel
protection-realtime-why = Suspendez l’analyse des fichiers pour que Defender ne bloque pas les fichiers d’installation d’Atlas.
protection-cloud = Protection dans le cloud
protection-cloud-why = Suspendez les vérifications en ligne qui pourraient bloquer les fichiers d’installation d’Atlas.
protection-samples = Envoi automatique d’un échantillon
protection-samples-why = Empêchez Defender d’envoyer automatiquement des fichiers d’Atlas à Microsoft pour analyse.

## Étape 4 : Installation

install-preparing-title = Dernière vérification avant l’installation
install-preparing-message = Atlas vérifie à nouveau votre PC et vos paramètres de protection avant d’apporter des modifications.
install-installing = Installation
install-running = En cours
# Nom accessible de la barre de progression.
install-progress = Progression de l’installation
phase-preflight = Vérification de votre PC et préparation des fichiers
phase-staging = Préparation des fichiers d’installation
phase-applying = Configuration de Windows. Laissez votre PC allumé.
phase-done = Finalisation de la configuration
outcome-succeeded-title = Atlas est installé
outcome-lost-title = Impossible de confirmer le résultat de l’installation
outcome-failed-title = L’installation ne s’est pas terminée
outcome-succeeded = Redémarrez votre PC pour terminer la configuration d’Atlas.
outcome-requirements = Votre PC ne répond pas aux conditions requises pour l’installation. Aucune modification n’a été apportée. Revenez à l’étape Préparation et vérifiez à nouveau.
outcome-not-elevated = Aucune modification n’a été apportée. Relancez Atlas en tant qu’administrateur, puis réessayez.
outcome-failed-preflight = L’installation s’est arrêtée avant toute modification. Ouvrez le fichier journal pour voir ce qui s’est passé, puis réessayez.
outcome-failed-staging = L’installation s’est arrêtée pendant la préparation des fichiers, avant toute modification de Windows. Ouvrez le fichier journal pour voir ce qui s’est passé, puis réessayez.
outcome-failed-applying = Certaines modifications ont peut-être déjà été appliquées. Si vous vous arrêtez ici, réactivez dans Sécurité Windows les protections que vous avez désactivées, si elles sont toujours disponibles.
outcome-not-started = Le programme d’installation n’a pas démarré à temps. Aucune modification n’a été apportée. Choisissez Réessayer.
outcome-lost = Le programme d’installation s’est arrêté sans indiquer de résultat, et certaines modifications ont peut-être déjà été appliquées. Ouvrez le fichier journal pour voir ce qui s’est passé, puis choisissez Réessayer pour reprendre l’installation.
restart-now-message = Windows redémarre pour terminer la configuration d’Atlas.
restart-countdown =
    { $seconds ->
        [one] Windows redémarre dans { $seconds } seconde pour qu’Atlas termine sa configuration.
       *[other] Windows redémarre dans { $seconds } secondes pour qu’Atlas termine sa configuration.
    }
restart-stopped = Redémarrage automatique annulé. Enregistrez votre travail, puis redémarrez votre PC pour terminer la configuration d’Atlas.
restart-needed = Enregistrez votre travail, puis redémarrez Windows pour terminer la configuration d’Atlas.
restart-dont-now = Redémarrer plus tard
restart-now = Redémarrer maintenant
# Nom accessible de la barre de compte à rebours.
restart-progress = Temps restant avant le redémarrage
restart-start-failed = Impossible de redémarrer Windows. Enregistrez votre travail, puis redémarrez depuis le menu Démarrer. Détails : { $error }
preflight-title = L’installation n’a pas démarré
preflight-invalid-options = Atlas n’a pas pu utiliser ces choix de configuration. Revenez à l’étape Vos choix pour les revoir, puis réessayez. Détails : { $error }
# $problems est une ou deux phrases construites à partir de preflight-problem et preflight-security.
preflight-changed = L’état de votre PC a changé depuis les vérifications précédentes. Résolvez les points suivants avant de réessayer. { $problems }
preflight-problem = { $title } : { $detail }
# $summary est le résumé de Sécurité Windows, par exemple « 2 encore activés ».
preflight-security = Sécurité Windows : { $summary }.
preflight-busy = Une autre fenêtre Atlas démarre une installation. Patientez un instant, puis réessayez.
preflight-record-unreadable = Atlas n’a pas pu vérifier si l’installation précédente est encore en cours et n’en a donc pas démarré une autre. Fermez puis rouvrez Atlas pour obtenir les instructions de récupération. Détails : { $error }
preflight-refused = Impossible de démarrer le programme d’installation. Aucune modification n’a été apportée. Détails : { $error }
go-to-ready = Revenir à l’étape Préparation
go-to-options = Revenir à l’étape Vos choix
output-problem-title = Impossible de lire la progression de l’installation
output-problem-message = Atlas n’a pas pu lire le journal. Cela ne signifie pas que l’installation s’est arrêtée. Laissez votre PC allumé et essayez d’ouvrir le fichier journal. Détails : { $error }
install-elevate-title = Atlas a besoin d’une autorisation pour lancer l’installation
install-no-package-title = Choisissez d’abord vos fichiers d’installation
install-no-package-message = Revenez à l’étape Préparation pour télécharger Atlas ou ouvrir un playbook (.apbx) enregistré.
install-security-title = Vérifiez la protection antivirus avant d’installer
install-security-reading = Nouvelle vérification des quatre paramètres de protection.
install-security-message = { $summary }. Ouvrez Sécurité Windows et assurez-vous que les quatre paramètres sont désactivés avant de continuer.
summary-this-install = Résumé de l’installation
summary-try-again = À vérifier avant de réessayer
summary-ready = Vérifiez votre configuration Atlas
summary-activation = Activation
summary-activation-ok = Activé. Atlas n’y changera rien.
summary-activation-missing = Non activé. Vous pouvez continuer, mais Atlas n’activera pas Windows.
summary-activation-unknown = Atlas ne modifiera pas l’état d’activation de Windows.
summary-duration = Durée estimée
summary-duration-value =
    { $minutes ->
        [one] { $minutes } minute, puis un redémarrage
       *[other] { $minutes } minutes, puis un redémarrage
    }
summary-restart-checkbox = Redémarrer mon PC automatiquement après l’installation
summary-show-command = Afficher la commande d’installation
summary-hide-command = Masquer la commande d’installation
summary-command-unavailable = Impossible de préparer la commande d’installation. Détails : { $error }
summary-not-chosen = Aucun choix pour le moment
# Nom accessible d'un lien Modifier. $title est un message screen-*-title.
summary-change-a11y = Modifier le choix { $title }
footer-still-checking = Préparation de l’installation
footer-fix-items = Terminez les vérifications ci-dessus pour continuer
footer-need-package = Téléchargez Atlas ou ouvrez un playbook pour continuer
footer-reading-security = Vérification des paramètres de protection
button-checking = Vérification
button-installing = Installation
button-install = Installer Atlas
log-earlier-lines =
    { $count ->
        [one] { $count } ligne précédente se trouve dans le fichier journal.
       *[other] { $count } lignes précédentes se trouvent dans le fichier journal.
    }
# Ajouté lorsque le journal est copié. $path est un chemin de fichier (texte).
log-full-log-note = (journal complet : { $path })

## La vue d'installation en cours

installing-checking-title = Dernière vérification
installing-checking-line = Atlas vérifie votre PC avant d’apporter des modifications. Cela peut prendre un instant.
installing-title = Installation d’Atlas
installing-phase-preflight = Vérification de votre PC et préparation des fichiers d’installation.
installing-phase-staging = Préparation des fichiers d’installation. Laissez votre PC allumé.
installing-phase-applying = Configuration de Windows selon vos choix. Laissez votre PC allumé et branché.
installing-phase-done = Finalisation de l’installation. Laissez votre PC allumé.
installing-installed-title = Atlas est installé
# $time est une heure formatée.
installing-started-just-now = Démarrage à { $time }, il y a moins d’une minute
installing-started-minutes =
    { $minutes ->
        [one] Démarrage à { $time }, il y a une minute
       *[other] Démarrage à { $time }, il y a { $minutes } minutes
    }

## La fenêtre « Atlas est installé » après le redémarrage

installed-title-version = Atlas { $version } est installé
installed-title = Atlas est installé
installed-ready = C’est terminé. Votre PC est prêt à être utilisé avec Atlas.
installed-open-atlas = Voir votre configuration Atlas

## Paramètres

settings-title = Paramètres
settings-theme = Thème de l’application
settings-theme-system = Comme Windows
settings-theme-light = Clair
settings-theme-dark = Sombre
settings-theme-contrast-note = Atlas utilise les couleurs de votre thème de contraste Windows.
settings-theme-mica-note = Pour afficher l’arrière-plan translucide, choisissez le même thème clair ou sombre que Windows.
settings-language = Langue
settings-language-system = Comme Windows
# Sous « Comme Windows » : la langue que cela donne. $language est le nom de la langue dans cette langue.
settings-language-system-detail = Avec « Comme Windows » : { $language }
# Sous une langue traduite mais pas encore relue par un locuteur natif ; ces langues ne sont jamais choisies automatiquement.
settings-language-preview = Aperçu · en attente de relecture linguistique
preview-notice = { $language } est une traduction en aperçu.
preview-notice-switch = Passer en anglais
preview-notice-language = Changer de langue
# $tag est une balise de langue (texte).
settings-language-unavailable = { $tag } n’est pas disponible dans cette version d’Atlas. L’anglais est affiché pour le moment et votre choix de langue est conservé.
# $languages est la liste des langues d'affichage de Windows (texte).
settings-language-windows-unmatched = Atlas ne prend pas encore en charge vos langues d’affichage Windows ({ $languages }). L’anglais est affiché pour le moment.
settings-language-windows-unavailable = Impossible de vérifier votre langue d’affichage Windows. Atlas utilise l’anglais pour le moment. Détails : { $error }
# $locale est le nom du format régional dans sa propre langue, par exemple « français (France) ».
settings-language-formats = Les nombres, les dates et les heures suivent votre format régional Windows ({ $locale }).
settings-language-contribute = Aider à traduire Atlas sur GitHub
settings-installing = Installation
settings-restart-label = Redémarrer mon PC automatiquement après l’installation
settings-restart-locked = Vous pourrez modifier ce réglage une fois l’installation terminée.
settings-restart-description = Un redémarrage est nécessaire pour terminer la configuration. Si le redémarrage automatique est activé, enregistrez votre travail avant d’installer.
settings-about = À propos
settings-about-app = Atlas Manager
settings-about-data = Fichiers de l’application
settings-about-licence = Licence
settings-about-licence-value = GPL-3.0, libre et open source
settings-view-source = Voir le code source sur GitHub
settings-open-data-folder = Ouvrir le dossier de l’application

## Choix facultatifs : explications affichées avant la sélection.

consequence-disable-hibernation = Libère l’espace disque utilisé pour enregistrer votre session lors de la mise en veille prolongée. La veille prolongée et le démarrage rapide ne seront plus disponibles.
consequence-disable-power-saving = Désactive les fonctions d’économie d’énergie. Votre PC peut consommer davantage, chauffer plus et avoir une autonomie réduite.
consequence-disable-core-isolation = Désactive une couche de sécurité supplémentaire de Windows, dont l’intégrité de la mémoire. Cela réduit la protection et peut affecter les applications ou les jeux qui en ont besoin.
consequence-remove-snipping-tool = Supprime l’application Windows de capture d’écran et d’enregistrement vidéo de l’écran.
consequence-uninstall-edge = Supprime le navigateur Microsoft Edge. Assurez-vous d’avoir un autre navigateur ou choisissez-en un ci-dessous.
consequence-install-another-browser = Choisissez un navigateur ci-dessous et Atlas l’installera pour vous.

# Introduction sur la page d'accueil avant l'installation d'Atlas.
home-intro = Atlas ajuste Windows pour réduire l’activité en arrière-plan et les distractions. Nous vous guidons dans les vérifications et les choix avant toute modification.

detail-build-missing = Ce playbook ne déclare aucune build Windows prise en charge. Choisissez un playbook complet plutôt qu’un package LocalTest.
## ISO creation (Beta)
iso-home-title = Support d’installation de Windows
iso-home-description = Créez une image ISO de Windows avec Atlas pour une nouvelle installation sur ce PC ou un autre.
iso-open = Créer une ISO avec Atlas
iso-title = Créer une ISO avec Atlas
iso-beta = Bêta
iso-beta-description = Testez l’ISO dans une machine virtuelle avant de l’utiliser sur un PC. Sauvegardez vos fichiers avant d’installer Windows.
iso-admin-description = Des droits d’administrateur sont nécessaires pour lire les images Windows et créer un support d’installation.
iso-files-description = Choisissez une ISO Windows 11 x64 non modifiée, un playbook Atlas (.apbx) et un nouveau nom de fichier pour le résultat.
iso-source = ISO Windows
iso-package = Playbook Atlas (0.6+)
iso-output = Enregistrer la nouvelle ISO sous
iso-no-file = Aucun fichier sélectionné
iso-browse = Parcourir
iso-save-as = Enregistrer sous
iso-inspect = Vérifier les fichiers
iso-mode-title = Préférences de Windows et Atlas
iso-mode-interactive = Choisir les réglages Atlas après la connexion
iso-mode-interactive-description = Après la connexion, Atlas vous aide à mettre à jour Windows et les applications du Store, à choisir vos réglages et à appliquer Atlas.
iso-mode-before = Choisir les réglages Atlas maintenant
iso-mode-before-description = Enregistrez vos réglages Atlas dans l’ISO. Après la connexion, mettez à jour Windows et les applications du Store, puis appliquez Atlas avec ces réglages.
iso-package-unsupported-title = Choisir un playbook plus récent
iso-package-unsupported = La configuration par ISO nécessite Atlas 0.6 ou une version ultérieure prenant en charge les ISO. Choisissez un playbook compatible.
iso-atlas-options = Paramètres Atlas
iso-review = Vérifier l’ISO
iso-review-description = Atlas crée une nouvelle ISO et conserve l’originale. Démarrez sur la nouvelle ISO pour installer Windows. Sa création n’installe pas Atlas sur ce PC.
iso-review-files = Fichiers
iso-review-package = Playbook Atlas
iso-review-output = Nouvelle ISO
iso-review-editions = Éditions
iso-review-size = Taille
iso-review-size-value = { $size } Mo
iso-review-account = Nom du compte
iso-review-target = Installer sur
iso-review-drivers = Pilotes
iso-create = Créer l’ISO
iso-stage-inspect = Vérification de l’image Windows
iso-stage-copy = Copie des fichiers Windows
iso-stage-inject = Ajout d’Atlas
iso-stage-master = Création de l’ISO
iso-stage-verify = Vérification du résultat
iso-stage-cleanup = Finalisation
iso-progress-description = Gardez l’application ouverte. Le traitement des images volumineuses peut prendre du temps.
iso-cancel = Annuler la création
iso-cancelling = En attente d’un point d’arrêt sûr
iso-cancelled = Création de l’ISO annulée
iso-cancelled-description = Votre ISO d’origine est conservée. Le journal de diagnostic indique les fichiers temporaires qu’il reste éventuellement à supprimer.
iso-complete = Votre ISO est prête
iso-complete-description = Testez-la dans une machine virtuelle, puis utilisez-la pour créer un support d’installation de Windows.
iso-open-folder = Afficher dans le dossier
iso-failed = La création de l’ISO n’a pas pu aboutir
iso-failed-description = Ouvrez le diagnostic pour connaître la cause de l’échec. Corrigez le problème, puis réessayez avec un nouveau nom de fichier.
iso-diagnostics = Ouvrir le diagnostic
iso-close-title = La création de l’ISO est en cours
iso-close-message = Gardez cette fenêtre ouverte jusqu’à la fin de la création ou de l’annulation. L’annulation attend que l’opération en cours puisse s’arrêter sans risque.
iso-keep-open = Garder ouvert
prepare-title = Mettre à jour Windows et les applications du Store
prepare-description = Avant d’appliquer Atlas, installez les mises à jour de Windows et mettez à jour le Microsoft Store et toutes ses applications installées. Les applications du Store peuvent se fermer pendant leur mise à jour.
prepare-complete = Windows et les applications du Store sont à jour.
prepare-reboot = Windows doit redémarrer. Vos choix pour Atlas seront enregistrés. Recherchez à nouveau les mises à jour après votre connexion.
prepare-failed = Certaines mises à jour n’ont pas pu se terminer. Consultez le journal de diagnostic, corrigez les erreurs de Windows ou du Store, puis réessayez.
prepare-cancelled = La préparation a été arrêtée. Recherchez à nouveau les mises à jour avant de continuer.
prepare-windows-search = Recherche de mises à jour Windows…
prepare-windows-download = Téléchargement des mises à jour Windows…
prepare-windows-install = Installation des mises à jour Windows…
prepare-store-search = Vérification du Microsoft Store…
prepare-store-install = Mise à jour du Microsoft Store et de ses applications…
prepare-stop-description = L’arrêt attend la fin de la mise à jour en cours. Gardez Atlas ouvert jusque-là.
prepare-stop = Arrêter après cette opération
prepare-restart = Redémarrer et continuer
prepare-start = Rechercher et installer les mises à jour
iso-username = Nom du compte local
iso-account-description = Windows vous demandera de définir un mot de passe après la réinstallation.
iso-username-placeholder = Votre nom
iso-account-invalid = Utilisez 1 à 20 caractères, sans espaces au début ou à la fin ni symboles interdits dans les noms de comptes Windows.
iso-privacy-defaults = La configuration de Windows désactive automatiquement le partage facultatif de données et les offres personnalisées.
prepare-drivers = Comment installer les pilotes ?
prepare-drivers-auto = Obtenir les pilotes via Windows Update
prepare-drivers-auto-detail = Windows recherche les pilotes adaptés à votre matériel. Recommandé pour la plupart des PC.
prepare-drivers-manual = Installer les pilotes moi-même
prepare-drivers-manual-detail = Bloque le téléchargement de pilotes via Windows Update. Vous devrez les obtenir vous-même ; les pilotes déjà installés sont conservés.
prepare-network-needed = Connectez-vous en Wi-Fi ou par Ethernet avec une connexion non limitée, puis réessayez. Si le Wi-Fi est absent, installez d’abord le pilote réseau.
prepare-network-settings = Ouvrir les paramètres réseau
iso-target-title = Sur quel PC allez-vous réinstaller Windows ?
iso-target-this = Ce PC
iso-target-other = Un autre PC
iso-copy-network = Inclure les pilotes réseau de ce PC
iso-network-detail = Réutilise les pilotes Wi-Fi et Ethernet de ce PC pendant l’installation de Windows. Vous devrez ensuite vous reconnecter au Wi-Fi.
iso-network-source = Source des pilotes réseau
iso-network-installed = Utiliser les pilotes installés
iso-network-updated = Rechercher d’abord sur Windows Update
iso-network-updated-detail = Télécharge les pilotes compatibles proposés par Windows Update et conserve les pilotes installés en secours. Nécessite une connexion non limitée.
iso-stage-network-drivers = Préparation des pilotes réseau…
iso-network-failed = Impossible de préparer les pilotes réseau. Consultez le diagnostic ou revenez en arrière pour changer l’option des pilotes réseau.
iso-mode-desktop = Terminer la configuration avant le bureau
iso-mode-desktop-description = Choisissez les paramètres d’Atlas maintenant. Après la connexion, terminez les mises à jour et la configuration avant d’ouvrir le bureau Windows.
desktop-setup-description = Terminez la configuration du PC. Vos choix Atlas sont enregistrés ; vous pouvez revenir à Windows si nécessaire.
desktop-setup-exit = Continuer dans Windows

# Windows installation USB (Beta)
usb-title = Créer une clé d’installation
usb-existing = Créer une clé USB depuis une ISO existante
usb-description = Créez une clé USB de démarrage Windows 11 25H2 pour installer Windows et Atlas sur votre PC.
usb-choose-iso = Choisir une ISO
usb-drive = Clé USB
usb-empty = Branchez une clé USB, puis actualisez la liste. Seuls les supports USB accessibles en écriture et ne contenant pas le Windows en cours d’utilisation sont affichés.
usb-refresh = Actualiser
usb-drive-detail = { $size } Go · { $volumes } · N° de série : { $serial }
usb-review = Vérifier la clé USB
usb-erase-title = Effacer cette clé USB ?
usb-erase-description = Tous les fichiers et partitions de { $drive } ({ $size } Go) seront définitivement effacés. Votre ISO sera conservée.
usb-layout = L’installation de Windows utilise jusqu’à 32 Go. L’espace restant sera non alloué. Cette clé est destinée aux PC démarrant en UEFI.
usb-ack = Je comprends que tout le contenu de cette clé USB sera effacé.
usb-write = Effacer et créer la clé
usb-stage-prepare = Préparation des fichiers d’installation…
usb-stage-format = Formatage de la clé USB…
usb-stage-copy = Copie des fichiers d’installation…
usb-stage-verify = Vérification de la clé USB…
usb-working = Gardez Atlas ouvert et la clé branchée. L’annulation attend que l’opération en cours puisse s’arrêter sans risque. Une clé incomplète ne permet pas d’installer Windows.
usb-failed = La création de la clé USB a échoué. Vérifiez son branchement et ouvrez le diagnostic pour en savoir plus. Sélectionnez à nouveau la clé pour réessayer.
usb-cancelled = La création de la clé USB s’est arrêtée. Elle peut contenir des fichiers d’installation incomplets. Recréez-la avant d’installer Windows.
usb-complete = Votre clé est prête et tous les fichiers ont été vérifiés. Éjectez-la, branchez-la au PC à réinstaller, puis sélectionnez-la dans son menu de démarrage UEFI.
usb-eject = Éjecter la clé USB
usb-ejected = Vous pouvez débrancher la clé USB en toute sécurité. Pour installer Windows, sélectionnez-la dans le menu de démarrage UEFI de votre PC.
usb-eject-failed = Windows n’a pas pu éjecter la clé. Fermez les fichiers ou fenêtres qui l’utilisent, puis réessayez.
ready-fresh-title = Commencez par une nouvelle installation de Windows
ready-fresh-description = Atlas nécessite une nouvelle installation de Windows, sauf pour les mises à niveau d’Atlas prises en charge. Une nouvelle installation d’Atlas 0.6 nécessite Windows 11 25H2. Sauvegardez vos fichiers avant de réinstaller Windows.
detail-edition-unsupported = Utilisez Windows 11 Pro, Pro for Workstations ou Enterprise. Les éditions Home, LTSC et Server ne sont pas prises en charge. Si votre édition n’a pas pu être identifiée, résolvez ce problème avant de continuer.
install-source-title = Installation indisponible
install-source-unsupported = Atlas { $source } ne peut pas être mis à jour directement vers { $target }. Réinstallez Windows pour utiliser cette version.
install-source-unknown = Atlas n’a pas pu vérifier l’état de l’installation. Résolvez toute installation inachevée et consultez le diagnostic avant de réessayer.
iso-edition-selection = Seules les éditions prises en charge sont incluses. Lors de l’installation de Windows, choisissez une édition pour laquelle vous disposez d’une licence Windows.
detail-windows-preview = Les builds Insider ne sont pas pris en charge. Utilisez une version publique de Windows 11.
detail-windows-release-unknown = Atlas n’a pas pu confirmer que ce build de Windows est une version publique. Connectez-vous à Internet et relancez la vérification.
iso-release-unknown = Atlas n’a pas pu confirmer que cette ISO contient une version publique de Windows 11 25H2. Connectez-vous à Internet et réessayez, ou choisissez un support d’installation officiel.
prepare-previous-worker = Une mise à jour précédente est toujours en cours. Atlas attendra qu’elle se termine avant de vous laisser réessayer.

ready-used-windows-title = Réinstallez Windows avant de continuer
ready-used-windows-description = Cette installation de Windows présente des signes d’utilisation antérieure. Y installer Atlas n’est pas pris en charge et est fortement déconseillé. Continuez uniquement si vous comprenez les risques.
ready-used-windows-dismiss = Je comprends les risques
playbook-option-install-eclean = Installer eclean
consequence-install-eclean = Un outil de maintenance de l’équipe d’AtlasOS pour entretenir votre PC après l’installation. Examinez les fichiers inutiles et les applications au démarrage. Nécessite un compte et une connexion Internet.

prepare-resumed = Windows a redémarré. Vos choix Atlas ont été restaurés. Poursuivez les mises à jour avant d’installer Atlas.
prepare-continue = Poursuivre les mises à jour
prepare-saving-restart = Enregistrement de vos choix et configuration de la réouverture d’Atlas après le redémarrage de Windows…
prepare-restart-save-failed = Vos choix n’ont pas pu être enregistrés. Réessayez avant de redémarrer.
prepare-restart-registration-failed = Vos choix sont enregistrés, mais la réouverture automatique n’a pas pu être configurée. Réessayez ou redémarrez Windows et ouvrez Atlas manuellement.
prepare-restart-failed = Windows n’a pas pu redémarrer. Réessayez ou redémarrez depuis Windows. Vos choix sont enregistrés et Atlas est configuré pour se rouvrir.
