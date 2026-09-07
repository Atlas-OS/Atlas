### Atlas Manager: Português (Brasil), pt-BR. Preview translation, revised on 6 September 2026 from the en-GB source (i18n/en-GB/atlas.ftl).
###
### Style notes for this catalog: address the reader as "você" (mostly implicit),
### the computer is "seu PC" / "o PC"; "o Atlas" and "o Windows" take the article;
### buttons are short infinitives ("Reiniciar agora"); headings are sentence case
### with no final full stop. "Reiniciar" is only ever the PC / Windows; reopening
### the Atlas Manager is "reabrir". The four Windows Security switches keep the names
### Windows shows in Brazilian Portuguese and are referred to as "proteções".
### This catalog also serves pt-PT requests; Brazilian vocabulary is used where
### no neutral form exists (baixar, arquivo, configurações, excluir, tela).

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
# Accessible description of a disabled control.
common-not-available = Indisponível no momento
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

## Janela

# Dialog shown when the window is closed while an install runs.
window-close-title = Fechar durante a instalação do Atlas?
window-close-message = A instalação continuará em segundo plano. Abra o Atlas novamente para acompanhar o progresso e ver o resultado. Mantenha o PC ligado até ela terminar.
window-close-keep = Manter aberta
window-close-close = Fechar janela
# Title of the file picker for a playbook (.apbx) file.
file-dialog-open-playbook = Abrir um playbook do Atlas (.apbx)
# Message Windows shows in its restart notification.
shutdown-comment = O Atlas foi instalado. O Windows está reiniciando para concluir a configuração.

## Sistema

# "Windows 11 Pro 25H2 (build 26200.1234)". All three values are text. Windows pt-BR keeps "build".
system-description = { $product } { $version } (build { $build })

## Página inicial

home-not-installed = Boas-vindas ao Atlas
# The headline when Atlas is installed. $version is text.
home-version = Atlas { $version }
# $date is a formatted date.
home-installed-on = Instalado em { $date }
home-status-checking = Verificando atualizações
home-status-offline = Não foi possível verificar atualizações
home-status-not-checked = Atualizações ainda não verificadas
home-status-update = O Atlas { $version } está disponível
home-status-up-to-date = Atualizado
home-status-newest = Versão mais recente: Atlas { $version }
home-check-again = Verificar novamente
# Primary button while an install is running or waiting.
home-show-install = Ver progresso
home-continue-installing = Continuar a configuração
home-update-to = Atualizar para o Atlas { $version }
home-reinstall = Reinstalar o Atlas
home-install = Instalar o Atlas
home-start-over = Começar de novo
home-security-reminder-title = Reative sua proteção
# Buttons beside it: Abrir a Segurança do Windows, Concluído.
home-security-reminder-message = Nenhuma instalação está em andamento. Na Segurança do Windows, reative a Proteção contra violações, a Proteção em tempo real, a Proteção fornecida pela nuvem e o Envio automático de amostra.
home-elevation-title = O Atlas precisa de permissão para instalar
home-state-error-title = Não foi possível ler os dados da sua instalação do Atlas
home-whats-new = Novidades do Atlas { $version }
home-view-release = Ver notas da versão no GitHub
home-released = Lançado em { $date }
home-show-less = Mostrar menos
home-show-full-notes = Mostrar todas as notas da versão
home-your-install = Sua instalação do Atlas
# Row label: how Atlas was set up.
home-set-up = Método de configuração
home-set-up-during-oobe = Durante a configuração do Windows
home-history = Histórico de instalações
# One history row. $version is text, $mode one of the history-mode-* messages, $date a formatted date and time.
home-history-entry = Atlas { $version } · { $mode } · { $date }
home-how-it-works = Vamos preparar seu PC para o Atlas
home-step-1-title = Verificar o PC
home-step-1-detail = O Atlas verifica o Windows e baixa os arquivos de instalação. Suas configurações do Windows continuam como estão.
home-step-2-title = Deixar do seu jeito
home-step-2-detail = Escolha como o Windows cuida da proteção e das atualizações e, se quiser, adicione apps ou ajustes extras.
home-step-3-title = Pausar a proteção antivírus
home-step-3-detail = O Atlas orienta você a desativar quatro proteções da Segurança do Windows para que elas não bloqueiem a instalação.
home-step-4-title = Instalar e reiniciar
home-step-4-detail =
    { $minutes ->
        [one] Cerca de um minuto.
       *[other] Cerca de { $minutes } minutos.
    }
