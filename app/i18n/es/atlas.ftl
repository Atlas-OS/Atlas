### Atlas Manager: Spanish (es), preview translation. Revised on 24 November 2026 from the en-GB source (i18n/en-GB/atlas.ftl).
###
### Español internacional (neutro entre España y Latinoamérica). Se trata al
### usuario de usted de forma implícita (imperativos "Seleccione", posesivo
### "su"). Para evitar la diferencia de género de "PC" (el PC / la PC) se usa
### "su PC" con posesivo y "el equipo" cuando hace falta un artículo o un
### adjetivo que concuerde.
### Los nombres de las funciones de Windows siguen la interfaz de Windows en
### español (Seguridad de Windows, Windows Update, Configuración, Recortes).
### "Volver a abrir" se refiere a la aplicación Atlas; "reiniciar" siempre se
### refiere al PC o a Windows. El archivo .atlaspkg es el "paquete de Atlas" ("el
### paquete" cuando ya está claro).
###
### Convenciones:
### - Plurales: one y other.
### - Sin comillas alrededor de las etiquetas que se citan en el texto.
### - Pasos de la instalación: Preparación, Sus preferencias, Seguridad de
###   Windows, Instalación. Pasos de la ISO: Windows, Configuración, Creación.
### - Las etapas de la actualización y de la creación de la ISO son "etapas";
###   "paso" es solo para los pasos del flujo.
### - Las elecciones del usuario son "preferencias"; "Configuración" es la
###   página de la aplicación y la configuración de Windows.
### - "Windows Setup" es "el programa de instalación de Windows".
### - Los datos son "diagnósticos"; el archivo es el "ZIP de diagnóstico".
### - "No installation changes were made" es "la instalación no hizo ningún
###   cambio".
### - Los interruptores de protección se nombran con "el interruptor" o "estos
###   interruptores" delante, para que el adjetivo concuerde con cualquier nombre.
### - "Unsupported" es "no cuenta con soporte"; "no es compatible" significa
###   incompatible.

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
# Nombre accesible de un botón que actúa sobre una tarjeta. $action es la etiqueta del botón;
# $section, el título de su tarjeta.
common-details-a11y = { $action }, { $section }
# Abre la carpeta del registro de instalación, con el registro seleccionado.
common-open-log-folder = Abrir la carpeta de registros
# Nombre accesible del botón Copiar junto al registro de instalación.
common-copy-install-log = Copiar el registro de instalación
common-install-log = Registro de instalación
# Etiquetas de fila en las tarjetas de resumen.
common-windows = Windows
common-package = Paquete de Atlas
common-checking = Comprobando
# Une dos elementos de una lista: "Brave, Firefox". Las llaves conservan el espacio.
list-separator = { ", " }
# Une dos alternativas: "26100 o 26200".
list-or = { $a } o { $b }
# Une los dos últimos elementos de una lista; $a puede contener ya varios unidos con list-separator.
list-and = { $a } y { $b }
# Accessible name of a message bar that announces itself: its title, then its message.
infobar-a11y = { $title }. { $message }

## Ventana

# Al cerrar la ventana durante una instalación. Botones: window-close-keep y window-close-close.
window-close-title = ¿Cerrar la ventana mientras Atlas se instala?
window-close-installing = La instalación seguirá en curso. Vuelva a abrir Atlas para ver el resultado.
# En lugar de window-close-installing cuando la instalación reinicia el PC al final: solo una
# ventana de Atlas abierta lo reinicia.
window-close-installing-no-restart = La instalación seguirá en curso, pero su PC no se reiniciará automáticamente. Vuelva a abrir Atlas para ver el resultado.
# La respuesta que mantiene la ventana abierta cuando cerrarla interrumpiría algo.
window-close-keep = Mantener abierta
window-close-close = Cerrar la ventana
# Al cerrar la ventana durante las últimas comprobaciones, antes de que se inicie el instalador.
# Botones: window-close-keep-installing y window-close-stop-and-close.
window-close-checks-question = ¿Detener antes de instalar?
window-close-checks-unchanged = La instalación aún no ha hecho ningún cambio. Si cierra la ventana, no se iniciará.
window-close-keep-installing = Seguir instalando
window-close-stop-and-close = Detener y cerrar
# Al cerrar la ventana mientras se actualizan Windows y las aplicaciones de la Store. Botones:
# stop-update-keep y prepare-stop.
prepare-close-question = ¿Detener las actualizaciones?
# "Etapa" es una etapa de la actualización (como en prepare-percent), no uno de los cuatro pasos.
prepare-close-stops-after-stage = Atlas se detendrá al terminar la etapa actual. Entonces podrá cerrarlo.
# Al cerrar la ventana durante la cuenta atrás del reinicio tras una instalación correcta.
# Botones: restart-now y restart-dont-now (cierra Atlas sin reiniciar).
window-close-restart-question = ¿Reiniciar para terminar de configurar Atlas?
window-close-restart-closed = Una vez cerrado, Atlas no puede reiniciar su PC. Guarde antes su trabajo.
# Al cerrar durante la cuenta atrás del reinicio que necesitan las actualizaciones. Botones:
# restart-now y restart-dont-now; Atlas se vuelve a abrir y continúa tras el siguiente reinicio.
window-close-update-restart-question = ¿Reiniciar para terminar de actualizar?
window-close-update-restart-later = Guarde antes su trabajo. Si reinicia más tarde, Atlas continuará después del reinicio.
# Al cerrar la ventana con interruptores de Seguridad de Windows aún desactivados. Su mensaje es
# window-close-protection-all o window-close-protection-some.
window-close-protection-title = ¿Cerrar Atlas con la protección desactivada?
window-close-protection-all = Los cuatro interruptores de protección de Seguridad de Windows están desactivados. Si no va a instalar Atlas ahora, vuelva a activarlos primero.
# $switches nombra los interruptores desactivados como lo hace Seguridad de Windows, unidos como
# una lista; $count es cuántos son.
window-close-protection-some =
    { $count ->
        [one] Este interruptor está desactivado en Seguridad de Windows: { $switches }. Si no va a instalar Atlas ahora, vuelva a activarlo primero.
       *[other] Estos interruptores están desactivados en Seguridad de Windows: { $switches }. Si no va a instalar Atlas ahora, vuelva a activarlos primero.
    }
# Al cerrar la ventana mientras se crea una ISO o una unidad USB. Botones: window-close-keep-creating
# y window-close-stop.
iso-close-question = ¿Detener la creación de la ISO?
iso-close-safe-point = Atlas se detendrá en el siguiente punto seguro.
usb-close-question = ¿Detener la creación de la unidad USB?
usb-close-unfinished = Una unidad sin terminar no puede instalar Windows.
window-close-keep-creating = Seguir creando
window-close-stop = Detener
# El botón Abrir del selector de archivos para un paquete de Atlas (.atlaspkg), en Preparación y en la
# página de la ISO. Es la etiqueta de un botón, así que debe ser breve.
file-dialog-open-package = Abrir un paquete de Atlas (.atlaspkg)
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
# Bajo home-not-installed: el Windows de este equipo, como "Windows 11 Pro 25H2". Ambos valores son texto.
home-windows = { $product } { $version }
# En lugar de home-windows cuando Atlas ya encontró su versión más reciente: el Windows de este
# equipo y la versión que instalaría Instalar Atlas, como "Windows 11 Pro 25H2 · Atlas 0.6.1".
# $product y $version son la edición y la versión de Windows; $atlas, la versión de Atlas (todo texto).
home-windows-atlas = { $product } { $version } · Atlas { $atlas }
# Bajo home-windows o home-windows-atlas, en un equipo sin Atlas: qué hace Atlas, en una frase.
# Solo lo que Atlas cambia: no promete un PC más rápido.
home-about = Atlas reduce la actividad en segundo plano y las distracciones de Windows.
# Titular cuando Atlas Manager no puede saber qué hay instalado en este equipo.
home-state-unknown = Atlas en este equipo
# Titular cuando Atlas está instalado. $version es texto.
home-version = Atlas { $version }
# Junto al estado de las actualizaciones. $date es una fecha con formato.
home-installed-on = Instalado el { $date }
home-status-checking = Buscando actualizaciones…
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
# Pregunta de Instalar Atlas cuando Windows ya se ha usado en este equipo (instalado hace una
# semana o más, o con varias aplicaciones). Botones: common-cancel y home-used-windows-install.
home-used-windows-title = ¿Instalar Atlas en este equipo?
# OneDrive: el nombre que muestra Windows.
home-used-windows-message = Las aplicaciones y la configuración que ya tiene pueden dejar de funcionar, y Atlas quita OneDrive, así que los archivos que contiene dejan de sincronizarse y algunas carpetas pueden aparecer vacías. Haga antes una copia de seguridad de sus archivos.
home-used-windows-install = Instalar de todos modos
# La tarjeta que abre la creación de la ISO; su botón es iso-open.
home-iso-title = Reinstalar Windows con Atlas
# Bajo home-iso-title, con la insignia Recomendado, cuando Windows ya se ha usado en este equipo.
home-iso-used = Windows ya se ha usado en este equipo, y Atlas funciona mejor en una instalación limpia.
# Barra en Inicio tras una instalación, hasta que el PC se reinicia. Mensaje: restart-needed;
# botón: restart-now.
home-restart-title = Su PC necesita reiniciarse
# En lugar de restart-needed cuando Windows rechazó el reinicio. Botón: common-try-again.
home-restart-failed = Atlas no pudo reiniciar su PC. Reinícielo desde el menú Inicio.
home-security-reminder-title = Vuelva a activar la protección
# Instead of home-security-reminder-title when no switch reads off but some couldn't be read
# (with home-security-reminder-unreadable-message).
home-security-reminder-unreadable-title = Asegúrese de que la protección esté activada
# Bajo home-security-reminder-title, al salir del flujo de instalación o tras una instalación que
# conservó Microsoft Defender. $switches nombra los interruptores desactivados como lo hace
# Seguridad de Windows, unidos con list-separator y list-and; $count es cuántos nombra.
security-switches-still-off =
    { $count ->
        [one] Este interruptor sigue desactivado en Seguridad de Windows: { $switches }.
       *[other] Estos interruptores siguen desactivados en Seguridad de Windows: { $switches }.
    }
# En lugar de security-switches-still-off cuando ningún interruptor está desactivado, pero algunos no se
# pudieron leer. $switches los nombra.
home-security-reminder-unreadable-message = Atlas no pudo leer todos los interruptores de protección. Compruebe que estos estén activados en Seguridad de Windows: { $switches }.
home-elevation-title = Atlas necesita permiso para instalar
# Bajo home-elevation-title cuando no se pudieron guardar las preferencias; el error está tras
# Mostrar detalles.
home-elevation-draft-not-saved = Atlas no pudo guardar sus preferencias de configuración, así que no se ha vuelto a abrir.
home-state-error-title = No se pudieron leer los datos de su instalación de Atlas
# Su botón es common-try-again; el error está tras Mostrar detalles.
home-state-error-problem = Puede que su versión de Atlas, sus preferencias y su historial no se muestren correctamente.
# Barra en Inicio cuando el paquete de Atlas necesita un Atlas Manager más reciente. Su mensaje es
# acquire-manager-update-required o acquire-manager-update-required-any.
home-manager-needed-title = Atlas Manager necesita una actualización
home-whats-new = Novedades de Atlas { $version }
home-view-release = Ver las notas de la versión en GitHub
home-show-less = Mostrar menos
home-show-full-notes = Mostrar todas las notas de la versión
home-your-install = Su instalación de Atlas
# Atlas está instalado, pero sin el registro que guarda Atlas Manager (las versiones anteriores no lo creaban).
home-install-unrecorded = Este equipo no tiene ningún registro de cómo se instaló Atlas, así que no se pueden mostrar sus preferencias ni el historial de instalaciones.
home-history = Historial de instalaciones
# Una fila del historial. $version es texto, $mode uno de los mensajes history-mode-*, $date una fecha y hora con formato.
home-history-entry = Atlas { $version } · { $mode } · { $date }
# Nombre accesible de un paso numerado.
home-step-a11y = Paso { $number }: { $title }
# Nombre accesible de un paso numerado con su frase, como los lectores de pantalla leen cada paso de
# las listas de Inicio. $step es home-step-a11y o stepper-item-a11y, y $detail es la frase del paso,
# como home-step-ready.
home-step-detail-a11y = { $step }. { $detail }
# La tarjeta de Inicio que enumera los cuatro pasos de la instalación (step-ready, step-options,
# step-security y step-install) en un equipo sin Atlas, cada uno con su frase home-step-* al lado.
home-steps-title = Qué ocurrirá
# En lugar de home-steps-title mientras hay una configuración en curso: cada paso muestra si está
# completado, en curso o pendiente.
home-steps-under-way-title = Configuración de Atlas en curso
# Junto a step-ready en esa tarjeta.
home-step-ready = Atlas comprueba su PC y actualiza Windows.
# En lugar de home-step-ready cuando Windows debe pasar a una versión más reciente antes de que Atlas
# pueda instalarse. $release es esa versión, como "26H2" (texto).
home-step-ready-move = Atlas comprueba su PC y pasa Windows a la versión { $release }.
# Junto a step-options en esa tarjeta. Microsoft Defender es una de las preferencias que se preguntan allí.
# "Usted" explícito, para distinguir lo que hace el usuario de lo que hace Atlas.
home-step-options = Usted elige qué conservar, como Microsoft Defender.
# Junto a step-security en esa tarjeta.
home-step-security = Usted desactiva los cuatro interruptores de protección de Seguridad de Windows.
# Junto a step-install en esa tarjeta. $minutes es cuánto suele tardar la instalación, según el
# paquete de Atlas (un número). El primero se muestra cuando el PC se reinicia solo al terminar,
# según settings-restart-automatically, y el segundo cuando lo reinicia el usuario.
home-step-install-restarts =
    { $minutes ->
        [one] La instalación suele tardar alrededor de { $minutes } minuto y después su PC se reinicia.
       *[other] La instalación suele tardar alrededor de { $minutes } minutos y después su PC se reinicia.
    }
home-step-install-restart-yourself =
    { $minutes ->
        [one] La instalación suele tardar alrededor de { $minutes } minuto y después debe reiniciar su PC.
       *[other] La instalación suele tardar alrededor de { $minutes } minutos y después debe reiniciar su PC.
    }
# Al pie de esa tarjeta, bajo los cuatro pasos.
home-steps-save-work = Guarde antes su trabajo: las aplicaciones pueden cerrarse y su PC se reiniciará.
home-github = Ver Atlas en GitHub
home-discord = Unirse a la comunidad de Atlas en Discord
home-report-problem = Notificar un problema

## Cómo se hizo una instalación (según el documento de estado)

# Formas en minúscula usadas dentro de una fila del historial.
history-mode-fresh = primera instalación
history-mode-upgrade = actualización
history-mode-reapply = reinstalación
history-mode-unknown = instalación

## Avisos en la página de inicio

# El error sin procesar de cada aviso, y el archivo al que se refiere, están tras Mostrar detalles.
notice-settings-reset-title = Atlas está usando la configuración predeterminada de la aplicación
notice-settings-unreadable-problem = Atlas no pudo leer la configuración guardada de la aplicación. La configuración de Windows no ha cambiado.
notice-settings-damaged-kept-problem = El archivo de configuración de la aplicación estaba dañado, así que Atlas lo restableció y guardó una copia del archivo anterior.
notice-settings-damaged-problem = El archivo de configuración de la aplicación estaba dañado. Por ahora, Atlas usa los valores predeterminados.
notice-settings-not-saved-title = No se pudo guardar la configuración de la aplicación
notice-settings-not-saved-problem = Atlas no pudo guardar sus últimos cambios, así que podrían perderse al cerrar Atlas. Si hay otra ventana de Atlas abierta, ciérrela y vuelva a hacer el cambio.
notice-session-unreadable-title = No se pudo comprobar la instalación anterior
# Su botón, iso-open-folder, muestra el archivo de la instalación en el Explorador de archivos.
notice-session-unreadable-problem = Atlas no pudo saber si una instalación anterior sigue en curso. Si sabe con certeza que no, elimine el archivo con los datos de esa instalación y vuelva a abrir Atlas.
# Preparación, cuando no se puede leer el archivo de la instalación. $path es una ruta de archivo (texto).
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
# Nombre accesible de un paso. $heading es step-heading; $status, uno de los mensajes stepper-status-*.
stepper-item-a11y = { $heading }, { $status }
stepper-status-completed = completado
stepper-status-current = paso actual
stepper-status-upcoming = paso pendiente
# Un paso ya visitado cuyos requisitos aún no se cumplen.
stepper-status-attention = requiere atención
# Nombra el paso que se muestra. No es visible: lo lee el paso actual al recibir el foco.
step-heading = Paso { $number } de { $total }: { $title }
# Nombre accesible del paso actual en Sus preferencias. $heading es stepper-item-a11y; $questions,
# las preguntas de la pantalla, una tras otra.
step-heading-choices-a11y = { $heading }. { $questions }

