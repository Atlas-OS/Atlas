### Atlas Manager: Spanish (es), preview translation. Revised on 6 September 2026 from the en-GB source (i18n/en-GB/atlas.ftl).
###
### Español internacional (neutro entre España y Latinoamérica). Se trata al
### usuario de usted de forma implícita (imperativos "Seleccione", posesivo
### "su"). Para evitar la diferencia de género de "PC" (el PC / la PC) se usa
### "su PC" con posesivo y "el equipo" cuando hace falta un artículo.
### Los nombres de las funciones de Windows siguen la interfaz de Windows en
### español (Seguridad de Windows, Windows Update, Configuración, Recortes).
### "Volver a abrir" se refiere a la aplicación Atlas; "reiniciar" siempre se
### refiere al PC o a Windows.

## Compartido

app-name = Atlas Manager
common-done = Listo
common-cancel = Cancelar
common-back = Atrás
common-next = Continuar
common-dismiss = Descartar
# Vínculo junto a una fila de resumen que vuelve atrás para cambiar esa elección.
common-change = Cambiar
common-copy = Copiar
# Se muestra cuando una lista de opciones está vacía.
common-none = Ninguna
# Descripción accesible de un control deshabilitado.
common-not-available = No disponible en este momento
# Nombre accesible de la flecha atrás en las páginas Instalación y Configuración.
common-back-to-home = Volver al inicio
# Nombre accesible del botón de engranaje de la barra de título.
common-settings = Configuración
common-close-settings = Cerrar la configuración
common-open-windows-security = Abrir Seguridad de Windows
# Vuelve a abrir la aplicación Atlas con permisos de administrador (no reinicia el PC).
common-restart-as-administrator = Reabrir como administrador
common-try-again = Reintentar
common-read-the-docs = Leer la guía de Atlas
common-show-details = Mostrar detalles
common-hide-details = Ocultar detalles
common-open-log-file = Abrir el archivo de registro
# Nombre accesible del botón Copiar junto al registro de instalación.
common-copy-install-log = Copiar el registro de instalación
common-install-log = Registro de instalación
# Etiquetas de fila en las tarjetas de resumen.
common-windows = Windows
common-options = Opciones
common-package = Archivos de instalación
common-installed-as = Tipo de instalación
common-installed = Instalado
common-checking = Comprobando
# Une dos elementos de una lista: "Brave, Firefox". Las llaves conservan el espacio.
list-separator = { ", " }
# Une dos alternativas: "26100 o 26200".
list-or = { $a } o { $b }

## Ventana

# Cuadro de diálogo que aparece al cerrar la ventana mientras se ejecuta una instalación.
window-close-title = ¿Cerrar la ventana mientras Atlas se instala?
window-close-message = La instalación continuará en segundo plano. Vuelva a abrir Atlas para ver el progreso y el resultado. Mantenga el equipo encendido hasta que termine.
window-close-keep = Mantener abierta
window-close-close = Cerrar la ventana
# Título del selector de archivos para un archivo playbook (.apbx).
file-dialog-open-playbook = Abrir un playbook de Atlas (.apbx)
# Mensaje que Windows muestra en su notificación de reinicio.
shutdown-comment = Atlas está instalado. Windows se reiniciará para terminar la configuración.

## Sistema

# "Windows 11 Pro 25H2 (compilación 26200.1234)". Los tres valores son texto.
system-description = { $product } { $version } (compilación { $build })

## Página de inicio

home-not-installed = Le damos la bienvenida a Atlas
# Titular cuando Atlas está instalado. $version es texto.
home-version = Atlas { $version }
# $date es una fecha con formato.
home-installed-on = Instalado el { $date }
home-status-checking = Buscando actualizaciones
home-status-offline = No se pudieron buscar actualizaciones
home-status-not-checked = Aún no se han buscado actualizaciones
home-status-update = Atlas { $version } está disponible
home-status-up-to-date = Actualizado
home-status-newest = Versión más reciente: Atlas { $version }
home-check-again = Volver a comprobar
# Botón principal mientras una instalación se ejecuta o espera.
home-show-install = Ver el progreso
home-continue-installing = Continuar la configuración
home-update-to = Actualizar a Atlas { $version }
home-reinstall = Reinstalar Atlas
home-install = Instalar Atlas
home-start-over = Empezar de nuevo
home-security-reminder-title = Vuelva a activar la protección
home-security-reminder-message = No hay ninguna instalación en curso. Abra Seguridad de Windows y active la protección contra alteraciones, la protección en tiempo real, la protección basada en la nube y el envío automático de muestras.
home-elevation-title = Atlas necesita permiso para instalar
home-state-error-title = No se pudieron leer los datos de su instalación de Atlas
home-whats-new = Novedades de Atlas { $version }
home-view-release = Ver las notas de la versión en GitHub
home-released = Fecha de publicación: { $date }
home-show-less = Mostrar menos
home-show-full-notes = Mostrar todas las notas de la versión
home-your-install = Su instalación de Atlas
# Etiqueta de fila: cómo se configuró Atlas.
home-set-up = Configurado
home-set-up-during-oobe = Durante la configuración inicial de Windows
home-history = Historial de instalaciones
# Una fila del historial. $version es texto, $mode uno de los mensajes history-mode-*, $date una fecha y hora con formato.
home-history-entry = Atlas { $version } · { $mode } · { $date }
home-how-it-works = Vamos a preparar su PC para Atlas
home-step-1-title = Compruebe su PC
home-step-1-detail = Atlas comprueba Windows y descarga los archivos de instalación. La configuración de Windows no cambia.
home-step-2-title = Elija sus preferencias
home-step-2-detail = Decida cómo administra Windows la protección y las actualizaciones y, si quiere, agregue aplicaciones o ajustes adicionales.
home-step-3-title = Pause la protección antivirus
home-step-3-detail = Atlas le muestra los cuatro interruptores de Seguridad de Windows que debe desactivar para que no bloqueen la instalación.
home-step-4-title = Instale y reinicie
home-step-4-detail =
    { $minutes ->
        [one] Alrededor de un minuto.
       *[other] Alrededor de { $minutes } minutos.
    }
