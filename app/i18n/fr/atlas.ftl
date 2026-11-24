### Atlas Manager: French (fr). Preview translation, revised on 24 November 2026 from the en-GB source (i18n/en-GB/atlas.ftl).
###
### Conventions pour cette langue : vouvoiement ; espace insécable (U+00A0) avant
### « : ; ? ! % » et à l'intérieur des guillemets « » ; apostrophe typographique (’) ;
### boutons à l'infinitif ; titres et libellés sans point final ; « relancer »
### désigne l'application Atlas, « redémarrer » désigne le PC ou Windows.
### Le fichier .atlaspkg est le « package Atlas » (masculin), puis « le package ».
### Les interrupteurs de Sécurité Windows sont des « paramètres de protection ».
### Étapes de l'installation : Préparation, Vos choix, Sécurité Windows, Installation.
### Étapes de l'ISO : Windows, Configuration, Création. « étape » ne désigne que ces
### étapes ; une phase de mise à jour, d'ISO ou de clé USB est une « opération ».
### Windows Setup est le « programme d'installation de Windows ». Une ISO est féminine.
### Un USB drive est une « clé USB » (« la clé » ensuite). Shift s'écrit « Maj ».
### Les noms de paramètres, de vérifications et de choix insérés dans une phrase
### suivent un deux-points (« Ces paramètres… : { $switches } ») pour éviter les accords.
### Pluriels : one (0 et 1) et other.

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
# Accessible name of a button that acts on one card. $action is the button's label;
# $section is the title of its card.
common-details-a11y = { $action }, { $section }
# Opens the folder of the install log, with the log selected.
common-open-log-folder = Ouvrir le dossier des journaux
# Nom accessible du bouton Copier à côté du journal d'installation.
common-copy-install-log = Copier le journal d’installation
common-install-log = Journal d’installation
# Libellés de ligne dans les cartes de résumé.
common-windows = Windows
common-package = Package Atlas
common-checking = Vérification en cours
# Sépare deux éléments d'une liste : « Brave, Firefox ». Les accolades conservent l'espace.
list-separator = { ", " }
# Relie deux alternatives : « 26100 ou 26200 ».
list-or = { $a } ou { $b }
# Joins the last two items of a list; $a may itself be several items joined with list-separator.
list-and = { $a } et { $b }
# Accessible name of a message bar that announces itself: its title, then its message.
infobar-a11y = { $title }. { $message }

## Fenêtre

# Dialog shown when the window is closed while an install runs. Its buttons are
# window-close-keep and window-close-close.
window-close-title = Fermer la fenêtre pendant l’installation ?
window-close-installing = L’installation continue. Rouvrez Atlas pour voir le résultat.
# Instead of window-close-installing when only an open Atlas window can restart the PC afterwards.
window-close-installing-no-restart = L’installation continue, mais votre PC ne redémarrera pas de lui-même. Rouvrez Atlas pour voir le résultat.
# The answer that keeps the window open when closing it would interrupt something.
window-close-keep = Garder la fenêtre ouverte
window-close-close = Fermer la fenêtre
# Closing during the final checks, before the installer has started. Its buttons are
# window-close-keep-installing and window-close-stop-and-close.
window-close-checks-question = Arrêter avant l’installation ?
window-close-checks-unchanged = L’installation n’a encore rien modifié. Si vous fermez Atlas, elle ne démarrera pas.
window-close-keep-installing = Poursuivre l’installation
window-close-stop-and-close = Arrêter et fermer
# Closing while Windows and Store apps update. Its buttons are stop-update-keep and prepare-stop.
prepare-close-question = Arrêter les mises à jour ?
# « Opération » : une phase de la mise à jour (comme dans prepare-percent), pas une des quatre étapes.
prepare-close-stops-after-stage = Atlas s’arrête après l’opération en cours. Vous pourrez alors le fermer.
# Closing during the restart countdown after a successful install. Its buttons are restart-now
# and restart-dont-now.
window-close-restart-question = Redémarrer pour terminer la configuration d’Atlas ?
window-close-restart-closed = Une fois fermé, Atlas ne peut pas redémarrer votre PC. Enregistrez d’abord votre travail.
# Closing while Get ready counts down to the restart updates need. Atlas opens again after
# the next restart.
window-close-update-restart-question = Redémarrer pour terminer les mises à jour ?
window-close-update-restart-later = Enregistrez d’abord votre travail. Si vous redémarrez plus tard, Atlas reprendra après le redémarrage.
# Closing during a setup with Windows Security switches still off. Its message is
# window-close-protection-all or window-close-protection-some.
window-close-protection-title = Fermer Atlas avec la protection désactivée ?
window-close-protection-all = Les quatre paramètres de protection de Sécurité Windows sont désactivés. Si vous n’installez pas Atlas maintenant, réactivez-les d’abord.
# $switches names the switches that are off, joined like a list; $count is how many there are.
window-close-protection-some =
    { $count ->
        [one] Ce paramètre est désactivé dans Sécurité Windows : { $switches }. Si vous n’installez pas Atlas maintenant, réactivez-le d’abord.
       *[other] Ces paramètres sont désactivés dans Sécurité Windows : { $switches }. Si vous n’installez pas Atlas maintenant, réactivez-les d’abord.
    }
# Closing while an ISO or a USB drive is being created. Their buttons are
# window-close-keep-creating and window-close-stop.
iso-close-question = Arrêter la création de l’ISO ?
iso-close-safe-point = Atlas s’arrête au prochain point d’arrêt sûr.
usb-close-question = Arrêter la création de la clé USB ?
usb-close-unfinished = Une clé incomplète ne permet pas d’installer Windows.
window-close-keep-creating = Poursuivre la création
window-close-stop = Arrêter
# Le bouton Ouvrir du sélecteur de fichier pour un package Atlas (.atlaspkg). Restez bref.
file-dialog-open-package = Ouvrir un package Atlas (.atlaspkg)
# Message affiché par Windows dans sa notification de redémarrage.
shutdown-comment = Atlas est installé. Windows redémarre pour terminer la configuration.
# Message affiché par Windows lorsque l'étape Préparation redémarre pour terminer
# l'installation des mises à jour Windows.
prepare-shutdown-comment = Atlas redémarre Windows pour terminer l’installation des mises à jour.

## Système

# « Windows 11 Professionnel, version 25H2 (build 26200.1234) ». Les trois valeurs sont du texte.
system-description = { $product }, version { $version } (build { $build })

## Page d'accueil

home-not-installed = Bienvenue dans Atlas
# Under home-not-installed: this PC's Windows, such as "Windows 11 Pro, version 25H2". Both values are text.
home-windows = { $product }, version { $version }
# Instead of home-windows once Atlas has found its latest release: this PC's Windows and the Atlas
# version Install Atlas would install, such as "Windows 11 Pro, version 25H2 · Atlas 0.6.1".
# $product and $version are this PC's Windows edition and version, and $atlas is the Atlas version (all text).
home-windows-atlas = { $product }, version { $version } · Atlas { $atlas }
# Under home-windows or home-windows-atlas, on a PC without Atlas: what Atlas does, in one sentence.
# Keep it to what Atlas changes: don't promise a faster PC.
home-about = Atlas réduit l’activité en arrière-plan et les distractions dans Windows.
# Le titre lorsqu'Atlas Manager ne peut pas savoir ce qui est installé sur ce PC.
home-state-unknown = Atlas sur ce PC
# Le titre lorsqu'Atlas est installé. $version est du texte.
home-version = Atlas { $version }
# $date est une date formatée.
home-installed-on = Installé le { $date }
home-status-checking = Recherche de mises à jour…
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
# Asked by Install Atlas where Windows on this PC has been in use. Its buttons are
# common-cancel and home-used-windows-install.
home-used-windows-title = Installer Atlas sur ce PC ?
home-used-windows-message = Vos applications et paramètres actuels risquent de ne plus fonctionner. Atlas supprime aussi OneDrive : ses fichiers ne sont plus synchronisés et des dossiers peuvent sembler vides. Sauvegardez d’abord vos fichiers.
home-used-windows-install = Installer quand même
# The card that opens ISO creation; its button is iso-open.
home-iso-title = Réinstaller Windows avec Atlas
# Under home-iso-title, with the Recommended badge, where Windows on this PC has been in use.
home-iso-used = Windows est déjà utilisé sur ce PC, et Atlas fonctionne mieux sur une nouvelle installation.
# A bar on Home after an installation finished, until the PC restarts.
home-restart-title = Votre PC doit redémarrer
# Instead of restart-needed when Windows refused to restart.
home-restart-failed = Atlas n’a pas pu redémarrer votre PC. Redémarrez-le depuis le menu Démarrer.
home-security-reminder-title = Réactivez votre protection
# Instead of home-security-reminder-title when no switch reads off but some couldn't be read.
home-security-reminder-unreadable-title = Vérifiez que votre protection est activée
# Under home-security-reminder-title. $switches names the switches that read off (protection-*),
# joined with list-separator and list-and; $count is how many it names.
security-switches-still-off =
    { $count ->
        [one] Ce paramètre est toujours désactivé dans Sécurité Windows : { $switches }.
       *[other] Ces paramètres sont toujours désactivés dans Sécurité Windows : { $switches }.
    }
# Instead of security-switches-still-off when some switches couldn't be read. $switches names those.
home-security-reminder-unreadable-message = Atlas n’a pas pu lire tous les paramètres de protection. Vérifiez dans Sécurité Windows que ces paramètres sont activés : { $switches }.
home-elevation-title = Atlas a besoin d’une autorisation pour lancer l’installation
# Under home-elevation-title when the setup choices couldn't be saved.
home-elevation-draft-not-saved = Atlas n’a pas pu enregistrer vos choix de configuration et n’a donc pas été relancé.
home-state-error-title = Impossible de lire les informations sur votre installation d’Atlas
home-state-error-problem = Votre version d’Atlas, vos choix et votre historique risquent de ne pas s’afficher correctement.
# A bar on Home when the Atlas package needs a newer Atlas Manager.
home-manager-needed-title = Atlas Manager doit être mis à jour
home-whats-new = Nouveautés d’Atlas { $version }
home-view-release = Voir les notes de version sur GitHub
home-show-less = Afficher moins
home-show-full-notes = Afficher toutes les notes de version
home-your-install = Votre configuration Atlas
# Atlas est installé, mais sans l'enregistrement que tient Atlas Manager (les anciennes versions n'en écrivaient pas).
home-install-unrecorded = Ce PC ne conserve aucune trace de la façon dont Atlas a été installé. Vos choix et l’historique des installations ne peuvent donc pas être affichés.
home-history = Historique des installations
# Une ligne d'historique. $version est du texte, $mode l'un des messages history-mode-*, $date une date et heure formatées.
home-history-entry = Atlas { $version } · { $mode } · { $date }
# Nom accessible d'une étape numérotée.
home-step-a11y = Étape { $number } : { $title }
# Accessible name of a numbered step with its sentence, as screen readers read each step of
# Home's lists. $step is home-step-a11y or stepper-item-a11y, and $detail is the step's sentence,
# such as home-step-ready.
home-step-detail-a11y = { $step }. { $detail }
# The card on Home that lists the four install steps (step-ready, step-options, step-security and
# step-install) on a PC without Atlas, each with its home-step-* sentence beside it.
home-steps-title = Déroulement
# Instead of home-steps-title while a setup is under way: each step shows whether it's done, current
# or still to come.
home-steps-under-way-title = Configuration d’Atlas en cours
# Beside step-ready in that card.
home-step-ready = Atlas vérifie votre PC et met à jour Windows.
# Instead of home-step-ready where Windows must move to a newer version before Atlas can install.
# $release is that version, such as "26H2" (text).
home-step-ready-move = Atlas vérifie votre PC et fait passer Windows à la version { $release }.
# Beside step-options in that card. Microsoft Defender is one of the choices asked there.
home-step-options = Vous choisissez ce que vous conservez, par exemple Microsoft Defender.
# Beside step-security in that card.
home-step-security = Vous désactivez les quatre paramètres de protection de Sécurité Windows.
# Beside step-install in that card. $minutes is how long installing usually takes, from the Atlas
# package (a number). The first is shown when the PC restarts by itself after installing, as set in
# settings-restart-automatically, and the second when the person restarts it.
home-step-install-restarts =
    { $minutes ->
        [one] L’installation prend en général environ { $minutes } minute, puis votre PC redémarre.
       *[other] L’installation prend en général environ { $minutes } minutes, puis votre PC redémarre.
    }
home-step-install-restart-yourself =
    { $minutes ->
        [one] L’installation prend en général environ { $minutes } minute, puis vous redémarrez votre PC.
       *[other] L’installation prend en général environ { $minutes } minutes, puis vous redémarrez votre PC.
    }
# At the bottom of that card, under the four steps.
home-steps-save-work = Enregistrez d’abord votre travail : des applications peuvent se fermer et votre PC redémarrera.
home-github = Voir Atlas sur GitHub
home-discord = Rejoindre la communauté Atlas
home-report-problem = Signaler un problème

## Comment une installation a été faite (d'après le document d'état)

# Formes en minuscules utilisées dans une ligne d'historique.
history-mode-fresh = première installation
history-mode-upgrade = mise à jour
history-mode-reapply = réinstallation
history-mode-unknown = installation

## Avis sur la page d'accueil

# The raw error, and the file concerned, are behind Show details.
notice-settings-reset-title = Atlas utilise ses paramètres par défaut
notice-settings-unreadable-problem = Atlas n’a pas pu lire les paramètres enregistrés de l’application. Vos paramètres Windows n’ont pas changé.
notice-settings-damaged-kept-problem = Le fichier de paramètres de l’application était endommagé : Atlas l’a réinitialisé et a conservé une copie de l’ancien fichier.
notice-settings-damaged-problem = Le fichier de paramètres de l’application était endommagé. Atlas utilise les valeurs par défaut pour le moment.
notice-settings-not-saved-title = Impossible d’enregistrer les paramètres de l’application
notice-settings-not-saved-problem = Atlas n’a pas pu enregistrer vos dernières modifications : elles risquent d’être perdues à la fermeture d’Atlas. Si une autre fenêtre Atlas est ouverte, fermez-la, puis refaites la modification.
notice-session-unreadable-title = Impossible de vérifier l’installation précédente
# Its button, iso-open-folder, shows the install record in File Explorer.
notice-session-unreadable-problem = Atlas n’a pas pu déterminer si une installation précédente est encore en cours. Si vous avez la certitude qu’aucune ne l’est, supprimez son enregistrement d’installation, puis relancez Atlas.
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
# Accessible name of one step. $heading is step-heading; $status is one of the stepper-status-* messages.
stepper-item-a11y = { $heading }, { $status }
stepper-status-completed = terminée
stepper-status-current = en cours
stepper-status-upcoming = à venir
# A step already visited whose requirements aren't met yet.
stepper-status-attention = attention requise
# Names the step showing; read when the current step takes focus.
step-heading = Étape { $number } sur { $total } : { $title }
# Read when the current step on Your choices takes focus. $heading is stepper-item-a11y;
# $questions is what the screen asks.
step-heading-choices-a11y = { $heading }. { $questions }

