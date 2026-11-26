### Atlas Manager: Português (Brasil), pt-BR. Preview translation, revised on 24 November 2026 from the en-GB source (i18n/en-GB/atlas.ftl).
###
### Style notes for this catalog: address the reader as "você" (mostly implicit),
### the computer is "seu PC" / "o PC"; "o Atlas" and "o Windows" take the article;
### buttons are short infinitives ("Reiniciar agora"); headings are sentence case
### with no final full stop. "Reiniciar" is only ever the PC / Windows; reopening
### the Atlas Manager is "reabrir". The four Windows Security switches keep the names
### Windows shows in Brazilian Portuguese and are referred to as "proteções".
### This catalog also serves pt-PT requests; Brazilian vocabulary is used where
### no neutral form exists (baixar, arquivo, configurações, excluir, tela).
### The .atlaspkg file is the "pacote do Atlas" ("o pacote" once it is clear).
### Install steps: Preparação, Suas escolhas, Segurança do Windows, Instalação
### ("à etapa Preparação"). ISO steps: Windows, Configuração, Criação.
### "Etapa" is only a flow step; a stage of updating or of the installer is a "fase".
### Windows Setup, the program, is "a Instalação do Windows" (capital I).
### A Windows build is a "compilação"; a USB drive is a "unidade USB".
### The switch names differ in gender, so sentences put them after a colon
### ("Esta proteção está desativada: …") instead of agreeing with them.
### Plurals are one and other; one covers 0.

## Compartilhado

app-name = Atlas Manager
common-done = Concluído
common-cancel = Cancelar
common-back = Voltar
common-next = Continuar
common-dismiss = Fechar
# Link beside a summary row that jumps back to change that choice.
common-change = Alterar
common-copy = Copiar
# Shown where a list of options is empty.
common-none = Nenhuma
# Accessible name of the back arrow on the Install and Settings pages.
common-back-to-home = Voltar à página inicial
# Accessible name of the gear button in the title bar.
common-settings = Configurações
common-close-settings = Fechar configurações
common-open-windows-security = Abrir a Segurança do Windows
# "Relaunch" means reopening Atlas Manager (elevated), never restarting the PC.
common-restart-as-administrator = Reabrir como administrador
common-try-again = Tentar novamente
common-read-the-docs = Ler o guia do Atlas
common-show-details = Mostrar detalhes
common-hide-details = Ocultar detalhes
# Accessible name of a button that acts on one card, so two buttons with the same label stay
# distinct: a Show details or Hide details toggle, or PC checks' Check again. $action is the
# button's label; $section is the title of its card.
common-details-a11y = { $action }, { $section }
# Opens the folder of the install log, with the log selected.
common-open-log-folder = Abrir pasta de logs
# Accessible name of the Copy button beside the install log.
common-copy-install-log = Copiar log de instalação
common-install-log = Log de instalação
# Row labels in summary cards.
common-windows = Windows
common-package = Pacote do Atlas
common-checking = Verificando
# Joins two items in a list: "Brave, Firefox". The braces keep the space.
list-separator = { ", " }
# Joins two alternatives: "26100 or 26200".
list-or = { $a } ou { $b }
# Joins the last two items of a list: "Tamper Protection and Cloud-delivered protection".
# $a may itself be several items joined with list-separator.
list-and = { $a } e { $b }
# Accessible name of a message bar that announces itself: its title, then its message.
infobar-a11y = { $title }. { $message }

## Janela

# Dialog shown when the window is closed while an install runs. Its buttons are
# window-close-keep and window-close-close.
window-close-title = Fechar durante a instalação do Atlas?
window-close-installing = A instalação continua em andamento. Reabra o Atlas para ver o resultado.
# Instead of window-close-installing when the installation restarts the PC afterwards: only an
# open Atlas window restarts it, so closing the window cancels that.
window-close-installing-no-restart = A instalação continua em andamento, mas seu PC não será reiniciado sozinho. Reabra o Atlas para ver o resultado.
# The answer that keeps the window open when closing it would interrupt something, such as
# installing or Windows Update access.
window-close-keep = Manter aberta
window-close-close = Fechar janela
# Dialog shown when the window is closed during the final checks, before the installer has
# started. Its buttons are window-close-keep-installing and window-close-stop-and-close.
window-close-checks-question = Parar antes de instalar?
window-close-checks-unchanged = A instalação ainda não alterou nada. Se você fechar, ela não vai começar.
window-close-keep-installing = Continuar instalando
window-close-stop-and-close = Parar e fechar
# Dialog shown when the window is closed while Windows and Store apps update. Its buttons are
# stop-update-keep and prepare-stop. Atlas stays open once it has stopped.
prepare-close-question = Parar as atualizações?
# "Stage" is a stage of updating (as in prepare-percent), not one of the four flow steps.
prepare-close-stops-after-stage = O Atlas vai parar após a fase atual. Depois disso, você poderá fechá-lo.
# Dialog shown when the window is closed during the restart countdown after a successful
# install. Its buttons are restart-now and restart-dont-now, the default, which closes Atlas
# without restarting.
window-close-restart-question = Reiniciar para concluir a configuração do Atlas?
window-close-restart-closed = O Atlas não consegue reiniciar seu PC depois de fechado. Salve seu trabalho primeiro.
# Closing while Get ready counts down to the restart Windows and Store updates need. Its buttons
# are restart-now and restart-dont-now ("Restart later"), the default, which closes Atlas; Atlas
# opens again and carries on after the next restart.
window-close-update-restart-question = Reiniciar para concluir a atualização?
window-close-update-restart-later = Salve seu trabalho primeiro. Se você reiniciar depois, o Atlas continua após a reinicialização.
# Dialog shown when the window is closed during a setup with Windows Security switches still
# off. Its message is window-close-protection-all or window-close-protection-some; its buttons
# are common-open-windows-security and window-close-close.
window-close-protection-title = Fechar o Atlas com a proteção desativada?
window-close-protection-all = As quatro proteções da Segurança do Windows estão desativadas. Se você não for instalar o Atlas agora, reative-as primeiro.
# $switches names the switches that are off as Windows Security does, joined like a list;
# $count is how many there are.
window-close-protection-some =
    { $count ->
        [one] Esta proteção está desativada na Segurança do Windows: { $switches }. Se você não for instalar o Atlas agora, reative-a primeiro.
       *[other] Estas proteções estão desativadas na Segurança do Windows: { $switches }. Se você não for instalar o Atlas agora, reative-as primeiro.
    }
# Dialogs shown when the window is closed while an ISO or a USB drive is being created.
# Their buttons are window-close-keep-creating and window-close-stop; Atlas stays open once it
# has stopped.
iso-close-question = Parar a criação da ISO?
iso-close-safe-point = O Atlas vai parar no próximo ponto seguro.
usb-close-question = Parar a criação da unidade USB?
usb-close-unfinished = Uma unidade incompleta não pode instalar o Windows.
window-close-keep-creating = Continuar criando
window-close-stop = Parar
# The Open button of the file picker for an Atlas package (.atlaspkg) file, on Get ready and the
# ISO page. It's a button label, so keep it short.
file-dialog-open-package = Abrir um pacote do Atlas (.atlaspkg)
# Message Windows shows in its restart notification.
shutdown-comment = O Atlas foi instalado. O Windows está reiniciando para concluir a configuração.
# Message Windows shows in its restart notification when "Get ready" restarts
# to finish installing Windows updates.
prepare-shutdown-comment = O Atlas está reiniciando o Windows para concluir a instalação das atualizações.

## Sistema

# "Windows 11 Pro 25H2 (build 26200.1234)". All three values are text.
system-description = { $product } { $version } (compilação { $build })

## Página inicial

home-not-installed = Boas-vindas ao Atlas
# Under home-not-installed: this PC's Windows, such as "Windows 11 Pro 25H2". Both values are text.
home-windows = { $product } { $version }
# Instead of home-windows once Atlas has found its latest release: this PC's Windows and the Atlas
# version Install Atlas would install, such as "Windows 11 Pro 25H2 · Atlas 0.6.1". $product and
# $version are this PC's Windows edition and version, and $atlas is the Atlas version (all text).
home-windows-atlas = { $product } { $version } · Atlas { $atlas }
# Under home-windows or home-windows-atlas, on a PC without Atlas: what Atlas does, in one sentence.
# Keep it to what Atlas changes: don't promise a faster PC.
home-about = O Atlas reduz a atividade em segundo plano e as distrações do Windows.
# The headline when Atlas Manager can't tell what is installed on this PC.
home-state-unknown = Atlas neste PC
# The headline when Atlas is installed. $version is text.
home-version = Atlas { $version }
# Beside the update status, on the line under the version. $date is a formatted date.
home-installed-on = Instalado em { $date }
home-status-checking = Verificando atualizações…
# While startup checks whether another window's installation is running.
home-status-recovering = Procurando uma instalação em andamento
home-status-offline = Não foi possível verificar atualizações
home-status-not-checked = Atualizações ainda não verificadas
home-status-update = O Atlas { $version } está disponível
home-status-up-to-date = Atualizado
home-status-newest = Versão mais recente: Atlas { $version }
# An earlier installation of Atlas { $version } stopped before it finished.
home-status-unfinished = A instalação do Atlas { $version } não terminou
home-check-again = Verificar novamente
# Primary button while an install is running or waiting.
home-show-install = Ver progresso
home-continue-installing = Continuar a configuração
home-update-to = Atualizar para o Atlas { $version }
home-reinstall = Reinstalar o Atlas
home-install = Instalar o Atlas
home-finish-install = Concluir a instalação do Atlas { $version }
home-start-over = Começar de novo
# The question Install Atlas asks where Windows on this PC has been in use: installed a week
# or more ago, or with several apps. Its buttons are common-cancel and home-used-windows-install.
home-used-windows-title = Instalar o Atlas neste PC?
# OneDrive: use the name Windows shows in your language.
home-used-windows-message = Os apps e as configurações que você já tem podem parar de funcionar, e o Atlas remove o OneDrive, então os arquivos nele deixam de ser sincronizados e as pastas podem parecer vazias. Faça backup dos seus arquivos primeiro.
home-used-windows-install = Instalar mesmo assim
# The card that opens ISO creation; its button is iso-open.
home-iso-title = Reinstalar o Windows com o Atlas
# Under home-iso-title, with the Recommended badge, where Windows on this PC has been in use.
home-iso-used = O Windows deste PC já foi usado, e o Atlas funciona melhor em uma instalação limpa.
# A bar on Home after an installation finished, until the PC restarts. Its message is
# restart-needed and its button restart-now.
home-restart-title = Seu PC precisa ser reiniciado
# Instead of restart-needed when Windows refused to restart. The raw error is behind Show
# details, and the bar's button is common-try-again.
home-restart-failed = O Atlas não conseguiu reiniciar seu PC. Reinicie-o pelo menu Iniciar.
home-security-reminder-title = Reative sua proteção
# Instead of home-security-reminder-title when no switch reads off but some couldn't be read
# (with home-security-reminder-unreadable-message).
home-security-reminder-unreadable-title = Confira se sua proteção está ativada
# Under home-security-reminder-title, after leaving the install flow or an installation that kept
# Microsoft Defender. $switches names the switches that read off, as Windows Security names them
# (protection-*), joined with list-separator and list-and; $count is how many it names.
security-switches-still-off =
    { $count ->
        [one] Esta proteção continua desativada na Segurança do Windows: { $switches }.
       *[other] Estas proteções continuam desativadas na Segurança do Windows: { $switches }.
    }
# Instead of security-switches-still-off when no switch
# reads off but some couldn't be read. $switches names those, joined like a list.
home-security-reminder-unreadable-message = O Atlas não conseguiu ler todas as proteções. Confira na Segurança do Windows se estas proteções estão ativadas: { $switches }.
home-elevation-title = O Atlas precisa de permissão para instalar
# Under home-elevation-title when the setup choices couldn't be saved; the raw error is
# behind Show details.
home-elevation-draft-not-saved = O Atlas não conseguiu salvar suas escolhas de configuração, então não foi reaberto.
home-state-error-title = Não foi possível ler os dados da sua instalação do Atlas
# Its button is common-try-again; the raw error is behind Show details.
home-state-error-problem = A versão, as escolhas e o histórico do Atlas podem não aparecer corretamente.
# A bar on Home when the Atlas package needs a newer Atlas Manager. Its message is
# acquire-manager-update-required or acquire-manager-update-required-any, and the button beside
# the version above is manager-download.
home-manager-needed-title = O Atlas Manager precisa ser atualizado
home-whats-new = Novidades do Atlas { $version }
home-view-release = Ver notas da versão no GitHub
home-show-less = Mostrar menos
home-show-full-notes = Mostrar todas as notas da versão
home-your-install = Sua configuração do Atlas
# Atlas is installed, but without the record Atlas Manager keeps (older versions didn't write one).
home-install-unrecorded = Este PC não tem registro de como o Atlas foi instalado, então não é possível mostrar suas escolhas nem o histórico de instalações.
home-history = Histórico de instalações
# One history row. $version is text, $mode one of the history-mode-* messages, $date a formatted date and time.
home-history-entry = Atlas { $version } · { $mode } · { $date }
# Accessible name of a numbered step.
home-step-a11y = Etapa { $number }: { $title }
# Accessible name of a numbered step with its sentence, as screen readers read each step of
# Home's lists. $step is home-step-a11y or stepper-item-a11y, and $detail is the step's sentence,
# such as home-step-ready.
home-step-detail-a11y = { $step }. { $detail }
# The card on Home that lists the four install steps (step-ready, step-options, step-security and
# step-install) on a PC without Atlas, each with its home-step-* sentence beside it.
home-steps-title = O que vai acontecer
# Instead of home-steps-title while a setup is under way: each step shows whether it's done, current
# or still to come.
home-steps-under-way-title = Configuração do Atlas em andamento
# Beside step-ready in that card.
home-step-ready = O Atlas verifica seu PC e atualiza o Windows.
# Instead of home-step-ready where Windows must move to a newer version before Atlas can install.
# $release is that version, such as "26H2" (text).
home-step-ready-move = O Atlas verifica seu PC e leva o Windows à versão { $release }.
# Beside step-options in that card. Microsoft Defender is one of the choices asked there.
home-step-options = Você escolhe o que manter, como o Microsoft Defender.
# Beside step-security in that card.
home-step-security = Você desativa as quatro proteções da Segurança do Windows.
# Beside step-install in that card. $minutes is how long installing usually takes, from the Atlas
# package (a number). The first is shown when the PC restarts by itself after installing, as set in
# settings-restart-automatically, and the second when the person restarts it.
home-step-install-restarts =
    { $minutes ->
        [one] A instalação geralmente leva cerca de { $minutes } minuto, e depois seu PC é reiniciado.
       *[other] A instalação geralmente leva cerca de { $minutes } minutos, e depois seu PC é reiniciado.
    }
home-step-install-restart-yourself =
    { $minutes ->
        [one] A instalação geralmente leva cerca de { $minutes } minuto, e depois você reinicia seu PC.
       *[other] A instalação geralmente leva cerca de { $minutes } minutos, e depois você reinicia seu PC.
    }
# At the bottom of that card, under the four steps.
home-steps-save-work = Salve seu trabalho primeiro: os apps podem ser fechados e seu PC será reiniciado.
home-github = Ver o Atlas no GitHub
home-discord = Participar da comunidade do Atlas
home-report-problem = Relatar um problema

## Como uma instalação foi feita (do documento de estado)

# Lower-case forms used inside a history row.
history-mode-fresh = primeira instalação
history-mode-upgrade = atualização
history-mode-reapply = reinstalação
history-mode-unknown = instalação

## Avisos na página inicial

# Each notice's raw error, and the file it concerns, are behind Show details.
notice-settings-reset-title = O Atlas está usando as configurações padrão do app
notice-settings-unreadable-problem = O Atlas não conseguiu ler as configurações salvas do app. Suas configurações do Windows não foram alteradas.
notice-settings-damaged-kept-problem = O arquivo de configurações do app estava danificado, então o Atlas o redefiniu e guardou uma cópia do arquivo antigo.
notice-settings-damaged-problem = O arquivo de configurações do app estava danificado. Por enquanto, o Atlas está usando os padrões.
notice-settings-not-saved-title = Não foi possível salvar as configurações do app
notice-settings-not-saved-problem = O Atlas não conseguiu salvar suas últimas alterações, então elas podem ser perdidas quando você fechar o Atlas. Se houver outra janela do Atlas aberta, feche-a e faça a alteração novamente.
notice-session-unreadable-title = Não foi possível verificar a instalação anterior
# Its button, iso-open-folder, shows the install record in File Explorer.
notice-session-unreadable-problem = O Atlas não conseguiu identificar se uma instalação anterior ainda está em andamento. Se tiver certeza de que nenhuma está, exclua o registro dessa instalação e reabra o Atlas.
# Get ready, when the install record can't be read. $path is a file path (text).
notice-session-unreadable-message = O Atlas não conseguiu identificar se uma instalação anterior ainda está em andamento. Se não tiver certeza, peça ajuda à comunidade do Atlas. Só exclua { $path } e tente novamente se tiver certeza de que nenhuma instalação está em andamento. Detalhes: { $error }

