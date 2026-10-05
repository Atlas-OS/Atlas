### Atlas Manager: Spanish (es), preview translation. Revised on 1 October 2026 from the en-GB source (i18n/en-GB/atlas.ftl).
###
### Español internacional (neutro entre España y Latinoamérica). Se trata al
### usuario de usted de forma implícita (imperativos "Seleccione", posesivo
### "su"). Para evitar la diferencia de género de "PC" (el PC / la PC) se usa
### "su PC" con posesivo y "el equipo" cuando hace falta un artículo.
### Los nombres de las funciones de Windows siguen la interfaz de Windows en
### español (Seguridad de Windows, Windows Update, Configuración, Recortes).
### "Volver a abrir" se refiere a la aplicación Atlas; "reiniciar" siempre se
### refiere al PC o a Windows. El archivo .apbx es el "paquete de Atlas" ("el
### paquete" cuando ya está claro); "playbook" solo aparece donde se explica
### que AME Wizard lo llama así.

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
# Accessible name of a Show details or Hide details toggle. $action is common-show-details or
# common-hide-details; $section is the title of the card it opens.
common-details-a11y = { $action }, { $section }
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
list-and = { $a } y { $b }
# Accessible name of a message bar that announces itself: its title, then its message.
infobar-a11y = { $title }. { $message }

## Ventana

# Cuadro de diálogo que aparece al cerrar la ventana mientras se ejecuta una instalación.
window-close-title = ¿Cerrar la ventana mientras Atlas se instala?
window-close-message = La instalación continuará en segundo plano. Vuelva a abrir Atlas para ver el progreso y el resultado. Mantenga el equipo encendido hasta que termine.
# Instead of window-close-message when the installation restarts the PC afterwards: only an
# open Atlas window restarts it, so closing the window cancels that.
window-close-message-restart = La instalación continuará en segundo plano, pero su PC no se reiniciará automáticamente mientras Atlas esté cerrado. Vuelva a abrir Atlas para ver el progreso y el resultado. Mantenga el equipo encendido hasta que termine.
window-close-keep = Mantener abierta
window-close-close = Cerrar la ventana
# Cuadro de diálogo que aparece al cerrar la ventana durante las últimas comprobaciones, antes de
# que se inicie el instalador; sus botones son window-close-keep y window-close-close.
window-close-preparing-title = ¿Cerrar antes de que empiece la instalación?
window-close-preparing-message = Atlas todavía está comprobando su PC y aún no ha empezado a instalar. Si cierra ahora, la instalación no se iniciará. Vuelva a abrir Atlas para continuar.
prepare-close-title = Las actualizaciones siguen en curso
# "Stop updating" is prepare-stop, the dialog's other button.
prepare-close-message = Mantenga Atlas abierto mientras se instalan las actualizaciones. Si elige Detener actualizaciones, se detendrán tras el paso actual y entonces podrá cerrar Atlas.
# Cuadro de diálogo que aparece al cerrar la ventana durante la cuenta atrás del reinicio tras una
# instalación correcta. Sus botones son window-close-keep, restart-now y window-close-restart-close.
window-close-restart-title = ¿Cerrar Atlas sin reiniciar?
# "Reiniciar ahora" es restart-now, uno de los tres botones de este cuadro de diálogo.
window-close-restart-message = Su PC debe reiniciarse para terminar de configurar Atlas. Si cierra Atlas ahora, su PC no se reiniciará, así que reinícielo por su cuenta cuando le convenga. Guarde su trabajo antes de elegir Reiniciar ahora.
window-close-restart-close = Cerrar sin reiniciar
# Dialog shown when the window is closed during a setup with Windows Security switches still
# off. $switches names them as Windows Security does, joined like a list. Its buttons are
# window-close-keep, common-open-windows-security and window-close-close.
window-close-protection-title = ¿Cerrar Atlas con la protección desactivada?
window-close-protection-message = Parte de la protección de Seguridad de Windows sigue desactivada: { $switches }. Si no va a terminar de instalar Atlas, vuelva a activarla antes de cerrar. Si va a terminar la instalación, Atlas continuará la configuración cuando vuelva a abrirlo.
# Título del selector de archivos para un paquete de Atlas (.apbx).
file-dialog-open-package = Abrir un paquete de Atlas (.apbx)
# Mensaje que Windows muestra en su notificación de reinicio.
shutdown-comment = Atlas está instalado. Windows se reiniciará para terminar la configuración.
# Mensaje que Windows muestra en su notificación de reinicio cuando Preparación
# reinicia para terminar de instalar actualizaciones de Windows.
prepare-shutdown-comment = Atlas está reiniciando Windows para terminar de instalar las actualizaciones.

## Sistema

# "Windows 11 Pro 25H2 (compilación 26200.1234)". Los tres valores son texto.
system-description = { $product } { $version } (compilación { $build })

## Página de inicio

home-not-installed = Le damos la bienvenida a Atlas
# Titular cuando Atlas Manager no puede saber qué hay instalado en este equipo.
home-state-unknown = Atlas en este equipo
# Titular cuando Atlas está instalado. $version es texto.
home-version = Atlas { $version }
# $date es una fecha con formato.
home-installed-on = Instalado el { $date }
home-status-checking = Buscando actualizaciones
# Mientras el inicio comprueba si se está ejecutando la instalación de otra ventana.
home-status-recovering = Buscando una instalación en curso
home-status-offline = No se pudieron buscar actualizaciones
home-status-not-checked = Aún no se han buscado actualizaciones
home-status-update = Atlas { $version } está disponible
home-status-up-to-date = Actualizado
home-status-newest = Versión más reciente: Atlas { $version }
# Una instalación anterior de Atlas { $version } se detuvo antes de terminar.
home-status-unfinished = Instalación de Atlas { $version } sin terminar
home-check-again = Volver a comprobar
# Botón principal mientras una instalación se ejecuta o espera.
home-show-install = Ver el progreso
home-continue-installing = Continuar la configuración
home-update-to = Actualizar a Atlas { $version }
home-reinstall = Reinstalar Atlas
home-install = Instalar Atlas
home-finish-install = Terminar de instalar Atlas { $version }
home-start-over = Empezar de nuevo
home-restart-title = Su PC necesita reiniciarse
home-security-reminder-title = Vuelva a activar la protección
# Instead of home-security-reminder-title when no switch reads off but some couldn't be read
# (with home-security-reminder-unreadable-message).
home-security-reminder-unreadable-title = Asegúrese de que la protección esté activada
home-security-reminder-message = Atlas no está instalando nada, pero parte de la protección de Seguridad de Windows sigue desactivada. Abra Seguridad de Windows y asegúrese de que estos interruptores estén activados: { $switches }.
home-security-reminder-unreadable-message = Atlas no pudo comprobar todos los interruptores de protección. Compruebe en Seguridad de Windows que estos interruptores estén activados: { $switches }.
home-elevation-title = Atlas necesita permiso para instalar
home-state-error-title = No se pudieron leer los datos de su instalación de Atlas
home-state-error-message = Puede que su versión de Atlas, sus preferencias y su historial no se muestren correctamente. Elija Volver a comprobar para reintentarlo. Detalles: { $error }
home-whats-new = Novedades de Atlas { $version }
home-view-release = Ver las notas de la versión en GitHub
home-released = Fecha de publicación: { $date }
home-show-less = Mostrar menos
home-show-full-notes = Mostrar todas las notas de la versión
home-your-install = Su instalación de Atlas
# Atlas está instalado, pero sin el registro que guarda Atlas Manager (las versiones anteriores no lo creaban).
home-install-unrecorded = Este equipo no tiene ningún registro de cómo se instaló Atlas, así que no se pueden mostrar sus preferencias ni el historial de instalaciones.
# Etiqueta de fila: cómo se configuró Atlas.
home-set-up = Configurado
home-set-up-during-oobe = Durante la configuración inicial de Windows
home-history = Historial de instalaciones
# Una fila del historial. $version es texto, $mode uno de los mensajes history-mode-*, $date una fecha y hora con formato.
home-history-entry = Atlas { $version } · { $mode } · { $date }
home-how-it-works = Vamos a preparar su PC para Atlas
home-step-1-detail = Atlas comprueba su PC, instala las actualizaciones pendientes de Windows y de Microsoft Store, y descarga los archivos de instalación. Es posible que se cierren aplicaciones de la Store y que su PC tenga que reiniciarse, así que guarde antes su trabajo.
# Versión de prueba: el paquete de Atlas viene incluido, no se descarga nada.
home-step-1-detail-bundled = Atlas comprueba su PC, instala las actualizaciones pendientes de Windows y de Microsoft Store, y prepara los archivos de instalación incluidos. Es posible que se cierren aplicaciones de la Store y que su PC tenga que reiniciarse, así que guarde antes su trabajo.
home-step-2-detail = Decida si conserva Microsoft Defender y las protecciones del procesador, cómo se instalan las actualizaciones de Windows y qué extras opcionales quiere.
home-step-3-detail = Desactive cuatro interruptores de protección en Seguridad de Windows para que no bloqueen la instalación. Atlas le muestra cómo hacerlo.
home-step-4-detail =
    { $minutes ->
        [one] La instalación tarda alrededor de un minuto. Después, su PC necesita reiniciarse.
       *[other] La instalación tarda alrededor de { $minutes } minutos. Después, su PC necesita reiniciarse.
    }
# Nombre accesible de un paso numerado.
home-step-a11y = Paso { $number }: { $title }
home-github = Ver Atlas en GitHub
home-discord = Unirse a la comunidad de Atlas en Discord
home-report-problem = Notificar un problema

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
# $error es un mensaje de error sin procesar (texto).
notice-settings-not-saved = Atlas no pudo guardar sus últimos cambios, así que podrían perderse al cerrar Atlas. Si hay otra ventana de Atlas abierta, ciérrela y vuelva a hacer el cambio. Detalles: { $error }
notice-session-unreadable-title = No se pudo comprobar la instalación anterior
# $path es una ruta de archivo (texto).
notice-session-unreadable-message = Atlas no pudo saber si una instalación anterior sigue en curso. Si tiene dudas, pida ayuda a la comunidad de Atlas. Solo si sabe con certeza que no hay ninguna en curso, elimine { $path } y vuelva a intentarlo. Detalles: { $error }

## Elevación a administrador

elevation-declined = No se concedió el permiso. Vuelva a intentarlo y elija Sí cuando Windows pregunte si permite que Atlas haga cambios.
elevation-declined-continue = No se concedió el permiso. Vuelva a intentarlo y elija Sí cuando Windows pregunte si permite que Atlas haga cambios. Sus preferencias de configuración están guardadas.
elevation-draft-not-saved = Atlas no pudo guardar sus preferencias de configuración, así que no se ha vuelto a abrir. Vuelva a intentarlo. Detalles: { $error }
# Se muestra con el botón home-start-over.
elevation-taken-over = Otra ventana de Atlas está usando ahora esta configuración, así que Atlas no se ha vuelto a abrir. Continúe en esa ventana o elija Empezar de nuevo para volver a configurar Atlas aquí.

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
stepper-status-attention = requiere atención
# Encabezado sobre el contenido de cada paso.
step-heading = Paso { $number } de { $total }: { $title }
# Accessible name of the step heading on a screen of Your choices, read when it takes focus.
# $heading is step-heading; $progress is options-progress; $question is the screen's question.
step-heading-choice-a11y = { $heading }. { $progress }: { $question }
# The same on the optional extras screen; $progress is options-progress-extras.
step-heading-extras-a11y = { $heading }. { $progress }

## Paso 1: Preparación

ready-banner-busy-title = Preparando su PC
ready-banner-busy-message = Atlas está comprobando su PC y preparando los archivos de instalación.
ready-banner-blocked-title = El equipo aún no está listo
ready-banner-blocked-message = Resuelva los puntos marcados en Comprobaciones del equipo y elija Volver a comprobar.
ready-banner-no-package-title = Descargue Atlas para continuar
ready-banner-no-package-message = Descargue Atlas en Archivos de instalación o, si ya tiene un paquete de Atlas (.apbx), elija Abrir un archivo de paquete.
# Versión de prueba: no se pudo extraer el paquete de Atlas incluido.
ready-banner-no-package-bundled-title = Prepare el paquete de Atlas incluido para continuar
ready-banner-no-package-bundled-message = El paquete de Atlas incluido en esta versión de prueba aún no está listo. Revise la tarjeta Archivos de instalación.
ready-banner-updates-title = Actualice Windows y las aplicaciones de la Store para continuar
ready-banner-updates-message = Elija Buscar e instalar actualizaciones. Cuando terminen las actualizaciones, Atlas volverá a comprobar su PC.
# While Windows and Store apps update. "Update Windows and Store apps" is prepare-title, the
# card further down the page.
ready-banner-updating-title = Actualizando Windows y las aplicaciones de la Store
ready-banner-updating-message = Esto puede tardar un rato. Mantenga Atlas abierto. El progreso se muestra en Actualizar Windows y las apps de la Store.
# After Stop updating. "Check and install updates" is prepare-start, the card's button.
ready-banner-updates-stopped-title = La actualización se detuvo
ready-banner-updates-stopped-message = Elija Buscar e instalar actualizaciones en Actualizar Windows y las apps de la Store para terminar.
# Atlas reopened after restarting the PC to continue updating. "Continue updates" is
# prepare-continue, the card's button.
ready-banner-updates-resumed-title = Su PC se ha reiniciado
ready-banner-updates-resumed-message = Elija Continuar actualizaciones en Actualizar Windows y las apps de la Store para terminar de actualizar.
# Under prepare-failed-title or prepare-unconfirmed-title. "Try again" is common-try-again,
# the card's button.
ready-banner-updates-failed-message = Consulte en Actualizar Windows y las apps de la Store qué debe hacer y, después, elija Reintentar.
# Under prepare-reboot-title. "Restart and continue" is prepare-restart, the card's button.
ready-banner-reboot-message = Guarde antes su trabajo y, después, elija Reiniciar y continuar en Actualizar Windows y las apps de la Store.
ready-banner-warnings-title = Algunos puntos que revisar
ready-banner-warnings-message = Puede continuar, pero antes lea los puntos marcados en Comprobaciones del equipo.
ready-banner-ok-title = Ya puede elegir sus preferencias
ready-banner-ok-message = Las comprobaciones son correctas y los archivos de instalación están listos.