# Nombre accesible de un paso numerado.
home-step-a11y = Paso { $number }: { $title }
home-github = Ver Atlas en GitHub
home-discord = Unirse a la comunidad de Atlas en Discord
home-report-problem = Notificar un problema en GitHub

## Cómo se hizo una instalación (según el documento de estado)

mode-fresh = Primera instalación
mode-upgrade = Actualización desde una versión anterior
mode-reapply = Reinstalación de la misma versión
mode-unknown = Instalación
# Formas en minúscula usadas dentro de una fila del historial.
history-mode-fresh = primera instalación
history-mode-upgrade = actualización
history-mode-reapply = reinstalación
history-mode-unknown = instalación

## Avisos en la página de inicio

notice-settings-reset-title = Atlas está usando la configuración predeterminada de la aplicación
# $error es un mensaje de error sin procesar (texto).
notice-settings-unreadable = Atlas no pudo leer la configuración guardada de la aplicación. La configuración de Windows no ha cambiado. Detalles: { $error }
# $file es un nombre de archivo (texto).
notice-settings-damaged-kept = El archivo de configuración de la aplicación estaba dañado y se restableció. Se guardó una copia del archivo anterior como { $file }. Detalles: { $error }
notice-settings-damaged = El archivo de configuración de la aplicación estaba dañado. Por ahora, Atlas usa los valores predeterminados. Detalles: { $error }
notice-settings-not-saved-title = No se pudo guardar la configuración de la aplicación
notice-session-unreadable-title = No se pudo comprobar la instalación anterior
# $path es una ruta de archivo (texto).
notice-session-unreadable-message = Atlas no puede leer { $path } y necesita saber si todavía hay una instalación en curso. Si tiene dudas, pida ayuda a la comunidad de Atlas antes de eliminar este archivo. Elimínelo y vuelva a intentarlo solo si ha confirmado que no hay ninguna instalación en curso. Detalles: { $error }

## Elevación a administrador

elevation-declined = No se concedió el permiso. Vuelva a intentarlo y elija Sí cuando Windows pregunte si permite que Atlas haga cambios.
elevation-declined-continue = No se concedió el permiso. Vuelva a intentarlo y elija Sí cuando Windows pregunte si permite que Atlas haga cambios. Sus preferencias de configuración están guardadas.
elevation-draft-not-saved = Atlas no pudo guardar sus preferencias de configuración, así que no se ha vuelto a abrir. Vuelva a intentarlo. Detalles: { $error }

## El flujo de instalación

step-ready = Preparación
step-options = Sus preferencias
step-security = Seguridad de Windows
step-install = Instalación
install-title = Configurar Atlas
# Nombre accesible de la fila de pasos.
stepper-label = Pasos de la configuración de Atlas
# Nombre accesible de un paso. $status es uno de los mensajes stepper-status-*.
stepper-step-a11y = Paso { $number } de { $total }, { $title }, { $status }
stepper-status-completed = completado
stepper-status-current = paso actual
stepper-status-upcoming = paso pendiente
# Encabezado sobre el contenido de cada paso.
step-heading = Paso { $number } de { $total }: { $title }

## Paso 1: Preparación

ready-banner-busy-title = Preparando su PC
ready-banner-busy-message = Atlas está comprobando su PC y preparando los archivos de instalación.
ready-banner-blocked-title = Su PC necesita un poco de preparación
ready-banner-blocked-message = Siga las instrucciones de abajo y luego elija Volver a comprobar.
ready-banner-no-package-title = Descargue Atlas para continuar
ready-banner-no-package-message = Descargue la versión más reciente abajo o abra un playbook de Atlas (.apbx) guardado.
ready-banner-warnings-title = Algunos puntos que revisar
ready-banner-warnings-message = Lea las notas de abajo y siga los pasos recomendados antes de continuar.
ready-banner-ok-title = Ya puede elegir sus preferencias
ready-banner-ok-message = Las comprobaciones son correctas y los archivos de instalación están listos.

# Título de la tarjeta y nombre accesible de la lista de comprobaciones.
ready-this-pc = Comprobaciones del equipo
ready-check-again = Volver a comprobar

package-title = Archivos de instalación
# $received y $total son números de megabytes con formato (texto).
package-downloading = Descargando Atlas { $version } · { $received } de { $total } MB
package-unpacking-progress =
    { $total ->
        [one] Extrayendo · { $done } de { $total } archivo
       *[other] Extrayendo · { $done } de { $total } archivos
    }
package-unpacking = Extrayendo
package-looking = Buscando la versión más reciente de Atlas.
package-none = Aún no hay archivos de instalación. Un playbook (.apbx) contiene las instrucciones y los archivos que Atlas necesita.
# Palabras de estado breves junto al título de la tarjeta.
package-status-downloading = Descargando
package-status-unpacking = Extrayendo
package-status-failed = Error al preparar
package-status-ready = Listos
package-status-checking = Comprobando
package-status-missing = Sin descargar
# Nombre accesible de la barra de progreso.
package-progress = Progreso de los archivos de instalación
package-download-again = Volver a descargar
package-download-version = Descargar Atlas { $version }
package-download-newest = Descargar la versión más reciente
package-open-file = Abrir un archivo playbook
# De dónde procede el paquete. $file es un nombre de archivo, $path una ruta de carpeta (texto).
package-from-release = Atlas { $version } se descargó de GitHub y está listo para instalar.
package-from-file = Atlas { $version } se cargó desde { $file } y está listo para instalar.
package-unpacked = Atlas { $version } está listo para instalar.
package-at = Archivos de instalación: { $path }
package-none-yet = No se han seleccionado archivos de instalación
acquire-no-asset = Atlas { $version } no tiene ningún archivo playbook disponible para descargar. Para continuar, abra un playbook de Atlas (.apbx) guardado.
acquire-unsupported = Esta aplicación puede instalar Atlas 0.6.0 y versiones posteriores. Para instalar Atlas { $version }, use AME Wizard.
acquire-failed = No se pudieron preparar los archivos de instalación. Vuelva a descargarlos o abra otro playbook de Atlas (.apbx). Detalles: { $error }