## Paso 1: Preparación
## Una lista con tres filas: las comprobaciones, el paquete de Atlas y las actualizaciones. Cada fila
## tiene un título y una línea de estado. Preparación empieza a actualizar y avanza por sí sola.

# Título de la fila. Nombra lo que hace la fila, como un elemento de una lista.
ready-checks-title = Comprobar su PC
# Línea de estado mientras se ejecutan las comprobaciones.
ready-checks-running = Comprobando su PC…
ready-check-again = Volver a comprobar
# Línea de estado cuando se superan todas las comprobaciones.
ready-checks-passed =
    { $count ->
        [one] { $count } comprobación superada
       *[other] { $count } comprobaciones superadas
    }
# Línea de estado cuando algunas comprobaciones requieren atención.
ready-checks-passed-some =
    { $total ->
        [one] { $passed } de { $total } comprobación superada
       *[other] { $passed } de { $total } comprobaciones superadas
    }
# Tras ready-checks-passed-some, cuando las únicas comprobaciones no superadas son las que resuelve
# la actualización: "5 de 9 comprobaciones superadas · 4 se resuelven con la actualización". $count
# es cuántas resuelve.
ready-checks-handled =
    { $count ->
        [one] { $count } se resuelve con la actualización
       *[other] { $count } se resuelven con la actualización
    }
# Estado accesible de una comprobación que resuelve la actualización, tras el título de check-a11y.
check-state-updates = lo resuelve la actualización
# Bajo el título de una comprobación que resuelve la actualización.
check-updates-handled = Hay actualizaciones pendientes. Atlas las instala mientras actualiza Windows.
check-restart-handled = Windows necesita reiniciarse para terminar cambios anteriores. La actualización lo resuelve.
check-handled = La actualización lo resuelve.
# Título de la fila: la versión de Atlas que contiene el paquete.
ready-package-title = Atlas { $version }
# Líneas de estado de la fila del paquete.
ready-package-downloading = Descargando…
ready-package-unpacking = Extrayendo…
ready-package-ready = Listo
ready-package-checking = Buscando la versión más reciente…
# Versión de prueba: se está extrayendo el paquete de Atlas incluido; no se descarga nada.
ready-package-bundled = Preparando el paquete de Atlas incluido…
ready-package-none = Aún sin descargar
ready-package-failed = No se pudo obtener el paquete de Atlas
# Bajo ready-package-failed, con package-download-again y package-open-file.
ready-package-failed-detail = Vuelva a descargarlo o abra otro paquete de Atlas (.atlaspkg).
# Versión de prueba: lo mismo, con Reintentar como único control.
ready-package-bundled-failed-detail = No se pudo extraer el paquete de Atlas incluido en esta versión de prueba. Vuelva a intentarlo.
ready-package-manager = Requiere un Atlas Manager más reciente
ready-package-release-failed = No se pudo buscar la versión más reciente
# Bajo ready-package-release-failed, con package-download-again y package-open-file.
ready-package-release-failed-detail = Compruebe su conexión a Internet y vuelva a intentarlo. Si tiene un paquete de Atlas (.atlaspkg), puede abrirlo en su lugar.
# Título de la fila.
ready-updates-title = Actualizaciones de Windows y Microsoft Store
# Línea de estado antes de empezar a actualizar. Preparación empieza por sí sola.
ready-updates-pending = Las aplicaciones de la Store, como Bloc de notas, pueden cerrarse mientras se actualizan. Guarde antes su trabajo en ellas.
# Mientras Windows pasa a la versión $release, cuya tarjeta indica cómo va.
ready-updates-after-move = Empieza cuando Windows pase a la versión { $release }.
# Tras el reinicio que hace Atlas, hasta que la actualización continúa por sí sola.
ready-updates-resumed = Continuando tras el reinicio…
ready-updates-restarting = Reiniciando su PC…
ready-updates-done = Windows y las aplicaciones de la Store están al día.
# En lugar de ready-updates-done cuando Microsoft Store está desactivada y solo se actualizó Windows.
ready-updates-done-windows = Windows está al día.
# La cuenta atrás del reinicio que necesita la actualización, con restart-now y restart-dont-now debajo.
ready-updates-restart-countdown =
    { $seconds ->
        [one] Su PC se reiniciará en { $seconds } segundo.
       *[other] Su PC se reiniciará en { $seconds } segundos.
    }
ready-updates-restart = Su PC necesita reiniciarse para terminar de actualizar.
ready-updates-restart-finish = Windows necesita reiniciarse una vez más para terminar de instalar la versión { $release }.
ready-updates-restart-failed = Su PC no se reinició
# Bajo la línea de estado del reinicio, antes de Reiniciar ahora.
ready-updates-restart-save = Guarde antes su trabajo.
ready-updates-restart-persists = Windows sigue pidiendo un reinicio
# Bajo ready-updates-restart-persists, con Reintentar y check-fix-windows-update.
ready-updates-restart-persists-advice = Volver a reiniciar probablemente no sirva de nada. Termine lo que esté pendiente en Windows Update y vuelva a intentarlo.
# Tras Mostrar detalles. $reasons enumera mensajes prepare-reason-*.
ready-updates-restart-persists-reasons = Motivos del reinicio: { $reasons }
ready-updates-network = Las actualizaciones no pueden usar esta conexión
ready-updates-stopped = La actualización se detuvo. Es posible que ya se hayan instalado algunas actualizaciones.
ready-updates-previous = Esperando a las actualizaciones iniciadas antes…
# Botón después de que el usuario detuviera la actualización.
ready-updates-resume = Reanudar actualizaciones
ready-updates-start = Iniciar actualizaciones
# Por qué no ha empezado la actualización, bajo la fila.
ready-updates-blocked = Las actualizaciones esperarán hasta que Atlas pueda instalarse en este equipo.
ready-updates-needs-admin = Empieza cuando Atlas tenga permiso de administrador.
ready-updates-needs-windows = Empieza cuando se supere la comprobación Compatibilidad con Windows.
ready-updates-needs-drivers = Empieza cuando decida cómo se instalan los controladores.
# La elección de controladores, una línea bajo la fila de actualizaciones. $choice es
# ready-drivers-automatic o ready-drivers-manual.
ready-drivers-row = Controladores: { $choice }
ready-drivers-automatic = Mediante Windows Update
ready-drivers-manual = Instalarlos por mi cuenta
ready-drivers-change-a11y = Cambiar cómo se instalan los controladores
# Bajo las dos respuestas, cuando ya se ha actualizado.
ready-drivers-again = Si cambia esto, las actualizaciones se vuelven a ejecutar.

# $received y $total son números de megabytes con formato (texto).
package-downloading = Descargando Atlas { $version } · { $received } de { $total } MB
package-unpacking = Extrayendo
package-status-ready = Listo
# Nombre accesible de la barra de progreso.
package-progress = Progreso del paquete de Atlas
package-download-again = Volver a descargar
package-download-version = Descargar Atlas { $version }
package-download-newest = Descargar la versión más reciente
package-cancel-download = Cancelar descarga
package-open-file = Abrir un archivo de paquete
# De dónde procede el paquete. $file es un nombre de archivo (texto).
package-from-release = Atlas { $version } se descargó de GitHub y está listo para instalar.
package-from-file = Atlas { $version } se cargó desde { $file } y está listo para instalar.
package-unpacked = Atlas { $version } está listo para instalar.
package-none-yet = Aún no hay ningún paquete de Atlas
acquire-no-asset = Atlas { $version } no tiene ningún archivo de paquete para descargar. Para continuar, abra un paquete de Atlas (.atlaspkg) guardado.
# Shown for a package older than Atlas 0.6.0, and for a file that isn't an Atlas package, such as an
# .apbx file from an Atlas release before 0.6.
acquire-unsupported = Esta aplicación puede instalar Atlas 0.6.0 y versiones posteriores desde paquetes de Atlas (.atlaspkg).
# Un paquete lo bastante reciente para incluir el script de instalación que usa esta aplicación, pero sin él.
acquire-incomplete = A Atlas { $version } le faltan archivos que esta aplicación necesita para instalarlo. Vuelva a descargarlo o abra otro paquete de Atlas (.atlaspkg).
acquire-failed = No se pudo preparar el paquete de Atlas. Vuelva a descargarlo o abra otro paquete de Atlas (.atlaspkg). Detalles: { $error }
# La descarga no recibió nada durante un minuto y se detuvo.
acquire-stalled = La descarga dejó de responder. Compruebe su conexión a Internet y vuelva a intentar la descarga, o abra un paquete de Atlas (.atlaspkg) guardado.
# Versión de prueba: no se pudo extraer el paquete de Atlas incluido. Reintentar es el único control que se ofrece.
acquire-failed-bundled = No se pudo preparar el paquete de Atlas incluido. Elija Reintentar. Detalles: { $error }
# El paquete de Atlas pide un Atlas Manager más reciente que este. $version es la versión que pide,
# como 0.7.0. Descargar Atlas Manager (manager-download) está al lado. "Úsela" es la versión
# descargada, y "esta", el Atlas Manager que se está ejecutando.
acquire-manager-update-needed = Este paquete de Atlas necesita un Atlas Manager más reciente. Descargue Atlas Manager { $version } o una versión posterior y úsela en lugar de esta.
# Lo mismo, para un paquete que no indica qué versión necesita.
acquire-manager-update-needed-any = Este paquete de Atlas necesita un Atlas Manager más reciente. Descargue la última versión de Atlas Manager y úsela en lugar de esta.
# El paquete de Atlas $version pide Atlas Manager $required o posterior, como 0.7.0. Descargar
# Atlas Manager (manager-download) está al lado, en Preparación y en Inicio.
acquire-manager-update-required = Para instalar Atlas { $version }, descargue Atlas Manager { $required } o una versión posterior y úsela en lugar de esta.
# Lo mismo, para un paquete que no indica qué Atlas Manager necesita.
acquire-manager-update-required-any = Para instalar Atlas { $version }, descargue la última versión de Atlas Manager y úsela en lugar de esta.

## Atlas Manager más reciente

# Opens the latest Atlas release on GitHub in the browser, where Atlas Manager is downloaded.
manager-download = Descargar Atlas Manager
# A note on Home and in Settings that a newer Atlas Manager has been released. $version is its
# version, such as 0.7.0. The note doesn't stop anything; manager-download is its button.
manager-update-title = Atlas Manager { $version } está disponible
manager-update-message = Atlas Manager no puede actualizarse solo. Descargue la nueva versión y úsela en lugar de esta.

## Comprobaciones del sistema

check-administrator = Permiso para instalar
check-supported-build = Compatibilidad con Windows
check-pending-updates = Actualizaciones de Windows
check-pending-reboot = Reinicio pendiente
check-third-party-antivirus = Otro software antivirus
check-internet = Conexión a Internet
check-power = Alimentación eléctrica
check-activation = Activación de Windows
# Comprobaciones que solo aparecen cuando Atlas pasa Windows a una versión más reciente.
check-move-hardware = Hardware para Windows 11
check-move-space = Espacio libre
check-move-update-source = Origen de las actualizaciones
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
# Abre Almacenamiento en Configuración de Windows, donde se libera espacio.
check-fix-storage = Abrir Almacenamiento
# Abre Aplicaciones instaladas en Configuración de Windows, desde la comprobación Otro software
# antivirus. Es el nombre de la página de Configuración, como en fixed-installed.
check-fix-installed-apps = Abrir Aplicaciones instaladas
# Casilla que el usuario marca cuando no se pudo ejecutar la búsqueda de Windows Update.
check-ack-updates = He comprobado Windows Update: no hay actualizaciones pendientes de instalar

detail-admin-ok = Atlas tiene permiso para hacer los cambios que requiere la instalación.
detail-admin-missing = Vuelva a abrir Atlas como administrador y elija Sí cuando Windows le pida permiso.
# $builds es una lista de números de compilación como "26100 o 26200"; $build es la de este equipo (texto).
detail-build-unsupported = Esta versión de Atlas requiere la compilación { $builds } de Windows. Su PC tiene la compilación { $build }. Instale una versión compatible de Windows antes de continuar.
detail-build-missing = Este paquete de Atlas no indica ninguna compilación de Windows compatible. Use una compilación completa del paquete en lugar de una compilación LocalTest.
detail-updates-none = No hay actualizaciones de Windows pendientes de instalar.
# Actualizaciones que siguen pendientes después de actualizar. $count es cuántas.
detail-updates-left =
    { $count ->
        [one] Aún queda { $count } actualización pendiente. Instálela en Windows Update y vuelva a comprobar.
       *[other] Aún quedan { $count } actualizaciones pendientes. Instálelas en Windows Update y vuelva a comprobar.
    }
detail-updates-scan-failed = No se pudieron buscar actualizaciones de Windows. Abra Windows Update para ver si hay alguna pendiente. ({ $error })
detail-reboot-none = Windows no necesita reiniciarse ahora.
# Después de actualizar: un reinicio que dejó la actualización, o uno que Windows sigue pidiendo.
detail-restart-pending = Windows necesita reiniciarse para terminar cambios anteriores. Reinicie su PC y vuelva a comprobar.
# $reasons: los marcadores de reinicio pendiente que dejó Windows, a partir de los nombres prepare-reason-*.
detail-restart-pending-reasons = Windows necesita reiniciarse para terminar cambios anteriores ({ $reasons }). Reinicie su PC y vuelva a comprobar.
# Aviso, no un bloqueo: $files enumera hasta tres rutas de archivo que Windows reemplazará o eliminará en el próximo reinicio.
detail-reboot-file-renames = Puede continuar. Windows tiene archivos pendientes de reemplazar o eliminar en el próximo reinicio ({ $files }). Algunas aplicaciones, como Xbox Gaming Services, hacen esto después de cada reinicio.
detail-reboot-unknown = No se pudo comprobar si Windows necesita reiniciarse. Reinicie su PC, vuelva a abrir Atlas y compruébelo de nuevo. ({ $error })
detail-antivirus-none = No se detectó otro software antivirus.
# $products es una lista de nombres de producto (texto). La fila ofrece check-fix-installed-apps.
detail-antivirus-uninstall = Las aplicaciones antivirus distintas de Microsoft Defender pueden bloquear la instalación. Desinstale { $products } y vuelva a comprobar.
# Advertencia, no un bloqueo: el Centro de seguridad todavía muestra el producto, pero sus archivos ya no están.
detail-antivirus-stale = Seguridad de Windows todavía muestra { $products }, pero sus archivos ya no están, así que ya no está instalado. Atlas se puede instalar de todos modos.
detail-antivirus-check-failed = No se pudo comprobar si hay otro software antivirus. Si sigue ocurriendo, reinicie su PC y vuelva a comprobar. ({ $error })
detail-internet-ok = Hay conexión a Internet. Manténgala disponible mientras Atlas descarga e instala software.
detail-internet-missing = Conéctese a Internet y vuelva a comprobar.
detail-power-mains = El equipo está conectado a la corriente. Manténgalo conectado hasta que termine la instalación.
detail-power-battery = Conecte el equipo a la corriente para que siga encendido durante toda la instalación.
detail-power-check-failed = Atlas no pudo saber si el equipo está conectado a la corriente. Si es un portátil, conéctelo y vuelva a comprobar.
detail-activation-ok = Windows está activado. Atlas no cambiará esto.
detail-activation-missing = Windows no está activado. Puede continuar, pero Atlas no activará Windows.
detail-activation-no-licence = Windows no informó de ninguna licencia. Puede continuar; Atlas no cambiará el estado de activación.
detail-activation-unknown = No se pudo comprobar la activación de Windows. Puede continuar; Atlas no cambiará el estado de activación. ({ $error })
# Lo que necesita el paso de Windows a la versión $release. $missing enumera hardware-tpm y hardware-uefi.
detail-move-not-needed = Atlas no necesita pasar Windows a una versión más reciente en este equipo.
detail-move-hardware-ready = Este equipo tiene el TPM 2.0 y el firmware UEFI que necesita Windows 11.
detail-move-hardware-missing = Este equipo no tiene { $missing }, así que Windows Update no lo pasará a la versión { $release }. Haga una copia de seguridad de sus archivos y reinstale Windows con una ISO de Atlas.
detail-move-hardware-unread = Atlas no pudo leer todo el hardware de este equipo, así que lo comprobará Windows Update.
# $drive es una unidad, como C:; $free y $needed son gigabytes enteros.
detail-move-space-ok = { $drive } tiene { $free } GB libres.
detail-move-space-short = La versión { $release } necesita { $needed } GB libres en { $drive }, y solo hay { $free } GB. Libere espacio y Atlas volverá a comprobarlo por sí solo.
detail-move-space-unknown = No se pudo comprobar el espacio libre para la actualización de Windows. Reinicie su PC y vuelva a comprobar. ({ $error })
detail-move-update-source-ok = Este equipo recibe las actualizaciones de Windows Update.
detail-move-update-source-managed = Este equipo recibe las actualizaciones del servidor de su organización, que no ofrece la versión { $release }. Consulte con su organización o reinstale Windows con una ISO de Atlas.