# Título de la tarjeta y nombre accesible de la lista de comprobaciones.
ready-this-pc = Comprobaciones del equipo
ready-check-again = Volver a comprobar
ready-checks-passed =
    { $count ->
        [one] { $count } comprobación superada
       *[other] { $count } comprobaciones superadas
    }

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
# Versión de prueba: se está extrayendo el paquete de Atlas incluido, no se descarga nada.
package-looking-bundled = Preparando el paquete de Atlas incluido.
package-none = Descargue Atlas para obtener los archivos de instalación. Si ya tiene un paquete de Atlas (.apbx), ábralo en su lugar.
# No se pudo consultar la versión en GitHub. "Descargar la versión más reciente" es package-download-newest,
# el botón que se ofrece en este estado; vuelve a comprobarlo.
package-release-failed = Atlas no pudo buscar la versión más reciente. Compruebe su conexión a Internet y elija Descargar la versión más reciente, o abra un paquete de Atlas (.apbx) guardado.
# Palabras de estado breves junto al título de la tarjeta.
package-status-downloading = Descargando
package-status-unpacking = Extrayendo
package-status-failed = Error al preparar
package-status-ready = Listos
package-status-checking = Comprobando
package-status-preparing = Preparando
package-status-missing = Sin descargar
# Nombre accesible de la barra de progreso.
package-progress = Progreso de los archivos de instalación
package-download-again = Volver a descargar
package-download-version = Descargar Atlas { $version }
package-download-newest = Descargar la versión más reciente
package-cancel-download = Cancelar descarga
package-open-file = Abrir un archivo de paquete
# De dónde procede el paquete. $file es un nombre de archivo, $path una ruta de carpeta (texto).
package-from-release = Atlas { $version } se descargó de GitHub y está listo para instalar.
package-from-file = Atlas { $version } se cargó desde { $file } y está listo para instalar.
package-unpacked = Atlas { $version } está listo para instalar.
package-none-yet = No se han seleccionado archivos de instalación
acquire-no-asset = Atlas { $version } no tiene ningún archivo de paquete para descargar. Para continuar, abra un paquete de Atlas (.apbx) guardado.
acquire-unsupported = Esta aplicación puede instalar Atlas 0.6.0 y versiones posteriores. Para instalar Atlas { $version }, use AME Wizard.
# Un paquete lo bastante reciente para incluir el script de instalación que usa esta aplicación, pero sin él.
acquire-incomplete = A Atlas { $version } le faltan archivos que esta aplicación necesita para instalarlo. Vuelva a descargarlo o abra otro paquete de Atlas (.apbx).
acquire-failed = No se pudieron preparar los archivos de instalación. Vuelva a descargarlos o abra otro paquete de Atlas (.apbx). Detalles: { $error }
# La descarga no recibió nada durante un minuto y se detuvo.
acquire-stalled = La descarga dejó de responder. Compruebe su conexión a Internet y vuelva a intentar la descarga, o abra un paquete de Atlas (.apbx) guardado.
# Versión de prueba: no se pudo extraer el paquete de Atlas incluido. Reintentar es el único control que se ofrece.
acquire-failed-bundled = No se pudo preparar el paquete de Atlas incluido. Elija Reintentar. Detalles: { $error }

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
check-fix-apps = Abrir Aplicaciones instaladas
# Casilla que el usuario marca cuando no se pudo ejecutar la búsqueda de Windows Update.
check-ack-updates = He comprobado Windows Update: no hay actualizaciones pendientes de instalar

detail-admin-ok = Atlas tiene permiso para hacer los cambios que requiere la instalación.
detail-admin-missing = Vuelva a abrir Atlas como administrador y elija Sí cuando Windows le pida permiso.
# $builds es una lista de números de compilación como "26100 o 26200"; $build es la de este equipo (texto).
detail-build-unsupported = Esta versión de Atlas requiere la compilación { $builds } de Windows. Su PC tiene la compilación { $build }. Instale una versión compatible de Windows antes de continuar.
detail-build-missing = Este paquete de Atlas no indica ninguna compilación de Windows compatible. Use una compilación completa del paquete en lugar de una compilación LocalTest.
detail-updates-none = No hay actualizaciones de Windows pendientes de instalar.
# $titles enumera hasta dos nombres de actualización (texto); $count es el total.
detail-updates-pending =
    { $count ->
        [1] Esta actualización está pendiente: { $titles }. Atlas la instalará en Actualizar Windows y las apps de la Store.
        [2] Estas actualizaciones están pendientes: { $titles }. Atlas las instalará en Actualizar Windows y las apps de la Store.
       *[other] Hay { $count } actualizaciones pendientes, entre ellas { $titles }. Atlas las instalará en Actualizar Windows y las apps de la Store.
    }
detail-updates-unknown = No se pudieron buscar actualizaciones de Windows. Abra Windows Update y, si no hay actualizaciones pendientes, confírmelo abajo. ({ $error })
detail-reboot-none = Windows no necesita reiniciarse ahora.
detail-reboot-pending = Windows necesita reiniciarse para completar cambios anteriores. Cuando elija Buscar e instalar actualizaciones, Atlas le pedirá que reinicie primero.
# $reasons: los marcadores de reinicio pendiente que dejó Windows, a partir de los nombres prepare-reason-*.
detail-reboot-pending-reasons = Windows necesita reiniciarse para completar cambios anteriores ({ $reasons }). Cuando elija Buscar e instalar actualizaciones, Atlas le pedirá que reinicie primero.
# Aviso, no un bloqueo: $files enumera hasta tres rutas de archivo que Windows reemplazará o eliminará en el próximo reinicio.
detail-reboot-file-renames = Puede continuar. Windows tiene archivos pendientes de reemplazar o eliminar en el próximo reinicio ({ $files }). Algunas aplicaciones, como Xbox Gaming Services, hacen esto después de cada reinicio.
detail-reboot-unknown = No se pudo comprobar si Windows necesita reiniciarse. Reinicie su PC; después, vuelva a abrir Atlas y elija Volver a comprobar. ({ $error })
detail-antivirus-none = No se detectó otro software antivirus.
# $products es una lista de nombres de producto (texto).
detail-antivirus-found = Las aplicaciones antivirus distintas de Microsoft Defender pueden bloquear la instalación. Desinstale { $products } y elija Volver a comprobar.
# Advertencia, no un bloqueo: el Centro de seguridad todavía muestra el producto, pero sus archivos ya no están.
detail-antivirus-stale = Seguridad de Windows todavía muestra { $products }, pero sus archivos ya no están, así que ya no está instalado. Atlas se puede instalar de todos modos.
detail-antivirus-unknown = No se pudo comprobar si hay otro software antivirus. Elija Volver a comprobar. Si sigue fallando, reinicie su PC y vuelva a comprobarlo. ({ $error })
detail-internet-ok = Hay conexión a Internet. Manténgala disponible mientras Atlas descarga e instala software.
detail-internet-missing = Conéctese a Internet y vuelva a comprobar.
detail-power-mains = El equipo está conectado a la corriente. Manténgalo conectado hasta que termine la instalación.
detail-power-battery = Conecte el equipo a la corriente para que siga encendido durante toda la instalación.
detail-power-unknown = Atlas no pudo saber si el equipo está conectado a la corriente. Si es un equipo portátil, conéctelo a la corriente y elija Volver a comprobar. Si esto sigue ocurriendo, elija Enviar un informe.
detail-activation-ok = Windows está activado. Atlas no cambiará esto.
detail-activation-missing = Windows no está activado. Puede continuar, pero Atlas no activará Windows.
detail-activation-no-licence = Windows no informó de ninguna licencia. Puede continuar; Atlas no cambiará el estado de activación.
detail-activation-unknown = No se pudo comprobar la activación de Windows. Puede continuar; Atlas no cambiará el estado de activación. ({ $error })

## Paso 2: Opciones

options-progress = Decisión { $number } de { $total }
options-progress-extras = Decisión { $number } de { $total }: extras opcionales
options-change-later = Más adelante puede cambiar Microsoft Defender, las protecciones del procesador y la configuración de actualizaciones desde la carpeta Atlas de su escritorio.
# Nombres cortos de cada decisión (filas de resumen) y la pregunta de cada pantalla.
screen-defender-title = Microsoft Defender
screen-defender-question = ¿Conservar Microsoft Defender?
screen-mitigations-title = Protecciones del procesador
screen-mitigations-question = ¿Mantener las protecciones de Windows para el procesador?
screen-updates-title = Windows Update
screen-updates-question = ¿Cómo debe instalar Windows las actualizaciones?
screen-browser-title = Navegador
screen-power-title = Energía y seguridad
screen-apps-title = Aplicaciones
screen-optional-apps-title = Aplicaciones opcionales
screen-choose-one-title = Elija una opción
screen-extras-title = Extras opcionales
# Pregunta para una elección obligatoria para la que esta aplicación no tiene un texto específico.
screen-generic-question = Elija una opción para { $title }
learn-more-defender = Más información sobre Microsoft Defender
learn-more-mitigations = Más información sobre las protecciones del procesador
learn-more-updates = Más información sobre Windows Update
learn-more-browser = Más información sobre los navegadores
learn-more-power = Más información sobre energía y seguridad
learn-more-apps = Más información sobre las aplicaciones
learn-more-eclean = Cómo funciona eclean con AtlasOS
learn-more-generic = Leer la guía de configuración
# Una línea bajo cada respuesta: qué significa para el equipo.
consequence-defender-enable = Conserva el antivirus integrado de Windows para ayudar a proteger su PC frente a virus y otras amenazas.
consequence-defender-disable = También quita SmartScreen. Su PC no tendrá protección antivirus hasta que instale otra aplicación antivirus, y Windows no le avisará antes de que abra aplicaciones o descargas no reconocidas.
consequence-mitigations-default = Mantiene las protecciones predeterminadas de Windows contra las vulnerabilidades del procesador y los ataques que aprovechan errores de las aplicaciones.
consequence-mitigations-disable = También desactiva la Protección contra vulnerabilidades de las aplicaciones, como la Protección de flujo de control (CFG). Esto reduce la seguridad. La posible diferencia de rendimiento depende de su procesador.
consequence-auto-updates-disable = Abra Windows Update con regularidad para instalar las actualizaciones. Las notificaciones de actualizaciones seguirán activadas.
consequence-auto-updates-default = Windows instalará las actualizaciones automáticamente, incluidas las correcciones de seguridad.

## Texto del paquete de Atlas
## El paquete de Atlas incluye su propio texto en inglés para cada opción. Estas
## etiquetas y explicaciones solo se usan cuando el texto del paquete coincide con
## i18n/playbook-source.ftl. Un paquete futuro con otro texto conserva sus propias
## palabras en lugar de recibir una descripción que podría estar obsoleta.

playbook-option-defender-enable = Conservar Microsoft Defender (recomendado)
playbook-option-defender-disable = Quitar Microsoft Defender
playbook-option-mitigations-default = Mantener las protecciones del procesador (recomendado)
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
playbook-option-install-eclean = Instalar eclean
playbook-option-browser-brave = Brave
playbook-option-browser-librewolf = LibreWolf
playbook-option-browser-firefox = Firefox
playbook-option-browser-chrome = Chrome
playbook-page-defender-enable-description = Microsoft Defender es el antivirus integrado en Windows. Quítelo solo si entiende los riesgos y piensa usar otra aplicación antivirus. Sea cual sea su elección, Atlas desactiva el Control inteligente de aplicaciones, la Protección mejorada contra suplantación de identidad y Encontrar mi dispositivo.
playbook-page-mitigations-default-description = Estas protecciones, también llamadas mitigaciones de seguridad, ayudan a proteger contra las vulnerabilidades del procesador, como Spectre y Meltdown, y contra los ataques que aprovechan errores de las aplicaciones. Se recomienda mantener la configuración predeterminada de Windows.
playbook-page-auto-updates-disable-description = Las actualizaciones de Windows incluyen correcciones de seguridad. Puede dejar que Windows las instale automáticamente o instalarlas por su cuenta. En ambos casos, Atlas mantiene Windows en su versión actual, que solo recibe correcciones de seguridad hasta que Microsoft deje de darle soporte. Atlas también desactiva las actualizaciones automáticas de las aplicaciones de Microsoft Store, así que actualícelas desde Microsoft Store.
playbook-page-browser-brave-description = Elija un navegador para instalar. Atlas no cambiará la configuración de su navegador.