## Comprobaciones del sistema

check-administrator = Permiso para instalar
check-supported-build = Compatibilidad con Windows
check-pending-updates = Actualizaciones de Windows
check-pending-reboot = Reinicio pendiente
check-third-party-antivirus = Otro software antivirus
check-internet = Conexión a Internet
check-power = Alimentación eléctrica
check-activation = Activación de Windows
# Nombre accesible de una fila de comprobación. $state es uno de los mensajes check-state-*.
check-a11y = { $title }: { $state }
check-state-checking = comprobando
check-state-passed = correcto
check-state-warning = requiere atención
check-state-failed-blocking = requiere una acción antes de instalar
check-state-failed = requiere atención
check-state-unknown = no se pudo comprobar
check-fix-windows-update = Abrir Windows Update
check-fix-network = Abrir la configuración de red
check-fix-power = Abrir la configuración de energía
check-fix-activation = Abrir la configuración de activación
# Casillas que el usuario marca cuando una comprobación no se pudo ejecutar.
check-ack-updates = He comprobado Windows Update: no hay actualizaciones pendientes de instalar
check-ack-reboot = He reiniciado Windows y no hace falta otro reinicio
check-ack-internet = Este equipo está conectado a Internet
check-ack-generic = He comprobado este requisito por mi cuenta

detail-admin-ok = Atlas tiene permiso para hacer los cambios que requiere la instalación.
detail-admin-missing = Vuelva a abrir Atlas como administrador y elija Sí cuando Windows le pida permiso.
# $builds es una lista de números de compilación como "26100 o 26200"; $build es la de este equipo (texto).
detail-build-unsupported = Esta versión de Atlas requiere la compilación { $builds } de Windows. Su PC tiene la compilación { $build }. Instale una versión compatible de Windows antes de continuar.
detail-updates-none = No hay actualizaciones de Windows pendientes de instalar.
# $titles enumera hasta dos nombres de actualización (texto); $count es el total.
detail-updates-pending =
    { $count ->
        [1] Instale primero esta actualización: { $titles }.
        [2] Instale primero estas actualizaciones: { $titles }.
       *[other] Instale primero { $count } actualizaciones, entre ellas { $titles }.
    }
detail-updates-unknown = No se pudieron buscar actualizaciones de Windows. Abra Windows Update y, si no hay actualizaciones pendientes, confírmelo abajo. ({ $error })
detail-reboot-none = Windows no necesita reiniciarse ahora.
detail-reboot-pending = Reinicie su PC para completar cambios anteriores; después, vuelva a abrir Atlas y elija Volver a comprobar.
detail-reboot-unknown = No se pudo comprobar si Windows necesita reiniciarse. Reinicie su PC; después, vuelva a abrir Atlas y elija Volver a comprobar. ({ $error })
detail-antivirus-none = No se detectó otro software antivirus.
# $products es una lista de nombres de producto (texto).
detail-antivirus-found = Este software antivirus puede bloquear la instalación: { $products }. Desinstálelo antes de continuar.
detail-antivirus-unknown = No se pudo comprobar si hay otro software antivirus. Revise las aplicaciones instaladas antes de continuar. ({ $error })
detail-internet-ok = Hay conexión a Internet. Manténgala disponible mientras Atlas descarga e instala software.
detail-internet-missing = Conéctese a Internet y vuelva a comprobar.
detail-power-mains = El equipo está conectado a la corriente. Manténgalo conectado hasta que termine la instalación.
detail-power-battery = Conecte el equipo a la corriente para que siga encendido durante toda la instalación.
detail-power-unknown = No se pudo comprobar la alimentación eléctrica. Si usa un equipo portátil, conéctelo a la corriente antes de continuar.
detail-activation-ok = Windows está activado. Atlas no cambiará esto.
detail-activation-missing = Windows no está activado. Puede continuar, pero Atlas no activará Windows.
detail-activation-no-licence = Windows no informó de ninguna licencia. Puede continuar; Atlas no cambiará el estado de activación.
detail-activation-unknown = No se pudo comprobar la activación de Windows. Puede continuar; Atlas no cambiará el estado de activación. ({ $error })

## Paso 2: Opciones