# Accessible name of a numbered step.
home-step-a11y = Etapa { $number }: { $title }
# Link buttons: say where they lead.
home-github = Ver o Atlas no GitHub
home-discord = Comunidade do Atlas no Discord
home-report-problem = Relatar um problema no GitHub

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
notice-session-unreadable-title = Não foi possível verificar a instalação anterior
# $path is a file path (text).
notice-session-unreadable-message = O Atlas não consegue ler { $path } e precisa saber se ainda há uma instalação em andamento. Se não tiver certeza, peça ajuda à comunidade do Atlas antes de excluir esse arquivo. Só o exclua e tente novamente depois de confirmar que nenhuma instalação está em andamento. Detalhes: { $error }

## Elevação para administrador

elevation-declined = A permissão não foi concedida. Tente novamente e escolha Sim quando o Windows perguntar se o Atlas pode fazer alterações no dispositivo.
elevation-declined-continue = A permissão não foi concedida. Tente novamente e escolha Sim quando o Windows perguntar se o Atlas pode fazer alterações no dispositivo. Suas escolhas de configuração foram salvas.
elevation-draft-not-saved = O Atlas não conseguiu salvar suas escolhas de configuração e, por isso, não foi reaberto. Tente novamente. Detalhes: { $error }

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
# Heading above each step's content.
step-heading = Etapa { $number } de { $total }: { $title }

## Etapa 1: Preparação

ready-banner-busy-title = Preparando seu PC
ready-banner-busy-message = O Atlas está verificando seu PC e preparando os arquivos de instalação.
ready-banner-blocked-title = Seu PC precisa de alguns ajustes
ready-banner-blocked-message = Siga as instruções abaixo e depois escolha Verificar novamente.
ready-banner-no-package-title = Baixe o Atlas para continuar
ready-banner-no-package-message = Baixe a versão mais recente abaixo ou abra um playbook do Atlas (.apbx) salvo no PC.
ready-banner-warnings-title = Alguns pontos para revisar
ready-banner-warnings-message = Leia as observações abaixo e siga as recomendações antes de continuar.
ready-banner-ok-title = Tudo pronto para escolher suas configurações
ready-banner-ok-message = As verificações passaram e os arquivos de instalação estão prontos.
# Card title and accessible name of the list of checks.
ready-this-pc = Verificações do PC
ready-check-again = Verificar novamente
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
package-none = Ainda não há arquivos de instalação. Um playbook (.apbx) contém as instruções e os arquivos de que o Atlas precisa.
# Short status words beside the card title.
package-status-downloading = Baixando
package-status-unpacking = Extraindo
package-status-failed = Falha na preparação
package-status-ready = Pronto
package-status-checking = Verificando
package-status-missing = Não baixado
# Accessible name of the progress bar.
package-progress = Progresso dos arquivos de instalação
package-download-again = Baixar novamente
package-download-version = Baixar o Atlas { $version }
package-download-newest = Baixar a versão mais recente
package-open-file = Abrir arquivo de playbook
# Where the package came from. $file is a file name, $path a folder path (text).
package-from-release = O Atlas { $version } foi baixado do GitHub e está pronto para instalar.
package-from-file = O Atlas { $version } foi carregado de { $file } e está pronto para instalar.
package-unpacked = O Atlas { $version } está pronto para instalar.
package-at = Arquivos de instalação: { $path }
package-none-yet = Nenhum arquivo de instalação selecionado
acquire-no-asset = O Atlas { $version } não tem um arquivo de playbook disponível para baixar. Abra um playbook do Atlas (.apbx) salvo no PC para continuar.
acquire-unsupported = Este app instala o Atlas 0.6.0 ou mais recente. Para instalar o Atlas { $version }, use o AME Wizard.
acquire-failed = Não foi possível preparar os arquivos de instalação. Tente baixar novamente ou abra outro playbook do Atlas (.apbx). Detalhes: { $error }

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
# Check boxes the user ticks when a check could not run.
check-ack-updates = Verifiquei o Windows Update: não há atualizações aguardando instalação
check-ack-reboot = Reiniciei o Windows e não é preciso reiniciar de novo
check-ack-internet = Este PC está conectado à internet
check-ack-generic = Verifiquei este requisito por conta própria
detail-admin-ok = O Atlas tem permissão para fazer as alterações necessárias à instalação.
# The button "Reabrir como administrador" sits beside this line.
detail-admin-missing = O Atlas precisa de permissão de administrador para instalar. Escolha Reabrir como administrador e, quando o Windows pedir, escolha Sim.
# $builds is a list of build numbers such as "26100 ou 26200"; $build is this PC's (text).
detail-build-unsupported = Esta versão do Atlas requer o Windows na build { $builds }. Seu PC está na build { $build }. Instale uma versão compatível do Windows antes de continuar.
detail-updates-none = Não há atualizações do Windows aguardando instalação.
# $titles lists up to two update names (text); $count is the total.
detail-updates-pending =
    { $count ->
        [1] Instale esta atualização primeiro: { $titles }.
        [2] Instale estas atualizações primeiro: { $titles }.
       *[other] Instale primeiro as { $count } atualizações pendentes, incluindo { $titles }.
    }
