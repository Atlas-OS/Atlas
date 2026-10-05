### Atlas Manager: Português (Brasil), pt-BR. Preview translation, revised on 30 September 2026 from the en-GB source (i18n/en-GB/atlas.ftl).
###
### Style notes for this catalog: address the reader as "você" (mostly implicit),
### the computer is "seu PC" / "o PC"; "o Atlas" and "o Windows" take the article;
### buttons are short infinitives ("Reiniciar agora"); headings are sentence case
### with no final full stop. "Reiniciar" is only ever the PC / Windows; reopening
### the Atlas Manager is "reabrir". The four Windows Security switches keep the names
### Windows shows in Brazilian Portuguese and are referred to as "proteções".
### This catalog also serves pt-PT requests; Brazilian vocabulary is used where
### no neutral form exists (baixar, arquivo, configurações, excluir, tela).
### The .apbx file is the "pacote do Atlas" ("o pacote" once it is clear).

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
# "Relaunch" means reopening the Atlas Manager (elevated), never restarting the PC.
common-restart-as-administrator = Reabrir como administrador
common-try-again = Tentar novamente
common-read-the-docs = Ler o guia do Atlas
common-show-details = Mostrar detalhes
common-hide-details = Ocultar detalhes
# Accessible name of a Show details or Hide details toggle. $action is common-show-details or
# common-hide-details; $section is the title of the card it opens.
common-details-a11y = { $action }, { $section }
common-open-log-file = Abrir arquivo de log
# Accessible name of the Copy button beside the install log.
common-copy-install-log = Copiar log de instalação
common-install-log = Log de instalação
# Row labels in summary cards.
common-windows = Windows
common-options = Opções
common-package = Arquivos de instalação
common-installed-as = Tipo de instalação
common-installed = Instalado
common-checking = Verificando
# Joins two items in a list: "Brave, Firefox". The braces keep the space.
list-separator = { ", " }
# Joins two alternatives: "26100 ou 26200".
list-or = { $a } ou { $b }
# Joins the last two items of a list: "Tamper Protection and Cloud-delivered protection".
# $a may itself be several items joined with list-separator.
list-and = { $a } e { $b }
# Accessible name of a message bar that announces itself: its title, then its message.
infobar-a11y = { $title }. { $message }

## Janela

# Dialog shown when the window is closed while an install runs.
window-close-title = Fechar durante a instalação do Atlas?
window-close-message = A instalação continuará em segundo plano. Abra o Atlas novamente para acompanhar o progresso e ver o resultado. Mantenha o PC ligado até ela terminar.
# Instead of window-close-message when the installation restarts the PC afterwards: only an
# open Atlas window restarts it, so closing the window cancels that.
window-close-message-restart = A instalação continuará em segundo plano, mas seu PC não será reiniciado automaticamente enquanto o Atlas estiver fechado. Abra o Atlas novamente para acompanhar o progresso e ver o resultado. Mantenha o PC ligado até ela terminar.
window-close-keep = Manter aberta
window-close-close = Fechar janela
# Dialog shown when the window is closed during the final checks, before the
# installer has started; window-close-keep and window-close-close are its buttons.
window-close-preparing-title = Fechar antes do início da instalação?
window-close-preparing-message = O Atlas ainda está verificando seu PC e não começou a instalação. Se você fechar agora, a instalação não será iniciada. Abra o Atlas novamente para continuar.
# Dialog shown when the window is closed while Windows and Store apps update. Its
# message is prepare-close-message; its buttons are iso-keep-open and prepare-stop.
prepare-close-title = As atualizações ainda estão em andamento
# "Stop updating" is prepare-stop, the dialog's other button.
prepare-close-message = Mantenha o Atlas aberto enquanto as atualizações estiverem em andamento. Se você escolher Parar atualizações, elas serão interrompidas após a etapa atual, e então você poderá fechar o Atlas.
# Dialog shown when the window is closed during the restart countdown after a
# successful install. Its buttons are window-close-keep, restart-now and
# window-close-restart-close.
window-close-restart-title = Fechar o Atlas sem reiniciar?
# "Reiniciar agora" is restart-now, one of this dialog's three buttons.
window-close-restart-message = Seu PC precisa ser reiniciado para concluir a configuração do Atlas. Se você fechar o Atlas agora, ele não reiniciará seu PC, então reinicie-o por conta própria quando puder. Salve seu trabalho antes de escolher Reiniciar agora.
window-close-restart-close = Fechar sem reiniciar
# Dialog shown when the window is closed during a setup with Windows Security switches still
# off. $switches names them as Windows Security does, joined like a list. Its buttons are
# window-close-keep, common-open-windows-security and window-close-close.
window-close-protection-title = Fechar o Atlas com a proteção desativada?
window-close-protection-message = Parte da proteção da Segurança do Windows ainda está desativada: { $switches }. Se você não for concluir a instalação do Atlas, reative a proteção antes de fechar. Se for, o Atlas continuará sua configuração quando você abri-lo novamente.
# Title of the file picker for an Atlas package (.apbx) file.
file-dialog-open-package = Abrir um pacote do Atlas (.apbx)
# Message Windows shows in its restart notification.
shutdown-comment = O Atlas foi instalado. O Windows está reiniciando para concluir a configuração.
# Message Windows shows in its restart notification when "Get ready" restarts
# to finish installing Windows updates.
prepare-shutdown-comment = O Atlas está reiniciando o Windows para concluir a instalação das atualizações.

## Sistema

# "Windows 11 Pro 25H2 (build 26200.1234)". All three values are text. Windows pt-BR keeps "build".
system-description = { $product } { $version } (build { $build })

## Página inicial

home-not-installed = Boas-vindas ao Atlas
# The headline when Atlas Manager can't tell what is installed on this PC.
home-state-unknown = Atlas neste PC
# The headline when Atlas is installed. $version is text.
home-version = Atlas { $version }
# $date is a formatted date.
home-installed-on = Instalado em { $date }
home-status-checking = Verificando atualizações
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
# A bar on Home after an installation finished, until the PC restarts. Its message is
# restart-needed and its button restart-now.
home-restart-title = Seu PC precisa ser reiniciado
home-security-reminder-title = Reative sua proteção
# Instead of home-security-reminder-title when no switch reads off but some couldn't be read
# (with home-security-reminder-unreadable-message).
home-security-reminder-unreadable-title = Confira se sua proteção está ativada
# After leaving the install flow. $switches names the switches that read off, as
# Windows Security names them (protection-*), joined with list-separator and list-and.
home-security-reminder-message = O Atlas não está instalando nada, mas parte da proteção da Segurança do Windows ainda está desativada. Abra a Segurança do Windows e verifique se estas proteções estão ativadas: { $switches }.
# Instead of home-security-reminder-message or installed-security-message when no switch
# reads off but some couldn't be read. $switches names those, joined like a list.
home-security-reminder-unreadable-message = O Atlas não conseguiu verificar todas as proteções. Confira na Segurança do Windows se estas proteções estão ativadas: { $switches }.
home-elevation-title = O Atlas precisa de permissão para instalar
home-state-error-title = Não foi possível ler os dados da sua instalação do Atlas
# "Check again" is home-check-again, beside the status above the bar. $error is a raw
# error message (text).
home-state-error-message = A versão, as escolhas e o histórico do Atlas podem não aparecer corretamente. Escolha Verificar novamente para tentar outra vez. Detalhes: { $error }
home-whats-new = Novidades do Atlas { $version }
home-view-release = Ver notas da versão no GitHub
home-released = Lançado em { $date }
home-show-less = Mostrar menos
home-show-full-notes = Mostrar todas as notas da versão
home-your-install = Sua instalação do Atlas
# Atlas is installed, but without the record Atlas Manager keeps (older versions didn't write one).
home-install-unrecorded = Este PC não tem registro de como o Atlas foi instalado, então não é possível mostrar suas escolhas nem o histórico de instalações.
# Row label: how Atlas was set up.
home-set-up = Método de configuração
home-set-up-during-oobe = Durante a configuração do Windows
home-history = Histórico de instalações
# One history row. $version is text, $mode one of the history-mode-* messages, $date a formatted date and time.
home-history-entry = Atlas { $version } · { $mode } · { $date }
home-how-it-works = Vamos preparar seu PC para o Atlas
home-step-1-detail = O Atlas verifica seu PC, instala as atualizações pendentes do Windows e da Microsoft Store e baixa os arquivos de instalação. Os apps da Store podem ser fechados e talvez seja preciso reiniciar o PC, então salve seu trabalho primeiro.
# Tester build: the Atlas package is bundled, nothing is downloaded.
home-step-1-detail-bundled = O Atlas verifica seu PC, instala as atualizações pendentes do Windows e da Microsoft Store e prepara os arquivos de instalação incluídos. Os apps da Store podem ser fechados e talvez seja preciso reiniciar o PC, então salve seu trabalho primeiro.
home-step-2-detail = Escolha se quer manter o Microsoft Defender e as proteções do processador, como as atualizações do Windows são instaladas e quais extras opcionais adicionar.
home-step-3-detail = Desative quatro proteções na Segurança do Windows para que elas não bloqueiem a instalação. O Atlas mostra como.
home-step-4-detail =
    { $minutes ->
        [one] A instalação leva cerca de um minuto. Depois, seu PC precisa ser reiniciado.
       *[other] A instalação leva cerca de { $minutes } minutos. Depois, seu PC precisa ser reiniciado.
    }
# Accessible name of a numbered step.
home-step-a11y = Etapa { $number }: { $title }
# Link buttons: say where they lead.
home-github = Ver o Atlas no GitHub
home-discord = Comunidade do Atlas no Discord
home-report-problem = Relatar um problema

## Como uma instalação foi feita (do documento de estado)

mode-fresh = Primeira instalação
mode-upgrade = Atualização de uma versão anterior
mode-reapply = Reinstalação da mesma versão
mode-unknown = Instalação
# Lower-case forms used inside a history row.
history-mode-fresh = primeira instalação
history-mode-upgrade = atualização
history-mode-reapply = reinstalação
history-mode-unknown = instalação

## Avisos na página inicial

notice-settings-reset-title = O Atlas está usando as configurações padrão do app
# $error is a raw error message (text).
notice-settings-unreadable = O Atlas não conseguiu ler as configurações salvas do app. Suas configurações do Windows não foram alteradas. Detalhes: { $error }
# $file is a file name (text).
notice-settings-damaged-kept = O arquivo de configurações do app estava danificado e foi redefinido. Uma cópia do arquivo antigo foi salva como { $file }. Detalhes: { $error }
notice-settings-damaged = O arquivo de configurações do app estava danificado. Por enquanto, o Atlas está usando os padrões. Detalhes: { $error }
notice-settings-not-saved-title = Não foi possível salvar as configurações do app
# $error is a raw error message (text).
notice-settings-not-saved = O Atlas não conseguiu salvar suas últimas alterações, então elas podem ser perdidas quando você fechar o Atlas. Se houver outra janela do Atlas aberta, feche-a e faça a alteração novamente. Detalhes: { $error }
notice-session-unreadable-title = Não foi possível verificar a instalação anterior
# $path is a file path (text).
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
# Accessible name of one step. $status is one of the stepper-status-* messages.
stepper-step-a11y = Etapa { $number } de { $total }, { $title }, { $status }
stepper-status-completed = concluída
stepper-status-current = etapa atual
stepper-status-upcoming = etapa pendente
# A step already visited whose requirements aren't met yet.
stepper-status-attention = requer atenção
# Heading above each step's content.
step-heading = Etapa { $number } de { $total }: { $title }
# Accessible name of the step heading on a screen of Your choices, read when it takes focus.
# $heading is step-heading; $progress is options-progress; $question is the screen's question.
step-heading-choice-a11y = { $heading }. { $progress }: { $question }
# The same on the optional extras screen; $progress is options-progress-extras.
step-heading-extras-a11y = { $heading }. { $progress }

## Etapa 1: Preparação