## Paso 3: Seguridad de Windows

security-banner-reading-title = Comprobando Seguridad de Windows
security-banner-reading-message = Atlas está comprobando los cuatro interruptores de protección de abajo.
security-banner-off-title = Los cuatro interruptores de protección están desactivados
# Shown instead of the switch list when an earlier Atlas install removed Microsoft Defender.
security-banner-absent-title = Microsoft Defender no está instalado en este equipo
security-banner-absent-message = No hay nada que desactivar en este paso. Elija Continuar.
security-banner-off-message = Elija Continuar para revisar su configuración e instalar Atlas.
security-banner-on-title = Desactive la protección antivirus en Seguridad de Windows
security-banner-on-message = Microsoft Defender puede bloquear los cambios que hace Atlas. Elija Abrir Seguridad de Windows y desactive cada uno de los interruptores de la lista de abajo. Si conserva Microsoft Defender, vuelva a activar los interruptores cuando termine la instalación.
# El nombre de la página en Seguridad de Windows.
security-list-title = Configuración de antivirus y protección contra amenazas
security-switch-off = Desactivado
security-switch-on = Activado
security-switch-unreadable = No se pudo comprobar
security-switch-reading = Comprobando
security-all-off = Todo desactivado
# Nombre accesible de una fila de interruptor. $state es uno de los mensajes security-switch-*.
security-a11y = { $title }: { $state }
# Partes del resumen "2 aún activados, 1 sin comprobar".
security-count-still-on =
    { $count ->
        [one] { $count } aún activado
       *[other] { $count } aún activados
    }
security-count-unreadable = { $count } sin comprobar
security-count-join = { $a }, { $b }
security-unknown-title = Confirme los interruptores que Atlas no pudo comprobar
security-unknown-message = Asegúrese de que los cuatro interruptores estén desactivados en Seguridad de Windows y, después, confírmelo abajo.
security-acknowledge = He comprobado Seguridad de Windows y los cuatro interruptores están desactivados
security-unknown-unelevated-title = Atlas necesita permiso para comprobar la protección
security-unknown-unelevated-message = Vuelva a abrir Atlas como administrador para que pueda comprobar la configuración de Microsoft Defender.
# Los cuatro interruptores, con los nombres que usa Seguridad de Windows en español.
protection-tamper = Protección contra alteraciones
protection-tamper-why = Desactívela para que Defender no impida a Atlas cambiar la configuración de seguridad de Defender.
protection-realtime = Protección en tiempo real
protection-realtime-why = Desactívela para que Defender no bloquee los archivos de instalación de Atlas al analizarlos.
protection-cloud = Protección basada en la nube
protection-cloud-why = Desactívela para que las comprobaciones de amenazas en línea no bloqueen los archivos de instalación de Atlas.
protection-samples = Envío automático de muestras
protection-samples-why = Evite que Defender envíe automáticamente archivos de Atlas a Microsoft para su análisis.

## Paso 4: Instalación

# Nombre accesible de la barra de progreso.
install-progress = Progreso de la instalación
# El progreso de la instalación junto a la barra. $percent es un número entero de 0 a 99.
install-percent = { $percent } %
outcome-succeeded-title = Atlas está instalado
outcome-lost-title = No se pudo confirmar el resultado de la instalación
outcome-failed-title = La instalación no terminó
outcome-requirements = Su PC no cumplía los requisitos de instalación. No se hizo ningún cambio. Vuelva a Preparación y ejecute de nuevo las comprobaciones.
# Las variantes -resumed aparecen al reintentar una instalación que un intento anterior ya había empezado a aplicar.
outcome-requirements-resumed = Su PC no cumplía los requisitos de instalación, así que este intento se detuvo. Un intento anterior ya había empezado a hacer cambios. Vuelva a Preparación y ejecute de nuevo las comprobaciones.
outcome-not-elevated = Atlas no tenía permisos de administrador. No se hizo ningún cambio. Vuelva a abrir Atlas como administrador e inténtelo de nuevo.
outcome-not-elevated-resumed = Atlas no tenía permisos de administrador, así que este intento se detuvo. Un intento anterior ya había empezado a hacer cambios. Vuelva a abrir Atlas como administrador e inténtelo de nuevo.
# La comprobación del instalador encontró actualizaciones de Windows o de la Store sin terminar. Preparación
# vuelve a ofrecer la búsqueda; "Buscar e instalar actualizaciones" es prepare-start, su botón en ese estado.
outcome-preparation-stale = Atlas no pudo confirmar que Windows y las aplicaciones de la Store estén al día, así que la instalación se detuvo antes de cambiar Windows. Vuelva a Preparación y elija Buscar e instalar actualizaciones.
outcome-preparation-stale-resumed = Atlas no pudo confirmar que Windows y las aplicaciones de la Store estén al día, así que este intento se detuvo, pero un intento anterior ya había empezado a hacer cambios. Vuelva a Preparación y elija Buscar e instalar actualizaciones.
outcome-failed-preflight = La instalación se detuvo antes de cambiar nada. Puede volver a intentarlo. Si vuelve a detenerse, elija Enviar un informe.
outcome-failed-staging = La instalación se detuvo al preparar los archivos, antes de cambiar Windows. Puede volver a intentarlo. Si vuelve a detenerse, elija Enviar un informe.
outcome-failed-applying = Es posible que ya se hayan hecho algunos cambios. Puede volver a intentarlo. Si decide no continuar, vuelva a activar en Seguridad de Windows las protecciones que desactivó, si siguen disponibles.
outcome-failed-resumed = Este intento se detuvo antes de tiempo, pero un intento anterior ya había empezado a hacer cambios. Puede volver a intentarlo. Si decide no continuar, vuelva a activar en Seguridad de Windows las protecciones que desactivó, si siguen disponibles.
outcome-not-started = El instalador no se inició a tiempo. No se hizo ningún cambio. Puede volver a intentarlo.
outcome-lost = El instalador se detuvo sin informar de un resultado, y es posible que ya se hayan hecho algunos cambios. Puede volver a intentarlo. Si decide no continuar, vuelva a activar en Seguridad de Windows las protecciones que desactivó, si siguen disponibles.
restart-now-message = Windows se está reiniciando para terminar de configurar Atlas.
restart-countdown =
    { $seconds ->
        [one] Windows se reiniciará en { $seconds } segundo para terminar de configurar Atlas. Para guardar antes su trabajo, elija Reiniciar más tarde.
       *[other] Windows se reiniciará en { $seconds } segundos para terminar de configurar Atlas. Para guardar antes su trabajo, elija Reiniciar más tarde.
    }
restart-stopped = Reinicio automático cancelado. Guarde su trabajo y reinicie su PC para terminar de configurar Atlas.
restart-needed = Guarde su trabajo y reinicie su PC para terminar de configurar Atlas.
restart-dont-now = Reiniciar más tarde
restart-now = Reiniciar ahora
restart-start-failed = Atlas no pudo reiniciar su PC. Guarde su trabajo y reinícielo desde el menú Inicio. Detalles: { $error }
preflight-title = La instalación no se ha iniciado
preflight-invalid-options = Atlas no pudo usar estas preferencias de configuración. Vuelva al paso Sus preferencias, revíselas y vuelva a intentarlo. Detalles: { $error }
# $problems es una o dos frases formadas a partir de preflight-problem y preflight-security.
preflight-changed = El estado de su PC cambió después de las comprobaciones anteriores. Resuelva lo siguiente antes de volver a intentarlo. { $problems }
preflight-problem = { $title }: { $detail }
# $summary es el resumen de Seguridad de Windows, como "2 aún activados".
preflight-security = Seguridad de Windows: { $summary }.
preflight-busy = Otra ventana de Atlas está iniciando una instalación. Espere un momento y vuelva a elegir Instalar Atlas.
# Se muestra con el botón home-start-over.
preflight-taken-over = Otra ventana de Atlas está usando ahora esta configuración, así que la instalación no se ha iniciado. Continúe en esa ventana o elija Empezar de nuevo para volver a configurar Atlas aquí.
preflight-record-unreadable = Atlas no pudo comprobar si la instalación anterior sigue en curso, así que no ha iniciado otra. Vuelva a Preparación para ver qué hacer a continuación. Detalles: { $error }
preflight-refused = No se pudo iniciar el instalador. No se hizo ningún cambio. Elija Instalar Atlas para volver a intentarlo. Si sigue ocurriendo, elija Enviar un informe. Detalles: { $error }
# En lugar de preflight-refused al reintentar una instalación que un intento anterior ya había empezado a aplicar.
preflight-refused-resumed = No se pudo iniciar el instalador, así que este intento se detuvo. Un intento anterior ya había empezado a hacer cambios. Elija Instalar Atlas para volver a intentarlo. Si sigue ocurriendo, elija Enviar un informe. Detalles: { $error }
go-to-ready = Volver a Preparación
go-to-options = Volver a Sus preferencias
# Sustituye a Continuar en una elección abierta desde un vínculo Cambiar del paso Instalación, cuando Continuar lleva directamente de vuelta a él.
go-to-install = Volver a Instalación
output-problem-title = No se pudo leer el progreso de la instalación
output-problem-message = Atlas no pudo leer el registro. Esto no significa que la instalación se haya detenido. Mantenga el equipo encendido e intente abrir el archivo de registro. Detalles: { $error }
install-elevate-title = Atlas necesita permiso para instalar
install-no-package-title = Elija primero los archivos de instalación
install-no-package-message = Vuelva a Preparación para descargar Atlas o abrir un paquete de Atlas (.apbx) guardado.
# Variante de install-no-package-message para la versión de prueba.
install-no-package-bundled-message = Vuelva a Preparación para preparar el paquete de Atlas incluido en esta versión de prueba.
# Paso 4 cuando el paso 1 no se ha completado en esta sesión (comprobaciones o actualizaciones de Windows); go-to-ready es el botón.
install-not-ready-title = Termine primero el paso Preparación
install-not-ready-message = Atlas necesita terminar de comprobar su PC y de actualizar Windows antes de poder instalar.
install-security-title = Compruebe la protección antivirus antes de instalar
install-security-reading = Comprobando de nuevo los cuatro interruptores de protección.
install-security-message = { $summary }. Abra Seguridad de Windows y asegúrese de que los cuatro interruptores estén desactivados antes de instalar.
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
summary-copy-command-a11y = Copiar el comando de instalación
summary-command-unavailable = No se pudo preparar el comando de instalación. Detalles: { $error }
summary-not-chosen = Aún sin elegir
# Nombre accesible de un vínculo Cambiar. $title es un mensaje screen-*-title.
summary-change-a11y = Cambiar { $title }
footer-still-checking = Preparando la instalación
footer-fix-items = Resuelva los puntos de Comprobaciones del equipo para continuar
footer-need-package = Descargue Atlas o abra un paquete de Atlas para continuar
# Variante de footer-need-package para la versión de prueba.
footer-need-package-bundled = Prepare el paquete de Atlas incluido para continuar
footer-reading-security = Comprobando los interruptores de protección
footer-security-pending = Desactive los cuatro interruptores para continuar
footer-security-confirm = Para continuar, confirme los interruptores que Atlas no pudo comprobar
footer-install-ready = Antes, guarde su trabajo y cierre sus aplicaciones
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
installing-phase-applying = Mantenga el equipo encendido y conectado a la corriente mientras Atlas configura Windows.
installing-phase-done = Terminando la instalación. Mantenga el equipo encendido.
installing-installed-title = Atlas está instalado
# $time es una hora con formato.
installing-started-just-now = Inicio: { $time }, hace menos de un minuto
installing-started-minutes =
    { $minutes ->
        [one] Inicio: { $time }, hace un minuto
       *[other] Inicio: { $time }, hace { $minutes } minutos
    }
installing-restart-auto = Su PC se reiniciará automáticamente cuando termine la instalación. Guarde antes su trabajo en las demás aplicaciones.

## La ventana "Atlas está instalado" tras el reinicio