## Étape 1 : Préparation
## Une liste de trois lignes (vérifications, package Atlas, mises à jour), chacune avec un
## titre et une ligne d'état. La préparation lance les mises à jour d'elle-même.

# Row title, as a checklist item.
ready-checks-title = Vérifier votre PC
# Status line while the checks run.
ready-checks-running = Vérification de votre PC…
ready-check-again = Vérifier à nouveau
ready-checks-passed =
    { $count ->
        [one] { $count } vérification réussie
       *[other] { $count } vérifications réussies
    }
# Status line when some checks need attention. Selects on $passed for agreement.
ready-checks-passed-some =
    { $passed ->
        [one] { $passed } vérification réussie
       *[other] { $passed } vérifications réussies
    } sur { $total }
# After ready-checks-passed-some: « 5 vérifications réussies sur 9 · 4 prises en charge par la
# mise à jour ». $count is how many updating takes care of; agrees with « vérification ».
ready-checks-handled =
    { $count ->
        [one] { $count } prise en charge par la mise à jour
       *[other] { $count } prises en charge par la mise à jour
    }
# Accessible state of a check that updating takes care of, after check-a11y's title.
check-state-updates = la mise à jour s’en charge
# Under the title of a check that updating takes care of.
check-updates-handled = Des mises à jour sont en attente. Atlas les installe pendant la mise à jour de Windows.
check-restart-handled = Windows doit redémarrer pour terminer des modifications antérieures. La mise à jour s’en charge.
check-handled = La mise à jour s’en charge.
# Row title: the Atlas version the package holds.
ready-package-title = Atlas { $version }
# Status lines of the package row.
ready-package-downloading = Téléchargement…
ready-package-unpacking = Extraction…
ready-package-ready = Prêt
ready-package-checking = Recherche de la dernière version…
# Tester build: the bundled Atlas package is being unpacked.
ready-package-bundled = Préparation du package Atlas intégré…
ready-package-none = Pas encore téléchargé
ready-package-failed = Impossible d’obtenir le package Atlas
# Under ready-package-failed, with package-download-again and package-open-file.
ready-package-failed-detail = Téléchargez-le à nouveau ou ouvrez un autre package Atlas (.atlaspkg).
# Tester build: the same, with Try again as the only control.
ready-package-bundled-failed-detail = Le package Atlas intégré à cette version de test n’a pas pu être extrait. Réessayez.
ready-package-manager = Nécessite un Atlas Manager plus récent
ready-package-release-failed = Impossible de rechercher la dernière version
ready-package-release-failed-detail = Vérifiez votre connexion Internet, puis réessayez. Si vous avez un package Atlas (.atlaspkg), vous pouvez l’ouvrir à la place.
# Row title.
ready-updates-title = Mises à jour de Windows et du Microsoft Store
# Status line before updating starts by itself.
ready-updates-pending = Les applications du Store, comme le Bloc-notes, peuvent se fermer pendant leur mise à jour. Enregistrez d’abord votre travail dans ces applications.
# While Windows moves to version $release.
ready-updates-after-move = Démarre une fois Windows passé à la version { $release }.
# After Atlas's own restart, until updating carries on by itself.
ready-updates-resumed = Reprise après le redémarrage…
ready-updates-restarting = Redémarrage de votre PC…
ready-updates-done = Windows et les applications du Store sont à jour.
# Instead of ready-updates-done where Microsoft Store is turned off.
ready-updates-done-windows = Windows est à jour.
# The countdown before the restart updating needs. Read when it shows, not every second.
ready-updates-restart-countdown =
    { $seconds ->
        [one] Votre PC redémarre dans { $seconds } seconde.
       *[other] Votre PC redémarre dans { $seconds } secondes.
    }
ready-updates-restart = Votre PC doit redémarrer pour terminer les mises à jour.
ready-updates-restart-finish = Windows doit redémarrer une fois de plus pour terminer l’installation de la version { $release }.
ready-updates-restart-failed = Votre PC n’a pas redémarré
# Under the restart's status line, before Restart now.
ready-updates-restart-save = Enregistrez d’abord votre travail.
ready-updates-restart-persists = Windows demande toujours un redémarrage
# Under ready-updates-restart-persists, with Try again and check-fix-windows-update.
ready-updates-restart-persists-advice = Redémarrer à nouveau n’y changera probablement rien. Terminez ce qui est en attente dans Windows Update, puis réessayez.
# Behind Show details. $reasons lists prepare-reason-* messages.
ready-updates-restart-persists-reasons = Motifs du redémarrage : { $reasons }
ready-updates-network = Les mises à jour ne peuvent pas utiliser cette connexion
ready-updates-stopped = Mises à jour arrêtées. Certaines sont peut-être déjà installées.
ready-updates-previous = En attente des mises à jour lancées précédemment…
# Button after the user stopped updating.
ready-updates-resume = Reprendre les mises à jour
ready-updates-start = Lancer les mises à jour
# Why updating hasn't started, under the row.
ready-updates-blocked = Les mises à jour attendent qu’Atlas puisse s’installer sur ce PC.
ready-updates-needs-admin = Démarre dès qu’Atlas a l’autorisation d’administrateur.
ready-updates-needs-windows = Démarre dès que la vérification Compatibilité de Windows réussit.
ready-updates-needs-drivers = Démarre dès que vous avez choisi comment installer les pilotes.
# The driver choice under the update row. $choice is ready-drivers-automatic or ready-drivers-manual,
# which are also values of the Drivers row on the ISO's Create step.
ready-drivers-row = Pilotes : { $choice }
ready-drivers-automatic = Via Windows Update
ready-drivers-manual = Installation manuelle
ready-drivers-change-a11y = Modifier le mode d’installation des pilotes
# Under the two answers, once updating has run.
ready-drivers-again = Si vous modifiez ce choix, les mises à jour s’exécutent à nouveau.

# $received et $total sont des nombres de mégaoctets formatés (texte).
package-downloading = Téléchargement d’Atlas { $version } · { $received } sur { $total } Mo
package-unpacking = Extraction
package-status-ready = Prêt
# Nom accessible de la barre de progression.
package-progress = Progression du package Atlas
package-download-again = Télécharger à nouveau
package-download-version = Télécharger Atlas { $version }
package-download-newest = Télécharger la dernière version
package-cancel-download = Annuler le téléchargement
package-open-file = Ouvrir un fichier de package
# Provenance du package. $file est un nom de fichier (texte).
package-from-release = Atlas { $version } a été téléchargé depuis GitHub et est prêt à être installé.
package-from-file = Atlas { $version } a été chargé depuis { $file } et est prêt à être installé.
package-unpacked = Atlas { $version } est prêt à être installé.
package-none-yet = Aucun package Atlas pour le moment
acquire-no-asset = Atlas { $version } ne propose aucun fichier de package à télécharger. Ouvrez un package Atlas (.atlaspkg) déjà enregistré pour continuer.
# Shown for a package older than Atlas 0.6.0, and for a file that isn't an Atlas package.
acquire-unsupported = Cette application installe Atlas 0.6.0 et versions ultérieures à partir de packages Atlas (.atlaspkg).
# Un package assez récent pour inclure le script d'installation que pilote cette application, mais qui ne le contient pas.
acquire-incomplete = Il manque à Atlas { $version } des fichiers dont cette application a besoin pour l’installer. Téléchargez-le à nouveau ou ouvrez un autre package Atlas (.atlaspkg).
acquire-failed = Impossible de préparer le package Atlas. Téléchargez-le à nouveau ou ouvrez un autre package Atlas (.atlaspkg). Détails : { $error }
# Le téléchargement n'a rien reçu pendant une minute et a été arrêté.
acquire-stalled = Le téléchargement a cessé de répondre. Vérifiez votre connexion Internet, puis réessayez le téléchargement ou ouvrez un package Atlas (.atlaspkg) déjà enregistré.
# Version de test : le package Atlas intégré n'a pas pu être extrait. Réessayer est le seul bouton proposé.
acquire-failed-bundled = Impossible de préparer le package Atlas intégré. Choisissez Réessayer. Détails : { $error }
# The Atlas package asks for a newer Atlas Manager than this one. $version is the version it asks
# for, such as 0.7.0; manager-download is beside it. « la version actuelle » est l'Atlas Manager
# qui s'exécute, comme dans manager-update-message.
acquire-manager-update-needed = Ce package Atlas nécessite une version plus récente d’Atlas Manager. Téléchargez Atlas Manager { $version } ou une version ultérieure, et utilisez-la à la place de la version actuelle.
# The same, for a package that doesn't say which version it needs.
acquire-manager-update-needed-any = Ce package Atlas nécessite une version plus récente d’Atlas Manager. Téléchargez la dernière version d’Atlas Manager et utilisez-la à la place de la version actuelle.
# The Atlas package for Atlas $version asks for Atlas Manager $required or later, such as 0.7.0.
acquire-manager-update-required = Pour installer Atlas { $version }, téléchargez Atlas Manager { $required } ou une version ultérieure, et utilisez-la à la place de la version actuelle.
# The same, for a package that doesn't say which Atlas Manager it needs.
acquire-manager-update-required-any = Pour installer Atlas { $version }, téléchargez la dernière version d’Atlas Manager et utilisez-la à la place de la version actuelle.

## Atlas Manager plus récent

# Opens the latest Atlas release on GitHub in the browser, where Atlas Manager is downloaded.
manager-download = Télécharger Atlas Manager
# A note on Home and in Settings that a newer Atlas Manager has been released. $version is its version.
manager-update-title = Atlas Manager { $version } est disponible
manager-update-message = Atlas Manager ne peut pas se mettre à jour lui-même. Téléchargez la nouvelle version et utilisez-la à la place de la version actuelle.

## Vérifications du système

check-administrator = Autorisation d’installer
check-supported-build = Compatibilité de Windows
check-pending-updates = Mises à jour Windows
check-pending-reboot = Redémarrage en attente
check-third-party-antivirus = Autre logiciel antivirus
check-internet = Connexion Internet
check-power = Alimentation
check-activation = Activation de Windows
# Checks shown only where Atlas moves Windows to a newer version: what the move needs.
check-move-hardware = Matériel pour Windows 11
check-move-space = Espace libre
check-move-update-source = Source des mises à jour
# Nom accessible d'une ligne de vérification. $state est l'un des messages check-state-*.
check-a11y = { $title } : { $state }
# Fragments invariables : le titre qui précède peut être masculin ou féminin.
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
# Opens Storage in Windows Settings.
check-fix-storage = Ouvrir les paramètres de stockage
# Opens Installed apps in Windows Settings, from the Other antivirus software check. The page's
# name as French Windows shows it, as in fixed-installed.
check-fix-installed-apps = Ouvrir Applications installées
# Case que l'utilisateur coche lorsque la recherche Windows Update n'a pas pu s'exécuter.
check-ack-updates = J’ai vérifié dans Windows Update : aucune mise à jour n’est en attente d’installation

detail-admin-ok = Atlas a l’autorisation d’apporter les modifications nécessaires à l’installation.
detail-admin-missing = Relancez Atlas en tant qu’administrateur, puis choisissez Oui lorsque Windows demande l’autorisation.
# $builds est une liste de numéros de build comme « 26100 ou 26200 » ; $build est celle de ce PC (texte).
detail-build-unsupported = Cette version d’Atlas nécessite la build Windows { $builds }. Votre PC utilise la build { $build }. Installez une version compatible de Windows avant de continuer.
detail-build-missing = Ce package Atlas n’indique aucune build Windows prise en charge. Utilisez une build complète du package plutôt qu’une build LocalTest.
detail-updates-none = Aucune mise à jour Windows n’est en attente d’installation.
# Updates still waiting once updating has run. $count is how many.
detail-updates-left =
    { $count ->
        [one] { $count } mise à jour est toujours en attente. Installez-la dans Windows Update, puis vérifiez à nouveau.
       *[other] { $count } mises à jour sont toujours en attente. Installez-les dans Windows Update, puis vérifiez à nouveau.
    }
detail-updates-scan-failed = Impossible de rechercher les mises à jour Windows. Ouvrez Windows Update pour voir si certaines sont en attente. ({ $error })
detail-reboot-none = Windows n’a pas besoin de redémarrer pour le moment.
# Once updating has run: a restart it left, or one Windows still wants.
detail-restart-pending = Windows doit redémarrer pour terminer des modifications antérieures. Redémarrez votre PC, puis vérifiez à nouveau.
# $reasons : les marqueurs de redémarrage en attente posés par Windows, d'après les noms prepare-reason-*.
detail-restart-pending-reasons = Windows doit redémarrer pour terminer des modifications antérieures ({ $reasons }). Redémarrez votre PC, puis vérifiez à nouveau.
# Avertissement, pas un blocage : $files liste jusqu'à trois chemins de fichiers que Windows remplacera ou supprimera au prochain redémarrage.
detail-reboot-file-renames = Vous pouvez continuer. Windows doit remplacer ou supprimer des fichiers au prochain redémarrage ({ $files }). Certaines applications, comme Xbox Gaming Services, font cela après chaque redémarrage.
detail-reboot-unknown = Impossible de vérifier si Windows doit redémarrer. Redémarrez votre PC, puis rouvrez Atlas et vérifiez à nouveau. ({ $error })
detail-antivirus-none = Aucun autre logiciel antivirus n’a été détecté.
# $products est une liste de noms de produits (texte). La ligne propose check-fix-installed-apps.
detail-antivirus-uninstall = Les applications antivirus autres que Microsoft Defender peuvent bloquer l’installation. Désinstallez { $products }, puis vérifiez à nouveau.
# Avertissement, pas un blocage : le Centre de sécurité liste encore le produit, mais ses fichiers ont disparu.
detail-antivirus-stale = Sécurité Windows liste encore { $products }, mais ses fichiers ont disparu : ce logiciel n’est donc plus installé. Atlas peut quand même être installé.
detail-antivirus-check-failed = Impossible de vérifier la présence d’autres logiciels antivirus. Si le problème persiste, redémarrez votre PC et vérifiez à nouveau. ({ $error })
detail-internet-ok = Ce PC est connecté à Internet. Conservez cette connexion pendant qu’Atlas télécharge et installe des logiciels.
detail-internet-missing = Connectez-vous à Internet, puis vérifiez à nouveau.
detail-power-mains = Votre PC est branché sur le secteur. Laissez-le branché jusqu’à la fin de l’installation.
detail-power-battery = Branchez votre PC sur le secteur pour qu’il reste allumé pendant toute l’installation.
detail-power-check-failed = Atlas n’a pas pu déterminer si votre PC est branché sur le secteur. S’il s’agit d’un ordinateur portable, branchez-le, puis vérifiez à nouveau.
detail-activation-ok = Windows est activé. Atlas n’y changera rien.
detail-activation-missing = Windows n’est pas activé. Vous pouvez continuer, mais Atlas n’activera pas Windows à votre place.
detail-activation-no-licence = Windows n’a signalé aucune licence. Vous pouvez continuer ; Atlas ne modifiera pas l’état d’activation.
detail-activation-unknown = Impossible de vérifier l’activation de Windows. Vous pouvez continuer ; Atlas ne modifiera pas l’état d’activation. ({ $error })
# What moving Windows to version $release needs. $missing lists hardware-tpm and hardware-uefi.
detail-move-not-needed = Atlas n’a pas besoin de faire passer Windows à une version plus récente sur ce PC.
detail-move-hardware-ready = Ce PC dispose du TPM 2.0 et du microprogramme UEFI requis par Windows 11.
detail-move-hardware-missing = Il manque à ce PC : { $missing }. Windows Update ne le fera donc pas passer à la version { $release }. Sauvegardez vos fichiers, puis réinstallez Windows avec une ISO Atlas.
detail-move-hardware-unread = Atlas n’a pas pu lire tout le matériel de ce PC : c’est donc Windows Update qui le vérifie.
# $drive is a drive such as C:; $free and $needed are whole gigabytes.
detail-move-space-ok = Espace libre sur { $drive } : { $free } Go.
detail-move-space-short = La version { $release } nécessite { $needed } Go d’espace libre sur { $drive }, qui n’a que { $free } Go. Libérez de l’espace ; Atlas vérifie à nouveau de lui-même.
detail-move-space-unknown = Impossible de vérifier l’espace libre pour la mise à jour de Windows. Redémarrez votre PC, puis vérifiez à nouveau. ({ $error })
detail-move-update-source-ok = Ce PC reçoit ses mises à jour de Windows Update.
detail-move-update-source-managed = Ce PC reçoit ses mises à jour du serveur de son organisation, qui ne propose pas la version { $release }. Adressez-vous à votre organisation ou réinstallez Windows avec une ISO Atlas.