ready-banner-busy-title = Preparando seu PC
ready-banner-busy-message = O Atlas está verificando seu PC e preparando os arquivos de instalação.
ready-banner-blocked-title = Seu PC ainda não está pronto
ready-banner-blocked-message = Resolva os itens marcados em Verificações do PC e depois escolha Verificar novamente.
ready-banner-no-package-title = Baixe o Atlas para continuar
# "Installation files" is package-title, the first card; "Open package file" is package-open-file.
ready-banner-no-package-message = Baixe o Atlas no cartão Arquivos de instalação ou escolha Abrir arquivo de pacote se você já tem um pacote do Atlas (.apbx).
# Tester build: the bundled Atlas package couldn't be unpacked.
ready-banner-no-package-bundled-title = Prepare o pacote do Atlas incluído para continuar
ready-banner-no-package-bundled-message = O pacote do Atlas incluído nesta versão de teste ainda não está pronto. Confira o cartão Arquivos de instalação.
# Shown while updating Windows and Store apps is the next task (Get ready's last card,
# Update Windows and Store apps).
ready-banner-updates-title = Atualize o Windows e os apps da Store para continuar
# "Check and install updates" is prepare-start, the button on the update card.
ready-banner-updates-message = Escolha Buscar e instalar atualizações. Quando as atualizações terminarem, o Atlas verificará seu PC novamente.
# While Windows and Store apps update. "Update Windows and Store apps" is prepare-title, the
# card further down the page.
ready-banner-updating-title = Atualizando o Windows e os apps da Store
ready-banner-updating-message = Isso pode demorar. Mantenha o Atlas aberto. Você pode acompanhar o progresso no cartão Atualizar o Windows e os apps da Store.
# After Stop updating. "Check and install updates" is prepare-start, the card's button.
ready-banner-updates-stopped-title = Atualização interrompida
ready-banner-updates-stopped-message = Escolha Buscar e instalar atualizações no cartão Atualizar o Windows e os apps da Store para concluir.
# Atlas reopened after restarting the PC to continue updating. "Continue updates" is
# prepare-continue, the card's button.
ready-banner-updates-resumed-title = Seu PC foi reiniciado
ready-banner-updates-resumed-message = Escolha Continuar atualizações no cartão Atualizar o Windows e os apps da Store para concluir a atualização.
# Under prepare-failed-title or prepare-unconfirmed-title. "Try again" is common-try-again,
# the card's button.
ready-banner-updates-failed-message = Veja no cartão Atualizar o Windows e os apps da Store o que fazer e depois escolha Tentar novamente.
# Under prepare-reboot-title. "Restart and continue" is prepare-restart, the card's button.
ready-banner-reboot-message = Salve seu trabalho primeiro e depois escolha Reiniciar e continuar no cartão Atualizar o Windows e os apps da Store.
ready-banner-warnings-title = Alguns pontos para revisar
ready-banner-warnings-message = Você pode continuar, mas leia primeiro os itens marcados em Verificações do PC.
ready-banner-ok-title = Tudo pronto para fazer suas escolhas
ready-banner-ok-message = As verificações foram aprovadas e os arquivos de instalação estão prontos.
# Card title and accessible name of the list of checks.
ready-this-pc = Verificações do PC
ready-check-again = Verificar novamente
# The one line that stands for every check that passed; common-show-details opens them.
ready-checks-passed =
    { $count ->
        [one] { $count } verificação aprovada
       *[other] { $count } verificações aprovadas
    }
package-title = Arquivos de instalação
# $received and $total are formatted numbers of megabytes (text).
package-downloading = Baixando o Atlas { $version } · { $received } de { $total } MB
package-unpacking-progress =
    { $total ->
        [one] Extraindo · { $done } de { $total } arquivo
       *[other] Extraindo · { $done } de { $total } arquivos
    }
package-unpacking = Extraindo
package-looking = Verificando qual é a versão mais recente do Atlas.
# Tester build: the bundled Atlas package is being unpacked, nothing is downloaded.
package-looking-bundled = Preparando o pacote do Atlas incluído.
package-none = Baixe o Atlas para obter os arquivos de instalação. Se você já tem um pacote do Atlas (.apbx), abra-o em vez disso.
# The GitHub release check failed. "Baixar a versão mais recente" is package-download-newest,
# the button offered in this state; it checks again.
package-release-failed = O Atlas não conseguiu verificar qual é a versão mais recente. Confira sua conexão com a internet e escolha Baixar a versão mais recente ou abra um pacote do Atlas (.apbx) salvo no PC.
# Short status words beside the card title.
package-status-downloading = Baixando
package-status-unpacking = Extraindo
package-status-failed = Falha na preparação
package-status-ready = Pronto
package-status-checking = Verificando
package-status-preparing = Preparando
package-status-missing = Não baixado
# Accessible name of the progress bar.
package-progress = Progresso dos arquivos de instalação
package-download-again = Baixar novamente
package-download-version = Baixar o Atlas { $version }
package-download-newest = Baixar a versão mais recente
package-cancel-download = Cancelar download
package-open-file = Abrir arquivo de pacote
# Where the package came from. $file is a file name (text).
package-from-release = O Atlas { $version } foi baixado do GitHub e está pronto para instalar.
package-from-file = O Atlas { $version } foi carregado de { $file } e está pronto para instalar.
package-unpacked = O Atlas { $version } está pronto para instalar.
package-none-yet = Nenhum arquivo de instalação selecionado
acquire-no-asset = O Atlas { $version } não tem um arquivo de pacote para baixar. Abra um pacote do Atlas (.apbx) salvo no PC para continuar.
acquire-unsupported = Este app instala o Atlas 0.6.0 ou mais recente. Para instalar o Atlas { $version }, use o AME Wizard.
# A package new enough to include the installer script that this app drives, but without it.
acquire-incomplete = O Atlas { $version } não inclui alguns arquivos de que este app precisa para instalá-lo. Baixe-o novamente ou abra outro pacote do Atlas (.apbx).
acquire-failed = Não foi possível preparar os arquivos de instalação. Tente baixar novamente ou abra outro pacote do Atlas (.apbx). Detalhes: { $error }
# The download received nothing for a minute and was stopped.
acquire-stalled = O download parou de responder. Confira sua conexão com a internet e baixe novamente ou abra um pacote do Atlas (.apbx) salvo no PC.
# Tester build: the bundled Atlas package couldn't be unpacked. Try again is the only control offered.
acquire-failed-bundled = Não foi possível preparar o pacote do Atlas incluído. Escolha Tentar novamente. Detalhes: { $error }

## Verificações do sistema

check-administrator = Permissão para instalar
check-supported-build = Compatibilidade do Windows
check-pending-updates = Atualizações do Windows
check-pending-reboot = Reinicialização pendente
check-third-party-antivirus = Outro antivírus
check-internet = Conexão com a internet
check-power = Energia
check-activation = Ativação do Windows
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
# Opens Installed apps in Windows Settings, from the Other antivirus software check.
check-fix-apps = Abrir aplicativos instalados
# Check box the user ticks when the Windows Update scan could not run.
check-ack-updates = Verifiquei o Windows Update: não há atualizações aguardando instalação
detail-admin-ok = O Atlas tem permissão para fazer as alterações necessárias à instalação.
# The button "Reabrir como administrador" sits beside this line.
detail-admin-missing = O Atlas precisa de permissão de administrador para instalar. Escolha Reabrir como administrador e, quando o Windows pedir, escolha Sim.
# $builds is a list of build numbers such as "26100 ou 26200"; $build is this PC's (text).
detail-build-unsupported = Esta versão do Atlas requer o Windows na build { $builds }. Seu PC está na build { $build }. Instale uma versão compatível do Windows antes de continuar.
detail-build-missing = Este pacote do Atlas não indica nenhuma build compatível do Windows. Use uma versão completa do pacote em vez de uma versão LocalTest.
detail-updates-none = Não há atualizações do Windows aguardando instalação.
# $titles lists up to two update names (text); $count is the total. "Update Windows and
# Store apps" is prepare-title, the card that installs them.
detail-updates-pending =
    { $count ->
        [1] Há uma atualização pendente: { $titles }. O Atlas a instala no cartão Atualizar o Windows e os apps da Store.
        [2] Há duas atualizações pendentes: { $titles }. O Atlas as instala no cartão Atualizar o Windows e os apps da Store.
       *[other] Há { $count } atualizações pendentes, incluindo { $titles }. O Atlas as instala no cartão Atualizar o Windows e os apps da Store.
    }
detail-updates-unknown = Não foi possível verificar se há atualizações do Windows. Abra o Windows Update e, se não houver atualizações aguardando, confirme abaixo. ({ $error })
detail-reboot-none = O Windows não precisa ser reiniciado agora.
# "Check and install updates" is prepare-start, the button on the update card, which
# then asks for the restart before updating.
detail-reboot-pending = O Windows precisa reiniciar para concluir alterações anteriores. Quando você escolher Buscar e instalar atualizações, o Atlas pedirá que você reinicie primeiro.
# $reasons: the pending-restart markers Windows set, from the prepare-reason-* names.
detail-reboot-pending-reasons = O Windows precisa reiniciar para concluir alterações anteriores ({ $reasons }). Quando você escolher Buscar e instalar atualizações, o Atlas pedirá que você reinicie primeiro.
# Warning, not a block: $files lists up to three file paths Windows will replace or remove at the next restart.
detail-reboot-file-renames = Você pode continuar. O Windows tem arquivos para substituir ou remover na próxima reinicialização ({ $files }). Alguns apps, como o Xbox Gaming Services, fazem isso após cada reinicialização.
detail-reboot-unknown = Não foi possível verificar se o Windows precisa ser reiniciado. Reinicie o PC, reabra o Atlas e verifique novamente. ({ $error })
detail-antivirus-none = Nenhum outro antivírus foi detectado.
# $products is a list of product names (text). The row offers check-fix-apps.
detail-antivirus-found = Outros antivírus além do Microsoft Defender podem bloquear a instalação. Desinstale { $products } e depois escolha Verificar novamente.
# Warning, not a block: Security Center still lists the product but its files are gone.
detail-antivirus-stale = A Segurança do Windows ainda lista { $products }, mas os arquivos já não existem, então esse software não está mais instalado. O Atlas pode ser instalado mesmo assim.
detail-antivirus-unknown = Não foi possível verificar se há outro antivírus. Escolha Verificar novamente. Se continuar falhando, reinicie o PC e verifique novamente. ({ $error })
detail-internet-ok = Seu PC está conectado à internet. Mantenha a conexão enquanto o Atlas baixa e instala os programas.
detail-internet-missing = Conecte-se à internet e depois verifique novamente.
detail-power-mains = Seu PC está ligado na tomada. Mantenha-o assim até a instalação terminar.
detail-power-battery = Ligue o PC na tomada para que ele não desligue durante a instalação.
detail-power-unknown = O Atlas não conseguiu identificar se o PC está ligado na tomada. Se for um notebook, ligue-o na tomada e escolha Verificar novamente. Se isso continuar acontecendo, escolha Enviar um relato.
detail-activation-ok = O Windows está ativado. O Atlas não altera isso.
detail-activation-missing = O Windows não está ativado. Você pode continuar, mas o Atlas não ativará o Windows para você.
detail-activation-no-licence = O Windows não informou uma licença. Você pode continuar; o Atlas não altera o status da ativação.
detail-activation-unknown = Não foi possível verificar a ativação do Windows. Você pode continuar; o Atlas não altera o status da ativação. ({ $error })

## Etapa 2: Suas escolhas

options-progress = Escolha { $number } de { $total }
options-progress-extras = Escolha { $number } de { $total }: extras opcionais
# Beside "Choice N of M" on every screen of Your choices. It names only what the Atlas
# folder can change back; other choices, such as removing Microsoft Edge, can't be undone there.
options-change-later = Depois, você pode alterar o Microsoft Defender, as proteções do processador e as configurações de atualização na pasta Atlas da sua área de trabalho.
# Short names for each decision (summary rows) and the question each screen asks.
screen-defender-title = Microsoft Defender
screen-defender-question = Manter o Microsoft Defender?
screen-mitigations-title = Proteções do processador
screen-mitigations-question = Manter as proteções do Windows para o processador?
screen-updates-title = Windows Update
screen-updates-question = Como o Windows deve instalar as atualizações?
screen-browser-title = Navegador
screen-power-title = Energia e segurança
screen-apps-title = Apps
screen-optional-apps-title = Aplicativos opcionais
screen-choose-one-title = Escolha uma opção
screen-extras-title = Extras opcionais
# Question for a required choice this app has no specific wording for.
screen-generic-question = Escolha uma opção para { $title }
learn-more-defender = Saiba mais sobre o Microsoft Defender
learn-more-mitigations = Saiba mais sobre as proteções do processador
learn-more-updates = Saiba mais sobre o Windows Update
learn-more-browser = Saiba mais sobre navegadores
learn-more-power = Saiba mais sobre energia e segurança
learn-more-apps = Saiba mais sobre apps
learn-more-eclean = Como o eclean funciona com o AtlasOS
learn-more-generic = Ler o guia de configuração
# One line under the chosen answer: what it means for the PC.
consequence-defender-enable = Mantém o antivírus integrado do Windows para ajudar a proteger seu PC contra vírus e outras ameaças.
consequence-defender-disable = Também remove o SmartScreen. Seu PC ficará sem proteção antivírus até você instalar outro app antivírus, e o Windows não avisará antes de você abrir apps ou downloads não reconhecidos.
consequence-mitigations-default = Mantém as proteções padrão do Windows contra falhas do processador e contra ataques que exploram erros em apps.
# Under Turn off processor protections. "Exploit protection" is the Windows Security page
# of that name; use the name Windows shows in your language.
consequence-mitigations-disable = Também desativa a Proteção contra vulnerabilidades para apps, como a Proteção de fluxo de controle (CFG). Isso reduz a segurança. Qualquer diferença de desempenho depende do seu processador.
consequence-auto-updates-disable = Abra o Windows Update regularmente para instalar as atualizações. As notificações de atualização continuam ativadas.
consequence-auto-updates-default = O Windows instalará as atualizações automaticamente, incluindo correções de segurança.

## Texto do pacote do Atlas
## The Atlas package carries its own English text for each option. These
## UI labels and explanations are used only when the package text matches
## i18n/playbook-source.ftl. A future package with different wording keeps
## its own text instead of receiving a potentially outdated description.

