### Atlas Manager: French (fr). Preview translation, revised on 1 October 2026 from the en-GB source (i18n/en-GB/atlas.ftl).
###
### Conventions pour cette langue : vouvoiement ; espace insécable (U+00A0) avant
### « : ; ? ! » et à l'intérieur des guillemets « » ; apostrophe typographique (’) ;
### boutons à l'infinitif ; titres et libellés sans point final ; « relancer »
### désigne l'application Atlas, « redémarrer » désigne le PC ou Windows.
### Le fichier .apbx est le « package Atlas » (masculin), puis « le package » ;
### « playbook » seulement là où un texte explique le terme d'AME Wizard. Les
### interrupteurs de Sécurité Windows sont des « paramètres de protection ».

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
# Accessible name of a Show details or Hide details toggle. $action is common-show-details or
# common-hide-details; $section is the title of the card it opens.
common-details-a11y = { $action }, { $section }
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
list-and = { $a } et { $b }
# Accessible name of a message bar that announces itself: its title, then its message.
infobar-a11y = { $title }. { $message }

## Fenêtre

# Boîte de dialogue affichée si la fenêtre est fermée pendant une installation.
window-close-title = Fermer la fenêtre pendant l’installation ?
window-close-message = L’installation continue en arrière-plan. Rouvrez Atlas pour suivre sa progression et voir le résultat. Laissez votre PC allumé jusqu’à la fin.
# Instead of window-close-message when the installation restarts the PC afterwards: only an
# open Atlas window restarts it, so closing the window cancels that.
window-close-message-restart = L’installation continue en arrière-plan, mais votre PC ne redémarrera pas automatiquement tant qu’Atlas est fermé. Rouvrez Atlas pour suivre sa progression et voir le résultat. Laissez votre PC allumé jusqu’à la fin.
window-close-keep = Garder la fenêtre ouverte
window-close-close = Fermer la fenêtre
# Boîte de dialogue affichée si la fenêtre est fermée pendant les dernières vérifications, avant le démarrage du programme d'installation ; window-close-keep et window-close-close sont ses boutons.
window-close-preparing-title = Fermer avant le début de l’installation ?
window-close-preparing-message = Atlas vérifie encore votre PC et n’a pas commencé l’installation. Si vous fermez maintenant, l’installation ne démarrera pas. Rouvrez Atlas pour continuer.
prepare-close-title = Des mises à jour sont encore en cours
# "Stop updating" is prepare-stop, the dialog's other button.
prepare-close-message = Gardez Atlas ouvert pendant les mises à jour. Si vous choisissez Arrêter les mises à jour, elles s’arrêteront après l’opération en cours et vous pourrez alors fermer Atlas.
# Boîte de dialogue affichée si la fenêtre est fermée pendant le compte à rebours du redémarrage après une installation réussie. Ses boutons sont window-close-keep, restart-now et window-close-restart-close.
window-close-restart-title = Fermer Atlas sans redémarrer ?
# « Redémarrer maintenant » est restart-now, l'un des trois boutons de cette boîte de dialogue.
window-close-restart-message = Votre PC doit redémarrer pour terminer la configuration d’Atlas. Si vous fermez Atlas maintenant, il ne redémarrera pas votre PC : redémarrez-le vous-même quand vous le souhaitez. Enregistrez votre travail avant de choisir Redémarrer maintenant.
window-close-restart-close = Fermer sans redémarrer
# Dialog shown when the window is closed during a setup with Windows Security switches still
# off. $switches names them as Windows Security does, joined like a list. Its buttons are
# window-close-keep, common-open-windows-security and window-close-close.
window-close-protection-title = Fermer Atlas avec la protection désactivée ?
window-close-protection-message = Certaines protections de Sécurité Windows sont encore désactivées : { $switches }. Si vous ne comptez pas terminer l’installation d’Atlas, réactivez-les avant de fermer. Si vous comptez la terminer, Atlas reprendra votre configuration lorsque vous le rouvrirez.
# Titre du sélecteur de fichier pour un package Atlas (.apbx).
file-dialog-open-package = Ouvrir un package Atlas (.apbx)
# Message affiché par Windows dans sa notification de redémarrage.
shutdown-comment = Atlas est installé. Windows redémarre pour terminer la configuration.
# Message affiché par Windows dans sa notification de redémarrage lorsque l'étape
# Préparation redémarre pour terminer l'installation des mises à jour Windows.
prepare-shutdown-comment = Atlas redémarre Windows pour terminer l’installation des mises à jour.

## Système

# « Windows 11 Professionnel, version 25H2 (build 26200.1234) ». Les trois valeurs sont du texte.
system-description = { $product }, version { $version } (build { $build })

## Page d'accueil

home-not-installed = Bienvenue dans Atlas
# Le titre lorsqu'Atlas Manager ne peut pas savoir ce qui est installé sur ce PC.
home-state-unknown = Atlas sur ce PC
# Le titre lorsqu'Atlas est installé. $version est du texte.
home-version = Atlas { $version }
# $date est une date formatée.
home-installed-on = Installé le { $date }
home-status-checking = Recherche de mises à jour
# Pendant que le démarrage vérifie si l'installation d'une autre fenêtre est en cours.
home-status-recovering = Recherche d’une installation en cours
home-status-offline = Impossible de rechercher les mises à jour
home-status-not-checked = Recherche de mises à jour non effectuée
home-status-update = Atlas { $version } est disponible
home-status-up-to-date = À jour
home-status-newest = Dernière version : Atlas { $version }
# Une installation précédente d'Atlas { $version } s'est arrêtée avant la fin.
home-status-unfinished = Installation d’Atlas { $version } inachevée
home-check-again = Vérifier à nouveau
# Bouton principal pendant qu'une installation est en cours ou en attente.
home-show-install = Voir la progression
home-continue-installing = Reprendre la configuration
home-update-to = Mettre à jour vers Atlas { $version }
home-reinstall = Réinstaller Atlas
home-install = Installer Atlas
home-finish-install = Terminer l’installation d’Atlas { $version }
home-start-over = Recommencer
home-restart-title = Votre PC doit redémarrer
home-security-reminder-title = Réactivez votre protection
# Instead of home-security-reminder-title when no switch reads off but some couldn't be read
# (with home-security-reminder-unreadable-message).
home-security-reminder-unreadable-title = Vérifiez que votre protection est activée
home-security-reminder-message = Atlas n’installe rien en ce moment, mais certaines protections de Sécurité Windows sont encore désactivées. Ouvrez Sécurité Windows et assurez-vous que ces paramètres sont activés : { $switches }.
home-security-reminder-unreadable-message = Atlas n’a pas pu vérifier tous les paramètres de protection. Vérifiez dans Sécurité Windows que ces paramètres sont activés : { $switches }.
home-elevation-title = Atlas a besoin d’une autorisation pour lancer l’installation
home-state-error-title = Impossible de lire les informations sur votre installation d’Atlas
home-state-error-message = Votre version d’Atlas, vos choix et votre historique risquent de ne pas s’afficher correctement. Choisissez Vérifier à nouveau pour réessayer. Détails : { $error }
home-whats-new = Nouveautés d’Atlas { $version }
home-view-release = Voir les notes de version sur GitHub
home-released = Publié le { $date }
home-show-less = Afficher moins
home-show-full-notes = Afficher toutes les notes de version
home-your-install = Votre configuration Atlas
# Atlas est installé, mais sans l'enregistrement que tient Atlas Manager (les anciennes versions n'en écrivaient pas).
home-install-unrecorded = Ce PC ne conserve aucune trace de la façon dont Atlas a été installé. Vos choix et l’historique des installations ne peuvent donc pas être affichés.
# Libellé de ligne : comment Atlas a été mis en place.
home-set-up = Méthode de configuration
home-set-up-during-oobe = Pendant l’installation de Windows
home-history = Historique des installations
# Une ligne d'historique. $version est du texte, $mode l'un des messages history-mode-*, $date une date et heure formatées.
home-history-entry = Atlas { $version } · { $mode } · { $date }
home-how-it-works = Préparons votre PC pour Atlas
home-step-1-detail = Atlas vérifie votre PC, installe les mises à jour en attente de Windows et du Microsoft Store, puis télécharge les fichiers d’installation. Les applications du Store peuvent se fermer et un redémarrage peut être nécessaire : enregistrez d’abord votre travail.
# Version de test : le package Atlas est intégré, rien n'est téléchargé.
home-step-1-detail-bundled = Atlas vérifie votre PC, installe les mises à jour en attente de Windows et du Microsoft Store, puis prépare les fichiers d’installation intégrés. Les applications du Store peuvent se fermer et un redémarrage peut être nécessaire : enregistrez d’abord votre travail.
home-step-2-detail = Choisissez si vous conservez Microsoft Defender et les protections du processeur, comment les mises à jour Windows s’installent et quelles options facultatives ajouter.
home-step-3-detail = Désactivez quatre paramètres de protection dans Sécurité Windows pour qu’ils ne bloquent pas l’installation. Atlas vous montre comment faire.
home-step-4-detail =
    { $minutes ->
        [one] L’installation prend environ une minute. Votre PC doit ensuite redémarrer.
       *[other] L’installation prend environ { $minutes } minutes. Votre PC doit ensuite redémarrer.
    }
# Nom accessible d'une étape numérotée.
home-step-a11y = Étape { $number } : { $title }
home-github = Voir Atlas sur GitHub
home-discord = Rejoindre Atlas sur Discord
home-report-problem = Signaler un problème

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
# $error est un message d'erreur brut (texte).
notice-settings-not-saved = Atlas n’a pas pu enregistrer vos dernières modifications : elles risquent d’être perdues à la fermeture d’Atlas. Si une autre fenêtre Atlas est ouverte, fermez-la, puis refaites la modification. Détails : { $error }
notice-session-unreadable-title = Impossible de vérifier l’installation précédente
# $path est un chemin de fichier (texte).
notice-session-unreadable-message = Atlas n’a pas pu déterminer si une installation précédente est encore en cours. En cas de doute, demandez de l’aide à la communauté Atlas. Ne supprimez { $path } et ne réessayez que si vous avez la certitude qu’aucune installation n’est en cours. Détails : { $error }

## Élévation administrateur