## Étape 2 : Vos choix
## Un seul écran pose toutes les questions, une carte chacune, avec les options facultatives repliées en dessous.

# Once, at the top of Your choices: only what the Atlas folder can change back.
options-change-later = Vous pourrez modifier plus tard vos choix pour Microsoft Defender, les protections du processeur et les mises à jour depuis le dossier Atlas de votre bureau.
# The status line of the folded Optional extras card.
options-extras-none = Aucune sélectionnée
# $count is how many of the extras' check boxes are ticked.
options-extras-ticked =
    { $count ->
        [one] { $count } sélectionnée
       *[other] { $count } sélectionnées
    }
# Links that unfold and fold the Optional extras card.
options-extras-show = Afficher
options-extras-hide = Masquer
# Under each question's title, one sentence at most.
question-defender-description = Microsoft Defender est l’antivirus intégré à Windows.
question-mitigations-description = Ces protections, aussi appelées mesures d’atténuation de sécurité, protègent contre les failles du processeur, comme Spectre et Meltdown, et contre les attaques qui exploitent des bogues dans les applications.
question-auto-updates-description = Dans les deux cas, Atlas maintient Windows sur sa version actuelle et désactive les mises à jour automatiques des applications du Microsoft Store.
question-browser-description = Atlas ne modifiera pas les paramètres de votre navigateur.
# One line under an answer other than the recommended one: what it costs. cost-defender-disable is
# also shown on the Install step, on Home and after an installation that removed Defender.
cost-defender-disable = Votre PC n’a aucun antivirus tant que vous n’en installez pas un autre, et Windows ne vous avertit plus avant l’ouverture d’applications ou de téléchargements non reconnus.
# « Exploit Protection » est le nom de la page de Sécurité Windows, en anglais dans Windows en français.
cost-mitigations-disable = Cela désactive aussi Exploit Protection pour les applications, comme la Protection du flux de contrôle (CFG), ce qui réduit la sécurité.
cost-auto-updates-disable = Ouvrez régulièrement Windows Update pour obtenir les correctifs de sécurité.
cost-auto-updates-default = Windows peut redémarrer votre PC pour terminer l’installation des mises à jour.
# Under the taskbar selector answer, which turns off the keyboard shortcuts for switching.
cost-keyboard-shortcuts-off = Alt+Maj et Ctrl+Maj ne changent plus la langue ni la disposition.
# One line under an optional extra: what ticking it does.
extra-disable-hibernation = Libère de l’espace disque, mais la mise en veille prolongée et le démarrage rapide ne sont plus disponibles.
extra-disable-power-saving = Votre PC peut consommer davantage, chauffer plus et avoir une autonomie réduite.
extra-disable-core-isolation = Cela réduit la protection, dont l’intégrité de la mémoire, et peut affecter les applications ou les jeux qui en ont besoin.
extra-uninstall-edge = Vos favoris, votre historique et vos mots de passe enregistrés dans Edge sur ce PC sont supprimés, sauf ce qui est synchronisé avec votre compte Microsoft.
extra-install-toolbox = Vous aide à gérer vos paramètres Atlas. En version bêta, certaines fonctionnalités peuvent être inachevées.
extra-install-eclean = Un outil de l’équipe d’AtlasOS pour examiner les fichiers inutiles et les applications au démarrage. Nécessite un compte et une connexion Internet.
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
# Each decision's name in mid-sentence, with its article: "Modifier { $title }" (summary-change-a11y)
# and "pour { $choices }" (update-path-differs).
screen-update-path-name = le mode de mise à jour
screen-defender-name = Microsoft Defender
screen-mitigations-name = les protections du processeur
screen-updates-name = Windows Update
screen-keyboard-name = les langues du clavier
screen-browser-name = le navigateur
screen-power-name = l’alimentation et la sécurité
screen-apps-name = les applications
screen-optional-apps-name = les applications facultatives
# A question with one answer that this app has no name for, such as one a newer Atlas package adds.
screen-package-choice-name = un choix du package Atlas
screen-extras-name = les options facultatives
# Question pour un choix obligatoire pour lequel cette application n'a pas de formulation spécifique.
screen-generic-question = Choisissez une option pour { $title }
learn-more-defender = En savoir plus sur Microsoft Defender
learn-more-mitigations = En savoir plus sur les protections du processeur
learn-more-updates = En savoir plus sur Windows Update
learn-more-browser = En savoir plus sur les navigateurs
learn-more-power = En savoir plus sur l’alimentation et la sécurité
learn-more-apps = En savoir plus sur les applications
learn-more-eclean = En savoir plus sur eclean
learn-more-keyboard = En savoir plus sur les langues du clavier
learn-more-generic = Lire le guide de configuration
# Une ligne sous la réponse choisie : ce que cela implique pour le PC.
consequence-defender-enable = Conserve l’antivirus intégré à Windows pour aider à protéger votre PC contre les virus et autres menaces.
consequence-mitigations-default = Conserve les protections par défaut de Windows contre les failles du processeur et les attaques qui exploitent des bogues dans les applications.
consequence-mitigations-disable = Désactive aussi Exploit Protection pour les applications, comme la Protection du flux de contrôle (CFG). Cela réduit la sécurité. L’effet sur les performances dépend de votre processeur.
consequence-auto-updates-disable = Ouvrez régulièrement Windows Update pour installer les mises à jour. Les notifications de mise à jour restent activées.
consequence-auto-updates-default = Windows installera les mises à jour automatiquement, y compris les correctifs de sécurité.

## Étape 2 lors d'une mise à jour ou d'une réinstallation d'Atlas

# $version is the Atlas version being installed, such as 0.6.1.
update-path-update-title = Comment souhaitez-vous passer à Atlas { $version } ?
update-path-reinstall-title = Comment souhaitez-vous réinstaller Atlas { $version } ?
# The two answers, each with its detail line. Other messages name the answers too.
update-path-keep = Conserver mes choix
update-path-keep-detail = Atlas conserve chaque choix tel qu’il est actuellement sur ce PC et n’en modifie aucun.
update-path-choose = Refaire mes choix
update-path-choose-detail = Repartez de la configuration actuelle de ce PC. Vos applications, vos fichiers et votre personnalisation sont conservés.
# Heading of the list under the two answers: one row per choice, as this PC has it now.
update-path-now-title = Vos choix actuels sur ce PC
# The value of a row for a choice nothing on the PC shows.
update-path-unknown = Atlas ne peut pas le déterminer d’après votre PC : il vous pose donc la question
# $choices lists screen-*-name messages, joined with list-and.
update-path-differs = Ce PC ne correspond pas à l’enregistrement d’Atlas pour { $choices }.
# Above the questions Keep my choices still asks.
keep-choices-asked = Atlas conserve tous les autres choix tels qu’ils sont actuellement sur ce PC.
# A short tag under the answer this PC has now, on the screens of Choose again.
option-now = Actuellement sur ce PC
# Under an answer on a screen of Choose again, when choosing it changes this PC.
change-defender-enable = Atlas rétablit Microsoft Defender. Après le redémarrage, activez sa protection dans Sécurité Windows.
change-mitigations-default = Atlas réactive les protections du processeur avec les paramètres par défaut de Windows. Cela prend effet après le redémarrage.
change-mitigations-all-on = Toutes les protections du processeur sont actuellement activées. Si vous les conservez, elles restent toutes activées.
change-auto-updates-default = Atlas laisse de nouveau Windows installer les mises à jour automatiquement.
change-hibernation-on = Atlas réactive la mise en veille prolongée.
change-power-saving-on = Atlas réactive les économies d’énergie et rétablit votre mode de gestion de l’alimentation précédent, ou, à défaut, le mode Utilisation normale.
change-core-isolation-on = Atlas réactive la sécurité basée sur la virtualisation (VBS), sauf si une stratégie de ce PC la contrôle. Cela prend effet après le redémarrage.
change-remove-snipping-tool = Supprime l’Outil Capture d’écran pour tous les utilisateurs de ce PC. Atlas ne pourra pas le rétablir ensuite, mais vous pourrez le réinstaller depuis le Microsoft Store.
# Install or Remove Edge est un nom de fichier du dossier Atlas, en anglais sur tous les PC.
fixed-uninstall-edge = Microsoft Edge a déjà été supprimé, et la mise à jour d’Atlas ne peut pas le rétablir. Pour le réinstaller, utilisez Install or Remove Edge dans le dossier Atlas.
# $app is an app Atlas installed, such as Atlas Toolbox or Brave.
fixed-installed = { $app } est installé. Atlas ne désinstalle pas d’applications ; pour le supprimer, ouvrez Applications installées dans les Paramètres Windows.
# $installed and $browser are browser names, such as Brave and Firefox.
browser-also = { $installed } reste installé, et Atlas installe aussi { $browser }.

## Texte du package Atlas
## Libellés et descriptions des options et des questions du package Atlas,
## selon leurs identifiants dans le fichier atlas.json du package. Une option
## ajoutée par un package plus récent, sans message ici, affiche le texte anglais.
## Les formes -short reprennent la réponse sans la recommandation.

package-option-defender-enable = Conserver Microsoft Defender (recommandé)
package-option-defender-enable-short = Conserver Microsoft Defender
package-option-defender-disable = Supprimer Microsoft Defender
package-option-mitigations-default = Conserver les protections du processeur (recommandé)
package-option-mitigations-default-short = Conserver les protections du processeur
package-option-mitigations-disable = Désactiver les protections du processeur
package-option-auto-updates-disable = Installer les mises à jour moi-même
package-option-auto-updates-default = Installer les mises à jour automatiquement
package-option-disable-hibernation = Désactiver la mise en veille prolongée
package-option-disable-power-saving = Désactiver les économies d’énergie
package-option-disable-core-isolation = Désactiver la sécurité basée sur la virtualisation (VBS)
package-option-remove-snipping-tool = Supprimer l’Outil Capture d’écran
package-option-uninstall-edge = Supprimer Microsoft Edge
package-option-install-another-browser = Installer un navigateur
package-option-install-toolbox = Installer Atlas Toolbox
package-option-install-eclean = Installer eclean
package-option-browser-brave = Brave
package-option-browser-librewolf = LibreWolf
package-option-browser-firefox = Firefox
package-option-browser-chrome = Chrome
package-choice-defender-description = Microsoft Defender est l’antivirus intégré à Windows. Ne le supprimez que si vous comprenez les risques et prévoyez d’utiliser une autre application antivirus. Quel que soit votre choix, Atlas désactive le Contrôle intelligent des applications, la Protection renforcée contre l’hameçonnage et Localiser mon appareil.
package-choice-mitigations-description = Ces protections, aussi appelées mesures d’atténuation de sécurité, aident à protéger votre PC contre les failles du processeur, comme Spectre et Meltdown, et contre les attaques qui exploitent des bogues dans les applications. Il est recommandé de conserver les paramètres par défaut de Windows.
package-choice-auto-updates-description = Les mises à jour Windows comprennent des correctifs de sécurité. Vous pouvez laisser Windows les installer automatiquement ou les installer vous-même. Dans les deux cas, Atlas maintient Windows sur sa version actuelle, qui ne reçoit des correctifs de sécurité que jusqu’à la fin de son support par Microsoft. Atlas désactive aussi les mises à jour automatiques des applications du Microsoft Store : mettez-les donc à jour dans le Microsoft Store.
package-choice-browser-description = Choisissez un navigateur à installer. Atlas ne modifiera pas les paramètres de votre navigateur.

## Étape 3 : Sécurité Windows

# Instead of the switch list when Microsoft Defender isn't on this PC and the user chose to remove it.
security-banner-absent-title = Microsoft Defender n’est pas installé sur ce PC
# The message under security-banner-absent-title and security-banner-removed-title.
security-nothing-to-turn-off = Il n’y a aucun paramètre de protection à désactiver.
security-banner-removed-title = Atlas a supprimé Microsoft Defender de ce PC
# When Atlas's own package removed Microsoft Defender and this installation brings it back.
security-banner-restore-title = Atlas rétablit Microsoft Defender lors de cette installation
security-restore-nothing-to-turn-off = Defender ne fonctionne pas encore : il n’y a donc rien à désactiver. Après le redémarrage, activez sa protection dans Sécurité Windows.
# A warning that doesn't stop the step: Defender is missing and Atlas didn't remove it.
security-banner-missing-title = Microsoft Defender est introuvable
security-banner-missing-message = Atlas ne l’a pas supprimé et ne peut donc pas le rétablir. Vous pouvez continuer, mais votre PC n’aura aucun antivirus tant que vous n’aurez pas installé une autre application antivirus ou réparé Windows.
# While a switch is on, or none can be read. Open Windows Security is its button.
security-turn-off-title = Désactivez ces quatre paramètres
security-turn-off-message = Microsoft Defender peut bloquer Atlas pendant son installation. Si vous conservez Defender, réactivez-les après l’installation.
# Le nom de la page dans Sécurité Windows.
security-list-title = Paramètres de protection contre les virus et menaces
security-switch-off = Désactivé
security-switch-on = Activé
security-switch-unreadable = Lecture impossible
security-switch-reading = Vérification
security-all-off = Tous désactivés
# Nom accessible d'une ligne de paramètre. $state est l'un des messages security-switch-*.
security-a11y = { $title } : { $state }
# Éléments du résumé « 2 encore activés, 1 n’a pas pu être lu ».
security-count-still-on =
    { $count ->
        [one] { $count } encore activé
       *[other] { $count } encore activés
    }
security-count-unreadable =
    { $count ->
        [one] { $count } n’a pas pu être lu
       *[other] { $count } n’ont pas pu être lus
    }
security-count-join = { $a }, { $b }
# Every readable switch is off and the rest couldn't be read. $switches names those, joined with
# list-and; $count is how many there are.
security-unread-switches-title =
    { $count ->
        [one] Atlas n’a pas pu lire ce paramètre : { $switches }
       *[other] Atlas n’a pas pu lire ces paramètres : { $switches }
    }