installed-title-version = Atlas { $version } está instalado
installed-title = Atlas está instalado
installed-ready = Todo listo. Ya puede usar su PC con Atlas.
installed-security-message = Conservó Microsoft Defender, pero parte de su protección sigue desactivada. Abra Seguridad de Windows y asegúrese de que estos interruptores estén activados: { $switches }.
installed-defender-removed-title = Se quitó Microsoft Defender
installed-defender-removed-message = Su PC no tendrá protección antivirus hasta que instale otra aplicación antivirus. También se quitó SmartScreen, así que Windows no le avisará antes de que abra aplicaciones o descargas no reconocidas.
# Home and the "Atlas is installed" window, after an installation that kept Microsoft Defender,
# when it is missing. Its title is security-banner-absent-title; "Report a problem" is
# home-report-problem, its button.
installed-defender-missing-message = Eligió conservar Microsoft Defender, pero ya no está en el equipo. Si no usa otra aplicación antivirus, instale una para proteger su PC. Si no fue usted quien quitó Defender, elija Notificar un problema.

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
settings-language-system-selected = { settings-language-system } ({ $language })
# Bajo "Igual que Windows": qué idioma resulta. $language es el nombre del idioma en ese idioma.
settings-language-system-detail = Con la opción Igual que Windows: { $language }
# Etiqueta breve bajo cada idioma traducido pero aún no revisado por un hablante nativo.
settings-language-preview-tag = Versión preliminar
# Bajo la lista de idiomas, una sola vez, para explicar la etiqueta Versión preliminar.
settings-language-preview-note = Un hablante nativo aún no ha revisado las traducciones en versión preliminar.
preview-notice = { $language } es una traducción preliminar y puede contener errores.
preview-notice-switch = Cambiar a inglés
preview-notice-language = Cambiar idioma
# $tag es una etiqueta de idioma (texto).
settings-language-unavailable = { $tag } no está disponible en esta versión de Atlas. Por ahora se muestra en inglés y su elección de idioma se conserva.
# $languages es la lista de idiomas para mostrar de Windows (texto).
settings-language-windows-unmatched = Atlas aún no está disponible en sus idiomas para mostrar de Windows ({ $languages }). Por ahora se muestra en inglés.
settings-language-windows-unavailable = No se pudo comprobar el idioma para mostrar de Windows. Por ahora, Atlas se muestra en inglés. Detalles: { $error }
# $locale es el nombre del formato regional en su propio idioma, por ejemplo "Español (España)".
settings-language-formats = Los números, las fechas y las horas siguen el formato regional de Windows ({ $locale }).
# En lugar de settings-language-formats cuando el formato regional escribe fechas u horas de derecha a
# izquierda. $locale es el nombre del formato en inglés, por ejemplo "Arabic (Saudi Arabia)".
settings-language-formats-numbers-only = Los números siguen el formato regional de Windows ({ $locale }). Las fechas y las horas usan un formato estándar porque Atlas aún no puede mostrar texto de derecha a izquierda.
settings-language-contribute = Ayudar a traducir Atlas en GitHub
settings-restart-label = Reiniciar mi PC automáticamente al terminar la instalación
settings-restart-locked = Podrá cambiar esto cuando termine la instalación.
settings-restart-description = Con esta opción activada, su PC se reinicia en menos de un minuto tras terminar la instalación, y se cierran las aplicaciones abiertas. Guarde su trabajo antes de instalar.
settings-help = Ayuda y comentarios
settings-about = Acerca de
settings-about-app = Atlas Manager
settings-about-licence = Licencia
settings-about-licence-value = GPL-3.0, gratuito y de código abierto
settings-view-source = Ver el código fuente en GitHub
# Vínculo que abre los avisos de licencia de terceros.
settings-view-licences = Ver los avisos de licencia
# Bajo los vínculos cuando Windows no pudo abrir los avisos.
settings-licences-failed = No se pudieron abrir los avisos de licencia. Vuelva a intentarlo o búsquelos en el código fuente en GitHub.
settings-open-data-folder = Abrir la carpeta de la aplicación

## Opciones adicionales: explicaciones que se muestran antes de elegir.

consequence-disable-hibernation = Libera el espacio en disco que se usa para guardar la sesión al hibernar. Las opciones Hibernar e Inicio rápido dejarán de estar disponibles.
consequence-disable-power-saving = Desactiva las funciones de ahorro de energía. Su PC puede consumir más energía, calentarse más y tener menos autonomía.
consequence-disable-core-isolation = Desactiva una capa adicional de seguridad de Windows, incluida la integridad de memoria. Esto reduce la protección y puede afectar a las aplicaciones o juegos que la requieren.
consequence-remove-snipping-tool = Quita la aplicación de Windows para hacer capturas y grabaciones de pantalla.
consequence-uninstall-edge = Quita el navegador Microsoft Edge. Asegúrese de tener otro navegador o elija uno abajo.
# Instead of consequence-uninstall-edge when Atlas is installed on this PC, which has the
# user's Edge data. "choose one below" refers to the browser choice under it.
consequence-uninstall-edge-data = Quita Microsoft Edge y elimina los favoritos, el historial y las contraseñas guardadas de Edge en este equipo. Se perderá todo lo que no esté sincronizado con su cuenta Microsoft. Asegúrese de tener otro navegador o elija uno abajo.
# Under Remove Microsoft Edge in the Install step's summary, with a caution glyph.
caution-uninstall-edge = Elimina los favoritos, el historial y las contraseñas guardadas de Edge en este equipo.
consequence-install-another-browser = Elija un navegador abajo y Atlas lo instalará por usted.
consequence-install-toolbox = Agregue Atlas Toolbox para administrar la configuración de Atlas con más facilidad. Toolbox está en versión beta, así que algunas funciones pueden estar sin terminar.
consequence-install-eclean = Una herramienta de mantenimiento creada por el equipo de AtlasOS para mantener su PC en orden después de la instalación. Revise archivos innecesarios y aplicaciones de inicio. Requiere una cuenta y conexión a Internet.

# Introducción de la página de inicio antes de instalar Atlas.
home-intro = Atlas ajusta Windows para reducir la actividad en segundo plano y las distracciones. Instale Atlas sobre una instalación limpia de Windows, antes de agregar sus propias aplicaciones y archivos.