elevation-declined = L’autorisation n’a pas été accordée. Réessayez et choisissez Oui lorsque Windows demande si Atlas peut apporter des modifications.
elevation-declined-continue = L’autorisation n’a pas été accordée. Réessayez et choisissez Oui lorsque Windows demande si Atlas peut apporter des modifications. Vos choix de configuration sont enregistrés.
elevation-draft-not-saved = Atlas n’a pas pu enregistrer vos choix de configuration et n’a donc pas été relancé. Réessayez. Détails : { $error }
# Affiché avec le bouton home-start-over.
elevation-taken-over = Une autre fenêtre Atlas utilise désormais cette configuration, Atlas n’a donc pas été relancé. Continuez dans cette fenêtre ou choisissez Recommencer pour refaire la configuration ici.

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
stepper-status-attention = attention requise
# En-tête au-dessus du contenu de chaque étape.
step-heading = Étape { $number } sur { $total } : { $title }
# Accessible name of the step heading on a screen of Your choices, read when it takes focus.
# $heading is step-heading; $progress is options-progress; $question is the screen's question.
step-heading-choice-a11y = { $heading }. { $progress } : { $question }
# The same on the optional extras screen; $progress is options-progress-extras.
step-heading-extras-a11y = { $heading }. { $progress }

## Étape 1 : Préparation

ready-banner-busy-title = Préparation de votre PC
ready-banner-busy-message = Atlas vérifie votre PC et prépare les fichiers d’installation.
ready-banner-blocked-title = Votre PC n’est pas encore prêt
ready-banner-blocked-message = Corrigez les points signalés dans Vérifications du PC, puis choisissez Vérifier à nouveau.
ready-banner-no-package-title = Téléchargez Atlas pour continuer
ready-banner-no-package-message = Téléchargez Atlas dans Fichiers d’installation, ou choisissez Ouvrir un fichier de package si vous avez déjà un package Atlas (.apbx).
# Version de test : le package Atlas intégré n'a pas pu être extrait.
ready-banner-no-package-bundled-title = Préparez le package Atlas intégré pour continuer
ready-banner-no-package-bundled-message = Le package Atlas intégré à cette version de test n’est pas encore prêt. Consultez la carte Fichiers d’installation.
ready-banner-updates-title = Mettez à jour Windows et les applications du Store pour continuer
ready-banner-updates-message = Choisissez Rechercher et installer les mises à jour. Une fois les mises à jour terminées, Atlas vérifie à nouveau votre PC.
# While Windows and Store apps update. "Update Windows and Store apps" is prepare-title, the
# card further down the page.
ready-banner-updating-title = Mise à jour de Windows et des applications du Store
ready-banner-updating-message = Cela peut prendre du temps. Gardez Atlas ouvert. Vous pouvez suivre la progression dans « Mettre à jour Windows et les applications du Store ».
# After Stop updating. "Check and install updates" is prepare-start, the card's button.
ready-banner-updates-stopped-title = Mises à jour arrêtées
ready-banner-updates-stopped-message = Choisissez Rechercher et installer les mises à jour dans « Mettre à jour Windows et les applications du Store » pour terminer.
# Atlas reopened after restarting the PC to continue updating. "Continue updates" is
# prepare-continue, the card's button.
ready-banner-updates-resumed-title = Votre PC a redémarré
ready-banner-updates-resumed-message = Choisissez Poursuivre les mises à jour dans « Mettre à jour Windows et les applications du Store » pour les terminer.
# Under prepare-failed-title or prepare-unconfirmed-title. "Try again" is common-try-again,
# the card's button.
ready-banner-updates-failed-message = Consultez « Mettre à jour Windows et les applications du Store » pour savoir quoi faire, puis choisissez Réessayer.
# Under prepare-reboot-title. "Restart and continue" is prepare-restart, the card's button.
ready-banner-reboot-message = Enregistrez d’abord votre travail, puis choisissez Redémarrer et continuer dans « Mettre à jour Windows et les applications du Store ».
ready-banner-warnings-title = Quelques points à vérifier
ready-banner-warnings-message = Vous pouvez continuer, mais lisez d’abord les points signalés dans Vérifications du PC.
ready-banner-ok-title = Vous pouvez maintenant faire vos choix
ready-banner-ok-message = Les vérifications ont réussi et vos fichiers d’installation sont prêts.

# Titre de carte et nom accessible de la liste des vérifications.
ready-this-pc = Vérifications du PC
ready-check-again = Vérifier à nouveau
ready-checks-passed =
    { $count ->
        [one] { $count } vérification réussie
       *[other] { $count } vérifications réussies
    }

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
# Version de test : le package Atlas intégré est en cours d'extraction, rien n'est téléchargé.
package-looking-bundled = Préparation du package Atlas intégré.
package-none = Téléchargez Atlas pour obtenir les fichiers d’installation. Si vous avez déjà un package Atlas (.apbx), ouvrez-le plutôt.
# La recherche de version sur GitHub a échoué. « Télécharger la dernière version » est package-download-newest, le bouton proposé dans cet état ; il relance la recherche.
package-release-failed = Atlas n’a pas pu rechercher la dernière version. Vérifiez votre connexion Internet, puis choisissez Télécharger la dernière version ou ouvrez un package Atlas (.apbx) déjà enregistré.
# Mots d'état courts à côté du titre de la carte.
package-status-downloading = Téléchargement
package-status-unpacking = Extraction
package-status-failed = Échec de la préparation
package-status-ready = Prêts
package-status-checking = Vérification
package-status-preparing = Préparation
package-status-missing = Non téléchargés
# Nom accessible de la barre de progression.
package-progress = Progression des fichiers d’installation
package-download-again = Télécharger à nouveau
package-download-version = Télécharger Atlas { $version }
package-download-newest = Télécharger la dernière version
package-cancel-download = Annuler le téléchargement
package-open-file = Ouvrir un fichier de package
# Provenance du package. $file est un nom de fichier, $path un chemin de dossier (texte).
package-from-release = Atlas { $version } a été téléchargé depuis GitHub et est prêt à être installé.
package-from-file = Atlas { $version } a été chargé depuis { $file } et est prêt à être installé.
package-unpacked = Atlas { $version } est prêt à être installé.
package-none-yet = Aucun fichier d’installation sélectionné
acquire-no-asset = Atlas { $version } ne propose aucun fichier de package à télécharger. Ouvrez un package Atlas (.apbx) déjà enregistré pour continuer.
acquire-unsupported = Cette application installe Atlas 0.6.0 et versions ultérieures. Pour installer Atlas { $version }, utilisez plutôt AME Wizard.
# Un package assez récent pour inclure le script d'installation que pilote cette application, mais qui ne le contient pas.
acquire-incomplete = Il manque à Atlas { $version } des fichiers dont cette application a besoin pour l’installer. Téléchargez-le à nouveau ou ouvrez un autre package Atlas (.apbx).
acquire-failed = Impossible de préparer les fichiers d’installation. Réessayez le téléchargement ou ouvrez un autre package Atlas (.apbx). Détails : { $error }
# Le téléchargement n'a rien reçu pendant une minute et a été arrêté.
acquire-stalled = Le téléchargement a cessé de répondre. Vérifiez votre connexion Internet, puis réessayez le téléchargement ou ouvrez un package Atlas (.apbx) déjà enregistré.
# Version de test : le package Atlas intégré n'a pas pu être extrait. Réessayer est le seul bouton proposé.
acquire-failed-bundled = Impossible de préparer le package Atlas intégré. Choisissez Réessayer. Détails : { $error }

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
check-fix-apps = Ouvrir les applications installées
# Case que l'utilisateur coche lorsque la recherche Windows Update n'a pas pu s'exécuter.
check-ack-updates = J’ai vérifié dans Windows Update : aucune mise à jour n’est en attente d’installation

detail-admin-ok = Atlas a l’autorisation d’apporter les modifications nécessaires à l’installation.
detail-admin-missing = Relancez Atlas en tant qu’administrateur, puis choisissez Oui lorsque Windows demande l’autorisation.
# $builds est une liste de numéros de build comme « 26100 ou 26200 » ; $build est celle de ce PC (texte).
detail-build-unsupported = Cette version d’Atlas nécessite la build Windows { $builds }. Votre PC utilise la build { $build }. Installez une version compatible de Windows avant de continuer.
detail-build-missing = Ce package Atlas n’indique aucune build Windows prise en charge. Utilisez une build complète du package plutôt qu’une build LocalTest.
detail-updates-none = Aucune mise à jour Windows n’est en attente d’installation.
# $titles liste jusqu'à deux noms de mises à jour (texte) ; $count est le total.
detail-updates-pending =
    { $count ->
        [1] Cette mise à jour est en attente : { $titles }. Atlas l’installe depuis « Mettre à jour Windows et les applications du Store ».
        [2] Ces mises à jour sont en attente : { $titles }. Atlas les installe depuis « Mettre à jour Windows et les applications du Store ».
       *[other] { $count } mises à jour sont en attente, dont { $titles }. Atlas les installe depuis « Mettre à jour Windows et les applications du Store ».
    }
