<!-- Language switcher. Keep this row identical across every README.<lang>.md. -->
<p align="center">
  <a href="README.md">English</a> &nbsp;·&nbsp;
  <a href="README.zh-CN.md">简体中文</a> &nbsp;·&nbsp;
  <b>Español</b> &nbsp;·&nbsp;
  <a href="README.ja.md">日本語</a> &nbsp;·&nbsp;
  <a href="README.fr.md">Français</a> &nbsp;·&nbsp;
  <a href="README.de.md">Deutsch</a>
</p>

<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="assets/hero-dark.gif">
    <source media="(prefers-color-scheme: light)" srcset="assets/hero-light.gif">
    <img alt="Sleepless: keep your Mac awake with the lid closed" src="assets/hero-light.gif" width="780">
  </picture>
</p>

<p align="center">
  <b>Sleepless mantiene tu MacBook despierto con la tapa cerrada, con batería y sin pantalla externa.</b><br>
  <sub>Un único interruptor nativo en la barra de menús, con temporizador de apagado automático y un corte por nivel mínimo de batería para que nunca la agotes del todo.</sub>
</p>

<p align="center">
  <a href="https://github.com/Aboudjem/Sleepless/actions/workflows/ci.yml"><img alt="CI" src="https://img.shields.io/github/actions/workflow/status/Aboudjem/Sleepless/ci.yml?branch=main&label=CI&logo=githubactions&logoColor=white"></a>
  <a href="https://github.com/Aboudjem/Sleepless/releases/latest"><img alt="Release" src="https://img.shields.io/github/v/release/Aboudjem/Sleepless?label=release&logo=apple&logoColor=white"></a>
  <a href="https://github.com/Aboudjem/Sleepless/releases"><img alt="Downloads" src="https://img.shields.io/github/downloads/Aboudjem/Sleepless/total?label=downloads"></a>
  <a href="LICENSE"><img alt="License: MIT" src="https://img.shields.io/github/license/Aboudjem/Sleepless?color=blue"></a>
  <img alt="Platform" src="https://img.shields.io/badge/macOS-26%20·%20Apple%20Silicon-7c5cf0?logo=apple&logoColor=white">
  <a href="https://github.com/Aboudjem/Sleepless/stargazers"><img alt="Stars" src="https://img.shields.io/github/stars/Aboudjem/Sleepless?style=social"></a>
</p>

<p align="center">
  <img alt="Sleepless demo: flip the switch, set an auto-off timer, drag the battery-floor slider" src="assets/demo.gif" width="760">
</p>

> [!NOTE]
> Cerrar la tapa normalmente pone tu Mac a dormir, y las apps basadas en `caffeinate` (KeepingYouAwake y similares) **no pueden** cambiar eso, por diseño. Sleepless activa el único ajuste que sí puede, `pmset disablesleep`, y luego lo protege con un temporizador de apagado automático y un corte por nivel mínimo de batería para que sea seguro olvidarse de él.

## Qué hace Sleepless

Sleepless es una pequeña app de la barra de menús de macOS que mantiene tu MacBook despierto con la tapa cerrada, con batería, sin pantalla externa y sin enchufe HDMI ficticio. Haces clic en la taza de café de la barra de menús, activas un interruptor y cierras la tapa: tu Mac sigue funcionando. Vuelve a desactivarlo, o deja que el temporizador de apagado automático o el nivel mínimo de batería lo apaguen por ti, y el sueño normal vuelve. Un reinicio siempre lo restablece.

Es un único archivo nativo de AppKit. Sin icono en el Dock, sin daemon en segundo plano, sin extensión de kernel, sin dependencias. Si alguna vez escribiste `sudo pmset -a disablesleep 1` en la Terminal y luego olvidaste volver a desactivarlo, esto es ese comando convertido en un interruptor seguro de un solo clic.

## Por qué otras apps de mantener despierto no pueden hacer esto