## Elevação para administrador

elevation-declined = A permissão não foi concedida. Tente novamente e escolha Sim quando o Windows perguntar se o Atlas pode fazer alterações no dispositivo.
elevation-declined-continue = A permissão não foi concedida. Tente novamente e escolha Sim quando o Windows perguntar se o Atlas pode fazer alterações no dispositivo. Suas escolhas de configuração foram salvas.
elevation-draft-not-saved = O Atlas não conseguiu salvar suas escolhas de configuração e, por isso, não foi reaberto. Tente novamente. Detalhes: { $error }
# Shown with the home-start-over button.
elevation-taken-over = Outra janela do Atlas está usando esta configuração agora, então o Atlas não foi reaberto. Continue naquela janela ou escolha Começar de novo para refazer a configuração aqui.

## O fluxo de instalação

step-ready = Preparação
step-options = Suas escolhas
step-security = Segurança do Windows
step-install = Instalação
install-title = Configurar o Atlas
# Accessible name of the row of steps.
stepper-label = Etapas da configuração do Atlas
# Accessible name of one step. $heading is step-heading; $status is one of the
# stepper-status-* messages.
stepper-item-a11y = { $heading }, { $status }
stepper-status-completed = concluída
stepper-status-current = etapa atual
stepper-status-upcoming = etapa pendente
# A step already visited whose requirements aren't met yet.
stepper-status-attention = requer atenção
# Names the step showing. Not shown: the stepper marks the step, and its current step reads
# this, or step-heading-*-a11y, when it takes focus.
step-heading = Etapa { $number } de { $total }: { $title }
# Accessible name of the current step on Your choices, read when it takes focus. $heading is
# stepper-item-a11y; $questions is what the screen asks: each question, such as
# screen-defender-question, one after another, then screen-extras-title, or, on the first
# screen of an update or reinstall, update-path-update-title or update-path-reinstall-title.
step-heading-choices-a11y = { $heading }. { $questions }

## Etapa 1: Preparação
## One checklist with three rows: the checks, the Atlas package, and the updates. Each row has a
## title and one status line. Get ready starts updating and moves on by itself.

# Row title. It names what the row does, as a checklist item.
ready-checks-title = Verificar seu PC
# Status line while the checks run.
ready-checks-running = Verificando seu PC…
ready-check-again = Verificar novamente
# Status line once every check passed; common-show-details lists them.
ready-checks-passed =
    { $count ->
        [one] { $count } verificação aprovada
       *[other] { $count } verificações aprovadas
    }
# Status line when some checks need attention, which are listed under it. When updating takes
# care of every one of them, ready-checks-handled follows it, after usb-detail-separator.
ready-checks-passed-some =
    { $total ->
        [one] { $passed } de { $total } verificação aprovada
       *[other] { $passed } de { $total } verificações aprovadas
    }
# After ready-checks-passed-some, when the only checks that didn't pass are ones updating takes
# care of, such as updates waiting: "5 of 9 checks passed · 4 handled by updating". $count is
# how many updating takes care of.
ready-checks-handled = { $count } a cargo da atualização
# Accessible state of a check that updating takes care of, after check-a11y's title.
check-state-updates = a atualização cuida disso
# Under the title of a check that updating takes care of.
check-updates-handled = Há atualizações pendentes. O Atlas as instala ao atualizar o Windows.
check-restart-handled = O Windows precisa reiniciar para concluir alterações anteriores. A atualização cuida disso.
check-handled = A atualização cuida disso.
# Row title: the Atlas version the package holds.
ready-package-title = Atlas { $version }
# Status lines of the package row.
ready-package-downloading = Baixando…
ready-package-unpacking = Extraindo…
ready-package-ready = Pronto
ready-package-checking = Verificando a versão mais recente…
# Tester build: the bundled Atlas package is being unpacked; nothing is downloaded.
ready-package-bundled = Preparando o pacote do Atlas incluído…
ready-package-none = Ainda não baixado
ready-package-failed = Não foi possível obter o pacote do Atlas
# Under ready-package-failed, with package-download-again and package-open-file. The raw error
# is behind common-show-details.
ready-package-failed-detail = Baixe-o novamente ou abra outro pacote do Atlas (.atlaspkg).
# Tester build: the same, with Try again (common-try-again) as the only control.
ready-package-bundled-failed-detail = Não foi possível extrair o pacote do Atlas incluído nesta versão de teste. Tente novamente.
ready-package-manager = Requer um Atlas Manager mais recente
ready-package-release-failed = Não foi possível verificar a versão mais recente
# Under ready-package-release-failed, with package-download-again and package-open-file.
ready-package-release-failed-detail = Confira sua conexão com a internet e tente novamente. Se você tiver um pacote do Atlas (.atlaspkg), pode abri-lo em vez disso.
# Row title.
ready-updates-title = Atualizações do Windows e da Microsoft Store
# Status line before updating starts. Get ready starts it by itself.
ready-updates-pending = Os apps da Store, como o Bloco de Notas, podem ser fechados durante a atualização. Salve seu trabalho neles primeiro.
# Status line while Windows moves to version $release, whose card says how that stands.
ready-updates-after-move = Começa depois que o Windows mudar para a versão { $release }.
# Status line after Atlas's own restart, until updating carries on by itself.
ready-updates-resumed = Continuando após a reinicialização…
ready-updates-restarting = Reiniciando seu PC…
ready-updates-done = O Windows e os apps da Store estão atualizados.
# Instead of ready-updates-done where Microsoft Store is turned off, so only Windows was updated;
# prepare-store-skipped-removed says so under it.
ready-updates-done-windows = O Windows está atualizado.
# The countdown before the restart updating needs, with restart-now and restart-dont-now under
# it. Read when it shows, not every second.
ready-updates-restart-countdown =
    { $seconds ->
        [one] Seu PC será reiniciado em { $seconds } segundo.
       *[other] Seu PC será reiniciado em { $seconds } segundos.
    }
ready-updates-restart = Seu PC precisa ser reiniciado para concluir a atualização.
ready-updates-restart-finish = O Windows precisa de mais uma reinicialização para concluir a instalação da versão { $release }.
ready-updates-restart-failed = Seu PC não foi reiniciado
# Under the restart's status line, before Restart now.
ready-updates-restart-save = Salve seu trabalho primeiro.
ready-updates-restart-persists = O Windows ainda pede uma reinicialização
# Under ready-updates-restart-persists, with Try again and check-fix-windows-update.
ready-updates-restart-persists-advice = Reiniciar de novo provavelmente não vai adiantar. Conclua o que estiver aguardando no Windows Update e tente novamente.
# Behind common-show-details. $reasons lists prepare-reason-* messages.
ready-updates-restart-persists-reasons = Motivos da reinicialização: { $reasons }
ready-updates-network = As atualizações não podem usar esta conexão
ready-updates-stopped = A atualização foi interrompida. Algumas atualizações podem já ter sido instaladas.
ready-updates-previous = Aguardando as atualizações iniciadas anteriormente…
# Button after the user stopped updating.
ready-updates-resume = Retomar atualizações
ready-updates-start = Iniciar atualizações
# Why updating hasn't started, under the row.
ready-updates-blocked = As atualizações aguardam até que o Atlas possa ser instalado neste PC.
ready-updates-needs-admin = Começa quando o Atlas tiver permissão de administrador.
ready-updates-needs-windows = Começa quando a verificação de compatibilidade do Windows for aprovada.
ready-updates-needs-drivers = Começa quando você decidir como os drivers serão instalados.
# The driver choice, one line under the update row. $choice is ready-drivers-automatic or
# ready-drivers-manual. common-change unfolds the two answers.
ready-drivers-row = Drivers: { $choice }
ready-drivers-automatic = Pelo Windows Update
ready-drivers-manual = Por conta própria
ready-drivers-change-a11y = Alterar como os drivers são instalados
# Under the two answers, once updating has run.
ready-drivers-again = Alterar isso executa as atualizações novamente.

# $received and $total are formatted numbers of megabytes (text).
package-downloading = Baixando o Atlas { $version } · { $received } de { $total } MB
package-unpacking = Extraindo
package-status-ready = Pronto
# Accessible name of the progress bar.
package-progress = Progresso do pacote do Atlas
package-download-again = Baixar novamente
package-download-version = Baixar o Atlas { $version }
package-download-newest = Baixar a versão mais recente
package-cancel-download = Cancelar download
package-open-file = Abrir arquivo de pacote
# Where the package came from. $file is a file name (text).
package-from-release = O Atlas { $version } foi baixado do GitHub e está pronto para instalar.
package-from-file = O Atlas { $version } foi carregado de { $file } e está pronto para instalar.
package-unpacked = O Atlas { $version } está pronto para instalar.
package-none-yet = Nenhum pacote do Atlas ainda
acquire-no-asset = O Atlas { $version } não tem um arquivo de pacote para baixar. Abra um pacote do Atlas (.atlaspkg) salvo no PC para continuar.
# Shown for a package older than Atlas 0.6.0, and for a file that isn't an Atlas package, such as an
# .apbx file from an Atlas release before 0.6.
acquire-unsupported = Este app instala o Atlas 0.6.0 ou mais recente a partir de pacotes do Atlas (.atlaspkg).
# Instead of acquire-unsupported for a Windows ISO opened as the Atlas package. Create an Atlas ISO (iso-open) is beside it.
acquire-windows-iso = Este arquivo é uma ISO do Windows, não um pacote do Atlas (.atlaspkg). Para reinstalar o Windows com o Atlas, use-a para criar uma ISO com o Atlas.
# A package new enough to include the installer script that this app drives, but without it.
acquire-incomplete = O Atlas { $version } não inclui alguns arquivos de que este app precisa para instalá-lo. Baixe-o novamente ou abra outro pacote do Atlas (.atlaspkg).
acquire-failed = Não foi possível preparar o pacote do Atlas. Baixe-o novamente ou abra outro pacote do Atlas (.atlaspkg). Detalhes: { $error }
# The download received nothing for a minute and was stopped.
acquire-stalled = O download parou de responder. Confira sua conexão com a internet e baixe novamente ou abra um pacote do Atlas (.atlaspkg) salvo no PC.
# Tester build: the bundled Atlas package couldn't be unpacked. Try again is the only control offered.
acquire-failed-bundled = Não foi possível preparar o pacote do Atlas incluído. Escolha Tentar novamente. Detalhes: { $error }
# The Atlas package asks for a newer Atlas Manager than this one. $version is the version it asks for,
# such as 0.7.0. Download Atlas Manager (manager-download) is beside it. "It" is the Atlas Manager
# downloaded, and "this one" the Atlas Manager running now.
acquire-manager-update-needed = Este pacote do Atlas requer um Atlas Manager mais recente. Baixe o Atlas Manager { $version } ou mais recente e use-o no lugar deste.
# The same, for a package that doesn't say which version it needs.
acquire-manager-update-needed-any = Este pacote do Atlas requer um Atlas Manager mais recente. Baixe o Atlas Manager mais recente e use-o no lugar deste.
# The Atlas package for Atlas $version asks for Atlas Manager $required or later, such as 0.7.0.
# Download Atlas Manager (manager-download) is beside it, on Get ready and on Home.
acquire-manager-update-required = Para instalar o Atlas { $version }, baixe o Atlas Manager { $required } ou mais recente e use-o no lugar deste.
# The same, for a package that doesn't say which Atlas Manager it needs.
acquire-manager-update-required-any = Para instalar o Atlas { $version }, baixe o Atlas Manager mais recente e use-o no lugar deste.

## Atlas Manager mais recente

# Opens the latest Atlas release on GitHub in the browser, where Atlas Manager is downloaded.
manager-download = Baixar o Atlas Manager
# A note on Home and in Settings that a newer Atlas Manager has been released. $version is its
# version, such as 0.7.0. The note doesn't stop anything; manager-download is its button.
manager-update-title = O Atlas Manager { $version } está disponível
manager-update-message = O Atlas Manager não consegue se atualizar sozinho. Baixe a nova versão e use-a no lugar desta.

## Verificações do sistema

check-administrator = Permissão para instalar
check-supported-build = Compatibilidade do Windows
check-pending-updates = Atualizações do Windows
check-pending-reboot = Reinicialização pendente
check-third-party-antivirus = Outro antivírus
check-internet = Conexão com a internet
check-power = Energia
check-activation = Ativação do Windows
# Checks shown only where Atlas moves Windows to a newer version: what the move needs.
check-move-hardware = Hardware do Windows 11
check-move-space = Espaço livre
check-move-update-source = Origem das atualizações
# Accessible name of a check row. $state is one of the check-state-* messages.
check-a11y = { $title }: { $state }
check-state-checking = verificando
check-state-passed = tudo certo
check-state-warning = requer atenção
check-state-failed-blocking = ação necessária antes de instalar
check-state-failed = requer atenção
check-state-unknown = não foi possível verificar
check-fix-windows-update = Abrir o Windows Update
check-fix-network = Abrir configurações de rede
check-fix-power = Abrir configurações de energia
check-fix-activation = Abrir configurações de ativação
# Opens Storage in Windows Settings, where space is freed up.
check-fix-storage = Abrir configurações de armazenamento
# Opens Installed apps in Windows Settings, from the Other antivirus software check. "Installed
# apps" is the page of that name in Windows Settings, as in fixed-installed; use the name Windows
# shows in your language.
check-fix-installed-apps = Abrir Aplicativos instalados
# Check box the user ticks when the Windows Update scan could not run.
check-ack-updates = Verifiquei o Windows Update: não há atualizações aguardando instalação

detail-admin-ok = O Atlas tem permissão para fazer as alterações necessárias à instalação.
detail-admin-missing = Reabra o Atlas como administrador e escolha Sim quando o Windows pedir permissão.
# $builds is a list of build numbers such as "26100 or 26200"; $build is this PC's (text).
detail-build-unsupported = Esta versão do Atlas requer a compilação { $builds } do Windows. Seu PC tem a compilação { $build }. Instale uma versão compatível do Windows antes de continuar.
detail-build-missing = Este pacote do Atlas não indica nenhuma compilação compatível do Windows. Use uma versão completa do pacote em vez de uma versão LocalTest.
detail-updates-none = Não há atualizações do Windows aguardando instalação.
# Updates still waiting once updating has run. $count is how many.
detail-updates-left =
    { $count ->
        [one] { $count } atualização ainda está pendente. Instale-a no Windows Update e verifique novamente.
       *[other] { $count } atualizações ainda estão pendentes. Instale-as no Windows Update e verifique novamente.
    }