playbook-option-defender-enable = Manter o Microsoft Defender (recomendado)
playbook-option-defender-disable = Remover o Microsoft Defender
playbook-option-mitigations-default = Manter as proteções do processador (recomendado)
playbook-option-mitigations-disable = Desativar as proteções do processador
playbook-option-auto-updates-disable = Instalar atualizações manualmente
playbook-option-auto-updates-default = Instalar atualizações automaticamente
playbook-option-disable-hibernation = Desativar a hibernação
playbook-option-disable-power-saving = Desativar a economia de energia
playbook-option-disable-core-isolation = Desativar a segurança baseada em virtualização (VBS)
# "Ferramenta de Captura" is the Windows pt-BR name of Snipping Tool.
playbook-option-remove-snipping-tool = Remover a Ferramenta de Captura
playbook-option-uninstall-edge = Remover o Microsoft Edge
playbook-option-install-another-browser = Instalar um navegador
playbook-option-install-toolbox = Instalar o Atlas Toolbox
playbook-option-install-eclean = Instalar eclean
playbook-option-browser-brave = Brave
playbook-option-browser-librewolf = LibreWolf
playbook-option-browser-firefox = Firefox
playbook-option-browser-chrome = Chrome
playbook-page-defender-enable-description = O Microsoft Defender é o antivírus integrado do Windows. Remova-o apenas se você entender os riscos e pretender usar outro app antivírus. Seja qual for sua escolha, o Atlas desativa o Controle Inteligente de Aplicativos, a Proteção aprimorada contra phishing e o recurso Localizar meu dispositivo.
playbook-page-mitigations-default-description = Essas proteções, também chamadas de mitigações de segurança, ajudam a defender o PC contra falhas do processador, como Spectre e Meltdown, e contra ataques que exploram erros em apps. É recomendável manter os padrões do Windows.
playbook-page-auto-updates-disable-description = As atualizações do Windows incluem correções de segurança. Você pode deixar que o Windows as instale automaticamente ou instalá-las por conta própria. Em ambos os casos, o Atlas mantém o Windows na versão atual, que só recebe correções de segurança até a Microsoft encerrar o suporte a ela. O Atlas também desativa as atualizações automáticas dos apps da Microsoft Store, então atualize-os pela Microsoft Store.
playbook-page-browser-brave-description = Escolha um navegador para instalar. O Atlas não altera as configurações do navegador.

## Etapa 3: Segurança do Windows

security-banner-reading-title = Verificando a Segurança do Windows
security-banner-reading-message = O Atlas está verificando as quatro proteções abaixo.
security-banner-off-title = As quatro proteções estão desativadas
# Shown instead of the switch list when an earlier Atlas install removed Microsoft Defender.
security-banner-absent-title = O Microsoft Defender não está instalado neste PC
security-banner-absent-message = Não há nada para desativar nesta etapa. Escolha Continuar.
security-banner-off-message = Escolha Continuar para revisar sua configuração e instalar o Atlas.
security-banner-on-title = Desative a proteção antivírus na Segurança do Windows
security-banner-on-message = O Microsoft Defender pode bloquear as alterações que o Atlas faz. Escolha Abrir a Segurança do Windows e desative cada proteção listada abaixo. Se você mantiver o Microsoft Defender, reative as proteções quando a instalação terminar.
# The page name in Windows Security.
security-list-title = Configurações de proteção contra vírus e ameaças
# The invariant toggle words Windows Security itself shows under each switch.
security-switch-off = Desativado
security-switch-on = Ativado
security-switch-unreadable = Não foi possível verificar
security-switch-reading = Verificando
security-all-off = Todas desativadas
# Accessible name of a switch row. $state is one of the security-switch-* messages.
security-a11y = { $title }: { $state }
# Parts of the summary "2 ainda ativadas, 1 não pôde ser verificada".
security-count-still-on =
    { $count ->
        [one] { $count } ainda ativada
       *[other] { $count } ainda ativadas
    }
security-count-unreadable =
    { $count ->
        [one] { $count } não pôde ser verificada
       *[other] { $count } não puderam ser verificadas
    }
security-count-join = { $a }, { $b }
security-unknown-title = Confirme as proteções que o Atlas não conseguiu verificar
security-unknown-message = Verifique na Segurança do Windows se as quatro proteções estão desativadas e depois confirme abaixo.
security-acknowledge = Verifiquei na Segurança do Windows que as quatro proteções estão desativadas
security-unknown-unelevated-title = O Atlas precisa de permissão para verificar a proteção
# The button "Reabrir como administrador" sits beside this line.
security-unknown-unelevated-message = Reabra o Atlas como administrador para que ele consiga ler as configurações do Microsoft Defender.
# The four switches, named as Windows Security names them in Brazilian Portuguese.
protection-tamper = Proteção contra violações
protection-tamper-why = Desative esta proteção para que o Defender não impeça o Atlas de alterar as configurações de segurança do próprio Defender.
protection-realtime = Proteção em tempo real
protection-realtime-why = Desative esta proteção para que o Defender não bloqueie os arquivos de instalação do Atlas ao verificá-los.
protection-cloud = Proteção fornecida pela nuvem
protection-cloud-why = Desative esta proteção para que as verificações de ameaças online não bloqueiem os arquivos de instalação do Atlas.
protection-samples = Envio automático de amostra
protection-samples-why = Impeça que o Defender envie automaticamente arquivos do Atlas à Microsoft para análise.

## Etapa 4: Instalação

# Accessible name of the progress bar.
install-progress = Progresso da instalação
# The installation's progress shown beside the bar. $percent is a whole number from 0 to 99.
install-percent = { $percent }%
outcome-succeeded-title = O Atlas foi instalado
outcome-lost-title = Não foi possível confirmar o resultado da instalação
outcome-failed-title = A instalação não foi concluída
outcome-requirements = Seu PC não atendeu aos requisitos de instalação. Nenhuma alteração foi feita. Volte à etapa Preparação e execute as verificações novamente.
# The -resumed variants follow a retry of an installation an earlier attempt had already started applying.
outcome-requirements-resumed = Seu PC não atendeu aos requisitos de instalação, então esta tentativa parou. Uma tentativa anterior já começou a fazer alterações. Volte à etapa Preparação e execute as verificações novamente.
outcome-not-elevated = O Atlas não tinha permissão de administrador. Nenhuma alteração foi feita. Reabra o Atlas como administrador e tente novamente.
outcome-not-elevated-resumed = O Atlas não tinha permissão de administrador, então esta tentativa parou. Uma tentativa anterior já começou a fazer alterações. Reabra o Atlas como administrador e tente novamente.
# The installer's live check found Windows or Store updates unfinished. Preparação offers the
# update check again; "Buscar e instalar atualizações" is prepare-start, its button in that state.
outcome-preparation-stale = O Atlas não conseguiu confirmar se o Windows e os apps da Store estão atualizados, então a instalação parou antes de alterar o Windows. Volte à etapa Preparação e escolha Buscar e instalar atualizações.
outcome-preparation-stale-resumed = O Atlas não conseguiu confirmar se o Windows e os apps da Store estão atualizados, então esta tentativa parou. Uma tentativa anterior já começou a fazer alterações. Volte à etapa Preparação e escolha Buscar e instalar atualizações.
outcome-failed-preflight = A instalação parou antes de alterar qualquer coisa. Você pode tentar novamente. Se ela parar de novo, escolha Enviar um relato.
outcome-failed-staging = A instalação parou durante a preparação dos arquivos, antes de alterar o Windows. Você pode tentar novamente. Se ela parar de novo, escolha Enviar um relato.
outcome-failed-applying = Algumas alterações podem já ter sido feitas. Você pode tentar novamente. Se você parar por aqui, reative na Segurança do Windows as proteções que desativou, caso ainda estejam disponíveis.
outcome-failed-resumed = Esta tentativa parou no início, mas uma tentativa anterior já começou a fazer alterações. Você pode tentar novamente. Se você parar por aqui, reative na Segurança do Windows as proteções que desativou, caso ainda estejam disponíveis.
outcome-not-started = O instalador não iniciou a tempo. Nenhuma alteração foi feita. Você pode tentar novamente.
outcome-lost = O instalador parou sem informar um resultado, e algumas alterações podem já ter sido feitas. Você pode tentar novamente. Se você parar por aqui, reative na Segurança do Windows as proteções que desativou, caso ainda estejam disponíveis.
restart-now-message = O Windows está reiniciando para concluir a configuração do Atlas.
# "Restart later" is restart-dont-now, the button under it.
restart-countdown =
    { $seconds ->
        [one] O Windows reinicia em { $seconds } segundo para concluir a configuração do Atlas. Para salvar seu trabalho antes, escolha Reiniciar depois.
       *[other] O Windows reinicia em { $seconds } segundos para concluir a configuração do Atlas. Para salvar seu trabalho antes, escolha Reiniciar depois.
    }
restart-stopped = Reinicialização automática cancelada. Salve seu trabalho e depois reinicie o PC para concluir a configuração do Atlas.
restart-needed = Salve seu trabalho e depois reinicie o PC para concluir a configuração do Atlas.
restart-dont-now = Reiniciar depois
restart-now = Reiniciar agora
restart-start-failed = O Atlas não conseguiu reiniciar seu PC. Salve seu trabalho e reinicie-o pelo menu Iniciar. Detalhes: { $error }
preflight-title = A instalação não começou
preflight-invalid-options = O Atlas não conseguiu usar essas escolhas de configuração. Volte à etapa Suas escolhas, revise-as e tente novamente. Detalhes: { $error }
# $problems is a sentence or two built from preflight-problem and preflight-security.
preflight-changed = O estado do seu PC mudou desde as verificações anteriores. Resolva o seguinte antes de tentar novamente. { $problems }
preflight-problem = { $title }: { $detail }
# $summary is the Windows Security summary such as "2 ainda ativadas".
preflight-security = Segurança do Windows: { $summary }.
# "Install Atlas" is button-install: after a refusal the footer's button always reads it.
preflight-busy = Outra janela do Atlas está iniciando uma instalação. Aguarde um momento e escolha Instalar o Atlas novamente.
# Shown with the home-start-over button.
preflight-taken-over = Outra janela do Atlas está usando esta configuração agora, então a instalação não começou. Continue naquela janela ou escolha Começar de novo para refazer a configuração aqui.
preflight-record-unreadable = O Atlas não conseguiu verificar se a instalação anterior ainda está em andamento, então não iniciou outra. Volte à etapa Preparação para ver o que fazer em seguida. Detalhes: { $error }
# "Install Atlas" is button-install: after a refusal the footer's button always reads it.
# "Send a report" is report-title, in the diagnostics under the bar.
preflight-refused = Não foi possível iniciar o instalador. Nenhuma alteração foi feita. Escolha Instalar o Atlas para tentar novamente. Se isso continuar acontecendo, escolha Enviar um relato. Detalhes: { $error }
# Instead of preflight-refused when retrying an installation an earlier attempt had already
# started applying. "Install Atlas" is button-install, as for preflight-refused.
preflight-refused-resumed = Não foi possível iniciar o instalador, então esta tentativa parou. Uma tentativa anterior já começou a fazer alterações. Escolha Instalar o Atlas para tentar novamente. Se isso continuar acontecendo, escolha Enviar um relato. Detalhes: { $error }
go-to-ready = Voltar à etapa Preparação
# Button on the preflight banner when the setup choices could not be used; leads to step 2.
go-to-options = Voltar à etapa Suas escolhas
# Replaces Continue on a choice opened from a Change link on the Install step, while Continue leads straight back there.
go-to-install = Voltar à etapa Instalação
output-problem-title = Não foi possível ler o progresso da instalação
output-problem-message = O Atlas não conseguiu ler o log. Isso não significa que a instalação parou. Mantenha o PC ligado e tente abrir o arquivo de log. Detalhes: { $error }
install-elevate-title = O Atlas precisa de permissão para instalar
install-no-package-title = Escolha os arquivos de instalação primeiro
install-no-package-message = Volte à etapa Preparação para baixar o Atlas ou abrir um pacote do Atlas (.apbx) salvo no PC.
# Tester build variant of install-no-package-message.
install-no-package-bundled-message = Volte à etapa Preparação para preparar o pacote do Atlas incluído nesta versão de teste.
# Step 4 when step 1 is incomplete for this session (checks or Windows updates), with go-to-ready as the button.
install-not-ready-title = Conclua a etapa Preparação primeiro
install-not-ready-message = O Atlas precisa terminar de verificar seu PC e atualizar o Windows antes de instalar.
install-security-title = Confira a proteção antivírus antes de instalar
install-security-reading = Verificando as quatro proteções novamente.
install-security-message = { $summary }. Abra a Segurança do Windows e verifique se as quatro proteções estão desativadas antes de instalar.
summary-try-again = Revise antes de tentar novamente
summary-ready = Revise sua configuração do Atlas
summary-activation = Ativação
summary-activation-ok = Ativado. O Atlas não altera isso.
summary-activation-missing = Não ativado. Você pode continuar, mas o Atlas não ativará o Windows.
summary-activation-unknown = O Atlas não altera o status de ativação do Windows.
summary-duration = Tempo estimado
summary-duration-value =
    { $minutes ->
        [one] { $minutes } minuto, depois uma reinicialização
       *[other] { $minutes } minutos, depois uma reinicialização
    }