options-progress = Decisión { $number } de { $total }
options-progress-extras = Decisión { $number } de { $total }: extras opcionales
# Nombres cortos de cada decisión (filas de resumen) y la pregunta de cada pantalla.
screen-defender-title = Microsoft Defender
screen-defender-question = ¿Mantener la protección antivirus activada?
screen-mitigations-title = Seguridad del procesador
screen-mitigations-question = ¿Mantener las protecciones de Windows para el procesador?
screen-updates-title = Windows Update
screen-updates-question = ¿Cómo debe instalar Windows las actualizaciones?
screen-browser-title = Navegador
screen-power-title = Energía y seguridad
screen-apps-title = Aplicaciones
screen-toolbox-title = Atlas Toolbox
screen-choose-one-title = Elija una opción
screen-extras-title = Extras opcionales
screen-extras-question = Elija los extras que quiera
# Pregunta para una elección obligatoria para la que esta aplicación no tiene un texto específico.
screen-generic-question = Elija una opción para { $title }
learn-more-defender = Más información sobre Microsoft Defender
learn-more-mitigations = Más información sobre la seguridad del procesador
learn-more-updates = Más información sobre Windows Update
learn-more-browser = Más información sobre los navegadores
learn-more-power = Más información sobre energía y seguridad
learn-more-apps = Más información sobre las aplicaciones
learn-more-toolbox = Más información sobre Atlas Toolbox
learn-more-generic = Leer la guía de configuración
# Una línea bajo cada respuesta: qué significa para el equipo.
consequence-defender-enable = Conserva el antivirus integrado de Windows para ayudar a proteger su PC frente a virus y otras amenazas.
consequence-defender-disable = Quita Microsoft Defender. Su PC no tendrá protección antivirus hasta que instale otra aplicación antivirus.
consequence-mitigations-default = Mantiene las protecciones predeterminadas de Windows frente a ataques que aprovechan el funcionamiento del procesador.
consequence-mitigations-disable = Desactiva estas protecciones y reduce la seguridad. El rendimiento depende del procesador y puede empeorar.
consequence-auto-updates-disable = Tendrá que abrir Windows Update e instalar las actualizaciones por su cuenta. Seguirá recibiendo notificaciones de actualizaciones.
consequence-auto-updates-default = Windows instalará las actualizaciones automáticamente, incluidas las correcciones de seguridad.

## Texto del playbook
## El paquete playbook incluye su propio texto en inglés para cada opción. Estas
## etiquetas y explicaciones solo se usan cuando el texto del paquete coincide con
## i18n/playbook-source.ftl. Un paquete futuro con otro texto conserva sus propias
## palabras en lugar de recibir una descripción que podría estar obsoleta.

playbook-option-defender-enable = Conservar Microsoft Defender (recomendado)
playbook-option-defender-disable = Quitar Microsoft Defender
playbook-option-mitigations-default = Mantener las protecciones predeterminadas (recomendado)
playbook-option-mitigations-disable = Desactivar las protecciones del procesador
playbook-option-auto-updates-disable = Instalar las actualizaciones por mi cuenta
playbook-option-auto-updates-default = Instalar las actualizaciones automáticamente
playbook-option-disable-hibernation = Desactivar la hibernación
playbook-option-disable-power-saving = Desactivar el ahorro de energía
playbook-option-disable-core-isolation = Desactivar la seguridad basada en virtualización (VBS)
playbook-option-remove-snipping-tool = Quitar la aplicación Recortes
playbook-option-uninstall-edge = Quitar Microsoft Edge
playbook-option-install-another-browser = Instalar un navegador
playbook-option-install-toolbox = Instalar Atlas Toolbox
playbook-option-browser-brave = Brave
playbook-option-browser-librewolf = LibreWolf
playbook-option-browser-firefox = Firefox
playbook-option-browser-chrome = Chrome
playbook-page-defender-enable-description = Microsoft Defender es el antivirus integrado de Windows. Se recomienda conservarlo. Quítelo solo si entiende los riesgos y piensa usar otra aplicación antivirus.
playbook-page-mitigations-default-description = Estas protecciones, también llamadas mitigaciones de seguridad, ayudan a defenderse de las vulnerabilidades del procesador. Se recomienda mantener los valores predeterminados de Windows.
playbook-page-auto-updates-disable-description = Las actualizaciones de Windows incluyen correcciones de seguridad. Puede dejar que Windows las instale automáticamente o instalarlas por su cuenta.
playbook-page-install-toolbox-description = Agregue Atlas Toolbox para administrar la configuración de Atlas con más facilidad. Toolbox está en versión beta, así que algunas funciones pueden estar sin terminar.
playbook-page-browser-brave-description = Elija un navegador para instalar. Atlas no cambiará la configuración de su navegador.

## Paso 3: Seguridad de Windows

security-banner-reading-title = Comprobando Seguridad de Windows
security-banner-reading-message = Atlas está comprobando los cuatro interruptores de protección de abajo.
security-banner-off-title = Los cuatro interruptores de protección están desactivados
security-banner-off-message = Ya puede revisar sus preferencias antes de instalar.
security-banner-readable-off-title = Los interruptores que Atlas pudo comprobar están desactivados
security-banner-readable-off-message = Compruebe los demás interruptores en Seguridad de Windows.
security-banner-on-title = Desactive temporalmente la protección antivirus
security-banner-on-message = Estas protecciones pueden bloquear los cambios que Atlas necesita hacer.
# El nombre de la página en Seguridad de Windows.
security-list-title = Configuración de antivirus y protección contra amenazas
security-switch-off = Desactivado
security-switch-on = Activado
security-switch-unreadable = No se pudo comprobar
security-switch-reading = Comprobando
security-all-off = Todo desactivado
# Nombre accesible de una fila de interruptor. $state es uno de los mensajes security-switch-*.
security-a11y = { $title }: { $state }
# Partes del resumen "2 aún activados, 1 no se pudo comprobar".
security-count-still-on =
    { $count ->
        [one] { $count } aún activado
       *[other] { $count } aún activados
    }
security-count-unreadable = { $count } sin comprobar
security-count-join = { $a }, { $b }
security-unknown-title = Confirme los interruptores que Atlas no pudo comprobar
security-unknown-message = Cuando haya comprobado en Seguridad de Windows que los cuatro interruptores están desactivados, confírmelo abajo.
security-acknowledge = He comprobado Seguridad de Windows y los cuatro interruptores están desactivados
security-unknown-unelevated-title = Atlas necesita permiso para comprobar la protección
security-unknown-unelevated-message = Vuelva a abrir Atlas como administrador para que pueda comprobar la configuración de Microsoft Defender.
# Los cuatro interruptores, con los nombres que usa Seguridad de Windows en español.
protection-tamper = Protección contra alteraciones
protection-tamper-why = Desactívela primero para que Defender permita cambiar su configuración de protección.
protection-realtime = Protección en tiempo real
protection-realtime-why = Pause el análisis de archivos para que Defender no bloquee los archivos de instalación de Atlas.
protection-cloud = Protección basada en la nube
protection-cloud-why = Pause las comprobaciones de amenazas en línea que podrían bloquear los archivos de instalación de Atlas.
protection-samples = Envío automático de muestras
protection-samples-why = Evite que Defender envíe automáticamente archivos de Atlas a Microsoft para su análisis.