security-unread-message =
    { $count ->
        [one] Assurez-vous qu’il est désactivé dans Sécurité Windows.
       *[other] Assurez-vous qu’ils sont désactivés dans Sécurité Windows.
    }
# The check box under security-unread-message.
security-unread-confirm =
    { $count ->
        [one] J’ai vérifié que ce paramètre est désactivé : { $switches }
       *[other] J’ai vérifié que ces paramètres sont désactivés : { $switches }
    }
# The check box when Atlas couldn't read any of the four switches.
security-acknowledge = J’ai vérifié dans Sécurité Windows que les quatre paramètres sont désactivés
security-unknown-unelevated-title = Atlas a besoin d’une autorisation pour vérifier la protection
security-unknown-unelevated-message = Relancez Atlas en tant qu’administrateur pour qu’il puisse lire les paramètres de Microsoft Defender.
# Les quatre paramètres, nommés exactement comme dans Sécurité Windows, chacun avec la raison de le désactiver.
protection-tamper = Protection contre les falsifications
protection-tamper-why = Pour qu’Atlas puisse modifier les paramètres de sécurité.
protection-realtime = Protection en temps réel
protection-realtime-reason = Les analyses peuvent bloquer les fichiers d’Atlas.
protection-cloud = Protection dans le cloud
protection-cloud-reason = Les vérifications en ligne peuvent bloquer les fichiers d’Atlas.
protection-samples = Envoi automatique d’un échantillon
protection-samples-why = Pour que les fichiers d’Atlas ne soient pas envoyés à Microsoft.

## Étape 4 : Installation

outcome-succeeded-title = Atlas est installé
outcome-lost-title = Impossible de confirmer le résultat de l’installation
outcome-failed-title = L’installation ne s’est pas terminée
# The result bar's message after an attempt that didn't succeed: what happened, then what to do,
# in two sentences at most. It never names the bar's button.
result-requirements = Votre PC ne répondait pas aux conditions requises, l’installation n’a donc rien modifié.
# The -resumed variants follow a retry of an installation an earlier attempt had already started applying.
result-requirements-resumed = Votre PC ne répondait pas aux conditions requises, cette tentative s’est donc arrêtée. Une tentative précédente a déjà apporté des modifications.
result-not-elevated = Atlas n’avait pas l’autorisation d’administrateur, l’installation n’a donc rien modifié.
result-not-elevated-resumed = Atlas n’avait pas l’autorisation d’administrateur, cette tentative s’est donc arrêtée. Une tentative précédente a déjà apporté des modifications.
# The installer found Windows or Store updates unfinished.
result-preparation-stale = Atlas n’a pas pu confirmer que Windows et les applications du Store sont à jour, l’installation s’est donc arrêtée avant de modifier Windows.
result-preparation-stale-resumed = Atlas n’a pas pu confirmer que Windows et les applications du Store sont à jour, cette tentative s’est donc arrêtée. Une tentative précédente a déjà apporté des modifications.
result-failed-preflight = L’installation s’est arrêtée avant toute modification. Vous pouvez réessayer.
result-failed-staging = L’installation s’est arrêtée pendant la préparation des fichiers, avant de modifier Windows. Vous pouvez réessayer.
# The "protection switches" are the four the user turned off.
result-failed-applying = Certaines modifications ont peut-être déjà été apportées. Vous pouvez réessayer, ou réactiver les paramètres de protection dans Sécurité Windows si vous vous arrêtez ici.
# The -defender-removed variants once Defender has been removed, so there are no switches to turn back on.
result-failed-applying-defender-removed = Certaines modifications ont peut-être déjà été apportées. Vous pouvez réessayer.
result-failed-resumed = Cette tentative s’est arrêtée prématurément, mais une tentative précédente a déjà apporté des modifications. Vous pouvez réessayer, ou réactiver les paramètres de protection dans Sécurité Windows si vous vous arrêtez ici.
result-failed-resumed-defender-removed = Cette tentative s’est arrêtée prématurément, mais une tentative précédente a déjà apporté des modifications. Vous pouvez réessayer.
# The -repeated variants point to a report (report-title) rather than another try.
result-failed-repeated = Cette tentative s’est arrêtée sur la même erreur que la précédente : réessayer a donc peu de chances d’aboutir. Envoyez un rapport pour que l’équipe Atlas puisse en trouver la cause, et réactivez vos paramètres de protection si vous vous arrêtez ici.
result-failed-repeated-defender-removed = Cette tentative s’est arrêtée sur la même erreur que la précédente : réessayer a donc peu de chances d’aboutir. Envoyez un rapport pour que l’équipe Atlas puisse en trouver la cause.
# $apps holds the package names Windows gives the apps, such as MSTeams (text), joined with list-and.
result-failed-repeated-apps = Windows refuse toujours de supprimer { $apps } : réessayer a donc peu de chances d’aboutir. Envoyez un rapport pour que l’équipe Atlas puisse en trouver la cause, et réactivez vos paramètres de protection si vous vous arrêtez ici.
result-failed-repeated-apps-defender-removed = Windows refuse toujours de supprimer { $apps } : réessayer a donc peu de chances d’aboutir. Envoyez un rapport pour que l’équipe Atlas puisse en trouver la cause.
result-not-started = Le programme d’installation n’a pas démarré à temps, l’installation n’a donc rien modifié. Vous pouvez réessayer.
result-lost = Le programme d’installation s’est arrêté sans indiquer de résultat : certaines modifications ont donc peut-être été apportées. Vous pouvez réessayer, ou réactiver les paramètres de protection dans Sécurité Windows si vous vous arrêtez ici.
result-lost-defender-removed = Le programme d’installation s’est arrêté sans indiquer de résultat : certaines modifications ont donc peut-être été apportées. Vous pouvez réessayer.
restart-now-message = Windows redémarre pour terminer la configuration d’Atlas.
restart-stopped = Redémarrage automatique annulé. Enregistrez votre travail, puis redémarrez votre PC pour terminer la configuration d’Atlas.
restart-needed = Enregistrez votre travail, puis redémarrez votre PC pour terminer la configuration d’Atlas.
restart-dont-now = Redémarrer plus tard
restart-now = Redémarrer maintenant
# The bar when the final checks refuse to start the installer. Its message names what needs attention.
preflight-title = L’installation n’a pas démarré
# Beside go-to-options. $choice is a screen-*-name message, with its article, such as « les
# protections du processeur ».
preflight-choice-unanswered = Atlas a besoin de votre réponse pour { $choice }.
preflight-choices-unusable = Atlas n’a pas pu utiliser ces choix.
# $checks lists check-* names joined with list-and; $count is how many it names.
preflight-checks-changed =
    { $count ->
        [one] Depuis la vérification de votre PC, ce point nécessite votre attention : { $checks }.
       *[other] Depuis la vérification de votre PC, ces points nécessitent votre attention : { $checks }.
    }
# $summary est le résumé de Sécurité Windows, par exemple « 1 encore activé ».
preflight-security-changed = Sécurité Windows a changé depuis que vous avez désactivé les paramètres : { $summary }.
preflight-busy-wait = Une autre fenêtre Atlas démarre une installation. Patientez un instant, puis réessayez.
# Beside home-start-over.
preflight-taken-over-start-over = Une autre fenêtre Atlas utilise désormais cette configuration. Continuez dans l’autre fenêtre ou recommencez ici.
preflight-record-unreadable-check = Atlas n’a pas pu vérifier si une installation précédente est encore en cours et n’en a donc pas démarré une autre.
preflight-not-started = Atlas n’a pas pu démarrer le programme d’installation, l’installation n’a donc rien modifié. Vous pouvez réessayer.
# Instead of preflight-not-started when an earlier attempt had already started applying.
preflight-not-started-resumed = Atlas n’a pas pu démarrer le programme d’installation, mais une tentative précédente a déjà apporté des modifications. Vous pouvez réessayer.
go-to-ready = Aller à Préparation
# Opens Your choices at a question that has no answer.
go-to-options = Aller à Vos choix
# Opens Windows Security when switches Atlas can't read need confirming there.
go-to-security = Aller à Sécurité Windows
# Remplace Continuer sur un choix ouvert depuis un lien Modifier de l'étape Installation.
go-to-install = Revenir à Installation
output-problem-title = Impossible de lire la progression de l’installation
install-elevate-title = Atlas a besoin d’une autorisation pour lancer l’installation
# Under install-elevate-title, beside common-restart-as-administrator.
install-elevate-uac = Lorsqu’Atlas sera relancé, Windows vous demandera l’autorisation.
# A bar on the Install step, beside go-to-ready, when no Atlas package is ready.
install-package-missing = Le package Atlas n’est pas prêt
# Étape 4 lorsque l'étape 1 n'est pas terminée pour cette session ; go-to-ready est le bouton.
install-not-ready-title = Terminez d’abord l’étape Préparation
install-not-ready-message = Atlas doit terminer la vérification de votre PC et la mise à jour de Windows avant de pouvoir lancer l’installation.
# When a fresh reading of the switches no longer passes. $summary is such as « 1 encore activé ».
install-switches-title = Désactivez à nouveau les paramètres de protection
install-switches-message = Sécurité Windows : { $summary }.
# The Install step's card, when nothing stands in the way of installing, and otherwise.
summary-ready-title = Prêt pour l’installation
summary-setup-title = Votre configuration Atlas
summary-activation = Activation
summary-activation-ok = Activé. Atlas n’y changera rien.
summary-activation-missing = Non activé. Vous pouvez continuer, mais Atlas n’activera pas Windows.
summary-activation-unknown = Atlas ne modifiera pas l’état d’activation de Windows.
# How long installing usually takes: the first while the box below is ticked, the second while it isn't.
summary-time-restarts =
    { $minutes ->
        [one] Environ { $minutes } minute en général, puis votre PC redémarre
       *[other] Environ { $minutes } minutes en général, puis votre PC redémarre
    }
summary-time-restart-yourself =
    { $minutes ->
        [one] Environ { $minutes } minute en général, puis redémarrez votre PC
       *[other] Environ { $minutes } minutes en général, puis redémarrez votre PC
    }
# The same setting as settings-restart-automatically.
summary-restart-automatically = Redémarrer automatiquement à la fin de l’installation
# A row of the card's details: what Atlas turns off whichever Defender answer is chosen.
summary-turned-off = Également désactivés
summary-turned-off-value = Contrôle intelligent des applications, Protection renforcée contre l’hameçonnage et Localiser mon appareil
summary-show-command = Afficher la commande d’installation
summary-hide-command = Masquer la commande d’installation
summary-copy-command-a11y = Copier la commande d’installation
summary-command-unavailable = Impossible de préparer la commande d’installation. Détails : { $error }
summary-not-chosen = Aucun choix pour le moment
# Accessible name of a Change link. $title is a screen-*-name message, with its article.
summary-change-a11y = Modifier { $title }
# The summary's first row on an update or reinstall.
summary-update-path = Mode de mise à jour
# Why Continue waits on Get ready. 8 words or fewer.
footer-still-checking = Préparation de l’installation
footer-checks-blocked = Corrigez les problèmes détectés pour continuer
footer-manager-outdated = Téléchargez un Atlas Manager plus récent pour continuer
footer-need-files = Obtenez le package Atlas pour continuer
# Variante de footer-need-files pour la version de test.
footer-need-package-bundled = Préparez le package Atlas intégré pour continuer
footer-drivers = Choisissez comment installer les pilotes pour continuer
footer-windows-terms = Acceptez le contrat de licence pour continuer
footer-updating = Mise à jour de Windows et des applications du Store…
footer-restart = Redémarrez votre PC pour continuer
footer-reading-security = Vérification des paramètres de protection
# Why Continue waits on Windows Security.
footer-security-pending = Désactivez les quatre paramètres pour continuer
footer-security-confirm = Pour continuer, confirmez les paramètres qu’Atlas n’a pas pu lire
# Beside Install Atlas while automatic restart is on.
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

installing-title = Installation d’Atlas
# What Atlas is doing, under installing-title and as the progress bar's name: a short phrase ending in an ellipsis.
installing-checking-label = Vérification de votre PC…
installing-staging-label = Copie des fichiers d’Atlas…
installing-applying-label = Configuration de Windows…
installing-finishing-label = Finalisation…
# The line under the progress bar: when the PC restarts by itself after, and when it doesn't.
installing-keep-on-restart = Laissez votre PC allumé et branché. Il redémarre de lui-même à la fin de l’installation.
installing-keep-on = Laissez votre PC allumé et branché. Redémarrez-le à la fin de l’installation.
# When Atlas can't follow the installer's log. Its title is output-problem-title.
installing-output-problem = Cela ne signifie pas que l’installation s’est arrêtée.
installing-installed-title = Atlas est installé
# While the restart counts down, with installing-restart-save under it.
installing-restart-countdown =
    { $seconds ->
        [one] Votre PC redémarre dans { $seconds } seconde.
       *[other] Votre PC redémarre dans { $seconds } secondes.
    }
installing-restart-save = Enregistrez d’abord votre travail.

## La fenêtre « Atlas est installé » après le redémarrage

installed-title-version = Atlas { $version } est installé
installed-title = Atlas est installé
installed-ready = C’est terminé. Votre PC est prêt à être utilisé avec Atlas.
# Where the user installs drivers themselves, with installed-drivers-guide under it.
installed-manual-drivers-detail = Téléchargez les pilotes du chipset, du réseau et de la carte graphique auprès du fabricant de votre PC, de votre carte mère ou de votre périphérique.
installed-drivers-guide = Ouvrir le guide des pilotes
# After an installation that removed Defender. Its message is cost-defender-disable.
installed-defender-removed-title = Microsoft Defender a été supprimé
# Defender is missing and no Atlas package removed it. Its title is security-banner-missing-title.
defender-missing-message = Atlas ne l’a pas supprimé. Si vous n’utilisez pas d’autre application antivirus, installez-en une pour protéger votre PC.
# Atlas's record kept Defender but its package still removes it. 7. Security, Defender and
# Toggle Defender are folder and file names in the Atlas folder, in English on every PC.
installed-defender-not-restored-title = Microsoft Defender est toujours supprimé
defender-not-restored-message = Une mise à jour précédente d’Atlas ne l’a pas rétabli : Defender ne protège donc pas votre PC. Réinstallez Atlas en conservant Defender, ou lancez Toggle Defender depuis 7. Security > Defender dans le dossier Atlas.
# The "Atlas is installed" window, when what the installation recorded for some choices isn't
# what was chosen.
installed-not-applied-title = Certains choix n’ont pas pris effet
# $choices lists screen-*-name messages, with their articles, joined with list-and; $count is
# how many it names.
installed-not-applied-choices =
    { $count ->
        [one] Ce choix est resté tel qu’il était : { $choices }.
       *[other] Ces choix sont restés tels qu’ils étaient : { $choices }.
    }
# After an update whose last step turned Windows Update off, or paused it, again.
installed-update-off-title = Windows Update est de nouveau désactivé, selon votre choix
installed-update-off-message = Tant qu’il est désactivé, votre PC ne reçoit aucune mise à jour de sécurité.
installed-update-paused-title = Les mises à jour Windows sont de nouveau suspendues, selon votre choix
installed-update-paused-message = Tant qu’elles sont suspendues, votre PC ne reçoit aucune mise à jour de sécurité.