detail-updates-unknown = Impossible de rechercher les mises à jour Windows. Ouvrez Windows Update puis, si aucune mise à jour n’est en attente, confirmez-le ci-dessous. ({ $error })
detail-reboot-none = Windows n’a pas besoin de redémarrer pour le moment.
detail-reboot-pending = Windows doit redémarrer pour terminer des modifications antérieures. Lorsque vous choisissez Rechercher et installer les mises à jour, Atlas vous demande d’abord de redémarrer.
# $reasons : les marqueurs de redémarrage en attente posés par Windows, d'après les noms prepare-reason-*.
detail-reboot-pending-reasons = Windows doit redémarrer pour terminer des modifications antérieures ({ $reasons }). Lorsque vous choisissez Rechercher et installer les mises à jour, Atlas vous demande d’abord de redémarrer.
# Avertissement, pas un blocage : $files liste jusqu'à trois chemins de fichiers que Windows remplacera ou supprimera au prochain redémarrage.
detail-reboot-file-renames = Vous pouvez continuer. Windows doit remplacer ou supprimer des fichiers au prochain redémarrage ({ $files }). Certaines applications, comme Xbox Gaming Services, font cela après chaque redémarrage.
detail-reboot-unknown = Impossible de vérifier si Windows doit redémarrer. Redémarrez votre PC, puis rouvrez Atlas et vérifiez à nouveau. ({ $error })
detail-antivirus-none = Aucun autre logiciel antivirus n’a été détecté.
# $products est une liste de noms de produits (texte).
detail-antivirus-found = Les applications antivirus autres que Microsoft Defender peuvent bloquer l’installation. Désinstallez { $products }, puis choisissez Vérifier à nouveau.
# Avertissement, pas un blocage : le Centre de sécurité liste encore le produit, mais ses fichiers ont disparu.
detail-antivirus-stale = Sécurité Windows liste encore { $products }, mais ses fichiers ont disparu : ce logiciel n’est donc plus installé. Atlas peut quand même être installé.
detail-antivirus-unknown = Impossible de vérifier la présence d’autres antivirus. Choisissez Vérifier à nouveau. Si le problème persiste, redémarrez votre PC et vérifiez à nouveau. ({ $error })
detail-internet-ok = Ce PC est connecté à Internet. Conservez cette connexion pendant qu’Atlas télécharge et installe des logiciels.
detail-internet-missing = Connectez-vous à Internet, puis vérifiez à nouveau.
detail-power-mains = Votre PC est branché sur le secteur. Laissez-le branché jusqu’à la fin de l’installation.
detail-power-battery = Branchez votre PC sur le secteur pour qu’il reste allumé pendant toute l’installation.
detail-power-unknown = Atlas n’a pas pu déterminer si votre PC est branché sur le secteur. S’il s’agit d’un ordinateur portable, branchez-le, puis choisissez Vérifier à nouveau. Si cela se reproduit, choisissez Envoyer un rapport.
detail-activation-ok = Windows est activé. Atlas n’y changera rien.
detail-activation-missing = Windows n’est pas activé. Vous pouvez continuer, mais Atlas n’activera pas Windows à votre place.
detail-activation-no-licence = Windows n’a signalé aucune licence. Vous pouvez continuer ; Atlas ne modifiera pas l’état d’activation.
detail-activation-unknown = Impossible de vérifier l’activation de Windows. Vous pouvez continuer ; Atlas ne modifiera pas l’état d’activation. ({ $error })

## Étape 2 : Vos choix

options-progress = Choix { $number } sur { $total }
options-progress-extras = Choix { $number } sur { $total } : options facultatives
options-change-later = Vous pourrez modifier plus tard vos choix pour Microsoft Defender, les protections du processeur et les mises à jour depuis le dossier Atlas de votre bureau.
# Noms courts de chaque décision (lignes de résumé) et question posée par chaque écran.
screen-defender-title = Microsoft Defender
screen-defender-question = Conserver Microsoft Defender ?
screen-mitigations-title = Protections du processeur
screen-mitigations-question = Conserver les protections du processeur intégrées à Windows ?
screen-updates-title = Windows Update
screen-updates-question = Comment Windows doit-il installer les mises à jour ?
screen-browser-title = Navigateur
screen-power-title = Alimentation et sécurité
screen-apps-title = Applications
screen-optional-apps-title = Applications facultatives
screen-choose-one-title = Choisissez une option
screen-extras-title = Options facultatives
# Question pour un choix obligatoire pour lequel cette application n'a pas de formulation spécifique.
screen-generic-question = Choisissez une option pour { $title }
learn-more-defender = En savoir plus sur Microsoft Defender
learn-more-mitigations = En savoir plus sur les protections du processeur
learn-more-updates = En savoir plus sur Windows Update
learn-more-browser = En savoir plus sur les navigateurs
learn-more-power = En savoir plus sur l’alimentation et la sécurité
learn-more-apps = En savoir plus sur les applications
learn-more-eclean = Comment eclean fonctionne avec AtlasOS
learn-more-generic = Lire le guide de configuration
# Une ligne sous la réponse choisie : ce que cela implique pour le PC.
consequence-defender-enable = Conserve l’antivirus intégré à Windows pour aider à protéger votre PC contre les virus et autres menaces.
consequence-defender-disable = Supprime aussi SmartScreen. Votre PC n’aura aucune protection antivirus tant que vous n’aurez pas installé une autre application antivirus, et Windows ne vous avertira pas avant que vous ouvriez des applications ou des téléchargements non reconnus.
consequence-mitigations-default = Conserve les protections par défaut de Windows contre les failles du processeur et les attaques qui exploitent des bogues dans les applications.
consequence-mitigations-disable = Désactive aussi Exploit Protection pour les applications, comme la Protection du flux de contrôle (CFG). Cela réduit la sécurité. L’effet sur les performances dépend de votre processeur.
consequence-auto-updates-disable = Ouvrez régulièrement Windows Update pour installer les mises à jour. Les notifications de mise à jour restent activées.
consequence-auto-updates-default = Windows installera les mises à jour automatiquement, y compris les correctifs de sécurité.

## Texte du package Atlas
## Le package Atlas contient son propre texte anglais pour chaque option. Ces
## libellés et explications ne sont utilisés que si le texte du package correspond
## à i18n/playbook-source.ftl. Un futur package formulé autrement conserve ses
## propres mots plutôt que de recevoir une description peut-être obsolète.

playbook-option-defender-enable = Conserver Microsoft Defender (recommandé)
playbook-option-defender-disable = Supprimer Microsoft Defender
playbook-option-mitigations-default = Conserver les protections du processeur (recommandé)
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
playbook-option-install-eclean = Installer eclean
playbook-option-browser-brave = Brave
playbook-option-browser-librewolf = LibreWolf
playbook-option-browser-firefox = Firefox
playbook-option-browser-chrome = Chrome
playbook-page-defender-enable-description = Microsoft Defender est l’antivirus intégré à Windows. Ne le supprimez que si vous comprenez les risques et prévoyez d’utiliser une autre application antivirus. Quel que soit votre choix, Atlas désactive le Contrôle intelligent des applications, la Protection renforcée contre l’hameçonnage et Localiser mon appareil.
playbook-page-mitigations-default-description = Ces protections, aussi appelées mesures d’atténuation de sécurité, aident à protéger votre PC contre les failles du processeur, comme Spectre et Meltdown, et contre les attaques qui exploitent des bogues dans les applications. Il est recommandé de conserver les paramètres par défaut de Windows.
playbook-page-auto-updates-disable-description = Les mises à jour Windows comprennent des correctifs de sécurité. Vous pouvez laisser Windows les installer automatiquement ou les installer vous-même. Dans les deux cas, Atlas maintient Windows sur sa version actuelle, qui ne reçoit des correctifs de sécurité que jusqu’à la fin de son support par Microsoft. Atlas désactive aussi les mises à jour automatiques des applications du Microsoft Store : mettez-les donc à jour dans le Microsoft Store.
playbook-page-browser-brave-description = Choisissez un navigateur à installer. Atlas ne modifiera pas les paramètres de votre navigateur.

## Étape 3 : Sécurité Windows

security-banner-reading-title = Vérification de Sécurité Windows
security-banner-reading-message = Atlas vérifie les quatre paramètres de protection ci-dessous.
security-banner-off-title = Les quatre paramètres de protection sont désactivés
# Shown instead of the switch list when an earlier Atlas install removed Microsoft Defender.
security-banner-absent-title = Microsoft Defender n’est pas installé sur ce PC
security-banner-absent-message = Il n’y a rien à désactiver à cette étape. Choisissez Continuer.
security-banner-off-message = Choisissez Continuer pour vérifier votre configuration et installer Atlas.
security-banner-on-title = Désactivez la protection antivirus dans Sécurité Windows
security-banner-on-message = Microsoft Defender peut bloquer les modifications apportées par Atlas. Choisissez Ouvrir Sécurité Windows et désactivez chacun des paramètres ci-dessous. Si vous conservez Microsoft Defender, réactivez ces paramètres une fois l’installation terminée.
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
security-unknown-message = Assurez-vous que les quatre paramètres sont désactivés dans Sécurité Windows, puis confirmez-le ci-dessous.
security-acknowledge = J’ai vérifié dans Sécurité Windows que les quatre paramètres sont désactivés
security-unknown-unelevated-title = Atlas a besoin d’une autorisation pour vérifier la protection
security-unknown-unelevated-message = Relancez Atlas en tant qu’administrateur pour qu’il puisse lire les paramètres de Microsoft Defender.
# Les quatre paramètres, nommés exactement comme dans Sécurité Windows.
protection-tamper = Protection contre les falsifications
protection-tamper-why = Désactivez ce paramètre pour permettre à Atlas de modifier les paramètres de sécurité de Defender.
protection-realtime = Protection en temps réel
protection-realtime-why = Désactivez ce paramètre pour que Defender ne bloque pas les fichiers d’installation d’Atlas en les analysant.
protection-cloud = Protection dans le cloud
protection-cloud-why = Désactivez ce paramètre pour que les vérifications en ligne des menaces ne bloquent pas les fichiers d’installation d’Atlas.
protection-samples = Envoi automatique d’un échantillon
protection-samples-why = Empêchez Defender d’envoyer automatiquement des fichiers d’Atlas à Microsoft pour analyse.

## Étape 4 : Installation