detail-updates-scan-failed = Não foi possível verificar se há atualizações do Windows. Abra o Windows Update para ver se há alguma pendente. ({ $error })
detail-reboot-none = O Windows não precisa ser reiniciado agora.
# Once updating has run: a restart it left, or one Windows still wants.
detail-restart-pending = O Windows precisa reiniciar para concluir alterações anteriores. Reinicie seu PC e verifique novamente.
# $reasons: the pending-restart markers Windows set, from the prepare-reason-* names.
detail-restart-pending-reasons = O Windows precisa reiniciar para concluir alterações anteriores ({ $reasons }). Reinicie seu PC e verifique novamente.
# Warning, not a block: $files lists up to three file paths Windows will replace or remove at the next restart.
detail-reboot-file-renames = Você pode continuar. O Windows tem arquivos para substituir ou remover na próxima reinicialização ({ $files }). Alguns apps, como o Xbox Gaming Services, fazem isso após cada reinicialização.
detail-reboot-unknown = Não foi possível verificar se o Windows precisa ser reiniciado. Reinicie o PC, reabra o Atlas e verifique novamente. ({ $error })
detail-antivirus-none = Nenhum outro antivírus foi detectado.
# $products is a list of product names (text). The row offers check-fix-installed-apps.
detail-antivirus-uninstall = Antivírus diferentes do Microsoft Defender podem bloquear a instalação. Desinstale { $products } e verifique novamente.
# Warning, not a block: Security Center still lists the product but its files are gone.
detail-antivirus-stale = A Segurança do Windows ainda lista { $products }, mas os arquivos já não existem, então esse software não está mais instalado. O Atlas pode ser instalado mesmo assim.
detail-antivirus-check-failed = Não foi possível verificar se há outro antivírus. Se isso continuar acontecendo, reinicie seu PC e verifique novamente. ({ $error })
detail-internet-ok = Seu PC está conectado à internet. Mantenha a conexão enquanto o Atlas baixa e instala os programas.
detail-internet-missing = Conecte-se à internet e depois verifique novamente.
detail-power-mains = Seu PC está ligado na tomada. Mantenha-o assim até a instalação terminar.
detail-power-battery = Ligue o PC na tomada para que ele não desligue durante a instalação.
detail-power-check-failed = O Atlas não conseguiu identificar se seu PC está ligado na tomada. Se for um notebook, ligue-o na tomada e verifique novamente.
detail-activation-ok = O Windows está ativado. O Atlas não altera isso.
detail-activation-missing = O Windows não está ativado. Você pode continuar, mas o Atlas não ativará o Windows para você.
detail-activation-no-licence = O Windows não informou uma licença. Você pode continuar; o Atlas não altera o status da ativação.
detail-activation-unknown = Não foi possível verificar a ativação do Windows. Você pode continuar; o Atlas não altera o status da ativação. ({ $error })
# What moving Windows to version $release needs. $missing lists hardware-tpm and hardware-uefi.
detail-move-not-needed = O Atlas não precisa mudar o Windows para uma versão mais recente neste PC.
detail-move-hardware-ready = Este PC tem o TPM 2.0 e o firmware UEFI que o Windows 11 exige.
detail-move-hardware-missing = Este PC não tem { $missing }, então o Windows Update não vai levá-lo para a versão { $release }. Faça backup dos seus arquivos e reinstale o Windows usando uma ISO com o Atlas.
detail-move-hardware-unread = O Atlas não conseguiu ler todo o hardware deste PC, então o Windows Update fará essa verificação.
# $drive is a drive such as C:; $free and $needed are whole gigabytes.
detail-move-space-ok = { $drive } tem { $free } GB livres.
detail-move-space-short = A versão { $release } precisa de { $needed } GB livres em { $drive }, e há { $free } GB. Libere espaço, e o Atlas verificará novamente sozinho.
detail-move-space-unknown = Não foi possível verificar o espaço livre para a atualização do Windows. Reinicie seu PC e verifique novamente. ({ $error })
detail-move-update-source-ok = Este PC recebe atualizações do Windows Update.
detail-move-update-source-managed = Este PC recebe atualizações do servidor da organização, que não oferece a versão { $release }. Fale com sua organização ou reinstale o Windows usando uma ISO com o Atlas.

## Etapa 2: Suas escolhas
## One screen asks every question, a card each, with the optional extras folded under them.

# Once, at the top of Your choices. It names only what the Atlas folder can change back; other
# choices, such as removing Microsoft Edge, can't be undone there.
options-change-later = Depois, você pode alterar o Microsoft Defender, as proteções do processador e as configurações de atualização na pasta Atlas da sua área de trabalho.
# The status line of the folded Optional extras card, then options-extras-show or -hide beside it.
options-extras-none = Nenhum selecionado
# $count is how many of the extras' check boxes are ticked.
options-extras-ticked =
    { $count ->
        [one] { $count } selecionado
       *[other] { $count } selecionados
    }
# Links that unfold and fold the Optional extras card.
options-extras-show = Mostrar
options-extras-hide = Ocultar
# Under each question's title, one sentence at most. What every Defender answer turns off
# is in the Install step's details (summary-turned-off).
question-defender-description = O Microsoft Defender é o antivírus integrado do Windows.
question-mitigations-description = Essas proteções, também chamadas de mitigações de segurança, defendem contra falhas do processador, como Spectre e Meltdown, e contra ataques que exploram erros em apps.
question-auto-updates-description = De qualquer forma, o Atlas mantém o Windows na versão atual e desativa as atualizações automáticas dos apps da Microsoft Store.
question-browser-description = O Atlas não altera as configurações do navegador.
# One line under an answer other than the recommended one: what it costs.
# cost-defender-disable is also the caution under Remove Microsoft Defender on the Install step
# and Home, and the message after an installation that removed Defender.
cost-defender-disable = Seu PC fica sem antivírus até você instalar outro, e o Windows deixa de avisar antes de você abrir apps ou downloads não reconhecidos.
# "Exploit protection" is the Windows Security page of that name; use the name Windows shows in
# your language.
cost-mitigations-disable = Isso também desativa a Proteção contra vulnerabilidades para apps, como a Proteção de fluxo de controle (CFG), o que reduz a segurança.
cost-auto-updates-disable = Abra o Windows Update regularmente para receber as correções de segurança.
cost-auto-updates-default = O Windows pode reiniciar seu PC para concluir a instalação de atualizações.
# Under the taskbar selector answer, which turns off the keyboard shortcuts for switching.
cost-keyboard-shortcuts-off = Alt+Shift e Ctrl+Shift deixam de alternar idiomas ou layouts.
# One line under an optional extra: what ticking it does.
extra-disable-hibernation = Libera espaço em disco, mas a hibernação e a inicialização rápida ficam indisponíveis.
extra-disable-power-saving = Seu PC pode consumir mais energia, esquentar mais e ter menos autonomia de bateria.
extra-disable-core-isolation = Reduz a proteção, e jogos que usam sistemas antitrapaça como Riot Vanguard ou FACEIT podem não abrir até você reativar a integridade da memória.
extra-uninstall-edge = Os favoritos, o histórico e as senhas salvas do Edge neste PC são excluídos, exceto o que estiver sincronizado com sua conta Microsoft.
extra-install-toolbox = Ajuda a gerenciar as configurações do Atlas, mas alguns recursos podem estar incompletos enquanto ele estiver em beta.
extra-install-eclean = Uma ferramenta da equipe do AtlasOS para revisar arquivos desnecessários e apps de inicialização, que requer uma conta e conexão com a internet.
# Short names for each decision (summary rows) and the question each screen asks.
screen-defender-title = Microsoft Defender
screen-defender-question = Manter o Microsoft Defender?
screen-mitigations-title = Proteções do processador
screen-mitigations-question = Manter as proteções do Windows para o processador?
screen-updates-title = Windows Update
screen-updates-question = Como o Windows deve instalar as atualizações?
screen-browser-title = Navegador
screen-power-title = Energia e segurança
screen-apps-title = Aplicativos
screen-optional-apps-title = Aplicativos opcionais
screen-choose-one-title = Escolha uma opção
screen-extras-title = Extras opcionais
# Each decision's short name in the middle of a sentence, as in summary-change-a11y and
# update-path-differs. Write it as the language does mid-sentence: in English, product names
# keep their capitals and other names are lower case.
screen-update-path-name = como o Atlas é atualizado
screen-defender-name = o Microsoft Defender
screen-mitigations-name = as proteções do processador
screen-updates-name = o Windows Update
screen-keyboard-name = os idiomas do teclado
screen-browser-name = o navegador
screen-power-name = as opções de energia e segurança
screen-apps-name = os aplicativos
screen-optional-apps-name = os aplicativos opcionais
# A question with one answer that this app has no name for, such as one a newer Atlas package
# adds. Its title is screen-choose-one-title.
screen-package-choice-name = uma escolha do pacote do Atlas
screen-extras-name = os extras opcionais
# Question for a required choice this app has no specific wording for.
screen-generic-question = Escolha uma opção para { $title }
learn-more-defender = Saiba mais sobre o Microsoft Defender
learn-more-mitigations = Saiba mais sobre as proteções do processador
learn-more-updates = Saiba mais sobre o Windows Update
learn-more-browser = Saiba mais sobre navegadores
learn-more-power = Saiba mais sobre energia e segurança
learn-more-apps = Saiba mais sobre aplicativos
learn-more-eclean = Saiba mais sobre o eclean
learn-more-keyboard = Saiba mais sobre idiomas do teclado
learn-more-generic = Ler o guia de configuração
# One line under the chosen answer: what it means for the PC.
consequence-defender-enable = Mantém o antivírus integrado do Windows para ajudar a proteger seu PC contra vírus e outras ameaças.
consequence-mitigations-default = Mantém as proteções padrão do Windows contra falhas do processador e contra ataques que exploram erros em apps.
# Under Turn off processor protections. "Exploit protection" is the Windows Security page
# of that name; use the name Windows shows in your language.
consequence-mitigations-disable = Também desativa a Proteção contra vulnerabilidades para apps, como a Proteção de fluxo de controle (CFG). Isso reduz a segurança. Qualquer diferença de desempenho depende do seu processador.
consequence-auto-updates-disable = Abra o Windows Update regularmente para instalar as atualizações. As notificações de atualização continuam ativadas.
consequence-auto-updates-default = O Windows instalará as atualizações automaticamente, incluindo correções de segurança.

## Etapa 2 ao atualizar ou reinstalar o Atlas instalado

# The first screen of Your choices when updating the installed Atlas. $version is the Atlas
# version being installed, such as 0.6.1.
update-path-update-title = Como você quer atualizar para o Atlas { $version }?
# The same screen when installing again the Atlas version this PC already has.
update-path-reinstall-title = Como você quer reinstalar o Atlas { $version }?
# The two answers on that screen, each with the detail line under it. Other messages
# name the answers too, so keep each the same everywhere.
update-path-keep = Manter minhas escolhas
update-path-keep-detail = O Atlas mantém cada escolha como está agora neste PC e não altera nenhuma delas.
update-path-choose = Escolher novamente
update-path-choose-detail = Começa a partir da configuração atual deste PC. Seus apps, arquivos e personalizações são mantidos.
# Heading of the list under the two answers: one row per choice, as this PC has it now.
update-path-now-title = Suas escolhas atuais neste PC
# The value of a row in that list for a choice nothing on the PC shows. Keep my choices
# then asks it.
update-path-unknown = O Atlas não consegue identificar isso no seu PC, então pergunta a você
# Above that list. $choices lists the screen-*-name messages, such as "Microsoft Defender and
# processor protections", joined with list-and.
update-path-differs = Este PC não corresponde ao registro do Atlas nestes itens: { $choices }.
# A line above the questions Keep my choices still asks, which are the ones this PC can't show.
keep-choices-asked = O Atlas mantém todas as outras escolhas como estão agora neste PC.
# A short tag, on a line of its own, under the answer this PC has now, on the screens of
# Choose again.
option-now = Atualmente neste PC
# Under an answer on a screen of Choose again, instead of what it usually means, when
# choosing it changes this PC.
change-defender-enable = O Atlas restaura o Microsoft Defender. Depois da reinicialização, ative a proteção dele na Segurança do Windows.
change-mitigations-default = O Atlas reativa as proteções do processador com os padrões do Windows. Isso entra em vigor depois da reinicialização.
# Under Keep processor protections when every protection is turned on: Atlas leaves them
# all on rather than going back to the Windows defaults.
change-mitigations-all-on = Todas as proteções do processador estão ativadas agora. Se você as mantiver, todas continuarão ativadas.
change-auto-updates-default = O Atlas volta a deixar o Windows instalar atualizações automaticamente.
# Under Turn off hibernation, Turn off power saving and Turn off VBS when the box is cleared
# while this PC has them off.
change-hibernation-on = O Atlas reativa a hibernação.
change-power-saving-on = O Atlas reativa a economia de energia e volta ao seu plano de energia anterior, ou ao plano Equilibrado se não houver um.
change-core-isolation-on = O Atlas reativa a segurança baseada em virtualização (VBS), a menos que uma política deste PC a controle. Isso entra em vigor depois da reinicialização.
# Under Remove Snipping Tool when it's ticked while this PC still has the app.
change-remove-snipping-tool = Remove a Ferramenta de Captura para todos neste PC. O Atlas não poderá restaurá-la depois, mas você pode instalá-la novamente pela Microsoft Store.
# Under a box Choose again shows ticked and can't clear, saying why. Install or Remove Edge
# is a file name in the Atlas folder, in English on every PC.
fixed-uninstall-edge = O Microsoft Edge já foi removido, e a atualização do Atlas não pode restaurá-lo. Para instalá-lo novamente, use Install or Remove Edge na pasta Atlas.
# The same for an app Atlas installed. $app is its name, such as Atlas Toolbox or Brave.
# "Installed apps" is the page of that name in Windows Settings.
fixed-installed = { $app } está instalado. O Atlas não desinstala apps; para removê-lo, acesse Aplicativos instalados nas Configurações.
# Under the browser chosen when another browser Atlas offers is already installed.
# $installed and $browser are browser names, such as Brave and Firefox.
browser-also = { $installed } continua instalado, e o Atlas também instala { $browser }.

## Texto do pacote do Atlas
## Labels and descriptions for the Atlas package's options and choices, by
## their ids in the package's atlas.json. The app shows these in place of the
## package's own English text; an option or choice that a newer package adds,
## which has no message here, shows the package's English.
## An option whose label recommends it has a -short form too: the same answer
## without the recommendation, for the Install step's summary, Home and the
## records, where the choice is already made.

package-option-defender-enable = Manter o Microsoft Defender (recomendado)
package-option-defender-enable-short = Manter o Microsoft Defender
package-option-defender-disable = Remover o Microsoft Defender
package-option-mitigations-default = Manter as proteções do processador (recomendado)
package-option-mitigations-default-short = Manter as proteções do processador
package-option-mitigations-disable = Desativar as proteções do processador
package-option-auto-updates-disable = Instalar atualizações manualmente
package-option-auto-updates-default = Instalar atualizações automaticamente
package-option-disable-hibernation = Desativar a hibernação
package-option-disable-power-saving = Desativar a economia de energia
package-option-disable-core-isolation = Desativar a segurança baseada em virtualização (VBS)
# "Ferramenta de Captura" is the Windows pt-BR name of Snipping Tool.
package-option-remove-snipping-tool = Remover a Ferramenta de Captura
package-option-uninstall-edge = Remover o Microsoft Edge
package-option-install-another-browser = Instalar um navegador
package-option-install-toolbox = Instalar o Atlas Toolbox
package-option-install-eclean = Instalar o eclean
package-option-browser-brave = Brave
package-option-browser-librewolf = LibreWolf
package-option-browser-firefox = Firefox
package-option-browser-chrome = Chrome
package-choice-defender-description = O Microsoft Defender é o antivírus integrado do Windows. Remova-o apenas se você entender os riscos e pretender usar outro app antivírus. Seja qual for sua escolha, o Atlas desativa o Controle Inteligente de Aplicativos, a Proteção aprimorada contra phishing e o recurso Localizar meu dispositivo.
package-choice-mitigations-description = Essas proteções, também chamadas de mitigações de segurança, ajudam a defender o PC contra falhas do processador, como Spectre e Meltdown, e contra ataques que exploram erros em apps. É recomendável manter os padrões do Windows.
package-choice-auto-updates-description = As atualizações do Windows incluem correções de segurança. Você pode deixar que o Windows as instale automaticamente ou instalá-las por conta própria. Em ambos os casos, o Atlas mantém o Windows na versão atual, que só recebe correções de segurança até a Microsoft encerrar o suporte a ela. O Atlas também desativa as atualizações automáticas dos apps da Microsoft Store, então atualize-os pela Microsoft Store.
package-choice-browser-description = Escolha um navegador para instalar. O Atlas não altera as configurações do navegador.

## Etapa 3: Segurança do Windows

# Shown instead of the switch list when Microsoft Defender isn't on this PC and the user
# chose to remove it.
security-banner-absent-title = O Microsoft Defender não está instalado neste PC
# The message under security-banner-absent-title and security-banner-removed-title.
security-nothing-to-turn-off = Não há proteções para desativar.
# Instead of security-banner-absent-title when Atlas's own package removed Microsoft Defender
# and it stays removed. Its message is security-nothing-to-turn-off.
security-banner-removed-title = O Atlas removeu o Microsoft Defender deste PC
# When Atlas's own package removed Microsoft Defender and this installation brings it back.
security-banner-restore-title = O Atlas restaura o Microsoft Defender nesta instalação
security-restore-nothing-to-turn-off = O Defender ainda não está em execução, então não há nada para desativar. Depois da reinicialização, ative a proteção dele na Segurança do Windows.
# A warning that doesn't stop the step: the user chose to keep Microsoft Defender, but it
# isn't on this PC and Atlas didn't remove it. Home and the "Atlas is installed" window use
# the same title.
security-banner-missing-title = O Microsoft Defender não foi encontrado
security-banner-missing-message = O Atlas não o removeu, então não pode restaurá-lo. Você pode continuar, mas seu PC ficará sem antivírus até você instalar outro app antivírus ou reparar o Windows.
# While a switch is on, or none can be read. Atlas has opened Windows Security at the switches,
# and Open Windows Security, its button, opens it again.
security-turn-off-title = Desative estas quatro proteções
security-turn-off-message = O Microsoft Defender pode bloquear o Atlas durante a instalação. Se você mantiver o Defender, reative-as depois de instalar.
# The page name in Windows Security.
security-list-title = Configurações de proteção contra vírus e ameaças
security-switch-off = Desativado
security-switch-on = Ativado
security-switch-unreadable = Não foi possível ler
security-switch-reading = Verificando
security-all-off = Todas desativadas
# Accessible name of a switch row. $state is one of the security-switch-* messages.
security-a11y = { $title }: { $state }
# Parts of the summary "2 still on, 1 couldn't be read".
security-count-still-on =
    { $count ->
        [one] { $count } ainda ativada
       *[other] { $count } ainda ativadas
    }