detail-updates-unknown = Não foi possível verificar se há atualizações do Windows. Abra o Windows Update e, se não houver atualizações aguardando, confirme abaixo. ({ $error })
detail-reboot-none = O Windows não precisa ser reiniciado agora.
detail-reboot-pending = Reinicie o PC para concluir alterações anteriores. Depois, reabra o Atlas e verifique novamente.
detail-reboot-unknown = Não foi possível verificar se o Windows precisa ser reiniciado. Reinicie o PC, reabra o Atlas e verifique novamente. ({ $error })
detail-antivirus-none = Nenhum outro antivírus foi detectado.
# $products is a list of product names (text).
detail-antivirus-found = Outro antivírus pode bloquear a instalação: { $products }. Desinstale esse software antes de continuar.
detail-antivirus-unknown = Não foi possível verificar se há outro antivírus. Confira os apps instalados antes de continuar. ({ $error })
detail-internet-ok = Seu PC está conectado à internet. Mantenha a conexão enquanto o Atlas baixa e instala os programas.
detail-internet-missing = Conecte-se à internet e depois verifique novamente.
detail-power-mains = Seu PC está ligado na tomada. Mantenha-o assim até a instalação terminar.
detail-power-battery = Ligue o PC na tomada para que ele não desligue durante a instalação.
detail-power-unknown = Não foi possível verificar a alimentação de energia. Se estiver usando um notebook, ligue-o na tomada antes de continuar.
detail-activation-ok = O Windows está ativado. O Atlas não altera isso.
detail-activation-missing = O Windows não está ativado. Você pode continuar, mas o Atlas não ativará o Windows para você.
detail-activation-no-licence = O Windows não informou uma licença. Você pode continuar; o Atlas não altera o status da ativação.
detail-activation-unknown = Não foi possível verificar a ativação do Windows. Você pode continuar; o Atlas não altera o status da ativação. ({ $error })

## Etapa 2: Opções

options-progress = Escolha { $number } de { $total }
options-progress-extras = Escolha { $number } de { $total }: extras opcionais
# Short names for each decision (summary rows) and the question each screen asks.
screen-defender-title = Microsoft Defender
screen-defender-question = Manter a proteção antivírus ativada?
screen-mitigations-title = Segurança do processador
screen-mitigations-question = Manter as proteções do Windows para o processador?
screen-updates-title = Windows Update
screen-updates-question = Como o Windows deve instalar as atualizações?
screen-browser-title = Navegador
screen-power-title = Energia e segurança
screen-apps-title = Apps
screen-optional-apps-title = Aplicativos opcionais
screen-choose-one-title = Escolha uma opção
screen-extras-title = Extras opcionais
screen-extras-question = Escolha os extras que quiser
# Question for a required choice this app has no specific wording for.
screen-generic-question = Escolha uma opção para { $title }
learn-more-defender = Saiba mais sobre o Microsoft Defender
learn-more-mitigations = Leia sobre a segurança do processador
learn-more-updates = Saiba mais sobre o Windows Update
learn-more-browser = Saiba mais sobre navegadores
learn-more-power = Saiba mais sobre energia e segurança
learn-more-apps = Saiba mais sobre apps
learn-more-eclean = Como o eclean funciona com o AtlasOS
learn-more-generic = Ler o guia de configuração
# One line under the chosen answer: what it means for the PC.
consequence-defender-enable = Mantém o antivírus integrado do Windows para ajudar a proteger seu PC contra vírus e outras ameaças.
consequence-defender-disable = Remove o Microsoft Defender. Seu PC ficará sem proteção antivírus até você instalar outro antivírus.
consequence-mitigations-default = Mantém as proteções padrão do Windows contra ataques que exploram o funcionamento do processador.
consequence-mitigations-disable = Desativa essas proteções e reduz a segurança. O desempenho depende do processador e pode até piorar.
consequence-auto-updates-disable = Você precisará abrir o Windows Update e instalar as atualizações por conta própria. As notificações de atualização continuam ativadas.
consequence-auto-updates-default = O Windows instalará as atualizações automaticamente, incluindo correções de segurança.

## Texto do playbook
## The playbook package carries its own English text for each option. These
## UI labels and explanations are used only when the package text matches
## i18n/playbook-source.ftl. A future package with different wording keeps
## its own text instead of receiving a potentially outdated description.