# Nom accessible de la barre de progression.
install-progress = Progression de l’installation
# La progression de l'installation affichée à côté de la barre. $percent est un nombre entier de 0 à 99.
install-percent = { $percent } %
outcome-succeeded-title = Atlas est installé
outcome-lost-title = Impossible de confirmer le résultat de l’installation
outcome-failed-title = L’installation ne s’est pas terminée
outcome-requirements = Votre PC ne répond pas aux conditions requises pour l’installation. Aucune modification n’a été apportée. Revenez à l’étape Préparation et vérifiez à nouveau.
# Les variantes -resumed suivent une nouvelle tentative d'une installation qu'une tentative précédente avait déjà commencé à appliquer.
outcome-requirements-resumed = Votre PC ne répond pas aux conditions requises pour l’installation, cette tentative s’est donc arrêtée. Une tentative précédente a déjà commencé à apporter des modifications. Revenez à l’étape Préparation et vérifiez à nouveau.
outcome-not-elevated = Atlas n’avait pas l’autorisation d’administrateur. Aucune modification n’a été apportée. Relancez Atlas en tant qu’administrateur, puis réessayez.
outcome-not-elevated-resumed = Atlas n’avait pas l’autorisation d’administrateur, cette tentative s’est donc arrêtée. Une tentative précédente a déjà commencé à apporter des modifications. Relancez Atlas en tant qu’administrateur, puis réessayez.
# La vérification du programme d'installation a trouvé des mises à jour Windows ou Store inachevées. L'étape Préparation propose à nouveau la recherche ; « Rechercher et installer les mises à jour » est prepare-start, son bouton dans cet état.
outcome-preparation-stale = Atlas n’a pas pu confirmer que Windows et les applications du Store sont à jour, l’installation s’est donc arrêtée avant toute modification de Windows. Revenez à l’étape Préparation et choisissez Rechercher et installer les mises à jour.
outcome-preparation-stale-resumed = Atlas n’a pas pu confirmer que Windows et les applications du Store sont à jour, cette tentative s’est donc arrêtée. Une tentative précédente a toutefois déjà commencé à apporter des modifications. Revenez à l’étape Préparation et choisissez Rechercher et installer les mises à jour.
outcome-failed-preflight = L’installation s’est arrêtée avant toute modification. Vous pouvez réessayer. Si elle s’arrête de nouveau, choisissez Envoyer un rapport.
outcome-failed-staging = L’installation s’est arrêtée pendant la préparation des fichiers, avant toute modification de Windows. Vous pouvez réessayer. Si elle s’arrête de nouveau, choisissez Envoyer un rapport.
outcome-failed-applying = Certaines modifications ont peut-être déjà été appliquées. Vous pouvez réessayer. Si vous vous arrêtez ici, réactivez dans Sécurité Windows les protections que vous avez désactivées, si elles sont toujours disponibles.
outcome-failed-resumed = Cette tentative s’est arrêtée prématurément, mais une tentative précédente a déjà commencé à apporter des modifications. Vous pouvez réessayer. Si vous vous arrêtez ici, réactivez dans Sécurité Windows les protections que vous avez désactivées, si elles sont toujours disponibles.
outcome-not-started = Le programme d’installation n’a pas démarré à temps. Aucune modification n’a été apportée. Vous pouvez réessayer.
outcome-lost = Le programme d’installation s’est arrêté sans indiquer de résultat, et certaines modifications ont peut-être déjà été appliquées. Vous pouvez réessayer. Si vous vous arrêtez ici, réactivez dans Sécurité Windows les protections que vous avez désactivées, si elles sont toujours disponibles.
restart-now-message = Windows redémarre pour terminer la configuration d’Atlas.
restart-countdown =
    { $seconds ->
        [one] Windows redémarre dans { $seconds } seconde pour terminer la configuration d’Atlas. Pour enregistrer d’abord votre travail, choisissez Redémarrer plus tard.
       *[other] Windows redémarre dans { $seconds } secondes pour terminer la configuration d’Atlas. Pour enregistrer d’abord votre travail, choisissez Redémarrer plus tard.
    }
restart-stopped = Redémarrage automatique annulé. Enregistrez votre travail, puis redémarrez votre PC pour terminer la configuration d’Atlas.
restart-needed = Enregistrez votre travail, puis redémarrez votre PC pour terminer la configuration d’Atlas.
restart-dont-now = Redémarrer plus tard
restart-now = Redémarrer maintenant
restart-start-failed = Atlas n’a pas pu redémarrer votre PC. Enregistrez votre travail, puis redémarrez-le depuis le menu Démarrer. Détails : { $error }
preflight-title = L’installation n’a pas démarré
preflight-invalid-options = Atlas n’a pas pu utiliser ces choix de configuration. Revenez à l’étape Vos choix pour les revoir, puis réessayez. Détails : { $error }
# $problems est une ou deux phrases construites à partir de preflight-problem et preflight-security.
preflight-changed = L’état de votre PC a changé depuis les vérifications précédentes. Résolvez les points suivants avant de réessayer. { $problems }
preflight-problem = { $title } : { $detail }
# $summary est le résumé de Sécurité Windows, par exemple « 2 encore activés ».
preflight-security = Sécurité Windows : { $summary }.
preflight-busy = Une autre fenêtre Atlas démarre une installation. Patientez un instant, puis choisissez à nouveau Installer Atlas.
# Affiché avec le bouton home-start-over.
preflight-taken-over = Une autre fenêtre Atlas utilise désormais cette configuration, l’installation n’a donc pas démarré. Continuez dans cette fenêtre ou choisissez Recommencer pour refaire la configuration ici.
preflight-record-unreadable = Atlas n’a pas pu vérifier si l’installation précédente est encore en cours et n’en a donc pas démarré une autre. Revenez à l’étape Préparation pour savoir quoi faire ensuite. Détails : { $error }
preflight-refused = Impossible de démarrer le programme d’installation. Aucune modification n’a été apportée. Choisissez Installer Atlas pour réessayer. Si le problème persiste, choisissez Envoyer un rapport. Détails : { $error }
# Remplace preflight-refused lors d'une nouvelle tentative d'une installation qu'une tentative précédente avait déjà commencé à appliquer.
preflight-refused-resumed = Impossible de démarrer le programme d’installation, cette tentative s’est donc arrêtée. Une tentative précédente a déjà commencé à apporter des modifications. Choisissez Installer Atlas pour réessayer. Si le problème persiste, choisissez Envoyer un rapport. Détails : { $error }
go-to-ready = Revenir à l’étape Préparation
go-to-options = Revenir à l’étape Vos choix
# Remplace Continuer sur un choix ouvert depuis un lien Modifier de l'étape Installation, lorsque Continuer y ramène directement.
go-to-install = Revenir à l’étape Installation
output-problem-title = Impossible de lire la progression de l’installation
output-problem-message = Atlas n’a pas pu lire le journal. Cela ne signifie pas que l’installation s’est arrêtée. Laissez votre PC allumé et essayez d’ouvrir le fichier journal. Détails : { $error }
install-elevate-title = Atlas a besoin d’une autorisation pour lancer l’installation
install-no-package-title = Choisissez d’abord vos fichiers d’installation
install-no-package-message = Revenez à l’étape Préparation pour télécharger Atlas ou ouvrir un package Atlas (.apbx) enregistré.
# Variante de install-no-package-message pour la version de test.
install-no-package-bundled-message = Revenez à l’étape Préparation pour préparer le package Atlas intégré à cette version de test.
# Étape 4 lorsque l'étape 1 n'est pas terminée pour cette session (vérifications ou mises à jour Windows) ; go-to-ready est le bouton.
install-not-ready-title = Terminez d’abord l’étape Préparation
install-not-ready-message = Atlas doit terminer la vérification de votre PC et la mise à jour de Windows avant de pouvoir lancer l’installation.
install-security-title = Vérifiez la protection antivirus avant d’installer
install-security-reading = Nouvelle vérification des quatre paramètres de protection.
install-security-message = { $summary }. Ouvrez Sécurité Windows et assurez-vous que les quatre paramètres sont désactivés avant de lancer l’installation.
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
summary-copy-command-a11y = Copier la commande d’installation
summary-command-unavailable = Impossible de préparer la commande d’installation. Détails : { $error }
summary-not-chosen = Aucun choix pour le moment
# Nom accessible d'un lien Modifier. $title est un message screen-*-title.
summary-change-a11y = Modifier le choix { $title }
footer-still-checking = Préparation de l’installation
footer-fix-items = Corrigez les points signalés dans Vérifications du PC pour continuer
footer-need-package = Téléchargez Atlas ou ouvrez un package Atlas pour continuer
# Variante de footer-need-package pour la version de test.
footer-need-package-bundled = Préparez le package Atlas intégré pour continuer
footer-reading-security = Vérification des paramètres de protection
footer-security-pending = Désactivez les quatre paramètres pour continuer
footer-security-confirm = Pour continuer, confirmez les paramètres qu’Atlas n’a pas pu vérifier
footer-install-ready = Enregistrez d’abord votre travail et fermez vos applications
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
installing-restart-auto = Votre PC redémarrera automatiquement à la fin de l’installation. D’ici là, enregistrez votre travail dans vos autres applications.

## La fenêtre « Atlas est installé » après le redémarrage

installed-title-version = Atlas { $version } est installé
installed-title = Atlas est installé
installed-ready = C’est terminé. Votre PC est prêt à être utilisé avec Atlas.
installed-security-message = Vous avez conservé Microsoft Defender, mais certaines de ses protections sont encore désactivées. Ouvrez Sécurité Windows et assurez-vous que ces paramètres sont activés : { $switches }.
installed-defender-removed-title = Microsoft Defender a été supprimé
installed-defender-removed-message = Votre PC n’aura aucune protection antivirus tant que vous n’aurez pas installé une autre application antivirus. SmartScreen a aussi été supprimé : Windows ne vous avertira donc pas avant que vous ouvriez des applications ou des téléchargements non reconnus.
# Home and the "Atlas is installed" window, after an installation that kept Microsoft Defender,
# when it is missing. Its title is security-banner-absent-title; "Report a problem" is
# home-report-problem, its button.
installed-defender-missing-message = Vous avez choisi de conserver Microsoft Defender, mais il est introuvable. Si vous n’utilisez pas d’autre application antivirus, installez-en une pour protéger votre PC. Si vous n’avez pas supprimé Defender vous-même, choisissez Signaler un problème.

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
settings-language-system-selected = { settings-language-system } ({ $language })
# Sous « Comme Windows » : la langue que cela donne. $language est le nom de la langue dans cette langue.
settings-language-system-detail = Avec « Comme Windows » : { $language }
# Courte étiquette sous chaque langue traduite mais pas encore relue par un locuteur natif.
settings-language-preview-tag = Aperçu
# Sous la liste des langues, une seule fois, pour expliquer l'étiquette Aperçu.
settings-language-preview-note = Les traductions marquées Aperçu n’ont pas encore été relues par un locuteur natif.
preview-notice = { $language } est une traduction en aperçu et peut contenir des erreurs.
preview-notice-switch = Passer en anglais
preview-notice-language = Changer de langue
# $tag est une balise de langue (texte).
settings-language-unavailable = { $tag } n’est pas disponible dans cette version d’Atlas. L’anglais est affiché pour le moment et votre choix de langue est conservé.
# $languages est la liste des langues d'affichage de Windows (texte).
settings-language-windows-unmatched = Atlas ne prend pas encore en charge vos langues d’affichage Windows ({ $languages }). L’anglais est affiché pour le moment.
settings-language-windows-unavailable = Impossible de vérifier votre langue d’affichage Windows. Atlas utilise l’anglais pour le moment. Détails : { $error }
# $locale est le nom du format régional dans sa propre langue, par exemple « français (France) ».
settings-language-formats = Les nombres, les dates et les heures suivent votre format régional Windows ({ $locale }).
# Remplace settings-language-formats lorsque le format régional écrit les dates ou les heures de droite à gauche. $locale est le nom anglais du format, par exemple « Arabic (Saudi Arabia) ».
settings-language-formats-numbers-only = Les nombres suivent votre format régional Windows ({ $locale }). Les dates et les heures utilisent un format standard, car Atlas ne peut pas encore afficher le texte de droite à gauche.
settings-language-contribute = Aider à traduire Atlas sur GitHub
settings-restart-label = Redémarrer mon PC automatiquement après l’installation
settings-restart-locked = Vous pourrez modifier ce réglage une fois l’installation terminée.
settings-restart-description = Lorsque cette option est activée, votre PC redémarre dans la minute qui suit la fin de l’installation, ce qui ferme vos applications ouvertes. Enregistrez votre travail avant de lancer l’installation.
settings-help = Aide et commentaires
settings-about = À propos
settings-about-app = Atlas Manager
settings-about-licence = Licence
settings-about-licence-value = GPL-3.0, libre et open source
settings-view-source = Voir le code source sur GitHub
# Lien qui ouvre les mentions de licence des composants tiers.
settings-view-licences = Voir les mentions de licence
# Sous les liens lorsque Windows n'a pas pu ouvrir les mentions.
settings-licences-failed = Impossible d’ouvrir les mentions de licence. Réessayez ou consultez-les dans le code source sur GitHub.
settings-open-data-folder = Ouvrir le dossier de l’application