## Paramètres

settings-title = Paramètres
# Headings of the page's sections.
settings-appearance = Apparence
settings-installation = Installation
settings-privacy = Confidentialité
settings-theme = Thème de l’application
settings-theme-system = Comme Windows
settings-theme-light = Clair
settings-theme-dark = Sombre
settings-theme-contrast-note = Atlas utilise les couleurs de votre thème de contraste Windows.
settings-language = Langue
# The setting in the Language section, and its box's name.
settings-app-language = Langue de l’application
# The first choice in the language box. $language is that language's own name.
settings-language-match-windows = Comme Windows – { $language }

# Courte étiquette après chaque langue traduite mais pas encore relue par un locuteur natif.
settings-language-preview-tag = Aperçu
# Under the language box while a preview translation is in use, once its notice has been dismissed.
settings-language-preview-in-use = Cette traduction n’a pas encore été relue par un locuteur natif.
# A bar at the top of the content while a preview translation is in use. $language is the language's own name.
preview-notice = { $language } est une traduction en aperçu et peut contenir des erreurs.
preview-notice-switch = Passer en anglais
preview-notice-language = Changer de langue
# When the language chosen isn't in this version, and the box shows English.
settings-language-chosen-unavailable = La langue choisie n’est pas disponible dans cette version d’Atlas : Atlas s’affiche donc en anglais. Votre choix est conservé.
settings-language-windows-unsupported = Atlas ne prend pas encore en charge votre langue d’affichage Windows : il s’affiche donc en anglais.
settings-language-windows-unreadable = Atlas n’a pas pu vérifier votre langue d’affichage Windows : il s’affiche donc en anglais.
# $locale est le nom du format régional dans sa propre langue, par exemple « français (France) ».
settings-language-formats = Les nombres, les dates et les heures suivent votre format régional Windows : { $locale }.
# Remplace settings-language-formats lorsque le format régional écrit de droite à gauche. $locale est le nom anglais du format.
settings-language-formats-numbers-only = Les nombres suivent votre format régional Windows : { $locale }. Les dates et les heures utilisent un format standard, car Atlas ne peut pas encore afficher le texte de droite à gauche.
settings-language-contribute = Aider à traduire Atlas sur GitHub
# The usage analytics switch, with its description and a link to the privacy policy.
settings-share-usage = Partager les données d’utilisation avec Atlas
settings-share-usage-description = Pages consultées, créations d’ISO et réussite des installations.
settings-privacy-policy = Politique de confidentialité
# Covers the restart after installing and the restart that updates need before installing.
settings-restart-automatically = Redémarrer automatiquement après l’installation et les mises à jour
settings-restart-automatically-description = Votre PC redémarre moins d’une minute après qu’Atlas a terminé, en fermant les applications ouvertes.
settings-restart-locked = Vous pourrez modifier ce réglage une fois l’installation terminée.
# Heading over Send a report, Export diagnostics and settings-open-data-folder.
settings-help = Aide
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

## Choix facultatifs : explications affichées avant la sélection.

consequence-disable-hibernation = Libère l’espace disque utilisé pour enregistrer votre session lors de la mise en veille prolongée. La veille prolongée et le démarrage rapide ne seront plus disponibles.
consequence-disable-power-saving = Désactive les fonctions d’économie d’énergie. Votre PC peut consommer davantage, chauffer plus et avoir une autonomie réduite.
consequence-disable-core-isolation = Désactive une couche de sécurité supplémentaire de Windows, dont l’intégrité de la mémoire. Cela réduit la protection et peut affecter les applications ou les jeux qui en ont besoin.
consequence-remove-snipping-tool = Supprime l’application Windows de capture d’écran et d’enregistrement vidéo de l’écran.
consequence-uninstall-edge = Supprime le navigateur Microsoft Edge. Assurez-vous d’avoir un autre navigateur ou choisissez-en un ci-dessous.
# Under Remove Microsoft Edge in the Install step's summary, with a caution glyph.
caution-uninstall-edge = Supprime vos favoris, votre historique et vos mots de passe enregistrés dans Edge sur ce PC.
consequence-install-another-browser = Choisissez un navigateur ci-dessous et Atlas l’installera pour vous.
consequence-install-toolbox = Ajoutez Atlas Toolbox pour gérer plus facilement vos paramètres Atlas. Toolbox est en version bêta : certaines fonctionnalités peuvent être inachevées.
consequence-install-eclean = Un outil de maintenance de l’équipe d’AtlasOS pour entretenir votre PC après l’installation. Examinez les fichiers inutiles et les applications au démarrage. Nécessite un compte et une connexion Internet.

## Création d'ISO
iso-open = Créer une ISO avec Atlas
iso-title = Créer une ISO avec Atlas
iso-recommended = Recommandé
# The three ISO steps: where Windows comes from, how it's set up, and the review that creates the ISO.
iso-step-source = Windows
iso-step-setup = Configuration
iso-step-create = Création
# The first question on the Windows step; it sets the defaults that follow.
iso-target-title = À quel PC cette ISO est-elle destinée ?
iso-target-this = Ce PC
iso-target-another = Un autre PC
# When the ISO is for another processor than this PC's. $architecture is iso-architecture-x64 or -arm64.
iso-target-arch = Cette ISO est destinée aux PC { $architecture }.
iso-source = ISO Windows
# Starts the Windows 11 download at once, in the language and architecture of iso-download-caption.
iso-download-windows = Télécharger depuis Microsoft
# $language is Microsoft's own English name for the language; $architecture is iso-architecture-*.
iso-download-caption = Windows 11 · { $language } · { $architecture }
# The same while Microsoft's list of languages loads.
iso-download-caption-loading = Windows 11 · { $architecture }
# Completes summary-change-a11y (« Modifier { $title } ») for the download's Change link.
iso-download-what = le téléchargement de Windows
iso-download-language = Langue
iso-download-arch = Architecture
iso-download-languages = Chargement des langues…
# The progress bar's label while Windows downloads, then how much has arrived ("2,4 Go").
iso-downloading = Téléchargement de Windows 11…
iso-download-amount = { $received } sur { $total }
# Microsoft's download service couldn't be reached, or the download stopped part-way.
iso-download-unreachable = Atlas n’a pas pu joindre le service de téléchargement de Microsoft. Vérifiez votre connexion Internet, puis réessayez.
iso-download-incomplete = Le téléchargement ne s’est pas terminé. Vérifiez votre connexion Internet et l’espace libre, puis réessayez.
iso-download-website = Ouvrir la page de téléchargement Microsoft
# Opens the file picker for a Windows ISO, and is that picker's Open button.
iso-use-local = Choisir un fichier ISO
# A status pill while the files are checked.
iso-checking = Vérification de votre ISO Windows…
# Accessible name of the Ready pill. $facts is the ISO's architecture and size, such as "x64 · 6,6 Go".
iso-checked-a11y = ISO Windows prête, { $facts }
iso-package-latest-label = Dernière version
# Open package file (package-open-file) is under it.
iso-package-release-old = La dernière version d’Atlas est trop ancienne pour cette version d’Atlas Manager.
# While Atlas finds and downloads the latest Atlas package by itself.
iso-package-fetching = Récupération de la dernière version d’Atlas…
# The release check failed; Try again is beside it.
iso-package-release-failed = Atlas n’a pas pu rechercher la dernière version. Vérifiez votre connexion Internet, puis réessayez.
# Nom accessible du bouton Modifier à côté d'un fichier : $action est le texte de ce bouton et $field le libellé du fichier.
iso-pick-a11y = { $action } : { $field }
# Beside the unavailable Continue on the Windows step while there's no Windows ISO yet.
iso-need-windows = Obtenez une ISO Windows pour continuer
# The question on the Setup step about when the package's choices are made.
iso-mode-question = Quand souhaitez-vous faire vos choix Atlas ?
iso-mode-after = Après la connexion
iso-mode-after-description = Atlas vous guide dans la configuration après votre connexion.
iso-mode-now = Maintenant
iso-mode-now-description = Enregistrés dans l’ISO. Vous installez Atlas après votre connexion.
# A check box under Now.
iso-mode-before-desktop = Terminer avant l’ouverture du bureau
iso-mode-before-desktop-description = Après votre connexion, Atlas s’affiche en plein écran jusqu’à la fin de son installation.
# In place of the question when the Atlas package can't save choices in an ISO.
iso-mode-unavailable = Ce package Atlas ne peut pas enregistrer les choix dans l’ISO : vous les ferez donc après la connexion.
iso-atlas-options = Choix Atlas
# The line at the top of the Create step.
iso-create-intro = La création de l’ISO ne modifie ni ce PC ni votre ISO d’origine.
iso-review-package = Package Atlas
iso-review-output = Nouvelle ISO
iso-review-edition = Édition
iso-review-editions = Éditions
iso-edition = Édition de Windows
# The edition shown on the Setup step's edition card when Windows Setup asks which to install.
# Feminine, agreeing with « édition ».
iso-edition-auto = Choisie à l’installation
# The first item of that card's edition menu, above the ISO's own editions: the choice that lets
# Windows Setup ask which edition to install.
iso-edition-auto-menu = Choisir pendant l’installation de Windows
# An optional check box: accepting the terms here stops Windows Setup from asking.
iso-accept-terms-optional = Accepter le contrat de licence Windows ici plutôt que pendant l’installation
iso-architecture-x64 = x64
iso-architecture-arm64 = Arm64
# Une taille de fichier ; $size est un nombre formaté (texte). Mégaoctets en dessous d'un gigaoctet.
size-megabytes = { $size } Mo
size-gigabytes = { $size } Go
iso-review-account = Nom du compte
iso-review-target = Installer sur
iso-review-drivers = Pilotes
# A review row about the Windows Setup screens the ISO's answer file skips.
iso-review-setup-screens = Installation de Windows
iso-review-skips = Ignore les écrans de compte Microsoft et de confidentialité
iso-review-skips-terms = Ignore les écrans de licence, de compte Microsoft et de confidentialité
iso-review-network = Pilotes réseau
iso-review-network-included = Pilotes Wi-Fi et Ethernet de ce PC
# The Atlas choices row when they're saved in the ISO and finish before the desktop opens.
iso-review-mode-before-desktop = Maintenant, appliqués avant l’ouverture du bureau
# $needed and $free are sizes such as "35,0 Go"; $drive is a drive such as "C:".
iso-destination-space = Nécessite { $needed } · { $free } libres sur { $drive }
iso-destination-short = L’ISO nécessite { $needed }, et { $drive } n’a que { $free } d’espace libre. Libérez de l’espace ou enregistrez l’ISO sur un autre lecteur.
iso-destination-filesystem = { $drive } ne peut pas contenir les fichiers volumineux de l’ISO. Enregistrez-la sur un lecteur au format NTFS, comme votre lecteur Windows.
iso-destination-unusable = Atlas ne peut enregistrer l’ISO que dans un dossier d’un lecteur de ce PC.
iso-create = Créer l’ISO
# Heading above the progress bar and the list of stages while the ISO is being created.
iso-progress-title = Création de votre ISO…
# The progress bar's label: the stage under way. $stage is one of the iso-stage-* messages.
iso-progress-stage = { $stage }…
iso-stage-read = Lecture de l’ISO Windows
iso-stage-copy = Copie des fichiers Windows
iso-stage-add-atlas = Ajout d’Atlas
iso-stage-master = Écriture du fichier ISO
iso-stage-verify = Vérification de la nouvelle ISO
iso-stage-cleanup = Finalisation
# Accessible name of one stage. No "Étape": the screen reader adds "4 sur 6".
# $status is stepper-status-completed or one of the three below (feminine, like « opération »).
iso-stage-a11y = { $title }, { $status }
iso-stage-status-current = en cours
# The stage where creating the ISO stopped with an error.
iso-stage-status-failed = en échec
iso-stage-status-not-started = non commencée
iso-progress-keep-open = Gardez Atlas ouvert jusqu’à la fin.
iso-cancel = Annuler la création
iso-cancelling = En attente d’un point d’arrêt sûr
# The heading over the progress bar of an ISO or a USB drive once cancelling is asked for.
iso-cancelling-short = Annulation…
iso-cancelled = Création de l’ISO annulée
iso-cancelled-unchanged = Votre ISO d’origine n’a pas été modifiée.
iso-complete = Votre ISO est prête
iso-complete-backup = Sauvegardez vos fichiers avant de réinstaller Windows à partir de celle-ci.
# The finished page's main button, which opens the USB drive panel.
iso-create-usb = Créer une clé USB
iso-open-folder = Afficher dans le dossier
iso-failed = La création de l’ISO n’a pas pu aboutir
# Under iso-failed, beside Try again.
iso-failed-retry = Assurez-vous que vos fichiers se trouvent toujours à l’emplacement choisi et que le lecteur de destination est connecté, puis réessayez.
# Title while checking the files fails; the messages below say why.
iso-check-failed = Impossible de vérifier les fichiers
iso-check-failed-retry = Assurez-vous que le téléchargement de l’ISO et du package Atlas est terminé, puis réessayez.
# Nothing ran because the worker's folder couldn't be created.
iso-unstaged = Atlas n’a pas pu préparer son dossier de travail : rien n’a donc été modifié.
# Titles and messages for an ISO or package Atlas can't use. Famille (Home) et LTSC sont les
# éditions refusées ; noms tels que Windows les affiche en français.
iso-edition-unsupported-title = Cette ISO ne contient aucune édition prise en charge par Atlas
iso-edition-unsupported = Windows Famille et LTSC ne sont pas pris en charge. Utilisez une ISO avec l’édition Professionnel, Éducation ou Entreprise.
iso-customised-title = Cette ISO a été personnalisée
iso-customised = Elle contient déjà des fichiers d’installation, comme autounattend.xml. Utilisez une ISO non modifiée provenant de Microsoft.
iso-preview-title = Cette ISO contient une build en préversion
iso-preview = Sa build de Windows ne figure pas dans la liste Microsoft des versions publiques. Utilisez une ISO provenant de Microsoft.
iso-windows-unsupported-title = Ce package Atlas ne peut pas utiliser cette ISO
iso-windows-unsupported = Utilisez une ISO Windows 11 non modifiée d’une version prise en charge par le package.
iso-release-unknown-title = Atlas n’a pas pu confirmer cette version de Windows
iso-release-unconfirmed = Atlas la compare à la liste Microsoft des versions publiques. Vérifiez votre connexion Internet, puis réessayez.
# $minimum is the oldest Atlas version that can make an ISO, such as "0.6.0".
iso-package-old-title = Ce package Atlas ne permet pas de créer une ISO
iso-package-old = Utilisez Atlas { $minimum } ou une version ultérieure.
iso-manager-missing-title = Le fichier d’Atlas Manager est introuvable
iso-fix-package = Choisir un autre package
# A package that needs a newer Atlas Manager; acquire-manager-update-needed says which version.
iso-manager-outdated-title = Atlas Manager doit être mis à jour
# This PC's network drivers couldn't be exported; the button beside it builds without them.
iso-network-not-added = Atlas n’a pas pu ajouter les pilotes réseau de ce PC à l’ISO.
iso-network-skip = Créer sans ces pilotes
# Its message is iso-admin-reason, or iso-elevation-declined after Windows refused the relaunch.
iso-elevation-title = Atlas a besoin d’une autorisation pour créer une ISO
iso-admin-reason = Elle est nécessaire pour lire votre ISO Windows et créer la nouvelle.
iso-elevation-declined = Windows n’a pas accordé l’autorisation à Atlas, qui ne peut donc pas encore lire votre ISO Windows.
# The free space ran out while the ISO was being created.
iso-failed-space = L’espace libre est insuffisant sur le lecteur de destination. Libérez de l’espace ou enregistrez la nouvelle ISO sur un autre lecteur.
# Under iso-manager-missing-title.
iso-manager-missing = Téléchargez AtlasManager.exe dans un dossier local, comme Téléchargements, puis ouvrez-le depuis ce dossier.
# Famille (Home) et LTSC sont les éditions que la création d'ISO écarte ; les autres sont des exemples d'éditions conservées.
iso-failed-edition = Cette ISO ne contient aucune édition de Windows prise en charge. Les éditions Famille et LTSC ne sont pas prises en charge. Utilisez une ISO qui inclut une autre édition, comme Professionnel, Éducation ou Entreprise.
# Opens the folder with an ISO or USB job's raw logs.
iso-diagnostics = Ouvrir le dossier des journaux
# Sur les pages ISO et USB pendant qu'Atlas met à jour Windows, ou rétablit les paramètres Windows Update, depuis une autre page.
iso-locked = Atlas est occupé avec Windows Update. Vous pourrez continuer ici une fois l’opération terminée.
# Noms des marqueurs posés par Windows lorsqu'il demande un redémarrage. Ils complètent
# « Windows doit redémarrer (…) » ; courts et en minuscules.
prepare-reason-servicing = la maintenance de Windows
prepare-reason-windows-update = Windows Update
prepare-reason-file-renames = des fichiers en attente de remplacement
prepare-reason-update-agent = le service Windows Update
prepare-reason-unknown = motif non indiqué
# Under prepare-failed-title, with Try again.
prepare-failed-retry = Si une nouvelle tentative ne suffit pas, terminez les mises à jour restantes dans Windows Update ou le Microsoft Store.
# Title of the error bar on the update row; the cause is its message.
prepare-failed-title = Certaines mises à jour n’ont pas pu se terminer
# Under prepare-unconfirmed-title: the run ended without writing any result, for example
# after Atlas was closed while it ran.
prepare-unconfirmed = La mise à jour s’est arrêtée avant d’indiquer un résultat.
prepare-unconfirmed-title = Impossible de confirmer le résultat des mises à jour
prepare-affected-app = l’application concernée
# A Store app couldn't update because it was open. $app is its name, such as NanaZip, or prepare-affected-app.
prepare-close-app = Fermez { $app }, puis réessayez. Si vous ne la trouvez pas, fermez-la dans le Gestionnaire des tâches.
prepare-install-busy = Une autre installation ou un redémarrage requis bloque les mises à jour. Attendez la fin des autres installations, redémarrez votre PC si Windows vous le demande, puis réessayez.
# Updates failed after Atlas's own repair of the component store. The button is
# prepare-restart-and-retry; updating carries on by itself after the restart.
prepare-components-damaged-title = Windows n’a pas pu se réparer
prepare-components-damaged = Windows signale des dommages qui empêchent l’installation des mises à jour. Un redémarrage peut y remédier, et Atlas reprendra après votre connexion.
prepare-restart-and-retry = Redémarrer et réessayer
# Damage Windows can't repair, so Atlas stops before any update. The button is iso-open.
prepare-components-unrepairable-title = Windows est trop endommagé pour être mis à jour
prepare-components-unrepairable = Sauvegardez vos fichiers, puis réinstallez Windows avec une ISO Atlas.
# Causes signalées par le processus de mise à jour. Son propre message en anglais est affiché en dessous comme détail.
prepare-failed-session-owner = Atlas s’exécute sous un autre compte que celui connecté à Windows. Connectez-vous à Windows avec un compte administrateur, ouvrez Atlas depuis ce compte, puis réessayez.
prepare-failed-store-missing = Le Microsoft Store n’est pas configuré pour votre compte. Ouvrez le Microsoft Store une fois, ou réinstallez-le s’il est absent, puis réessayez.
prepare-failed-store-battery = Le Microsoft Store a suspendu les mises à jour pour économiser la batterie. Branchez votre PC sur le secteur, puis réessayez.
prepare-failed-store-network = Le Microsoft Store a suspendu les mises à jour jusqu’à ce que votre PC dispose d’une connexion non limitée. Connectez-vous en Wi-Fi ou par Ethernet avec une connexion non limitée, puis réessayez.
prepare-failed-store-timeout = Les applications du Store n’ont pas fini de se mettre à jour. Terminez les téléchargements restants dans le Microsoft Store, puis réessayez.
prepare-failed-store-passes = Le Microsoft Store a continué à proposer de nouvelles mises à jour. Terminez les mises à jour restantes dans le Microsoft Store, puis réessayez.
prepare-failed-manual-updates = Certaines mises à jour Windows doivent être terminées dans Windows Update. Ouvrez Windows Update, terminez-les, puis réessayez.
prepare-failed-windows-passes = Windows Update a continué à proposer de nouvelles mises à jour. Terminez les mises à jour restantes dans Windows Update, puis réessayez.
prepare-failed-windows-update-unreachable = Windows Update n’a pas pu joindre les serveurs de Microsoft. Vérifiez votre connexion Internet ainsi que tout pare-feu, proxy ou VPN, puis réessayez.
# Atlas Manager runs from a folder that links to another place (a junction or symbolic link).
prepare-failed-source-linked = Atlas Manager se trouve dans un dossier lié. Fermez Atlas, déplacez Atlas Manager dans un dossier local de ce PC, puis ouvrez-le depuis ce dossier.
prepare-error-code = Code d’erreur : { $code }
prepare-open-store = Ouvrir Microsoft Store
prepare-windows-search = Recherche de mises à jour Windows…
prepare-percent = { $percent } % de cette opération
prepare-count = Mises à jour terminées : { $completed } sur { $total }
prepare-bytes = { $downloaded } sur environ { $total } Mo téléchargés
prepare-progress-still = Aucune progression depuis { $minutes } min. Les mises à jour volumineuses peuvent prendre du temps : gardez Atlas ouvert.
prepare-report-late = Windows n’a signalé aucune progression depuis un moment. Les mises à jour sont peut-être encore en cours : gardez Atlas ouvert.
prepare-windows-download = Téléchargement des mises à jour Windows…
prepare-windows-install = Installation des mises à jour Windows…
# While DISM repairs Windows' component store, with prepare-windows-repair-detail under the progress bar.
prepare-windows-repairing = Réparation de Windows…
prepare-windows-repair-detail = Windows signale des dommages qui peuvent empêcher l’installation des mises à jour. Cela peut prendre une demi-heure ou plus.
prepare-store-search = Vérification du Microsoft Store…
prepare-store-install = Mise à jour du Microsoft Store et de ses applications…
prepare-stop = Arrêter les mises à jour
prepare-start = Rechercher et installer les mises à jour
# Under the Administrator check, while the Atlas package is still downloading or unpacking.
prepare-wait-for-package = Disponible lorsque le package Atlas est prêt.
iso-username = Nom du compte local
# Under the local account name: Windows asks for the password at the first sign-in.
iso-account-help = Vous choisirez un mot de passe lors de votre première connexion.
iso-username-placeholder = Votre nom
# Beside the unavailable Continue button while the local account name is empty.
iso-account-empty = Saisissez un nom de compte local pour continuer
# Keep the list of symbols exactly: Windows refuses them in account names.
iso-account-invalid = Utilisez 20 caractères au maximum, sans espace au début ni à la fin, et aucun de ces caractères : " / \ [ ] : ; | = , + * ? < > @
iso-account-trailing-dot = Le nom ne peut pas se terminer par un point.
iso-account-reserved = Windows utilise ce nom pour un compte intégré. Choisissez un autre nom.
iso-terms-in-setup = Le programme d’installation de Windows vous demandera d’accepter les termes du contrat de licence.
prepare-drivers = Comment installer les pilotes ?
prepare-drivers-auto = Obtenir les pilotes via Windows Update
# The same answer as a radio button's label, where the choice is made.
prepare-drivers-auto-recommended = Obtenir les pilotes via Windows Update (recommandé)
prepare-drivers-auto-detail = Windows recherche les pilotes adaptés à votre matériel.
prepare-drivers-manual = Installer les pilotes moi-même
prepare-drivers-manual-detail = Windows Update n’installera pas de pilotes : vous devrez les obtenir auprès du fabricant de votre PC ou de vos périphériques. Les pilotes déjà installés sont conservés.
# The Setup step's drivers card: this PC's network drivers on the ISO, then the choice
# applied after sign-in, asked with prepare-drivers.
iso-drivers-card = Pilotes
iso-network-drivers = Inclure les pilotes Wi-Fi et Ethernet de ce PC
# The third driver answer, and its value on the Create step: Get ready asks on the new PC.
iso-drivers-defer = Choisir après la connexion
prepare-network-unmetered = Les mises à jour nécessitent une connexion Internet non limitée. Connectez-vous en Wi-Fi ou par Ethernet, puis réessayez.
# Connecté, mais Windows n'a trouvé aucun accès à Internet (portail captif, ou filtrage DNS ou pare-feu).
prepare-network-limited = Windows indique que ce réseau n’a pas accès à Internet. Connectez-vous au réseau s’il le demande, ou vérifiez votre routeur et tout filtrage DNS ou par pare-feu, puis réessayez.
# « Connexion limitée » est le nom de l'interrupteur dans les paramètres réseau de Windows.
prepare-network-metered = Cette connexion est définie comme limitée ou soumise à une limite de données. Connectez-vous à un réseau non limité, ou désactivez Connexion limitée dans les paramètres réseau, puis réessayez.
prepare-network-settings = Ouvrir les paramètres réseau
iso-stage-network-drivers = Préparation des pilotes réseau
# Under iso-complete when the adapters use drivers that come with Windows, so none were added.
iso-network-inbox = Les cartes réseau de ce PC utilisent des pilotes fournis avec Windows : l’ISO n’a donc pas besoin de les inclure.
desktop-setup-description = Terminez la configuration du PC. Vos choix Atlas sont enregistrés ; vous pouvez revenir à Windows si nécessaire.
desktop-setup-exit = Continuer dans Windows