## Paso 4: Instalación

install-preparing-title = Una última comprobación antes de instalar
install-preparing-message = Atlas vuelve a comprobar su PC y la configuración de protección antes de hacer cambios.
install-installing = Instalando
install-running = En curso
# Nombre accesible de la barra de progreso.
install-progress = Progreso de la instalación
phase-preflight = Comprobando su PC y preparando los archivos
phase-staging = Preparando los archivos de instalación
phase-applying = Configurando Windows. Mantenga el equipo encendido.
phase-done = Terminando la configuración
outcome-succeeded-title = Atlas está instalado
outcome-lost-title = No se pudo confirmar el resultado de la instalación
outcome-failed-title = La instalación no terminó
outcome-succeeded = Reinicie su PC para terminar de configurar Atlas.
outcome-requirements = Su PC no cumplía los requisitos de instalación. No se hizo ningún cambio. Vuelva a Preparación y ejecute de nuevo las comprobaciones.
outcome-not-elevated = No se hizo ningún cambio. Vuelva a abrir Atlas como administrador e inténtelo de nuevo.
outcome-failed-preflight = La instalación se detuvo antes de cambiar nada. Abra el archivo de registro para ver qué ocurrió y vuelva a intentarlo.
outcome-failed-staging = La instalación se detuvo al preparar los archivos, antes de cambiar Windows. Abra el archivo de registro para ver qué ocurrió y vuelva a intentarlo.
outcome-failed-applying = Puede que ya se hayan hecho algunos cambios. Si se detiene aquí, vuelva a activar en Seguridad de Windows las protecciones que desactivó, si siguen disponibles.
outcome-not-started = El instalador no se inició a tiempo. No se hizo ningún cambio. Elija Reintentar.
outcome-lost = El instalador se detuvo sin informar del resultado y puede que ya se hayan hecho algunos cambios. Abra el archivo de registro para ver qué ocurrió y elija Reintentar para reanudar.
restart-now-message = Windows se está reiniciando para terminar de configurar Atlas.
restart-countdown =
    { $seconds ->
        [one] Windows se reiniciará en { $seconds } segundo para que Atlas pueda terminar la configuración.
       *[other] Windows se reiniciará en { $seconds } segundos para que Atlas pueda terminar la configuración.
    }
restart-stopped = Reinicio automático cancelado. Guarde su trabajo y reinicie su PC para terminar de configurar Atlas.
restart-needed = Guarde su trabajo y reinicie Windows para terminar de configurar Atlas.
restart-dont-now = Reiniciar más tarde
restart-now = Reiniciar ahora
# Nombre accesible de la barra de cuenta atrás.
restart-progress = Tiempo hasta el reinicio
restart-start-failed = No se pudo reiniciar Windows. Guarde su trabajo y reinicie desde el menú Inicio. Detalles: { $error }
preflight-title = La instalación no se ha iniciado
preflight-invalid-options = Atlas no pudo usar estas preferencias de configuración. Vuelva al paso Sus preferencias, revíselas y vuelva a intentarlo. Detalles: { $error }
# $problems es una o dos frases formadas a partir de preflight-problem y preflight-security.
preflight-changed = El estado de su PC cambió después de las comprobaciones anteriores. Resuelva lo siguiente antes de volver a intentarlo. { $problems }
preflight-problem = { $title }: { $detail }
# $summary es el resumen de Seguridad de Windows, como "2 aún activados".
preflight-security = Seguridad de Windows: { $summary }.
preflight-busy = Otra ventana de Atlas está iniciando una instalación. Espere un momento y vuelva a intentarlo.
preflight-record-unreadable = Atlas no pudo comprobar si la instalación anterior sigue en curso, así que no ha iniciado otra. Cierre Atlas y vuelva a abrirlo para ver las instrucciones de recuperación. Detalles: { $error }
preflight-refused = No se pudo iniciar el instalador. No se hizo ningún cambio. Detalles: { $error }
go-to-ready = Volver a Preparación
go-to-options = Volver a Sus preferencias
output-problem-title = No se pudo leer el progreso de la instalación
output-problem-message = Atlas no pudo leer el registro. Esto no significa que la instalación se haya detenido. Mantenga el equipo encendido e intente abrir el archivo de registro. Detalles: { $error }
install-elevate-title = Atlas necesita permiso para instalar
install-no-package-title = Elija primero los archivos de instalación
install-no-package-message = Vuelva a Preparación para descargar Atlas o abrir un playbook (.apbx) guardado.
install-security-title = Compruebe la protección antivirus antes de instalar
install-security-reading = Comprobando de nuevo los cuatro interruptores de protección.
install-security-message = { $summary }. Abra Seguridad de Windows y asegúrese de que los cuatro interruptores estén desactivados antes de continuar.
summary-this-install = Resumen de la instalación
summary-try-again = Revise antes de reintentar
summary-ready = Revise su configuración de Atlas
summary-activation = Activación
summary-activation-ok = Windows está activado. Atlas no cambiará esto.
summary-activation-missing = Windows no está activado. Puede continuar, pero Atlas no activará Windows.
summary-activation-unknown = Atlas no cambiará el estado de activación de Windows.
summary-duration = Tiempo estimado
summary-duration-value =
    { $minutes ->
        [one] { $minutes } minuto y después un reinicio
       *[other] { $minutes } minutos y después un reinicio
    }