## Choix facultatifs : explications affichées avant la sélection.

consequence-disable-hibernation = Libère l’espace disque utilisé pour enregistrer votre session lors de la mise en veille prolongée. La veille prolongée et le démarrage rapide ne seront plus disponibles.
consequence-disable-power-saving = Désactive les fonctions d’économie d’énergie. Votre PC peut consommer davantage, chauffer plus et avoir une autonomie réduite.
consequence-disable-core-isolation = Désactive une couche de sécurité supplémentaire de Windows, dont l’intégrité de la mémoire. Cela réduit la protection et peut affecter les applications ou les jeux qui en ont besoin.
consequence-remove-snipping-tool = Supprime l’application Windows de capture d’écran et d’enregistrement vidéo de l’écran.
consequence-uninstall-edge = Supprime le navigateur Microsoft Edge. Assurez-vous d’avoir un autre navigateur ou choisissez-en un ci-dessous.
# Instead of consequence-uninstall-edge when Atlas is installed on this PC, which has the
# user's Edge data. "choose one below" refers to the browser choice under it.
consequence-uninstall-edge-data = Supprime Microsoft Edge ainsi que vos favoris, votre historique et vos mots de passe enregistrés dans Edge sur ce PC. Tout ce qui n’est pas synchronisé avec votre compte Microsoft sera perdu. Assurez-vous d’avoir un autre navigateur ou choisissez-en un ci-dessous.
# Under Remove Microsoft Edge in the Install step's summary, with a caution glyph.
caution-uninstall-edge = Supprime vos favoris, votre historique et vos mots de passe enregistrés dans Edge sur ce PC.
consequence-install-another-browser = Choisissez un navigateur ci-dessous et Atlas l’installera pour vous.
consequence-install-toolbox = Ajoutez Atlas Toolbox pour gérer plus facilement vos paramètres Atlas. Toolbox est en version bêta : certaines fonctionnalités peuvent être inachevées.
consequence-install-eclean = Un outil de maintenance de l’équipe d’AtlasOS pour entretenir votre PC après l’installation. Examinez les fichiers inutiles et les applications au démarrage. Nécessite un compte et une connexion Internet.

# Introduction sur la page d'accueil avant l'installation d'Atlas.
home-intro = Atlas ajuste Windows pour réduire l’activité en arrière-plan et les distractions. Installez Atlas sur une nouvelle installation de Windows, avant d’y ajouter vos propres applications et fichiers.