summary-restart-checkbox = Reiniciar meu PC automaticamente após a instalação
summary-show-command = Mostrar comando de instalação
summary-hide-command = Ocultar comando de instalação
# Accessible name of the Copy button under the installation command.
summary-copy-command-a11y = Copiar comando de instalação
summary-command-unavailable = Não foi possível preparar o comando de instalação. Detalhes: { $error }
summary-not-chosen = Nenhuma escolha feita ainda
# Accessible name of a Change link. $title is a screen-*-title message.
summary-change-a11y = Alterar { $title }
footer-still-checking = Preparando a instalação
footer-fix-items = Resolva os itens em Verificações do PC para continuar
footer-need-package = Baixe o Atlas ou abra um pacote do Atlas para continuar
# Tester build variant of footer-need-package.
footer-need-package-bundled = Prepare o pacote do Atlas incluído para continuar
footer-reading-security = Verificando as proteções
# Windows Security footer hints: while a switch is on, then while only switches Atlas
# couldn't read are left to confirm.
footer-security-pending = Desative as quatro proteções para continuar
footer-security-confirm = Para continuar, confirme as proteções que o Atlas não conseguiu verificar
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

installing-checking-title = Uma última verificação
installing-checking-line = O Atlas está verificando seu PC antes de fazer alterações. Isso pode levar um momento.
installing-title = Instalando o Atlas
installing-phase-preflight = Verificando seu PC e preparando os arquivos de instalação.
installing-phase-staging = Preparando os arquivos de instalação. Mantenha o PC ligado.
installing-phase-applying = Configurando o Windows com suas escolhas. Mantenha o PC ligado e na tomada.
installing-phase-done = Concluindo a instalação. Mantenha o PC ligado.
installing-installed-title = O Atlas foi instalado
# $time is a formatted clock time.
installing-started-just-now = Início às { $time }, há menos de um minuto
installing-started-minutes =
    { $minutes ->
        [one] Início às { $time }, há um minuto
       *[other] Início às { $time }, há { $minutes } minutos
    }
# Under the progress bar while installing, when the PC is set to restart by itself after.
installing-restart-auto = Seu PC será reiniciado automaticamente quando a instalação terminar. Antes disso, salve seu trabalho nos outros apps.

## A janela "O Atlas foi instalado" após a reinicialização

installed-title-version = O Atlas { $version } foi instalado
installed-title = O Atlas foi instalado
installed-ready = Tudo certo. Seu PC já está pronto para usar com o Atlas.
# After an installation that kept Microsoft Defender, under home-security-reminder-title.
# $switches names the switches that read off, as Windows Security names them, joined like a list.
installed-security-message = Você manteve o Microsoft Defender, mas parte da proteção dele ainda está desativada. Abra a Segurança do Windows e verifique se estas proteções estão ativadas: { $switches }.
# After an installation that removed Microsoft Defender.
installed-defender-removed-title = O Microsoft Defender foi removido
# After an installation that removed Microsoft Defender (and SmartScreen with it).
installed-defender-removed-message = Seu PC ficará sem proteção antivírus até você instalar outro app antivírus. O SmartScreen também foi removido, então o Windows não avisará antes de você abrir apps ou downloads não reconhecidos.
# Home and the "Atlas is installed" window, after an installation that kept Microsoft Defender,
# when it is missing. Its title is security-banner-absent-title; "Report a problem" is
# home-report-problem, its button.
installed-defender-missing-message = Você escolheu manter o Microsoft Defender, mas ele não foi encontrado. Se você não usa outro app antivírus, instale um para proteger seu PC. Se não foi você que removeu o Defender, escolha Relatar um problema.

## Configurações

settings-title = Configurações
settings-theme = Tema do app
settings-theme-system = Igual ao Windows
settings-theme-light = Claro
settings-theme-dark = Escuro
settings-theme-contrast-note = O Atlas está usando as cores do tema de contraste do Windows.
settings-theme-mica-note = Para mostrar o fundo translúcido, escolha o mesmo tema claro ou escuro do Windows.
settings-language = Idioma
settings-language-system = Igual ao Windows
# What the closed language box shows while Match Windows is chosen. $language is the
# name, in its own language, of the language Match Windows gives, for example
# "English (United Kingdom)". Use your language's brackets.
settings-language-system-selected = { settings-language-system } ({ $language })
# Under the language box while a particular language is chosen: what Match Windows
# would give instead. $language is a language's own name.
settings-language-system-detail = Com “Igual ao Windows”: { $language }
# A short tag after each language in the list that is translated but not yet reviewed
# by a native speaker.
settings-language-preview-tag = Versão prévia
# Under the language box, once, explaining the Preview tag.
settings-language-preview-note = As traduções em versão prévia ainda não foram revisadas por um falante nativo.
# A bar at the top of the content while a preview translation is in use, until the user
# dismisses it (common-dismiss names its close button). $language is the language's own
# name; preview-notice-switch and preview-notice-language are its links.
preview-notice = { $language } é uma tradução em versão prévia e pode conter erros.
preview-notice-switch = Mudar para inglês
preview-notice-language = Alterar idioma
# $tag is a language tag (text).
settings-language-unavailable = { $tag } não está disponível nesta versão do Atlas. Por enquanto, o inglês é exibido, e sua escolha de idioma foi salva.
# $languages is the Windows display-language list (text).
settings-language-windows-unmatched = O Atlas ainda não tem suporte aos seus idiomas de exibição do Windows ({ $languages }). Por enquanto, o inglês é exibido.
settings-language-windows-unavailable = Não foi possível verificar o idioma de exibição do Windows. Por enquanto, o Atlas está em inglês. Detalhes: { $error }
# $locale is the regional format's own name, for example "Português (Brasil)".
settings-language-formats = Números, datas e horas seguem o formato regional do Windows ({ $locale }).
# Instead of settings-language-formats when the regional format writes dates or times
# right to left. $locale is the format's English name, for example "Arabic (Saudi Arabia)".
settings-language-formats-numbers-only = Números seguem o formato regional do Windows ({ $locale }). Datas e horas usam um formato padrão porque o Atlas ainda não consegue exibir texto da direita para a esquerda.
# Link to the i18n folder on GitHub.
settings-language-contribute = Ajudar a traduzir o Atlas no GitHub
settings-restart-label = Reiniciar meu PC automaticamente após a instalação
settings-restart-locked = Você poderá alterar isso quando a instalação terminar.
settings-restart-description = Quando esta opção está ativada, seu PC é reiniciado até um minuto depois que a instalação termina, o que fecha os apps abertos. Salve seu trabalho antes de instalar.
# Card title over Send a report and Export diagnostics.
settings-help = Ajuda e comentários
settings-about = Sobre
settings-about-app = Atlas Manager
settings-about-licence = Licença
settings-about-licence-value = GPL-3.0, gratuito e de código aberto
settings-view-source = Ver código-fonte no GitHub
# Link that opens the third-party licence notices.
settings-view-licences = Ver avisos de licença
# Under the links when Windows could not open the notices.
settings-licences-failed = Não foi possível abrir os avisos de licença. Tente novamente ou encontre-os no código-fonte, no GitHub.
settings-open-data-folder = Abrir pasta do app

## Optional choices: explanations shown before selection.

consequence-disable-hibernation = Libera o espaço em disco usado para salvar a sessão durante a hibernação. A hibernação e a inicialização rápida ficarão indisponíveis.
consequence-disable-power-saving = Desativa os recursos de economia de energia. O PC pode consumir mais energia, esquentar mais e ter menos autonomia de bateria.
consequence-disable-core-isolation = Desativa uma camada extra de segurança do Windows, incluindo a integridade da memória. Isso reduz a proteção e pode afetar apps ou jogos que exigem esse recurso.
consequence-remove-snipping-tool = Remove o app do Windows para capturas e gravações de tela.
consequence-uninstall-edge = Remove o navegador Microsoft Edge. Tenha outro navegador instalado ou escolha um abaixo.
# Instead of consequence-uninstall-edge when Atlas is installed on this PC, which has the
# user's Edge data. "choose one below" refers to the browser choice under it.
consequence-uninstall-edge-data = Remove o Microsoft Edge e exclui os favoritos, o histórico e as senhas salvas do Edge neste PC. Tudo o que não estiver sincronizado com sua conta Microsoft será perdido. Confira se você tem outro navegador ou escolha um abaixo.
# Under Remove Microsoft Edge in the Install step's summary, with a caution glyph.
caution-uninstall-edge = Exclui os favoritos, o histórico e as senhas salvas do Edge neste PC.
consequence-install-another-browser = Escolha um navegador abaixo e o Atlas o instalará para você.
consequence-install-toolbox = Adicione o Atlas Toolbox para ajudar a gerenciar as configurações do Atlas. O Toolbox está em beta, então alguns recursos podem estar incompletos.
consequence-install-eclean = Uma ferramenta de manutenção da equipe do AtlasOS para manter seu PC organizado após a configuração. Revise arquivos desnecessários e aplicativos de inicialização. Requer uma conta e conexão com a internet.

# Introduction on the home page before Atlas is installed.
home-intro = O Atlas ajusta o Windows para reduzir a atividade em segundo plano e as distrações. Instale o Atlas em uma instalação limpa do Windows, antes de adicionar seus próprios apps e arquivos.