# Clé USB d'installation de Windows
usb-title = Créer une clé USB
usb-existing = Créer une clé USB à partir d’une ISO existante
# Title of the drive card, and the name of a drive that doesn't report one.
usb-drive = Clé USB
# Title of the card with the ISO the USB drive is made from.
usb-iso-title = ISO Windows
# No ISO was given, and none whose name starts with "Atlas" is in Downloads.
usb-iso-missing = Aucune ISO Atlas ne se trouve dans votre dossier Téléchargements.
usb-iso-checking = Vérification de l’ISO…
# What checking the ISO found. It runs before anything is erased, so none of these mentions the drive.
usb-iso-not-usable = Atlas ne peut pas créer de clé USB à partir de cette ISO. Utilisez une ISO créée par Atlas, ou une ISO Windows 11 de Microsoft dans une version prise en charge par Atlas.
# A linked folder points to another place (a junction or symbolic link).
usb-iso-location = L’ISO ou Atlas Manager se trouve sur un emplacement réseau ou dans un dossier lié. Déplacez le fichier concerné dans un dossier de ce PC, comme Téléchargements.
# Atlas checks again every 30 seconds.
usb-working-space = L’espace libre est insuffisant sur le lecteur Windows pour préparer cette ISO. Libérez de l’espace ; Atlas vérifie à nouveau de lui-même.
# The ISO couldn't be read for another reason, such as a damaged file.
usb-iso-unreadable = Atlas n’a pas pu lire cette ISO. Réessayez ou utilisez une autre ISO.
# Opens the Storage page of Windows Settings.
usb-open-storage = Ouvrir les paramètres de stockage
usb-looking = Recherche de clés USB…
# $size is a whole number of gigabytes, as drives are sold.
usb-connect = Branchez une clé USB d’au moins { $size } Go.
# Under a drive that can't be used: why. $size as in usb-connect.
usb-drive-too-small-needs = Trop petite. Nécessite au moins { $size } Go.
usb-drive-too-small-iso = Trop petite pour cette ISO
usb-drive-has-iso = Votre ISO se trouve sur cette clé
usb-drive-has-app = Atlas Manager s’exécute depuis cette clé
# A drive's size as it's sold. $size is a whole number of gigabytes, or a number of terabytes (text).
usb-drive-size = { $size } Go
usb-drive-size-tb = { $size } To
# Joins a drive's size and its letters, and an ISO's architecture and size under its name.
usb-detail-separator = { " · " }
usb-create = Créer la clé USB
# Beside the unavailable Create USB drive while several drives are listed and none is picked.
usb-hint-pick = Sélectionnez d’abord une clé USB
# The question before erasing. $drive is the drive's name; $size is usb-drive-size or usb-drive-size-tb;
# $letters is its drive letters, such as "F:" or "F:, G:".
usb-confirm-title-letters = Effacer { $drive } ({ $size }, { $letters }) ?
usb-confirm-title = Effacer { $drive } ({ $size }) ?
# The same question for a drive that reports no name.
usb-confirm-title-unnamed-letters = Effacer la clé USB ({ $size }, { $letters }) ?
usb-confirm-title-unnamed = Effacer la clé USB ({ $size }) ?
usb-confirm-message = Tout son contenu sera supprimé. Votre ISO est conservée.
usb-confirm-erase = Effacer et créer
usb-progress-title = Création de la clé USB…
# $percent is a whole number.
usb-percent = { $percent } %
# The stages of creating the USB drive, as a checklist under usb-progress-title.
usb-stage-prepare-files = Préparation des fichiers
usb-stage-formatting = Formatage
usb-stage-copying = Copie des fichiers
usb-stage-checking = Vérification de la clé
usb-stage-ejecting = Éjection
usb-keep-open = Gardez Atlas ouvert et la clé branchée.
usb-scan-failed-title = Impossible de lire la liste des clés USB
usb-scan-failed-retry = Atlas n’a pas pu lire les clés USB branchées sur ce PC. Réessayez.
# The title of the error bar for a USB drive, and the heading of the finished drive's page.
usb-failed-title = Impossible de créer la clé USB
usb-complete-title = La clé USB est prête
# F12, F11 et Échap sont des noms de touches. « ce même PC » est le PC à réinstaller.
usb-ready = Débranchez-la et sauvegardez les fichiers du PC à réinstaller, puis démarrez ce même PC depuis la clé USB. Son menu de démarrage s’ouvre souvent avec F12, F11 ou Échap.
# After erasing may have begun.
usb-failed-partial = Une partie des données a déjà été écrite sur la clé. Vérifiez qu’elle est branchée, puis réessayez.
# Before anything on the drive was changed.
usb-failed-before-erase = Atlas s’est arrêté avant de modifier la clé. Réessayez.
# Before erasing, the drive no longer matched the list: it was removed, reconnected or replaced.
usb-drive-changed-title = La clé USB a changé
usb-drive-changed = Elle a été retirée ou rebranchée avant qu’Atlas ne l’efface : son contenu n’a donc pas été modifié.
usb-drive-cancelled-title = Création de la clé USB annulée
usb-cancelled-partial = La clé est incomplète. Recréez-la avant de l’utiliser.
usb-cancelled-unchanged = Votre clé USB n’a pas été modifiée.
usb-eject-failed-title = La clé USB n’a pas pu être éjectée
usb-eject-failed-ready = Elle est prête à l’emploi. Fermez les fichiers ou fenêtres qui l’utilisent, puis réessayez.
# Its message is usb-admin-reason, or usb-elevation-declined after Windows refused the relaunch.
usb-elevation-title = Atlas a besoin d’une autorisation pour créer une clé USB
usb-admin-reason = Atlas a besoin de l’autorisation d’administrateur pour effacer la clé et y écrire.
usb-elevation-declined = Windows n’a pas accordé l’autorisation à Atlas, qui ne peut donc pas encore écrire sur la clé USB.
# Famille (Home), LTSC et Server sont les éditions que la vérification refuse ; les autres sont des exemples d'éditions acceptées.
detail-edition-unsupported = Les éditions Famille, LTSC et Server de Windows 11 ne sont pas prises en charge. Utilisez une autre édition, comme Professionnel, Éducation ou Entreprise. Si Windows n’a pas pu identifier votre édition, résolvez ce problème avant de continuer.
install-source-title = Installation indisponible
install-source-unsupported = Atlas { $source } ne peut pas être mis à jour directement vers { $target }. Pour utiliser cette version, sauvegardez vos fichiers et réinstallez Windows.
# Avant le choix d'un package : la version proposée n'est pas encore connue.
install-source-unsupported-any = Atlas { $source } ne peut pas être mis à jour directement. Pour utiliser une version plus récente, sauvegardez vos fichiers et réinstallez Windows.
# $folder est un chemin de dossier (texte).
install-source-resume-package = Une installation d’Atlas { $target } ne s’est pas terminée, et seul le package Atlas { $target } permet de l’achever. Ouvrez ce package Atlas (.atlaspkg). Si Atlas l’a téléchargé, il se trouve dans { $folder }.
# Version de test : seul le package Atlas intégré peut être installé.
install-source-resume-bundled = Une installation d’Atlas { $target } ne s’est pas terminée. Cette version de test ne peut installer que son package Atlas intégré : terminez donc cette installation avec le package Atlas { $target } dans une version publiée d’Atlas Manager.
# Send a report and Export diagnostics are offered with it.
install-source-unconfirmed = Atlas n’a pas pu confirmer ce qui est déjà installé sur ce PC et n’installera donc rien pour le moment.
# Under the editions on the Create step, when Windows Setup asks which to install.
iso-edition-selection = Pendant l’installation de Windows, choisissez une édition couverte par votre licence.
detail-windows-preview = Les builds Insider ne sont pas prises en charge. Utilisez une version publique de Windows 11.
detail-windows-release-unknown = Atlas n’a pas pu confirmer que cette build de Windows est une version publique. Connectez-vous à Internet et vérifiez à nouveau.
# $build is this PC's Windows build and update number, such as 26300.9807 (text).
detail-windows-release-not-listed = La build { $build } ne figure pas dans la liste Microsoft des versions publiques de Windows 11 : Atlas ne peut donc pas encore s’y installer. Les builds Release Preview et les autres builds en préversion ne sont pas prises en charge. Vérifiez à nouveau quand Microsoft aura ajouté cette build à la liste.