## ISO creation (Beta)
iso-home-title = Medio de instalación de Windows
iso-home-description = Cree un archivo de instalación de Windows (ISO) que incluya Atlas y úselo para reinstalar Windows en este equipo o en otro.
iso-open = Crear una ISO con Atlas
iso-title = Crear una ISO con Atlas
iso-beta = Beta
iso-beta-description = Pruebe la ISO en una máquina virtual antes de usarla en un equipo. Haga una copia de seguridad de sus archivos antes de instalar Windows.
iso-admin-description = Atlas necesita permisos de administrador para leer su ISO de Windows y crear la nueva. Elija Reabrir como administrador y, después, elija Sí cuando Windows pregunte.
iso-files-description = Atlas crea una copia de una ISO de Windows 11 con Atlas incluido, para reinstalar Windows. Elija una ISO de Windows 11 descargada de Microsoft, descargue el paquete de Atlas más reciente o elija uno que ya tenga (.apbx) y, después, elija dónde guardar la nueva ISO.
# Versión de prueba: sin selector de paquete.
iso-files-description-bundled = Atlas crea una copia de una ISO de Windows 11 con el paquete de Atlas incluido en esta versión de prueba. Elija una ISO de Windows 11 descargada de Microsoft y, después, elija dónde guardar la nueva ISO.
iso-source = ISO de Windows
iso-source-download = Descargar Windows 11 de Microsoft
# $minimum es la primera versión de Atlas que se puede usar (texto, como 0.6.0).
iso-package = Paquete de Atlas ({ $minimum } o posterior)
iso-output = Guardar la nueva ISO en
iso-no-file = Ningún archivo seleccionado
iso-browse = Examinar
iso-save-as = Guardar como
# Nombre accesible del botón Examinar o Guardar como junto a un campo de archivo: $action es
# el texto de ese botón y $field la etiqueta del campo.
iso-pick-a11y = { $action }: { $field }
iso-inspect = Comprobar archivos
iso-mode-title = ¿Cómo desea configurar Atlas?
iso-mode-interactive = Elegir las preferencias de Atlas tras iniciar sesión
iso-mode-interactive-description = Cuando inicie sesión, Atlas se abrirá y le guiará por las actualizaciones, sus preferencias y la instalación de Atlas.
iso-mode-before = Elegir ahora las preferencias de Atlas
iso-mode-before-description = Atlas guarda sus preferencias en la ISO. Cuando inicie sesión, Atlas se abrirá y le guiará por las actualizaciones; después, podrá instalar Atlas con estas preferencias.
iso-package-unsupported-title = Elija un paquete de Atlas más reciente
# "Elegir las preferencias de Atlas tras iniciar sesión" es iso-mode-interactive.
iso-package-unsupported = Este paquete de Atlas no puede guardar las preferencias de Atlas en la ISO. Elija un paquete más reciente o la opción Elegir las preferencias de Atlas tras iniciar sesión.
# Se muestra cuando Comprobar archivos rechaza el paquete de Atlas; $minimum como en iso-package.
iso-failed-package-unsupported = Este paquete de Atlas no se puede usar para crear una ISO. Elija un paquete para Atlas { $minimum } o posterior.
# Versión de prueba: el paquete de Atlas incluido no se puede cambiar, así que la única salida es el modo tras iniciar sesión.
iso-package-unsupported-bundled-title = Las preferencias de Atlas no se pueden guardar en esta ISO
# "Elegir las preferencias de Atlas tras iniciar sesión" es iso-mode-interactive.
iso-package-unsupported-bundled = El paquete de Atlas incluido en esta versión de prueba no admite la configuración desde la ISO. Elija en su lugar la opción Elegir las preferencias de Atlas tras iniciar sesión.
iso-atlas-options = Preferencias de Atlas
iso-review = Revisar ISO
iso-review-description = Crear la ISO no instala nada en este equipo ni modifica su ISO original. Después, Atlas puede copiar la nueva ISO en una unidad USB para que pueda reinstalar Windows desde ella.
iso-review-files = Archivos
iso-step-windows = Instalación de Windows
iso-step-review = Revisión
iso-review-package = Paquete de Atlas
iso-review-output = Nueva ISO
iso-review-editions = Ediciones
iso-architecture-x64 = x64
iso-architecture-arm64 = Arm64
# Un tamaño de archivo; $size es un número con formato (texto). Megabytes por debajo de un gigabyte.
size-megabytes = { $size } MB
size-gigabytes = { $size } GB
iso-review-account = Nombre de la cuenta
iso-review-target = Instalar en
iso-review-drivers = Controladores
iso-create = Crear ISO
iso-progress-title = Creando su ISO
iso-stage-inspect = Comprobando su ISO de Windows
iso-stage-copy = Copiando archivos de Windows
iso-stage-add-atlas = Agregando Atlas
iso-stage-master = Escribiendo el archivo ISO
iso-stage-verify = Comprobando la nueva ISO
iso-stage-cleanup = Finalizando
# Accessible name of one stage while the ISO is created. No "Step": the screen reader adds
# "4 of 6". $status is stepper-status-completed or one of the three below.
iso-stage-a11y = { $title }, { $status }
iso-stage-status-current = en curso
# The stage where creating the ISO stopped with an error.
iso-stage-status-failed = con errores
iso-stage-status-not-started = sin empezar
iso-progress-description = Mantenga Atlas abierto. Procesar imágenes grandes puede tardar un rato.
iso-cancel = Cancelar creación
iso-cancelling = Esperando un punto seguro para cancelar
iso-cancelled = Creación de la ISO cancelada
iso-cancelled-description = Su ISO original no se ha modificado. Si quedaron archivos temporales, elija Abrir la carpeta de registros para ver dónde están.
iso-complete = Su ISO está lista
iso-complete-description = La creación de ISO está en versión beta, así que pruebe primero la ISO en una máquina virtual. Después, elija Crear USB de instalación y haga una copia de seguridad de sus archivos antes de reinstalar Windows.
iso-open-folder = Mostrar en la carpeta
iso-failed = No se pudo terminar de crear la ISO
iso-failed-description = Asegúrese de que sus archivos sigan donde los eligió y de que la unidad donde guarda la ISO esté conectada; después, elija Crear ISO. Si sigue fallando, elija Enviar un informe.
# Título cuando falla el paso Comprobar archivos; los mensajes de abajo dicen por qué.
iso-check-failed = No se pudieron comprobar los archivos
iso-check-failed-description = Asegúrese de que la ISO y el paquete de Atlas sigan donde los eligió y hayan terminado de descargarse; después, elija Comprobar archivos. Si sigue fallando, elija Enviar un informe.
# Título de la barra que pide permisos de administrador. Su mensaje es iso-admin-description o,
# cuando Windows rechazó la reapertura como administrador (UAC denegado), elevation-declined.
iso-elevation-title = Atlas necesita permiso para crear una ISO
# Motivos tipificados que informa el proceso de imagen.
iso-failed-output-exists = Ya existe un archivo con ese nombre. Elija Guardar como y escriba un nombre de archivo nuevo.
iso-failed-destination = Atlas no puede guardar la nueva ISO ahí. Elija Guardar como y seleccione una carpeta de este equipo, como Descargas. No se pueden usar ubicaciones de red ni unidades con formato FAT32 o exFAT, como muchas unidades USB.
iso-failed-space = No hay suficiente espacio libre en la unidad de destino. Libere espacio o guarde la nueva ISO en otra unidad.
# Home y LTSC son las ediciones que descarta la creación de la ISO; las demás son ejemplos de las que conserva.
iso-failed-edition = Esta ISO no contiene ninguna edición compatible de Windows. Windows Home y LTSC no son compatibles. Use una ISO que incluya otra edición, como Pro, Education o Enterprise.
iso-failed-customised = Esta ISO ya contiene archivos de instalación personalizados, como autounattend.xml. Elija una ISO original de Windows de Microsoft.
iso-failed-windows-unsupported = Esta imagen de Windows no es compatible con el paquete de Atlas. Use una ISO original de Windows 11 de 64 bits de una versión compatible con este paquete.
iso-failed-network-architecture = Los controladores de red de este equipo no coinciden con la arquitectura de esta ISO. Vuelva atrás y desmarque Incluir los controladores de red de este equipo, o elija una ISO para este equipo.
iso-failed-unstaged = Atlas no pudo preparar su carpeta de trabajo, así que no se ha cambiado nada. Inténtelo de nuevo. Si sigue fallando, elija Exportar diagnóstico para un informe de errores.
iso-failed-package-changed = El paquete de Atlas cambió después de comprobar los archivos. Elija Cambiar junto a Archivos y, después, elija Comprobar archivos.
iso-diagnostics = Abrir la carpeta de registros
iso-close-title = La ISO se está creando
iso-close-message = Mantenga esta ventana abierta hasta que termine la creación o la cancelación. La cancelación espera a que la operación en curso pueda detenerse de forma segura.
iso-keep-open = Mantener abierta
prepare-title = Actualizar Windows y las apps de la Store
prepare-description = Antes de instalar, Atlas actualiza Windows, Microsoft Store y sus aplicaciones de la Store. Las aplicaciones de la Store que tenga abiertas, como Bloc de notas, Paint o Terminal Windows, pueden cerrarse mientras se actualizan, así que guarde antes su trabajo en ellas. También es posible que su PC tenga que reiniciarse.
prepare-complete = Atlas no encontró más actualizaciones de Windows ni de la Store que instalar.
prepare-reboot-title = Reinicie su PC para continuar
prepare-reboot = Su PC necesita reiniciarse para terminar de instalar las actualizaciones. Atlas guarda las preferencias que ha elegido hasta ahora y se volverá a abrir cuando inicie sesión.
# $reasons: los marcadores de reinicio pendiente que dejó Windows, a partir de los nombres prepare-reason-*.
prepare-reboot-reasons = Su PC necesita reiniciarse para terminar de instalar las actualizaciones ({ $reasons }). Atlas guarda las preferencias que ha elegido hasta ahora y se volverá a abrir cuando inicie sesión.
# Bajo el mensaje de reinicio: el botón reinicia Windows sin cuenta atrás.
prepare-reboot-save-work = Antes, guarde su trabajo y cierre sus aplicaciones. Su PC se reiniciará de inmediato cuando elija Reiniciar y continuar.
# Se muestra en lugar de otro reinicio cuando Windows vuelve a pedir uno justo después de reiniciar.
prepare-restart-persists = Su PC se reinició, pero Windows sigue indicando que necesita reiniciarse ({ $reasons }), así que es probable que volver a reiniciar no sirva de nada. Elija Abrir Windows Update y termine lo que esté pendiente allí; después, elija Reintentar. Si no hay nada pendiente, elija Enviar un informe.
# Nombres de los marcadores que deja Windows cuando pide un reinicio. Completan
# "Windows necesita reiniciarse (…)"; cortos y en minúsculas.
prepare-reason-servicing = mantenimiento de Windows
prepare-reason-windows-update = Windows Update
prepare-reason-file-renames = archivos pendientes de reemplazar
prepare-reason-update-agent = el servicio de Windows Update
prepare-reason-unknown = motivo no indicado
prepare-failed = Elija Reintentar. Si vuelve a fallar, termine las actualizaciones pendientes en Windows Update o Microsoft Store, o elija Enviar un informe.
prepare-failed-title = No se pudieron completar algunas actualizaciones
# La actualización terminó sin dejar ningún resultado, por ejemplo porque se cerró Atlas mientras se
# ejecutaba. "Reintentar" es common-try-again, el botón que aparece al lado.
prepare-ended-unconfirmed = La actualización se detuvo antes de informar de un resultado, así que Atlas no puede confirmar que Windows y las aplicaciones de la Store estén al día. Elija Reintentar para buscar actualizaciones.
prepare-unconfirmed-title = No se pudo confirmar el resultado de la actualización
# "Buscar e instalar actualizaciones" es prepare-start, su botón en este estado.
prepare-cancelled = La actualización se detuvo. Es posible que ya se hayan instalado algunas actualizaciones. Elija Buscar e instalar actualizaciones para terminar antes de continuar.
prepare-windows-search = Buscando actualizaciones de Windows…
prepare-windows-download = Descargando actualizaciones de Windows…
prepare-windows-install = Instalando actualizaciones de Windows…
prepare-store-search = Comprobando Microsoft Store…
prepare-store-install = Actualizando Microsoft Store y sus apps…
prepare-stop-description = Atlas se detendrá cuando termine el paso actual. Mantenga Atlas abierto hasta entonces.
prepare-stop = Detener actualizaciones
prepare-restart = Reiniciar y continuar
prepare-start = Buscar e instalar actualizaciones
# Bajo el botón de preparación mientras no está disponible. $check es el título check-supported-build.
prepare-blocked-source = No disponible porque esta instalación no puede continuar. Consulte el mensaje de la parte superior de la página.
prepare-needs-build-check = Disponible cuando se supere la comprobación { $check } en Comprobaciones del equipo.
# Bajo el botón de preparación, y bajo la comprobación Administrador, mientras los archivos de instalación aún se descargan o se descomprimen.
prepare-wait-for-package = Disponible cuando los archivos de instalación estén listos.
iso-username = Nombre de la cuenta local
iso-account-description = La instalación de Windows crea una cuenta local con este nombre, así que no necesita una cuenta Microsoft. Windows le pedirá que elija una contraseña la primera vez que inicie sesión.
iso-username-placeholder = Su nombre
iso-account-empty = Escriba un nombre de cuenta local para continuar
iso-account-invalid = Use hasta 20 caracteres, sin espacios al principio ni al final y sin ninguno de estos: " / \ [ ] : ; | = , + * ? < > @
iso-account-trailing-dot = El nombre no puede terminar en punto.
iso-account-reserved = Windows usa este nombre para una cuenta integrada. Elija otro nombre.
iso-privacy-defaults = Esta ISO omite las pantallas de licencia, cuenta Microsoft y privacidad de la instalación de Windows, y desactiva el envío opcional de datos y las ofertas personalizadas.
prepare-drivers = ¿Cómo desea instalar los controladores?
prepare-drivers-auto = Obtener controladores mediante Windows Update
prepare-drivers-auto-detail = Windows busca los controladores adecuados para su equipo. Recomendado para la mayoría de los equipos.
prepare-drivers-manual = Instalar los controladores por mi cuenta
prepare-drivers-manual-detail = Windows Update no instalará controladores, así que tendrá que obtenerlos del fabricante de su PC o dispositivo. Los controladores ya instalados se conservan.
prepare-drivers-description = Los controladores permiten que Windows use su hardware, como los gráficos, el sonido y el Wi-Fi. Si cambia esta opción después de actualizar, Atlas tendrá que volver a buscar actualizaciones.
prepare-network-needed = Las actualizaciones necesitan una conexión a Internet sin uso medido. Conéctese por Wi-Fi o Ethernet y elija Reintentar. Si no ve ninguna red Wi-Fi, instale primero el controlador de red.
# Hay conexión, pero Windows no encontró acceso a Internet (un portal cautivo o un filtrado de DNS o del firewall).
prepare-network-limited = Windows indica que esta red no tiene acceso a Internet. Inicie sesión en la red si se lo solicita, o revise su enrutador y cualquier filtrado de DNS o del firewall, y vuelva a intentarlo.
# "Conexión de uso medido" es el nombre del interruptor en la configuración de red de Windows.
prepare-network-metered = Esta conexión es de uso medido o tiene un límite de datos. Conéctese a una red sin uso medido, o desactive Conexión de uso medido en la configuración de red, y vuelva a intentarlo.
prepare-network-settings = Abrir la configuración de red
iso-target-title = ¿En qué equipo reinstalará Windows?
iso-target-this = En este equipo
# Under This PC (iso-target-this), before it's chosen.
iso-target-this-description = Atlas puede agregar a la ISO los controladores de Wi-Fi y Ethernet de este equipo para que Windows pueda conectarse a Internet en cuanto se reinstale.
iso-target-other = En otro equipo
iso-copy-network = Incluir los controladores de red de este equipo
iso-network-detail = Reutiliza los controladores de Wi-Fi y Ethernet de este equipo durante la instalación de Windows. Deberá volver a conectarse al Wi-Fi después.
iso-network-source = Origen de los controladores de red
iso-network-installed = Usar los controladores instalados
iso-network-updated = Buscar primero en Windows Update
iso-network-updated-detail = Descarga controladores compatibles ofrecidos por Windows Update y conserva los instalados como respaldo. Requiere una conexión sin uso medido.
iso-stage-network-drivers = Preparando los controladores de red
iso-network-failed = No se pudieron preparar los controladores de red. Consulte el diagnóstico o vuelva atrás y cambie la opción de controladores de red.
# Under iso-complete when Include this PC's network drivers was chosen but the adapters use
# drivers that come with Windows, so none were added.
iso-network-inbox = Los adaptadores de red de este equipo usan controladores que vienen con Windows, así que no hace falta agregarlos a la ISO.
iso-mode-desktop = Completar la configuración antes del escritorio
iso-mode-desktop-description = Atlas guarda sus preferencias en la ISO. Cuando inicie sesión, Atlas terminará las actualizaciones y la instalación antes de que se abra el escritorio de Windows.
desktop-setup-description = Complete la configuración del equipo. Sus preferencias de Atlas están guardadas; puede volver a Windows si lo necesita.
desktop-setup-exit = Continuar en Windows