## Paso 2: Sus preferencias
## Una sola pantalla con todas las preguntas, una tarjeta para cada una, y los extras opcionales
## plegados debajo.

# Una vez, arriba de Sus preferencias. Solo nombra lo que la carpeta Atlas puede revertir.
options-change-later = Más adelante puede cambiar Microsoft Defender, las protecciones del procesador y la configuración de actualizaciones desde la carpeta Atlas de su escritorio.
# La línea de estado de la tarjeta plegada Extras opcionales, con options-extras-show o -hide al lado.
options-extras-none = Ninguno seleccionado
# $count es cuántas casillas de los extras están marcadas.
options-extras-ticked =
    { $count ->
        [one] { $count } seleccionado
       *[other] { $count } seleccionados
    }
# Vínculos que despliegan y pliegan la tarjeta Extras opcionales.
options-extras-show = Mostrar
options-extras-hide = Ocultar
# Bajo el título de cada pregunta, una frase como máximo.
question-defender-description = Microsoft Defender es el antivirus integrado en Windows.
question-mitigations-description = Estas protecciones, también llamadas mitigaciones de seguridad, protegen contra vulnerabilidades del procesador, como Spectre y Meltdown, y contra ataques que aprovechan errores de las aplicaciones.
question-auto-updates-description = En ambos casos, Atlas mantiene Windows en su versión actual y desactiva las actualizaciones automáticas de las aplicaciones de Microsoft Store.
question-browser-description = Atlas no cambiará la configuración de su navegador.
# Una línea bajo una respuesta distinta de la recomendada: lo que cuesta.
# cost-defender-disable también aparece bajo Quitar Microsoft Defender en Instalación y en Inicio,
# y tras una instalación que quitó Defender.
cost-defender-disable = Su PC no tendrá antivirus hasta que instale otro, y Windows dejará de avisarle antes de abrir aplicaciones o descargas no reconocidas.
# "Protección contra vulnerabilidades" es la página de Seguridad de Windows con ese nombre.
cost-mitigations-disable = También desactiva la Protección contra vulnerabilidades de las aplicaciones, como la Protección de flujo de control (CFG), lo que reduce la seguridad.
cost-auto-updates-disable = Abra Windows Update con regularidad para obtener las correcciones de seguridad.
cost-auto-updates-default = Windows puede reiniciar su PC para terminar de instalar actualizaciones.
# Bajo la respuesta del selector de la barra de tareas, que desactiva los atajos para cambiar.
cost-keyboard-shortcuts-off = Alt+Mayús y Ctrl+Mayús ya no cambian el idioma ni la distribución del teclado.
# Una línea bajo un extra opcional: lo que hace marcarlo.
extra-disable-hibernation = Libera espacio en disco, pero Hibernar e Inicio rápido dejan de estar disponibles.
extra-disable-power-saving = Su PC puede consumir más energía, calentarse más y tener menos autonomía.
extra-disable-core-isolation = Reduce la protección, y es posible que los juegos con sistemas antitrampas como Riot Vanguard o FACEIT no se inicien hasta que vuelva a activar la integridad de memoria.
extra-uninstall-edge = Se eliminan los favoritos, el historial y las contraseñas guardadas de Edge en este equipo, salvo lo sincronizado con su cuenta de Microsoft.
extra-install-toolbox = Le ayuda a administrar la configuración de Atlas, aunque algunas funciones pueden estar sin terminar mientras esté en versión beta.
extra-install-eclean = Una herramienta del equipo de AtlasOS para revisar archivos innecesarios y aplicaciones de inicio, que requiere una cuenta y conexión a Internet.
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
# El nombre corto de cada decisión en mitad de una frase, como en summary-change-a11y
# ("Cambiar el navegador") y update-path-differs. Con artículo; los nombres de producto, sin él.
screen-update-path-name = cómo se actualiza Atlas
screen-defender-name = Microsoft Defender
screen-mitigations-name = las protecciones del procesador
screen-updates-name = Windows Update
screen-keyboard-name = los idiomas del teclado
screen-browser-name = el navegador
screen-power-name = la energía y la seguridad
screen-apps-name = las aplicaciones
screen-optional-apps-name = las aplicaciones opcionales
# Una pregunta de una sola respuesta para la que esta aplicación no tiene nombre, como una que
# agrega un paquete de Atlas más reciente. Su título es screen-choose-one-title.
screen-package-choice-name = una opción del paquete de Atlas
screen-extras-name = los extras opcionales
# Pregunta para una elección obligatoria para la que esta aplicación no tiene un texto específico.
screen-generic-question = Elija una opción para { $title }
learn-more-defender = Más información sobre Microsoft Defender
learn-more-mitigations = Más información sobre las protecciones del procesador
learn-more-updates = Más información sobre Windows Update
learn-more-browser = Más información sobre los navegadores
learn-more-power = Más información sobre energía y seguridad
learn-more-apps = Más información sobre las aplicaciones
learn-more-eclean = Más información sobre eclean
learn-more-keyboard = Más información sobre los idiomas del teclado
learn-more-generic = Leer la guía de configuración
# Una línea bajo la respuesta elegida: qué significa para el equipo.
consequence-defender-enable = Conserva el antivirus integrado de Windows para ayudar a proteger su PC frente a virus y otras amenazas.
consequence-mitigations-default = Mantiene las protecciones predeterminadas de Windows contra las vulnerabilidades del procesador y los ataques que aprovechan errores de las aplicaciones.
# Bajo Desactivar las protecciones del procesador.
consequence-mitigations-disable = También desactiva la Protección contra vulnerabilidades de las aplicaciones, como la Protección de flujo de control (CFG). Esto reduce la seguridad. La posible diferencia de rendimiento depende de su procesador.
consequence-auto-updates-disable = Abra Windows Update con regularidad para instalar las actualizaciones. Las notificaciones de actualizaciones seguirán activadas.
consequence-auto-updates-default = Windows instalará las actualizaciones automáticamente, incluidas las correcciones de seguridad.

## Paso 2 al actualizar o reinstalar el Atlas instalado

# La primera pantalla de Sus preferencias al actualizar el Atlas instalado. $version es la versión
# de Atlas que se instala, como 0.6.1.
update-path-update-title = ¿Cómo quiere actualizar a Atlas { $version }?
# La misma pantalla al volver a instalar la versión de Atlas que ya tiene este equipo.
update-path-reinstall-title = ¿Cómo quiere reinstalar Atlas { $version }?
# Las dos respuestas de esa pantalla, cada una con su línea de detalle. Otros mensajes las nombran.
update-path-keep = Conservar mis preferencias
update-path-keep-detail = Atlas conserva cada preferencia tal como está ahora en este equipo y no cambia ninguna.
update-path-choose = Volver a elegir
update-path-choose-detail = Parte de la configuración actual de este equipo. Se conservan sus aplicaciones, archivos y personalización.
# Encabezado de la lista bajo las dos respuestas: una fila por preferencia, tal como está ahora.
update-path-now-title = Sus preferencias actuales en este equipo
# El valor de una fila para una preferencia que el equipo no muestra.
update-path-unknown = Atlas no puede saberlo a partir de su PC, así que se lo pregunta
# Sobre esa lista. $choices enumera mensajes screen-*-name, como "Microsoft Defender y las
# protecciones del procesador", unidos con list-and.
update-path-differs = Este equipo no coincide con lo que Atlas registró para { $choices }.
# Sobre las preguntas que Conservar mis preferencias aún hace.
keep-choices-asked = Atlas conserva todas las demás preferencias tal como están ahora en este equipo.
# Una etiqueta breve bajo la respuesta que tiene ahora este equipo, en Volver a elegir.
option-now = Actualmente en este equipo
# Bajo una respuesta de Volver a elegir cuando elegirla cambia este equipo.
change-defender-enable = Atlas restaura Microsoft Defender. Después del reinicio, active su protección en Seguridad de Windows.
change-mitigations-default = Atlas vuelve a activar las protecciones del procesador tal como las configura Windows. El cambio se aplica después del reinicio.
# Bajo Mantener las protecciones del procesador cuando todas están activadas.
change-mitigations-all-on = Todas las protecciones del procesador están activadas ahora. Si las mantiene, seguirán todas activadas.
change-auto-updates-default = Atlas vuelve a dejar que Windows instale las actualizaciones automáticamente.
# Bajo Desactivar la hibernación, el ahorro de energía o VBS cuando la casilla se desmarca y este
# equipo los tiene desactivados.
change-hibernation-on = Atlas vuelve a activar la hibernación.
change-power-saving-on = Atlas vuelve a activar el ahorro de energía y restaura su plan de energía anterior, o el plan Equilibrado si no había ninguno.
change-core-isolation-on = Atlas vuelve a activar la seguridad basada en virtualización (VBS), salvo que una directiva de este equipo la controle. El cambio se aplica después del reinicio.
# Bajo Quitar la aplicación Recortes cuando está marcada y este equipo aún tiene la aplicación.
change-remove-snipping-tool = Quita la aplicación Recortes para todos los usuarios de este equipo. Atlas no podrá restaurarla después, pero usted puede volver a instalarla desde Microsoft Store.
# Install or Remove Edge es un nombre de archivo de la carpeta Atlas, en inglés en todos los equipos.
fixed-uninstall-edge = Microsoft Edge ya se quitó, y actualizar Atlas no puede restaurarlo. Para volver a instalarlo, use Install or Remove Edge en la carpeta Atlas.
# Lo mismo para una aplicación que instaló Atlas. $app es su nombre, como Atlas Toolbox o Brave.
fixed-installed = { $app } está instalado. Atlas no desinstala aplicaciones; para quitarlo, vaya a Aplicaciones instaladas en Configuración.
# $installed y $browser son nombres de navegador, como Brave y Firefox.
browser-also = { $installed } sigue instalado y Atlas también instala { $browser }.

## Texto del paquete de Atlas
## Etiquetas y descripciones de las opciones y preguntas del paquete de Atlas,
## según sus identificadores en el atlas.json del paquete. La aplicación las
## muestra en lugar del texto en inglés del paquete; una opción o pregunta que
## añada un paquete más nuevo, sin mensaje aquí, muestra el texto en inglés.
## Una opción cuya etiqueta la recomienda tiene también una forma -short, sin la
## recomendación, para el resumen, Inicio y los registros.

package-option-defender-enable = Conservar Microsoft Defender (recomendado)
package-option-defender-enable-short = Conservar Microsoft Defender
package-option-defender-disable = Quitar Microsoft Defender
package-option-mitigations-default = Mantener las protecciones del procesador (recomendado)
package-option-mitigations-default-short = Mantener las protecciones del procesador
package-option-mitigations-disable = Desactivar las protecciones del procesador
package-option-auto-updates-disable = Instalar las actualizaciones por mi cuenta
package-option-auto-updates-default = Instalar las actualizaciones automáticamente
package-option-disable-hibernation = Desactivar la hibernación
package-option-disable-power-saving = Desactivar el ahorro de energía
package-option-disable-core-isolation = Desactivar la seguridad basada en virtualización (VBS)
package-option-remove-snipping-tool = Quitar la aplicación Recortes
package-option-uninstall-edge = Quitar Microsoft Edge
package-option-install-another-browser = Instalar un navegador
package-option-install-toolbox = Instalar Atlas Toolbox
package-option-install-eclean = Instalar eclean
package-option-browser-brave = Brave
package-option-browser-librewolf = LibreWolf
package-option-browser-firefox = Firefox
package-option-browser-chrome = Chrome
package-choice-defender-description = Microsoft Defender es el antivirus integrado en Windows. Quítelo solo si entiende los riesgos y piensa usar otra aplicación antivirus. Sea cual sea su elección, Atlas desactiva el Control inteligente de aplicaciones, la Protección mejorada contra suplantación de identidad y Encontrar mi dispositivo.
package-choice-mitigations-description = Estas protecciones, también llamadas mitigaciones de seguridad, ayudan a proteger contra las vulnerabilidades del procesador, como Spectre y Meltdown, y contra los ataques que aprovechan errores de las aplicaciones. Se recomienda mantener la configuración predeterminada de Windows.
package-choice-auto-updates-description = Las actualizaciones de Windows incluyen correcciones de seguridad. Puede dejar que Windows las instale automáticamente o instalarlas por su cuenta. En ambos casos, Atlas mantiene Windows en su versión actual, que solo recibe correcciones de seguridad hasta que Microsoft deje de darle soporte. Atlas también desactiva las actualizaciones automáticas de las aplicaciones de Microsoft Store, así que actualícelas desde Microsoft Store.
package-choice-browser-description = Elija un navegador para instalar. Atlas no cambiará la configuración de su navegador.

## Paso 3: Seguridad de Windows

# Shown instead of the switch list when Microsoft Defender isn't on this PC and the user
# chose to remove it.
security-banner-absent-title = Microsoft Defender no está instalado en este equipo
# El mensaje bajo security-banner-absent-title y security-banner-removed-title.
security-nothing-to-turn-off = No hay interruptores de protección que desactivar.
# En lugar de security-banner-absent-title cuando el propio paquete de Atlas quitó Microsoft Defender
# y sigue quitado.
security-banner-removed-title = Atlas quitó Microsoft Defender de este equipo
# Cuando el propio paquete de Atlas quitó Microsoft Defender y esta instalación lo restaura.
security-banner-restore-title = Atlas restaura Microsoft Defender en esta instalación
security-restore-nothing-to-turn-off = Defender aún no se está ejecutando, así que no hay nada que desactivar. Después del reinicio, active su protección en Seguridad de Windows.
# Un aviso que no detiene el paso: el usuario eligió conservar Microsoft Defender, pero no está en
# este equipo y Atlas no lo quitó. Inicio y la ventana "Atlas está instalado" usan el mismo título.
security-banner-missing-title = Falta Microsoft Defender
security-banner-missing-message = Atlas no lo quitó, así que no puede restaurarlo. Puede continuar, pero su PC no tendrá antivirus hasta que instale otra aplicación antivirus o repare Windows.
# Mientras un interruptor está activado o no se puede leer ninguno. Atlas ha abierto Seguridad de
# Windows en los interruptores, y Abrir Seguridad de Windows la vuelve a abrir.
security-turn-off-title = Desactive estos cuatro interruptores
security-turn-off-message = Microsoft Defender puede bloquear a Atlas mientras se instala. Si conserva Defender, vuelva a activarlos después de la instalación.
# El nombre de la página en Seguridad de Windows.
security-list-title = Configuración de antivirus y protección contra amenazas
security-switch-off = Desactivado
security-switch-on = Activado
security-switch-unreadable = No se pudo leer
security-switch-reading = Comprobando
security-all-off = Todo desactivado
# Nombre accesible de una fila de interruptor. $state es uno de los mensajes security-switch-*.
security-a11y = { $title }: { $state }
# Partes del resumen "2 aún activados, 1 no se pudo leer".
security-count-still-on =
    { $count ->
        [one] { $count } aún activado
       *[other] { $count } aún activados
    }
security-count-unreadable =
    { $count ->
        [one] { $count } no se pudo leer
       *[other] { $count } no se pudieron leer
    }
security-count-join = { $a }, { $b }
# Todos los interruptores que Atlas pudo leer están desactivados y los demás no se pudieron leer.
# $switches los nombra como Seguridad de Windows, unidos con list-and; $count es cuántos son.
security-unread-switches-title =
    { $count ->
        [one] Atlas no pudo leer el interruptor { $switches }
       *[other] Atlas no pudo leer los interruptores { $switches }
    }
security-unread-message =
    { $count ->
        [one] Asegúrese de que esté desactivado en Seguridad de Windows.
       *[other] Asegúrese de que estén desactivados en Seguridad de Windows.
    }
# La casilla bajo security-unread-message.
security-unread-confirm =
    { $count ->
        [one] He comprobado que el interruptor { $switches } está desactivado
       *[other] He comprobado que los interruptores { $switches } están desactivados
    }