security-count-unreadable =
    { $count ->
        [one] { $count } não pôde ser lida
       *[other] { $count } não puderam ser lidas
    }
security-count-join = { $a } e { $b }
# Every switch Atlas could read is off, and the rest couldn't be read. $switches names those,
# as Windows Security names them, joined with list-and; $count is how many there are. English
# reads the same for one or several; agree with $count where your language needs to.
security-unread-switches-title =
    { $count ->
        [one] O Atlas não conseguiu ler esta proteção: { $switches }
       *[other] O Atlas não conseguiu ler estas proteções: { $switches }
    }
security-unread-message =
    { $count ->
        [one] Confira na Segurança do Windows se essa proteção está desativada.
       *[other] Confira na Segurança do Windows se essas proteções estão desativadas.
    }
# The check box under security-unread-message.
security-unread-confirm =
    { $count ->
        [one] Verifiquei que esta proteção está desativada: { $switches }
       *[other] Verifiquei que estas proteções estão desativadas: { $switches }
    }
# The check box when Atlas couldn't read any of the four switches.
security-acknowledge = Verifiquei na Segurança do Windows que as quatro proteções estão desativadas
security-unknown-unelevated-title = O Atlas precisa de permissão para verificar a proteção
security-unknown-unelevated-message = Reabra o Atlas como administrador para que ele consiga ler as configurações do Microsoft Defender.
# The four switches, named as Windows Security names them, each with why it must be off.
protection-tamper = Proteção contra violações
protection-tamper-why = Para que o Atlas possa alterar as configurações de segurança.
protection-realtime = Proteção em tempo real
protection-realtime-reason = As verificações podem bloquear os arquivos do Atlas.
protection-cloud = Proteção fornecida pela nuvem
protection-cloud-reason = As verificações online podem bloquear os arquivos do Atlas.
protection-samples = Envio automático de amostra
protection-samples-why = Para que os arquivos do Atlas não sejam enviados à Microsoft.

## Etapa 4: Instalação

outcome-succeeded-title = O Atlas foi instalado
outcome-lost-title = Não foi possível confirmar o resultado da instalação
outcome-failed-title = A instalação não foi concluída
# The result bar's message after an attempt that didn't succeed: what happened, then what to do,
# in two sentences at most. The bar's button, or the footer's Try again, is the next step, so the
# message never names it. The installer's own error is behind Show details.
# Beside go-to-ready.
result-requirements = Seu PC não atendeu aos requisitos de instalação, então a instalação não alterou nada.
# The -resumed variants follow a retry of an installation an earlier attempt had already started applying.
result-requirements-resumed = Seu PC não atendeu aos requisitos de instalação, então esta tentativa parou. Uma tentativa anterior já fez alterações.
# Beside common-restart-as-administrator.
result-not-elevated = O Atlas não tinha permissão de administrador, então a instalação não alterou nada.
result-not-elevated-resumed = O Atlas não tinha permissão de administrador, então esta tentativa parou. Uma tentativa anterior já fez alterações.
# The installer's live check found Windows or Store updates unfinished. Beside go-to-ready, where
# updating starts again by itself.
result-preparation-stale = O Atlas não conseguiu confirmar se o Windows e os apps da Store estão atualizados, então a instalação parou antes de alterar o Windows.
result-preparation-stale-resumed = O Atlas não conseguiu confirmar se o Windows e os apps da Store estão atualizados, então esta tentativa parou. Uma tentativa anterior já fez alterações.
result-failed-preflight = A instalação parou antes de alterar qualquer coisa. Você pode tentar novamente.
result-failed-staging = A instalação parou durante a preparação dos arquivos, antes de alterar o Windows. Você pode tentar novamente.
# Beside common-open-windows-security. The "protection switches" are the four the user turned off.
result-failed-applying = Algumas alterações podem já ter sido feitas. Você pode tentar novamente ou, se parar por aqui, reativar as proteções na Segurança do Windows.
# The -defender-removed variants once Microsoft Defender has been removed, so there are no
# protection switches to turn back on.
result-failed-applying-defender-removed = Algumas alterações podem já ter sido feitas. Você pode tentar novamente.
result-failed-resumed = Esta tentativa parou no início, mas uma tentativa anterior já fez alterações. Você pode tentar novamente ou, se parar por aqui, reativar as proteções na Segurança do Windows.
result-failed-resumed-defender-removed = Esta tentativa parou no início, mas uma tentativa anterior já fez alterações. Você pode tentar novamente.
# The -repeated variants follow a retry of an installation already part-way through that stopped
# with the same error as the attempt before it, so they point to a report rather than another try.
# "Send a report" is report-title, in the row of links under the bar.
result-failed-repeated = Esta tentativa parou com o mesmo erro da anterior, então tentar novamente provavelmente não vai adiantar. Envie um relato para que a equipe do Atlas encontre a causa e, se parar por aqui, reative suas proteções.
result-failed-repeated-defender-removed = Esta tentativa parou com o mesmo erro da anterior, então tentar novamente provavelmente não vai adiantar. Envie um relato para que a equipe do Atlas encontre a causa.
# $apps holds the package names Windows gives the apps, such as MSTeams (text), joined with list-and.
result-failed-repeated-apps = O Windows continua sem remover { $apps }, então tentar novamente provavelmente não vai adiantar. Envie um relato para que a equipe do Atlas encontre a causa e, se parar por aqui, reative suas proteções.
result-failed-repeated-apps-defender-removed = O Windows continua sem remover { $apps }, então tentar novamente provavelmente não vai adiantar. Envie um relato para que a equipe do Atlas encontre a causa.
result-not-started = O instalador não foi iniciado a tempo, então a instalação não alterou nada. Você pode tentar novamente.
result-lost = O instalador parou sem informar um resultado, então algumas alterações podem ter sido feitas. Você pode tentar novamente ou, se parar por aqui, reativar as proteções na Segurança do Windows.
# Instead of result-lost once Defender is gone, as for the -defender-removed variants above.
result-lost-defender-removed = O instalador parou sem informar um resultado, então algumas alterações podem ter sido feitas. Você pode tentar novamente.
restart-now-message = O Windows está reiniciando para concluir a configuração do Atlas.
restart-stopped = Reinicialização automática cancelada. Salve seu trabalho e depois reinicie o PC para concluir a configuração do Atlas.
restart-needed = Salve seu trabalho e depois reinicie o PC para concluir a configuração do Atlas.
restart-dont-now = Reiniciar depois
restart-now = Reiniciar agora
# The bar when the final checks refuse to start the installer. Its message names what needs
# attention; the bar's button is the fix, and raw errors are behind Show details.
preflight-title = A instalação não começou
# Beside go-to-options. $choice is a screen-*-name message, as it reads mid-sentence, such as
# processor protections.
preflight-choice-unanswered = O Atlas precisa da sua resposta sobre { $choice }.
preflight-choices-unusable = O Atlas não conseguiu usar essas escolhas.
# Beside go-to-ready. $checks lists check-* names, such as "Internet connection and Power supply",
# joined with list-and; $count is how many it names.
preflight-checks-changed =
    { $count ->
        [one] { $checks } passou a exigir atenção depois que o Atlas verificou seu PC.
       *[other] { $checks } passaram a exigir atenção depois que o Atlas verificou seu PC.
    }
# Beside common-open-windows-security. $summary is the Windows Security summary such as "1 still on".
preflight-security-changed = A Segurança do Windows mudou depois que você desativou as proteções: { $summary }.
preflight-busy-wait = Outra janela do Atlas está iniciando uma instalação. Aguarde um momento e tente novamente.
# Beside home-start-over.
preflight-taken-over-start-over = Outra janela do Atlas está usando esta configuração agora. Continue nela ou comece de novo aqui.
# Beside go-to-ready.
preflight-record-unreadable-check = O Atlas não conseguiu verificar se uma instalação anterior ainda está em andamento, então não iniciou outra.
preflight-not-started = O Atlas não conseguiu iniciar o instalador, então a instalação não alterou nada. Você pode tentar novamente.
# Instead of preflight-not-started when retrying an installation an earlier attempt had already
# started applying.
preflight-not-started-resumed = O Atlas não conseguiu iniciar o instalador, mas uma tentativa anterior já fez alterações. Você pode tentar novamente.
go-to-ready = Ir para a etapa Preparação
# Button on the Install step's bar when a question has no answer; opens Your choices there.
go-to-options = Ir para a etapa Suas escolhas
# Button on the Install step's bar when switches Atlas can't read need confirming on that step.
go-to-security = Ir para a etapa Segurança do Windows
# Replaces Continue on a choice opened from a Change link on the Install step, while Continue leads straight back there.
go-to-install = Voltar à etapa Instalação
output-problem-title = Não foi possível ler o progresso da instalação
install-elevate-title = O Atlas precisa de permissão para instalar
# Under install-elevate-title, beside common-restart-as-administrator.
install-elevate-uac = Quando o Atlas for reaberto, o Windows pedirá sua permissão.
# A bar on the Install step, beside go-to-ready, when no Atlas package is ready.
install-package-missing = O pacote do Atlas não está pronto
# Step 4 when step 1 is incomplete for this session (checks or Windows updates), with go-to-ready as the button.
install-not-ready-title = Conclua a etapa Preparação primeiro
install-not-ready-message = O Atlas precisa terminar de verificar seu PC e atualizar o Windows antes de instalar.
# A bar on the Install step when a fresh reading of the protection switches no longer passes.
# $summary is the Windows Security summary such as "1 still on".
install-switches-title = Desative as proteções novamente
install-switches-message = Segurança do Windows: { $summary }.
# The Install step's card, when nothing stands in the way of installing, and otherwise.
summary-ready-title = Pronto para instalar
summary-setup-title = Sua configuração do Atlas
summary-activation = Ativação
summary-activation-ok = Ativado. O Atlas não altera isso.
summary-activation-missing = Não ativado. Você pode continuar, mas o Atlas não ativará o Windows.
summary-activation-unknown = O Atlas não altera o status de ativação do Windows.
# How long installing usually takes, from the Atlas package. The card shows the first while the
# box below it is ticked, and the second while it isn't.
summary-time-restarts =
    { $minutes ->
        [one] Geralmente cerca de { $minutes } minuto, depois seu PC é reiniciado
       *[other] Geralmente cerca de { $minutes } minutos, depois seu PC é reiniciado
    }
summary-time-restart-yourself =
    { $minutes ->
        [one] Geralmente cerca de { $minutes } minuto, depois reinicie seu PC
       *[other] Geralmente cerca de { $minutes } minutos, depois reinicie seu PC
    }
# The check box on the card. It's the same setting as settings-restart-label.
summary-restart-automatically = Reiniciar automaticamente quando a instalação terminar
# A row of the card's details: what Atlas turns off whichever Microsoft Defender answer is chosen.
summary-turned-off = Também desativados
summary-turned-off-value = Controle Inteligente de Aplicativos, Proteção aprimorada contra phishing e Localizar meu dispositivo
summary-show-command = Mostrar comando de instalação
summary-hide-command = Ocultar comando de instalação
# Accessible name of the Copy button under the installation command.
summary-copy-command-a11y = Copiar comando de instalação
summary-command-unavailable = Não foi possível preparar o comando de instalação. Detalhes: { $error }
summary-not-chosen = Nenhuma escolha feita ainda
# Accessible name of a Change link. $title is a screen-*-name message, as it reads mid-sentence.
summary-change-a11y = Alterar { $title }
# The summary's first row on an update or reinstall. Its value is update-path-keep or
# update-path-choose.
summary-update-path = Como o Atlas é atualizado
# Why Continue waits on Get ready: read with it as its description, and shown beside it
# where the page doesn't already say so. 8 words or fewer.
footer-still-checking = Preparando a instalação
footer-checks-blocked = Resolva o que as verificações encontraram para continuar
footer-manager-outdated = Baixe um Atlas Manager mais recente para continuar
footer-need-files = Obtenha o pacote do Atlas para continuar
# Tester build variant of footer-need-files.
footer-need-package-bundled = Prepare o pacote do Atlas incluído para continuar
footer-drivers = Decida como os drivers serão instalados para continuar
footer-windows-terms = Aceite os termos de licença para continuar
footer-updating = Atualizando o Windows e os apps da Store…
footer-restart = Reinicie seu PC para continuar
footer-reading-security = Verificando as proteções
# Why Continue waits on Windows Security, read with it as its description: while a switch is
# on, then while only switches Atlas couldn't read are left to confirm.
footer-security-pending = Desative as quatro proteções para continuar
footer-security-confirm = Para continuar, confirme as proteções que o Atlas não conseguiu ler
# Beside Install Atlas while automatic restart is on: the PC restarts when installation finishes.
footer-install-ready = Salve seu trabalho e feche seus apps primeiro
button-install = Instalar o Atlas
log-earlier-lines =
    { $count ->
        [one] { $count } linha anterior está no arquivo de log.
       *[other] { $count } linhas anteriores estão no arquivo de log.
    }
# Appended when the log is copied. $path is a file path (text).
log-full-log-note = (log completo: { $path })

## A tela de instalação em andamento

installing-title = Instalando o Atlas
# What Atlas is doing, under installing-title and as the progress bar's accessible name: a
# short verb phrase ending in an ellipsis. The final checks and the installer's own first
# checks both read installing-checking-label.
installing-checking-label = Verificando seu PC…
installing-staging-label = Copiando os arquivos do Atlas…
installing-applying-label = Configurando o Windows…
installing-finishing-label = Concluindo…
# The one line under the progress bar: when the PC restarts by itself after, and when it doesn't.
installing-keep-on-restart = Mantenha seu PC ligado e na tomada. Ele será reiniciado sozinho quando a instalação terminar.
installing-keep-on = Mantenha seu PC ligado e na tomada. Reinicie-o quando a instalação terminar.
# When Atlas can't follow the installer's log. Its title is output-problem-title; "Open log
# folder" is common-open-log-folder, its button.
installing-output-problem = Isso não significa que a instalação parou.
installing-installed-title = O Atlas foi instalado
# Under installing-installed-title while the restart counts down, with installing-restart-save
# under it, then restart-now and restart-dont-now.
installing-restart-countdown =
    { $seconds ->
        [one] Seu PC será reiniciado em { $seconds } segundo.
       *[other] Seu PC será reiniciado em { $seconds } segundos.
    }
installing-restart-save = Salve seu trabalho primeiro.

## A janela "O Atlas foi instalado" após a reinicialização

installed-title-version = O Atlas { $version } foi instalado
installed-title = O Atlas foi instalado
installed-ready = Tudo certo. Seu PC já está pronto para usar com o Atlas.
# A line under the setup card where the user installs drivers themselves, with
# installed-drivers-guide, a link, under it.
installed-manual-drivers-detail = Obtenha os drivers de chipset, rede e vídeo com o fabricante do seu PC, da placa-mãe ou do dispositivo.
installed-drivers-guide = Abrir o guia de drivers
# After an installation that removed Microsoft Defender. Its message is cost-defender-disable.
installed-defender-removed-title = O Microsoft Defender foi removido
# Home and the "Atlas is installed" window, after an installation that kept Microsoft Defender,
# when it is missing and no Atlas package removed it. Its title is security-banner-missing-title;
# its button is report-title.
defender-missing-message = O Atlas não o removeu. Se você não usa outro app antivírus, instale um para proteger seu PC.
# Home and the "Atlas is installed" window, when Atlas's record kept Microsoft Defender but
# Atlas's own package still removes it. Its button is home-reinstall. 7. Security, Defender and
# Toggle Defender are folder and file names in the Atlas folder, in English on every PC.
installed-defender-not-restored-title = O Microsoft Defender continua removido
defender-not-restored-message = Uma atualização anterior do Atlas não o restaurou, então o Defender não está protegendo seu PC. Reinstale o Atlas e mantenha o Defender ou execute Toggle Defender em 7. Security > Defender, na pasta Atlas.
# The "Atlas is installed" window, when what the installation recorded for some choices isn't
# what was chosen. The help links (Send a report, Export diagnostics, Open log folder) follow.
installed-not-applied-title = Algumas escolhas não foram aplicadas
# $choices lists their names as they read mid-sentence (screen-*-name), such as "Microsoft
# Defender and processor protections", joined with list-and; $count is how many it names.
installed-not-applied-choices =
    { $count ->
        [one] Esta escolha ficou como estava: { $choices }.
       *[other] Estas escolhas ficaram como estavam: { $choices }.
    }