# Windows installation USB (Beta)
usb-title = Crear USB de instalación
usb-existing = Crear un USB a partir de una ISO existente
usb-description = Copie una ISO en una unidad USB para poder reinstalar Windows desde ella. Use una ISO creada por Atlas para instalar Atlas al mismo tiempo.
usb-choose-iso = Elegir ISO
usb-drive = Unidad USB
# $min y $max son números con formato (texto), en gigabytes y terabytes.
usb-empty = No se encontró ninguna unidad USB. Conecte una unidad USB de al menos { $min } GB y elija Actualizar. No se muestran las unidades de más de { $max } TB, las de solo lectura ni la unidad desde la que se ejecuta Windows.
usb-refresh = Actualizar
# Se muestra cuando no se pudo leer la lista de unidades.
usb-scan-failed = Compruebe que la unidad esté conectada y elija Actualizar. Para ver los detalles, elija Abrir la carpeta de registros.
usb-scan-failed-title = No se pudo obtener la lista de unidades USB
# Partes de la línea de detalle de una unidad, unidas con usb-detail-separator; las partes vacías se omiten.
# $size es un número de gigabytes con formato (texto); $volumes y $serial son texto.
usb-drive-size = { $size } GB
usb-drive-serial = Serie: { $serial }
usb-detail-separator = { " · " }
usb-review = Revisar USB
usb-erase-title = ¿Borrar esta unidad USB?
usb-erase-description = Se borrará permanentemente todo el contenido de { $drive } ({ $size } GB), incluidos todos los archivos y particiones. Antes, copie en otra unidad todo lo que quiera guardar. Su ISO se conservará.
usb-layout = Atlas usa hasta 32 GB de la unidad y deja el resto sin usar. La unidad USB funciona en equipos que arrancan en modo UEFI, el modo que requiere Windows 11.
usb-ack = Entiendo que se borrará todo el contenido de esta unidad USB
usb-write = Borrar y crear USB
usb-stage-prepare = Preparando archivos de instalación…
usb-stage-format = Formateando USB…
usb-stage-copy = Copiando archivos de instalación…
usb-stage-verify = Verificando USB…
usb-working = Mantenga Atlas abierto y la unidad USB conectada. Si cancela, la unidad USB quedará sin terminar y no se podrá usar para instalar Windows.
# Títulos de la barra de error, la barra de éxito y el aviso de cierre mientras se escribe un USB.
usb-failed-title = No se pudo terminar de crear el USB
usb-complete-title = Su USB está listo
usb-close-title = El USB se está creando
# Cuando el borrado puede haber empezado.
usb-failed = Es posible que la unidad ya se haya borrado, así que todavía no se puede usar para instalar Windows. Asegúrese de que esté conectada y elija Revisar USB para volver a intentarlo. Si la volvió a conectar, elija primero Actualizar y vuelva a seleccionarla.
# Antes de modificar nada en la unidad: en general y, después, por los motivos que indica el proceso de escritura.
usb-failed-unchanged = Su unidad USB no se ha modificado. Elija Abrir la carpeta de registros para ver qué falló y, después, elija Revisar USB para volver a intentarlo.
usb-failed-iso = Esta ISO no se puede usar para crear un USB de instalación. Elija una ISO creada por Atlas o una ISO de Windows 11 de Microsoft de una versión compatible con Atlas. Su unidad USB no se ha modificado.
usb-failed-location = La ISO o Atlas Manager está en esta unidad USB, en una ubicación de red o en una carpeta vinculada. Mueva el archivo a una carpeta local de este equipo y vuelva a intentarlo. Su unidad USB no se ha modificado.
usb-failed-space = No hay suficiente espacio libre en la unidad de Windows para preparar los archivos de instalación. Libere espacio y vuelva a intentarlo. Su unidad USB no se ha modificado.
usb-failed-fit = Los archivos de instalación no caben en esta unidad USB. Use una unidad más grande y vuelva a intentarlo. Su unidad USB no se ha modificado.
usb-failed-drive-changed = La unidad USB se quitó, se volvió a conectar o se sustituyó después de leer la lista. Elija Actualizar, vuelva a seleccionar la unidad y elija Revisar USB. Su unidad USB no se ha modificado.
usb-cancelled = La unidad puede contener archivos de instalación incompletos. Vuelva a crearla antes de usarla para instalar Windows.
usb-cancelled-title = Creación del USB cancelada
usb-cancelled-unchanged = Su unidad USB no se ha modificado.
usb-complete = Atlas comprobó todos los archivos. Elija Expulsar USB y, después, haga una copia de seguridad de los archivos del equipo que quiere reinstalar. Conecte la unidad a ese equipo y arránquelo desde la unidad USB con su menú de arranque (a menudo F12, F11 o Esc al encender el equipo).
usb-eject = Expulsar USB
usb-ejected = Ya puede desconectar la unidad USB. Haga una copia de seguridad de los archivos del equipo que quiere reinstalar. Después, arranque ese equipo desde la unidad USB con su menú de arranque (a menudo F12, F11 o Esc al encenderlo).
usb-eject-failed = Cierre los archivos o ventanas que lo estén usando y vuelva a intentarlo.
usb-eject-failed-title = No se pudo expulsar el USB
ready-fresh-title = Atlas está pensado para una instalación limpia de Windows
ready-fresh-description = Si ya ha estado usando Windows en este equipo, haga una copia de seguridad de sus archivos y reinstale Windows antes de continuar. Asegúrese primero de que se supere la comprobación Compatibilidad con Windows en Comprobaciones del equipo, para reinstalar una versión compatible.
# Home, LTSC y Server son las ediciones que la comprobación rechaza; las demás son ejemplos de ediciones
# que acepta. Escriba los nombres de las ediciones como los muestra Windows.
detail-edition-unsupported = Las ediciones Home, LTSC y Server de Windows 11 no son compatibles. Use otra edición, como Pro, Education o Enterprise. Si Windows no pudo identificar su edición, resuelva el problema antes de continuar.
install-source-title = Instalación no disponible
install-source-unsupported = Atlas { $source } no se puede actualizar directamente a { $target }. Para usar esta versión, haga una copia de seguridad de sus archivos y reinstale Windows.
# Antes de elegir un paquete, así que aún no se sabe qué versión se ofrece.
install-source-unsupported-any = Atlas { $source } no se puede actualizar directamente. Para usar una versión más reciente, haga una copia de seguridad de sus archivos y reinstale Windows.
# "Abrir un archivo de paquete" es package-open-file. $folder es una ruta de carpeta (texto).
install-source-resume = Una instalación de Atlas { $target } no terminó y solo el paquete de Atlas { $target } puede terminarla. Elija Abrir un archivo de paquete y seleccione ese paquete de Atlas (.apbx). Si Atlas lo descargó, está en { $folder }.
# Versión de prueba: solo se puede instalar el paquete de Atlas incluido.
install-source-resume-bundled = Una instalación de Atlas { $target } no terminó. Esta versión de prueba solo puede instalar su paquete de Atlas incluido, así que termine esa instalación con el paquete de Atlas { $target } en una versión oficial de Atlas Manager.
install-source-unknown = Atlas no pudo confirmar qué hay ya instalado en su PC, así que por ahora no instalará nada. Elija Enviar un informe para que el equipo de Atlas pueda ayudarle.
# $problem es uno de los mensajes install-source-*; $error es un mensaje de error sin procesar (texto).
install-source-details = { $problem } Detalles: { $error }
iso-edition-selection = Solo se incluyen las ediciones compatibles. Durante la instalación de Windows, elija una edición para la que tenga licencia de Windows.
detail-windows-preview = Las compilaciones Insider no son compatibles. Use una versión pública de Windows 11.
detail-windows-release-unknown = Atlas no pudo confirmar que esta compilación de Windows sea una versión pública. Conéctese a Internet y vuelva a comprobarlo.
iso-release-unknown = Atlas no pudo confirmar que esta ISO sea una versión pública de Windows 11 compatible con el paquete de Atlas. Conéctese a Internet y vuelva a elegir Comprobar archivos. Si sigue fallando, vuelva a descargar la ISO de Microsoft.
prepare-previous-worker = Las actualizaciones iniciadas antes siguen en curso. Atlas esperará a que terminen y, después, podrá volver a buscar actualizaciones.

ready-used-windows-title = Parece que Windows ya se ha usado en este equipo
ready-used-windows-description = Windows se instaló en este equipo hace al menos una semana o ya tiene varias aplicaciones. Instalar Atlas aquí no cuenta con soporte y se desaconseja firmemente: es posible que las aplicaciones y la configuración que ya tiene no funcionen como espera, y Atlas quita OneDrive, así que los archivos que contiene dejarán de sincronizarse y sus carpetas Escritorio, Documentos e Imágenes pueden aparecer vacías. Primero haga una copia de seguridad de sus archivos y reinstale Windows, o continúe solo si acepta el riesgo.
ready-used-windows-dismiss = Continuar de todos modos

prepare-resumed = Su PC se reinició y Atlas restauró las preferencias que ya había elegido. Elija Continuar actualizaciones para terminar de actualizar antes de instalar Atlas.
prepare-continue = Continuar actualizaciones
prepare-saving-restart = Guardando sus preferencias y configurando Atlas para que se abra tras reiniciar Windows…
prepare-restart-save-failed = No se pudieron guardar sus preferencias. Vuelva a intentarlo antes de reiniciar.
prepare-restart-registration-failed = Sus preferencias están guardadas, pero Atlas no pudo configurarse para volver a abrirse después del reinicio. Vuelva a intentarlo, o reinicie su PC por su cuenta y abra Atlas cuando inicie sesión.
prepare-restart-failed = Atlas no pudo reiniciar su PC. Vuelva a intentarlo o reinícielo desde el menú Inicio. Sus preferencias están guardadas y Atlas se volverá a abrir cuando inicie sesión.
diagnostics-export = Exportar diagnóstico
diagnostics-exporting = Recopilando diagnóstico…
diagnostics-privacy = Envíe un informe privado al equipo de Atlas o exporte un ZIP de diagnóstico para compartirlo cuando pida ayuda. Atlas elimina del ZIP su nombre de usuario, el nombre de su PC y las direcciones de correo electrónico.
# Título de la barra de resultado tras exportar; su botón es iso-open-folder.
diagnostics-saved = ZIP de diagnóstico creado
diagnostics-failed-title = No se pudo exportar el diagnóstico
# $error es el error sin procesar (texto).
diagnostics-failed = Compruebe que su PC tenga espacio libre en disco y vuelva a intentarlo. Detalles: { $error }

## Tester builds (embedded-playbook feature)

# One line of chrome under the title bar on a release-candidate build.
rc-banner = Versión de prueba de Atlas { $release }. Esta aplicación solo instala el paquete de Atlas incluido.
home-status-bundled = Versión de prueba { $release }
package-bundled = Atlas { $version }, incluido en esta versión de prueba, está listo para instalar.
rc-about-release = Versión de prueba
rc-about-commit = Commit de origen
rc-about-package = Paquete de Atlas incluido (SHA-256)
iso-package-bundled = El paquete de Atlas incluido en esta versión de prueba
prepare-percent = { $percent } % de esta etapa
prepare-count = Actualizaciones completadas: { $completed } de { $total }
prepare-bytes = Descargados { $downloaded } de aproximadamente { $total } MB
prepare-elapsed = Tiempo transcurrido: { $minutes } min { $seconds } s
prepare-progress-waiting = Esperando al servicio de actualizaciones. No hay un porcentaje disponible para este paso.
prepare-progress-unchanged = Sin avances durante { $minutes } min. Las actualizaciones grandes pueden tardar, así que mantenga Atlas abierto. Para ver los detalles, elija Abrir la carpeta de registros.
prepare-report-delayed = Windows no ha informado del progreso durante { $seconds } s. Es posible que las actualizaciones sigan en curso, así que mantenga Atlas abierto.

prepare-affected-app = la aplicación afectada
prepare-app-in-use = Cierre { $app } y vuelva a intentarlo. Windows no puede actualizarla mientras esté abierta. Si no encuentra su ventana, ciérrela desde el Administrador de tareas. Si sigue fallando, reinicie su PC y vuelva a intentarlo antes de abrir { $app }.
prepare-install-busy = Otra instalación o un reinicio pendiente está bloqueando las actualizaciones. Espere a que terminen las demás instalaciones, reinicie su PC si Windows se lo pide y vuelva a intentarlo.
# Causas que indica el proceso de actualización. Su propio mensaje en inglés se muestra debajo como detalle.
prepare-failed-session-owner = Atlas se está ejecutando con una cuenta distinta de la que tiene la sesión iniciada en Windows. Inicie sesión en Windows con una cuenta de administrador, abra Atlas desde esa cuenta y vuelva a intentarlo.
prepare-failed-store-missing = Microsoft Store no está configurada para su cuenta. Abra Microsoft Store una vez, o reinstálela si falta, y vuelva a intentarlo.
prepare-failed-store-battery = Microsoft Store pausó las actualizaciones para ahorrar batería. Conecte su PC a la corriente y vuelva a intentarlo.
prepare-failed-store-network = Microsoft Store pausó las actualizaciones hasta que su PC tenga una conexión sin uso medido. Conéctese por Wi-Fi o Ethernet sin uso medido y vuelva a intentarlo.
prepare-failed-store-timeout = Las aplicaciones de la Store no han terminado de actualizarse. Termine las descargas pendientes en Microsoft Store y vuelva a intentarlo.
prepare-failed-store-passes = Microsoft Store siguió ofreciendo actualizaciones nuevas. Termine las actualizaciones pendientes en Microsoft Store y vuelva a intentarlo.
prepare-failed-manual-updates = Algunas actualizaciones de Windows deben terminarse desde Windows Update. Abra Windows Update, termínelas y vuelva a intentarlo.
prepare-failed-windows-passes = Windows Update siguió ofreciendo actualizaciones nuevas. Termine las actualizaciones pendientes en Windows Update y vuelva a intentarlo.
prepare-error-code = Código de error: { $code }
prepare-open-store = Abrir Microsoft Store

check-user-account = Cuenta de usuario
detail-user-account-ok = El Control de cuentas de usuario está activado y su cuenta está lista para la instalación.
detail-user-account-not-ready = Active el Control de cuentas de usuario (UAC), reinicie su PC y vuelva a intentarlo. Si usa la cuenta Administrador integrada, inicie sesión con otra cuenta de administrador.
detail-user-account-unknown = Atlas no pudo comprobar su cuenta de usuario. Vuelva a comprobarla antes de instalar. Windows informó: { $error }

footer-prepare-required = Termine de actualizar Windows y las aplicaciones de la Store para continuar
footer-prepare-stopping = Deteniendo las actualizaciones tras el paso actual…
resume-choices-title = Continuando la instalación anterior
resume-choices-detail = Para terminar esa instalación, Atlas restauró las preferencias que eligió la última vez. No podrá cambiarlas en Sus preferencias hasta que termine.