## ISO creation (Beta)
iso-home-title = Support d’installation de Windows
iso-home-description = Créez un fichier d’installation de Windows (ISO) qui inclut Atlas, puis utilisez-le pour réinstaller Windows sur ce PC ou sur un autre.
iso-open = Créer une ISO avec Atlas
iso-title = Créer une ISO avec Atlas
iso-beta = Bêta
iso-beta-description = Testez l’ISO dans une machine virtuelle avant de l’utiliser sur un PC. Sauvegardez vos fichiers avant d’installer Windows.
iso-admin-description = Atlas a besoin d’une autorisation d’administrateur pour lire votre ISO Windows et en créer une nouvelle. Choisissez Relancer en tant qu’administrateur, puis Oui lorsque Windows le demande.
iso-files-description = Atlas crée une copie d’une ISO Windows 11 en y ajoutant Atlas, pour réinstaller Windows. Choisissez une ISO Windows 11 téléchargée auprès de Microsoft, téléchargez le dernier package Atlas ou choisissez-en un que vous avez déjà (.apbx), puis choisissez où enregistrer la nouvelle ISO.
# Version de test : pas de sélecteur de package.
iso-files-description-bundled = Atlas crée une copie d’une ISO Windows 11 en y ajoutant le package Atlas intégré à cette version de test. Choisissez une ISO Windows 11 téléchargée auprès de Microsoft, puis choisissez où enregistrer la nouvelle ISO.
iso-source = ISO Windows
iso-source-download = Télécharger Windows 11 sur le site de Microsoft
iso-package = Package Atlas ({ $minimum } ou plus récent)
iso-output = Enregistrer la nouvelle ISO sous
iso-no-file = Aucun fichier sélectionné
iso-browse = Parcourir
iso-save-as = Enregistrer sous
# Nom accessible du bouton Parcourir ou Enregistrer sous à côté d'un champ de fichier : $action est le texte de ce bouton et $field le libellé du champ.
iso-pick-a11y = { $action } : { $field }
iso-inspect = Vérifier les fichiers
iso-mode-title = Comment souhaitez-vous configurer Atlas ?
iso-mode-interactive = Faire vos choix Atlas après la connexion
iso-mode-interactive-description = Après votre connexion, Atlas s’ouvre et vous guide dans les mises à jour, vos choix et l’installation d’Atlas.
iso-mode-before = Faire vos choix Atlas maintenant
iso-mode-before-description = Atlas enregistre vos choix dans l’ISO. Après votre connexion, Atlas s’ouvre et vous guide dans les mises à jour, puis vous installez Atlas avec ces choix.
iso-package-unsupported-title = Choisissez un package Atlas plus récent
iso-package-unsupported = Ce package Atlas ne peut pas enregistrer les choix Atlas dans l’ISO. Choisissez un package plus récent, ou l’option Faire vos choix Atlas après la connexion.
# Affiché lorsque Vérifier les fichiers refuse le package Atlas ; $minimum comme pour iso-package.
iso-failed-package-unsupported = Ce package Atlas ne permet pas de créer une ISO. Choisissez un package pour Atlas { $minimum } ou une version ultérieure.
# Version de test : le package Atlas intégré ne peut pas être remplacé ; seul le mode après connexion reste possible.
iso-package-unsupported-bundled-title = Les choix Atlas ne peuvent pas être enregistrés dans cette ISO
iso-package-unsupported-bundled = Le package Atlas intégré à cette version de test ne prend pas en charge la configuration par ISO. Choisissez plutôt Faire vos choix Atlas après la connexion.
iso-atlas-options = Choix Atlas
iso-review = Vérifier l’ISO
iso-review-description = La création de l’ISO n’installe rien sur ce PC et ne modifie pas votre ISO d’origine. Ensuite, Atlas peut copier la nouvelle ISO sur une clé USB pour que vous puissiez réinstaller Windows à partir de celle-ci.
iso-review-files = Fichiers
iso-step-windows = Installation de Windows
iso-step-review = Récapitulatif
iso-review-package = Package Atlas
iso-review-output = Nouvelle ISO
iso-review-editions = Éditions
iso-architecture-x64 = x64
iso-architecture-arm64 = Arm64
# Une taille de fichier ; $size est un nombre formaté (texte). Mégaoctets en dessous d'un gigaoctet.
size-megabytes = { $size } Mo
size-gigabytes = { $size } Go
iso-review-account = Nom du compte
iso-review-target = Installer sur
iso-review-drivers = Pilotes
iso-create = Créer l’ISO
iso-progress-title = Création de votre ISO
iso-stage-inspect = Vérification de votre ISO Windows
iso-stage-copy = Copie des fichiers Windows
iso-stage-add-atlas = Ajout d’Atlas
iso-stage-master = Écriture du fichier ISO
iso-stage-verify = Vérification de la nouvelle ISO
iso-stage-cleanup = Finalisation
# Accessible name of one stage while the ISO is created. No "Step": the screen reader adds
# "4 of 6". $status is stepper-status-completed or one of the three below.
iso-stage-a11y = { $title }, { $status }
iso-stage-status-current = en cours
# The stage where creating the ISO stopped with an error.
iso-stage-status-failed = en échec
iso-stage-status-not-started = non commencée
iso-progress-description = Gardez Atlas ouvert. Le traitement des images volumineuses peut prendre du temps.
iso-cancel = Annuler la création
iso-cancelling = En attente d’un point d’arrêt sûr
iso-cancelled = Création de l’ISO annulée
iso-cancelled-description = Votre ISO d’origine n’a pas été modifiée. Si des fichiers temporaires sont restés, choisissez Ouvrir le dossier des journaux pour voir où ils se trouvent.
iso-complete = Votre ISO est prête
iso-complete-description = La création d’ISO est en version bêta : testez d’abord l’ISO dans une machine virtuelle. Choisissez ensuite Créer une clé d’installation, et sauvegardez vos fichiers avant de réinstaller Windows.
iso-open-folder = Afficher dans le dossier
iso-failed = La création de l’ISO n’a pas pu aboutir
iso-failed-description = Assurez-vous que vos fichiers se trouvent toujours à l’emplacement choisi et que le disque de destination est connecté, puis choisissez Créer l’ISO. Si l’échec persiste, choisissez Envoyer un rapport.
# Titre lorsque l'étape Vérifier les fichiers échoue ; les messages ci-dessous en donnent la raison.
iso-check-failed = Impossible de vérifier les fichiers
iso-check-failed-description = Assurez-vous que l’ISO et le package Atlas se trouvent toujours à l’emplacement choisi et que leur téléchargement est terminé, puis choisissez Vérifier les fichiers. Si l’échec persiste, choisissez Envoyer un rapport.
# Titre lorsque Windows a refusé la relance en administrateur (UAC refusé) ; elevation-declined est le message.
iso-elevation-title = Atlas a besoin d’une autorisation pour créer une ISO
# Raisons typées signalées par le processus de traitement de l'image.
iso-failed-output-exists = Un fichier portant ce nom existe déjà. Choisissez Enregistrer sous et saisissez un nouveau nom de fichier.
iso-failed-destination = Atlas ne peut pas enregistrer la nouvelle ISO à cet emplacement. Choisissez Enregistrer sous et sélectionnez un dossier de ce PC, comme Téléchargements. Les emplacements réseau et les disques au format FAT32 ou exFAT, comme beaucoup de clés USB, ne peuvent pas être utilisés.
iso-failed-space = L’espace libre est insuffisant sur le disque de destination. Libérez de l’espace ou enregistrez la nouvelle ISO sur un autre disque.
# Famille (Home) et LTSC sont les éditions que la création d'ISO écarte ; les autres sont des exemples d'éditions conservées. Noms tels que Windows les affiche en français.
iso-failed-edition = Cette ISO ne contient aucune édition de Windows prise en charge. Les éditions Famille et LTSC ne sont pas prises en charge. Utilisez une ISO qui inclut une autre édition, comme Professionnel, Éducation ou Entreprise.
iso-failed-customised = Cette ISO contient déjà des fichiers d’installation personnalisés, comme autounattend.xml. Choisissez une ISO Windows non modifiée provenant de Microsoft.
iso-failed-windows-unsupported = Cette image Windows n’est pas prise en charge par le package Atlas. Utilisez une ISO Windows 11 64 bits non modifiée d’une version prise en charge par ce package.
iso-failed-network-architecture = Les pilotes réseau de ce PC ne correspondent pas à l’architecture de cette ISO. Revenez en arrière et décochez Inclure les pilotes réseau de ce PC, ou choisissez une ISO pour ce PC.
iso-failed-unstaged = Atlas n’a pas pu préparer son dossier de travail, donc rien n’a été modifié. Réessayez. Si le problème persiste, choisissez Exporter les diagnostics pour un rapport de bogue.
iso-failed-package-changed = Le package Atlas a changé après la vérification des fichiers. Choisissez Modifier à côté de Fichiers, puis Vérifier les fichiers.
iso-diagnostics = Ouvrir le dossier des journaux
iso-close-title = La création de l’ISO est en cours
iso-close-message = Gardez cette fenêtre ouverte jusqu’à la fin de la création ou de l’annulation. L’annulation attend que l’opération en cours puisse s’arrêter sans risque.
iso-keep-open = Garder ouvert
prepare-title = Mettre à jour Windows et les applications du Store
prepare-description = Avant l’installation, Atlas met à jour Windows, le Microsoft Store et vos applications du Store. Les applications du Store ouvertes, comme le Bloc-notes, Paint ou le Terminal Windows, peuvent se fermer pendant leur mise à jour : enregistrez d’abord votre travail dans ces applications. Votre PC devra peut-être aussi redémarrer.
prepare-complete = Atlas n’a plus trouvé de mises à jour Windows ou du Store à installer.
prepare-reboot-title = Redémarrez votre PC pour continuer
prepare-reboot = Votre PC doit redémarrer pour terminer l’installation des mises à jour. Atlas enregistre les choix que vous avez déjà faits et se rouvre après votre connexion.
# $reasons : les marqueurs de redémarrage en attente posés par Windows, d'après les noms prepare-reason-*.
prepare-reboot-reasons = Votre PC doit redémarrer pour terminer l’installation des mises à jour ({ $reasons }). Atlas enregistre les choix que vous avez déjà faits et se rouvre après votre connexion.
# Sous le message de redémarrage : le bouton redémarre Windows sans compte à rebours.
prepare-reboot-save-work = Enregistrez d’abord votre travail et fermez vos applications. Votre PC redémarre immédiatement lorsque vous choisissez Redémarrer et continuer.
# Affiché à la place d'un nouveau redémarrage lorsque Windows en redemande un juste après avoir redémarré.
prepare-restart-persists = Votre PC a redémarré, mais Windows indique toujours qu’un redémarrage est nécessaire ({ $reasons }) : redémarrer à nouveau n’y changera probablement rien. Choisissez Ouvrir Windows Update et terminez ce qui y est en attente, puis choisissez Réessayer. Si rien n’est en attente, choisissez Envoyer un rapport.
# Noms des marqueurs posés par Windows lorsqu'il demande un redémarrage. Ils complètent
# « Windows doit redémarrer (…) » ; courts et en minuscules.
prepare-reason-servicing = la maintenance de Windows
prepare-reason-windows-update = Windows Update
prepare-reason-file-renames = des fichiers en attente de remplacement
prepare-reason-update-agent = le service Windows Update
prepare-reason-unknown = motif non indiqué
prepare-failed = Choisissez Réessayer. En cas de nouvel échec, terminez les mises à jour restantes dans Windows Update ou le Microsoft Store, ou choisissez Envoyer un rapport.
prepare-failed-title = Certaines mises à jour n’ont pas pu se terminer
# La mise à jour s'est terminée sans écrire de résultat, par exemple après la fermeture d'Atlas pendant son exécution. « Rechercher et installer les mises à jour » est prepare-start.
prepare-ended-unconfirmed = La mise à jour s’est arrêtée sans indiquer de résultat, Atlas ne peut donc pas confirmer que Windows et les applications du Store sont à jour. Choisissez Réessayer pour rechercher les mises à jour.
prepare-unconfirmed-title = Impossible de confirmer le résultat des mises à jour
# « Rechercher et installer les mises à jour » est prepare-start, son bouton dans cet état.
prepare-cancelled = Les mises à jour ont été arrêtées. Certaines ont peut-être déjà été installées. Choisissez Rechercher et installer les mises à jour pour les terminer avant de continuer.
prepare-windows-search = Recherche de mises à jour Windows…
prepare-windows-download = Téléchargement des mises à jour Windows…
prepare-windows-install = Installation des mises à jour Windows…
prepare-store-search = Vérification du Microsoft Store…
prepare-store-install = Mise à jour du Microsoft Store et de ses applications…
prepare-stop-description = Atlas s’arrête une fois l’opération en cours terminée. Gardez Atlas ouvert jusque-là.
prepare-stop = Arrêter les mises à jour
prepare-restart = Redémarrer et continuer
prepare-start = Rechercher et installer les mises à jour
# Sous le bouton de préparation lorsqu'il est indisponible.
prepare-blocked-source = Indisponible, car cette installation ne peut pas continuer. Consultez le message en haut de la page.
# $check est le titre check-supported-build (texte).
prepare-needs-build-check = Disponible lorsque la vérification { $check } réussit dans Vérifications du PC.
# Sous le bouton de préparation, et sous la vérification Administrateur, tant que les fichiers d'installation sont encore en cours de téléchargement ou de décompression.
prepare-wait-for-package = Disponible lorsque les fichiers d’installation sont prêts.
iso-username = Nom du compte local
iso-account-description = L’installation de Windows crée un compte local portant ce nom : vous n’avez donc pas besoin de compte Microsoft. Windows vous demandera de choisir un mot de passe lors de votre première connexion.
iso-username-placeholder = Votre nom
iso-account-empty = Saisissez un nom de compte local pour continuer
iso-account-invalid = Utilisez 20 caractères au maximum, sans espace au début ni à la fin, et aucun de ces caractères : " / \ [ ] : ; | = , + * ? < > @
iso-account-trailing-dot = Le nom ne peut pas se terminer par un point.
iso-account-reserved = Windows utilise ce nom pour un compte intégré. Choisissez un autre nom.
iso-privacy-defaults = Avec cette ISO, l’installation de Windows ignore les écrans de licence, de compte Microsoft et de confidentialité, et désactive le partage facultatif de données et les offres personnalisées.
prepare-drivers = Comment installer les pilotes ?
prepare-drivers-auto = Obtenir les pilotes via Windows Update
prepare-drivers-auto-detail = Windows recherche les pilotes adaptés à votre matériel. Recommandé pour la plupart des PC.
prepare-drivers-manual = Installer les pilotes moi-même
prepare-drivers-manual-detail = Windows Update n’installera pas de pilotes : vous devrez les obtenir auprès du fabricant de votre PC ou de vos périphériques. Les pilotes déjà installés sont conservés.
prepare-drivers-description = Les pilotes permettent à Windows d’utiliser votre matériel, comme la carte graphique, le son et le Wi-Fi. Si vous modifiez ce choix après la mise à jour, Atlas devra rechercher à nouveau les mises à jour.
prepare-network-needed = Les mises à jour nécessitent une connexion Internet non limitée. Connectez-vous en Wi-Fi ou par Ethernet, puis choisissez Réessayer. Si aucun réseau Wi-Fi ne s’affiche, installez d’abord votre pilote réseau.
# Connecté, mais Windows n'a trouvé aucun accès à Internet (portail captif, ou filtrage DNS ou pare-feu).
prepare-network-limited = Windows indique que ce réseau n’a pas accès à Internet. Connectez-vous au réseau s’il le demande, ou vérifiez votre routeur et tout filtrage DNS ou par pare-feu, puis réessayez.
# « Connexion limitée » est le nom de l'interrupteur dans les paramètres réseau de Windows.
prepare-network-metered = Cette connexion est définie comme limitée ou soumise à une limite de données. Connectez-vous à un réseau non limité, ou désactivez Connexion limitée dans les paramètres réseau, puis réessayez.
prepare-network-settings = Ouvrir les paramètres réseau
iso-target-title = Sur quel PC allez-vous réinstaller Windows ?
iso-target-this = Ce PC
# Under This PC (iso-target-this), before it's chosen.
iso-target-this-description = Atlas peut ajouter les pilotes Wi-Fi et Ethernet de ce PC à l’ISO, pour que Windows puisse se connecter à Internet dès sa réinstallation.
iso-target-other = Un autre PC
iso-copy-network = Inclure les pilotes réseau de ce PC
iso-network-detail = Réutilise les pilotes Wi-Fi et Ethernet de ce PC pendant l’installation de Windows. Vous devrez ensuite vous reconnecter au Wi-Fi.
iso-network-source = Source des pilotes réseau
iso-network-installed = Utiliser les pilotes installés
iso-network-updated = Rechercher d’abord sur Windows Update
iso-network-updated-detail = Télécharge les pilotes compatibles proposés par Windows Update et conserve les pilotes installés en secours. Nécessite une connexion non limitée.
iso-stage-network-drivers = Préparation des pilotes réseau
iso-network-failed = Impossible de préparer les pilotes réseau. Consultez les diagnostics ou revenez en arrière pour changer l’option des pilotes réseau.
# Under iso-complete when Include this PC's network drivers was chosen but the adapters use
# drivers that come with Windows, so none were added.
iso-network-inbox = Les cartes réseau de ce PC utilisent des pilotes fournis avec Windows : l’ISO n’a donc pas besoin de les inclure.
iso-mode-desktop = Terminer la configuration avant le bureau
iso-mode-desktop-description = Atlas enregistre vos choix dans l’ISO. Après votre connexion, Atlas termine les mises à jour et l’installation avant l’ouverture du bureau Windows.
desktop-setup-description = Terminez la configuration du PC. Vos choix Atlas sont enregistrés ; vous pouvez revenir à Windows si nécessaire.
desktop-setup-exit = Continuer dans Windows