# La casilla cuando Atlas no pudo leer ninguno de los cuatro interruptores.
security-acknowledge = He comprobado Seguridad de Windows y los cuatro interruptores están desactivados
security-unknown-unelevated-title = Atlas necesita permiso para comprobar la protección
security-unknown-unelevated-message = Vuelva a abrir Atlas como administrador para que pueda comprobar la configuración de Microsoft Defender.
# Los cuatro interruptores, con los nombres que usa Seguridad de Windows en español, y por qué
# deben estar desactivados.
protection-tamper = Protección contra alteraciones
protection-tamper-why = Para que Atlas pueda cambiar la configuración de seguridad.
protection-realtime = Protección en tiempo real
protection-realtime-reason = Los análisis pueden bloquear los archivos de Atlas.
protection-cloud = Protección basada en la nube
protection-cloud-reason = Las comprobaciones en línea pueden bloquear los archivos de Atlas.
protection-samples = Envío automático de muestras
protection-samples-why = Para que los archivos de Atlas no se envíen a Microsoft.

## Paso 4: Instalación

outcome-succeeded-title = Atlas está instalado
outcome-lost-title = No se pudo confirmar el resultado de la instalación
outcome-failed-title = La instalación no terminó
# El mensaje de la barra de resultado tras un intento fallido: qué pasó y qué hacer, en dos frases
# como máximo. El botón de la barra es el siguiente paso, así que el mensaje no lo nombra.
# Junto a go-to-ready.
result-requirements = Su PC no cumplía los requisitos de instalación, así que la instalación no hizo ningún cambio.
# Las variantes -resumed aparecen al reintentar una instalación que un intento anterior ya había empezado a aplicar.
result-requirements-resumed = Su PC no cumplía los requisitos de instalación, así que este intento se detuvo. Un intento anterior ya hizo cambios.
# Junto a common-restart-as-administrator.
result-not-elevated = Atlas no tenía permiso de administrador, así que la instalación no hizo ningún cambio.
result-not-elevated-resumed = Atlas no tenía permiso de administrador, así que este intento se detuvo. Un intento anterior ya hizo cambios.
# La comprobación del instalador encontró actualizaciones de Windows o de la Store sin terminar. Junto a
# go-to-ready, donde la actualización vuelve a empezar por sí sola.
result-preparation-stale = Atlas no pudo confirmar que Windows y las aplicaciones de la Store estén al día, así que la instalación se detuvo antes de cambiar Windows.
result-preparation-stale-resumed = Atlas no pudo confirmar que Windows y las aplicaciones de la Store estén al día, así que este intento se detuvo. Un intento anterior ya hizo cambios.
result-failed-preflight = La instalación se detuvo antes de cambiar nada. Puede volver a intentarlo.
result-failed-staging = La instalación se detuvo al preparar los archivos, antes de cambiar Windows. Puede volver a intentarlo.
# Junto a common-open-windows-security. Los "interruptores de protección" son los cuatro que desactivó el usuario.
result-failed-applying = Es posible que ya se hayan hecho algunos cambios. Puede volver a intentarlo o, si lo deja aquí, volver a activar los interruptores de protección en Seguridad de Windows.
# Las variantes -defender-removed, cuando ya se quitó Microsoft Defender y no hay interruptores que reactivar.
result-failed-applying-defender-removed = Es posible que ya se hayan hecho algunos cambios. Puede volver a intentarlo.
result-failed-resumed = Este intento se detuvo antes de tiempo, pero un intento anterior ya hizo cambios. Puede volver a intentarlo o, si lo deja aquí, volver a activar los interruptores de protección en Seguridad de Windows.
result-failed-resumed-defender-removed = Este intento se detuvo antes de tiempo, pero un intento anterior ya hizo cambios. Puede volver a intentarlo.
# Las variantes -repeated: el intento se detuvo con el mismo error que el anterior, así que remiten a
# un informe. "Enviar un informe" es report-title, en los vínculos bajo la barra.
result-failed-repeated = Este intento se detuvo con el mismo error que el anterior, así que es poco probable que sirva volver a intentarlo. Envíe un informe para que el equipo de Atlas encuentre la causa y, si lo deja aquí, vuelva a activar los interruptores de protección.
result-failed-repeated-defender-removed = Este intento se detuvo con el mismo error que el anterior, así que es poco probable que sirva volver a intentarlo. Envíe un informe para que el equipo de Atlas encuentre la causa.
# $apps contiene los nombres de paquete que Windows da a las aplicaciones, como MSTeams (texto), unidos con list-and.
result-failed-repeated-apps = Windows siguió sin quitar { $apps }, así que es poco probable que sirva volver a intentarlo. Envíe un informe para que el equipo de Atlas encuentre la causa y, si lo deja aquí, vuelva a activar los interruptores de protección.
result-failed-repeated-apps-defender-removed = Windows siguió sin quitar { $apps }, así que es poco probable que sirva volver a intentarlo. Envíe un informe para que el equipo de Atlas encuentre la causa.
result-not-started = El instalador no se inició a tiempo, así que la instalación no hizo ningún cambio. Puede volver a intentarlo.
result-lost = El instalador se detuvo sin informar de un resultado, así que es posible que se hayan hecho algunos cambios. Puede volver a intentarlo o, si lo deja aquí, volver a activar los interruptores de protección en Seguridad de Windows.
# En lugar de result-lost cuando ya no está Defender, como en las variantes -defender-removed.
result-lost-defender-removed = El instalador se detuvo sin informar de un resultado, así que es posible que se hayan hecho algunos cambios. Puede volver a intentarlo.
restart-now-message = Windows se está reiniciando para terminar de configurar Atlas.
restart-stopped = Reinicio automático cancelado. Guarde su trabajo y reinicie su PC para terminar de configurar Atlas.
restart-needed = Guarde su trabajo y reinicie su PC para terminar de configurar Atlas.
restart-dont-now = Reiniciar más tarde
restart-now = Reiniciar ahora
# La barra cuando las últimas comprobaciones no inician el instalador. Su mensaje nombra lo que
# requiere atención; el botón es la solución y los errores están tras Mostrar detalles.
preflight-title = La instalación no se ha iniciado
# Junto a go-to-options. $choice es un mensaje screen-*-name tal como se lee en mitad de una frase,
# como "las protecciones del procesador".
preflight-choice-unanswered = Atlas necesita su respuesta sobre { $choice }.
preflight-choices-unusable = Atlas no pudo usar estas preferencias.
# Junto a go-to-ready. $checks enumera nombres check-*, como "Conexión a Internet y Alimentación
# eléctrica", unidos con list-and; $count es cuántos nombra.
preflight-checks-changed =
    { $count ->
        [one] { $checks } requiere atención desde que Atlas comprobó su PC.
       *[other] { $checks } requieren atención desde que Atlas comprobó su PC.
    }
# Junto a common-open-windows-security. $summary es el resumen de Seguridad de Windows, como "1 aún activado".
preflight-security-changed = Seguridad de Windows ha cambiado desde que desactivó los interruptores: { $summary }.
preflight-busy-wait = Otra ventana de Atlas está iniciando una instalación. Espere un momento y vuelva a intentarlo.
# Junto a home-start-over.
preflight-taken-over-start-over = Otra ventana de Atlas está usando ahora esta configuración. Continúe allí o empiece de nuevo aquí.
# Junto a go-to-ready.
preflight-record-unreadable-check = Atlas no pudo comprobar si una instalación anterior sigue en curso, así que no ha iniciado otra.
preflight-not-started = Atlas no pudo iniciar el instalador, así que la instalación no hizo ningún cambio. Puede volver a intentarlo.
# En lugar de preflight-not-started al reintentar una instalación que un intento anterior ya había empezado a aplicar.
preflight-not-started-resumed = Atlas no pudo iniciar el instalador, pero un intento anterior ya hizo cambios. Puede volver a intentarlo.
go-to-ready = Ir a Preparación
# Botón de la barra de Instalación cuando una pregunta no tiene respuesta; abre Sus preferencias.
go-to-options = Ir a Sus preferencias
# Botón de la barra de Instalación cuando hay que confirmar interruptores que Atlas no puede leer.
go-to-security = Ir a Seguridad de Windows
# Sustituye a Continuar en una elección abierta desde un vínculo Cambiar del paso Instalación, cuando Continuar lleva directamente de vuelta a él.
go-to-install = Volver a Instalación
output-problem-title = No se pudo leer el progreso de la instalación
install-elevate-title = Atlas necesita permiso para instalar
# Bajo install-elevate-title, junto a common-restart-as-administrator.
install-elevate-uac = Cuando Atlas se vuelva a abrir, Windows le pedirá permiso.
# Una barra en Instalación, junto a go-to-ready, cuando ningún paquete de Atlas está listo.
install-package-missing = El paquete de Atlas no está listo
# Paso 4 cuando el paso 1 no se ha completado en esta sesión (comprobaciones o actualizaciones de Windows); go-to-ready es el botón.
install-not-ready-title = Termine primero el paso Preparación
install-not-ready-message = Atlas necesita terminar de comprobar su PC y de actualizar Windows antes de poder instalar.
# Una barra en Instalación cuando una nueva lectura de los interruptores ya no es correcta.
# $summary es el resumen de Seguridad de Windows, como "1 aún activado".
install-switches-title = Vuelva a desactivar los interruptores de protección
install-switches-message = Seguridad de Windows: { $summary }.
# La tarjeta de Instalación cuando nada impide instalar, y en otro caso.
summary-ready-title = Listo para instalar
summary-setup-title = Su configuración de Atlas
summary-activation = Activación
summary-activation-ok = Activado. Atlas no cambiará esto.
summary-activation-missing = Sin activar. Puede continuar, pero Atlas no activará Windows.
summary-activation-unknown = Atlas no cambiará el estado de activación de Windows.
# Cuánto suele tardar la instalación, según el paquete de Atlas. La tarjeta muestra el primero si la
# casilla de debajo está marcada, y el segundo si no lo está.
summary-time-restarts =
    { $minutes ->
        [one] Suele tardar alrededor de { $minutes } minuto y después su PC se reinicia
       *[other] Suele tardar alrededor de { $minutes } minutos y después su PC se reinicia
    }
summary-time-restart-yourself =
    { $minutes ->
        [one] Suele tardar alrededor de { $minutes } minuto y después debe reiniciar su PC
       *[other] Suele tardar alrededor de { $minutes } minutos y después debe reiniciar su PC
    }
# La casilla de la tarjeta. Es la misma opción que settings-restart-automatically.
summary-restart-automatically = Reiniciar automáticamente al terminar la instalación
# Una fila de los detalles: lo que Atlas desactiva sea cual sea la respuesta sobre Microsoft Defender.
summary-turned-off = También se desactivan
summary-turned-off-value = Control inteligente de aplicaciones, Protección mejorada contra suplantación de identidad y Encontrar mi dispositivo
summary-show-command = Mostrar el comando de instalación
summary-hide-command = Ocultar el comando de instalación
# Nombre accesible del botón Copiar bajo el comando de instalación.
summary-copy-command-a11y = Copiar el comando de instalación
summary-command-unavailable = No se pudo preparar el comando de instalación. Detalles: { $error }
summary-not-chosen = Aún sin elegir
# Nombre accesible de un vínculo Cambiar. $title es un mensaje screen-*-name, como se lee en mitad de una frase.
summary-change-a11y = Cambiar { $title }
# La primera fila del resumen al actualizar o reinstalar. Su valor es update-path-keep o update-path-choose.
summary-update-path = Cómo se actualiza Atlas
# Por qué Continuar espera en Preparación: se lee como su descripción. 8 palabras o menos.
footer-still-checking = Preparando la instalación
footer-checks-blocked = Resuelva los problemas detectados para continuar
footer-manager-outdated = Descargue un Atlas Manager más reciente para continuar
footer-need-files = Obtenga el paquete de Atlas para continuar
# Variante de footer-need-files para la versión de prueba.
footer-need-package-bundled = Prepare el paquete de Atlas incluido para continuar
footer-drivers = Decida cómo se instalan los controladores para continuar
footer-windows-terms = Acepte los términos de licencia para continuar
footer-updating = Actualizando Windows y las aplicaciones de la Store…
footer-restart = Reinicie su PC para continuar
footer-reading-security = Comprobando los interruptores de protección
# Por qué Continuar espera en Seguridad de Windows: mientras un interruptor está activado, y después
# mientras solo quedan por confirmar los que Atlas no pudo leer.
footer-security-pending = Desactive los cuatro interruptores para continuar
footer-security-confirm = Para continuar, confirme los interruptores que Atlas no pudo leer
# Junto a Instalar Atlas con el reinicio automático activado: el PC se reinicia al terminar.
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

installing-title = Instalando Atlas
# Lo que está haciendo Atlas, bajo installing-title y como nombre accesible de la barra de
# progreso: una frase verbal breve que termina en puntos suspensivos.
installing-checking-label = Comprobando su PC…
installing-staging-label = Copiando los archivos de Atlas…
installing-applying-label = Configurando Windows…
installing-finishing-label = Finalizando…
# La línea bajo la barra de progreso: cuando el PC se reinicia solo al terminar, y cuando no.
installing-keep-on-restart = Mantenga el equipo encendido y conectado a la corriente. Se reiniciará automáticamente al terminar la instalación.
installing-keep-on = Mantenga el equipo encendido y conectado a la corriente. Reinícielo al terminar la instalación.
# Cuando Atlas no puede seguir el registro del instalador. Su título es output-problem-title;
# su botón, common-open-log-folder.
installing-output-problem = Esto no significa que la instalación se haya detenido.
installing-installed-title = Atlas está instalado
# Bajo installing-installed-title durante la cuenta atrás, con installing-restart-save debajo.
installing-restart-countdown =
    { $seconds ->
        [one] Su PC se reiniciará en { $seconds } segundo.
       *[other] Su PC se reiniciará en { $seconds } segundos.
    }
installing-restart-save = Guarde antes su trabajo.

## La ventana "Atlas está instalado" tras el reinicio

installed-title-version = Atlas { $version } está instalado
installed-title = Atlas está instalado
installed-ready = Todo listo. Ya puede usar su PC con Atlas.
# Una línea bajo la tarjeta cuando el usuario instala los controladores por su cuenta, con el
# vínculo installed-drivers-guide debajo.
installed-manual-drivers-detail = Obtenga los controladores del chipset, de red y de gráficos del fabricante de su PC, placa base o dispositivo.
installed-drivers-guide = Abrir la guía de controladores
# Tras una instalación que quitó Microsoft Defender. Su mensaje es cost-defender-disable.
installed-defender-removed-title = Se quitó Microsoft Defender
# Inicio y la ventana "Atlas está instalado", tras una instalación que conservó Microsoft Defender,
# cuando falta y ningún paquete de Atlas lo quitó. Título: security-banner-missing-title; botón: report-title.
defender-missing-message = Atlas no lo quitó. Si no usa otra aplicación antivirus, instale una para proteger su PC.
# Cuando el registro de Atlas conservó Microsoft Defender, pero el propio paquete de Atlas aún lo
# quita. Botón: home-reinstall. 7. Security, Defender y Toggle Defender son nombres de carpeta y de
# archivo de la carpeta Atlas, en inglés en todos los equipos.
installed-defender-not-restored-title = Microsoft Defender sigue sin restaurarse
defender-not-restored-message = Una actualización anterior de Atlas no lo restauró, así que Defender no protege su PC. Reinstale Atlas y conserve Defender, o ejecute Toggle Defender desde 7. Security > Defender en la carpeta Atlas.
# Cuando lo que registró la instalación para algunas preferencias no es lo elegido. Siguen los
# vínculos de ayuda.
installed-not-applied-title = Algunas preferencias no se aplicaron
# $choices enumera sus nombres tal como se leen en mitad de una frase (screen-*-name), como
# "Microsoft Defender y las protecciones del procesador", unidos con list-and; $count es cuántos nombra.
installed-not-applied-choices =
    { $count ->
        [one] Esta preferencia se mantuvo como estaba: { $choices }.
       *[other] Estas preferencias se mantuvieron como estaban: { $choices }.
    }
# Tras una actualización cuyo último paso volvió a desactivar o pausar Windows Update, como piden
# las propias preferencias de Atlas del usuario.
installed-update-off-title = Windows Update vuelve a estar desactivado, como eligió
installed-update-off-message = Mientras esté desactivado, su PC no recibirá actualizaciones de seguridad.
installed-update-paused-title = Las actualizaciones de Windows vuelven a estar en pausa, como eligió
installed-update-paused-message = Mientras estén en pausa, su PC no recibirá actualizaciones de seguridad.

## Configuración

settings-title = Configuración
# Encabezados de las secciones de la página. settings-language y settings-help también encabezan secciones.
settings-appearance = Apariencia
settings-installation = Instalación
settings-privacy = Privacidad
settings-theme = Tema de la aplicación
settings-theme-system = Igual que Windows
settings-theme-light = Claro
settings-theme-dark = Oscuro
settings-theme-contrast-note = Atlas está usando los colores del tema de contraste de Windows.
settings-language = Idioma
# La opción de la sección Idioma y el nombre de su cuadro.
settings-app-language = Idioma de la aplicación
# La primera opción del cuadro de idioma: seguir a Windows y el idioma que resulta.
# $language es el nombre de ese idioma en ese idioma, por ejemplo "Español (España)".
settings-language-match-windows = Igual que Windows – { $language }