playbook-option-defender-enable = Manter o Microsoft Defender (recomendado)
playbook-option-defender-disable = Remover o Microsoft Defender
playbook-option-mitigations-default = Manter as proteções padrão (recomendado)
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
playbook-option-browser-brave = Brave
playbook-option-browser-librewolf = LibreWolf
playbook-option-browser-firefox = Firefox
playbook-option-browser-chrome = Chrome
playbook-page-defender-enable-description = O Microsoft Defender é o antivírus integrado do Windows. Recomendamos mantê-lo. Só remova se você entender os riscos e pretender usar outro antivírus.
playbook-page-mitigations-default-description = Essas proteções, também chamadas de mitigações de segurança, ajudam a defender o PC contra vulnerabilidades do processador. Recomendamos manter os padrões do Windows.
playbook-page-auto-updates-disable-description = As atualizações do Windows incluem correções de segurança. Você pode deixar o Windows instalá-las automaticamente ou instalá-las por conta própria.
consequence-install-toolbox = Adicione o Atlas Toolbox para ajudar a gerenciar as configurações do Atlas. O Toolbox está em beta, então alguns recursos podem estar incompletos.
playbook-page-browser-brave-description = Escolha um navegador para instalar. O Atlas não altera as configurações do navegador.

## Etapa 3: Segurança do Windows

security-banner-reading-title = Verificando a Segurança do Windows
security-banner-reading-message = O Atlas está verificando as quatro proteções abaixo.
security-banner-off-title = As quatro proteções estão desativadas
security-banner-off-message = Agora você pode revisar suas escolhas antes de instalar.
security-banner-readable-off-title = As proteções que o Atlas conseguiu verificar estão desativadas
security-banner-readable-off-message = Confira as demais na Segurança do Windows.
security-banner-on-title = Desative temporariamente a proteção antivírus
security-banner-on-message = Essas proteções podem bloquear as alterações que o Atlas precisa fazer.
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
security-unknown-message = Depois de conferir na Segurança do Windows que as quatro proteções estão desativadas, confirme abaixo.
security-acknowledge = Verifiquei na Segurança do Windows que as quatro proteções estão desativadas
security-unknown-unelevated-title = O Atlas precisa de permissão para verificar a proteção
# The button "Reabrir como administrador" sits beside this line.
security-unknown-unelevated-message = Reabra o Atlas como administrador para que ele consiga ler as configurações do Microsoft Defender.
# The four switches, named as Windows Security names them in Brazilian Portuguese.
protection-tamper = Proteção contra violações
protection-tamper-why = Desative esta proteção primeiro para que o Defender permita alterar as outras configurações de proteção.
protection-realtime = Proteção em tempo real
protection-realtime-why = Pause a verificação de arquivos para que o Defender não bloqueie os arquivos de instalação do Atlas.
protection-cloud = Proteção fornecida pela nuvem
protection-cloud-why = Pause as verificações de ameaças online que podem bloquear os arquivos de instalação do Atlas.
protection-samples = Envio automático de amostra
protection-samples-why = Impeça que o Defender envie automaticamente arquivos do Atlas à Microsoft para análise.

## Etapa 4: Instalação

install-preparing-title = Uma última verificação antes de instalar
install-preparing-message = O Atlas está verificando novamente seu PC e as configurações de proteção antes de fazer alterações.
install-installing = Instalando
install-running = Em andamento
# Accessible name of the progress bar.
install-progress = Progresso da instalação
phase-preflight = Verificando seu PC e preparando os arquivos
phase-staging = Preparando os arquivos de instalação
phase-applying = Configurando o Windows. Mantenha o PC ligado.
phase-done = Concluindo a configuração
outcome-succeeded-title = O Atlas foi instalado
outcome-lost-title = Não foi possível confirmar o resultado da instalação
outcome-failed-title = A instalação não foi concluída
outcome-succeeded = Reinicie o PC para concluir a configuração do Atlas.
outcome-requirements = Seu PC não atendeu aos requisitos de instalação. Nenhuma alteração foi feita. Volte à etapa Preparação e execute as verificações novamente.
outcome-not-elevated = Nenhuma alteração foi feita. Reabra o Atlas como administrador e tente novamente.
outcome-failed-preflight = A instalação parou antes de alterar qualquer coisa. Abra o arquivo de log para ver o que aconteceu e depois tente novamente.
outcome-failed-staging = A instalação parou durante a preparação dos arquivos, antes de alterar o Windows. Abra o arquivo de log para ver o que aconteceu e depois tente novamente.
outcome-failed-applying = Algumas alterações podem já ter sido feitas. Se você parar por aqui, reative na Segurança do Windows as proteções que desativou, caso ainda estejam disponíveis.
outcome-not-started = O instalador não iniciou a tempo. Nenhuma alteração foi feita. Escolha Tentar novamente.
outcome-lost = O instalador parou sem informar um resultado, e algumas alterações podem já ter sido feitas. Abra o arquivo de log para ver o que aconteceu e depois escolha Tentar novamente para retomar a instalação.
restart-now-message = O Windows está reiniciando para concluir a configuração do Atlas.
restart-countdown =
    { $seconds ->
        [one] O Windows reinicia em { $seconds } segundo para concluir a configuração do Atlas.
       *[other] O Windows reinicia em { $seconds } segundos para concluir a configuração do Atlas.
    }