## ISO creation (Beta)
iso-home-title = Mídia de instalação do Windows
iso-home-description = Crie um arquivo de instalação do Windows (ISO) que inclua o Atlas e use-o para reinstalar o Windows neste PC ou em outro.
iso-open = Criar uma ISO com o Atlas
iso-title = Criar uma ISO com o Atlas
iso-beta = Beta
iso-beta-description = Teste a ISO em uma máquina virtual antes de usá-la em um PC. Faça backup dos seus arquivos antes de instalar o Windows.
# "Relaunch as administrator" is common-restart-as-administrator.
iso-admin-description = O Atlas precisa de permissão de administrador para ler sua ISO do Windows e criar a nova. Escolha Reabrir como administrador e, quando o Windows pedir, escolha Sim.
iso-files-description = O Atlas faz uma cópia de uma ISO do Windows 11 com o Atlas incluído, para reinstalar o Windows. Escolha uma ISO do Windows 11 baixada da Microsoft, baixe o pacote do Atlas mais recente ou escolha um que você já tenha (.apbx) e depois escolha onde salvar a nova ISO.
# Tester build: no package picker.
iso-files-description-bundled = O Atlas faz uma cópia de uma ISO do Windows 11 e adiciona a ela o pacote do Atlas incluído nesta versão de teste. Escolha uma ISO do Windows 11 baixada da Microsoft e depois escolha onde salvar a nova ISO.
iso-source = ISO do Windows
# Link under the Windows ISO field. It opens Microsoft's Windows 11 download page in the browser.
iso-source-download = Baixar o Windows 11 da Microsoft
# $minimum is the first Atlas version that can be used (text, such as 0.6.0).
iso-package = Pacote do Atlas ({ $minimum } ou mais recente)
iso-output = Salvar a nova ISO em
iso-no-file = Nenhum arquivo selecionado
iso-browse = Procurar
iso-save-as = Salvar como
# Accessible name of the Browse or Save as button beside a file field: $action is
# that button's text and $field the field's label.
iso-pick-a11y = { $action }: { $field }
iso-inspect = Verificar arquivos
# The question above the three ways to set up Atlas from the ISO (iso-mode-*).
iso-mode-title = Como você quer configurar o Atlas?
iso-mode-interactive = Fazer as escolhas do Atlas após entrar
iso-mode-interactive-description = Depois que você entrar na sua conta, o Atlas abre e orienta você nas atualizações, nas suas escolhas e na instalação do Atlas.
iso-mode-before = Fazer as escolhas do Atlas agora
iso-mode-before-description = O Atlas salva suas escolhas na ISO. Depois que você entrar na sua conta, o Atlas abre e orienta você nas atualizações. Em seguida, você instala o Atlas com essas escolhas.
iso-package-unsupported-title = Escolha um pacote do Atlas mais recente
# "Fazer as escolhas do Atlas após entrar" is iso-mode-interactive.
iso-package-unsupported = Este pacote do Atlas não permite salvar as escolhas do Atlas na ISO. Escolha um pacote mais recente ou escolha Fazer as escolhas do Atlas após entrar.
# Shown when Check files refuses the Atlas package; $minimum as for iso-package.
iso-failed-package-unsupported = Este pacote do Atlas não pode ser usado para criar uma ISO. Escolha um pacote do Atlas { $minimum } ou mais recente.
# Tester build: the bundled package cannot be swapped, so the only way on is the after-sign-in
# mode. Also the Your choices footer hint for any package that can't save choices.
iso-package-unsupported-bundled-title = As escolhas do Atlas não podem ser salvas nesta ISO
# "Fazer as escolhas do Atlas após entrar" is iso-mode-interactive.
iso-package-unsupported-bundled = O pacote do Atlas incluído nesta versão de teste não tem suporte à instalação por ISO. Em vez disso, escolha Fazer as escolhas do Atlas após entrar.
iso-atlas-options = Escolhas do Atlas
iso-review = Revisar ISO
iso-review-description = Criar a ISO não instala nada neste PC nem altera sua ISO original. Depois, o Atlas pode gravar a nova ISO em uma unidade USB para você reinstalar o Windows a partir dela.
iso-review-files = Arquivos
# Titles of the ISO steps in its stepper and step headings. The other two are
# iso-review-files ("Files") and step-options ("Your choices").
iso-step-windows = Instalação do Windows
iso-step-review = Revisão
iso-review-package = Pacote do Atlas
iso-review-output = Nova ISO
iso-review-editions = Edições
iso-architecture-x64 = x64
iso-architecture-arm64 = Arm64
# A file size; $size is a formatted number (text). Megabytes below a gigabyte.
size-megabytes = { $size } MB
size-gigabytes = { $size } GB
iso-review-account = Nome da conta
iso-review-target = Instalar em
iso-review-drivers = Drivers
iso-create = Criar ISO
# Heading above the list of stages (iso-stage-*) while the ISO is being created.
iso-progress-title = Criando sua ISO
iso-stage-inspect = Verificando sua ISO do Windows
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
iso-progress-description = Mantenha o Atlas aberto. Imagens grandes podem demorar para serem processadas.
iso-cancel = Cancelar criação
iso-cancelling = Aguardando um ponto seguro para cancelar
iso-cancelled = Criação da ISO cancelada
# "Open log folder" is iso-diagnostics, the button on the same bar.
iso-cancelled-description = Sua ISO original não foi alterada. Se sobraram arquivos temporários, escolha Abrir pasta de logs para ver onde eles estão.
iso-complete = Sua ISO está pronta
# "Create installation USB" is usb-title, the button below it.
iso-complete-description = A criação de ISO está em beta, então teste a ISO em uma máquina virtual primeiro. Depois, escolha Criar USB de instalação e faça backup dos seus arquivos antes de reinstalar o Windows.
iso-open-folder = Mostrar na pasta
iso-failed = Não foi possível concluir a criação da ISO
# "Create ISO" is iso-create; "Send a report" is report-title.
iso-failed-description = Confira se seus arquivos ainda estão onde você os escolheu e se a unidade de destino está conectada. Depois, escolha Criar ISO. Se continuar falhando, escolha Enviar um relato.
# Title while the Check files step fails; the messages below say why.
iso-check-failed = Não foi possível verificar os arquivos
# "Check files" is iso-inspect; "Send a report" is report-title.
iso-check-failed-description = Confira se a ISO e o pacote do Atlas ainda estão onde você os escolheu e se o download deles terminou. Depois, escolha Verificar arquivos. Se continuar falhando, escolha Enviar um relato.
# Title of the bar that asks for administrator permission. Its message is iso-admin-description,
# or elevation-declined after Windows refused the relaunch (UAC declined).
iso-elevation-title = O Atlas precisa de permissão para criar uma ISO
# Typed reasons reported by the image worker.
iso-failed-output-exists = Já existe um arquivo com esse nome. Escolha Salvar como e digite um novo nome de arquivo.
iso-failed-destination = O Atlas não pode salvar a nova ISO nesse local. Escolha Salvar como e selecione uma pasta neste PC, como Downloads. Não é possível usar locais de rede nem unidades formatadas em FAT32 ou exFAT, como muitas unidades USB.
iso-failed-space = Não há espaço livre suficiente na unidade de destino. Libere espaço ou salve a nova ISO em outra unidade.
# Home and LTSC are the editions ISO creation drops; the others are examples it keeps.
iso-failed-edition = Esta ISO não contém nenhuma edição compatível do Windows. O Windows Home e o LTSC não são compatíveis. Use uma ISO que inclua outra edição, como Pro, Education ou Enterprise.
iso-failed-customised = Esta ISO já contém arquivos de instalação personalizados, como autounattend.xml. Escolha uma ISO original do Windows fornecida pela Microsoft.
iso-failed-windows-unsupported = Esta imagem do Windows não é compatível com o pacote do Atlas. Use uma ISO original de 64 bits de uma versão do Windows 11 compatível com este pacote.
iso-failed-network-architecture = Os drivers de rede deste PC não são compatíveis com a arquitetura desta ISO. Volte e desmarque a opção Incluir os drivers de rede deste PC ou escolha uma ISO para este PC.
# Shown instead of the messages that point at diagnostics when the folder the
# worker runs from couldn't be created. "Export diagnostics" is diagnostics-export.
iso-failed-unstaged = O Atlas não conseguiu preparar a pasta de trabalho, então nada foi alterado. Tente novamente. Se continuar falhando, escolha Exportar diagnóstico para um relatório de erro.
# The Atlas package file was replaced between Check files and Create ISO. "Change" is
# common-change beside "Files" (iso-review-files); "Check files" is iso-inspect.
iso-failed-package-changed = O pacote do Atlas mudou depois que os arquivos foram verificados. Escolha Alterar ao lado de Arquivos e depois escolha Verificar arquivos.
# Opens the folder with an ISO or USB job's raw logs.
iso-diagnostics = Abrir pasta de logs
iso-close-title = A ISO ainda está sendo criada
iso-close-message = Mantenha esta janela aberta até a criação ou o cancelamento terminar. O cancelamento aguarda um ponto em que a operação atual possa parar com segurança.
iso-keep-open = Manter aberta
prepare-title = Atualizar o Windows e os apps da Store
# Notepad, Paint and Windows Terminal are examples of Store apps that may be open. Use their
# names as Windows shows them in your language.
prepare-description = Antes da instalação, o Atlas atualiza o Windows, a Microsoft Store e seus apps da Store. Os apps da Store que estiverem abertos, como o Bloco de Notas, o Paint ou o Terminal do Windows, podem ser fechados durante a atualização, então salve seu trabalho neles primeiro. Talvez também seja preciso reiniciar o PC.
prepare-complete = O Atlas não encontrou mais atualizações do Windows ou da Store para instalar.
# Title of the bar on the update card when Windows needs a restart; prepare-reboot is its message.
prepare-reboot-title = Reinicie o PC para continuar
prepare-reboot = Seu PC precisa ser reiniciado para concluir a instalação das atualizações. O Atlas salva as escolhas feitas até agora e abre novamente depois que você entrar na sua conta.
# $reasons: the pending-restart markers Windows set, from the prepare-reason-* names.
prepare-reboot-reasons = Seu PC precisa ser reiniciado para concluir a instalação das atualizações ({ $reasons }). O Atlas salva as escolhas feitas até agora e abre novamente depois que você entrar na sua conta.
# Under the restart message, before its button, which restarts the PC without a countdown.
prepare-reboot-save-work = Salve seu trabalho e feche seus apps primeiro. Seu PC será reiniciado imediatamente quando você escolher Reiniciar e continuar.
# Shown instead of another restart when Windows asks for one again right after restarting.
prepare-restart-persists = Seu PC foi reiniciado, mas o Windows ainda indica que precisa reiniciar ({ $reasons }), então reiniciar de novo provavelmente não vai adiantar. Escolha Abrir o Windows Update e conclua o que estiver aguardando lá. Depois, escolha Tentar novamente. Se não houver nada aguardando, escolha Enviar um relato.
# Names of the markers Windows sets when it wants a restart. They complete
# "Seu PC precisa ser reiniciado para concluir a instalação das atualizações (…)" and
# "O Windows precisa reiniciar para concluir alterações anteriores (…)"; keep them short and lower case.
prepare-reason-servicing = manutenção do Windows
prepare-reason-windows-update = Windows Update
prepare-reason-file-renames = arquivos aguardando substituição
prepare-reason-update-agent = o serviço do Windows Update
prepare-reason-unknown = motivo não informado
# Under prepare-failed-title. "Try again" is common-try-again, the button beside it;
# "Send a report" is report-title, in the diagnostics under it.
prepare-failed = Escolha Tentar novamente. Se falhar de novo, conclua as atualizações restantes no Windows Update ou na Microsoft Store, ou escolha Enviar um relato.
# Title of the error bar on the update card; the cause is its message.
prepare-failed-title = Algumas atualizações não foram concluídas
# The update run ended without writing any result, for example after Atlas was closed
# while it ran. "Try again" is common-try-again, the button beside it.
prepare-ended-unconfirmed = A atualização parou antes de informar um resultado, então o Atlas não consegue confirmar se o Windows e os apps da Store estão atualizados. Escolha Tentar novamente para buscar atualizações.
# Title of the bar over prepare-ended-unconfirmed: not called a failure, as none was reported.
prepare-unconfirmed-title = Não foi possível confirmar o resultado da atualização
# "Buscar e instalar atualizações" is prepare-start, its button in this state.
prepare-cancelled = A atualização foi interrompida. Algumas atualizações podem já ter sido instaladas. Escolha Buscar e instalar atualizações para concluir antes de continuar.
prepare-windows-search = Buscando atualizações do Windows…
prepare-windows-download = Baixando atualizações do Windows…
prepare-windows-install = Instalando atualizações do Windows…
prepare-store-search = Verificando a Microsoft Store…
prepare-store-install = Atualizando a Microsoft Store e seus apps…
prepare-stop-description = As atualizações serão interrompidas quando a etapa atual terminar. Mantenha o Atlas aberto até lá.
prepare-stop = Parar atualizações
prepare-restart = Reiniciar e continuar
prepare-start = Buscar e instalar atualizações
# Under the preparation button while it is unavailable. $check is the check-supported-build title.
prepare-blocked-source = Indisponível porque esta instalação não pode continuar. Veja a mensagem na parte superior da página.
# Under the update button while it is unavailable. $check is the title of the check
# that must pass first: check-supported-build or check-administrator.
prepare-needs-build-check = Disponível quando a verificação { $check } for aprovada em Verificações do PC.
# Under the preparation button, and under the Administrator check, while the installation files are still downloading or unpacking.
prepare-wait-for-package = Disponível quando os arquivos de instalação estiverem prontos.
iso-username = Nome da conta local
iso-account-description = A instalação do Windows cria uma conta local com este nome, então você não precisa de uma conta Microsoft. O Windows pedirá que você escolha uma senha na primeira vez que entrar.
iso-username-placeholder = Seu nome
# Beside the unavailable Continue button while the local account name is empty.
iso-account-empty = Digite um nome de conta local para continuar
# Keep the list of symbols exactly: Windows refuses them in account names.
iso-account-invalid = Use até 20 caracteres, sem espaço no início ou no fim e sem nenhum destes: " / \ [ ] : ; | = , + * ? < > @
iso-account-trailing-dot = O nome não pode terminar com um ponto.
iso-account-reserved = O Windows usa este nome para uma conta integrada. Escolha outro nome.
# The answer file on the ISO hides these Windows setup screens.
iso-privacy-defaults = Esta ISO pula as telas de licença, conta Microsoft e privacidade da instalação do Windows e desativa o compartilhamento opcional de dados e as ofertas personalizadas.
prepare-drivers = Como os drivers devem ser instalados?
prepare-drivers-auto = Obter drivers pelo Windows Update
prepare-drivers-auto-detail = O Windows encontra drivers para o seu hardware. Recomendado para a maioria dos PCs.
prepare-drivers-manual = Instalar os drivers por conta própria
prepare-drivers-manual-detail = O Windows Update não instalará drivers, então você precisará obtê-los com o fabricante do seu PC ou dispositivo. Os drivers já instalados serão mantidos.
# Get ready: under the drivers question, above its two answers.
prepare-drivers-description = Os drivers permitem que o Windows use seu hardware, como vídeo, som e Wi-Fi. Se você mudar isso depois de atualizar, o Atlas precisará buscar atualizações novamente.
prepare-network-needed = As atualizações precisam de uma conexão com a internet que não seja limitada. Conecte-se por Wi-Fi ou Ethernet e escolha Tentar novamente. Se nenhuma rede Wi-Fi aparecer, instale primeiro o driver de rede.
# Connected, but Windows found no internet access (a captive portal, or DNS or firewall filtering).
prepare-network-limited = O Windows informa que esta rede está sem acesso à internet. Faça login na rede, se ela pedir, ou verifique o roteador e eventuais filtros de DNS ou firewall. Depois, tente novamente.
# "Conexão limitada" is the switch's name in Windows network settings.
prepare-network-metered = Esta conexão é limitada ou tem um limite de dados. Conecte-se a uma rede não limitada ou desative Conexão limitada nas configurações de rede e tente novamente.
prepare-network-settings = Abrir configurações de rede
iso-target-title = Em qual PC você vai reinstalar o Windows?
iso-target-this = Neste PC
# Under This PC (iso-target-this), before it's chosen.
iso-target-this-description = O Atlas pode adicionar os drivers de Wi-Fi e Ethernet deste PC à ISO, para que o Windows se conecte à internet logo depois de ser reinstalado.
iso-target-other = Em outro PC
iso-copy-network = Incluir os drivers de rede deste PC
iso-network-detail = Reutiliza os drivers de Wi-Fi e Ethernet deste PC durante a instalação do Windows. Você precisará se reconectar ao Wi-Fi depois.
iso-network-source = Origem dos drivers de rede
iso-network-installed = Usar os drivers instalados
iso-network-updated = Verificar o Windows Update primeiro
iso-network-updated-detail = Baixa drivers compatíveis oferecidos pelo Windows Update e mantém os instalados como reserva. Requer uma conexão não limitada.
iso-stage-network-drivers = Preparando os drivers de rede
iso-network-failed = Não foi possível preparar os drivers de rede. Consulte o diagnóstico ou volte e altere a opção de drivers de rede.
# Under iso-complete when Include this PC's network drivers was chosen but the adapters use
# drivers that come with Windows, so none were added.
iso-network-inbox = Os adaptadores de rede deste PC usam drivers que já vêm com o Windows, então a ISO não precisa incluí-los.
iso-mode-desktop = Concluir a configuração antes da área de trabalho
iso-mode-desktop-description = O Atlas salva suas escolhas na ISO. Depois que você entrar na sua conta, o Atlas conclui as atualizações e a instalação antes de a área de trabalho do Windows abrir.
desktop-setup-description = Conclua a configuração do PC. Suas escolhas do Atlas estão salvas; você pode voltar ao Windows se precisar.
desktop-setup-exit = Continuar no Windows