# Etiqueta breve tras cada idioma traducido pero aún no revisado por un hablante nativo.
settings-language-preview-tag = Versión preliminar
# Bajo el cuadro de idioma mientras se usa una traducción preliminar, después de descartar su aviso.
settings-language-preview-in-use = Un hablante nativo aún no ha revisado esta traducción.
# Una barra arriba del contenido mientras se usa una traducción preliminar, hasta que el usuario la
# descarta. $language es el nombre del idioma en ese idioma.
preview-notice = { $language } es una traducción preliminar y puede contener errores.
preview-notice-switch = Cambiar a inglés
preview-notice-language = Cambiar idioma
# Bajo el cuadro de idioma cuando el idioma elegido no está en esta versión y el cuadro muestra inglés.
settings-language-chosen-unavailable = El idioma que eligió no está en esta versión de Atlas, así que Atlas se muestra en inglés. Su elección se conserva.
# Con Igual que Windows elegido, cuando Atlas no tiene ninguno de los idiomas para mostrar de Windows.
settings-language-windows-unsupported = Atlas aún no está disponible en su idioma para mostrar de Windows, así que se muestra en inglés.
# Con Igual que Windows elegido, cuando no se pudieron leer los idiomas para mostrar de Windows.
settings-language-windows-unreadable = Atlas no pudo comprobar su idioma para mostrar de Windows, así que se muestra en inglés.
# Cuando el formato regional es de otro idioma o región que la aplicación. $locale es el nombre
# del formato regional en su propio idioma, por ejemplo "English (United States)".
settings-language-formats = Los números, las fechas y las horas siguen su formato regional de Windows: { $locale }.
# En lugar de settings-language-formats cuando el formato regional escribe fechas u horas de derecha a
# izquierda. $locale es el nombre del formato en inglés, por ejemplo "Arabic (Saudi Arabia)".
settings-language-formats-numbers-only = Los números siguen su formato regional de Windows: { $locale }. Las fechas y las horas usan un formato estándar porque Atlas aún no puede mostrar texto de derecha a izquierda.
settings-language-contribute = Ayudar a traducir Atlas
# El interruptor de análisis de uso, con su descripción y un vínculo a la política de privacidad.
settings-share-usage = Compartir datos de uso con Atlas
settings-share-usage-description = Las páginas que abre, las ISO que crea y si las instalaciones terminan bien.
settings-privacy-policy = Política de privacidad
# El interruptor abarca el reinicio tras instalar y el que necesitan las actualizaciones de Windows
# y de la Store antes de instalar.
settings-restart-automatically = Reiniciar automáticamente después de instalar y actualizar
settings-restart-automatically-description = Su PC se reinicia en menos de un minuto cuando Atlas termina, y se cierran las aplicaciones abiertas.
settings-restart-locked = Podrá cambiar esto cuando termine la instalación.
# Encabezado sobre Enviar un informe, Exportar diagnósticos y settings-open-data-folder.
settings-help = Ayuda
settings-about = Acerca de
settings-about-app = Atlas Manager
settings-about-licence = Licencia
settings-about-licence-value = GPL-3.0, gratuito y de código abierto
settings-view-source = Ver el código fuente
# Vínculo que abre los avisos de licencia de terceros.
settings-view-licences = Ver los avisos de licencia
# Bajo los vínculos cuando Windows no pudo abrir los avisos.
settings-licences-failed = No se pudieron abrir los avisos de licencia. Vuelva a intentarlo o búsquelos en el código fuente en GitHub.
settings-open-data-folder = Abrir la carpeta de la aplicación

## Opciones adicionales: explicaciones que se muestran antes de elegir.

consequence-disable-hibernation = Libera el espacio en disco que se usa para guardar la sesión al hibernar. Las opciones Hibernar e Inicio rápido dejarán de estar disponibles.
consequence-disable-power-saving = Desactiva las funciones de ahorro de energía. Su PC puede consumir más energía, calentarse más y tener menos autonomía.
consequence-disable-core-isolation = Desactiva una capa adicional de seguridad de Windows, incluida la integridad de memoria. Esto reduce la protección, y es posible que los juegos con sistemas antitrampas como Riot Vanguard o FACEIT no se inicien hasta que vuelva a activar la integridad de memoria.
consequence-remove-snipping-tool = Quita la aplicación de Windows para hacer capturas y grabaciones de pantalla.
consequence-uninstall-edge = Quita el navegador Microsoft Edge. Asegúrese de tener otro navegador o elija uno abajo.
# Under Remove Microsoft Edge in the Install step's summary, with a caution glyph.
caution-uninstall-edge = Elimina los favoritos, el historial y las contraseñas guardadas de Edge en este equipo.
consequence-install-another-browser = Elija un navegador abajo y Atlas lo instalará por usted.
consequence-install-toolbox = Agregue Atlas Toolbox para administrar la configuración de Atlas con más facilidad. Toolbox está en versión beta, así que algunas funciones pueden estar sin terminar.
consequence-install-eclean = Una herramienta de mantenimiento creada por el equipo de AtlasOS para mantener su PC en orden después de la instalación. Revise archivos innecesarios y aplicaciones de inicio. Requiere una cuenta y conexión a Internet.