prepare-continue = Poursuivre les mises à jour
prepare-saving-restart = Enregistrement de vos choix et configuration de la réouverture d’Atlas après le redémarrage de Windows…
prepare-restart-save-failed = Vos choix n’ont pas pu être enregistrés. Réessayez avant de redémarrer.
prepare-restart-registration-failed = Vos choix sont enregistrés, mais Atlas n’a pas pu prévoir sa réouverture après le redémarrage. Réessayez, ou redémarrez votre PC vous-même et ouvrez Atlas après votre connexion.
# The same cause as prepare-failed-source-linked, met while arranging the restart.
prepare-restart-source-linked = Vos choix sont enregistrés, mais tant qu’Atlas Manager se trouve dans un dossier lié, Atlas ne peut pas prévoir sa réouverture après le redémarrage. Fermez Atlas et déplacez Atlas Manager dans un dossier local de ce PC. Ouvrez-le ensuite depuis ce dossier, ou redémarrez votre PC vous-même et ouvrez-le depuis ce dossier après votre connexion.
prepare-restart-failed = Atlas n’a pas pu redémarrer votre PC. Réessayez ou redémarrez-le depuis le menu Démarrer. Vos choix sont enregistrés et Atlas se rouvrira après votre connexion.
diagnostics-export = Exporter les diagnostics
# Beside a spinner while an export runs, and in Send a report's footer while diagnostics are collected.
diagnostics-exporting = Collecte des diagnostics…
# Accessible name of the row of help links: report-title, diagnostics-export and iso-diagnostics.
diagnostics-help-a11y = Obtenir de l’aide
# Title of the result bar after an export; its button is iso-open-folder.
diagnostics-saved = Diagnostics enregistrés
# $file is the ZIP's name, such as Atlas-diagnostics-2026-11-24-0612.zip, and $folder the name of
# its folder, "Diagnostics" (both text, never translated).
diagnostics-saved-in-folder = Enregistrés sous le nom { $file } dans le dossier { $folder } d’Atlas.
# Says exactly what the export removes, so keep every item.
diagnostics-saved-privacy = Atlas en a retiré votre nom d’utilisateur, le nom du PC, les adresses e-mail ainsi que les mots de passe ou clés connus.
# The bar when an export failed. Its button is common-try-again.
diagnostics-save-failed = Impossible d’enregistrer le ZIP de diagnostic

## Tester builds (embedded-package feature)

# A bar at the top of the content on a release-candidate build.
rc-banner = Version de test Atlas { $release }. Cette application n’installe que le package Atlas intégré.
home-status-bundled = Version de test { $release }
package-bundled = Atlas { $version }, intégré à cette version de test, est prêt à être installé.
rc-about-release = Version de test
rc-about-commit = Commit source
rc-about-package = Package Atlas intégré (SHA-256)
iso-package-bundled = Le package Atlas intégré à cette version de test

check-user-account = Compte utilisateur
detail-user-account-ok = Le contrôle de compte d’utilisateur est activé et votre compte est prêt pour l’installation.
detail-user-account-not-ready = Activez le contrôle de compte d’utilisateur (UAC), redémarrez votre PC, puis réessayez. Si vous utilisez le compte Administrateur intégré, connectez-vous avec un autre compte administrateur.
detail-user-account-work-or-school = Atlas ne peut pas être installé depuis un compte professionnel ou scolaire (Microsoft Entra ID). Connectez-vous avec un compte local ou un compte Microsoft, puis réessayez.
detail-user-account-check-failed = Atlas n’a pas pu vérifier votre compte utilisateur. Redémarrez votre PC, puis rouvrez Atlas et vérifiez à nouveau. Windows a signalé : { $error }

footer-prepare-required = Terminez la mise à jour de Windows et des applications du Store pour continuer
# « Opération » comme dans prepare-close-stops-after-stage.
footer-prepare-stopping-stage = Arrêt des mises à jour après l’opération en cours…
resume-choices-title = Reprise de votre installation précédente
# The bar on Your choices, above the choices an unfinished installation holds.
resume-choices-held = Atlas reprend les choix que vous aviez faits la dernière fois pour terminer cette installation : ils ne peuvent donc pas être modifiés avant la fin.

## Rapports volontaires
report-title = Envoyer un rapport
report-received = Rapport reçu
# Under the report's reference, which has a line of its own with a Copy button.
report-reference = Conservez cette référence si vous contactez l’équipe Atlas au sujet de ce rapport. Si vous avez laissé vos coordonnées, l’équipe peut les utiliser pour vous répondre, mais une réponse n’est pas garantie.
# Nom accessible du bouton Copier à côté de la référence du rapport.
report-copy-reference = Copier la référence du rapport
report-another = Envoyer un autre rapport
# Libellé du choix entre les deux types de rapport.
report-kind = Que souhaitez-vous envoyer ?
report-kind-issue = Un problème
report-kind-suggestion = Une suggestion
report-message = Votre message
# What the message box shows while it's empty, for each kind of report.
report-message-placeholder-issue = Que s’est-il passé, et que faisiez-vous ?
report-message-placeholder-suggestion = Que souhaiteriez-vous changer ?
# Under the message box, which also reads it out.
report-message-help = N’indiquez aucun mot de passe.
# Under the message or contact box once it's near the limit. $count and $max are numbers.
report-character-count = { $count } sur { $max } caractères
report-contact = Coordonnées (facultatif)
report-contact-placeholder = Adresse e-mail ou nom d’utilisateur Discord
report-attach = Joindre les diagnostics
# Part of the privacy notice the user agrees to: keep every item.
report-attach-description = Journaux et informations système qui aident à trouver la cause. Atlas retire votre nom d’utilisateur, le nom du PC, les adresses e-mail ainsi que les mots de passe ou clés connus. Les détails des erreurs, les modèles de matériel et les noms d’applications sont conservés. Vous pouvez vérifier le ZIP avant l’envoi.
report-review = Vérifier le ZIP
# A bar when diagnostics couldn't be prepared. Its button is common-try-again.
report-prepare-failed-title = Impossible de préparer les diagnostics
report-prepare-failed-advice = Réessayez, ou envoyez le rapport sans diagnostics.
# The privacy notice the user agrees to, with report-attach-description.
report-privacy = Votre rapport est envoyé en privé à l’équipe Atlas sur reports.atlasos.net. Votre message et vos coordonnées sont envoyés tels que vous les avez saisis. L’équipe peut faire appel à des services d’IA d’autres entreprises pour l’aider à analyser le problème. Ces services reçoivent votre message et les diagnostics, mais pas vos coordonnées. Les rapports sont supprimés au bout de 90 jours, et les journaux de sécurité du serveur peuvent enregistrer votre adresse IP.
report-website = Confidentialité et site de signalement
report-consent = J’accepte d’envoyer ce rapport et les éventuels diagnostics joints à l’équipe Atlas
# Under report-failed-title. The footer's button is common-try-again, except after
# report-not-sent-outdated, where it's report-failed-website.
report-not-sent-retry = Vérifiez votre connexion Internet, puis réessayez. Vous pouvez aussi l’envoyer depuis le site de signalement.
report-not-sent-busy = Le service de signalement est occupé. Patientez quelques minutes, puis réessayez.
report-not-sent-outdated = Cette version d’Atlas Manager ne peut pas envoyer de rapports. Copiez votre message sur le site de signalement, avec le ZIP si vous avez joint les diagnostics.
report-not-sent-diagnostics = Les diagnostics n’ont pas pu être envoyés. Réessayez, ou envoyez le rapport sans diagnostics.
# The footer's button where this version can't send.
report-failed-website = Ouvrir le site de signalement
# Beside a spinner in the footer while the report is on its way.
report-sending = Envoi…
report-send = Envoyer le rapport

# $min et $max sont des nombres : les longueurs de message acceptées.
report-validation-message = Saisissez entre { $min } et { $max } caractères.

# $max est un nombre : la longueur maximale des coordonnées.
report-validation-contact = Limitez les coordonnées à { $max } caractères.

# Sous la case d'accord lorsque Envoyer le rapport est choisi sans elle.
report-validation-consent = Confirmez votre accord pour envoyer ce rapport.

report-failed-title = Rapport non envoyé

## Mise à jour de la version de Windows
# Atlas fait passer Windows à une version plus récente avant l'installation, via Windows Update.
# $release est la version cible (26H2) et $current celle du PC (24H2) ; « Windows 11, version »
# les précède, comme chez Microsoft. $version est une version d'Atlas.

# Home, under the update button, when the update also moves Windows. home-plan-name is the
# accessible name of the list of its two parts.
home-plan-files = Vos fichiers et vos applications sont conservés.
home-plan-name = Cette mise à jour se fait en deux temps
home-plan-windows-title = Windows 11, version { $release }
home-plan-windows-step = Atlas l’installe depuis Windows Update, puis votre PC redémarre.
# The same step where moving is optional.
home-plan-windows-step-ask = Facultatif. Après votre accord, Atlas l’installe depuis Windows Update, puis votre PC redémarre.
# Instead of the step's own line, once Windows has moved.
home-plan-step-installed = Installé.
home-plan-atlas-title = Atlas { $version }
home-plan-atlas-step = Atlas se met à jour en conservant vos choix, puis votre PC redémarre.
# $date and $until are dates.
home-end-of-updates-title = Windows 11, version { $current } cessera de recevoir des mises à jour de sécurité le { $date }
home-end-of-updates-past-title = Windows 11, version { $current } ne reçoit plus de mises à jour de sécurité
home-end-of-updates-message = La mise à jour vers Atlas { $version } fait aussi passer ce PC à Windows 11, version { $release }, qui reçoit des mises à jour de sécurité jusqu’au { $until }.
# Instead of home-end-of-updates-message when the card with the update's two parts is under the bar.
home-end-of-support-plan = Windows 11, version { $release } reçoit des mises à jour de sécurité jusqu’au { $until }.

# Home, when this Windows can't take the Atlas version at all. $product is Windows' own name
# for the edition, such as Windows 11 Home (text).
install-windows-edition-only = Atlas { $version } fonctionne avec Windows 11 Professionnel, Entreprise et Éducation : il ne peut donc pas s’installer sur { $product }.
# The same, on a version whose security updates end, with Open Windows Update. $date is a date.
install-windows-edition-until = Atlas { $version } fonctionne avec Windows 11 Professionnel, Entreprise et Éducation : il ne peut donc pas s’installer sur { $product }. Windows 11, version { $current } reçoit des mises à jour de sécurité jusqu’au { $date }, et Windows Update peut faire passer ce PC à une version plus récente.
# The same once that date has passed.
install-windows-edition-ended-update = Atlas { $version } fonctionne avec Windows 11 Professionnel, Entreprise et Éducation : il ne peut donc pas s’installer sur { $product }. La version { $current } ne reçoit plus de mises à jour de sécurité : mettez Windows à jour, même sans Atlas.
# $releases lists the supported releases, such as "25H2 ou 26H2".
install-windows-reinstall = Atlas { $version } nécessite Windows 11, version { $releases }, et Windows Update ne peut pas y faire passer ce PC. Sauvegardez vos fichiers, puis réinstallez Windows avec une ISO Atlas.
# The same on Home, where the card that creates an Atlas ISO comes first.
home-windows-no-path = Atlas { $version } nécessite Windows 11, version { $releases }, et Windows Update ne peut pas y faire passer ce PC.