# After an update whose last step turned Windows Update off, or paused it, again, as the
# user's own Atlas choices ask.
installed-update-off-title = O Windows Update está desativado de novo, como você escolheu
installed-update-off-message = Enquanto ele estiver desativado, seu PC não recebe atualizações de segurança.
installed-update-paused-title = As atualizações do Windows estão pausadas de novo, como você escolheu
installed-update-paused-message = Enquanto elas estiverem pausadas, seu PC não recebe atualizações de segurança.

## Configurações

settings-title = Configurações
# Headings of the page's sections, over their cards. settings-language and settings-help
# head sections too.
settings-appearance = Aparência
settings-installation = Instalação
settings-privacy = Privacidade
settings-theme = Tema do app
settings-theme-system = Igual ao Windows
settings-theme-light = Claro
settings-theme-dark = Escuro
settings-theme-contrast-note = O Atlas está usando as cores do tema de contraste do Windows.
settings-language = Idioma
# The setting in the Language section, and its box's name.
settings-app-language = Idioma do app
# The first choice in the language box: following Windows, then the language that gives.
# $language is that language's own name, for example "English (United Kingdom)".
settings-language-match-windows = Igual ao Windows – { $language }

# A short tag after each language in the list that is translated but not yet reviewed
# by a native speaker.
settings-language-preview-tag = Versão prévia
# Under the language box while the language in use is a preview translation, once its
# notice (preview-notice) has been dismissed.
settings-language-preview-in-use = Esta tradução ainda não foi revisada por um falante nativo.
# A bar at the top of the content while a preview translation is in use, until the user
# dismisses it (common-dismiss names its close button). $language is the language's own
# name; preview-notice-switch and preview-notice-language are its links.
preview-notice = { $language } é uma tradução em versão prévia e pode conter erros.
preview-notice-switch = Mudar para inglês
preview-notice-language = Alterar idioma
# Under the language box when the language chosen isn't in this version, and the box
# shows English, which is in use.
settings-language-chosen-unavailable = O idioma que você escolheu não está nesta versão do Atlas, então o Atlas é exibido em inglês. Sua escolha foi mantida.
# Under the language box while Match Windows is chosen and Atlas has none of the Windows
# display languages.
settings-language-windows-unsupported = O Atlas ainda não oferece suporte ao idioma de exibição do Windows, então é exibido em inglês.
# Under the language box while Match Windows is chosen and the Windows display languages
# couldn't be read.
settings-language-windows-unreadable = O Atlas não conseguiu verificar o idioma de exibição do Windows, então é exibido em inglês.
# Under the language box when the regional format is of another language or region than
# the app. $locale is the regional format's own name, for example "English (United States)".
settings-language-formats = Números, datas e horas seguem o formato regional do Windows: { $locale }.
# Instead of settings-language-formats when the regional format writes dates or times
# right to left. $locale is the format's English name, for example "Arabic (Saudi Arabia)".
settings-language-formats-numbers-only = Os números seguem o formato regional do Windows: { $locale }. Datas e horas usam um formato padrão porque o Atlas ainda não consegue exibir texto da direita para a esquerda.
settings-language-contribute = Ajudar a traduzir o Atlas
# The usage analytics switch, with its description and a link to the privacy policy.
settings-share-usage = Compartilhar dados de uso com o Atlas
settings-share-usage-description = Páginas que você abre, criação de ISOs e o resultado das instalações.
settings-privacy-policy = Política de privacidade
# The switch covers the restart after installing and the restart that Windows and Store
# updates need before installing.
settings-restart-automatically = Reiniciar automaticamente após instalar e atualizar
settings-restart-automatically-description = Seu PC é reiniciado até um minuto depois que o Atlas termina, o que fecha os apps abertos.
settings-restart-locked = Você poderá alterar isso quando a instalação terminar.
# Heading over Send a report, Export diagnostics and settings-open-data-folder.
settings-help = Ajuda
settings-about = Sobre
settings-about-app = Atlas Manager
settings-about-licence = Licença
settings-about-licence-value = GPL-3.0, gratuito e de código aberto
settings-view-source = Ver código-fonte
# Link that opens the third-party licence notices.
settings-view-licences = Ver avisos de licença
# Under the links when Windows could not open the notices.
settings-licences-failed = Não foi possível abrir os avisos de licença. Tente novamente ou encontre-os no código-fonte, no GitHub.
settings-open-data-folder = Abrir pasta do app

## Optional choices: explanations shown before selection.

consequence-disable-hibernation = Libera o espaço em disco usado para salvar a sessão durante a hibernação. A hibernação e a inicialização rápida ficarão indisponíveis.
consequence-disable-power-saving = Desativa os recursos de economia de energia. O PC pode consumir mais energia, esquentar mais e ter menos autonomia de bateria.
consequence-disable-core-isolation = Desativa uma camada extra de segurança do Windows, incluindo a integridade da memória. Isso reduz a proteção, e jogos que usam sistemas antitrapaça como Riot Vanguard ou FACEIT podem não abrir até você reativar a integridade da memória.
consequence-remove-snipping-tool = Remove o app do Windows para capturas e gravações de tela.
consequence-uninstall-edge = Remove o navegador Microsoft Edge. Tenha outro navegador instalado ou escolha um abaixo.
# Under Remove Microsoft Edge in the Install step's summary, with a caution glyph.
caution-uninstall-edge = Exclui os favoritos, o histórico e as senhas salvas do Edge neste PC.
consequence-install-another-browser = Escolha um navegador abaixo e o Atlas o instalará para você.
consequence-install-toolbox = Adicione o Atlas Toolbox para ajudar a gerenciar as configurações do Atlas. O Toolbox está em beta, então alguns recursos podem estar incompletos.
consequence-install-eclean = Uma ferramenta de manutenção da equipe do AtlasOS para manter seu PC organizado após a configuração. Revise arquivos desnecessários e aplicativos de inicialização. Requer uma conta e conexão com a internet.

## ISO creation
iso-open = Criar uma ISO com o Atlas
iso-title = Criar uma ISO com o Atlas
iso-recommended = Recomendado
# Titles of the three ISO steps in the stepper: where Windows comes from, how it's set
# up, and the review that creates the ISO.
iso-step-source = Windows
iso-step-setup = Configuração
iso-step-create = Criação
# The first question on the Windows step. It sets the defaults that follow: the
# architecture, language, edition and account name, and this PC's network drivers.
iso-target-title = Para qual PC é esta ISO?
iso-target-this = Este PC
iso-target-another = Outro PC
# Under the question when the ISO is for another kind of processor than this PC's, so only
# Another PC applies. $architecture is iso-architecture-x64 or iso-architecture-arm64.
iso-target-arch = Esta ISO é para PCs { $architecture }.
iso-source = ISO do Windows
# Starts the Windows 11 download at once, in the language and architecture of the caption
# under it (iso-download-caption). Also in the Windows ISO's Change menu and on the bar of
# an ISO Atlas can't use.
iso-download-windows = Baixar da Microsoft
# What the download gets. $language is Microsoft's own name for the language, in English,
# such as "English International"; $architecture is iso-architecture-x64 or -arm64.
iso-download-caption = Windows 11 · { $language } · { $architecture }
# The same while Microsoft's list of languages loads.
iso-download-caption-loading = Windows 11 · { $architecture }
# Names the download's language and architecture for the accessible name of its Change link.
iso-download-what = Download do Windows
iso-download-language = Idioma
iso-download-arch = Arquitetura
iso-download-languages = Carregando idiomas…
# The progress bar's label while Windows downloads, then how much has arrived. $received and
# $total are sizes such as "2.4 GB" (size-gigabytes).
iso-downloading = Baixando o Windows 11…
iso-download-amount = { $received } de { $total }
# The download couldn't start because Microsoft's download service couldn't be reached
# through Atlas, or it stopped part-way. Try again (common-try-again) is beside it.
iso-download-unreachable = O Atlas não conseguiu acessar o serviço de download da Microsoft. Confira sua conexão com a internet e tente novamente.
iso-download-incomplete = O download não foi concluído. Confira sua conexão com a internet e o espaço livre. Depois, tente novamente.
iso-download-website = Abrir a página de download da Microsoft
# Opens the file picker for a Windows ISO, and is that picker's Open button. On the ISO and
# USB pages, and on the bar of an ISO Atlas can't use.
iso-use-local = Escolher um arquivo ISO
# A status pill while the files are checked, before Continue becomes available.
iso-checking = Verificando sua ISO do Windows…
# Accessible name of the Ready pill once the check passed. $facts is the ISO's architecture
# and size, such as "x64 · 6.6 GB".
iso-checked-a11y = ISO do Windows pronta, { $facts }
iso-package-latest-label = Mais recente
# The latest Atlas release is older than this Atlas Manager can use; Open package file
# (package-open-file) is under it.
iso-package-release-old = A versão mais recente do Atlas é mais antiga do que este Atlas Manager consegue usar.
# While Atlas finds and downloads the latest Atlas package by itself.
iso-package-fetching = Obtendo o Atlas mais recente…
# The release check failed, so the latest package couldn't be found; Try again is beside it.
iso-package-release-failed = O Atlas não conseguiu verificar a versão mais recente. Confira sua conexão com a internet e tente novamente.
# Accessible name of the Change button beside a file: $action is that button's text and
# $field the file's label.
iso-pick-a11y = { $action }: { $field }
# Beside the unavailable Continue on the Windows step while there's no Windows ISO yet.
iso-need-windows = Obtenha uma ISO do Windows para continuar
# The question on the Setup step about when the package's choices are made.
iso-mode-question = Quando você quer fazer suas escolhas do Atlas?
iso-mode-after = Depois de entrar
iso-mode-after-description = O Atlas orienta você na configuração depois que você entrar na sua conta.
iso-mode-now = Agora
iso-mode-now-description = Salvas na ISO. Você instala o Atlas depois de entrar na sua conta.
# A check box under Now, whose description already says the choices are saved in the ISO.
iso-mode-before-desktop = Concluir antes de a área de trabalho abrir
iso-mode-before-desktop-description = Depois que você entrar, o Atlas é executado em tela cheia até ser instalado.
# In place of the question when the Atlas package can't save choices in an ISO.
iso-mode-unavailable = Este pacote do Atlas não pode salvar escolhas na ISO, então você as faz depois de entrar.
iso-atlas-options = Escolhas do Atlas
# The line at the top of the Create step.
iso-create-intro = Criar a ISO não altera este PC nem sua ISO original.
iso-review-package = Pacote do Atlas
iso-review-output = Nova ISO
iso-review-edition = Edição
iso-review-editions = Edições
iso-edition = Edição do Windows
# The edition shown on the Setup step's edition card when Windows Setup asks which edition to
# install.
iso-edition-auto = A Instalação do Windows pergunta
# The first item of that card's edition menu, above the ISO's own editions: the choice that lets
# Windows Setup ask which edition to install.
iso-edition-auto-menu = Escolher na Instalação do Windows
# An optional check box: accepting the terms here stops Windows Setup from asking.
iso-accept-terms-optional = Aceitar os termos de licença do Windows, para que a Instalação do Windows não pergunte
iso-architecture-x64 = x64
iso-architecture-arm64 = Arm64
# A file size; $size is a formatted number (text). Megabytes below a gigabyte.
size-megabytes = { $size } MB
size-gigabytes = { $size } GB
iso-review-account = Nome da conta
iso-review-target = Instalar em
iso-review-drivers = Drivers
# A review row about the Windows Setup screens the ISO's answer file skips.
iso-review-setup-screens = Instalação do Windows
iso-review-skips = Pula as telas de conta Microsoft e privacidade
iso-review-skips-terms = Pula as telas de licença, conta Microsoft e privacidade
iso-review-network = Drivers de rede
iso-review-network-included = Drivers de Wi-Fi e Ethernet deste PC
# The Atlas choices row when they're saved in the ISO and finish before the desktop opens.
iso-review-mode-before-desktop = Agora, concluídas antes de a área de trabalho abrir
# Under the new ISO on the Create step. $needed and $free are sizes such as "35.0 GB"
# (size-gigabytes); $drive is a drive such as "C:".
iso-destination-space = Requer { $needed } · { $free } livres em { $drive }
iso-destination-short = A ISO precisa de { $needed }, e { $drive } tem { $free } livres. Libere espaço ou salve a ISO em outra unidade.
iso-destination-filesystem = { $drive } não comporta os arquivos grandes da ISO. Salve-a em uma unidade formatada em NTFS, como a unidade do Windows.
iso-destination-unusable = O Atlas só pode salvar a ISO em uma pasta de uma unidade deste PC.
# Copying the ISO's files would pass Windows' limit of 260 characters for a path, even at the
# root of the drive the new ISO is saved to. Under iso-failed.
iso-path-too-long = Os arquivos da ISO precisariam de caminhos mais longos do que o Windows permite na pasta de destino. Salve a nova ISO em uma pasta com um caminho mais curto, como uma na unidade do Windows.
iso-create = Criar ISO
# Heading above the progress bar and the list of stages (iso-stage-*) while the ISO is
# being created.
iso-progress-title = Criando sua ISO…
# The progress bar's label: the stage under way, as a verb phrase ending in an ellipsis.
# $stage is one of the iso-stage-* messages.
iso-progress-stage = { $stage }…
iso-stage-read = Lendo a ISO do Windows
iso-stage-copy = Copiando arquivos do Windows
iso-stage-add-atlas = Adicionando o Atlas
iso-stage-master = Gravando o arquivo ISO
iso-stage-verify = Verificando a nova ISO
iso-stage-cleanup = Finalizando
# Accessible name of one stage while the ISO is created. No "Step": the screen reader adds
# "4 of 6". $status is stepper-status-completed or one of the three below.
iso-stage-a11y = { $title }, { $status }
iso-stage-status-current = em andamento
# The stage where creating the ISO stopped with an error.
iso-stage-status-failed = falhou
iso-stage-status-not-started = não iniciada
iso-progress-keep-open = Mantenha o Atlas aberto até terminar.
iso-cancel = Cancelar criação
iso-cancelling = Aguardando um ponto seguro para cancelar
# The heading over the progress bar of an ISO or a USB drive once cancelling is asked for.
iso-cancelling-short = Cancelando…
iso-cancelled = Criação da ISO cancelada
iso-cancelled-unchanged = Sua ISO original não foi alterada.
iso-complete = Sua ISO está pronta
iso-complete-backup = Faça backup dos seus arquivos antes de reinstalar o Windows com ela.
# The finished page's main button, which opens the USB drive panel.
iso-create-usb = Criar uma unidade USB
iso-open-folder = Mostrar na pasta
iso-failed = Não foi possível concluir a criação da ISO
# Under iso-failed, beside Try again.
iso-failed-retry = Confira se seus arquivos ainda estão onde você os escolheu e se a unidade de destino está conectada. Depois, tente novamente.
# Title while checking the files fails; the messages below say why.
iso-check-failed = Não foi possível verificar os arquivos
iso-check-failed-retry = Confira se o download da ISO e do pacote do Atlas terminou e tente novamente.
# Nothing ran because the folder the worker runs from couldn't be created.
iso-unstaged = O Atlas não conseguiu preparar a pasta de trabalho, então nada foi alterado.
# Titles and messages for an ISO or package Atlas can't use. The bar offers the fix:
# iso-download-windows and iso-use-local for the ISO, iso-fix-package for the package.
iso-edition-unsupported-title = Esta ISO não tem nenhuma edição compatível com o Atlas
iso-edition-unsupported = O Windows Home e o LTSC não são compatíveis. Use uma ISO com Pro, Education ou Enterprise.
iso-customised-title = Esta ISO foi personalizada
# In place of iso-customised-title, above iso-customised, when the ISO is one Atlas Manager
# created: Atlas creates an ISO only from an unmodified ISO from Microsoft.
iso-created-by-atlas-title = Esta ISO foi criada pelo Atlas
iso-customised = Ela já contém arquivos de instalação, como autounattend.xml. Use uma ISO original da Microsoft.
iso-preview-title = Esta ISO é uma compilação de versão prévia
iso-preview = A compilação do Windows desta ISO não está na lista de versões públicas da Microsoft. Use uma ISO da Microsoft.
iso-windows-unsupported-title = Este pacote do Atlas não pode usar esta ISO
iso-windows-unsupported = Use uma ISO original do Windows 11 de uma versão compatível com o pacote.
iso-release-unknown-title = O Atlas não conseguiu confirmar esta versão do Windows
iso-release-unconfirmed = O Atlas a compara com a lista de versões públicas da Microsoft. Confira sua conexão com a internet e tente novamente.
# $minimum is the oldest Atlas version that can make an ISO, such as "0.6.0".
iso-package-old-title = Este pacote do Atlas não pode criar uma ISO
iso-package-old = Use o Atlas { $minimum } ou mais recente.
# Instead of iso-package-old-title and iso-package-old when the file chosen as the Atlas package is a Windows ISO. "The Windows ISO" is the field named iso-source.
iso-package-windows-iso-title = Este arquivo é uma ISO do Windows, não um pacote do Atlas
iso-package-windows-iso = Escolha um pacote do Atlas (.atlaspkg) no lugar dela e escolha esta ISO como a ISO do Windows.
iso-manager-missing-title = O arquivo do Atlas Manager não foi encontrado
iso-fix-package = Escolher outro pacote
# A package that needs a newer Atlas Manager; Download Atlas Manager (manager-download) is
# beside it, and acquire-manager-update-needed says which version.
iso-manager-outdated-title = O Atlas Manager precisa ser atualizado
# This PC's network drivers couldn't be exported; the button beside it builds without them.
iso-network-not-added = O Atlas não conseguiu adicionar os drivers de rede deste PC à ISO.
iso-network-skip = Criar sem eles
# Title of the bar that asks for administrator permission. Its message is iso-admin-reason,
# or iso-elevation-declined after Windows refused the relaunch (UAC declined).
iso-elevation-title = O Atlas precisa de permissão para criar uma ISO
iso-admin-reason = A permissão é necessária para ler sua ISO do Windows e criar a nova.
iso-elevation-declined = O Windows não deu permissão ao Atlas, então ele ainda não pode ler sua ISO do Windows.
# The free space ran out while the ISO was being created.
iso-failed-space = Não há espaço livre suficiente na unidade de destino. Libere espaço ou salve a nova ISO em outra unidade.
# Under iso-manager-missing-title.
iso-manager-missing = Baixe AtlasManager.exe para uma pasta local, como Downloads, e abra-o de lá.
# Home and LTSC are the editions ISO creation drops; the others are examples it keeps.
iso-failed-edition = Esta ISO não contém nenhuma edição compatível do Windows. O Windows Home e o LTSC não são compatíveis. Use uma ISO que inclua outra edição, como Pro, Education ou Enterprise.
# Windows didn't open an ISO as a drive Atlas can read: the Windows ISO, the new ISO while it's
# checked, or the ISO a USB drive is made from. Under iso-check-failed or iso-failed, or on the
# USB page's ISO card.
iso-mount-failed = O Windows não conseguiu abrir a ISO. Reinicie o PC e tente novamente.
# Windows stopped answering while it read or mounted the ISO.
iso-mount-timeout = O Windows parou de responder enquanto abria a ISO. Reinicie o PC e tente novamente.
# vdrvroot and cdrom are the Windows drivers' own names, as tools that turn drivers off show
# them. Keep them as they are.
iso-mount-drivers = O Windows não consegue abrir arquivos ISO neste PC porque os drivers que ele usa para isso, vdrvroot e cdrom, estão desativados. Reative-os, reinicie o PC e tente novamente.
# Windows can store a file compressed or encrypted (in the file's Properties, under Advanced),
# and a download can be stored sparse, with space reserved but not yet written. Windows can't
# open an ISO stored any of these ways. Under iso-check-failed, with iso-download-windows and
# iso-use-local beside it, or on the USB page's ISO card.
iso-mount-file = O Windows não consegue abrir esta ISO porque o arquivo está compactado, criptografado ou é um arquivo esparso. Copie-o para uma pasta que não esteja compactada nem criptografada e use a cópia.
# Opens the folder with an ISO or USB job's raw logs.
iso-diagnostics = Abrir pasta de logs
# On the ISO and USB pages while Atlas updates Windows, or puts back Windows Update settings,
# from another page. Their controls are unavailable until it finishes.
iso-locked = O Atlas está ocupado com o Windows Update. Você poderá continuar aqui quando ele terminar.
# Names of the markers Windows sets when it wants a restart. They complete
# "Your PC needs to restart to finish installing updates (…)"; keep them short and lower
# case where the language allows.
prepare-reason-servicing = manutenção do Windows
prepare-reason-windows-update = o Windows Update
prepare-reason-file-renames = arquivos aguardando substituição
prepare-reason-update-agent = o serviço do Windows Update
prepare-reason-unknown = motivo não informado
# Under prepare-failed-title, with Try again (common-try-again).
prepare-failed-retry = Se tentar novamente não ajudar, conclua as atualizações restantes no Windows Update ou na Microsoft Store.
# Title of the error bar on the update card; the cause is its message.
prepare-failed-title = Algumas atualizações não foram concluídas
# Under prepare-unconfirmed-title: the run ended without writing any result, for example after