# Windows installation USB (Beta)
usb-title = Criar USB de instalação
usb-existing = Criar um USB a partir de uma ISO existente
usb-description = Grave uma ISO em uma unidade USB para reinstalar o Windows a partir dela. Use uma ISO criada pelo Atlas para instalar o Atlas ao mesmo tempo.
usb-choose-iso = Escolher ISO
usb-drive = Unidade USB
# $min and $max are formatted numbers (text), in gigabytes and terabytes.
# "Refresh" is usb-refresh.
usb-empty = Nenhuma unidade USB encontrada. Conecte uma unidade USB de pelo menos { $min } GB e escolha Atualizar. Unidades maiores que { $max } TB, unidades somente leitura e a unidade em que o Windows está sendo executado não aparecem.
usb-refresh = Atualizar
# Shown when the drive list could not be read.
usb-scan-failed = Confira se a unidade está conectada e escolha Atualizar. Para ver os detalhes, escolha Abrir pasta de logs.
usb-scan-failed-title = Não foi possível listar as unidades USB
# Parts of a drive's detail line, joined by usb-detail-separator; empty parts are left out.
# The separator also joins an ISO's architecture and size under its name.
# $size is a formatted number of gigabytes (text); $volumes and $serial are text.
usb-drive-size = { $size } GB
usb-drive-serial = Série: { $serial }
usb-detail-separator = { " · " }
usb-review = Revisar USB
usb-erase-title = Apagar esta unidade USB?
usb-erase-description = Todo o conteúdo de { $drive } ({ $size } GB) será apagado permanentemente, incluindo todos os arquivos e partições. Antes, copie para outra unidade tudo o que quiser manter. Sua ISO será mantida.
usb-layout = O Atlas usa até 32 GB da unidade e deixa o restante sem uso. A unidade USB funciona em PCs que iniciam no modo UEFI, exigido pelo Windows 11.
usb-ack = Entendo que todo o conteúdo desta unidade USB será apagado
usb-write = Apagar e criar USB
usb-stage-prepare = Preparando arquivos de instalação…
usb-stage-format = Formatando USB…
usb-stage-copy = Copiando arquivos de instalação…
usb-stage-verify = Verificando USB…
usb-working = Mantenha o Atlas aberto e a unidade USB conectada. Se você cancelar, a unidade USB incompleta não poderá ser usada para instalar o Windows.
# Titles of the error bar, the success bar and the close prompt while a USB is being written.
usb-failed-title = Não foi possível concluir a criação do USB
usb-complete-title = Seu USB está pronto
usb-close-title = O USB ainda está sendo criado
# After erasing may have begun.
usb-failed = A unidade pode já ter sido apagada, então ainda não pode ser usada para instalar o Windows. Verifique se ela está conectada e escolha Revisar USB para tentar novamente. Se você a reconectou, primeiro escolha Atualizar e selecione-a novamente.
# Before anything on the drive was changed: in general, then for the reasons the writer reports.
usb-failed-unchanged = Sua unidade USB não foi alterada. Escolha Abrir pasta de logs para ver o que falhou e depois escolha Revisar USB para tentar novamente.
usb-failed-iso = Esta ISO não pode ser usada para criar um USB de instalação. Escolha uma ISO criada pelo Atlas ou uma ISO do Windows 11 da Microsoft de uma versão compatível com o Atlas. Sua unidade USB não foi alterada.
usb-failed-location = A ISO ou o Atlas Manager está nesta unidade USB, em um local de rede ou em uma pasta vinculada. Mova o arquivo para uma pasta local deste PC e tente novamente. Sua unidade USB não foi alterada.
usb-failed-space = Não há espaço livre suficiente na unidade do Windows para preparar os arquivos de instalação. Libere espaço e tente novamente. Sua unidade USB não foi alterada.
usb-failed-fit = Os arquivos de instalação não cabem nesta unidade USB. Use uma unidade maior e tente novamente. Sua unidade USB não foi alterada.
# The drive no longer matched the list, before anything was erased. "Refresh" is
# usb-refresh; "Review USB" is usb-review.
usb-failed-drive-changed = A unidade USB foi removida, reconectada ou substituída depois que a lista foi lida. Escolha Atualizar, selecione a unidade novamente e escolha Revisar USB. Sua unidade USB não foi alterada.
usb-cancelled = A unidade pode conter arquivos de instalação incompletos. Crie-a novamente antes de usá-la para instalar o Windows.
usb-cancelled-title = Criação do USB cancelada
usb-cancelled-unchanged = Sua unidade USB não foi alterada.
# "Eject USB" is usb-eject. F12, F11 and Esc are key names.
usb-complete = O Atlas verificou todos os arquivos. Escolha Ejetar USB e depois faça backup dos arquivos do PC que você quer reinstalar. Conecte a unidade a esse PC e inicie-o pela unidade USB usando o menu de inicialização dele (geralmente F12, F11 ou Esc quando o PC liga).
usb-eject = Ejetar USB
usb-ejected = Você já pode desconectar a unidade USB. Faça backup dos arquivos do PC que você quer reinstalar. Depois, inicie esse PC pela unidade USB usando o menu de inicialização dele (geralmente F12, F11 ou Esc quando ele liga).
usb-eject-failed = Feche os arquivos ou janelas que estejam usando a unidade e tente novamente.
usb-eject-failed-title = Não foi possível ejetar o USB
ready-fresh-title = O Atlas foi feito para uma instalação limpa do Windows
ready-fresh-description = Se você já vinha usando o Windows neste PC, faça backup dos seus arquivos e reinstale o Windows antes de continuar. Primeiro, confira se a verificação Compatibilidade do Windows foi aprovada em Verificações do PC, para reinstalar uma versão compatível.
# Home, LTSC and Server are the editions the check refuses; the others are examples of
# editions it accepts. Keep edition names as Windows shows them.
detail-edition-unsupported = As edições Home, LTSC e Server do Windows 11 não são compatíveis. Use outra edição, como Pro, Education ou Enterprise. Se o Windows não conseguiu identificar sua edição, resolva isso antes de continuar.
install-source-title = Instalação indisponível
install-source-unsupported = Não é possível atualizar o Atlas { $source } diretamente para { $target }. Para usar esta versão, faça backup dos seus arquivos e reinstale o Windows.
# Before a package is chosen, so the version on offer isn't known yet.
install-source-unsupported-any = Não é possível atualizar o Atlas { $source } diretamente. Para usar uma versão mais recente, faça backup dos seus arquivos e reinstale o Windows.
# "Abrir arquivo de pacote" is package-open-file. $folder is a folder path (text).
install-source-resume = Uma instalação do Atlas { $target } não foi concluída, e só o pacote do Atlas { $target } pode concluí-la. Escolha Abrir arquivo de pacote e selecione esse pacote do Atlas (.apbx). Se o Atlas o baixou, ele está em { $folder }.
# Tester build: only the bundled Atlas package can be installed.
install-source-resume-bundled = Uma instalação do Atlas { $target } não foi concluída. Esta versão de teste só pode instalar o pacote do Atlas incluído, então conclua essa instalação com o pacote do Atlas { $target } em uma versão oficial do Atlas Manager.
# "Send a report" is report-title, a button offered with this message.
install-source-unknown = O Atlas não conseguiu confirmar o que já está instalado neste PC, então não vai instalar nada por enquanto. Escolha Enviar um relato para que a equipe do Atlas possa ajudar.
# $problem is one of the install-source-* messages, or the outcome-* advice for a failed
# installation; $error is a raw error message or the installer's last error line (text).
install-source-details = { $problem } Detalhes: { $error }
iso-edition-selection = Apenas as edições compatíveis são incluídas. Durante a instalação do Windows, escolha uma edição para a qual você tenha uma licença do Windows.
detail-windows-preview = As compilações Insider não são compatíveis. Use uma versão pública do Windows 11.
detail-windows-release-unknown = O Atlas não conseguiu confirmar se esta compilação do Windows é uma versão pública. Conecte-se à internet e verifique novamente.
iso-release-unknown = O Atlas não conseguiu confirmar se esta ISO é uma versão pública do Windows 11 compatível com o pacote do Atlas. Conecte-se à internet e escolha Verificar arquivos novamente. Se ainda falhar, baixe a ISO da Microsoft de novo.
prepare-previous-worker = As atualizações iniciadas anteriormente ainda estão em andamento. O Atlas aguardará a conclusão delas e depois você poderá buscar atualizações novamente.

ready-used-windows-title = O Windows deste PC parece já ter sido usado
# Its buttons are iso-open, which opens ISO creation, and ready-used-windows-dismiss.
# OneDrive, Desktop, Documents and Pictures: use the names Windows shows in your language.
ready-used-windows-description = O Windows deste PC foi instalado há pelo menos uma semana ou já tem vários apps. Instalar o Atlas aqui não tem suporte e é fortemente desaconselhado: os apps e as configurações que você já tem podem não funcionar como esperado, e o Atlas remove o OneDrive, então os arquivos nele deixam de ser sincronizados e suas pastas Área de Trabalho, Documentos e Imagens podem parecer vazias. Faça backup dos seus arquivos e reinstale o Windows primeiro ou continue apenas se aceitar o risco.
ready-used-windows-dismiss = Continuar mesmo assim

# On the update card after the PC restarts mid-update. "Continue updates" is prepare-continue,
# the button beside this message.
prepare-resumed = Seu PC foi reiniciado, e o Atlas restaurou as escolhas feitas até agora. Escolha Continuar atualizações para concluir a atualização antes de instalar o Atlas.
prepare-continue = Continuar atualizações
prepare-saving-restart = Salvando suas escolhas e configurando o Atlas para reabrir após a reinicialização do Windows…
prepare-restart-save-failed = Não foi possível salvar suas escolhas. Tente novamente antes de reiniciar.
prepare-restart-registration-failed = Suas escolhas estão salvas, mas o Atlas não conseguiu se configurar para abrir novamente após a reinicialização. Tente novamente ou reinicie o PC por conta própria e abra o Atlas depois de entrar na sua conta.
prepare-restart-failed = O Atlas não conseguiu reiniciar seu PC. Tente novamente ou reinicie-o pelo menu Iniciar. Suas escolhas estão salvas, e o Atlas abrirá novamente depois que você entrar na sua conta.
diagnostics-export = Exportar diagnóstico
diagnostics-exporting = Coletando diagnóstico…
diagnostics-privacy = Envie um relato privado à equipe do Atlas ou exporte um ZIP de diagnóstico para compartilhar quando pedir ajuda. O Atlas remove do ZIP seu nome de usuário, o nome do PC e seus endereços de e-mail.
# Title of the result bar after an export; its button is iso-open-folder.
diagnostics-saved = ZIP de diagnóstico criado
diagnostics-failed-title = Não foi possível exportar o diagnóstico
# $error is the raw error (text).
diagnostics-failed = Confira se há espaço livre em disco no PC e tente novamente. Detalhes: { $error }

## Tester builds (embedded-playbook feature)

# A bar at the top of the content on a release-candidate build.
rc-banner = Versão de teste do Atlas { $release }. Este app instala apenas o pacote do Atlas incluído.
home-status-bundled = Versão de teste { $release }
package-bundled = O Atlas { $version } incluído nesta versão de teste está pronto para instalar.
rc-about-release = Versão de teste
rc-about-commit = Commit de origem
rc-about-package = Pacote do Atlas incluído (SHA-256)
iso-package-bundled = O pacote do Atlas incluído nesta versão de teste
prepare-percent = { $percent }% desta etapa
prepare-count = Atualizações concluídas: { $completed } de { $total }
prepare-bytes = { $downloaded } de aproximadamente { $total } MB baixados
prepare-elapsed = Tempo decorrido: { $minutes } min { $seconds } s
prepare-progress-waiting = Aguardando o serviço de atualização. Não há porcentagem disponível para esta etapa.
prepare-progress-unchanged = Nenhum progresso há { $minutes } min. Atualizações grandes podem demorar, então mantenha o Atlas aberto. Para ver os detalhes, escolha Abrir pasta de logs.
prepare-report-delayed = O Windows não informa o progresso há { $seconds } s. As atualizações podem ainda estar em andamento, então mantenha o Atlas aberto.

prepare-affected-app = o aplicativo afetado
prepare-app-in-use = Feche { $app } e tente novamente. O Windows não consegue atualizá-lo enquanto ele estiver aberto. Se você não encontrar a janela, feche-o pelo Gerenciador de Tarefas. Se ainda falhar, reinicie o PC e tente novamente antes de abrir { $app }.
prepare-install-busy = Outra instalação ou uma reinicialização necessária está bloqueando as atualizações. Aguarde as outras instalações terminarem, reinicie o PC se o Windows pedir e tente novamente.
# Causes the update worker names. The worker's own English message is shown below as a detail.
prepare-failed-session-owner = O Atlas está sendo executado com uma conta diferente da que você usou para entrar no Windows. Entre no Windows com uma conta de administrador, abra o Atlas nessa conta e tente novamente.
prepare-failed-store-missing = A Microsoft Store não está configurada para sua conta. Abra a Microsoft Store uma vez ou, se ela não estiver instalada, reinstale-a. Depois, tente novamente.
prepare-failed-store-battery = A Microsoft Store pausou as atualizações para economizar bateria. Ligue o PC na tomada e tente novamente.
prepare-failed-store-network = A Microsoft Store pausou as atualizações até que seu PC tenha uma conexão não limitada. Conecte-se por Wi-Fi ou Ethernet sem conexão limitada e tente novamente.
prepare-failed-store-timeout = Os apps da Store ainda não terminaram de atualizar. Conclua os downloads restantes na Microsoft Store e tente novamente.
prepare-failed-store-passes = A Microsoft Store continuou oferecendo novas atualizações. Conclua as atualizações restantes na Microsoft Store e tente novamente.
prepare-failed-manual-updates = Algumas atualizações do Windows precisam ser concluídas no Windows Update. Abra o Windows Update, conclua-as e tente novamente.
prepare-failed-windows-passes = O Windows Update continuou oferecendo novas atualizações. Conclua as atualizações restantes no Windows Update e tente novamente.
prepare-error-code = Código do erro: { $code }
prepare-open-store = Abrir Microsoft Store