## Voluntary reports
report-title = Enviar un informe
report-received = Informe recibido
report-reference = Guarde esta referencia por si se pone en contacto con el equipo de Atlas sobre este informe. Si dejó datos de contacto, el equipo puede usarlos para responderle, pero no se garantiza una respuesta.
# Nombre accesible del botón Copiar junto a la referencia del informe.
report-copy-reference = Copiar la referencia del informe
report-another = Enviar otro informe
# Etiqueta de la elección entre los dos tipos de informe.
report-kind = ¿Qué desea enviar?
report-kind-issue = Un problema
report-kind-suggestion = Una sugerencia
# $min y $max son números: las longitudes de mensaje que acepta el servicio de informes.
report-intro = Describa qué ocurrió o qué le gustaría cambiar ({ $min }–{ $max } caracteres). No incluya contraseñas en su mensaje.
report-message = Su mensaje
report-message-placeholder = Estaba intentando…
report-contact = Datos de contacto (opcional)
report-contact-placeholder = Correo electrónico o usuario de Discord
report-attach = Incluir diagnósticos
report-attach-description = Registros y detalles del sistema que ayudan a encontrar la causa. Atlas elimina su nombre de usuario, el nombre de su PC, las direcciones de correo electrónico y las contraseñas o claves conocidas. Se conservan los detalles de los errores, los modelos de hardware y los nombres de las aplicaciones. Puede revisar el ZIP antes de enviarlo.
report-prepare = Preparar diagnósticos
report-review = Revisar ZIP
report-prepare-failed-title = No se pudieron preparar los diagnósticos
# $error es un mensaje de error sin procesar (texto).
report-prepare-failed = Vuelva a elegir Preparar diagnósticos o desactive Incluir diagnósticos para enviar su informe sin ellos. Detalles: { $error }
report-privacy = Su informe se envía de forma privada al equipo de Atlas en reports.atlasos.net. Su mensaje y sus datos de contacto se envían tal como los escribió. El equipo puede usar servicios de IA de otras empresas para ayudar en la investigación. Estos servicios reciben su mensaje y sus diagnósticos, pero no sus datos de contacto. Los informes se eliminan pasados 90 días, y los registros de seguridad del servidor pueden guardar su dirección IP.
report-website = Privacidad y sitio de informes
report-consent = Acepto enviar al equipo de Atlas este informe y los diagnósticos incluidos
report-failed = Su mensaje sigue aquí. Compruebe su conexión a Internet y elija Reintentar, o envíe su informe desde el sitio web de informes.
report-failed-busy = El servicio de informes está ocupado. Su mensaje sigue aquí. Vuelva a intentarlo más tarde.
report-failed-outdated = Esta versión de Atlas Manager ya no puede enviar informes. Su mensaje sigue aquí: cópielo en el sitio web de informes. Si incluyó diagnósticos, elija Revisar ZIP y adjunte también el ZIP allí.
report-failed-diagnostics = Los diagnósticos preparados no se pueden enviar. Su mensaje sigue aquí. Vuelva a elegir Preparar diagnósticos o desactive Incluir diagnósticos.
# Vínculo bajo un informe que no se envió.
report-failed-website = Abrir el sitio web de informes
report-sending = Enviando…
report-send = Enviar informe

# $min y $max son números: las longitudes de mensaje que acepta el servicio de informes.
report-validation-message = Escriba entre { $min } y { $max } caracteres.

# $max es un número: la longitud máxima de los datos de contacto que acepta el servicio de informes.
report-validation-contact = Limite los datos de contacto a { $max } caracteres.

report-validation-consent = Confirme que acepta enviar este informe.

report-failed-title = El informe no se envió

## Windows version update
# Inicio, bajo el botón de actualización, cuando la actualización también cambia la versión de Windows.
home-plan-intro = Esta actualización tiene dos partes. Sus archivos y aplicaciones se conservan. Si al actualizar Windows se deshace alguno de los cambios de Atlas, Atlas los vuelve a aplicar.
home-plan-windows-title = Windows 11, versión { $release }
home-plan-windows-detail = Atlas la instala desde Windows Update. Su PC se reinicia para terminar de instalarla.
# El mismo paso cuando el cambio de versión es opcional.
home-plan-windows-optional = Recomendado. Atlas la instala desde Windows Update. Su PC se reinicia para terminar de instalarla.
home-plan-atlas-title = Atlas { $version }
home-plan-atlas-detail = Atlas actualiza sus propios archivos y conserva las preferencias que eligió. Su PC se reinicia al final.
# $date y $until son fechas.
home-end-of-updates-title = Windows 11, versión { $current }, deja de recibir actualizaciones de seguridad el { $date }
home-end-of-updates-past-title = Windows 11, versión { $current }, ya no recibe actualizaciones de seguridad
home-end-of-updates-message = Al actualizar a Atlas { $version }, este equipo también pasa a Windows 11, versión { $release }, que recibe actualizaciones de seguridad hasta el { $until }.
# Inicio, cuando este Windows no admite la versión de Atlas. $product es el nombre que Windows da
# a la edición, como Windows 11 Home.
install-windows-edition = Atlas { $version } funciona con Windows 11 Pro, Enterprise y Education. Este equipo tiene { $product }, así que Atlas no se puede instalar en él.
# Lo mismo, en una versión cuyas actualizaciones de seguridad terminan. $date es una fecha.
install-windows-edition-ending = Atlas { $version } funciona con Windows 11 Pro, Enterprise y Education. Este equipo tiene { $product }, así que Atlas no se puede instalar en él. Windows 11, versión { $current }, deja de recibir actualizaciones de seguridad el { $date }. Windows Update puede actualizar este equipo a una versión más reciente.
# $releases enumera las versiones compatibles, como "25H2 o 26H2".
install-windows-no-path = Atlas { $version } requiere Windows 11, versión { $releases }, y Windows Update no puede llevar este equipo a esa versión desde el Windows que tiene. Para usar Atlas { $version }, haga una copia de seguridad de sus archivos y reinstale Windows con una ISO de Atlas.
# Inicio, cuando Atlas cambió la configuración de Windows Update para una actualización y aún no la ha restaurado.
home-update-access-title = La configuración de Windows Update sigue cambiada para la actualización de Atlas
# Cuando la última comprobación aún no encontró la oferta.
home-update-access-not-offered = Atlas activó Windows Update para actualizar este equipo a Windows 11, versión { $release }, y Windows Update aún no la ha ofrecido. Elija Volver a comprobar o Restaurar la configuración.
home-update-access-before = Atlas activó Windows Update para actualizar este equipo a Windows 11, versión { $release }, y aún no ha terminado. Continúe la actualización o elija Restaurar la configuración.
home-update-access-after = Este equipo ya tiene Windows 11, versión { $release }. Termine de instalar Atlas o elija Restaurar la configuración.
home-update-access-plain = Atlas activó Windows Update para instalar actualizaciones y aún no ha terminado. Continúe la actualización o elija Restaurar la configuración.
home-update-access-unreadable = Atlas no puede leer los datos que guardó sobre la configuración de Windows Update que cambió, así que no cambiará ni restaurará nada. Elija Enviar un informe para que el equipo de Atlas pueda ayudarle.
# $error es el error sin procesar.
home-update-access-failed = Atlas no pudo restaurar la configuración. Elija Reintentar o Enviar un informe. Detalles: { $error }
home-update-access-install-active = Termine primero de instalar Atlas. Al final de la instalación, Atlas restaura esta configuración.
home-continue-update = Continuar la actualización
home-put-back = Restaurar la configuración
home-putting-back = Restaurando la configuración…
# Preparación: la tarjeta de la versión de Windows.
windows-card-title = Windows 11, versión { $release }
windows-card-required = Atlas { $version } requiere una versión más reciente de Windows. Cuando Atlas actualice Windows, en la tarjeta de abajo, también instalará Windows 11, versión { $release }, desde Windows Update.
windows-card-question = ¿Qué versión de Windows debe usar este equipo?
windows-choice-move = Actualizar a Windows 11, versión { $release }
# $date es la fecha en que la nueva versión deja de recibir actualizaciones de seguridad.
windows-choice-move-detail = Recomendado. Actualizaciones de seguridad hasta el { $date }. Un reinicio más.
windows-choice-keep = Conservar Windows 11, versión { $current }
windows-choice-keep-detail = Su PC se queda en esta versión. Windows Update no lo pasará a una versión más reciente, así que cambiar de versión más adelante requerirá otra actualización en Atlas Manager.
windows-card-facts = Qué cambia
windows-fact-keep = Sus archivos y aplicaciones se conservan. Si la actualización deshace alguno de los cambios de Atlas, Atlas los vuelve a aplicar al instalarse.
windows-fact-restart = Su PC se reinicia al menos una vez más para terminar de instalarla.
# También tras home-plan-windows-detail en Inicio: cuánto puede tardar Windows Update en ofrecer la nueva versión.
transition-offer-expectation = Windows Update suele ofrecerla en unos minutos, pero puede tardar hasta 2 horas; Atlas espera y lo comprueba por usted.
windows-fact-stays = Después, Windows se queda en la versión { $release } y no pasa por sí solo a una versión más reciente.
windows-fact-removed = La versión { $release } no incluye Windows PowerShell 2.0 ni la herramienta WMIC.
# Cómo deshacer el cambio: Windows puede activar la nueva versión sin reinstalarse (se desinstala
# desde Historial de actualizaciones) o reinstalarse (se deshace con Volver durante 10 días).
# Historial de actualizaciones, Volver, Recuperación y Sistema son los nombres de Windows en español.
windows-card-undo = Para deshacerlo más adelante, desinstale la actualización desde Historial de actualizaciones en Windows Update. Si Windows se reinstaló para actualizarse, elija en su lugar Volver en Configuración > Sistema > Recuperación, en un plazo de 10 días. Atlas { $version } no es compatible con la versión { $current }, así que no deshaga la actualización una vez instalado Atlas { $version }.
windows-card-undo-optional = Para deshacerlo más adelante, desinstale la actualización desde Historial de actualizaciones en Windows Update. Si Windows se reinstaló para actualizarse, elija en su lugar Volver en Configuración > Sistema > Recuperación, en un plazo de 10 días.
windows-terms = Acepto los Términos de licencia del software de Microsoft para Windows 11, versión { $release }
windows-terms-link = Leer los términos de licencia
# Cancelar es el botón del propio flujo; Detener actualizaciones lo confirma (prepare-stop).
windows-card-locked = Para conservar la versión { $current }, elija Cancelar y, después, Detener actualizaciones.
# Preparación: la tarjeta de actualización mientras cambia la versión de Windows.
prepare-description-transition = Antes de instalar, Atlas instala las actualizaciones pendientes de Windows, después Windows 11, versión { $release }, y por último actualiza Microsoft Store y sus aplicaciones de la Store. Las aplicaciones de la Store que tenga abiertas pueden cerrarse mientras se actualizan, así que guarde antes su trabajo en ellas. Su PC se reiniciará al menos una vez.
prepare-start-transition = Actualizar Windows a la versión { $release }
prepare-needs-terms = Disponible cuando acepte los términos de licencia en la tarjeta Windows 11, versión { $release }.
ready-banner-not-offered-message = Consulte en Actualizar Windows y las apps de la Store qué puede hacer ahora.
ready-banner-transition-failed-message = Consulte en Actualizar Windows y las apps de la Store qué debe hacer a continuación.
ready-banner-terms-title = Acepte los términos de licencia para continuar
ready-banner-terms-message = Están en la tarjeta Windows 11, versión { $release }, más abajo en esta página. Después, elija Actualizar Windows a la versión { $release }.
# La barra que nombra cada opción de Windows Update que Atlas activa para la actualización.
access-notice-title = Atlas activa Windows Update temporalmente
access-off = Windows Update está desactivado en este equipo. Atlas lo vuelve a activar mientras actualiza Windows.
access-paused = Las actualizaciones de Windows están en pausa en este equipo. Atlas las reanuda mientras actualiza Windows.
access-delayed = Las actualizaciones mensuales están aplazadas en este equipo. Atlas quita el aplazamiento mientras actualiza Windows.
# Tras las líneas anteriores. "Como usted eligió" se usa cuando las fijó una opción de Atlas que eligió el usuario.
access-back-chosen = Cuando Atlas { $version } esté instalado, esta configuración volverá a quedar como usted eligió.
access-back = Cuando Atlas { $version } esté instalado, esta configuración volverá a quedar como estaba.
access-back-stop = Si detiene la actualización antes, Atlas la restaurará.
# El reinicio que termina la nueva versión.
prepare-reboot-transition = Windows 11, versión { $release }, está instalado. Elija Reiniciar y continuar para terminar la instalación. Atlas se volverá a abrir cuando inicie sesión.
prepare-reboot-commit = Windows necesita reiniciarse una vez más para terminar de instalar la versión { $release }. Atlas se volverá a abrir cuando inicie sesión.
prepare-restart-commit-failed = Windows no pudo dejar lista la versión { $release } para terminar de instalarla al reiniciar, así que su PC no se reinició. Elija Reiniciar y continuar para volver a intentarlo.
prepare-reason-feature-update = la nueva versión de Windows
prepare-reason-feature-commit = finalización de la nueva versión de Windows
prepare-resumed-transition = Su PC se reinició. Elija Continuar actualizaciones para que Atlas compruebe que Windows 11, versión { $release }, terminó de instalarse e instale las actualizaciones que falten.
# Bajo la barra de progreso mientras Windows Update aún no ha ofrecido la nueva versión.
prepare-waiting-offer = Esperando a que Windows Update ofrezca Windows 11, versión { $release }. Suele tardar unos minutos, pero puede llevar hasta 2 horas. Puede seguir usando su PC; deje Atlas abierto.
# Tras un reinicio por las actualizaciones que Windows instala antes de la nueva versión.
prepare-resumed-before-move = Su PC se reinició para terminar de instalar actualizaciones. Elija Continuar actualizaciones para que Atlas instale las actualizaciones que falten y, después, Windows 11, versión { $release }.
# Resultados del cambio de versión de Windows. Cada uno dice qué cambió y qué hacer a continuación.
prepare-not-offered-title = Esperando a que Windows Update ofrezca Windows 11, versión { $release }
prepare-transition-failed-title = No se pudo actualizar Windows a la versión { $release }
prepare-failed-feature-not-offered = Windows Update puede tardar un tiempo en ofrecer Windows 11, versión { $release }, a un equipo. Su PC sigue teniendo la versión { $current }.
# Se añade tras el mensaje anterior mientras Atlas vuelve a comprobarlo por su cuenta.
prepare-offer-rechecking = Atlas vuelve a comprobarlo cada 10 minutos y continúa por sí solo en cuanto Windows Update la ofrezca. También puede elegir Volver a comprobar.
# Bajo la barra de progreso mientras Atlas espera, en una sola línea: cuánto lleva esperando y cuándo vuelve a comprobarlo, o que lo está comprobando ahora.
prepare-offer-waited =
    { $minutes ->
        [one] Esperando desde hace { $minutes } minuto.
       *[other] Esperando desde hace { $minutes } minutos.
    }