# Home, when Atlas changed Windows Update settings for an update and hasn't put them back.
# The bar's button is home-put-back; home-continue-update is beside the version above.
home-update-access-title = Paramètres Windows Update modifiés pour la mise à jour d’Atlas
# While an update that moves Windows is under way.
home-update-access-put-back-later = Atlas rétablit ces paramètres à la fin de la mise à jour.
# When the last check found no offer yet.
home-update-access-waiting = Atlas a activé Windows Update pour faire passer ce PC à Windows 11, version { $release }, mais Windows Update ne l’a pas encore proposé.
home-update-access-updating = Atlas a activé Windows Update pour installer des mises à jour et n’a pas terminé.
# Instead of home-update-access-title when Atlas can't read its record of the settings it changed.
home-update-access-unreadable-title = Impossible de lire l’enregistrement Windows Update d’Atlas
home-update-access-unreadable-problem = Atlas ne parvient pas à lire son enregistrement des paramètres Windows Update qu’il a modifiés : il ne modifiera et ne rétablira donc rien.
# When putting the settings back failed for another reason. Put back settings tries again.
home-put-back-failed = Atlas n’a pas pu rétablir les paramètres.
# Why the Windows Update settings Atlas changed can't be put back yet: an unfinished installation
# or update puts them back in its last stage. Shown on Home, in the close question and on Get
# ready, for an install and an update alike. « Opération » : une phase de l'installation, pas une
# des quatre étapes.
update-access-finish-install = Terminez d’abord l’installation d’Atlas. Sa dernière opération rétablit les paramètres Windows Update modifiés par Atlas.
home-continue-update = Reprendre la mise à jour
home-put-back = Rétablir les paramètres
home-putting-back = Rétablissement des paramètres…

# Get ready: the card of the move to a newer Windows version, first on the page.
windows-card-title = Windows 11, version { $release }
# Under the title of a move the Atlas package needs, before the go-ahead.
windows-required = Atlas { $version } ne prend pas en charge la version { $current } : Atlas met donc d’abord Windows à jour.
# Under the title where moving is optional.
windows-optional = Atlas fonctionne avec les deux versions.
# The choice's accessible name; the two answers say it.
windows-card-question = Quelle version de Windows ce PC doit-il utiliser ?
windows-choice-move-recommended = Mettre à jour vers Windows 11, version { $release } (recommandé)
# $date is when the new version stops getting security updates.
windows-choice-move-support = Mises à jour de sécurité jusqu’au { $date }.
windows-choice-keep = Conserver Windows 11, version { $current }
windows-choice-keep-later = Reste sur la version { $current }. Vous pourrez changer de version plus tard depuis Atlas Manager.
windows-card-facts = Ce qui change
windows-fact-files = Vos fichiers et vos applications sont conservés. Atlas rétablit tout ce que la mise à jour annule.
windows-fact-time = En général quelques minutes, jusqu’à 2 heures, puis un redémarrage.
# Behind Show details, on a PC whose version still has them.
windows-fact-removes = Supprime Windows PowerShell 2.0 et WMIC.
# Opens the Atlas documentation on undoing the move, where moving is optional.
windows-undo-link = Comment annuler la mise à jour
# Before windows-accept: accepting the terms and starting the move are one choice.
windows-terms-line = En mettant à jour, vous acceptez les termes du contrat de licence logiciel Microsoft.
windows-terms-link = Lire les termes du contrat de licence
windows-accept = Accepter et mettre à jour
# Once the terms are accepted, before the move starts by itself.
windows-starting = Démarrage…
windows-starts-after-checks = Démarre dès que les vérifications réussissent.
windows-starts-after-package = Démarre dès qu’Atlas { $version } est prêt.
# After the move, when Windows reinstalled itself instead of switching the new version on.
windows-rebuilt = La version { $release } a annulé certaines modifications d’Atlas. Atlas { $version } les rétablit avec vos choix précédents.
# Asked before keeping this version once the move has begun; the message is stop-update-before
# and the buttons are common-cancel and prepare-keep-version.
windows-keep-title = Conserver Windows 11, version { $current } ?


# La barre qui nomme chaque paramètre Windows Update qu'Atlas active pour la mise à jour.
access-notice-title = Atlas active temporairement Windows Update
access-off = Windows Update est désactivé sur ce PC. Atlas le réactive pendant qu’il met à jour Windows.
access-paused = Les mises à jour Windows sont suspendues sur ce PC. Atlas lève cette suspension pendant qu’il met à jour Windows.
access-delayed = Les mises à jour mensuelles sont différées sur ce PC. Atlas supprime ce report pendant qu’il met à jour Windows.
# Après les lignes ci-dessus.
access-back = Une fois Atlas { $version } installé, ces paramètres sont rétablis tels qu’ils étaient.
access-back-stop = Si vous arrêtez avant, Atlas les rétablit.

prepare-reason-feature-update = la nouvelle version de Windows
prepare-reason-feature-commit = la finalisation de la nouvelle version de Windows
# Waiting for Windows Update to offer the new version: the progress bar's label and status line,
# the line under the bar, and how long Atlas has waited, in whole minutes.
windows-waiting = En attente de Windows 11, version { $release } dans Windows Update…
windows-waiting-detail = En général quelques minutes, jusqu’à 2 heures. Atlas poursuit de lui-même ; vous pouvez continuer à utiliser votre PC.
windows-waited =
    { $minutes ->
        [one] En attente depuis { $minutes } minute.
       *[other] En attente depuis { $minutes } minutes.
    }
# After 2 hours without an offer. The buttons are common-try-again and iso-open.
windows-wait-ended-title = Windows Update n’a pas proposé la version { $release } en 2 heures
windows-wait-ended = Atlas a rétabli vos paramètres. Réessayez plus tard ou réinstallez Windows avec une ISO Atlas.
# Instead of the message above when putting the settings back failed. The button is home-put-back.
windows-wait-put-back-failed = Atlas n’a pas pu rétablir vos paramètres Windows Update.
# Windows couldn't get the new version ready to finish at the restart, so the PC didn't restart.
windows-commit-failed-title = Windows n’a pas pu préparer le redémarrage
windows-commit-failed = Votre PC n’a pas redémarré. Réessayez.

# Outcomes of moving Windows, each a title and what to do next. A cause only the Atlas team can
# look into has report-title as its button; one an ISO fixes, iso-open.
windows-outcome-not-offered-title = Windows Update n’a pas encore proposé la version { $release }
windows-outcome-not-offered = Cela peut prendre jusqu’à 2 heures. Votre PC utilise toujours la version { $current }.
windows-outcome-hardware-title = Ce PC ne répond pas à la configuration requise pour Windows 11
# $missing lists the hardware this PC lacks, from the two messages below.
windows-outcome-hardware = Il lui manque : { $missing }. Windows Update ne proposera donc pas la version { $release }. Sauvegardez vos fichiers, puis réinstallez Windows avec une ISO Atlas.
hardware-tpm = TPM 2.0
hardware-uefi = microprogramme UEFI
windows-outcome-hidden-title = La version { $release } est masquée dans Windows Update
windows-outcome-hidden = Affichez-la à nouveau avec l’outil qui a servi à la masquer, puis réessayez.
windows-outcome-disk-space-title = Espace libre insuffisant
# $needed and $free are whole gigabytes; $drive is a drive such as C:. The button is check-fix-storage.
windows-outcome-disk-space = Windows a besoin de { $needed } Go d’espace libre sur { $drive }, qui n’a que { $free } Go. Atlas poursuit de lui-même dès qu’il y en a assez.
windows-outcome-managed-title = Ce PC reçoit ses mises à jour de son organisation
windows-outcome-managed = Son serveur de mise à jour ne propose pas la version { $release } : Atlas n’a donc rien modifié. Adressez-vous à votre organisation ou réinstallez Windows avec une ISO Atlas.
windows-outcome-policy-title = Un élément rétablit sans cesse les paramètres de Windows Update
# $setting is the technical name of a Windows Update policy value, such as NoAutoUpdate, shown as it is.
windows-outcome-policy = { $setting } revient à sa valeur précédente après chaque modification d’Atlas : Atlas ne peut donc pas mettre à jour Windows. Si ce PC est géré par une organisation, adressez-vous à elle.
# $service is a service-* name, after a fixed phrase so that the name needs no agreement. The
# buttons are common-try-again and prepare-open-services.
windows-outcome-service-off-title = Service désactivé : { $service }
windows-outcome-blocked-service = Windows Update en a besoin. Définissez son type de démarrage sur Manuel dans Services, puis réessayez.
windows-outcome-blocked-title = Un élément maintient Windows Update désactivé
windows-outcome-blocked = Un paramètre qu’Atlas n’a pas modifié, { $setting }, l’empêche de fonctionner. Modifiez-le, puis réessayez.
windows-outcome-rollback-title = Windows n’a pas pu terminer l’installation de la version { $release }
windows-outcome-rolled-back = Il est revenu à la version { $current }. Vos fichiers et vos applications sont intacts.
windows-outcome-components-lost-title = Certaines modifications d’Atlas ont disparu
windows-outcome-components-lost = Atlas ne parvient pas à en déterminer la cause : il s’est donc arrêté avant d’installer Atlas { $version }.
windows-outcome-build-title = Windows a changé de version pendant la mise à jour
windows-outcome-build = Rétablissez les paramètres modifiés par Atlas, puis recommencez depuis l’accueil.
windows-outcome-journal-title = Atlas ne parvient pas à lire son enregistrement de cette mise à jour
windows-outcome-journal = Il ne modifiera et ne rétablira rien tant que l’équipe Atlas n’aura pas examiné le problème.
windows-outcome-pin-title = Une stratégie Windows Update ne peut pas être enregistrée
# $setting is the name of a Windows Update policy value, such as TargetReleaseVersionInfo.
windows-outcome-pin = { $setting } a une valeur qu’Atlas ne pourrait pas rétablir ensuite : Atlas n’a donc rien modifié.
windows-outcome-terms-title = Les termes du contrat de licence n’ont pas été acceptés
windows-outcome-terms = Windows Update exige leur acceptation avant d’installer la version { $release }.
windows-outcome-failed-title = Windows n’a pas pu installer la version { $release }
windows-outcome-failed = Votre PC utilise toujours la version { $current }.
# Windows services a move needs, as Services lists them in French Windows.
service-bits = Service de transfert intelligent en arrière-plan (BITS)
service-cryptsvc = Services de chiffrement
service-trusted-installer = Programme d’installation pour les modules Windows
prepare-open-services = Ouvrir Services
# Confirme la conservation de cette version dans la question windows-keep-title.
prepare-keep-version = Conserver la version { $current }

# Asked before leaving the update with Windows Update settings changed.
stop-update-title = Arrêter la mise à jour vers Atlas { $version } ?
# stop-update-title for a first install or a reinstall, which so far has only updated Windows.
stop-update-title-windows = Arrêter la mise à jour de Windows ?
stop-update-before = Atlas rétablit les paramètres Windows Update qu’il a modifiés. Les mises à jour déjà installées par Windows le restent, et votre PC conserve Windows 11, version { $current }.
stop-update-after = Votre PC conserve Windows 11, version { $release }. Atlas rétablit les paramètres Windows Update qu’il a modifiés.
stop-update-access = Atlas rétablit les paramètres Windows Update qu’il a modifiés. Les mises à jour déjà installées par Windows le restent.
stop-update-keep = Continuer la mise à jour
# Boîte de dialogue affichée si la fenêtre est fermée pendant que Windows Update est activé pour une mise à jour. Ses boutons sont window-close-keep et window-close-put-back.
window-close-update-access-title = Fermer Atlas ?
window-close-update-access-message = Avant de se fermer, Atlas rétablit les paramètres Windows Update qu’il a modifiés. Vous pourrez recommencer la mise à jour depuis l’accueil.
window-close-put-back = Rétablir et fermer
# When putting the settings back before closing failed. The buttons are window-close-keep and window-close-close.
window-close-put-back-failed-title = Fermer sans rétablir les paramètres ?
window-close-put-back-failed-message = Si vous fermez Atlas maintenant, les paramètres Windows Update restent tels qu’Atlas les a modifiés. Lorsque vous rouvrirez Atlas, l’accueil vous proposera de les rétablir.

# PC checks: Windows compatibility on a version Atlas moves from.
detail-build-needs-release = Cette version d’Atlas nécessite Windows 11, version { $release }, et ce PC utilise la version { $current }.

# Les premières lignes d'un rapport sur une mise à jour de Windows inachevée ; les détails techniques suivent en anglais.
report-transition-intro = La mise à jour de Windows pour Atlas ne s’est pas terminée. Détails pour l’équipe Atlas :

# When Windows reinstalled itself while it moved to a newer version.
history-mode-rebase = réinstallation après une mise à jour de Windows
# Your choices after Windows reinstalled itself during a move.
rebase-choices-title = Vos choix d’Atlas { $previous }
rebase-choices-kept = Atlas rétablit les choix que vous aviez faits pour Atlas { $previous }. Vous pourrez les modifier plus tard en réinstallant Atlas.
# Above the questions the record of the move had no answer for.
rebase-choices-asked = Atlas rétablit tous les autres choix que vous aviez faits pour Atlas { $previous }.
# Asked before any restart Atlas makes while other people are signed in. Its buttons are
# restart-others-keep, the default, and restart-others-restart.
restart-other-question = Redémarrer alors qu’une autre personne est connectée ?
restart-others-question = Redémarrer alors que d’autres personnes sont connectées ?
# $names lists their account names, such as "Alex et Sam"; $count is how many there are. The
# wording avoids agreeing with the person's gender.
restart-others-signed-in =
    { $count ->
        [one] { $names } a aussi une session ouverte. Le redémarrage fermera ses applications et lui fera perdre son travail non enregistré.
       *[other] { $names } ont aussi une session ouverte. Le redémarrage fermera leurs applications et leur fera perdre leur travail non enregistré.
    }
restart-others-keep = Ne pas redémarrer
restart-others-restart = Redémarrer quand même
# Microsoft Store itself, before the Store apps: Get ready's status line while it updates or is repaired.
prepare-store-updating = Mise à jour du Microsoft Store…
prepare-store-repairing = Réparation du Microsoft Store…
prepare-store-repair-detail = Cela peut prendre quelques minutes.
# Under ready-updates-done-windows once Get ready has finished, where Microsoft Store is turned off.
prepare-store-skipped-removed = Le Microsoft Store est désactivé sur ce PC : les applications du Store n’ont donc pas été mises à jour.
# None of Atlas's repairs made Microsoft Store work. The button is prepare-repair-store-again;
# prepare-store-broken-iso and iso-open are behind common-show-details.
prepare-store-broken-title = Le Microsoft Store ne fonctionne pas
prepare-store-broken = Atlas n’a pas pu le réparer, et installer Atlas maintenant pourrait empêcher les applications du Store de fonctionner.
prepare-store-broken-iso = Si la réparation échoue encore, sauvegardez vos fichiers et réinstallez Windows avec une ISO Atlas.
prepare-repair-store-again = Réessayer la réparation

screen-keyboard-title = Langues du clavier
screen-keyboard-question = Utilisez-vous plusieurs langues de clavier ?
package-option-keyboard-shortcuts = Oui, avec des raccourcis clavier
package-option-keyboard-selector = Oui, avec le sélecteur de la barre des tâches
package-option-keyboard-single = Non, une seule disposition
consequence-keyboard-shortcuts = Alt+Maj change la langue ; Ctrl+Maj change la disposition.
consequence-keyboard-selector = Désactive Alt+Maj et Ctrl+Maj pour éviter les changements involontaires en jeu.
package-choice-keyboard-description = Choisissez comment changer la langue du clavier.
consequence-keyboard-single = { consequence-keyboard-selector }