# Windows installation USB (Beta)
usb-title = Créer une clé d’installation
usb-existing = Créer une clé USB depuis une ISO existante
usb-description = Copiez une ISO sur une clé USB pour pouvoir réinstaller Windows à partir de celle-ci. Utilisez une ISO créée par Atlas pour installer Atlas en même temps.
usb-choose-iso = Choisir une ISO
usb-drive = Clé USB
usb-empty = Aucune clé USB trouvée. Branchez une clé USB d’au moins { $min } Go, puis choisissez Actualiser. Les supports de plus de { $max } To, les supports en lecture seule et le disque sur lequel Windows s’exécute ne sont pas affichés.
usb-refresh = Actualiser
# Affiché lorsque la liste des clés n'a pas pu être lue.
usb-scan-failed = Vérifiez que la clé est branchée, puis choisissez Actualiser. Pour plus de détails, choisissez Ouvrir le dossier des journaux.
usb-scan-failed-title = Impossible de lire la liste des clés USB
# Éléments de la ligne de détail d'une clé, reliés par usb-detail-separator ; les éléments vides sont omis.
# $size est un nombre de gigaoctets formaté (texte) ; $volumes et $serial sont du texte.
usb-drive-size = { $size } Go
usb-drive-serial = N° de série : { $serial }
usb-detail-separator = { " · " }
usb-review = Vérifier la clé USB
usb-erase-title = Effacer cette clé USB ?
usb-erase-description = Tout le contenu de { $drive } ({ $size } Go) sera définitivement effacé, y compris tous les fichiers et partitions. Copiez d’abord sur un autre disque tout ce que vous souhaitez conserver. Votre ISO ne sera pas effacée.
usb-layout = Atlas utilise jusqu’à 32 Go de la clé et laisse le reste inutilisé. La clé USB fonctionne sur les PC qui démarrent en mode UEFI, requis par Windows 11.
usb-ack = Je comprends que tout le contenu de cette clé USB sera effacé
usb-write = Effacer et créer la clé
usb-stage-prepare = Préparation des fichiers d’installation…
usb-stage-format = Formatage de la clé USB…
usb-stage-copy = Copie des fichiers d’installation…
usb-stage-verify = Vérification de la clé USB…
usb-working = Gardez Atlas ouvert et la clé USB branchée. Si vous annulez, la clé USB incomplète ne pourra pas servir à installer Windows.
# Titres de la barre d'erreur, de la barre de réussite et de l'invite de fermeture pendant l'écriture d'une clé.
usb-failed-title = La création de la clé USB n’a pas pu aboutir
usb-complete-title = Votre clé USB est prête
usb-close-title = La création de la clé USB est en cours
# Après le début possible de l'effacement.
usb-failed = La clé a peut-être déjà été effacée : elle ne permet donc pas encore d’installer Windows. Assurez-vous qu’elle est branchée, puis choisissez Vérifier la clé USB pour réessayer. Si vous l’avez rebranchée, choisissez d’abord Actualiser et sélectionnez-la à nouveau.
# Avant toute modification de la clé : en général, puis pour les raisons signalées par le processus d'écriture.
usb-failed-unchanged = Votre clé USB n’a pas été modifiée. Choisissez Ouvrir le dossier des journaux pour voir ce qui a échoué, puis Vérifier la clé USB pour réessayer.
usb-failed-iso = Cette ISO ne permet pas de créer une clé d’installation. Choisissez une ISO créée par Atlas, ou une ISO Windows 11 de Microsoft d’une version prise en charge par Atlas. Votre clé USB n’a pas été modifiée.
usb-failed-location = L’ISO ou Atlas Manager se trouve sur cette clé USB, sur un emplacement réseau ou dans un dossier lié. Déplacez le fichier concerné dans un dossier local de ce PC, puis réessayez. Votre clé USB n’a pas été modifiée.
usb-failed-space = L’espace libre est insuffisant sur le disque Windows pour préparer les fichiers d’installation. Libérez de l’espace, puis réessayez. Votre clé USB n’a pas été modifiée.
usb-failed-fit = Les fichiers d’installation ne tiennent pas sur cette clé USB. Utilisez une clé de plus grande capacité, puis réessayez. Votre clé USB n’a pas été modifiée.
usb-failed-drive-changed = La clé USB a été retirée, rebranchée ou remplacée après la lecture de la liste. Choisissez Actualiser, sélectionnez à nouveau la clé, puis choisissez Vérifier la clé USB. Votre clé USB n’a pas été modifiée.
usb-cancelled = La clé peut contenir des fichiers d’installation incomplets. Recréez-la avant de l’utiliser pour installer Windows.
usb-cancelled-title = Création de la clé USB annulée
usb-cancelled-unchanged = Votre clé USB n’a pas été modifiée.
usb-complete = Atlas a vérifié chaque fichier. Choisissez Éjecter la clé USB, puis sauvegardez les fichiers du PC à réinstaller. Branchez la clé sur ce même PC, puis démarrez-le depuis la clé USB à l’aide de son menu de démarrage (souvent F12, F11 ou Échap au démarrage du PC).
usb-eject = Éjecter la clé USB
usb-ejected = Vous pouvez maintenant débrancher la clé USB. Sauvegardez les fichiers du PC à réinstaller. Démarrez ensuite ce même PC depuis la clé USB à l’aide de son menu de démarrage (souvent F12, F11 ou Échap au démarrage).
usb-eject-failed = Fermez les fichiers ou fenêtres qui l’utilisent, puis réessayez.
usb-eject-failed-title = Impossible d’éjecter la clé USB
ready-fresh-title = Atlas est conçu pour une nouvelle installation de Windows
ready-fresh-description = Si vous utilisez déjà Windows sur ce PC, sauvegardez vos fichiers et réinstallez Windows avant de continuer. Assurez-vous d’abord que la vérification Compatibilité de Windows réussit dans Vérifications du PC, pour réinstaller une version prise en charge.
# Famille (Home), LTSC et Server sont les éditions que la vérification refuse ; les autres sont des exemples d'éditions acceptées. Noms tels que Windows les affiche en français.
detail-edition-unsupported = Les éditions Famille, LTSC et Server de Windows 11 ne sont pas prises en charge. Utilisez une autre édition, comme Professionnel, Éducation ou Entreprise. Si Windows n’a pas pu identifier votre édition, résolvez ce problème avant de continuer.
install-source-title = Installation indisponible
install-source-unsupported = Atlas { $source } ne peut pas être mis à jour directement vers { $target }. Pour utiliser cette version, sauvegardez vos fichiers et réinstallez Windows.
# Avant le choix d'un package : la version proposée n'est pas encore connue.
install-source-unsupported-any = Atlas { $source } ne peut pas être mis à jour directement. Pour utiliser une version plus récente, sauvegardez vos fichiers et réinstallez Windows.
# « Ouvrir un fichier de package » est package-open-file. $folder est un chemin de dossier (texte).
install-source-resume = Une installation d’Atlas { $target } ne s’est pas terminée, et seul le package Atlas { $target } permet de l’achever. Choisissez Ouvrir un fichier de package et sélectionnez ce package Atlas (.apbx). Si Atlas l’a téléchargé, il se trouve dans { $folder }.
# Version de test : seul le package Atlas intégré peut être installé.
install-source-resume-bundled = Une installation d’Atlas { $target } ne s’est pas terminée. Cette version de test ne peut installer que son package Atlas intégré : terminez donc cette installation avec le package Atlas { $target } dans une version publiée d’Atlas Manager.
install-source-unknown = Atlas n’a pas pu confirmer ce qui est déjà installé sur ce PC et n’installera donc rien pour le moment. Choisissez Envoyer un rapport pour que l’équipe Atlas puisse vous aider.
# $problem est l'un des messages install-source-* ; $error est un message d'erreur brut (texte).
install-source-details = { $problem } Détails : { $error }
iso-edition-selection = Seules les éditions prises en charge sont incluses. Lors de l’installation de Windows, choisissez une édition pour laquelle vous disposez d’une licence Windows.
detail-windows-preview = Les builds Insider ne sont pas prises en charge. Utilisez une version publique de Windows 11.
detail-windows-release-unknown = Atlas n’a pas pu confirmer que cette build de Windows est une version publique. Connectez-vous à Internet et vérifiez à nouveau.
iso-release-unknown = Atlas n’a pas pu confirmer que cette ISO contient une version publique de Windows 11 prise en charge par le package Atlas. Connectez-vous à Internet, puis choisissez à nouveau Vérifier les fichiers. Si l’échec persiste, téléchargez de nouveau l’ISO auprès de Microsoft.
prepare-previous-worker = Des mises à jour lancées précédemment sont toujours en cours. Atlas attendra qu’elles se terminent, puis vous pourrez rechercher à nouveau les mises à jour.