La mayoría de las apps de mantener despierto (KeepingYouAwake, Caffeine, Theine, Lungo y el comando integrado `caffeinate`) se construyen sobre las aserciones de energía de macOS. Las aserciones de energía detienen el temporizador de *inactividad*, pero no pueden anular el disparador por hardware del cierre de la tapa, así que una tapa cerrada sigue poniendo el Mac a dormir. El responsable de KeepingYouAwake lo dice sin rodeos: "caffeinate doesn't support this. KYA uses caffeinate under the hood" ([issue #66](https://github.com/newmarcel/KeepingYouAwake/issues/66)).

El único ajuste que anula el sueño por cierre de tapa es `pmset disablesleep`, que activa el indicador `SleepDisabled` del kernel. Sleepless cambia exactamente eso, vuelve a leer el valor para que la barra de menús nunca mienta, y lo envuelve en redes de seguridad. Amphetamine también puede mantener la tapa cerrada, pero se construye sobre la misma capa de aserciones y se reporta ampliamente que falla en Apple Silicon cuando cambia la fuente de alimentación ([Amphetamine-Enhancer #28](https://github.com/x74353/Amphetamine-Enhancer/issues/28)).

## Características

|  |  |
|---|---|
| ☕ **Un solo interruptor** | Haz clic en la taza de café de la barra de menús y activa el conmutador. Una taza vacía significa sueño normal, una taza llena significa despierto, y una taza llena con un punto significa despierto con batería y la red de seguridad activa. |
| ⏲️ **Temporizador de apagado automático** | Mantén el Mac despierto durante 1 hora o 2 horas con una cuenta atrás en vivo, y luego se apaga solo. El temporizador vive solo en memoria, así que salir de la app o reiniciar lo borra. |
| 🔋 **Corte por nivel mínimo de batería** | Elige un mínimo (5–50 %, predeterminado 15 %). Con batería, Sleepless se apaga solo antes de que la agotes. |
| 🪫 **Apagado automático en Low Power Mode** | Con batería, si Low Power Mode está activado, Sleepless se hace a un lado y deja que el Mac duerma, con la misma forma de seguridad que el nivel mínimo de batería. |
| 🖥️ **Sin pantalla, sin adaptador** | Solo la tapa cerrada, con batería. Sin monitor externo, sin enchufe HDMI ficticio, sin adaptador clamshell. |
| 🚀 **Iniciar al iniciar sesión** | Opcional, desactivado por defecto. Siempre arranca en estado apagado y nunca reactiva la prevención del sueño por su cuenta. |
| 🪶 **Diminuto y nativo** | Un archivo de AppKit con SF Symbols. Sin icono en el Dock, sin daemon en segundo plano, sin kext, sin dependencias. |

## Instalación

**Homebrew** (recomendado):

```sh
brew install --cask aboudjem/tap/sleepless
# one-time: add the passwordless grant (it prints exactly what it writes first)
/Applications/Sleepless.app/Contents/Resources/grant.sh
```

**Compilar desde el código fuente** (la vía de confianza: léelo, compílalo, sin aviso de Gatekeeper):

```sh
git clone https://github.com/Aboudjem/Sleepless.git
cd Sleepless && ./install.sh
```

**O descarga la app:** obtén la [última versión](https://github.com/Aboudjem/Sleepless/releases/latest), descomprímela y mueve `Sleepless.app` a `/Applications`. Está firmada de forma ad-hoc, así que aprueba el primer lanzamiento en **Ajustes del Sistema → Privacidad y seguridad → Abrir igualmente** (el viejo truco de clic derecho → Abrir se eliminó en macOS 15).

¿Descargaste una versión? Puedes confirmar que es realmente la compilación de este proyecto, sin ninguna cuenta de Apple:

```sh
shasum -a 256 -c SHA256SUMS
gh attestation verify Sleepless-*.app.zip -R Aboudjem/Sleepless
```

El recorrido completo de verificación está en [docs/AUDIT.md](docs/AUDIT.md).

## Cómo usarlo

1. Haz clic en la taza de café de la barra de menús.
2. Activa **Keep awake with lid closed**.
3. Opcionalmente elige un temporizador de apagado automático de 1 h o 2 h, y fija el nivel mínimo de batería en el que confíes.
4. Cierra la tapa. Tu Mac sigue funcionando con batería.

Desactiva el interruptor, deja que el temporizador o el nivel mínimo de batería lo apaguen, o reinicia, y el sueño normal vuelve. `./uninstall.sh` elimina todo y demuestra que el permiso ha desaparecido.

## Sleepless frente a las alternativas

| | **Sleepless** | Amphetamine | KeepingYouAwake | `caffeinate` |
|---|:---:|:---:|:---:|:---:|
| Despierto, tapa cerrada, sin monitor | ✅ ¹ | ⚠️ ² | ❌ ³ | ❌ |
| Con batería | ✅ | ✅ | ✅ (tapa abierta) | ⚠️ ⁴ |
| Temporizador de apagado automático | ✅ | ✅ | ✅ | ❌ |
| Apagado automático con batería baja | ✅ | ✅ | ✅ | ❌ |
| Código abierto | ✅ MIT | ❌ App Store | ✅ MIT | Apple |
| Coste | Gratis | Gratis | Gratis | Gratis |

<sub>A fecha de 2026-06. ¹ Sleepless usa `pmset disablesleep`, el mecanismo creado para el cierre de tapa, y vuelve a leer el indicador para que la interfaz refleje la realidad; el comportamiento de cualquier herramienta de mantener despierto sigue dependiendo del hardware y de la versión de macOS. ² Amphetamine documenta el modo de pantalla cerrada pero se reporta ampliamente que falla en Apple Silicon cuando cambia la fuente de alimentación ([Amphetamine-Enhancer #28](https://github.com/x74353/Amphetamine-Enhancer/issues/28); la propia [nota sobre sesiones fallidas](https://iffy.freshdesk.com/support/solutions/articles/48001180528) del desarrollador); la app en sí es de código cerrado (solo su repo de soporte es abierto). ³ KeepingYouAwake no puede mantener la tapa cerrada por diseño, ya que envuelve `caffeinate` ([issue #66](https://github.com/newmarcel/KeepingYouAwake/issues/66)). ⁴ `caffeinate -i` funciona con batería; `-s` es solo con corriente según la página del manual. Se agradecen las correcciones.</sub>

## Úsalo para…

- 🤖 **Terminar un trabajo largo después de irte.** La ejecución de un agente de IA, una compilación, un render, entrenamiento de ML, una gran instalación de `brew`/`npm`: actívalo, cierra la tapa, métela en la mochila y vuelve a un trabajo terminado.
- 📡 **Compartir tu punto de acceso en movimiento.** Compartir Internet / Compartir conexión desde el Mac sigue funcionando con la tapa cerrada.
- ⬇️ **Dejar transferencias grandes en marcha.** Descargas o subidas grandes, o una copia de Time Machine, se completan mientras te alejas.
- 🖥️ **Mantener vivo un servidor o una sesión SSH.** Un servidor de desarrollo local, un daemon de sincronización o una sesión remota siguen accesibles con la tapa cerrada.
- 🎧 **Mantener el audio en marcha.** La música o un render largo sigue reproduciéndose dentro de la mochila.

> [!TIP]
> Fija el nivel mínimo de batería en un valor en el que confíes (digamos 20 %) y un temporizador de apagado automático, y podrás hacer todo lo anterior sin tener que vigilar la batería.

## Cómo funciona

`caffeinate` y las aserciones de energía que utiliza no pueden anular el disparador por hardware del cierre de la tapa, así que una tapa cerrada siempre pone el Mac a dormir. El único ajuste del sistema que lo anula es `pmset disablesleep`, que activa el indicador `SleepDisabled` del kernel. Sleepless lo cambia desde un interruptor nativo, vuelve a leer el valor en vivo para que la interfaz nunca mienta, y lo revierte en tu nivel mínimo de batería, en Low Power Mode, o cuando el temporizador termina. Un reinicio también lo restablece.

Como una app gráfica no puede escribir una contraseña, el instalador añade una regla `/etc/sudoers.d` de alcance muy reducido (propiedad de root, `0440`) que permite **exactamente dos comandos y nada más**:

```
<you> ALL=(root) NOPASSWD: /usr/bin/pmset -a disablesleep 0, /usr/bin/pmset -a disablesleep 1
```

- **No se puede ampliar.** `sudoers` coincide con los argumentos de forma literal, sin comodines, así que cualquier otro comando vuelve a pedir una contraseña.
- **Sin daemon, sin script auxiliar** que un atacante pueda secuestrar. Llama directamente al `/usr/bin/pmset` de Apple con un array de argv, sin shell.
- **Siempre reversible.** Un reinicio restablece el indicador, el nivel mínimo de batería y el temporizador lo apagan, y `./uninstall.sh` elimina el permiso y lo demuestra.

El modelo de amenazas completo, la evidencia no documentada pero real de `disablesleep`, por qué no puede estar en la Mac App Store, y cómo verificar una descarga están en **[SECURITY.md](SECURITY.md)** y **[docs/AUDIT.md](docs/AUDIT.md)**.

## Preguntas frecuentes

<details>
<summary><b>cómo mantener mi MacBook despierto con la tapa cerrada sin monitor</b></summary>

Instala Sleepless, haz clic en la taza de café de la barra de menús, activa el interruptor y cierra la tapa. Mantiene el Mac despierto con batería y sin pantalla externa, usando `pmset disablesleep`. No hace falta ningún enchufe HDMI ficticio ni adaptador clamshell.
</details>

<details>
<summary><b>por qué mi MacBook se duerme al cerrar la tapa incluso con Amphetamine o KeepingYouAwake</b></summary>

Porque esas herramientas se construyen sobre las aserciones de energía de macOS, que detienen el temporizador de inactividad pero no pueden anular el disparador por hardware del cierre de la tapa. KeepingYouAwake envuelve `caffeinate`, cuyo responsable confirma que "doesn't support this" ([issue #66](https://github.com/newmarcel/KeepingYouAwake/issues/66)). Amphetamine lo intenta, pero se reporta ampliamente que falla en Apple Silicon cuando cambia la fuente de alimentación. `pmset disablesleep`, que es lo que usa Sleepless, es un ajuste de más bajo nivel que sí puede anular el sueño por cierre de tapa.
</details>

<details>
<summary><b>¿sigue funcionando <code>pmset disablesleep</code> en Apple Silicon (M1/M2/M3)?</b></summary>

`pmset -a disablesleep 1` sigue activando el indicador `SleepDisabled` en Apple Silicon y, según reportes de primera mano, mantiene un MacBook despierto con la tapa cerrada con batería, pero Apple no documenta oficialmente el ajuste, así que su comportamiento exacto puede variar según el modelo y la versión de macOS. Verifícalo en tu propia máquina con `pmset -g | grep SleepDisabled` (debería leerse `1`). La mayoría de las afirmaciones de que "ya no funciona en M1/M2/M3" describen en realidad `caffeinate` o apps basadas en caffeinate (Amphetamine, KeepingYouAwake), que nunca pudieron evitar el sueño con la tapa cerrada, un mecanismo distinto, no una regresión de `pmset disablesleep`.
</details>

<details>
<summary><b>¿puedo mantener mi MacBook despierto con batería y la tapa cerrada?</b></summary>

Sí. Ese es todo el propósito de Sleepless, y es lo que lo distingue de las apps basadas en `caffeinate`. Fija un nivel mínimo de batería y un temporizador de apagado automático para que no agote el Mac mientras funciona sin supervisión.
</details>

<details>
<summary><b>cuál es la diferencia entre <code>caffeinate</code> y desactivar el sueño por cierre de tapa</b></summary>

`caffeinate` mantiene una aserción de energía que evita el sueño por *inactividad* mientras la tapa está abierta, y no puede impedir que una tapa cerrada ponga el Mac a dormir. Desactivar el sueño por cierre de tapa con `pmset disablesleep` activa un indicador del kernel que anula el disparador del cierre de la tapa en sí, y por eso funciona con la tapa cerrada.
</details>

<details>
<summary><b>en qué se diferencia Sleepless de Amphetamine y KeepingYouAwake</b></summary>

Sleepless hace una sola cosa, mantener despierto con la tapa cerrada y con batería, con un diseño que prioriza la seguridad: un temporizador de apagado automático, un corte por nivel mínimo de batería, apagado automático en Low Power Mode y un restablecimiento al reiniciar. Es de código abierto (MIT), un pequeño archivo de AppKit sin daemon ni kext, y usa `pmset disablesleep` en lugar de la capa de aserciones que limita a los demás.
</details>

<details>
<summary><b>¿es seguro usar un MacBook con la tapa cerrada? ¿se sobrecalentará o agotará la batería?</b></summary>

Es seguro para trabajo ligero y sin supervisión como descargas, sincronizaciones o un punto de acceso. Una carga sostenida y pesada con la tapa totalmente cerrada reduce el flujo de aire, así que usa el sentido común ahí. Para proteger la batería, Sleepless se apaga solo en el nivel mínimo que fijes y en Low Power Mode, y el temporizador de apagado automático limita cuánto tiempo permanece activo.
</details>

<details>
<summary><b>¿necesito un enchufe HDMI ficticio para usar el modo clamshell?</b></summary>

No. El modo clamshell oficial de Apple necesita alimentación externa y una pantalla, pero Sleepless mantiene el Mac despierto con la tapa cerrada solo con batería, sin pantalla y sin adaptador HDMI.
</details>

<details>
<summary><b>¿Sleepless requiere sudo, una extensión de kernel o un daemon en segundo plano?</b></summary>

Necesita un único permiso `sudo` de alcance muy reducido (dos comandos `pmset` exactos, nada más) para que una app gráfica pueda cambiar el ajuste sin un aviso de contraseña. No hay extensión de kernel ni daemon en segundo plano. Toda la app es un único archivo de AppKit.
</details>

<details>
<summary><b>la taza de café no aparece en mi barra de menús</b></summary>

macOS 26 puede ocultar elementos de la barra de menús. Revisa Ajustes del Sistema (Centro de Control / Barra de menús) y permite que Sleepless muestre su elemento. Confirma que está en ejecución con <code>pgrep -x Sleepless</code>.
</details>

<details>
<summary><b>cómo detengo Sleepless y restauro el sueño normal</b></summary>

Desactiva el interruptor, o deja que el temporizador de apagado automático o el nivel mínimo de batería lo apaguen, y el sueño normal vuelve de inmediato. Un reinicio también lo restablece, y `./uninstall.sh` elimina la app, el elemento de inicio de sesión y el permiso de sudoers, y luego demuestra que el permiso ha desaparecido.
</details>

<details>
<summary><b>¿puedo ejecutar agentes de IA o trabajos largos durante la noche con la tapa cerrada?</b></summary>

Sí. Activa Sleepless, fija un nivel mínimo de batería, cierra la tapa, y la ejecución de un agente, una compilación, un render o un trabajo de entrenamiento sigue en marcha. Conecta a la corriente para toda la noche, o quédate con batería con un nivel mínimo y un temporizador para que se detenga solo antes de que la batería se agote.
</details>

<details>
<summary><b>¿por qué no está notarizada?</b></summary>

Es una herramienta personal de código abierto sin un Apple Developer ID de pago, así que está firmada de forma ad-hoc. Compila desde el código fuente para saltarte Gatekeeper por completo, o usa el flujo **Abrir igualmente** para la app precompilada. La notarización está documentada como un próximo paso previsto en [docs/AUDIT.md](docs/AUDIT.md).
</details>

<details>
<summary><b>¿funciona en Intel o en versiones antiguas de macOS?</b></summary>

Está verificado en **macOS 26 Apple Silicon**. `disablesleep` no está documentado, así que no se garantiza en otras versiones o hardware. Pruébalo y cuéntanos, se agradecen los informes honestos.
</details>

## Cómo contribuir

Se agradecen issues y PRs, especialmente traducciones e informes de pruebas desde otro hardware. Consulta [CONTRIBUTING.md](CONTRIBUTING.md) y el [Código de Conducta](CODE_OF_CONDUCT.md). Sleepless se mantiene deliberadamente pequeño.

## Licencia

[MIT](LICENSE) © 2026 Adam Boudjemaa.

<p align="center">
  <sub>Si Sleepless te ahorró un viaje al Terminal, una ⭐ ayuda a que otras personas lo encuentren.</sub>
</p>