restart-stopped = Reinicialização automática cancelada. Salve seu trabalho e depois reinicie o PC para concluir a configuração do Atlas.
restart-needed = Salve seu trabalho e depois reinicie o Windows para concluir a configuração do Atlas.
restart-dont-now = Reiniciar depois
restart-now = Reiniciar agora
# Accessible name of the countdown bar.
restart-progress = Tempo até a reinicialização
restart-start-failed = Não foi possível reiniciar o Windows. Salve seu trabalho e reinicie pelo menu Iniciar. Detalhes: { $error }
preflight-title = A instalação não começou
preflight-invalid-options = O Atlas não conseguiu usar essas escolhas de configuração. Volte à etapa Suas escolhas, revise-as e tente novamente. Detalhes: { $error }
# $problems is a sentence or two built from preflight-problem and preflight-security.
preflight-changed = O estado do seu PC mudou desde as verificações anteriores. Resolva o seguinte antes de tentar novamente. { $problems }
preflight-problem = { $title }: { $detail }
# $summary is the Windows Security summary such as "2 ainda ativadas".
preflight-security = Segurança do Windows: { $summary }.
preflight-busy = Outra janela do Atlas está iniciando uma instalação. Aguarde um momento e tente novamente.
preflight-record-unreadable = O Atlas não conseguiu verificar se a instalação anterior ainda está em andamento, então não iniciou outra. Feche e abra o Atlas novamente para ver as instruções de recuperação. Detalhes: { $error }
preflight-refused = Não foi possível iniciar o instalador. Nenhuma alteração foi feita. Detalhes: { $error }
go-to-ready = Voltar à etapa Preparação
go-to-options = Voltar à etapa Suas escolhas
output-problem-title = Não foi possível ler o progresso da instalação
output-problem-message = O Atlas não conseguiu ler o log. Isso não significa que a instalação parou. Mantenha o PC ligado e tente abrir o arquivo de log. Detalhes: { $error }
install-elevate-title = O Atlas precisa de permissão para instalar
install-no-package-title = Escolha os arquivos de instalação primeiro
install-no-package-message = Volte à etapa Preparação para baixar o Atlas ou abrir um playbook (.apbx) salvo no PC.
install-security-title = Confira a proteção antivírus antes de instalar
install-security-reading = Verificando as quatro proteções novamente.
install-security-message = { $summary }. Antes de continuar, verifique na Segurança do Windows se as quatro proteções estão desativadas.
summary-this-install = Resumo da instalação
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
summary-command-unavailable = Não foi possível preparar o comando de instalação. Detalhes: { $error }
summary-not-chosen = Nenhuma escolha feita ainda
# Accessible name of a Change link. $title is a screen-*-title message.
summary-change-a11y = Alterar { $title }
footer-still-checking = Preparando a instalação
footer-fix-items = Conclua as verificações acima para continuar
footer-need-package = Baixe o Atlas ou abra um playbook para continuar
footer-reading-security = Verificando as proteções
button-checking = Verificando
button-installing = Instalando
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

## A janela "O Atlas foi instalado" após a reinicialização

installed-title-version = O Atlas { $version } foi instalado
installed-title = O Atlas foi instalado
installed-ready = Tudo certo. Seu PC já está pronto para usar com o Atlas.
installed-open-atlas = Ver sua instalação do Atlas

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
# Under "Igual ao Windows": which language that gives. $language is a language's own name.
settings-language-system-detail = Com “Igual ao Windows”: { $language }
# Under a language that is translated but not yet reviewed by a native speaker.
settings-language-preview = Versão prévia · aguardando revisão
preview-notice = { $language } é uma versão prévia da tradução.
preview-notice-switch = Mudar para inglês
preview-notice-language = Alterar idioma
# $tag is a language tag (text).
settings-language-unavailable = { $tag } não está disponível nesta versão do Atlas. Por enquanto, o inglês é exibido, e sua escolha de idioma foi salva.
# $languages is the Windows display-language list (text).
settings-language-windows-unmatched = O Atlas ainda não tem suporte aos seus idiomas de exibição do Windows ({ $languages }). Por enquanto, o inglês é exibido.
settings-language-windows-unavailable = Não foi possível verificar o idioma de exibição do Windows. Por enquanto, o Atlas está em inglês. Detalhes: { $error }
# $locale is the regional format's own name, for example "Português (Brasil)".
settings-language-formats = Números, datas e horas seguem o formato regional do Windows ({ $locale }).
# Link to the i18n folder on GitHub.
settings-language-contribute = Ajudar a traduzir o Atlas no GitHub
settings-installing = Instalação
settings-restart-label = Reiniciar meu PC automaticamente após a instalação
settings-restart-locked = Você poderá alterar isso quando a instalação terminar.
settings-restart-description = É preciso reiniciar para concluir a configuração. Se a reinicialização automática estiver ativada, salve seu trabalho antes de instalar.
settings-about = Sobre
settings-about-app = Atlas Manager
settings-about-data = Arquivos do app
settings-about-licence = Licença
settings-about-licence-value = GPL-3.0, gratuito e de código aberto
settings-view-source = Ver código-fonte no GitHub
settings-open-data-folder = Abrir pasta do app