prepare-offer-next-check =
    { $minutes ->
        [one] Próxima comprobación en { $minutes } minuto.
       *[other] Próxima comprobación en { $minutes } minutos.
    }
prepare-offer-checking-now = Comprobando ahora.
# Se añade en su lugar cuando Atlas no vuelve a comprobarlo por su cuenta.
prepare-offer-check-again = Elija Volver a comprobar para buscarla ahora.
# Tras 2 horas de comprobaciones sin oferta.
prepare-offer-wait-ended-title = Windows Update aún no ha ofrecido Windows 11, versión { $release }
prepare-offer-wait-ended = Windows Update no ofreció Windows 11, versión { $release }, en 2 horas, así que Atlas dejó de esperar y restauró su configuración de Windows Update. Elija Volver a comprobar más tarde. Si no puede esperar, haga una copia de seguridad de sus archivos y reinstale Windows con una ISO de Atlas.
# En lugar del anterior cuando no se pudo restaurar la configuración al final de la espera. $error es el error sin procesar.
prepare-offer-wait-put-back-failed = Windows Update no ofreció Windows 11, versión { $release }, en 2 horas, y Atlas no pudo restaurar su configuración de Windows Update. Elija Restaurar la configuración para volver a intentarlo. Detalles: { $error }
# $missing enumera el hardware que le falta a este equipo, a partir de los dos mensajes siguientes.
prepare-failed-feature-hardware = Este equipo no cumple los requisitos de hardware de Windows 11 ({ $missing }), así que Windows Update no lo actualizará a la versión { $release }. Su PC sigue teniendo la versión { $current }. Para usar Atlas { $version }, haga una copia de seguridad de sus archivos y reinstale Windows con una ISO de Atlas.
hardware-tpm = TPM 2.0
hardware-uefi = firmware UEFI
prepare-failed-feature-hidden = La versión { $release } de Windows 11 está oculta en Windows Update en este equipo. Vuelva a mostrarla con la herramienta que usó para ocultarla y, después, elija Reintentar.
# $needed y $free son gigabytes enteros; $drive es una unidad, como C:.
prepare-failed-feature-disk-space = Windows necesita al menos { $needed } GB libres en la unidad { $drive } para esta actualización, y solo tiene { $free } GB. Atlas no cambió nada. Libere espacio y, después, elija Reintentar.
prepare-failed-feature-servicing = Windows informa de daños en su almacén de componentes que no puede reparar, así que Atlas no cambió nada. Repare Windows y, después, elija Reintentar.
prepare-failed-feature-managed = Este equipo recibe las actualizaciones del servidor de actualizaciones de una organización, así que Atlas no puede actualizarlo a la versión { $release }. Atlas no cambió nada.
# $setting es el nombre técnico de un valor de directiva o un servicio de Windows Update, como
# NoAutoUpdate o BITS, que se muestra tal cual.
prepare-failed-feature-policy = Algo en este equipo vuelve a cambiar { $setting } cada vez que Atlas lo cambia, así que Atlas no puede actualizar Windows. Si una organización administra este equipo, consulte con ella. Cuando detenga la actualización, Atlas restaurará lo que cambió.
prepare-failed-feature-blocked = Una opción que Atlas no cambió impide que Windows Update se ejecute: { $setting }. Cámbiela para que Windows Update pueda ejecutarse y, después, elija Reintentar.
prepare-failed-feature-rolled-back = Windows no pudo terminar de instalar la versión { $release } durante el reinicio y volvió a la versión { $current }. Sus archivos y aplicaciones no se han visto afectados. Elija Reintentar o Enviar un informe.
prepare-failed-feature-components-lost = Algunos de los cambios de Atlas ya no están después de la actualización de Windows, y Windows no muestra señales de haberse reinstalado, así que Atlas no puede saber qué ocurrió. Atlas { $version } no se instaló. Elija Enviar un informe para que el equipo de Atlas pueda ayudarle.
prepare-failed-feature-build = La versión de Windows de este equipo cambió mientras Atlas lo actualizaba. Elija Restaurar la configuración y, después, vuelva a empezar desde la página de inicio.
prepare-failed-feature-journal = Atlas no puede leer los datos que guardó sobre la configuración de Windows Update que cambió, así que no cambiará ni restaurará nada. Elija Enviar un informe para que el equipo de Atlas pueda ayudarle.
# $setting es el nombre de un valor de directiva de Windows Update, como TargetReleaseVersionInfo.
prepare-failed-feature-pin = Una directiva de Windows Update de su PC, { $setting }, tiene un valor que Atlas no puede guardar, así que Atlas no cambió nada. Elija Enviar un informe para que el equipo de Atlas pueda ayudarle.
prepare-failed-feature-terms = Acepte los términos de licencia de Windows 11, versión { $release }, y, después, elija Reintentar.
prepare-failed-feature-failed = Windows no pudo instalar la versión { $release }. Su PC sigue teniendo la versión { $current }. Elija Reintentar. Si vuelve a fallar, elija Enviar un informe.
prepare-check-again = Volver a comprobar
prepare-keep-version = Conservar la versión { $current }
# Pregunta antes de abandonar la actualización con la configuración de Windows Update cambiada.
stop-update-title = ¿Dejar de actualizar a Atlas { $version }?
stop-update-before = Atlas restaurará la configuración de Windows Update que cambió. Las actualizaciones que Windows ya instaló seguirán instaladas, y su PC conservará Windows 11, versión { $current }.
stop-update-after = Su PC conservará Windows 11, versión { $release }. Atlas restaurará la configuración de Windows Update que cambió.
stop-update-access = Atlas restaurará la configuración de Windows Update que cambió. Las actualizaciones que Windows ya instaló seguirán instaladas.
stop-update-keep = Seguir actualizando
window-close-update-access-title = ¿Cerrar Atlas?
window-close-update-access-message = Antes de cerrarse, Atlas restaurará la configuración de Windows Update que cambió. Puede volver a iniciar la actualización desde la página de inicio.
window-close-put-back = Restaurar y cerrar
# Cuando no se pudo restaurar la configuración antes de cerrar. Primero se muestra el motivo y
# después este mensaje; los botones son window-close-keep y window-close-close.
window-close-put-back-failed-title = ¿Cerrar sin restaurar la configuración?
window-close-put-back-failed-message = Si cierra Atlas ahora, la configuración de Windows Update se quedará como Atlas la cambió. Cuando vuelva a abrir Atlas, la página de inicio le ofrecerá restaurarla.
# La ventana "Atlas está instalado", cuando la elección del usuario volvió a desactivar Windows Update.
installed-update-off-again = Windows Update vuelve a estar desactivado, como usted eligió. Mientras esté desactivado, su PC no recibirá actualizaciones de seguridad.
installed-update-paused-again = Las actualizaciones de Windows vuelven a estar en pausa, como usted eligió. Mientras estén en pausa, su PC no recibirá actualizaciones de seguridad.
# Comprobaciones del equipo: compatibilidad con Windows en una versión desde la que Atlas actualiza.
detail-build-transition = Este equipo tiene Windows 11, versión { $current }, que no es compatible con esta versión de Atlas. Atlas pasará Windows a la versión { $release } cuando lo actualice en Actualizar Windows y las apps de la Store, más abajo.
# Primeras líneas de un informe sobre una actualización de Windows que no terminó; a continuación
# siguen los detalles técnicos en inglés.
report-transition-intro = La actualización de Windows para Atlas no terminó. Detalles para el equipo de Atlas:
# Cuando Windows se reinstaló al pasar a una versión más reciente, en lugar de activar la nueva
# versión sin reinstalarse. Atlas vuelve a aplicar entonces todos sus cambios.
mode-rebase = Reinstalación tras una actualización de Windows
history-mode-rebase = reinstalación tras una actualización de Windows
ready-rebase-title = Windows se reinstaló durante la actualización
# $previous es la versión de Atlas que tenía antes el equipo.
ready-rebase-message = Windows 11, versión { $release }, reemplazó el Windows que tenía este equipo, así que se perdieron algunos de los cambios de Atlas. Atlas { $version } los vuelve a aplicar con las preferencias que eligió para Atlas { $previous }.
# Sus preferencias en una actualización, a partir de lo que eligió el Atlas instalado.
upgrade-choices-title = Sus preferencias de Atlas { $previous }
upgrade-choices-detail = Atlas partió de lo que Atlas { $previous } configuró en este equipo. La actualización conserva lo que hicieron esas preferencias, así que desmarcar aquí un extra opcional no deshace su efecto. Para cambiar alguna más adelante, use la carpeta Atlas o la Configuración de Windows.
rebase-choices-title = Sus preferencias de Atlas { $previous }
rebase-choices-detail = Atlas usa las preferencias que eligió para Atlas { $previous }, así que aquí no hay nada que elegir. Puede cambiarlas más adelante en la carpeta Atlas.
# $missing enumera las preferencias, como "Microsoft Defender, Protecciones del procesador".
rebase-choices-partial = Atlas usa las preferencias que eligió para Atlas { $previous }. No pudo encontrar las siguientes, así que revíselas: { $missing }
# Pregunta antes de cualquier reinicio que haga Atlas mientras otras personas tienen la sesión iniciada en el equipo.
restart-other-title = Otra persona tiene la sesión iniciada en este equipo
restart-others-title = Otras personas tienen la sesión iniciada en este equipo
# $names enumera los nombres de sus cuentas, como "Alex y Sam".
restart-others-message = Al reiniciar se cerrarán las aplicaciones de esas sesiones y se perderá el trabajo que no se haya guardado. Con sesión iniciada: { $names }.
restart-others-keep = No reiniciar
restart-others-restart = Reiniciar de todos modos
# Microsoft Store en sí, antes de las aplicaciones de la Store. Línea de estado de Preparación mientras se actualiza o se repara.
prepare-store-self-update = Actualizando primero Microsoft Store. Está desactualizada en este equipo.
prepare-store-repair = Reparando Microsoft Store. Esto puede tardar unos minutos.
# Bajo prepare-complete, cuando Preparación ha terminado.
prepare-store-updated = Microsoft Store estaba desactualizada, así que Atlas la actualizó antes que sus aplicaciones.
prepare-store-bootstrapped = Microsoft Store no pudo actualizarse por sí sola, así que Atlas instaló desde Microsoft las versiones más recientes de Instalador de aplicación y de Microsoft Store.
prepare-store-repaired = Microsoft Store no funcionaba, así que Atlas la reparó.
prepare-store-skipped-removed = Microsoft Store está desactivada en este equipo, así que Atlas omitió las actualizaciones de las aplicaciones de la Store.
# "Reparar Microsoft Store" es prepare-repair-store; "Enviar un informe" es report-title.
prepare-failed-store-repair-failed = Microsoft Store no funciona y Atlas no pudo repararla. Elija Reparar Microsoft Store para volver a intentarlo. Si sigue sin funcionar, elija Enviar un informe.
prepare-repair-store = Reparar Microsoft Store

screen-keyboard-title = Idiomas del teclado
screen-keyboard-question = ¿Usas varios idiomas de teclado?
playbook-option-keyboard-shortcuts = Sí, con atajos de teclado
playbook-option-keyboard-selector = Sí, con el selector de la barra de tareas
playbook-option-keyboard-single = No, uso una sola distribución
consequence-keyboard-shortcuts = Alt+Shift cambia el idioma; Ctrl+Shift cambia la distribución.
consequence-keyboard-selector = Desactiva Alt+Shift y Ctrl+Shift para evitar cambios accidentales al jugar.
playbook-page-keyboard-shortcuts-description = Elige cómo cambiar el idioma del teclado.
consequence-keyboard-single = { consequence-keyboard-selector }