summary-restart-checkbox = Reiniciar mi PC automáticamente al terminar la instalación
summary-show-command = Mostrar el comando de instalación
summary-hide-command = Ocultar el comando de instalación
summary-command-unavailable = No se pudo preparar el comando de instalación. Detalles: { $error }
summary-not-chosen = Aún sin elegir
# Nombre accesible de un vínculo Cambiar. $title es un mensaje screen-*-title.
summary-change-a11y = Cambiar { $title }
footer-still-checking = Preparando la instalación
footer-fix-items = Complete las comprobaciones de arriba para continuar
footer-need-package = Descargue Atlas o abra un playbook para continuar
footer-reading-security = Comprobando los interruptores de protección
button-checking = Comprobando
button-installing = Instalando
button-install = Instalar Atlas
log-earlier-lines =
    { $count ->
        [one] Hay { $count } línea anterior en el archivo de registro.
       *[other] Hay { $count } líneas anteriores en el archivo de registro.
    }
# Se añade al copiar el registro. $path es una ruta de archivo (texto).
log-full-log-note = (registro completo: { $path })

## La vista de instalación en curso

installing-checking-title = Una última comprobación
installing-checking-line = Atlas está comprobando su PC antes de hacer cambios. Puede tardar un momento.
installing-title = Instalando Atlas
installing-phase-preflight = Comprobando su PC y preparando los archivos de instalación.
installing-phase-staging = Preparando los archivos de instalación. Mantenga el equipo encendido.
installing-phase-applying = Configurando Windows con sus preferencias. Mantenga el equipo encendido y conectado a la corriente.
installing-phase-done = Terminando la instalación. Mantenga el equipo encendido.
installing-installed-title = Atlas está instalado
# $time es una hora con formato.
installing-started-just-now = Inicio: { $time }, hace menos de un minuto
installing-started-minutes =
    { $minutes ->
        [one] Inicio: { $time }, hace un minuto
       *[other] Inicio: { $time }, hace { $minutes } minutos
    }

## La ventana "Atlas está instalado" tras el reinicio

installed-title-version = Atlas { $version } está instalado
installed-title = Atlas está instalado
installed-ready = Todo listo. Ya puede usar su PC con Atlas.
installed-open-atlas = Ver su instalación de Atlas

## Configuración

settings-title = Configuración
settings-theme = Tema de la aplicación
settings-theme-system = Igual que Windows
settings-theme-light = Claro
settings-theme-dark = Oscuro
settings-theme-contrast-note = Atlas está usando los colores del tema de contraste de Windows.
settings-theme-mica-note = Para ver el fondo translúcido, elija el mismo tema, claro u oscuro, que usa Windows.
settings-language = Idioma
settings-language-system = Igual que Windows
# Bajo "Igual que Windows": qué idioma resulta. $language es el nombre del idioma en ese idioma.
settings-language-system-detail = Con la opción Igual que Windows: { $language }
# Bajo un idioma traducido pero aún no revisado por un hablante nativo; esos idiomas nunca se eligen automáticamente.
settings-language-preview = Versión preliminar · pendiente de revisión lingüística
preview-notice = { $language } es una traducción preliminar.
preview-notice-switch = Cambiar a inglés
preview-notice-language = Cambiar idioma
# $tag es una etiqueta de idioma (texto).
settings-language-unavailable = { $tag } no está disponible en esta versión de Atlas. Por ahora se muestra en inglés y su elección de idioma se conserva.
# $languages es la lista de idiomas para mostrar de Windows (texto).
settings-language-windows-unmatched = Atlas aún no está disponible en sus idiomas para mostrar de Windows ({ $languages }). Por ahora se muestra en inglés.
settings-language-windows-unavailable = No se pudo comprobar el idioma para mostrar de Windows. Por ahora, Atlas se muestra en inglés. Detalles: { $error }
# $locale es el nombre del formato regional en su propio idioma, por ejemplo "Español (España)".
settings-language-formats = Los números, las fechas y las horas siguen el formato regional de Windows ({ $locale }).
settings-language-contribute = Ayudar a traducir Atlas en GitHub
settings-installing = Instalación
settings-restart-label = Reiniciar mi PC automáticamente al terminar la instalación
settings-restart-locked = Podrá cambiar esto cuando termine la instalación.
settings-restart-description = Hace falta reiniciar para terminar la configuración. Si el reinicio automático está activado, guarde su trabajo antes de instalar.
settings-about = Acerca de
settings-about-app = Atlas Manager
settings-about-data = Archivos de la aplicación
settings-about-licence = Licencia
settings-about-licence-value = GPL-3.0, gratuito y de código abierto
settings-view-source = Ver el código fuente en GitHub
settings-open-data-folder = Abrir la carpeta de la aplicación

## Opciones adicionales: explicaciones que se muestran antes de elegir.

consequence-disable-hibernation = Libera el espacio en disco que se usa para guardar la sesión al hibernar. Las opciones Hibernar e Inicio rápido dejarán de estar disponibles.
consequence-disable-power-saving = Desactiva las funciones de ahorro de energía. Su PC puede consumir más energía, calentarse más y tener menos autonomía.
consequence-disable-core-isolation = Desactiva una capa adicional de seguridad de Windows, incluida la integridad de memoria. Esto reduce la protección y puede afectar a las aplicaciones o juegos que la requieren.
consequence-remove-snipping-tool = Quita la aplicación de Windows para hacer capturas y grabaciones de pantalla.
consequence-uninstall-edge = Quita el navegador Microsoft Edge. Asegúrese de tener otro navegador o elija uno abajo.
consequence-install-another-browser = Elija un navegador abajo y Atlas lo instalará por usted.

# Introducción de la página de inicio antes de instalar Atlas.
home-intro = Atlas ajusta Windows para reducir la actividad en segundo plano y las distracciones. Le guiaremos por las comprobaciones y las decisiones antes de hacer cambios.