# Atlas was closed while it ran.
prepare-unconfirmed = A atualização parou antes de informar um resultado.
# Title of the bar over prepare-ended-unconfirmed: not called a failure, as none was reported.
prepare-unconfirmed-title = Não foi possível confirmar o resultado da atualização
prepare-affected-app = o aplicativo afetado
# A Store app couldn't update because it was open. $app is its name, such as NanaZip, or
# prepare-affected-app.
prepare-close-app = Feche { $app } e tente novamente. Se não o encontrar, feche-o pelo Gerenciador de Tarefas.
prepare-install-busy = Outra instalação ou uma reinicialização necessária está bloqueando as atualizações. Aguarde as outras instalações terminarem, reinicie o PC se o Windows pedir e tente novamente.
# Updates failed with 0x80073712 after Atlas's own repair of the component store (DISM). The
# button is prepare-restart-and-retry; updating carries on by itself after the restart.
prepare-components-damaged-title = O Windows não conseguiu se reparar
prepare-components-damaged = O Windows informa danos que impedem a instalação de atualizações. Uma reinicialização pode resolver isso, e o Atlas continua depois que você entrar.
prepare-restart-and-retry = Reiniciar e tentar novamente
# Windows records damage to its component store that it can't repair, so Atlas stops before
# any update. The one button is iso-open.
prepare-components-unrepairable-title = O Windows está danificado demais para ser atualizado
prepare-components-unrepairable = Faça backup dos seus arquivos e reinstale o Windows usando uma ISO com o Atlas.
# Causes the update worker names. The worker's own English message is shown below as a detail.
prepare-failed-session-owner = O Atlas está sendo executado com uma conta diferente da que você usou para entrar no Windows. Entre no Windows com uma conta de administrador, abra o Atlas nessa conta e tente novamente.
prepare-failed-store-missing = A Microsoft Store não está configurada para sua conta. Abra a Microsoft Store uma vez ou, se ela não estiver instalada, reinstale-a. Depois, tente novamente.
prepare-failed-store-battery = A Microsoft Store pausou as atualizações para economizar bateria. Ligue o PC na tomada e tente novamente.
prepare-failed-store-network = A Microsoft Store pausou as atualizações até que seu PC tenha uma conexão não limitada. Conecte-se por Wi-Fi ou Ethernet sem conexão limitada e tente novamente.
prepare-failed-store-timeout = Os apps da Store ainda não terminaram de atualizar. Conclua os downloads restantes na Microsoft Store e tente novamente.
prepare-failed-store-passes = A Microsoft Store continuou oferecendo novas atualizações. Conclua as atualizações restantes na Microsoft Store e tente novamente.
prepare-failed-manual-updates = Algumas atualizações do Windows precisam ser concluídas no Windows Update. Abra o Windows Update, conclua-as e tente novamente.
prepare-failed-windows-passes = O Windows Update continuou oferecendo novas atualizações. Conclua as atualizações restantes no Windows Update e tente novamente.
prepare-failed-windows-update-unreachable = O Windows Update não conseguiu acessar os servidores da Microsoft. Confira sua conexão com a internet e qualquer firewall, proxy ou VPN e tente novamente.
# Atlas Manager runs from a folder that links to another place (a junction or symbolic
# link). "Linked folder" and "local folder" as in usb-failed-location. Atlas keeps using
# the folder it was opened from, so trying again in the same window can't help.
prepare-failed-source-linked = O Atlas Manager está em uma pasta vinculada. Feche o Atlas, mova o Atlas Manager para uma pasta local deste PC e abra-o de lá.
prepare-error-code = Código do erro: { $code }
prepare-open-store = Abrir a Microsoft Store
prepare-windows-search = Buscando atualizações do Windows…
prepare-percent = { $percent }% desta fase
prepare-count = Atualizações concluídas: { $completed } de { $total }
prepare-bytes = { $downloaded } de aproximadamente { $total } MB baixados
prepare-progress-still = Nenhum progresso há { $minutes } min. Atualizações grandes podem demorar, então mantenha o Atlas aberto.
prepare-report-late = O Windows não informa o progresso há algum tempo. As atualizações podem ainda estar em andamento, então mantenha o Atlas aberto.
prepare-windows-download = Baixando atualizações do Windows…
prepare-windows-install = Instalando atualizações do Windows…
# While DISM repairs Windows' component store, before updates or after one failed on it, with
# prepare-windows-repair-detail under the progress bar. DISM reports no progress.
prepare-windows-repairing = Reparando o Windows…
prepare-windows-repair-detail = O Windows informa danos que podem impedir a instalação de atualizações. Isso pode levar meia hora ou mais.
prepare-store-search = Verificando a Microsoft Store…
prepare-store-install = Atualizando a Microsoft Store e seus apps…
prepare-stop = Parar atualizações
prepare-start = Buscar e instalar atualizações
# Under the Administrator check, while the Atlas package is still downloading or unpacking.
prepare-wait-for-package = Disponível quando o pacote do Atlas estiver pronto.
iso-username = Nome da conta local
# Under the local account name: Windows asks for the password at the first sign-in.
iso-account-help = Você escolherá uma senha quando entrar pela primeira vez.
iso-username-placeholder = Seu nome
# Beside the unavailable Continue button while the local account name is empty.
iso-account-empty = Digite um nome de conta local para continuar
# Keep the list of symbols exactly: Windows refuses them in account names.
iso-account-invalid = Use até 20 caracteres, sem espaço no início ou no fim e sem nenhum destes: " / \ [ ] : ; | = , + * ? < > @
iso-account-trailing-dot = O nome não pode terminar com um ponto.
iso-account-reserved = O Windows usa este nome para uma conta integrada. Escolha outro nome.
# The answer file on the ISO hides these Windows setup screens.
iso-terms-in-setup = A Instalação do Windows pedirá que você aceite os termos de licença.
prepare-drivers = Como os drivers devem ser instalados?
prepare-drivers-auto = Obter drivers pelo Windows Update
# The same answer as a radio button's label, where the choice is made.
prepare-drivers-auto-recommended = Obter drivers pelo Windows Update (recomendado)
prepare-drivers-auto-detail = O Windows encontra os drivers para seu hardware.
prepare-drivers-manual = Instalar os drivers por conta própria
prepare-drivers-manual-detail = O Windows Update não instalará drivers, então você precisará obtê-los com o fabricante do seu PC ou dispositivo. Os drivers já instalados serão mantidos.
# The Setup step's drivers card: this PC's network drivers on the ISO, then the choice
# Atlas Manager applies after sign-in, asked with prepare-drivers.
iso-drivers-card = Drivers
iso-network-drivers = Incluir os drivers de Wi-Fi e Ethernet deste PC
# The third driver answer, and its value on the Create step: Get ready asks on the new PC.
iso-drivers-defer = Escolher depois de entrar
prepare-network-unmetered = As atualizações precisam de uma conexão com a internet que não seja limitada. Conecte-se por Wi-Fi ou Ethernet e tente novamente.
# Connected, but Windows found no internet access (a captive portal, or DNS or firewall filtering).
prepare-network-limited = O Windows informa que esta rede está sem acesso à internet. Faça login na rede, se ela pedir, ou verifique o roteador e eventuais filtros de DNS ou firewall. Depois, tente novamente.
# "Metered connection" is the switch's name in Windows network settings.
prepare-network-metered = Esta conexão é limitada ou tem um limite de dados. Conecte-se a uma rede não limitada ou desative Conexão limitada nas configurações de rede e tente novamente.
prepare-network-settings = Abrir configurações de rede
iso-stage-network-drivers = Preparando os drivers de rede
# Under iso-complete when this PC's network drivers were asked for but the adapters use
# drivers that come with Windows, so none were added.
iso-network-inbox = Os adaptadores de rede deste PC usam drivers que já vêm com o Windows, então a ISO não precisa incluí-los.
desktop-setup-description = Conclua a configuração do PC. Suas escolhas do Atlas estão salvas; você pode voltar ao Windows se precisar.
desktop-setup-exit = Continuar no Windows