## Creación de la ISO
iso-open = Crear una ISO con Atlas
iso-title = Crear una ISO con Atlas
iso-recommended = Recomendado
# Títulos de los tres pasos de la ISO: de dónde sale Windows, cómo se configura y la revisión que
# crea la ISO.
iso-step-source = Windows
iso-step-setup = Configuración
iso-step-create = Creación
# La primera pregunta del paso Windows. Fija los valores predeterminados que siguen: arquitectura,
# idioma, edición, nombre de cuenta y controladores de red de este equipo.
iso-target-title = ¿Para qué equipo es esta ISO?
iso-target-this = Este equipo
iso-target-another = Otro equipo
# Cuando la ISO es para otro tipo de procesador que el de este equipo, así que solo vale Otro equipo.
# $architecture es iso-architecture-x64 o iso-architecture-arm64.
iso-target-arch = Esta ISO es para equipos { $architecture }.
iso-source = ISO de Windows
# Inicia la descarga de Windows 11 en el idioma y la arquitectura del texto de debajo
# (iso-download-caption). También en el menú Cambiar y en la barra de una ISO que Atlas no puede usar.
iso-download-windows = Descargar de Microsoft
# Lo que se descarga. $language es el nombre que da Microsoft al idioma, en inglés, como
# "English International"; $architecture es iso-architecture-x64 o -arm64.
iso-download-caption = Windows 11 · { $language } · { $architecture }
# Lo mismo mientras se carga la lista de idiomas de Microsoft.
iso-download-caption-loading = Windows 11 · { $architecture }
# Nombra el idioma y la arquitectura de la descarga en el nombre accesible de su vínculo Cambiar.
iso-download-what = Descarga de Windows
iso-download-language = Idioma
iso-download-arch = Arquitectura
iso-download-languages = Cargando idiomas…
# La etiqueta de la barra de progreso mientras se descarga Windows, y cuánto ha llegado. $received y
# $total son tamaños como "2,4 GB" (size-gigabytes).
iso-downloading = Descargando Windows 11…
iso-download-amount = { $received } de { $total }
# No se pudo conectar con el servicio de descargas de Microsoft, o la descarga se detuvo a medias.
# Reintentar (common-try-again) está al lado.
iso-download-unreachable = Atlas no pudo conectar con el servicio de descargas de Microsoft. Compruebe su conexión a Internet y vuelva a intentarlo.
iso-download-incomplete = La descarga no terminó. Compruebe su conexión a Internet y el espacio libre, y vuelva a intentarlo.
iso-download-website = Abrir la página de descarga de Microsoft
# Abre el selector de archivos para una ISO de Windows, y es el botón Abrir de ese selector. En las
# páginas de la ISO y del USB, y en la barra de una ISO que Atlas no puede usar.
iso-use-local = Elegir un archivo ISO
# Una etiqueta de estado mientras se comprueban los archivos, antes de que Continuar esté disponible.
iso-checking = Comprobando su ISO de Windows…
# Nombre accesible de la etiqueta Listo tras la comprobación. $facts es la arquitectura y el tamaño
# de la ISO, como "x64 · 6,6 GB".
iso-checked-a11y = ISO de Windows lista, { $facts }
iso-package-latest-label = Última versión
# La versión más reciente de Atlas es anterior a las que puede usar este Atlas Manager; debajo está
# Abrir un archivo de paquete (package-open-file).
iso-package-release-old = La versión más reciente de Atlas es anterior a las que puede usar este Atlas Manager.
# Mientras Atlas busca y descarga por sí solo el paquete de Atlas más reciente.
iso-package-fetching = Obteniendo la versión más reciente de Atlas…
# No se pudo buscar la versión más reciente; Reintentar está al lado.
iso-package-release-failed = Atlas no pudo buscar la versión más reciente. Compruebe su conexión a Internet y vuelva a intentarlo.
# Nombre accesible del botón Cambiar junto a un archivo: $action es el texto de ese botón y $field
# la etiqueta del archivo.
iso-pick-a11y = { $action }: { $field }
# Junto a Continuar no disponible en el paso Windows mientras aún no hay una ISO de Windows.
iso-need-windows = Obtenga una ISO de Windows para continuar
# La pregunta del paso Configuración sobre cuándo se eligen las preferencias del paquete.
iso-mode-question = ¿Cuándo quiere elegir sus preferencias de Atlas?
iso-mode-after = Después de iniciar sesión
iso-mode-after-description = Atlas le guía por la configuración después de que inicie sesión.
iso-mode-now = Ahora
iso-mode-now-description = Se guardan en la ISO. Instalará Atlas después de iniciar sesión.
# Una casilla bajo Ahora, cuya descripción ya dice que las preferencias se guardan en la ISO.
iso-mode-before-desktop = Terminar antes de que se abra el escritorio
iso-mode-before-desktop-description = Después de iniciar sesión, Atlas se ejecuta en pantalla completa hasta que termina de instalarse.
# En lugar de la pregunta cuando el paquete de Atlas no puede guardar preferencias en una ISO.
iso-mode-unavailable = Este paquete de Atlas no puede guardar preferencias en la ISO, así que las elegirá después de iniciar sesión.
iso-atlas-options = Preferencias de Atlas
# La línea de arriba del paso Creación.
iso-create-intro = Crear la ISO no cambia este equipo ni su ISO original.
iso-review-package = Paquete de Atlas
iso-review-output = Nueva ISO
iso-review-edition = Edición
iso-review-editions = Ediciones
iso-edition = Edición de Windows
# La edición que se muestra en la tarjeta de edición del paso Configuración cuando el programa de
# instalación de Windows pregunta qué edición instalar.
iso-edition-auto = Se elige al instalar Windows
# La primera opción del menú de edición de esa tarjeta, sobre las ediciones de la ISO: la que deja
# que el programa de instalación de Windows pregunte qué edición instalar.
iso-edition-auto-menu = Elegir al instalar Windows
# Una casilla opcional: aceptar aquí los términos evita que los pida el programa de instalación.
iso-accept-terms-optional = Aceptar los términos de licencia de Windows para que el programa de instalación no los pida
iso-architecture-x64 = x64
iso-architecture-arm64 = Arm64
# Un tamaño de archivo; $size es un número con formato (texto). Megabytes por debajo de un gigabyte.
size-megabytes = { $size } MB
size-gigabytes = { $size } GB
iso-review-account = Nombre de la cuenta
iso-review-target = Instalar en
iso-review-drivers = Controladores
# Una fila sobre las pantallas del programa de instalación de Windows que omite el archivo de respuesta.
iso-review-setup-screens = Programa de instalación de Windows
iso-review-skips = Omite las pantallas de cuenta de Microsoft y privacidad
iso-review-skips-terms = Omite las pantallas de licencia, cuenta de Microsoft y privacidad
iso-review-network = Controladores de red
iso-review-network-included = Controladores de Wi-Fi y Ethernet de este equipo
# La fila Preferencias de Atlas cuando se guardan en la ISO y terminan antes de que se abra el escritorio.
iso-review-mode-before-desktop = Ahora; se termina antes de que se abra el escritorio
# Bajo la nueva ISO en el paso Creación. $needed y $free son tamaños como "35,0 GB"
# (size-gigabytes); $drive es una unidad, como "C:".
iso-destination-space = Necesita { $needed } · { $free } libres en { $drive }
iso-destination-short = La ISO necesita { $needed } y { $drive } tiene { $free } libres. Libere espacio o guarde la ISO en otra unidad.
iso-destination-filesystem = { $drive } no admite los archivos grandes de la ISO. Guárdela en una unidad con formato NTFS, como la unidad de Windows.
iso-destination-unusable = Atlas solo puede guardar la ISO en una carpeta de una unidad de este equipo.
iso-create = Crear ISO
# Encabezado sobre la barra de progreso y la lista de etapas (iso-stage-*) mientras se crea la ISO.
iso-progress-title = Creando su ISO…
# La etiqueta de la barra de progreso: la etapa en curso, terminada en puntos suspensivos.
# $stage es uno de los mensajes iso-stage-*.
iso-progress-stage = { $stage }…
iso-stage-read = Leyendo la ISO de Windows
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
iso-progress-keep-open = Mantenga Atlas abierto hasta que termine.
iso-cancel = Cancelar creación
iso-cancelling = Esperando un punto seguro para cancelar
# El encabezado sobre la barra de progreso de una ISO o una unidad USB cuando se pide cancelar.
iso-cancelling-short = Cancelando…
iso-cancelled = Creación de la ISO cancelada
iso-cancelled-unchanged = Su ISO original no se ha modificado.
iso-complete = Su ISO está lista
iso-complete-backup = Haga una copia de seguridad de sus archivos antes de reinstalar Windows con ella.
# El botón principal de la página final, que abre el panel de la unidad USB.
iso-create-usb = Crear una unidad USB
iso-open-folder = Mostrar en la carpeta
iso-failed = No se pudo terminar de crear la ISO
# Bajo iso-failed, junto a Reintentar.
iso-failed-retry = Asegúrese de que sus archivos sigan donde los eligió y de que la unidad de destino esté conectada; después, vuelva a intentarlo.
# Título cuando falla la comprobación de los archivos; los mensajes de abajo dicen por qué.
iso-check-failed = No se pudieron comprobar los archivos
iso-check-failed-retry = Asegúrese de que la ISO y el paquete de Atlas hayan terminado de descargarse y vuelva a intentarlo.
# No se ejecutó nada porque no se pudo crear la carpeta de trabajo.
iso-unstaged = Atlas no pudo preparar su carpeta de trabajo, así que no ha cambiado nada.
# Títulos y mensajes para una ISO o un paquete que Atlas no puede usar. La barra ofrece la solución:
# iso-download-windows e iso-use-local para la ISO, iso-fix-package para el paquete.
iso-edition-unsupported-title = Esta ISO no tiene ninguna edición que admita Atlas
iso-edition-unsupported = Windows Home y LTSC no cuentan con soporte. Use una ISO con Pro, Education o Enterprise.
iso-customised-title = Esta ISO está personalizada
iso-customised = Ya contiene archivos de instalación, como autounattend.xml. Use una ISO sin modificar de Microsoft.
iso-preview-title = Esta ISO es una compilación preliminar
iso-preview = Su compilación de Windows no figura en la lista de versiones públicas de Microsoft. Use una ISO de Microsoft.
iso-windows-unsupported-title = Este paquete de Atlas no puede usar esta ISO
iso-windows-unsupported = Use una ISO de Windows 11 sin modificar de una versión compatible con el paquete.
iso-release-unknown-title = Atlas no pudo confirmar esta versión de Windows
iso-release-unconfirmed = Atlas la compara con la lista de versiones públicas de Microsoft. Compruebe su conexión a Internet y vuelva a intentarlo.
# $minimum es la versión de Atlas más antigua que puede crear una ISO, como "0.6.0".
iso-package-old-title = Este paquete de Atlas no puede crear una ISO
iso-package-old = Use Atlas { $minimum } o una versión posterior.
iso-manager-missing-title = Falta el archivo de Atlas Manager
iso-fix-package = Elegir otro paquete
# Un paquete que necesita un Atlas Manager más reciente; Descargar Atlas Manager (manager-download)
# está al lado, y acquire-manager-update-needed indica la versión.
iso-manager-outdated-title = Atlas Manager necesita una actualización
# No se pudieron exportar los controladores de red de este equipo; el botón de al lado crea la ISO sin ellos.
iso-network-not-added = Atlas no pudo agregar a la ISO los controladores de red de este equipo.
iso-network-skip = Crear sin ellos
# Título de la barra que pide permiso de administrador. Su mensaje es iso-admin-reason o, cuando
# Windows rechazó la reapertura (UAC denegado), iso-elevation-declined.
iso-elevation-title = Atlas necesita permiso para crear una ISO
iso-admin-reason = Lo necesita para leer su ISO de Windows y crear la nueva.
iso-elevation-declined = Windows no dio permiso a Atlas, así que aún no puede leer su ISO de Windows.
# Se acabó el espacio libre mientras se creaba la ISO.
iso-failed-space = No hay suficiente espacio libre en la unidad de destino. Libere espacio o guarde la nueva ISO en otra unidad.
# Bajo iso-manager-missing-title.
iso-manager-missing = Descargue AtlasManager.exe en una carpeta local, como Descargas, y ábralo desde allí.
# Home y LTSC son las ediciones que descarta la creación de la ISO; las demás son ejemplos de las que conserva.
iso-failed-edition = Esta ISO no contiene ninguna edición de Windows que cuente con soporte. Windows Home y LTSC no cuentan con soporte. Use una ISO que incluya otra edición, como Pro, Education o Enterprise.
# Abre la carpeta con los registros de un trabajo de ISO o de USB.
iso-diagnostics = Abrir la carpeta de registros
# En las páginas de la ISO y del USB mientras Atlas actualiza Windows, o restaura la configuración de
# Windows Update, desde otra página. Sus controles no están disponibles hasta que termine.
iso-locked = Atlas está ocupado con Windows Update. Podrá continuar aquí cuando termine.
# Nombres de los marcadores que deja Windows cuando pide un reinicio. Completan
# "Su PC necesita reiniciarse para terminar de instalar las actualizaciones (…)"; cortos y en minúsculas.
prepare-reason-servicing = mantenimiento de Windows
prepare-reason-windows-update = Windows Update
prepare-reason-file-renames = archivos pendientes de reemplazar
prepare-reason-update-agent = el servicio de Windows Update
prepare-reason-unknown = motivo no indicado
# Bajo prepare-failed-title, con Reintentar (common-try-again).
prepare-failed-retry = Si volver a intentarlo no sirve, termine las actualizaciones pendientes en Windows Update o Microsoft Store.
# Título de la barra de error de la tarjeta de actualizaciones; la causa es su mensaje.
prepare-failed-title = No se pudieron completar algunas actualizaciones
# Bajo prepare-unconfirmed-title: la actualización terminó sin dejar ningún resultado, por ejemplo
# porque se cerró Atlas mientras se ejecutaba.
prepare-unconfirmed = La actualización se detuvo antes de informar de un resultado.
# Título de la barra sobre prepare-unconfirmed: no se llama error, porque no se informó de ninguno.
prepare-unconfirmed-title = No se pudo confirmar el resultado de la actualización
prepare-affected-app = la aplicación afectada
# Una aplicación de la Store no se pudo actualizar porque estaba abierta. $app es su nombre, como
# NanaZip, o prepare-affected-app.
prepare-close-app = Cierre { $app } y vuelva a intentarlo. Si no encuentra la ventana, use el Administrador de tareas.
prepare-install-busy = Otra instalación o un reinicio pendiente está bloqueando las actualizaciones. Espere a que terminen las demás instalaciones, reinicie su PC si Windows se lo pide y vuelva a intentarlo.
# Las actualizaciones fallaron con 0x80073712 después de que Atlas reparara el almacén de componentes
# (DISM). Botón: prepare-restart-and-retry; la actualización continúa sola tras el reinicio.
prepare-components-damaged-title = Windows no pudo repararse
prepare-components-damaged = Windows informa de daños que impiden instalar las actualizaciones. Un reinicio puede solucionarlo, y Atlas continuará cuando inicie sesión.
prepare-restart-and-retry = Reiniciar y reintentar
# Windows registra daños en su almacén de componentes que no puede reparar, así que Atlas se detiene
# antes de actualizar. El único botón es iso-open.
prepare-components-unrepairable-title = Windows está demasiado dañado para actualizarse
prepare-components-unrepairable = Haga una copia de seguridad de sus archivos y reinstale Windows con una ISO de Atlas.
# Causas que indica el proceso de actualización. Su propio mensaje en inglés se muestra debajo como detalle.
prepare-failed-session-owner = Atlas se está ejecutando con una cuenta distinta de la que tiene la sesión iniciada en Windows. Inicie sesión en Windows con una cuenta de administrador, abra Atlas desde esa cuenta y vuelva a intentarlo.
prepare-failed-store-missing = Microsoft Store no está configurada para su cuenta. Abra Microsoft Store una vez, o reinstálela si falta, y vuelva a intentarlo.
prepare-failed-store-battery = Microsoft Store pausó las actualizaciones para ahorrar batería. Conecte su PC a la corriente y vuelva a intentarlo.
prepare-failed-store-network = Microsoft Store pausó las actualizaciones hasta que su PC tenga una conexión sin uso medido. Conéctese por Wi-Fi o Ethernet sin uso medido y vuelva a intentarlo.
prepare-failed-store-timeout = Las aplicaciones de la Store no han terminado de actualizarse. Termine las descargas pendientes en Microsoft Store y vuelva a intentarlo.
prepare-failed-store-passes = Microsoft Store siguió ofreciendo actualizaciones nuevas. Termine las actualizaciones pendientes en Microsoft Store y vuelva a intentarlo.
prepare-failed-manual-updates = Algunas actualizaciones de Windows deben terminarse desde Windows Update. Abra Windows Update, termínelas y vuelva a intentarlo.
prepare-failed-windows-passes = Windows Update siguió ofreciendo actualizaciones nuevas. Termine las actualizaciones pendientes en Windows Update y vuelva a intentarlo.
prepare-failed-windows-update-unreachable = Windows Update no pudo conectar con los servidores de Microsoft. Compruebe su conexión a Internet y cualquier firewall, proxy o VPN, y vuelva a intentarlo.
# Atlas Manager se ejecuta desde una carpeta que apunta a otro lugar (una unión o un vínculo
# simbólico). "Carpeta vinculada" y "carpeta local", como en usb-iso-location.
prepare-failed-source-linked = Atlas Manager está en una carpeta vinculada. Cierre Atlas, mueva Atlas Manager a una carpeta local de este equipo y ábralo desde allí.
prepare-error-code = Código de error: { $code }
prepare-open-store = Abrir Microsoft Store
prepare-windows-search = Buscando actualizaciones de Windows…
prepare-percent = { $percent } % de esta etapa
prepare-count = Actualizaciones completadas: { $completed } de { $total }
prepare-bytes = Descargados { $downloaded } de aproximadamente { $total } MB
prepare-progress-still = Sin avances durante { $minutes } min. Las actualizaciones grandes pueden tardar, así que mantenga Atlas abierto.
prepare-report-late = Windows lleva un rato sin informar del progreso. Es posible que las actualizaciones sigan en curso, así que mantenga Atlas abierto.
prepare-windows-download = Descargando actualizaciones de Windows…
prepare-windows-install = Instalando actualizaciones de Windows…
# Mientras DISM repara el almacén de componentes de Windows, con prepare-windows-repair-detail bajo la
# barra de progreso. DISM no informa del progreso.
prepare-windows-repairing = Reparando Windows…
prepare-windows-repair-detail = Windows informa de daños que pueden impedir instalar las actualizaciones. Esto puede tardar media hora o más.
prepare-store-search = Comprobando Microsoft Store…
prepare-store-install = Actualizando Microsoft Store y sus apps…
prepare-stop = Detener actualizaciones
prepare-start = Buscar e instalar actualizaciones
# Bajo la comprobación Administrador, mientras el paquete de Atlas aún se descarga o se extrae.
prepare-wait-for-package = Disponible cuando el paquete de Atlas esté listo.
iso-username = Nombre de la cuenta local
# Bajo el nombre de la cuenta local: Windows pide la contraseña al iniciar sesión por primera vez.
iso-account-help = Elegirá una contraseña la primera vez que inicie sesión.
iso-username-placeholder = Su nombre
# Junto a Continuar no disponible mientras el nombre de la cuenta local está vacío.
iso-account-empty = Escriba un nombre de cuenta local para continuar
# Conserve la lista de símbolos tal cual: Windows los rechaza en los nombres de cuenta.
iso-account-invalid = Use hasta 20 caracteres, sin espacios al principio ni al final y sin ninguno de estos: " / \ [ ] : ; | = , + * ? < > @
iso-account-trailing-dot = El nombre no puede terminar en punto.
iso-account-reserved = Windows usa este nombre para una cuenta integrada. Elija otro nombre.
# El archivo de respuesta de la ISO oculta estas pantallas del programa de instalación de Windows.
iso-terms-in-setup = El programa de instalación de Windows le pedirá que acepte los términos de licencia.
prepare-drivers = ¿Cómo desea instalar los controladores?
prepare-drivers-auto = Obtener controladores mediante Windows Update
# La misma respuesta como etiqueta de un botón de radio, donde se hace la elección.
prepare-drivers-auto-recommended = Obtener controladores mediante Windows Update (recomendado)
prepare-drivers-auto-detail = Windows busca los controladores adecuados para su hardware.
prepare-drivers-manual = Instalar los controladores por mi cuenta
prepare-drivers-manual-detail = Windows Update no instalará controladores, así que tendrá que obtenerlos del fabricante de su PC o dispositivo. Los controladores ya instalados se conservan.
# La tarjeta de controladores del paso Configuración: los controladores de red de este equipo en la
# ISO y la elección que aplica Atlas Manager tras iniciar sesión, con la pregunta prepare-drivers.
iso-drivers-card = Controladores
iso-network-drivers = Incluir los controladores de Wi-Fi y Ethernet de este equipo
# La tercera respuesta sobre controladores, y su valor en el paso Creación: Preparación pregunta en el nuevo equipo.
iso-drivers-defer = Elegir después de iniciar sesión
prepare-network-unmetered = Las actualizaciones necesitan una conexión a Internet sin uso medido. Conéctese por Wi-Fi o Ethernet y vuelva a intentarlo.
# Hay conexión, pero Windows no encontró acceso a Internet (un portal cautivo o un filtrado de DNS o del firewall).
prepare-network-limited = Windows indica que esta red no tiene acceso a Internet. Inicie sesión en la red si se lo solicita, o revise su enrutador y cualquier filtrado de DNS o del firewall, y vuelva a intentarlo.
# "Conexión de uso medido" es el nombre del interruptor en la configuración de red de Windows.
prepare-network-metered = Esta conexión es de uso medido o tiene un límite de datos. Conéctese a una red sin uso medido, o desactive Conexión de uso medido en la configuración de red, y vuelva a intentarlo.
prepare-network-settings = Abrir la configuración de red
iso-stage-network-drivers = Preparando los controladores de red
# Bajo iso-complete cuando se pidieron los controladores de red de este equipo, pero los
# adaptadores usan controladores que vienen con Windows, así que no se agregó ninguno.
iso-network-inbox = Los adaptadores de red de este equipo usan controladores que vienen con Windows, así que no hace falta agregarlos a la ISO.
desktop-setup-description = Complete la configuración del equipo. Sus preferencias de Atlas están guardadas; puede volver a Windows si lo necesita.
desktop-setup-exit = Continuar en Windows

# Unidad USB de instalación de Windows
usb-title = Crear una unidad USB
usb-existing = Crear una unidad USB a partir de una ISO existente
# Título de la tarjeta de la unidad, y el nombre de una unidad que no indica ninguno.
usb-drive = Unidad USB
# Título de la tarjeta con la ISO a partir de la que se crea la unidad USB.
usb-iso-title = ISO de Windows
# No se indicó ninguna ISO y no hay ninguna en Descargas cuyo nombre empiece por "Atlas".
usb-iso-missing = No hay ninguna ISO de Atlas en su carpeta Descargas.
usb-iso-checking = Comprobando la ISO…
# Lo que encontró la comprobación de la ISO. Se hace antes de borrar nada, así que ninguno menciona la unidad.
usb-iso-not-usable = Atlas no puede crear una unidad USB a partir de esta ISO. Use una ISO creada por Atlas o una ISO de Microsoft con una versión de Windows 11 que Atlas admita.
# Una carpeta vinculada apunta a otro lugar (una unión o un vínculo simbólico).
usb-iso-location = La ISO o Atlas Manager está en una ubicación de red o en una carpeta vinculada. Mueva el archivo a una carpeta de este equipo, como Descargas.
# Dividir una imagen grande de Windows requiere espacio en la unidad de Windows. Atlas vuelve a
# comprobarlo cada 30 segundos.
usb-working-space = No hay suficiente espacio libre en la unidad de Windows para preparar esta ISO. Libere espacio y Atlas volverá a comprobarlo por sí solo.
# No se pudo leer la ISO por otro motivo, como un archivo dañado.
usb-iso-unreadable = Atlas no pudo leer esta ISO. Vuelva a intentarlo o use otra ISO.
# Abre la página Almacenamiento de Configuración de Windows, donde se puede liberar espacio.
usb-open-storage = Abrir Almacenamiento
usb-looking = Buscando unidades USB…
# $size es un número entero de gigabytes, como se venden las unidades.
usb-connect = Conecte una unidad USB de { $size } GB o más.
# Bajo una unidad que no se puede usar, tras su tamaño y sus letras: por qué. $size es un número
# entero de gigabytes, como en usb-connect.
usb-drive-too-small-needs = Demasiado pequeña. Necesita { $size } GB o más.
usb-drive-too-small-iso = Demasiado pequeña para esta ISO
usb-drive-has-iso = Su ISO está en esta unidad
usb-drive-has-app = Atlas Manager se está ejecutando desde esta unidad
# El tamaño comercial de una unidad, que no es el que muestra Windows. $size es un número entero de
# gigabytes o un número de terabytes (texto).
usb-drive-size = { $size } GB
usb-drive-size-tb = { $size } TB
# Une el tamaño y las letras de una unidad, y la arquitectura y el tamaño de una ISO bajo su nombre.
usb-detail-separator = { " · " }
usb-create = Crear unidad USB
# Junto a Crear unidad USB no disponible cuando hay varias unidades y no se ha elegido ninguna.
usb-hint-pick = Elija antes una unidad USB
# La pregunta antes de borrar. $drive es el nombre de la unidad; $size es usb-drive-size o
# usb-drive-size-tb; $letters son sus letras de unidad, como "F:" o "F:, G:". Una unidad sin letra
# se pregunta con usb-confirm-title.
usb-confirm-title-letters = ¿Borrar { $drive } ({ $size }, { $letters })?
usb-confirm-title = ¿Borrar { $drive } ({ $size })?
# La misma pregunta para una unidad que no indica ningún nombre.
usb-confirm-title-unnamed-letters = ¿Borrar la unidad USB ({ $size }, { $letters })?
usb-confirm-title-unnamed = ¿Borrar la unidad USB ({ $size })?
usb-confirm-message = Se eliminará todo lo que contiene. Su ISO se conserva.
usb-confirm-erase = Borrar y crear
usb-progress-title = Creando la unidad USB…
# $percent es un número entero.
usb-percent = { $percent } %
# Las etapas de la creación de la unidad USB, como una lista bajo usb-progress-title.
usb-stage-prepare-files = Preparando archivos
usb-stage-formatting = Formateando
usb-stage-copying = Copiando archivos
usb-stage-checking = Comprobando la unidad
usb-stage-ejecting = Expulsando
usb-keep-open = Mantenga Atlas abierto y la unidad conectada.
usb-scan-failed-title = No se pudo obtener la lista de unidades USB
usb-scan-failed-retry = Atlas no pudo leer las unidades conectadas a este equipo. Vuelva a intentarlo.
# El título de la barra de error de una unidad USB, y el encabezado de la página de la unidad terminada.
usb-failed-title = No se pudo crear la unidad USB
usb-complete-title = Su unidad USB está lista
# F12, F11 y Esc son nombres de teclas.
usb-ready = Desconéctela, haga una copia de seguridad del equipo que va a reinstalar y arranque ese equipo desde la unidad USB. Su menú de arranque suele abrirse con F12, F11 o Esc.
# Cuando el borrado puede haber empezado.
usb-failed-partial = La unidad se escribió solo en parte. Compruebe que esté conectada y vuelva a intentarlo.
# Antes de modificar nada en la unidad.
usb-failed-before-erase = Atlas se detuvo antes de modificar la unidad. Vuelva a intentarlo.
# Antes de borrar, la unidad ya no coincidía con la lista: se quitó, se volvió a conectar o se
# sustituyó. Atlas vuelve a leer la lista y la vuelve a elegir si está.
usb-drive-changed-title = La unidad USB cambió
usb-drive-changed = Se quitó o se volvió a conectar antes de que Atlas la borrara, así que su contenido no cambió.
usb-drive-cancelled-title = Creación de la unidad USB cancelada
usb-cancelled-partial = La unidad está incompleta. Vuelva a crearla antes de usarla.
usb-cancelled-unchanged = Su unidad USB no se ha modificado.
usb-eject-failed-title = No se pudo expulsar la unidad USB
usb-eject-failed-ready = Está lista para usarse. Cierre los archivos o ventanas que la estén usando y vuelva a intentarlo.
# Título de la barra con Reabrir como administrador (common-restart-as-administrator). Su mensaje es
# usb-admin-reason o, cuando Windows rechazó la reapertura (UAC denegado), usb-elevation-declined.
usb-elevation-title = Atlas necesita permiso para crear una unidad USB
usb-admin-reason = Atlas necesita permiso de administrador para borrar la unidad y escribir en ella.
usb-elevation-declined = Windows no dio permiso a Atlas, así que aún no puede escribir en la unidad USB.
# Home, LTSC y Server son las ediciones que la comprobación rechaza; las demás son ejemplos de ediciones
# que acepta. Escriba los nombres de las ediciones como los muestra Windows.
detail-edition-unsupported = Las ediciones Home, LTSC y Server de Windows 11 no cuentan con soporte. Use otra edición, como Pro, Education o Enterprise. Si Windows no pudo identificar su edición, resuelva el problema antes de continuar.
install-source-title = Instalación no disponible
install-source-unsupported = Atlas { $source } no se puede actualizar directamente a { $target }. Para usar esta versión, haga una copia de seguridad de sus archivos y reinstale Windows.
# Antes de elegir un paquete, así que aún no se sabe qué versión se ofrece.
install-source-unsupported-any = Atlas { $source } no se puede actualizar directamente. Para usar una versión más reciente, haga una copia de seguridad de sus archivos y reinstale Windows.
# $folder es una ruta de carpeta (texto).
install-source-resume-package = Una instalación de Atlas { $target } no terminó y solo el paquete de Atlas { $target } puede terminarla. Abra ese paquete de Atlas (.atlaspkg). Si Atlas lo descargó, está en { $folder }.
# Versión de prueba: solo se puede instalar el paquete de Atlas incluido.
install-source-resume-bundled = Una instalación de Atlas { $target } no terminó. Esta versión de prueba solo puede instalar su paquete de Atlas incluido, así que termine esa instalación con el paquete de Atlas { $target } en una versión oficial de Atlas Manager.
# Se ofrecen Enviar un informe y Exportar diagnósticos.
install-source-unconfirmed = Atlas no pudo confirmar qué hay ya instalado en este equipo, así que por ahora no instalará nada.
# Bajo las ediciones en el paso Creación, cuando el programa de instalación pregunta cuál instalar.
iso-edition-selection = En el programa de instalación de Windows, elija una edición para la que tenga licencia.
detail-windows-preview = Las compilaciones Insider no cuentan con soporte. Use una versión pública de Windows 11.
detail-windows-release-unknown = Atlas no pudo confirmar que esta compilación de Windows sea una versión pública. Conéctese a Internet y vuelva a comprobarlo.
# $build is this PC's Windows build and update number, such as 26300.9807 (text).
detail-windows-release-not-listed = La compilación { $build } no figura en la lista de versiones públicas de Windows 11 de Microsoft, así que Atlas aún no puede instalarse en ella. Las compilaciones Release Preview y otras compilaciones preliminares no cuentan con soporte. Vuelva a comprobarlo cuando Microsoft incluya esta compilación.