detail-build-missing = Este playbook no declara ninguna compilación de Windows compatible. Elija una compilación completa del playbook en lugar de un paquete LocalTest.
## ISO creation (Beta)
iso-home-title = Medio de instalación de Windows
iso-home-description = Cree una ISO de Windows con Atlas para realizar una instalación limpia en este equipo o en otro.
iso-open = Crear una ISO con Atlas
iso-title = Crear una ISO con Atlas
iso-beta = Beta
iso-beta-description = Pruebe la ISO en una máquina virtual antes de usarla en un equipo. Haga una copia de seguridad de sus archivos antes de instalar Windows.
iso-admin-description = Se necesitan permisos de administrador para leer imágenes de Windows y crear medios de instalación.
iso-files-description = Seleccione una ISO original de Windows 11 para x64, un playbook de Atlas (.apbx) y un nombre nuevo para el archivo de salida.
iso-source = ISO de Windows
iso-package = Playbook de Atlas (0.6+)
iso-output = Guardar la nueva ISO en
iso-no-file = Ningún archivo seleccionado
iso-browse = Examinar
iso-save-as = Guardar como
iso-inspect = Comprobar archivos
iso-mode-title = Opciones de Windows y Atlas
iso-mode-interactive = Elegir las opciones de Atlas al iniciar sesión
iso-mode-interactive-description = Tras iniciar sesión, Atlas le ayudará a actualizar Windows y las aplicaciones de la Store, elegir sus opciones y aplicar Atlas.
iso-mode-before = Elegir ahora las opciones de Atlas
iso-mode-before-description = Guarde sus opciones de Atlas en la ISO. Tras iniciar sesión, actualice Windows y las aplicaciones de la Store y aplique Atlas con estas opciones.
iso-package-unsupported-title = Elige un playbook más reciente
iso-package-unsupported = La instalación desde ISO requiere Atlas 0.6 o posterior con soporte para ISO. Seleccione un playbook compatible.
iso-atlas-options = Ajustes de Atlas
iso-review = Revisar ISO
iso-review-title = Todo listo para crear su ISO
iso-editions = Ediciones incluidas: { $editions }
iso-source-size = ISO de origen: { $size } MB
iso-review-description = Atlas creará una ISO nueva y conservará el archivo original. Arranque desde la nueva ISO para instalar Windows. Crear la ISO no instala Atlas en este equipo.
iso-create = Crear ISO
iso-stage-inspect = Comprobando la imagen de Windows
iso-stage-copy = Copiando archivos de Windows
iso-stage-inject = Añadiendo Atlas
iso-stage-master = Creando la ISO
iso-stage-verify = Verificando el resultado
iso-stage-cleanup = Finalizando
iso-progress-description = Mantenga la aplicación abierta. Procesar imágenes grandes puede tardar un rato.
iso-cancel = Cancelar creación
iso-cancelling = Esperando un punto seguro para cancelar
iso-cancelled = Creación de la ISO cancelada
iso-cancelled-description = La ISO original se conserva. El registro de diagnóstico indica si quedan archivos temporales por eliminar.
iso-complete = Su ISO está lista
iso-complete-description = Pruébela en una máquina virtual y úsela después para crear un medio de instalación de Windows.
iso-open-folder = Mostrar en la carpeta
iso-failed = No se ha podido terminar de crear la ISO
iso-failed-description = Abra los diagnósticos para ver qué ha fallado. Corrija el problema e inténtelo de nuevo con otro nombre de archivo.
iso-diagnostics = Abrir diagnóstico
iso-close-title = La ISO se está creando
iso-close-message = Mantenga esta ventana abierta hasta que termine la creación o la cancelación. La cancelación espera a que la operación en curso pueda detenerse de forma segura.
iso-keep-open = Mantener abierta
prepare-title = Actualizar Windows y las apps de la Store
prepare-description = Antes de aplicar Atlas, instale las actualizaciones de Windows y actualice Microsoft Store y todas sus aplicaciones instaladas. Las aplicaciones de Store pueden cerrarse durante la actualización.
prepare-complete = Windows y las apps de la Store están al día.
prepare-reboot = Windows necesita reiniciarse. Sus opciones de Atlas se guardarán. Vuelva a buscar actualizaciones cuando inicie sesión.
prepare-failed = No se pudieron completar algunas actualizaciones. Revise el registro de diagnóstico, resuelva los errores de Windows o la Store e inténtelo de nuevo.
prepare-cancelled = Se ha detenido la preparación. Vuelva a buscar actualizaciones antes de continuar.
prepare-windows-search = Buscando actualizaciones de Windows…
prepare-windows-download = Descargando actualizaciones de Windows…
prepare-windows-install = Instalando actualizaciones de Windows…
prepare-store-search = Comprobando Microsoft Store…
prepare-store-install = Actualizando Microsoft Store y sus apps…
prepare-stop-description = La preparación se detendrá cuando termine la operación de actualización en curso. Mantenga Atlas abierto hasta entonces.
prepare-stop = Detener tras esta operación
prepare-restart = Reiniciar y continuar
prepare-start = Buscar e instalar actualizaciones
iso-username = Nombre de la cuenta local
iso-account-description = Windows le pedirá que cree una contraseña después de reinstalarlo.
iso-username-placeholder = Su nombre
iso-account-invalid = Use entre 1 y 20 caracteres, sin espacios al principio ni al final ni símbolos no permitidos en las cuentas de Windows.
iso-privacy-defaults = Durante la instalación, Windows desactiva automáticamente el envío opcional de datos y las ofertas personalizadas.
prepare-drivers = ¿Cómo desea instalar los controladores?
prepare-drivers-auto = Obtener controladores mediante Windows Update
prepare-drivers-auto-detail = Windows busca los controladores adecuados para su equipo. Recomendado para la mayoría de los equipos.
prepare-drivers-manual = Instalar los controladores por mi cuenta
prepare-drivers-manual-detail = Se bloquea la descarga de controladores desde Windows Update. Deberá obtenerlos por su cuenta; los ya instalados se conservan.
prepare-network-needed = Conéctese por Wi-Fi o Ethernet sin uso medido y vuelva a intentarlo. Si no aparece Wi-Fi, instale primero el controlador de red.
prepare-network-settings = Abrir la configuración de red
iso-target-title = ¿En qué equipo reinstalará Windows?
iso-target-this = En este equipo
iso-target-other = En otro equipo
iso-copy-network = Incluir los controladores de red de este equipo
iso-network-detail = Reutiliza los controladores de Wi-Fi y Ethernet de este equipo durante la instalación de Windows. Deberá volver a conectarse al Wi-Fi después.
iso-network-source = Origen de los controladores de red
iso-network-installed = Usar los controladores instalados
iso-network-updated = Buscar primero en Windows Update
iso-network-updated-detail = Descarga controladores compatibles ofrecidos por Windows Update y conserva los instalados como respaldo. Requiere una conexión sin uso medido.
iso-stage-network-drivers = Preparando los controladores de red…
iso-network-failed = No se pudieron preparar los controladores de red. Consulte el diagnóstico o vuelva atrás y cambie la opción de controladores de red.
iso-mode-desktop = Completar la configuración antes del escritorio
iso-mode-desktop-description = Elija ahora las opciones de Atlas. Tras iniciar sesión, complete las actualizaciones y la configuración antes de abrir el escritorio de Windows.
desktop-setup-description = Complete la configuración del equipo. Sus opciones de Atlas están guardadas; puede volver a Windows si lo necesita.
desktop-setup-exit = Continuar en Windows