# Windows installation USB
usb-title = Criar uma unidade USB
usb-existing = Criar uma unidade USB a partir de uma ISO existente
# Title of the drive card, and the name of a drive that doesn't report one.
usb-drive = Unidade USB
# Title of the card with the ISO the USB drive is made from.
usb-iso-title = ISO do Windows
# No ISO was given, and none whose name starts with "Atlas" is in Downloads.
usb-iso-missing = Não há nenhuma ISO com o Atlas na sua pasta Downloads.
usb-iso-checking = Verificando a ISO…
# What checking the ISO found. It runs before anything is erased, so none of these mentions the drive.
usb-iso-not-usable = O Atlas não consegue criar uma unidade USB a partir desta ISO. Use uma ISO criada pelo Atlas ou uma ISO do Windows 11 da Microsoft em uma versão compatível com o Atlas.
# A linked folder points to another place (a junction or symbolic link).
usb-iso-location = A ISO ou o Atlas Manager está em um local de rede ou em uma pasta vinculada. Mova o arquivo para uma pasta deste PC, como Downloads.
# Splitting a large Windows image needs room on the drive Windows is on. Atlas checks again every 30 seconds.
usb-working-space = Não há espaço livre suficiente na unidade do Windows para preparar esta ISO. Libere espaço, e o Atlas verificará novamente sozinho.
# The ISO couldn't be read for another reason, such as a damaged file.
usb-iso-unreadable = O Atlas não conseguiu ler esta ISO. Tente novamente ou use outra ISO.
# Opens the Storage page of Windows Settings, where space can be freed.
usb-open-storage = Abrir configurações de armazenamento
usb-looking = Procurando unidades USB…
# $size is a whole number of gigabytes, as drives are sold.
usb-connect = Conecte uma unidade USB de { $size } GB ou mais.
# Under a drive that can't be used, after its size and letters: why. $size is a whole number
# of gigabytes, as drives are sold, as in usb-connect.
usb-drive-too-small-needs = Pequena demais. Requer { $size } GB ou mais.
usb-drive-too-small-iso = Pequena demais para esta ISO
usb-drive-has-iso = Sua ISO está nesta unidade
usb-drive-has-app = O Atlas Manager está sendo executado desta unidade
# A drive's size as it's sold, which isn't the size Windows shows. $size is a whole number of
# gigabytes, or a number of terabytes (text).
usb-drive-size = { $size } GB
usb-drive-size-tb = { $size } TB
# Joins a drive's size and its letters, an ISO's architecture and size under its name, and
# ready-checks-passed-some and ready-checks-handled on Get ready.
usb-detail-separator = { " · " }
usb-create = Criar unidade USB
# Beside the unavailable Create USB drive (usb-create) while several drives are listed and none is picked.
usb-hint-pick = Escolha uma unidade USB primeiro
# The question before erasing. $drive is the drive's name; $size is usb-drive-size or
# usb-drive-size-tb; $letters is its drive letters, such as "F:" or "F:, G:". A drive with no
# letter, such as one an unfinished write left, is asked with usb-confirm-title.
usb-confirm-title-letters = Apagar { $drive } ({ $size }, { $letters })?
usb-confirm-title = Apagar { $drive } ({ $size })?
# The same question for a drive that reports no name.
usb-confirm-title-unnamed-letters = Apagar a unidade USB ({ $size }, { $letters })?
usb-confirm-title-unnamed = Apagar a unidade USB ({ $size })?
usb-confirm-message = Todo o conteúdo da unidade será excluído. Sua ISO será mantida.
usb-confirm-erase = Apagar e criar
usb-progress-title = Criando a unidade USB…
# $percent is a whole number.
usb-percent = { $percent }%
# The stages of creating the USB drive, as a checklist under usb-progress-title.
usb-stage-prepare-files = Preparando os arquivos
usb-stage-formatting = Formatando
usb-stage-copying = Copiando os arquivos
usb-stage-checking = Verificando a unidade
usb-stage-ejecting = Ejetando
usb-keep-open = Mantenha o Atlas aberto e a unidade conectada.
usb-scan-failed-title = Não foi possível listar as unidades USB
usb-scan-failed-retry = O Atlas não conseguiu ler as unidades conectadas a este PC. Tente novamente.
# The title of the error bar for a USB drive, and the heading of the finished drive's page.
usb-failed-title = Não foi possível criar a unidade USB
usb-complete-title = Sua unidade USB está pronta
# F12, F11 and Esc are key names.
usb-ready = Desconecte-a, faça backup do PC que você vai reinstalar e inicie esse PC pela unidade USB. O menu de inicialização dele costuma abrir com F12, F11 ou Esc.
# After erasing may have begun.
usb-failed-partial = A unidade foi parcialmente gravada. Confira se ela está conectada e tente novamente.
# Before anything on the drive was changed.
usb-failed-before-erase = O Atlas parou antes de alterar a unidade. Tente novamente.
# Before erasing, the drive no longer matched the list: it was removed, reconnected or replaced.
# Atlas reads the list again, and picks the drive again if it's back.
usb-drive-changed-title = A unidade USB mudou
usb-drive-changed = Ela foi removida ou reconectada antes de o Atlas apagá-la, então nada nela foi alterado.
usb-drive-cancelled-title = Criação da unidade USB cancelada
usb-cancelled-partial = A unidade está incompleta. Crie-a novamente antes de usá-la.
usb-cancelled-unchanged = Sua unidade USB não foi alterada.
usb-eject-failed-title = Não foi possível ejetar a unidade USB
usb-eject-failed-ready = Ela está pronta para uso. Feche os arquivos ou janelas que a estejam usando e tente novamente.
# Title of the bar with Relaunch as administrator (common-restart-as-administrator). Its
# message is usb-admin-reason, or usb-elevation-declined after Windows refused the relaunch
# (UAC declined), as on the ISO page.
usb-elevation-title = O Atlas precisa de permissão para criar uma unidade USB
usb-admin-reason = O Atlas precisa de permissão de administrador para apagar e gravar a unidade.
usb-elevation-declined = O Windows não deu permissão ao Atlas, então ele ainda não pode gravar a unidade USB.
# Home, LTSC and Server are the editions the check refuses; the others are examples of
# editions it accepts. Keep edition names as Windows shows them.
detail-edition-unsupported = As edições Home, LTSC e Server do Windows 11 não são compatíveis. Use outra edição, como Pro, Education ou Enterprise. Se o Windows não conseguiu identificar sua edição, resolva isso antes de continuar.
install-source-title = Instalação indisponível
install-source-unsupported = Não é possível atualizar o Atlas { $source } diretamente para { $target }. Para usar esta versão, faça backup dos seus arquivos e reinstale o Windows.
# Before a package is chosen, so the version on offer isn't known yet.
install-source-unsupported-any = Não é possível atualizar o Atlas { $source } diretamente. Para usar uma versão mais recente, faça backup dos seus arquivos e reinstale o Windows.
# $folder is a folder path (text).
install-source-resume-package = Uma instalação do Atlas { $target } não foi concluída, e só o pacote do Atlas { $target } pode concluí-la. Abra esse pacote do Atlas (.atlaspkg). Se o Atlas o baixou, ele está em { $folder }.
# Tester build: only the bundled Atlas package can be installed.
install-source-resume-bundled = Uma instalação do Atlas { $target } não foi concluída. Esta versão de teste só pode instalar o pacote do Atlas incluído, então conclua essa instalação com o pacote do Atlas { $target } em uma versão oficial do Atlas Manager.
# Send a report and Export diagnostics are offered with it.
install-source-unconfirmed = O Atlas não conseguiu confirmar o que já está instalado neste PC, então não vai instalar nada por enquanto.
# Atlas's files are on this PC without a record of a finished installation. Create an Atlas ISO (iso-open) is beside it.
install-source-unrecorded = Este PC tem arquivos de uma versão anterior do Atlas, mas nenhum registro de uma instalação concluída, então não é possível atualizá-la. Para instalar o Atlas, faça backup dos seus arquivos e reinstale o Windows.
# Under the editions on the Create step, when Windows Setup asks which to install.
iso-edition-selection = Na Instalação do Windows, escolha uma edição para a qual você tenha licença.
detail-windows-preview = As compilações Insider não são compatíveis. Use uma versão pública do Windows 11.
detail-windows-release-unknown = O Atlas não conseguiu confirmar se esta compilação do Windows é uma versão pública. Conecte-se à internet e verifique novamente.
# $build is this PC's Windows build and update number, such as 26300.9807 (text).
detail-windows-release-not-listed = A compilação { $build } não está na lista de versões públicas do Windows 11 da Microsoft, então o Atlas ainda não pode ser instalado nela. As compilações Release Preview e outras compilações de versão prévia não são compatíveis. Verifique novamente quando a Microsoft incluir esta compilação na lista.


prepare-continue = Continuar atualizações
prepare-saving-restart = Salvando suas escolhas e configurando o Atlas para reabrir após a reinicialização do Windows…
prepare-restart-save-failed = Não foi possível salvar suas escolhas. Tente novamente antes de reiniciar.
prepare-restart-registration-failed = Suas escolhas estão salvas, mas o Atlas não conseguiu se configurar para abrir novamente após a reinicialização. Tente novamente ou reinicie o PC por conta própria e abra o Atlas depois de entrar na sua conta.
# The same cause as prepare-failed-source-linked, met while arranging the restart. Both ways
# on need the move, because Atlas keeps using the folder it was opened from.
prepare-restart-source-linked = Suas escolhas estão salvas, mas enquanto o Atlas Manager estiver em uma pasta vinculada, o Atlas não consegue se configurar para abrir novamente após a reinicialização. Feche o Atlas e mova o Atlas Manager para uma pasta local deste PC. Depois, abra-o de lá ou reinicie o PC por conta própria e abra-o de lá depois de entrar na sua conta.
prepare-restart-failed = O Atlas não conseguiu reiniciar seu PC. Tente novamente ou reinicie-o pelo menu Iniciar. Suas escolhas estão salvas, e o Atlas abrirá novamente depois que você entrar na sua conta.
diagnostics-export = Exportar diagnósticos
# Beside a spinner while an export runs, and in Send a report's footer while its diagnostics
# are collected.
diagnostics-exporting = Coletando diagnósticos…
# Accessible name of the row of help links: report-title, diagnostics-export and iso-diagnostics.
diagnostics-help-a11y = Obter ajuda
# Title of the result bar after an export; its button is iso-open-folder.
diagnostics-saved = Diagnósticos salvos
# Under diagnostics-saved, above diagnostics-saved-privacy. $file is the ZIP's name, such as
# Atlas-diagnostics-2026-11-24-0612.zip, and $folder the name of the folder it's in,
# "Diagnostics" (both text, never translated).
diagnostics-saved-in-folder = Salvos como { $file } na pasta { $folder } do Atlas.
# Under diagnostics-saved. Says exactly what the export removes, so keep every item.
diagnostics-saved-privacy = O Atlas removeu do arquivo seu nome de usuário, o nome do PC, os endereços de e-mail e as senhas ou chaves conhecidas.
# The bar when an export failed, on its own. Its button is common-try-again, and its raw error
# is behind Show details.
diagnostics-save-failed = Não foi possível salvar o ZIP de diagnóstico

## Tester builds (embedded-package feature)

# A bar at the top of the content on a release-candidate build.
rc-banner = Versão de teste do Atlas { $release }. Este app instala apenas o pacote do Atlas incluído.
home-status-bundled = Versão de teste { $release }
package-bundled = O Atlas { $version } incluído nesta versão de teste está pronto para instalar.
rc-about-release = Versão de teste
rc-about-commit = Commit de origem
rc-about-package = Pacote do Atlas incluído (SHA-256)
iso-package-bundled = O pacote do Atlas incluído nesta versão de teste

check-user-account = Conta de usuário
detail-user-account-ok = O UAC está ativado e sua conta está pronta para a instalação.
detail-user-account-not-ready = Ative o Controle de Conta de Usuário (UAC), reinicie o PC e tente novamente. Se você usa a conta Administrador integrada, entre com outra conta de administrador.
detail-user-account-work-or-school = O Atlas não pode ser instalado a partir de uma conta corporativa ou de estudante (Microsoft Entra ID). Entre com uma conta local ou uma conta Microsoft e tente novamente.
detail-user-account-check-failed = O Atlas não conseguiu verificar sua conta de usuário. Reinicie seu PC, reabra o Atlas e verifique novamente. O Windows informou: { $error }

footer-prepare-required = Conclua a atualização do Windows e dos apps da Store para continuar
# "Stage" as in prepare-close-stops-after-stage.
footer-prepare-stopping-stage = Parando as atualizações após a fase atual…
resume-choices-title = Continuando a instalação anterior
# The bar on Your choices, above the choices an unfinished installation holds, which it shows
# and can't change.
resume-choices-held = O Atlas usa as escolhas que você fez da última vez para concluir essa instalação, então elas não podem ser alteradas até que ela termine.

## Voluntary reports
report-title = Enviar um relato
report-received = Relato recebido
# Under the report's reference, which has a line of its own with a Copy button.
report-reference = Guarde esta referência caso entre em contato com a equipe do Atlas sobre este relato. Se você deixou dados de contato, a equipe pode usá-los para responder, mas não há garantia de resposta.
# Accessible name of the Copy button beside the report reference.
report-copy-reference = Copiar referência do relato
report-another = Enviar outro relato
# Label of the choice between the two kinds of report.
report-kind = O que você quer enviar?
report-kind-issue = Um problema
report-kind-suggestion = Uma sugestão
report-message = Sua mensagem
# What the message box shows while it's empty, for each kind of report.
report-message-placeholder-issue = O que aconteceu e o que você estava fazendo?
report-message-placeholder-suggestion = O que você gostaria que mudasse?
# Under the message box, which also reads it out.
report-message-help = Não inclua senhas.
# Under the message or contact box once it's near the longest the report service accepts.
# $count and $max are numbers.
report-character-count = { $count } de { $max } caracteres
report-contact = Contato (opcional)
report-contact-placeholder = E-mail ou nome de usuário no Discord
report-attach = Incluir diagnósticos
# Under Include diagnostics. Part of the privacy notice the user agrees to: it says
# exactly what Atlas removes and keeps, so keep every item.
report-attach-description = Logs e detalhes do sistema que ajudam a encontrar a causa. O Atlas remove seu nome de usuário, o nome do PC, endereços de e-mail e senhas ou chaves conhecidas. Detalhes de erros, modelos de hardware e nomes de apps são mantidos. Você pode revisar o ZIP antes de enviar.
report-review = Revisar ZIP
# A bar when diagnostics couldn't be prepared. Its button is common-try-again, and its raw
# error is behind Show details.
report-prepare-failed-title = Não foi possível preparar os diagnósticos
report-prepare-failed-advice = Tente novamente ou envie sem os diagnósticos.
# The privacy notice the user agrees to, with report-attach-description. Changing it means a
# new PRIVACY_VERSION in the app, the report service and the website, deployed together.
report-privacy = Seu relato é enviado de forma privada à equipe do Atlas em reports.atlasos.net. Sua mensagem e seus dados de contato são enviados como foram escritos. A equipe pode usar serviços de IA de outras empresas para ajudar na investigação. Esses serviços recebem sua mensagem e os diagnósticos, mas não seus dados de contato. Os relatos são excluídos após 90 dias, e os logs de segurança do servidor podem registrar seu endereço IP.
report-website = Privacidade e site de relatos
report-consent = Concordo em enviar este relato e os diagnósticos incluídos à equipe do Atlas
# Under "Report wasn't sent". The footer's button is common-try-again, except after
# report-not-sent-outdated, where it's report-failed-website and the bar's button is
# manager-download.
report-not-sent-retry = Confira sua conexão com a internet e tente novamente. Você também pode enviá-lo pelo site de relatos.
report-not-sent-busy = O serviço de relatos está ocupado. Aguarde alguns minutos e tente novamente.
report-not-sent-outdated = Esta versão do Atlas Manager não pode enviar relatos. Copie sua mensagem para o site de relatos, com o ZIP, se você incluiu diagnósticos.
report-not-sent-diagnostics = Não foi possível enviar os diagnósticos. Tente novamente ou envie sem eles.
# The footer's button where this version can't send.
report-failed-website = Abrir o site de relatos
# Beside a spinner in the footer while the report is on its way.
report-sending = Enviando…
report-send = Enviar relato

# Under the message box when Send report finds it too short or too long. $min and $max
# are numbers: the message lengths the report service accepts.
report-validation-message = Digite entre { $min } e { $max } caracteres.

# Under the contact box. $max is a number: the longest contact details the report
# service accepts.
report-validation-contact = Limite os dados de contato a { $max } caracteres.

# Under the agreement check box when Send report is chosen without it.
report-validation-consent = Confirme que concorda em enviar este relato.

report-failed-title = O relato não foi enviado

## Windows version update
# Atlas moves Windows to a newer release before installing, through Windows Update.
# $release is the target release (26H2) and $current the release the PC has (24H2);
# say "Windows 11, version" before them as Microsoft does. $version is an Atlas version.

# Home, under the update button, when the update also moves Windows: a card with the
# update's two parts. home-plan-name is the accessible name of their list.
home-plan-files = Seus arquivos e apps são mantidos.
home-plan-name = Esta atualização tem duas partes
home-plan-windows-title = Windows 11, versão { $release }
home-plan-windows-step = O Atlas a instala pelo Windows Update, e depois seu PC é reiniciado.
# The same step where moving is optional.
home-plan-windows-step-ask = Opcional. O Atlas pergunta primeiro, depois a instala pelo Windows Update, e seu PC é reiniciado.
# Instead of the step's own line, once Windows has moved.
home-plan-step-installed = Instalada.
home-plan-atlas-title = Atlas { $version }
home-plan-atlas-step = O Atlas é atualizado e mantém suas escolhas, e depois seu PC é reiniciado.
# $date and $until are dates.
home-end-of-updates-title = O Windows 11, versão { $current }, deixa de receber atualizações de segurança em { $date }
home-end-of-updates-past-title = O Windows 11, versão { $current }, não recebe mais atualizações de segurança
home-end-of-updates-message = Atualizar para o Atlas { $version } também leva este PC para o Windows 11, versão { $release }, que recebe atualizações de segurança até { $until }.
# Instead of home-end-of-updates-message when the card with the update's two parts, which
# names the move, is under the bar.
home-end-of-support-plan = O Windows 11, versão { $release }, recebe atualizações de segurança até { $until }.

# Home, when this Windows can't take the Atlas version at all. $product is Windows'
# own name for the edition, such as Windows 11 Home.
install-windows-edition-only = O Atlas { $version } funciona com o Windows 11 Pro, Enterprise e Education, então não pode ser instalado no { $product }.
# The same, on a version whose security updates end, with Open Windows Update. $date is a date.
install-windows-edition-until = O Atlas { $version } funciona com o Windows 11 Pro, Enterprise e Education, então não pode ser instalado no { $product }. O Windows 11, versão { $current }, recebe atualizações de segurança até { $date }, e o Windows Update pode levar este PC para uma versão mais recente.
# The same once that date has passed.
install-windows-edition-ended-update = O Atlas { $version } funciona com o Windows 11 Pro, Enterprise e Education, então não pode ser instalado no { $product }. A versão { $current } não recebe mais atualizações de segurança, então atualize o Windows mesmo sem o Atlas.
# Instead of install-windows-edition-only on an LTSC edition, which Windows names with a year that reads like a version.
install-windows-edition-ltsc = O Atlas { $version } funciona com o Windows 11 Pro, Enterprise e Education. As edições LTSC não são compatíveis.
# $releases lists the supported releases, such as "25H2 or 26H2".
install-windows-reinstall = O Atlas { $version } requer o Windows 11, versão { $releases }, e o Windows Update não consegue levar este PC até ela. Faça backup dos seus arquivos e reinstale o Windows usando uma ISO com o Atlas.
# The same on Home, where the card that creates an Atlas ISO comes first and says how to reinstall.
home-windows-no-path = O Atlas { $version } requer o Windows 11, versão { $releases }, e o Windows Update não consegue levar este PC até ela.