check-user-account = Conta de usuário
detail-user-account-ok = O UAC está ativado e sua conta está pronta para a instalação.
detail-user-account-not-ready = Ative o Controle de Conta de Usuário (UAC), reinicie o PC e tente novamente. Se você usa a conta Administrador integrada, entre com outra conta de administrador.
detail-user-account-unknown = O Atlas não conseguiu verificar sua conta de usuário. Verifique novamente antes de instalar. O Windows informou: { $error }

footer-prepare-required = Conclua a atualização do Windows e dos apps da Store para continuar
footer-prepare-stopping = Parando as atualizações após a etapa atual…
resume-choices-title = Continuando a instalação anterior
resume-choices-detail = Para concluir essa instalação, o Atlas restaurou as escolhas que você fez da última vez. Você não pode alterá-las na etapa Suas escolhas até que ela termine.

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
# Under "Your message", above the box, which also reads it out. $min and $max are
# numbers: the message lengths the report service accepts.
report-intro = Descreva o que aconteceu ou o que você gostaria de mudar ({ $min }–{ $max } caracteres). Não inclua senhas na sua mensagem.
report-message = Sua mensagem
report-message-placeholder = Eu estava tentando…
report-contact = Contato (opcional)
report-contact-placeholder = E-mail ou nome de usuário no Discord
report-attach = Incluir diagnósticos
# Under Include diagnostics. Part of the privacy notice the user agrees to: it says
# exactly what Atlas removes, so keep every item.
report-attach-description = Logs e detalhes do sistema que ajudam a encontrar a causa. O Atlas remove seu nome de usuário, o nome do PC, endereços de e-mail e senhas ou chaves conhecidas. Detalhes de erros, modelos de hardware e nomes de apps são mantidos. Você pode revisar o ZIP antes de enviar.
# Button that collects diagnostics again after they couldn't be prepared or sent.
report-prepare = Preparar diagnósticos
report-review = Revisar ZIP
report-prepare-failed-title = Não foi possível preparar os diagnósticos
# $error is a raw error message (text).
report-prepare-failed = Prepare os diagnósticos novamente ou desative Incluir diagnósticos para enviar o relato sem eles. Detalhes: { $error }
# The privacy notice the user agrees to, with report-attach-description. Changing it means a
# new PRIVACY_VERSION in the app, the report service and the website, deployed together.
report-privacy = Seu relato é enviado de forma privada à equipe do Atlas em reports.atlasos.net. Sua mensagem e seus dados de contato são enviados como foram escritos. A equipe pode usar serviços de IA de outras empresas para ajudar na investigação. Esses serviços recebem sua mensagem e os diagnósticos, mas não seus dados de contato. Os relatos são excluídos após 90 dias, e os logs de segurança do servidor podem registrar seu endereço IP.
report-website = Privacidade e site de relatos
report-consent = Concordo em enviar este relato e os diagnósticos incluídos à equipe do Atlas
# Under "Report wasn't sent", with Try again and the report website.
report-failed = Sua mensagem continua aqui. Confira sua conexão com a internet e escolha Tentar novamente ou envie seu relato pelo site de relatos.
report-failed-busy = O serviço de relatos está ocupado. Sua mensagem continua aqui. Tente novamente mais tarde.
# With the report website and, when diagnostics were included, Review ZIP.
report-failed-outdated = Esta versão do Atlas Manager não pode mais enviar relatos. Sua mensagem continua aqui: copie-a para o site de relatos. Se você incluiu diagnósticos, escolha Revisar ZIP e anexe o ZIP lá também.
report-failed-diagnostics = Não é possível enviar os diagnósticos preparados. Sua mensagem continua aqui. Prepare os diagnósticos novamente ou desative Incluir diagnósticos.
# Link under a report that wasn't sent.
report-failed-website = Abrir o site de relatos
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
# say "Windows 11, versão" before them as Microsoft does. $version is an Atlas version.

# Home, under the update button, when the update also moves Windows.
home-plan-intro = Esta atualização tem duas partes. Seus arquivos e apps são mantidos. Se a atualização do Windows desfizer alterações do Atlas, o Atlas as aplica novamente.
home-plan-windows-title = Windows 11, versão { $release }
home-plan-windows-detail = O Atlas instala essa versão pelo Windows Update. Seu PC é reiniciado para concluir a instalação.
# The same step where moving is optional.
home-plan-windows-optional = Recomendado. O Atlas instala essa versão pelo Windows Update. Seu PC é reiniciado para concluir a instalação.
home-plan-atlas-title = Atlas { $version }
home-plan-atlas-detail = O Atlas atualiza os arquivos dele e mantém as escolhas que você fez. Seu PC é reiniciado no final.
# $date and $until are dates.
home-end-of-updates-title = O Windows 11, versão { $current }, deixa de receber atualizações de segurança em { $date }
home-end-of-updates-past-title = O Windows 11, versão { $current }, não recebe mais atualizações de segurança
home-end-of-updates-message = Atualizar para o Atlas { $version } também leva este PC para o Windows 11, versão { $release }, que recebe atualizações de segurança até { $until }.
# Home, when this Windows can't take the Atlas version at all. $product is Windows'
# own name for the edition, such as Windows 11 Home.
install-windows-edition = O Atlas { $version } funciona com o Windows 11 Pro, Enterprise e Education. Este PC tem o { $product }, então o Atlas não pode ser instalado nele.
# The same, on a version whose security updates end. $date is a date.
install-windows-edition-ending = O Atlas { $version } funciona com o Windows 11 Pro, Enterprise e Education. Este PC tem o { $product }, então o Atlas não pode ser instalado nele. O Windows 11, versão { $current }, deixa de receber atualizações de segurança em { $date }. O Windows Update pode levar este PC para uma versão mais recente.
# $releases lists the supported releases, such as "25H2 ou 26H2".
install-windows-no-path = O Atlas { $version } requer o Windows 11, versão { $releases }, e o Windows Update não consegue levar este PC até ela a partir do Windows que ele tem. Para usar o Atlas { $version }, faça backup dos seus arquivos e reinstale o Windows com uma ISO com o Atlas.
# Home, when Atlas changed Windows Update settings for an update and hasn't put them back.
home-update-access-title = As configurações do Windows Update foram alteradas para a atualização do Atlas
# When the last check found no offer yet.
home-update-access-not-offered = O Atlas ativou o Windows Update para levar este PC ao Windows 11, versão { $release }, mas o Windows Update ainda não ofereceu essa versão. Escolha Verificar novamente ou Restaurar configurações.
home-update-access-before = O Atlas ativou o Windows Update para levar este PC ao Windows 11, versão { $release }, e ainda não terminou. Continue a atualização ou escolha Restaurar configurações.
home-update-access-after = Este PC tem o Windows 11, versão { $release }. Conclua a instalação do Atlas ou escolha Restaurar configurações.
home-update-access-plain = O Atlas ativou o Windows Update para instalar atualizações e ainda não terminou. Continue a atualização ou escolha Restaurar configurações.
home-update-access-unreadable = O Atlas não consegue ler o registro que fez das configurações do Windows Update que alterou, então não vai alterar nem restaurar nada. Escolha Enviar um relato para que a equipe do Atlas possa ajudar.
# $error is the raw error.
home-update-access-failed = O Atlas não conseguiu restaurar as configurações. Tente novamente ou escolha Enviar um relato. Detalhes: { $error }
home-update-access-install-active = Conclua a instalação do Atlas primeiro. No final, a instalação restaura essas configurações.
home-continue-update = Continuar atualização
home-put-back = Restaurar configurações
home-putting-back = Restaurando configurações…
# Get ready: the Windows version card.
windows-card-title = Windows 11, versão { $release }
windows-card-required = O Atlas { $version } requer uma versão mais recente do Windows. Quando o Atlas atualizar o Windows abaixo, ele também instalará o Windows 11, versão { $release }, pelo Windows Update.
windows-card-question = Qual versão do Windows este PC deve usar?
windows-choice-move = Atualizar para o Windows 11, versão { $release }
# $date is when the new version stops getting security updates.
windows-choice-move-detail = Recomendado. Atualizações de segurança até { $date }. Mais uma reinicialização.
windows-choice-keep = Manter o Windows 11, versão { $current }
windows-choice-keep-detail = Seu PC continua nesta versão. O Windows Update não vai levá-lo para uma versão mais recente, então mudar depois exige outra atualização no Atlas Manager.
windows-card-facts = O que muda
windows-fact-keep = Seus arquivos e apps são mantidos. Se a atualização desfizer alterações do Atlas, o Atlas as aplica novamente ao ser instalado.
windows-fact-restart = Seu PC é reiniciado pelo menos mais uma vez para concluir a atualização.
# Also after home-plan-windows-detail on Home: how long Windows Update can take to offer the
# new version, which Atlas waits for by itself.
transition-offer-expectation = O Windows Update costuma oferecer a nova versão em poucos minutos, mas pode demorar até 2 horas; o Atlas aguarda e verifica por você.
windows-fact-stays = Depois, o Windows permanece na versão { $release } e não muda sozinho para uma versão mais recente.
windows-fact-removed = A versão { $release } não inclui o Windows PowerShell 2.0 nem a ferramenta WMIC.
# How to undo the move: Windows may switch the new version on in place, which Update history
# can uninstall, or reinstall itself, which Go back undoes for 10 days. "Histórico de
# atualizações", "Voltar", "Recuperação" and "Sistema" are Windows pt-BR's own labels.
windows-card-undo = Para desfazer isso depois, desinstale a atualização em Histórico de atualizações, no Windows Update. Se o Windows tiver se reinstalado para fazer a atualização, escolha Voltar em Sistema > Recuperação, nas Configurações, em até 10 dias. O Atlas { $version } não tem suporte à versão { $current }, então não desfaça a atualização depois que o Atlas { $version } estiver instalado.
windows-card-undo-optional = Para desfazer isso depois, desinstale a atualização em Histórico de atualizações, no Windows Update. Se o Windows tiver se reinstalado para fazer a atualização, escolha Voltar em Sistema > Recuperação, nas Configurações, em até 10 dias.
windows-terms = Aceito os Termos de Licença para Software Microsoft do Windows 11, versão { $release }
windows-terms-link = Ler os termos de licença
# Cancelar is common-cancel; Parar atualizações confirms it (prepare-stop).
windows-card-locked = Para manter a versão { $current }, escolha Cancelar e depois Parar atualizações.
# Get ready: the update card while Windows moves.
prepare-description-transition = Antes da instalação, o Atlas instala as atualizações que o Windows está aguardando, depois o Windows 11, versão { $release }, e por fim atualiza a Microsoft Store e seus apps da Store. Os apps da Store que estiverem abertos podem ser fechados durante a atualização, então salve seu trabalho neles primeiro. Seu PC é reiniciado pelo menos uma vez.
prepare-start-transition = Atualizar o Windows para a versão { $release }
prepare-needs-terms = Disponível quando você aceitar os termos de licença no cartão Windows 11, versão { $release }.
ready-banner-not-offered-message = Veja no cartão Atualizar o Windows e os apps da Store o que você pode fazer agora.
ready-banner-transition-failed-message = Veja no cartão Atualizar o Windows e os apps da Store o que fazer em seguida.
ready-banner-terms-title = Aceite os termos de licença para continuar
ready-banner-terms-message = Eles estão no cartão Windows 11, versão { $release }, mais abaixo nesta página. Depois, escolha Atualizar o Windows para a versão { $release }.
# The bar that names each Windows Update setting Atlas turns on for the update.
access-notice-title = O Atlas ativa o Windows Update temporariamente
access-off = O Windows Update está desativado neste PC. O Atlas o reativa enquanto atualiza o Windows.
access-paused = As atualizações do Windows estão pausadas neste PC. O Atlas as retoma enquanto atualiza o Windows.
access-delayed = As atualizações mensais estão adiadas neste PC. O Atlas remove o adiamento enquanto atualiza o Windows.
# After the lines above. "As you chose" applies when an Atlas setting the user chose set them.
access-back-chosen = Quando o Atlas { $version } estiver instalado, essas configurações voltarão a ficar como você escolheu.
access-back = Quando o Atlas { $version } estiver instalado, essas configurações voltarão a ficar como eram.
access-back-stop = Se você parar antes disso, o Atlas as restaura.
# The restart that finishes the new version.
prepare-reboot-transition = O Windows 11, versão { $release }, foi instalado. Escolha Reiniciar e continuar para concluir a instalação. O Atlas abre novamente depois que você entrar na sua conta.
prepare-reboot-commit = O Windows precisa reiniciar mais uma vez para concluir a instalação da versão { $release }. O Atlas abre novamente depois que você entrar na sua conta.
prepare-restart-commit-failed = O Windows não conseguiu preparar a versão { $release } para ser concluída na reinicialização, então seu PC não foi reiniciado. Escolha Reiniciar e continuar para tentar novamente.
prepare-reason-feature-update = a nova versão do Windows
prepare-reason-feature-commit = a conclusão da nova versão do Windows
prepare-resumed-transition = Seu PC foi reiniciado. Escolha Continuar atualizações para que o Atlas verifique se o Windows 11, versão { $release }, foi concluído e instale as atualizações restantes.
# Under the progress bar while Windows Update has yet to offer the new version.
prepare-waiting-offer = Aguardando o Windows Update oferecer o Windows 11, versão { $release }. Isso costuma levar alguns minutos, mas pode demorar até 2 horas. Você pode continuar usando seu PC; deixe o Atlas aberto.
# After a restart for the updates Windows installs before the new version.
prepare-resumed-before-move = Seu PC foi reiniciado para concluir a instalação das atualizações. Escolha Continuar atualizações para que o Atlas instale as atualizações restantes e depois o Windows 11, versão { $release }.
# Outcomes of moving Windows. Each says what changed and what to do next.
prepare-not-offered-title = Aguardando o Windows Update oferecer o Windows 11, versão { $release }
prepare-transition-failed-title = O Windows não conseguiu mudar para a versão { $release }
prepare-failed-feature-not-offered = O Windows Update pode demorar para oferecer o Windows 11, versão { $release }, a um PC. Seu PC continua com a versão { $current }.
# Added after the message above while Atlas looks again by itself.
prepare-offer-rechecking = O Atlas verifica novamente a cada 10 minutos e continua sozinho assim que o Windows Update oferecer essa versão. Você também pode escolher Verificar novamente.
# Under the progress bar while Atlas waits, shown together on one line: how long it has
# waited, then when it looks again, or that it's looking now.
prepare-offer-waited =
    { $minutes ->
        [one] Aguardando há { $minutes } minuto.
       *[other] Aguardando há { $minutes } minutos.
    }