## Optional choices: explanations shown before selection.

consequence-disable-hibernation = Libera o espaço em disco usado para salvar a sessão durante a hibernação. A hibernação e a inicialização rápida ficarão indisponíveis.
consequence-disable-power-saving = Desativa os recursos de economia de energia. O PC pode consumir mais energia, esquentar mais e ter menos autonomia de bateria.
consequence-disable-core-isolation = Desativa uma camada extra de segurança do Windows, incluindo a integridade da memória. Isso reduz a proteção e pode afetar apps ou jogos que exigem esse recurso.
consequence-remove-snipping-tool = Remove o app do Windows para capturas e gravações de tela.
consequence-uninstall-edge = Remove o navegador Microsoft Edge. Tenha outro navegador instalado ou escolha um abaixo.
consequence-install-another-browser = Escolha um navegador abaixo e o Atlas o instalará para você.

# Introduction on the home page before Atlas is installed.
home-intro = O Atlas ajusta o Windows para reduzir a atividade em segundo plano e as distrações. Vamos orientar você nas verificações e escolhas antes de fazer qualquer alteração.

detail-build-missing = Este playbook não declara nenhuma build compatível do Windows. Escolha um playbook completo em vez de um pacote LocalTest.
## ISO creation (Beta)
iso-home-title = Mídia de instalação do Windows
iso-home-description = Crie uma ISO do Windows com o Atlas para uma instalação do zero neste PC ou em outro.
iso-open = Criar uma ISO com o Atlas
iso-title = Criar uma ISO com o Atlas
iso-beta = Beta
iso-beta-description = Teste a ISO em uma máquina virtual antes de usá-la em um PC. Faça backup dos seus arquivos antes de instalar o Windows.
iso-admin-description = É preciso ter acesso de administrador para ler imagens do Windows e criar mídias de instalação.
iso-files-description = Escolha uma ISO original do Windows 11 x64, um playbook do Atlas (.apbx) e um novo nome de arquivo para o resultado.
iso-source = ISO do Windows
iso-package = Playbook do Atlas (0.6+)
iso-output = Salvar a nova ISO em
iso-no-file = Nenhum arquivo selecionado
iso-browse = Procurar
iso-save-as = Salvar como
iso-inspect = Verificar arquivos
iso-mode-title = Preferências do Windows e do Atlas
iso-mode-interactive = Escolher as opções do Atlas após entrar
iso-mode-interactive-description = Depois de entrar na sua conta, o Atlas ajudará você a atualizar o Windows e os apps da Store, escolher suas opções e aplicar o Atlas.
iso-mode-before = Escolher as opções do Atlas agora
iso-mode-before-description = Salve suas opções do Atlas na ISO. Depois de entrar na sua conta, atualize o Windows e os apps da Store e aplique o Atlas com essas opções.
iso-package-unsupported-title = Escolha um playbook mais recente
iso-package-unsupported = A instalação por ISO exige o Atlas 0.6 ou mais recente com suporte a ISO. Escolha um playbook compatível.
iso-atlas-options = Configurações do Atlas
iso-review = Revisar ISO
iso-review-title = Tudo pronto para criar sua ISO
iso-editions = Edições incluídas: { $editions }
iso-source-size = ISO de origem: { $size } MB
iso-review-description = O Atlas criará uma nova ISO e manterá a original. Inicialize pela nova ISO para instalar o Windows. Criar a ISO não instala o Atlas neste PC.
iso-create = Criar ISO
iso-stage-inspect = Verificando a imagem do Windows
iso-stage-copy = Copiando arquivos do Windows
iso-stage-inject = Adicionando o Atlas
iso-stage-master = Criando a ISO
iso-stage-verify = Verificando o resultado
iso-stage-cleanup = Finalizando
iso-progress-description = Mantenha o aplicativo aberto. Imagens grandes podem demorar para serem processadas.
iso-cancel = Cancelar criação
iso-cancelling = Aguardando um ponto seguro para cancelar
iso-cancelled = Criação da ISO cancelada
iso-cancelled-description = A ISO original foi mantida. O log de diagnóstico informa se ainda há arquivos temporários para remover.
iso-complete = Sua ISO está pronta
iso-complete-description = Teste-a em uma máquina virtual e depois use-a para criar uma mídia de instalação do Windows.
iso-open-folder = Mostrar na pasta
iso-failed = Não foi possível concluir a criação da ISO
iso-failed-description = Abra o diagnóstico para ver o que falhou. Corrija o problema e tente novamente com um novo nome de arquivo.
iso-diagnostics = Abrir diagnóstico
iso-close-title = A ISO ainda está sendo criada
iso-close-message = Mantenha esta janela aberta até a criação ou o cancelamento terminar. O cancelamento aguarda um ponto em que a operação atual possa parar com segurança.
iso-keep-open = Manter aberta
prepare-title = Atualizar o Windows e os apps da Store
prepare-description = Antes de aplicar o Atlas, instale as atualizações do Windows e atualize a Microsoft Store e todos os apps instalados por ela. Os apps da Store podem ser fechados durante as atualizações.
prepare-complete = O Windows e os apps da Store estão atualizados.
prepare-reboot = O Windows precisa reiniciar. Suas escolhas no Atlas serão salvas. Busque atualizações novamente depois de entrar na sua conta.
prepare-failed = Algumas atualizações não foram concluídas. Consulte o log de diagnóstico, resolva os erros do Windows ou da Store e tente novamente.
prepare-cancelled = A preparação foi interrompida. Busque atualizações novamente antes de continuar.
prepare-windows-search = Buscando atualizações do Windows…
prepare-windows-download = Baixando atualizações do Windows…
prepare-windows-install = Instalando atualizações do Windows…
prepare-store-search = Verificando a Microsoft Store…
prepare-store-install = Atualizando a Microsoft Store e seus apps…
prepare-stop-description = A preparação será interrompida quando a atualização em andamento terminar. Mantenha o Atlas aberto até lá.
prepare-stop = Parar após esta operação
prepare-restart = Reiniciar e continuar
prepare-start = Buscar e instalar atualizações
iso-username = Nome da conta local
iso-account-description = O Windows pedirá que você crie uma senha após a reinstalação.
iso-username-placeholder = Seu nome
iso-account-invalid = Use de 1 a 20 caracteres, sem espaços no início ou no fim e sem símbolos não permitidos em nomes de contas do Windows.
iso-privacy-defaults = A instalação do Windows desativa automaticamente o compartilhamento opcional de dados e as ofertas personalizadas.
prepare-drivers = Como os drivers devem ser instalados?
prepare-drivers-auto = Obter drivers pelo Windows Update
prepare-drivers-auto-detail = O Windows encontra drivers para o seu hardware. Recomendado para a maioria dos PCs.
prepare-drivers-manual = Instalar os drivers por conta própria
prepare-drivers-manual-detail = Bloqueia o download de drivers pelo Windows Update. Você precisará obter os drivers por conta própria; os já instalados serão mantidos.
prepare-network-needed = Conecte-se por Wi-Fi ou Ethernet sem conexão limitada e tente novamente. Se o Wi-Fi não aparecer, instale primeiro o driver de rede.
prepare-network-settings = Abrir configurações de rede
iso-target-title = Em qual PC você vai reinstalar o Windows?
iso-target-this = Neste PC
iso-target-other = Em outro PC
iso-copy-network = Incluir os drivers de rede deste PC
iso-network-detail = Reutiliza os drivers de Wi-Fi e Ethernet deste PC durante a instalação do Windows. Você precisará se reconectar ao Wi-Fi depois.
iso-network-source = Origem dos drivers de rede
iso-network-installed = Usar os drivers instalados
iso-network-updated = Verificar o Windows Update primeiro
iso-network-updated-detail = Baixa drivers compatíveis oferecidos pelo Windows Update e mantém os instalados como reserva. Requer uma conexão não limitada.
iso-stage-network-drivers = Preparando os drivers de rede…
iso-network-failed = Não foi possível preparar os drivers de rede. Consulte o diagnóstico ou volte e altere a opção de drivers de rede.
iso-mode-desktop = Concluir a configuração antes da área de trabalho
iso-mode-desktop-description = Escolha as opções do Atlas agora. Após entrar, conclua as atualizações e a configuração antes de abrir a área de trabalho do Windows.
desktop-setup-description = Conclua a configuração do PC. Suas escolhas do Atlas estão salvas; você pode voltar ao Windows se precisar.
desktop-setup-exit = Continuar no Windows