# Home, when Atlas changed Windows Update settings for an update and hasn't put them back.
# The bar's button is home-put-back; Continue update (home-continue-update) is beside the
# version above.
home-update-access-title = As configurações do Windows Update foram alteradas para a atualização do Atlas
# Under home-update-access-title while an update that moves Windows is under way.
home-update-access-put-back-later = O Atlas restaura essas configurações quando a atualização terminar.
# When the last check found no offer yet.
home-update-access-waiting = O Atlas ativou o Windows Update para levar este PC ao Windows 11, versão { $release }, e o Windows Update ainda não a ofereceu.
home-update-access-updating = O Atlas ativou o Windows Update para instalar atualizações e ainda não terminou.
# Instead of home-update-access-title when Atlas can't read its record of the settings it changed.
home-update-access-unreadable-title = Não foi possível ler o registro do Atlas sobre o Windows Update
# With Send a report and Export diagnostics under it; the raw error is behind Show details. Also
# why putting the settings back failed, where the worker names this cause.
home-update-access-unreadable-problem = O Atlas não consegue ler o registro das configurações do Windows Update que alterou, então não vai alterar nem restaurar nada.
# Under the bar when putting the settings back failed for another reason. Put back settings
# tries again; the raw error is behind Show details.
home-put-back-failed = O Atlas não conseguiu restaurar as configurações.
# Why the Windows Update settings Atlas changed can't be put back yet: an unfinished Atlas
# installation or update puts them back in its last stage. On Home, where Put back settings is
# hidden meanwhile, and in the close question when putting them back failed. Also under the
# Windows release choice on Get ready, where keeping this version waits for the same reason.
# "Stage" is a stage of installing, not one of the four flow steps.
update-access-finish-install = Conclua primeiro a instalação do Atlas. Na última fase, ela restaura as configurações do Windows Update que o Atlas alterou.
home-continue-update = Continuar atualização
home-put-back = Restaurar configurações
home-putting-back = Restaurando configurações…

# Get ready: the card of the move to a newer Windows version, first on the page. Its title is
# windows-card-title, and the line under it says how the move stands.
windows-card-title = Windows 11, versão { $release }
# Under the title of a move the Atlas package needs, before the go-ahead.
windows-required = O Atlas { $version } não oferece suporte à versão { $current }, então o Atlas atualiza o Windows primeiro.
# Under the title where moving is optional.
windows-optional = O Atlas funciona com qualquer uma das versões.
# The choice's accessible name; the two answers say it.
windows-card-question = Qual versão do Windows este PC deve usar?
windows-choice-move-recommended = Atualizar para o Windows 11, versão { $release } (recomendado)
# $date is when the new version stops getting security updates.
windows-choice-move-support = Atualizações de segurança até { $date }.
windows-choice-keep = Manter o Windows 11, versão { $current }
windows-choice-keep-later = Permanece na versão { $current }. Você pode atualizar depois pelo Atlas Manager.
windows-card-facts = O que muda
windows-fact-files = Seus arquivos e apps são mantidos. O Atlas restaura o que a atualização desfizer.
windows-fact-time = Geralmente alguns minutos, até 2 horas, e depois uma reinicialização.
# Behind Show details, on a PC whose version still has them.
windows-fact-removes = Remove o Windows PowerShell 2.0 e o WMIC.
# Opens the Atlas documentation on undoing the move, where moving is optional.
windows-undo-link = Como desfazer a atualização
# Before windows-accept: accepting the terms and starting the move are one choice.
windows-terms-line = Ao atualizar, você aceita os Termos de Licença para Software Microsoft.
windows-terms-link = Ler os termos de licença
windows-accept = Aceitar e atualizar
# Once the terms are accepted, before the move starts by itself.
windows-starting = Iniciando…
windows-starts-after-checks = Começa quando as verificações forem aprovadas.
windows-starts-after-package = Começa quando o Atlas { $version } estiver pronto.
# After the move, when Windows reinstalled itself instead of switching the new version on.
windows-rebuilt = A versão { $release } redefiniu algumas alterações do Atlas. O Atlas { $version } as aplica novamente com suas escolhas anteriores.
# Asked before keeping this version once the move has begun; the message is stop-update-before
# and the buttons are common-cancel and prepare-keep-version.
windows-keep-title = Manter o Windows 11, versão { $current }?


# The bar that names each Windows Update setting Atlas turns on for the update.
access-notice-title = O Atlas ativa o Windows Update temporariamente
access-off = O Windows Update está desativado neste PC. O Atlas o reativa enquanto atualiza o Windows.
access-paused = As atualizações do Windows estão pausadas neste PC. O Atlas as retoma enquanto atualiza o Windows.
access-delayed = As atualizações mensais estão adiadas neste PC. O Atlas remove o adiamento enquanto atualiza o Windows.
# After the lines above.
access-back = Quando o Atlas { $version } estiver instalado, essas configurações voltarão a ficar como eram.
access-back-stop = Se você parar antes disso, o Atlas as restaura.

prepare-reason-feature-update = a nova versão do Windows
prepare-reason-feature-commit = a conclusão da nova versão do Windows
prepare-reason-apprepository = o reparo da Microsoft Store
# Waiting for Windows Update to offer the new version: the progress bar's label and status
# line, the line under the bar, and how long Atlas has waited, in whole minutes, after it.
windows-waiting = Aguardando o Windows Update oferecer o Windows 11, versão { $release }…
windows-waiting-detail = Geralmente alguns minutos, até 2 horas. O Atlas segue sozinho, e você pode continuar usando seu PC.
windows-waited =
    { $minutes ->
        [one] Aguardando há { $minutes } minuto.
       *[other] Aguardando há { $minutes } minutos.
    }
# After 2 hours of looking again without an offer. The buttons are common-try-again and iso-open.
windows-wait-ended-title = O Windows Update não ofereceu a versão { $release } em 2 horas
windows-wait-ended = O Atlas restaurou suas configurações. Tente novamente mais tarde ou reinstale o Windows usando uma ISO com o Atlas.
# Instead of the message above when putting the settings back failed. The button is
# home-put-back; the raw error is behind common-show-details.
windows-wait-put-back-failed = O Atlas não conseguiu restaurar suas configurações do Windows Update.
# Windows couldn't get the new version ready to finish at the restart, so the PC didn't
# restart. Try again (common-try-again) makes the restart again.
windows-commit-failed-title = O Windows não conseguiu preparar a reinicialização
windows-commit-failed = Seu PC não foi reiniciado. Tente novamente.

# Outcomes of moving Windows, each a title and what to do next. A cause that only the Atlas
# team can look into has report-title as its button; one an ISO fixes, iso-open.
windows-outcome-not-offered-title = O Windows Update ainda não ofereceu a versão { $release }
windows-outcome-not-offered = Isso pode levar até 2 horas. Seu PC continua com a versão { $current }.
windows-outcome-hardware-title = Este PC não atende aos requisitos do Windows 11
# $missing lists the hardware this PC lacks, from the two messages below.
windows-outcome-hardware = Ele não tem { $missing }, então o Windows Update não vai oferecer a versão { $release }. Faça backup dos seus arquivos e reinstale o Windows usando uma ISO com o Atlas.
hardware-tpm = TPM 2.0
hardware-uefi = firmware UEFI
windows-outcome-hidden-title = A versão { $release } está oculta no Windows Update
windows-outcome-hidden = Volte a exibi-la com a ferramenta que você usou para ocultá-la e tente novamente.
windows-outcome-disk-space-title = Não há espaço livre suficiente
# $needed and $free are whole gigabytes; $drive is a drive such as C:. The button is
# check-fix-storage; Atlas reads the free space again by itself.
windows-outcome-disk-space = O Windows precisa de { $needed } GB livres em { $drive }, e há { $free } GB. O Atlas continua sozinho quando houver espaço suficiente.
windows-outcome-managed-title = Este PC recebe atualizações da organização
windows-outcome-managed = O servidor de atualizações da organização não oferece a versão { $release }, então o Atlas não alterou nada. Fale com sua organização ou reinstale o Windows usando uma ISO com o Atlas.
windows-outcome-policy-title = Algo continua desfazendo as alterações no Windows Update
# $setting is the technical name of a Windows Update policy value, such as NoAutoUpdate,
# shown as it is.
windows-outcome-policy = { $setting } volta ao valor anterior depois que o Atlas o altera, então o Atlas não consegue atualizar o Windows. Se uma organização gerencia este PC, fale com ela.
# $service is a service-* name, after a fixed phrase so that the name needs no agreement. The
# buttons are common-try-again and prepare-open-services.
windows-outcome-service-off-title = Serviço desativado: { $service }
windows-outcome-blocked-service = O Windows Update precisa dele. Defina-o como Manual em Serviços e tente novamente.
windows-outcome-blocked-title = Algo mantém o Windows Update desativado
windows-outcome-blocked = Uma configuração que o Atlas não alterou, { $setting }, impede a execução dele. Altere-a e tente novamente.
windows-outcome-rollback-title = O Windows não conseguiu concluir a instalação da versão { $release }
windows-outcome-rolled-back = Ele voltou para a versão { $current }. Seus arquivos e apps estão intactos.
windows-outcome-components-lost-title = Algumas alterações do Atlas foram perdidas
windows-outcome-components-lost = O Atlas não consegue identificar o motivo, então parou antes de instalar o Atlas { $version }.
windows-outcome-build-title = O Windows mudou de versão durante a atualização
windows-outcome-build = Restaure as configurações que o Atlas alterou e comece de novo pela página inicial.
windows-outcome-journal-title = O Atlas não consegue ler o registro desta atualização
windows-outcome-journal = Ele não vai alterar nem restaurar nada até que a equipe do Atlas analise o problema.
windows-outcome-pin-title = Não é possível registrar uma política do Windows Update
# $setting is the name of a Windows Update policy value, such as TargetReleaseVersionInfo.
windows-outcome-pin = { $setting } tem um valor que o Atlas não conseguiria restaurar depois, então o Atlas não alterou nada.
windows-outcome-terms-title = Os termos de licença não foram aceitos
windows-outcome-terms = O Windows Update precisa deles antes de instalar a versão { $release }.
windows-outcome-failed-title = O Windows não conseguiu instalar a versão { $release }
windows-outcome-failed = Seu PC continua com a versão { $current }.
# Windows services a move needs, as Services lists them.
service-bits = Serviço de Transferência Inteligente de Plano de Fundo (BITS)
service-cryptsvc = Serviços de Criptografia
service-trusted-installer = Instalador de Módulos do Windows
prepare-open-services = Abrir Serviços
# Confirms keeping this version in the windows-keep-title question.
prepare-keep-version = Manter a versão { $current }

# Asked before leaving the update with Windows Update settings changed.
stop-update-title = Parar a atualização para o Atlas { $version }?
# stop-update-title for a first install or a reinstall, which so far has only updated Windows.
stop-update-title-windows = Parar a atualização do Windows?
stop-update-before = O Atlas restaura as configurações do Windows Update que alterou. As atualizações que o Windows já instalou continuam instaladas, e seu PC mantém o Windows 11, versão { $current }.
stop-update-after = Seu PC mantém o Windows 11, versão { $release }. O Atlas restaura as configurações do Windows Update que alterou.
stop-update-access = O Atlas restaura as configurações do Windows Update que alterou. As atualizações que o Windows já instalou continuam instaladas.
stop-update-keep = Continuar atualizando
# Dialog shown when the window is closed while Windows Update is turned on for an update; its
# buttons are window-close-keep and window-close-put-back.
window-close-update-access-title = Fechar o Atlas?
window-close-update-access-message = Antes de fechar, o Atlas restaura as configurações do Windows Update que alterou. Você pode iniciar a atualização novamente pela página inicial.
window-close-put-back = Restaurar e fechar
# When putting the settings back before closing failed. The reason comes first, then this
# message; the buttons are window-close-keep and window-close-close.
window-close-put-back-failed-title = Fechar sem restaurar as configurações?
window-close-put-back-failed-message = Se você fechar o Atlas agora, as configurações do Windows Update continuarão como o Atlas as alterou. Quando você abrir o Atlas novamente, a página inicial oferecerá a opção de restaurá-las.

# PC checks: Windows compatibility on a version Atlas moves from. The move's card says how
# the move goes.
detail-build-needs-release = Esta versão do Atlas requer o Windows 11, versão { $release }, e este PC tem a versão { $current }.

# The first lines of a report about a Windows update that didn't finish; technical
# details follow in English.
report-transition-intro = A atualização do Windows para o Atlas não foi concluída. Detalhes para a equipe do Atlas:

# When Windows reinstalled itself while it moved to a newer version, instead of
# switching the new version on in place. Atlas then puts all of its changes back.
history-mode-rebase = reinstalação após uma atualização do Windows
# Your choices after Windows reinstalled itself during a move, which put the choices of the
# Atlas it had back.
rebase-choices-title = Suas escolhas do Atlas { $previous }
rebase-choices-kept = O Atlas restaura as escolhas que você fez para o Atlas { $previous }, e você pode alterá-las depois reinstalando o Atlas.
# Above the questions the record of the move had no answer for, which are all Your choices asks.
rebase-choices-asked = O Atlas restaura todas as outras escolhas que você fez para o Atlas { $previous }.
# Asked before any restart Atlas makes while other people are signed in to the PC. Its
# buttons are restart-others-keep, the default, and restart-others-restart.
restart-other-question = Reiniciar com outra pessoa conectada?
restart-others-question = Reiniciar com outras pessoas conectadas?
# $names lists their account names, such as "Alex and Sam"; $count is how many there are.
restart-others-signed-in =
    { $count ->
        [one] Esta conta também está conectada: { $names }. Reiniciar fecha os apps abertos nela, e o trabalho não salvo será perdido.
       *[other] Estas contas também estão conectadas: { $names }. Reiniciar fecha os apps abertos nelas, e o trabalho não salvo será perdido.
    }
restart-others-keep = Não reiniciar
restart-others-restart = Reiniciar mesmo assim
# Microsoft Store itself, before the Store apps: Get ready's status line while it updates or is
# repaired, with prepare-store-repair-detail under the progress bar while it's repaired.
prepare-store-updating = Atualizando a Microsoft Store…
prepare-store-repairing = Reparando a Microsoft Store…
prepare-store-repair-detail = Isso pode levar alguns minutos.
prepare-store-repair-notice = O Atlas está reparando a Microsoft Store. Até terminar, o menu Iniciar e a barra de tarefas podem não funcionar, e os apps que abrem quando você entra na sua conta podem mostrar um erro. Mantenha seu PC ligado e na tomada. Ele será reiniciado sozinho quando o reparo terminar.
# Under ready-updates-done-windows once Get ready has finished, where Microsoft Store is turned off.
# What updating did to Microsoft Store itself otherwise is only in the log.
prepare-store-skipped-removed = A Microsoft Store está desativada neste PC, então os apps da Store não foram atualizados.
# None of Atlas's repairs made Microsoft Store work. The button is prepare-repair-store-again;
# prepare-store-broken-iso and Create an Atlas ISO (iso-open) are behind common-show-details.
prepare-store-broken-title = A Microsoft Store não está funcionando
prepare-store-broken = O Atlas não conseguiu repará-la, e instalar o Atlas agora pode danificar os apps da Store.
prepare-store-broken-iso = Se o reparo continuar falhando, faça backup dos seus arquivos e reinstale o Windows usando uma ISO com o Atlas.
prepare-repair-store-again = Tentar reparar novamente
# Windows couldn't install updates for some of its own apps, and Atlas's Store repairs didn't help.
# $apps lists the apps by their package names, joined with list-and.
prepare-store-staging-title = O Windows não consegue atualizar os apps integrados
prepare-store-staging = O Windows não conseguiu instalar as atualizações destes apps integrados, e os reparos do Atlas não resolveram: { $apps }. { prepare-components-unrepairable }

screen-keyboard-title = Idiomas do teclado
screen-keyboard-question = Você usa vários idiomas de teclado?
package-option-keyboard-shortcuts = Sim, com atalhos de teclado
package-option-keyboard-selector = Sim, com o seletor na barra de tarefas
package-option-keyboard-single = Não, uso apenas um layout
consequence-keyboard-shortcuts = Alt+Shift alterna o idioma; Ctrl+Shift alterna o layout.
consequence-keyboard-selector = Desative Alt+Shift e Ctrl+Shift para evitar mudanças acidentais durante jogos.
package-choice-keyboard-description = Escolha como alternar o idioma do teclado.
consequence-keyboard-single = { consequence-keyboard-selector }