prepare-continue = Continuar actualizaciones
prepare-saving-restart = Guardando sus preferencias y configurando Atlas para que se abra tras reiniciar Windows…
prepare-restart-save-failed = No se pudieron guardar sus preferencias. Vuelva a intentarlo antes de reiniciar.
prepare-restart-registration-failed = Sus preferencias están guardadas, pero Atlas no pudo configurarse para volver a abrirse después del reinicio. Vuelva a intentarlo, o reinicie su PC por su cuenta y abra Atlas cuando inicie sesión.
# La misma causa que prepare-failed-source-linked, al preparar el reinicio.
prepare-restart-source-linked = Sus preferencias están guardadas, pero mientras Atlas Manager esté en una carpeta vinculada, Atlas no puede configurarse para volver a abrirse después del reinicio. Cierre Atlas y mueva Atlas Manager a una carpeta local de este equipo. Después, ábralo desde allí, o reinicie su PC por su cuenta y ábralo desde allí cuando inicie sesión.
prepare-restart-failed = Atlas no pudo reiniciar su PC. Vuelva a intentarlo o reinícielo desde el menú Inicio. Sus preferencias están guardadas y Atlas se volverá a abrir cuando inicie sesión.
diagnostics-export = Exportar diagnósticos
# Junto a un indicador de actividad mientras se exporta, y en el pie de Enviar un informe mientras
# se recopilan sus diagnósticos.
diagnostics-exporting = Recopilando diagnósticos…
# Nombre accesible de la fila de vínculos de ayuda: report-title, diagnostics-export e iso-diagnostics.
diagnostics-help-a11y = Obtener ayuda
# Título de la barra de resultado tras exportar; su botón es iso-open-folder.
diagnostics-saved = Diagnósticos guardados
# Bajo diagnostics-saved. $file es el nombre del ZIP, como Atlas-diagnostics-2026-11-24-0612.zip, y
# $folder el nombre de su carpeta, "Diagnostics" (ambos texto, no se traducen).
diagnostics-saved-in-folder = Se guardó como { $file } en la carpeta { $folder } de Atlas.
# Bajo diagnostics-saved. Dice exactamente lo que quita la exportación, así que conserve cada elemento.
diagnostics-saved-privacy = Atlas quitó del ZIP su nombre de usuario, el nombre de su PC, las direcciones de correo electrónico y las contraseñas o claves conocidas.
# La barra cuando falló una exportación. Su botón es common-try-again, y el error está tras Mostrar detalles.
diagnostics-save-failed = No se pudo guardar el ZIP de diagnóstico

## Tester builds (embedded-package feature)

# Una barra arriba del contenido en una versión candidata.
rc-banner = Versión de prueba de Atlas { $release }. Esta aplicación solo instala el paquete de Atlas incluido.
home-status-bundled = Versión de prueba { $release }
package-bundled = Atlas { $version }, incluido en esta versión de prueba, está listo para instalar.
rc-about-release = Versión de prueba
rc-about-commit = Commit de origen
rc-about-package = Paquete de Atlas incluido (SHA-256)
iso-package-bundled = El paquete de Atlas incluido en esta versión de prueba

check-user-account = Cuenta de usuario
detail-user-account-ok = El Control de cuentas de usuario está activado y su cuenta está lista para la instalación.
detail-user-account-not-ready = Active el Control de cuentas de usuario (UAC), reinicie su PC y vuelva a intentarlo. Si usa la cuenta Administrador integrada, inicie sesión con otra cuenta de administrador.
detail-user-account-work-or-school = Atlas no se puede instalar desde una cuenta profesional o educativa (Microsoft Entra ID). Inicie sesión con una cuenta local o una cuenta de Microsoft y vuelva a intentarlo.
detail-user-account-check-failed = Atlas no pudo comprobar su cuenta de usuario. Reinicie su PC, vuelva a abrir Atlas y compruébelo de nuevo. Windows informó: { $error }

footer-prepare-required = Termine de actualizar Windows y las aplicaciones de la Store para continuar
# "Etapa" como en prepare-close-stops-after-stage.
footer-prepare-stopping-stage = Deteniendo las actualizaciones tras la etapa actual…
resume-choices-title = Continuando la instalación anterior
# La barra de Sus preferencias, sobre las preferencias de una instalación sin terminar, que muestra
# y no se pueden cambiar.
resume-choices-held = Atlas usa las preferencias que eligió la última vez para terminar esa instalación, así que no se pueden cambiar hasta que termine.

## Informes voluntarios
report-title = Enviar un informe
report-received = Informe recibido
# Bajo la referencia del informe, que tiene una línea propia con un botón Copiar.
report-reference = Guarde esta referencia por si se pone en contacto con el equipo de Atlas sobre este informe. Si dejó datos de contacto, el equipo puede usarlos para responderle, pero no se garantiza una respuesta.
# Nombre accesible del botón Copiar junto a la referencia del informe.
report-copy-reference = Copiar la referencia del informe
report-another = Enviar otro informe
# Etiqueta de la elección entre los dos tipos de informe.
report-kind = ¿Qué desea enviar?
report-kind-issue = Un problema
report-kind-suggestion = Una sugerencia
report-message = Su mensaje
# Lo que muestra el cuadro de mensaje mientras está vacío, para cada tipo de informe.
report-message-placeholder-issue = ¿Qué ocurrió y qué estaba haciendo?
report-message-placeholder-suggestion = ¿Qué le gustaría cambiar?
# Bajo el cuadro de mensaje, que también lo lee en voz alta.
report-message-help = No incluya contraseñas.
# Bajo el cuadro de mensaje o de contacto cuando se acerca a la longitud máxima que acepta el
# servicio de informes. $count y $max son números.
report-character-count = { $count } de { $max } caracteres
report-contact = Datos de contacto (opcional)
report-contact-placeholder = Correo electrónico o usuario de Discord
report-attach = Incluir diagnósticos
# Bajo Incluir diagnósticos. Parte del aviso de privacidad que acepta el usuario: dice exactamente
# lo que Atlas quita y conserva, así que conserve cada elemento.
report-attach-description = Registros y detalles del sistema que ayudan a encontrar la causa. Atlas elimina su nombre de usuario, el nombre de su PC, las direcciones de correo electrónico y las contraseñas o claves conocidas. Se conservan los detalles de los errores, los modelos de hardware y los nombres de las aplicaciones. Puede revisar el ZIP antes de enviarlo.
report-review = Revisar ZIP
# Una barra cuando no se pudieron preparar los diagnósticos. Su botón es common-try-again, y el error
# está tras Mostrar detalles.
report-prepare-failed-title = No se pudieron preparar los diagnósticos
report-prepare-failed-advice = Vuelva a intentarlo o envíe el informe sin diagnósticos.
# El aviso de privacidad que acepta el usuario, con report-attach-description. Cambiarlo requiere un
# nuevo PRIVACY_VERSION en la aplicación, el servicio de informes y el sitio web, publicados a la vez.
report-privacy = Su informe se envía de forma privada al equipo de Atlas en reports.atlasos.net. Su mensaje y sus datos de contacto se envían tal como los escribió. El equipo puede usar servicios de IA de otras empresas para ayudar en la investigación. Estos servicios reciben su mensaje y sus diagnósticos, pero no sus datos de contacto. Los informes se eliminan pasados 90 días, y los registros de seguridad del servidor pueden guardar su dirección IP.
report-website = Privacidad y sitio de informes
report-consent = Acepto enviar al equipo de Atlas este informe y los diagnósticos incluidos
# Bajo "El informe no se envió". El botón del pie es common-try-again, salvo tras
# report-not-sent-outdated, donde es report-failed-website y el botón de la barra es manager-download.
report-not-sent-retry = Compruebe su conexión a Internet y vuelva a intentarlo. También puede enviarlo desde el sitio web de informes.
report-not-sent-busy = El servicio de informes está ocupado. Espere unos minutos y vuelva a intentarlo.
report-not-sent-outdated = Esta versión de Atlas Manager no puede enviar informes. Copie su mensaje en el sitio web de informes, junto con el ZIP si incluyó diagnósticos.
report-not-sent-diagnostics = No se pudieron enviar los diagnósticos. Vuelva a intentarlo o envíe el informe sin ellos.
# El botón del pie cuando esta versión no puede enviar.
report-failed-website = Abrir el sitio web de informes
# Junto a un indicador de actividad en el pie mientras se envía el informe.
report-sending = Enviando…
report-send = Enviar informe

# Bajo el cuadro de mensaje cuando Enviar informe lo encuentra demasiado corto o largo. $min y $max
# son números: las longitudes de mensaje que acepta el servicio de informes.
report-validation-message = Escriba entre { $min } y { $max } caracteres.

# Bajo el cuadro de contacto. $max es un número: la longitud máxima de los datos de contacto que
# acepta el servicio de informes.
report-validation-contact = Limite los datos de contacto a { $max } caracteres.

# Bajo la casilla de aceptación cuando se elige Enviar informe sin marcarla.
report-validation-consent = Confirme que acepta enviar este informe.

report-failed-title = El informe no se envió

## Actualización de la versión de Windows
# Atlas pasa Windows a una versión más reciente antes de instalar, mediante Windows Update.
# $release es la versión de destino (26H2) y $current la que tiene el equipo (24H2); se escribe
# "Windows 11, versión" delante, como hace Microsoft. $version es una versión de Atlas.

# Inicio, bajo el botón de actualización, cuando la actualización también cambia Windows: una tarjeta
# con las dos partes de la actualización. home-plan-name es el nombre accesible de su lista.
home-plan-files = Sus archivos y aplicaciones se conservan.
home-plan-name = Esta actualización tiene dos partes
home-plan-windows-title = Windows 11, versión { $release }
home-plan-windows-step = Atlas la instala desde Windows Update y después su PC se reinicia.
# El mismo paso cuando el cambio de versión es opcional.
home-plan-windows-step-ask = Opcional. Atlas le pregunta antes; después la instala desde Windows Update y su PC se reinicia.
# En lugar de la línea del paso, cuando Windows ya ha cambiado de versión.
home-plan-step-installed = Instalada.
home-plan-atlas-title = Atlas { $version }
home-plan-atlas-step = Atlas se actualiza y conserva sus preferencias; después, su PC se reinicia.
# $date y $until son fechas.
home-end-of-updates-title = Windows 11, versión { $current }, deja de recibir actualizaciones de seguridad el { $date }
home-end-of-updates-past-title = Windows 11, versión { $current }, ya no recibe actualizaciones de seguridad
home-end-of-updates-message = Al actualizar a Atlas { $version }, este equipo también pasa a Windows 11, versión { $release }, que recibe actualizaciones de seguridad hasta el { $until }.
# En lugar de home-end-of-updates-message cuando la tarjeta con las dos partes de la actualización,
# que ya nombra el cambio, está bajo la barra.
home-end-of-support-plan = Windows 11, versión { $release }, recibe actualizaciones de seguridad hasta el { $until }.

# Inicio, cuando este Windows no admite la versión de Atlas. $product es el nombre que Windows da a
# la edición, como Windows 11 Home.
install-windows-edition-only = Atlas { $version } funciona con Windows 11 Pro, Enterprise y Education, así que no se puede instalar en { $product }.
# Lo mismo, en una versión cuyas actualizaciones de seguridad terminan, con Abrir Windows Update. $date es una fecha.
install-windows-edition-until = Atlas { $version } funciona con Windows 11 Pro, Enterprise y Education, así que no se puede instalar en { $product }. Windows 11, versión { $current }, recibe actualizaciones de seguridad hasta el { $date }, y Windows Update puede pasar este equipo a una versión más reciente.
# Lo mismo cuando ya pasó esa fecha.
install-windows-edition-ended-update = Atlas { $version } funciona con Windows 11 Pro, Enterprise y Education, así que no se puede instalar en { $product }. La versión { $current } ya no recibe actualizaciones de seguridad, así que actualice Windows aunque no use Atlas.
# $releases enumera las versiones compatibles, como "25H2 o 26H2".
install-windows-reinstall = Atlas { $version } necesita Windows 11, versión { $releases }, y Windows Update no puede llevar este equipo a esa versión. Haga una copia de seguridad de sus archivos y reinstale Windows con una ISO de Atlas.
# Lo mismo en Inicio, donde la tarjeta que crea una ISO de Atlas va primero y explica cómo reinstalar.
home-windows-no-path = Atlas { $version } necesita Windows 11, versión { $releases }, y Windows Update no puede llevar este equipo a esa versión.