# Windows installation USB (Beta)
usb-title = Criar USB de instalação
usb-existing = Criar um USB a partir de uma ISO existente
usb-description = Crie um USB inicializável do Windows 11 25H2 para instalar o Windows e o Atlas no seu PC.
usb-choose-iso = Escolher ISO
usb-drive = Unidade USB
usb-empty = Conecte uma unidade USB e atualize a lista. Só aparecem unidades USB graváveis que não contêm o Windows em uso.
usb-refresh = Atualizar
usb-drive-detail = { $size } GB · { $volumes } · Série: { $serial }
usb-review = Revisar USB
usb-erase-title = Apagar esta unidade USB?
usb-erase-description = Todos os arquivos e partições de { $drive } ({ $size } GB) serão apagados permanentemente. Sua ISO será mantida.
usb-layout = A instalação do Windows usa até 32 GB. O espaço restante ficará não alocado. Este USB é para PCs que inicializam por UEFI.
usb-ack = Entendo que todo o conteúdo desta unidade USB será apagado.
usb-write = Apagar e criar USB
usb-stage-prepare = Preparando arquivos de instalação…
usb-stage-format = Formatando USB…
usb-stage-copy = Copiando arquivos de instalação…
usb-stage-verify = Verificando USB…
usb-working = Mantenha o Atlas aberto e o USB conectado. O cancelamento espera a operação atual parar com segurança. Um USB incompleto não pode ser usado para instalar o Windows.
usb-failed = Não foi possível concluir a criação do USB. Confira a conexão e abra o diagnóstico para ver os detalhes. Selecione a unidade novamente para tentar outra vez.
usb-cancelled = A criação do USB foi interrompida. A unidade pode conter arquivos de instalação incompletos. Crie-a novamente antes de instalar o Windows.
usb-complete = Seu USB está pronto e todos os arquivos foram verificados. Ejete-o, conecte-o ao PC em que deseja reinstalar o Windows e selecione-o no menu de inicialização UEFI.
usb-eject = Ejetar USB
usb-ejected = Você já pode desconectar o USB com segurança. Para instalar o Windows, selecione-o no menu de inicialização UEFI do PC.
usb-eject-failed = O Windows não conseguiu ejetar o USB. Feche os arquivos ou janelas que estejam usando a unidade e tente novamente.
ready-fresh-title = Comece com uma instalação limpa do Windows
ready-fresh-description = O Atlas exige uma instalação limpa do Windows, exceto para atualizações compatíveis do Atlas. Uma nova instalação do Atlas 0.6 exige o Windows 11 25H2. Faça backup dos seus arquivos antes de reinstalar o Windows.
detail-edition-unsupported = Use o Windows 11 Pro, Pro for Workstations ou Enterprise. As edições Home, LTSC e Server não são compatíveis. Se não foi possível identificar sua edição, resolva o problema antes de continuar.
install-source-title = Instalação indisponível
install-source-unsupported = Não é possível atualizar o Atlas { $source } diretamente para { $target }. Reinstale o Windows para usar esta versão.
install-source-unknown = O Atlas não conseguiu verificar o estado da instalação. Resolva qualquer instalação pendente e consulte o diagnóstico antes de tentar novamente.
iso-edition-selection = Apenas as edições compatíveis são incluídas. Durante a instalação do Windows, escolha uma edição para a qual você tenha uma licença do Windows.
detail-windows-preview = As compilações Insider não são compatíveis. Use uma versão pública do Windows 11.
detail-windows-release-unknown = O Atlas não conseguiu confirmar se esta compilação do Windows é uma versão pública. Conecte-se à internet e verifique novamente.
iso-release-unknown = Não foi possível confirmar se esta ISO contém uma versão pública do Windows 11 25H2. Conecte-se à internet e tente novamente ou escolha uma mídia de instalação oficial.
prepare-previous-worker = Uma atualização anterior ainda está em andamento. O Atlas aguardará a conclusão para que você possa tentar novamente.

ready-used-windows-title = Reinstale o Windows antes de continuar
ready-used-windows-description = Esta instalação do Windows mostra sinais de uso anterior. Instalar o Atlas aqui não tem suporte e é fortemente desaconselhado. Continue apenas se compreender os riscos.
ready-used-windows-dismiss = Compreendo os riscos
playbook-option-install-eclean = Instalar eclean
consequence-install-eclean = Uma ferramenta de manutenção da equipe do AtlasOS para manter seu PC organizado após a configuração. Revise arquivos desnecessários e aplicativos de inicialização. Requer uma conta e conexão com a internet.