ready-used-windows-title = Windows semble déjà utilisé sur ce PC
ready-used-windows-description = Windows a été installé sur ce PC il y a au moins une semaine ou contient déjà plusieurs applications. Installer Atlas ici n’est pas pris en charge et est fortement déconseillé : vos applications et paramètres existants risquent de ne pas fonctionner comme prévu, et Atlas supprime OneDrive, si bien que les fichiers qu’il contient ne sont plus synchronisés et que vos dossiers Bureau, Documents et Images peuvent sembler vides. Sauvegardez vos fichiers et réinstallez d’abord Windows, ou ne continuez que si vous acceptez ce risque.
ready-used-windows-dismiss = Continuer quand même

prepare-resumed = Votre PC a redémarré et Atlas a restauré les choix que vous aviez déjà faits. Choisissez Poursuivre les mises à jour pour les terminer avant d’installer Atlas.
prepare-continue = Poursuivre les mises à jour
prepare-saving-restart = Enregistrement de vos choix et configuration de la réouverture d’Atlas après le redémarrage de Windows…
prepare-restart-save-failed = Vos choix n’ont pas pu être enregistrés. Réessayez avant de redémarrer.
prepare-restart-registration-failed = Vos choix sont enregistrés, mais Atlas n’a pas pu prévoir sa réouverture après le redémarrage. Réessayez, ou redémarrez votre PC vous-même et ouvrez Atlas après votre connexion.
prepare-restart-failed = Atlas n’a pas pu redémarrer votre PC. Réessayez ou redémarrez-le depuis le menu Démarrer. Vos choix sont enregistrés et Atlas se rouvrira après votre connexion.
diagnostics-export = Exporter les diagnostics
diagnostics-exporting = Collecte des diagnostics…
diagnostics-privacy = Envoyez un rapport en privé à l’équipe Atlas, ou exportez un ZIP de diagnostic à partager quand vous demandez de l’aide. Atlas en retire votre nom d’utilisateur, le nom de votre PC et vos adresses e-mail.
# Titre de la barre de résultat après une exportation ; son bouton est iso-open-folder.
diagnostics-saved = ZIP de diagnostic créé
diagnostics-failed-title = Impossible d’exporter les diagnostics
# $error est l'erreur brute (texte).
diagnostics-failed = Vérifiez que votre PC dispose d’espace disque libre, puis réessayez. Détails : { $error }

## Tester builds (embedded-playbook feature)

# One line of chrome under the title bar on a release-candidate build.
rc-banner = Version de test Atlas { $release }. Cette application n’installe que le package Atlas intégré.
home-status-bundled = Version de test { $release }
package-bundled = Atlas { $version }, intégré à cette version de test, est prêt à être installé.
rc-about-release = Version de test
rc-about-commit = Commit source
rc-about-package = Package Atlas intégré (SHA-256)
iso-package-bundled = Le package Atlas intégré à cette version de test
prepare-percent = { $percent } % de cette opération
prepare-count = Mises à jour terminées : { $completed } sur { $total }
prepare-bytes = { $downloaded } sur environ { $total } Mo téléchargés
prepare-elapsed = Temps écoulé : { $minutes } min { $seconds } s
prepare-progress-waiting = En attente du service de mise à jour. Aucun pourcentage n’est disponible pour cette opération.
prepare-progress-unchanged = Aucune progression depuis { $minutes } min. Les mises à jour volumineuses peuvent prendre du temps : gardez Atlas ouvert. Pour plus de détails, choisissez Ouvrir le dossier des journaux.
prepare-report-delayed = Windows n’a signalé aucune progression depuis { $seconds } s. Les mises à jour sont peut-être encore en cours : gardez Atlas ouvert.

prepare-affected-app = l’application concernée
prepare-app-in-use = Fermez { $app }, puis réessayez. Windows ne peut pas mettre à jour cette application tant qu’elle est ouverte. Si vous ne trouvez pas sa fenêtre, fermez l’application dans le Gestionnaire des tâches. Si l’échec persiste, redémarrez votre PC et réessayez avant d’ouvrir { $app }.
prepare-install-busy = Une autre installation ou un redémarrage requis bloque les mises à jour. Attendez la fin des autres installations, redémarrez votre PC si Windows vous le demande, puis réessayez.
# Causes signalées par le processus de mise à jour. Son propre message en anglais est affiché en dessous comme détail.
prepare-failed-session-owner = Atlas s’exécute sous un autre compte que celui connecté à Windows. Connectez-vous à Windows avec un compte administrateur, ouvrez Atlas depuis ce compte, puis réessayez.
prepare-failed-store-missing = Le Microsoft Store n’est pas configuré pour votre compte. Ouvrez le Microsoft Store une fois, ou réinstallez-le s’il est absent, puis réessayez.
prepare-failed-store-battery = Le Microsoft Store a suspendu les mises à jour pour économiser la batterie. Branchez votre PC sur le secteur, puis réessayez.
prepare-failed-store-network = Le Microsoft Store a suspendu les mises à jour jusqu’à ce que votre PC dispose d’une connexion non limitée. Connectez-vous en Wi-Fi ou par Ethernet avec une connexion non limitée, puis réessayez.
prepare-failed-store-timeout = Les applications du Store n’ont pas fini de se mettre à jour. Terminez les téléchargements restants dans le Microsoft Store, puis réessayez.
prepare-failed-store-passes = Le Microsoft Store a continué à proposer de nouvelles mises à jour. Terminez les mises à jour restantes dans le Microsoft Store, puis réessayez.
prepare-failed-manual-updates = Certaines mises à jour Windows doivent être terminées dans Windows Update. Ouvrez Windows Update, terminez-les, puis réessayez.
prepare-failed-windows-passes = Windows Update a continué à proposer de nouvelles mises à jour. Terminez les mises à jour restantes dans Windows Update, puis réessayez.
prepare-error-code = Code d’erreur : { $code }
prepare-open-store = Ouvrir Microsoft Store

check-user-account = Compte utilisateur
detail-user-account-ok = Le contrôle de compte d’utilisateur est activé et votre compte est prêt pour l’installation.
detail-user-account-not-ready = Activez le contrôle de compte d’utilisateur (UAC), redémarrez votre PC, puis réessayez. Si vous utilisez le compte Administrateur intégré, connectez-vous avec un autre compte administrateur.
detail-user-account-unknown = Atlas n’a pas pu vérifier votre compte utilisateur. Vérifiez à nouveau avant l’installation. Windows a signalé : { $error }

footer-prepare-required = Terminez la mise à jour de Windows et des applications du Store pour continuer
footer-prepare-stopping = Arrêt des mises à jour après l’opération en cours…
resume-choices-title = Reprise de votre installation précédente
resume-choices-detail = Pour terminer cette installation, Atlas a restauré les choix que vous aviez faits la dernière fois. Vous ne pourrez pas les modifier à l’étape Vos choix tant que cette installation n’est pas terminée.

## Voluntary reports
report-title = Envoyer un rapport
report-received = Rapport reçu
report-reference = Conservez cette référence si vous contactez l’équipe Atlas au sujet de ce rapport. Si vous avez laissé vos coordonnées, l’équipe peut les utiliser pour vous répondre, mais une réponse n’est pas garantie.
# Nom accessible du bouton Copier à côté de la référence du rapport.
report-copy-reference = Copier la référence du rapport
report-another = Envoyer un autre rapport
# Libellé du choix entre les deux types de rapport.
report-kind = Que souhaitez-vous envoyer ?
report-kind-issue = Un problème
report-kind-suggestion = Une suggestion
report-intro = Décrivez ce qui s’est passé ou ce que vous aimeriez changer ({ $min } à { $max } caractères). N’indiquez aucun mot de passe dans votre message.
report-message = Votre message
report-message-placeholder = J’essayais de…
report-contact = Coordonnées (facultatif)
report-contact-placeholder = Adresse e-mail ou nom d’utilisateur Discord
report-attach = Joindre les diagnostics
report-attach-description = Journaux et informations système qui aident à trouver la cause. Atlas retire votre nom d’utilisateur, le nom du PC, les adresses e-mail ainsi que les mots de passe ou clés connus. Les détails des erreurs, les modèles de matériel et les noms d’applications sont conservés. Vous pouvez vérifier le ZIP avant l’envoi.
report-prepare = Préparer les diagnostics
report-review = Vérifier le ZIP
report-prepare-failed-title = Impossible de préparer les diagnostics
# $error est un message d'erreur brut (texte).
report-prepare-failed = Préparez à nouveau les diagnostics, ou désactivez Joindre les diagnostics pour envoyer votre rapport sans eux. Détails : { $error }
report-privacy = Votre rapport est envoyé en privé à l’équipe Atlas sur reports.atlasos.net. Votre message et vos coordonnées sont envoyés tels que vous les avez saisis. L’équipe peut faire appel à des services d’IA d’autres entreprises pour l’aider à analyser le problème. Ces services reçoivent votre message et les diagnostics, mais pas vos coordonnées. Les rapports sont supprimés au bout de 90 jours, et les journaux de sécurité du serveur peuvent enregistrer votre adresse IP.
report-website = Confidentialité et site de signalement
report-consent = J’accepte d’envoyer ce rapport et les éventuels diagnostics joints à l’équipe Atlas
report-failed = Votre message est conservé. Vérifiez votre connexion Internet, puis choisissez Réessayer, ou envoyez votre rapport depuis le site de signalement.
report-failed-busy = Le service de signalement est occupé. Votre message est conservé. Réessayez plus tard.
report-failed-outdated = Cette version d’Atlas Manager ne peut plus envoyer de rapports. Votre message est conservé : copiez-le sur le site de signalement. Si vous avez joint les diagnostics, choisissez Vérifier le ZIP et joignez aussi le ZIP sur le site.
report-failed-diagnostics = Les diagnostics préparés ne peuvent pas être envoyés. Votre message est conservé. Préparez à nouveau les diagnostics ou désactivez Joindre les diagnostics.
# Lien sous un rapport qui n'a pas été envoyé.
report-failed-website = Ouvrir le site de signalement
report-sending = Envoi…
report-send = Envoyer le rapport

report-validation-message = Saisissez entre { $min } et { $max } caractères.

report-validation-contact = Limitez les coordonnées à { $max } caractères.

report-validation-consent = Confirmez votre accord pour envoyer ce rapport.

report-failed-title = Rapport non envoyé