# Inicio, cuando Atlas cambió la configuración de Windows Update para una actualización y aún no la ha
# restaurado. El botón de la barra es home-put-back; Continuar la actualización (home-continue-update)
# está junto a la versión, más arriba.
home-update-access-title = La configuración de Windows Update sigue cambiada para la actualización de Atlas
# Bajo home-update-access-title mientras está en curso una actualización que cambia Windows.
home-update-access-put-back-later = Atlas restaurará esta configuración cuando termine la actualización.
# Cuando la última comprobación aún no encontró la oferta.
home-update-access-waiting = Atlas activó Windows Update para pasar este equipo a Windows 11, versión { $release }, y Windows Update aún no la ha ofrecido.
home-update-access-updating = Atlas activó Windows Update para instalar actualizaciones y aún no ha terminado.
# En lugar de home-update-access-title cuando Atlas no puede leer los datos que guardó sobre la
# configuración que cambió.
home-update-access-unreadable-title = No se pudieron leer los datos de Windows Update que guardó Atlas
# Con Enviar un informe y Exportar diagnósticos debajo; el error está tras Mostrar detalles.
home-update-access-unreadable-problem = Atlas no puede leer los datos que guardó sobre la configuración de Windows Update que cambió, así que no cambiará ni restaurará nada.
# Bajo la barra cuando no se pudo restaurar la configuración por otro motivo. Restaurar la
# configuración lo vuelve a intentar; el error está tras Mostrar detalles.
home-put-back-failed = Atlas no pudo restaurar la configuración.
# Por qué aún no se puede restaurar la configuración de Windows Update que cambió Atlas: una
# instalación o actualización de Atlas sin terminar la restaura en su última etapa. En Inicio, donde
# Restaurar la configuración está oculto mientras tanto, y en la pregunta al cerrar cuando no se pudo
# restaurar. También bajo la elección de la versión de Windows en Preparación, donde conservar esta
# versión espera por el mismo motivo. "Etapa" es una etapa de la instalación, no uno de los cuatro pasos.
update-access-finish-install = Termine primero de instalar Atlas. La última etapa de la instalación restaura la configuración de Windows Update que cambió Atlas.
home-continue-update = Continuar la actualización
home-put-back = Restaurar la configuración
home-putting-back = Restaurando la configuración…

# Preparación: la tarjeta del cambio a una versión más reciente de Windows, la primera de la página.
# Su título es windows-card-title, y la línea de debajo dice cómo va el cambio.
windows-card-title = Windows 11, versión { $release }
# Bajo el título de un cambio que necesita el paquete de Atlas, antes de dar la aprobación.
windows-required = Atlas { $version } no admite la versión { $current }, así que Atlas actualiza Windows primero.
# Bajo el título cuando el cambio es opcional.
windows-optional = Atlas funciona con ambas versiones.
# El nombre accesible de la elección; las dos respuestas lo dicen.
windows-card-question = ¿Qué versión de Windows debe usar este equipo?
windows-choice-move-recommended = Actualizar a Windows 11, versión { $release } (recomendado)
# $date es la fecha en que la nueva versión deja de recibir actualizaciones de seguridad.
windows-choice-move-support = Actualizaciones de seguridad hasta el { $date }.
windows-choice-keep = Conservar Windows 11, versión { $current }
windows-choice-keep-later = Se queda en la versión { $current }. Puede actualizar más adelante desde Atlas Manager.
windows-card-facts = Qué cambia
windows-fact-files = Sus archivos y aplicaciones se conservan. Atlas restaura lo que deshaga la actualización.
windows-fact-time = Normalmente, unos minutos, hasta 2 horas, y después un reinicio.
# Tras Mostrar detalles, en un equipo cuya versión aún los tiene.
windows-fact-removes = Quita Windows PowerShell 2.0 y WMIC.
# Abre la documentación de Atlas sobre cómo deshacer el cambio, cuando es opcional.
windows-undo-link = Cómo deshacer la actualización
# Antes de windows-accept: aceptar los términos e iniciar el cambio son una sola elección.
windows-terms-line = Al actualizar, acepta los Términos de licencia del software de Microsoft.
windows-terms-link = Leer los términos de licencia
windows-accept = Aceptar y actualizar
# Una vez aceptados los términos, antes de que el cambio empiece por sí solo.
windows-starting = Iniciando…
windows-starts-after-checks = Empieza cuando se superen las comprobaciones.
windows-starts-after-package = Empieza cuando Atlas { $version } esté listo.
# Tras el cambio, cuando Windows se reinstaló en lugar de activar la nueva versión.
windows-rebuilt = La versión { $release } deshizo algunos cambios de Atlas. Atlas { $version } los vuelve a aplicar con sus preferencias anteriores.
# Se pregunta antes de conservar esta versión cuando el cambio ya ha empezado; el mensaje es
# stop-update-before y los botones son common-cancel y prepare-keep-version.
windows-keep-title = ¿Conservar Windows 11, versión { $current }?


# La barra que nombra cada opción de Windows Update que Atlas activa para la actualización.
access-notice-title = Atlas activa Windows Update temporalmente
access-off = Windows Update está desactivado en este equipo. Atlas lo vuelve a activar mientras actualiza Windows.
access-paused = Las actualizaciones de Windows están en pausa en este equipo. Atlas las reanuda mientras actualiza Windows.
access-delayed = Las actualizaciones mensuales están aplazadas en este equipo. Atlas quita el aplazamiento mientras actualiza Windows.
# Tras las líneas anteriores.
access-back = Cuando Atlas { $version } esté instalado, esta configuración volverá a quedar como estaba.
access-back-stop = Si la detiene antes, Atlas restaurará esta configuración.

prepare-reason-feature-update = la nueva versión de Windows
prepare-reason-feature-commit = finalización de la nueva versión de Windows
prepare-reason-apprepository = la eliminación de registros de aplicaciones sobrantes
# Mientras se espera a que Windows Update ofrezca la nueva versión: la etiqueta y la línea de estado
# de la barra de progreso, la línea de debajo y cuánto lleva esperando Atlas, en minutos enteros.
windows-waiting = Esperando a que Windows Update ofrezca Windows 11, versión { $release }…
windows-waiting-detail = Suele tardar unos minutos, hasta 2 horas. Atlas continuará por sí solo; puede seguir usando su PC.
windows-waited =
    { $minutes ->
        [one] Esperando desde hace { $minutes } minuto.
       *[other] Esperando desde hace { $minutes } minutos.
    }
# Tras 2 horas de comprobaciones sin oferta. Botones: common-try-again e iso-open.
windows-wait-ended-title = Windows Update no ofreció la versión { $release } en 2 horas
windows-wait-ended = Atlas restauró su configuración. Vuelva a intentarlo más tarde o reinstale Windows con una ISO de Atlas.
# En lugar del mensaje anterior cuando no se pudo restaurar la configuración. Botón: home-put-back;
# el error está tras common-show-details.
windows-wait-put-back-failed = Atlas no pudo restaurar su configuración de Windows Update.
# Windows no pudo dejar lista la nueva versión para terminarla al reiniciar, así que el PC no se
# reinició. Reintentar (common-try-again) vuelve a reiniciar.
windows-commit-failed-title = Windows no pudo preparar el reinicio
windows-commit-failed = Su PC no se reinició. Vuelva a intentarlo.

# Resultados del cambio de versión de Windows, cada uno con un título y qué hacer a continuación. Una
# causa que solo puede revisar el equipo de Atlas tiene report-title como botón; una que se resuelve
# con una ISO, iso-open.
windows-outcome-not-offered-title = Windows Update aún no ha ofrecido la versión { $release }
windows-outcome-not-offered = Puede tardar hasta 2 horas. Su PC sigue teniendo la versión { $current }.
windows-outcome-hardware-title = Este equipo no cumple los requisitos de Windows 11
# $missing enumera el hardware que le falta a este equipo, a partir de los dos mensajes siguientes.
windows-outcome-hardware = No tiene { $missing }, así que Windows Update no ofrecerá la versión { $release }. Haga una copia de seguridad de sus archivos y reinstale Windows con una ISO de Atlas.
hardware-tpm = TPM 2.0
hardware-uefi = firmware UEFI
windows-outcome-hidden-title = La versión { $release } está oculta en Windows Update
windows-outcome-hidden = Muéstrela de nuevo con la herramienta que usó para ocultarla y vuelva a intentarlo.
windows-outcome-disk-space-title = No hay suficiente espacio libre
# $needed y $free son gigabytes enteros; $drive es una unidad, como C:. El botón es check-fix-storage;
# Atlas vuelve a leer el espacio libre por sí solo.
windows-outcome-disk-space = Windows necesita { $needed } GB libres en { $drive } y solo hay { $free } GB. Atlas continuará por sí solo cuando haya suficiente.
windows-outcome-managed-title = Este equipo recibe las actualizaciones de su organización
windows-outcome-managed = Su servidor de actualizaciones no ofrece la versión { $release }, así que Atlas no cambió nada. Consulte con su organización o reinstale Windows con una ISO de Atlas.
windows-outcome-policy-title = Algo revierte los cambios de Windows Update
# $setting es el nombre técnico de un valor de directiva de Windows Update, como NoAutoUpdate,
# que se muestra tal cual.
windows-outcome-policy = { $setting } vuelve a su valor anterior después de que Atlas lo cambie, así que Atlas no puede actualizar Windows. Si una organización administra este equipo, consulte con ella.
# $service es un nombre service-*, tras una frase fija para que no tenga que concordar. Los botones
# son common-try-again y prepare-open-services.
windows-outcome-service-off-title = Servicio desactivado: { $service }
windows-outcome-blocked-service = Windows Update lo necesita. En Servicios, cambie su tipo de inicio a Manual y vuelva a intentarlo.
windows-outcome-blocked-title = Algo mantiene desactivado Windows Update
windows-outcome-blocked = Una opción que Atlas no cambió, { $setting }, impide que se ejecute. Cámbiela y vuelva a intentarlo.
windows-outcome-rollback-title = Windows no pudo terminar de instalar la versión { $release }
windows-outcome-rolled-back = Volvió a la versión { $current }. Sus archivos y aplicaciones están bien.
windows-outcome-components-lost-title = Algunos cambios de Atlas ya no están
windows-outcome-components-lost = Atlas no puede saber por qué, así que se detuvo antes de instalar Atlas { $version }.
windows-outcome-build-title = Windows cambió de versión durante la actualización
windows-outcome-build = Restaure la configuración que cambió Atlas y vuelva a empezar desde la página de inicio.
windows-outcome-journal-title = Atlas no puede leer sus datos de esta actualización
windows-outcome-journal = No cambiará ni restaurará nada hasta que el equipo de Atlas lo revise.
windows-outcome-pin-title = No se puede guardar una directiva de Windows Update
# $setting es el nombre de un valor de directiva de Windows Update, como TargetReleaseVersionInfo.
windows-outcome-pin = { $setting } tiene un valor que Atlas no podría restaurar después, así que Atlas no cambió nada.
windows-outcome-terms-title = No se aceptaron los términos de licencia
windows-outcome-terms = Windows Update los necesita para instalar la versión { $release }.
windows-outcome-failed-title = Windows no pudo instalar la versión { $release }
windows-outcome-failed = Su PC sigue teniendo la versión { $current }.
# Servicios de Windows que necesita el cambio, como los muestra Servicios.
service-bits = Servicio de transferencia inteligente en segundo plano (BITS)
service-cryptsvc = Servicios de cifrado
service-trusted-installer = Instalador de módulos de Windows
prepare-open-services = Abrir Servicios
# Confirma conservar esta versión en la pregunta windows-keep-title.
prepare-keep-version = Conservar la versión { $current }

# Pregunta antes de abandonar la actualización con la configuración de Windows Update cambiada.
stop-update-title = ¿Dejar de actualizar a Atlas { $version }?
# stop-update-title en una primera instalación o una reinstalación, que hasta ahora solo ha actualizado Windows.
stop-update-title-windows = ¿Dejar de actualizar Windows?
stop-update-before = Atlas restaurará la configuración de Windows Update que cambió. Las actualizaciones que Windows ya instaló seguirán instaladas, y su PC conservará Windows 11, versión { $current }.
stop-update-after = Su PC conservará Windows 11, versión { $release }. Atlas restaurará la configuración de Windows Update que cambió.
stop-update-access = Atlas restaurará la configuración de Windows Update que cambió. Las actualizaciones que Windows ya instaló seguirán instaladas.
stop-update-keep = Seguir actualizando
# Cuadro de diálogo que aparece al cerrar la ventana mientras Windows Update está activado para una
# actualización; sus botones son window-close-keep y window-close-put-back.
window-close-update-access-title = ¿Cerrar Atlas?
window-close-update-access-message = Antes de cerrarse, Atlas restaurará la configuración de Windows Update que cambió. Puede volver a iniciar la actualización desde la página de inicio.
window-close-put-back = Restaurar y cerrar
# Cuando no se pudo restaurar la configuración antes de cerrar. Primero se muestra el motivo y
# después este mensaje; los botones son window-close-keep y window-close-close.
window-close-put-back-failed-title = ¿Cerrar sin restaurar la configuración?
window-close-put-back-failed-message = Si cierra Atlas ahora, la configuración de Windows Update se quedará como Atlas la cambió. Cuando vuelva a abrir Atlas, la página de inicio le ofrecerá restaurarla.

# Comprobar su PC: compatibilidad con Windows en una versión desde la que Atlas actualiza.
# La tarjeta del cambio explica cómo se hace.
detail-build-needs-release = Esta versión de Atlas necesita Windows 11, versión { $release }, y este equipo tiene la versión { $current }.

# Primeras líneas de un informe sobre una actualización de Windows que no terminó; a continuación
# siguen los detalles técnicos en inglés.
report-transition-intro = La actualización de Windows para Atlas no terminó. Detalles para el equipo de Atlas:

# Cuando Windows se reinstaló al pasar a una versión más reciente, en lugar de activar la nueva
# versión sin reinstalarse. Atlas vuelve a aplicar entonces todos sus cambios.
history-mode-rebase = reinstalación tras una actualización de Windows
# Sus preferencias después de que Windows se reinstalara durante el cambio, que restauró las
# preferencias del Atlas que tenía.
rebase-choices-title = Sus preferencias de Atlas { $previous }
rebase-choices-kept = Atlas restaura las preferencias que eligió para Atlas { $previous }; puede cambiarlas más adelante reinstalando Atlas.
# Sobre las preguntas para las que el registro del cambio no tenía respuesta, que son las únicas que hace Sus preferencias.
rebase-choices-asked = Atlas restaura todas las demás preferencias que eligió para Atlas { $previous }.
# Pregunta antes de cualquier reinicio que haga Atlas mientras otras personas tienen la sesión
# iniciada en el equipo. Botones: restart-others-keep (predeterminado) y restart-others-restart.
restart-other-question = ¿Reiniciar mientras otra persona tiene la sesión iniciada?
restart-others-question = ¿Reiniciar mientras otras personas tienen la sesión iniciada?
# $names enumera sus nombres de cuenta, como "Alex y Sam"; $count es cuántos son.
restart-others-signed-in =
    { $count ->
        [one] { $names } también tiene la sesión iniciada. Al reiniciar, se cerrarán las aplicaciones de esa sesión y se perderá el trabajo no guardado.
       *[other] { $names } también tienen la sesión iniciada. Al reiniciar, se cerrarán las aplicaciones de esas sesiones y se perderá el trabajo no guardado.
    }
restart-others-keep = No reiniciar
restart-others-restart = Reiniciar de todos modos
# Microsoft Store en sí, antes que las aplicaciones de la Store: la línea de estado de Preparación
# mientras se actualiza o se repara, con prepare-store-repair-detail bajo la barra al repararla.
prepare-store-updating = Actualizando Microsoft Store…
prepare-store-repairing = Reparando Microsoft Store…
prepare-store-repair-detail = Esto puede tardar unos minutos.
# Bajo ready-updates-done-windows cuando Preparación ha terminado y Microsoft Store está desactivada.
prepare-store-skipped-removed = Microsoft Store está desactivada en este equipo, así que las aplicaciones de la Store no se actualizaron.
# Ninguna reparación de Atlas hizo funcionar Microsoft Store. El botón es prepare-repair-store-again;
# prepare-store-broken-iso y Crear una ISO con Atlas (iso-open) están tras common-show-details.
prepare-store-broken-title = Microsoft Store no funciona
prepare-store-broken = Atlas no pudo repararla, e instalar Atlas ahora podría dañar las aplicaciones de la Store.
prepare-store-broken-iso = Si la reparación sigue fallando, haga una copia de seguridad de sus archivos y reinstale Windows con una ISO de Atlas.
prepare-repair-store-again = Volver a reparar

screen-keyboard-title = Idiomas del teclado
screen-keyboard-question = ¿Usa varios idiomas de teclado?
package-option-keyboard-shortcuts = Sí, con atajos de teclado
package-option-keyboard-selector = Sí, con el selector de la barra de tareas
package-option-keyboard-single = No, uso una sola distribución
consequence-keyboard-shortcuts = Alt+Mayús cambia el idioma; Ctrl+Mayús cambia la distribución.
consequence-keyboard-selector = Desactiva Alt+Mayús y Ctrl+Mayús para evitar cambios accidentales al jugar.
package-choice-keyboard-description = Elija cómo cambiar el idioma del teclado.
consequence-keyboard-single = { consequence-keyboard-selector }