prepare-offer-next-check =
    { $minutes ->
        [one] Próxima verificação em { $minutes } minuto.
       *[other] Próxima verificação em { $minutes } minutos.
    }
prepare-offer-checking-now = Verificando agora.
# Added instead while Atlas isn't looking again by itself.
prepare-offer-check-again = Escolha Verificar novamente para procurar agora.
# After 2 hours of looking again without an offer.
prepare-offer-wait-ended-title = O Windows Update ainda não ofereceu o Windows 11, versão { $release }
prepare-offer-wait-ended = O Windows Update não ofereceu o Windows 11, versão { $release }, em 2 horas, então o Atlas parou de aguardar e restaurou suas configurações do Windows Update. Escolha Verificar novamente mais tarde. Se você não puder esperar, faça backup dos seus arquivos e reinstale o Windows com uma ISO com o Atlas.
# Instead of the message above when putting the settings back failed. $error is the raw error.
prepare-offer-wait-put-back-failed = O Windows Update não ofereceu o Windows 11, versão { $release }, em 2 horas, e o Atlas não conseguiu restaurar suas configurações do Windows Update. Escolha Restaurar configurações para tentar novamente. Detalhes: { $error }
# $missing lists the hardware this PC lacks, from the two messages below.
prepare-failed-feature-hardware = Este PC não atende aos requisitos de hardware do Windows 11 ({ $missing }), então o Windows Update não vai levá-lo para a versão { $release }. Seu PC continua com a versão { $current }. Para usar o Atlas { $version }, faça backup dos seus arquivos e reinstale o Windows com uma ISO com o Atlas.
hardware-tpm = TPM 2.0
hardware-uefi = firmware UEFI
prepare-failed-feature-hidden = O Windows 11, versão { $release }, está oculto no Windows Update neste PC. Volte a exibi-lo com a ferramenta que você usou para ocultá-lo e depois escolha Tentar novamente.
# $needed and $free are whole gigabytes; $drive is a drive such as C:.
prepare-failed-feature-disk-space = O Windows precisa de pelo menos { $needed } GB livres na unidade { $drive } para esta atualização, e ela tem { $free } GB. O Atlas não alterou nada. Libere espaço e depois escolha Tentar novamente.
prepare-failed-feature-servicing = O Windows informa danos no repositório de componentes que ele não consegue reparar, então o Atlas não alterou nada. Repare o Windows e depois escolha Tentar novamente.
prepare-failed-feature-managed = Este PC recebe atualizações do servidor de atualizações de uma organização, então o Atlas não pode levá-lo para a versão { $release }. O Atlas não alterou nada.
# $setting is the technical name of a Windows Update policy value or service, such as
# NoAutoUpdate or BITS, shown as it is.
prepare-failed-feature-policy = Algo neste PC continua desfazendo a alteração que o Atlas faz em { $setting }, então o Atlas não consegue atualizar o Windows. Se este PC for gerenciado por uma organização, peça ajuda a ela. Quando você parar, o Atlas restaura o que alterou.
prepare-failed-feature-blocked = Uma configuração que o Atlas não alterou impede a execução do Windows Update: { $setting }. Altere-a para que o Windows Update possa ser executado e depois escolha Tentar novamente.
prepare-failed-feature-rolled-back = O Windows não conseguiu concluir a instalação da versão { $release } durante a reinicialização e voltou para a versão { $current }. Seus arquivos e apps não foram afetados. Escolha Tentar novamente ou Enviar um relato.
prepare-failed-feature-components-lost = Algumas alterações do Atlas foram perdidas após a atualização do Windows, e o Windows não mostra sinais de ter se reinstalado, então o Atlas não consegue identificar o que aconteceu. O Atlas { $version } não foi instalado. Escolha Enviar um relato para que a equipe do Atlas possa ajudar.
prepare-failed-feature-build = A versão do Windows deste PC mudou enquanto o Atlas o atualizava. Escolha Restaurar configurações e depois comece de novo pela página inicial.
prepare-failed-feature-journal = O Atlas não consegue ler o registro que fez das configurações do Windows Update que alterou, então não vai alterar nem restaurar nada. Escolha Enviar um relato para que a equipe do Atlas possa ajudar.
# $setting is the name of a Windows Update policy value, such as TargetReleaseVersionInfo.
prepare-failed-feature-pin = Uma política do Windows Update neste PC, { $setting }, tem um valor que o Atlas não consegue registrar, então o Atlas não alterou nada. Escolha Enviar um relato para que a equipe do Atlas possa ajudar.
prepare-failed-feature-terms = Aceite os termos de licença do Windows 11, versão { $release }, e depois escolha Tentar novamente.
prepare-failed-feature-failed = O Windows não conseguiu instalar a versão { $release }. Seu PC continua com a versão { $current }. Escolha Tentar novamente. Se falhar de novo, escolha Enviar um relato.
prepare-check-again = Verificar novamente
prepare-keep-version = Manter a versão { $current }
# Asked before leaving the update with Windows Update settings changed.
stop-update-title = Parar a atualização para o Atlas { $version }?
stop-update-before = O Atlas restaura as configurações do Windows Update que alterou. As atualizações que o Windows já instalou continuam instaladas, e seu PC mantém o Windows 11, versão { $current }.
stop-update-after = Seu PC mantém o Windows 11, versão { $release }. O Atlas restaura as configurações do Windows Update que alterou.
stop-update-access = O Atlas restaura as configurações do Windows Update que alterou. As atualizações que o Windows já instalou continuam instaladas.
stop-update-keep = Continuar atualizando
window-close-update-access-title = Fechar o Atlas?
window-close-update-access-message = Antes de fechar, o Atlas restaura as configurações do Windows Update que alterou. Você pode iniciar a atualização novamente pela página inicial.
window-close-put-back = Restaurar e fechar
# When putting the settings back before closing failed. The reason comes first, then this
# message; the buttons are window-close-keep and window-close-close.
window-close-put-back-failed-title = Fechar sem restaurar as configurações?
window-close-put-back-failed-message = Se você fechar o Atlas agora, as configurações do Windows Update continuarão como o Atlas as alterou. Quando você abrir o Atlas novamente, a página inicial oferecerá a opção de restaurá-las.
# The "Atlas is installed" window, when the user's choice turned Windows Update off again.
installed-update-off-again = O Windows Update está desativado de novo, como você escolheu. Enquanto ele estiver desativado, seu PC não recebe atualizações de segurança.
installed-update-paused-again = As atualizações do Windows estão pausadas de novo, como você escolheu. Enquanto elas estiverem pausadas, seu PC não recebe atualizações de segurança.
# PC checks: Windows compatibility on a version Atlas moves from.
detail-build-transition = Este PC tem o Windows 11, versão { $current }, que não tem suporte nesta versão do Atlas. O Atlas muda o Windows para a versão { $release } quando atualiza o Windows abaixo.
# The first lines of a report about a Windows update that didn't finish; technical
# details follow in English.
report-transition-intro = A atualização do Windows para o Atlas não foi concluída. Detalhes para a equipe do Atlas:
# When Windows reinstalled itself while it moved to a newer version, instead of
# switching the new version on in place. Atlas then puts all of its changes back.
mode-rebase = Reinstalação após uma atualização do Windows
history-mode-rebase = reinstalação após uma atualização do Windows
ready-rebase-title = O Windows se reinstalou durante a atualização
# $previous is the Atlas version the PC had before.
ready-rebase-message = O Windows 11, versão { $release }, substituiu o Windows que este PC tinha, então algumas alterações do Atlas foram perdidas. O Atlas { $version } as aplica novamente, com as escolhas que você fez para o Atlas { $previous }.
# Your choices on an update, started from what the installed Atlas chose.
upgrade-choices-title = Suas escolhas do Atlas { $previous }
upgrade-choices-detail = O Atlas partiu do que o Atlas { $previous } configurou neste PC. A atualização mantém o efeito dessas escolhas, então desmarcar um extra aqui não o desfaz. Para alterar alguma delas depois, use a pasta Atlas ou as Configurações do Windows.
rebase-choices-title = Suas escolhas do Atlas { $previous }
rebase-choices-detail = O Atlas usa as escolhas que você fez para o Atlas { $previous }, então não há nada para escolher aqui. Você pode alterá-las depois na pasta Atlas.
# $missing lists the choices, such as "Microsoft Defender, Proteções do processador".
rebase-choices-partial = O Atlas usa as escolhas que você fez para o Atlas { $previous }. Ele não encontrou estas, então confira-as: { $missing }
# Asked before any restart Atlas makes while other people are signed in to the PC.
restart-other-title = Outra pessoa está conectada a este PC
restart-others-title = Outras pessoas estão conectadas a este PC
# $names lists their account names, such as "Alex e Sam". Also under restart-other-title,
# so the wording works for one account or several.
restart-others-message = Reiniciar fecha os apps abertos nessas contas, e o trabalho não salvo nelas será perdido. Contas conectadas: { $names }.
restart-others-keep = Não reiniciar
restart-others-restart = Reiniciar mesmo assim
# Microsoft Store itself, before the Store apps. Get ready's status line while it updates or is repaired.
prepare-store-self-update = Atualizando a Microsoft Store primeiro. Ela está desatualizada neste PC.
prepare-store-repair = Reparando a Microsoft Store. Isso pode levar alguns minutos.
# Under prepare-complete, once Get ready has finished.
prepare-store-updated = A Microsoft Store estava desatualizada, então o Atlas a atualizou antes dos seus apps.
# "Instalador de Aplicativo" is App Installer's name in the Brazilian Microsoft Store.
prepare-store-bootstrapped = A Microsoft Store não conseguiu se atualizar, então o Atlas instalou as versões mais recentes do Instalador de Aplicativo e da Microsoft Store diretamente da Microsoft.
prepare-store-repaired = A Microsoft Store não estava funcionando, então o Atlas a reparou.
prepare-store-skipped-removed = A Microsoft Store está desativada neste PC, então o Atlas pulou as atualizações dos apps da Store.
# "Reparar a Microsoft Store" is prepare-repair-store; "Enviar um relato" is report-title.
prepare-failed-store-repair-failed = A Microsoft Store não está funcionando, e o Atlas não conseguiu repará-la. Escolha Reparar a Microsoft Store para tentar novamente. Se ainda não funcionar, escolha Enviar um relato.
prepare-repair-store = Reparar a Microsoft Store

screen-keyboard-title = Idiomas do teclado
screen-keyboard-question = Você usa vários idiomas de teclado?
playbook-option-keyboard-shortcuts = Sim, com atalhos de teclado
playbook-option-keyboard-selector = Sim, com o seletor na barra de tarefas
playbook-option-keyboard-single = Não, uso apenas um layout
consequence-keyboard-shortcuts = Alt+Shift alterna o idioma; Ctrl+Shift alterna o layout.
consequence-keyboard-selector = Desative Alt+Shift e Ctrl+Shift para evitar mudanças acidentais durante jogos.
playbook-page-keyboard-shortcuts-description = Escolha como alternar o idioma do teclado.
consequence-keyboard-single = { consequence-keyboard-selector }