# Windows installation USB (Beta)
usb-title = Crear USB de instalación
usb-existing = Crear un USB a partir de una ISO existente
usb-description = Cree un USB de arranque de Windows 11 25H2 para instalar Windows y Atlas en su PC.
usb-choose-iso = Elegir ISO
usb-drive = Unidad USB
usb-empty = Conecte una unidad USB y actualice la lista. Solo se muestran unidades USB con permiso de escritura que no contienen la instalación de Windows en uso.
usb-refresh = Actualizar
usb-drive-detail = { $size } GB · { $volumes } · Serie: { $serial }
usb-review = Revisar USB
usb-erase-title = ¿Borrar esta unidad USB?
usb-erase-description = Se borrarán permanentemente todos los archivos y particiones de { $drive } ({ $size } GB). Su ISO se conservará.
usb-layout = La instalación de Windows usa hasta 32 GB. El espacio restante quedará sin asignar. Este USB es para equipos que arrancan mediante UEFI.
usb-ack = Entiendo que se borrará todo el contenido de esta unidad USB.
usb-write = Borrar y crear USB
usb-stage-prepare = Preparando archivos de instalación…
usb-stage-format = Formateando USB…
usb-stage-copy = Copiando archivos de instalación…
usb-stage-verify = Verificando USB…
usb-working = Mantenga Atlas abierto y el USB conectado. Al cancelar, se espera a que la operación actual se detenga de forma segura. Un USB incompleto no permite instalar Windows.
usb-failed = No se pudo terminar de crear el USB. Compruebe la conexión y abra el diagnóstico para ver los detalles. Vuelva a seleccionar la unidad para reintentarlo.
usb-cancelled = Se detuvo la creación del USB. La unidad puede contener archivos de instalación incompletos. Créela de nuevo antes de instalar Windows.
usb-complete = Su USB está listo y se han verificado todos los archivos. Expúlselo, conéctelo al PC que desea reinstalar y selecciónelo en su menú de arranque UEFI.
usb-eject = Expulsar USB
usb-ejected = Ya puede desconectar el USB con seguridad. Para instalar Windows, selecciónelo en el menú de arranque UEFI de su PC.
usb-eject-failed = Windows no pudo expulsar el USB. Cierre los archivos o ventanas que lo estén usando y vuelva a intentarlo.
ready-fresh-title = Empieza con una instalación limpia de Windows
ready-fresh-description = Atlas requiere una instalación limpia de Windows, salvo para las actualizaciones de Atlas compatibles. Una instalación nueva de Atlas 0.6 requiere Windows 11 25H2. Haz una copia de seguridad de tus archivos antes de reinstalar Windows.
detail-edition-unsupported = Usa Windows 11 Pro, Pro for Workstations o Enterprise. Las ediciones Home, LTSC y Server no son compatibles. Si no se pudo identificar tu edición, resuelve el problema antes de continuar.
install-source-title = Instalación no disponible
install-source-unsupported = Atlas { $source } no se puede actualizar directamente a { $target }. Reinstala Windows para usar esta versión.
install-source-unknown = Atlas no ha podido comprobar el estado de la instalación. Resuelve cualquier instalación pendiente y revisa el diagnóstico antes de volver a intentarlo.
iso-edition-selection = Solo se incluyen las ediciones compatibles. Durante la instalación de Windows, elige una edición para la que tengas una licencia de Windows.
detail-windows-preview = Las compilaciones Insider no son compatibles. Usa una versión pública de Windows 11.
detail-windows-release-unknown = Atlas no pudo confirmar que esta compilación de Windows sea una versión pública. Conéctate a internet y vuelve a comprobarlo.
iso-release-unknown = No se pudo confirmar que esta ISO contenga una versión pública de Windows 11 25H2. Conéctate a internet e inténtalo de nuevo, o elige un medio de instalación oficial.
prepare-previous-worker = Una actualización anterior sigue en curso. Atlas esperará a que termine para que puedas volver a intentarlo.
