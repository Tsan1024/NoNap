<!-- Language switcher. Keep this row identical across every README.<lang>.md. -->
<p align="center">
  <a href="README.md">English</a> &nbsp;·&nbsp;
  <a href="README.zh-CN.md">简体中文</a> &nbsp;·&nbsp;
  <a href="README.es.md">Español</a> &nbsp;·&nbsp;
  <a href="README.ja.md">日本語</a> &nbsp;·&nbsp;
  <a href="README.fr.md">Français</a> &nbsp;·&nbsp;
  <b>Deutsch</b>
</p>

> Diese Übersetzung wurde von der Community bzw. maschinell erstellt und kann gegenüber dem englischen README veraltet sein. Maßgeblich ist die englische Version. Siehe [English README](README.md).

<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="assets/hero-dark.gif">
    <source media="(prefers-color-scheme: light)" srcset="assets/hero-light.gif">
    <img alt="Sleepless: keep your Mac awake with the lid closed" src="assets/hero-light.gif" width="780">
  </picture>
</p>

<p align="center">
  <b>Sleepless hält dein MacBook bei geschlossenem Deckel wach, im Akkubetrieb, ohne externen Bildschirm.</b><br>
  <sub>Ein nativer Schalter in der Menüleiste, mit Abschalt-Timer und Abschaltung bei Akku-Mindeststand, damit du den Akku nie ganz leerziehst.</sub>
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
> Wenn du den Deckel schließt, geht dein Mac normalerweise in den Ruhezustand, und Apps auf `caffeinate`-Basis (KeepingYouAwake und Co.) **können** das von Haus aus nicht ändern. Sleepless legt die eine Einstellung um, die es kann, `pmset disablesleep`, und sichert sie dann mit einem Abschalt-Timer und einer Abschaltung bei Akku-Mindeststand ab, sodass du sie bedenkenlos vergessen kannst.

## Was Sleepless macht

Sleepless ist eine winzige macOS-App für die Menüleiste, die dein MacBook bei geschlossenem Deckel wach hält, im Akkubetrieb, ohne externen Bildschirm und ohne HDMI-Dummy-Stecker. Du klickst auf die Kaffeetasse in der Menüleiste, legst einen Schalter um und schließt den Deckel: dein Mac läuft weiter. Leg den Schalter zurück, oder lass den Abschalt-Timer oder den Akku-Mindeststand das für dich erledigen, und der normale Ruhezustand kehrt zurück. Ein Neustart setzt es immer zurück.

Es ist eine einzige native AppKit-Datei. Kein Dock-Symbol, kein Hintergrund-Daemon, keine Kernel-Erweiterung, keine Abhängigkeiten. Wenn du jemals `sudo pmset -a disablesleep 1` im Terminal getippt und dann vergessen hast, es wieder abzuschalten, dann ist das genau dieser Befehl, als sicherer Schalter mit einem Klick.

## Warum andere Wachhalte-Apps das nicht können

Die meisten Wachhalte-Apps (KeepingYouAwake, Caffeine, Theine, Lungo und der eingebaute Befehl `caffeinate`) bauen auf den Power Assertions von macOS auf. Power Assertions stoppen den *Leerlauf*-Timer, können aber den Hardware-Trigger beim Schließen des Deckels nicht überstimmen, daher schickt ein geschlossener Deckel den Mac weiterhin in den Ruhezustand. Der Maintainer von KeepingYouAwake sagt es ganz klar: "caffeinate doesn't support this. KYA uses caffeinate under the hood" ([Issue #66](https://github.com/newmarcel/KeepingYouAwake/issues/66)).

Die eine Einstellung, die den Ruhezustand beim Schließen des Deckels überstimmt, ist `pmset disablesleep`, die das `SleepDisabled`-Flag des Kernels setzt. Sleepless schaltet genau das um, liest den Wert zurück, sodass die Menüleiste nie lügt, und umgibt es mit Sicherheitsnetzen. Amphetamine kann den Deckel ebenfalls geschlossen halten, baut aber auf derselben Assertion-Schicht auf und versagt Berichten zufolge häufig auf Apple Silicon, sobald sich die Stromquelle ändert ([Amphetamine-Enhancer #28](https://github.com/x74353/Amphetamine-Enhancer/issues/28)).

## Funktionen

|  |  |
|---|---|
| ☕ **Ein Schalter** | Klicke auf die Kaffeetasse in der Menüleiste und lege den Schalter um. Eine leere Tasse bedeutet normalen Ruhezustand, eine volle Tasse bedeutet wach, eine volle Tasse mit Punkt bedeutet wach im Akkubetrieb mit aktivem Sicherheitsnetz. |
| ⏲️ **Abschalt-Timer** | Halte den Mac 1 Stunde oder 2 Stunden wach, mit einem laufenden Countdown, danach schaltet es sich selbst ab. Der Timer liegt nur im Arbeitsspeicher, ein Beenden oder Neustart löscht ihn also. |
| 🔋 **Abschaltung bei Akku-Mindeststand** | Wähle einen Mindeststand (5–50 %, Standard 15 %). Im Akkubetrieb schaltet Sleepless sich selbst ab, bevor du den Akku leerziehst. |
| 🪫 **Auto-Abschaltung im Low Power Mode** | Ist im Akkubetrieb der Low Power Mode aktiv, tritt Sleepless zur Seite und lässt den Mac schlafen, dieselbe Sicherheitslogik wie beim Akku-Mindeststand. |
| 🖥️ **Kein Bildschirm, kein Dongle** | Nur der Deckel geschlossen, im Akkubetrieb. Kein externer Monitor, kein HDMI-Dummy-Stecker, kein clamshell-Adapter. |
| 🚀 **Beim Anmelden starten** | Optional, standardmäßig aus. Es startet immer im ausgeschalteten Zustand und reaktiviert die Ruhezustand-Verhinderung nie von selbst. |
| 🪶 **Winzig und nativ** | Eine AppKit-Datei mit SF Symbols. Kein Dock-Symbol, kein Hintergrund-Daemon, keine kext, keine Abhängigkeiten. |

## Installation

**Homebrew** (empfohlen):

```sh
brew install --cask aboudjem/tap/sleepless
# one-time: add the passwordless grant (it prints exactly what it writes first)
/Applications/Sleepless.app/Contents/Resources/grant.sh
```

**Aus dem Quellcode bauen** (der Vertrauenspfad: lies ihn, bau ihn, kein Gatekeeper-Hinweis):

```sh
git clone https://github.com/Aboudjem/Sleepless.git
cd Sleepless && ./install.sh
```

**Oder lade die App herunter:** Hol dir das [latest release](https://github.com/Aboudjem/Sleepless/releases/latest), entpacke es und verschiebe `Sleepless.app` nach `/Applications`. Sie ist ad-hoc signiert, also bestätige den ersten Start unter **Systemeinstellungen → Datenschutz & Sicherheit → Trotzdem öffnen** (der alte Trick mit Rechtsklick → Öffnen wurde in macOS 15 entfernt).

Ein Release heruntergeladen? Du kannst ohne Apple-Konto bestätigen, dass es wirklich der Build dieses Projekts ist:

```sh
shasum -a 256 -c SHA256SUMS
gh attestation verify Sleepless-*.app.zip -R Aboudjem/Sleepless
```

Die vollständige Anleitung zur Überprüfung steht in [docs/AUDIT.md](docs/AUDIT.md).

## So verwendest du es

1. Klicke auf die Kaffeetasse in der Menüleiste.
2. Lege **Bei geschlossenem Deckel wach halten** auf an.
3. Wähle optional einen Abschalt-Timer von 1 h oder 2 h und stelle den Akku-Mindeststand ein, dem du vertraust.
4. Schließe den Deckel. Dein Mac läuft im Akkubetrieb weiter.

Leg den Schalter zurück, lass den Timer oder den Akku-Mindeststand abschalten, oder starte neu, und der normale Ruhezustand kehrt zurück. `./uninstall.sh` entfernt alles und belegt, dass die Berechtigung weg ist.

## Sleepless im Vergleich zu den Alternativen

| | **Sleepless** | Amphetamine | KeepingYouAwake | `caffeinate` |
|---|:---:|:---:|:---:|:---:|
| Wach, Deckel geschlossen, kein Monitor | ✅ ¹ | ⚠️ ² | ❌ ³ | ❌ |
| Im Akkubetrieb | ✅ | ✅ | ✅ (Deckel offen) | ⚠️ ⁴ |
| Abschalt-Timer | ✅ | ✅ | ✅ | ❌ |
| Auto-Abschaltung bei niedrigem Akku | ✅ | ✅ | ✅ | ❌ |
| Open Source | ✅ MIT | ❌ App Store | ✅ MIT | Apple |
| Kosten | Kostenlos | Kostenlos | Kostenlos | Kostenlos |

<sub>Stand 2026-06. ¹ Sleepless nutzt `pmset disablesleep`, den Mechanismus, der für das Schließen des Deckels gebaut wurde, und liest das Flag zurück, sodass die Oberfläche die Realität widerspiegelt; das Verhalten jedes Wachhalte-Werkzeugs hängt weiterhin von der Hardware und der macOS-Version ab. ² Amphetamine dokumentiert einen Modus für geschlossenen Bildschirm, versagt aber Berichten zufolge häufig auf Apple Silicon, sobald sich die Stromquelle ändert ([Amphetamine-Enhancer #28](https://github.com/x74353/Amphetamine-Enhancer/issues/28); die [eigene Notiz des Entwicklers zu fehlgeschlagenen Sitzungen](https://iffy.freshdesk.com/support/solutions/articles/48001180528)); die App selbst ist Closed Source (nur ihr Support-Repo ist offen). ³ KeepingYouAwake kann den Deckel konzeptbedingt nicht geschlossen wach halten, da es `caffeinate` umhüllt ([Issue #66](https://github.com/newmarcel/KeepingYouAwake/issues/66)). ⁴ `caffeinate -i` läuft im Akkubetrieb; `-s` ist laut Man-Page nur am Netzteil verfügbar. Korrekturen willkommen.</sub>

## Setze es ein, um…

- 🤖 **Einen langen Job zu Ende zu bringen, nachdem du weggegangen bist.** Ein Lauf eines KI-Agenten, ein Build, ein Render, ML-Training, eine große `brew`/`npm`-Installation: schalte es ein, schließe den Deckel, steck es in die Tasche, komm zu einem fertigen Job zurück.
- 📡 **Deinen Hotspot unterwegs zu teilen.** Internetfreigabe oder Persönlicher Hotspot vom Mac läuft auch bei geschlossenem Deckel weiter.
- ⬇️ **Große Übertragungen laufen zu lassen.** Große Downloads, Uploads oder ein Time-Machine-Backup laufen fertig, während du kurz weg bist.
- 🖥️ **Einen Server oder eine SSH-Sitzung am Leben zu halten.** Ein lokaler Dev-Server, ein Sync-Daemon oder eine entfernte Sitzung bleibt erreichbar, Deckel geschlossen.
- 🎧 **Audio weiterlaufen zu lassen.** Musik oder ein langes Render spielt in der Tasche weiter.

> [!TIP]
> Setze den Akku-Mindeststand auf einen Wert, dem du vertraust (etwa 20 %), und stelle einen Abschalt-Timer ein, dann kannst du all das machen, ohne den Akku im Auge behalten zu müssen.

## So funktioniert es

`caffeinate` und die dabei genutzten Power Assertions können den Hardware-Trigger beim Schließen des Deckels nicht überstimmen, daher schickt ein geschlossener Deckel den Mac immer in den Ruhezustand. Die eine Systemeinstellung, die das überstimmt, ist `pmset disablesleep`, die das `SleepDisabled`-Flag des Kernels umlegt. Sleepless schaltet sie über einen nativen Schalter um, liest den Live-Wert zurück, sodass die Oberfläche nie lügt, und setzt sie bei deinem Akku-Mindeststand, im Low Power Mode oder beim Ablaufen des Timers zurück. Ein Neustart setzt sie ebenfalls zurück.

Weil eine GUI-App kein Passwort eintippen kann, fügt das Installationsprogramm eine eng gefasste `/etc/sudoers.d`-Regel hinzu (root-eigen, `0440`), die **genau zwei Befehle und sonst nichts** erlaubt:

```
<you> ALL=(root) NOPASSWD: /usr/bin/pmset -a disablesleep 0, /usr/bin/pmset -a disablesleep 1
```

- **Sie lässt sich nicht ausweiten.** `sudoers` gleicht Argumente wörtlich ab, ohne Platzhalter, sodass jeder andere Befehl wieder nach einem Passwort fragt.
- **Kein Daemon, kein Hilfsskript**, das ein Angreifer kapern könnte. Es ruft Apples `/usr/bin/pmset` direkt mit einem argv-Array auf, ohne Shell.
- **Immer reversibel.** Ein Neustart setzt das Flag zurück, der Akku-Mindeststand und der Timer schalten es ab, und `./uninstall.sh` entfernt die Berechtigung und belegt es.

Das vollständige Bedrohungsmodell, die undokumentierten, aber realen Belege für `disablesleep`, warum es nicht in den Mac App Store kann und wie du einen Download überprüfst, stehen in **[SECURITY.md](SECURITY.md)** und **[docs/AUDIT.md](docs/AUDIT.md)**.

## FAQ

<details>
<summary><b>MacBook bei geschlossenem Deckel ohne Monitor wach halten, wie geht das?</b></summary>

Installiere Sleepless, klicke auf die Kaffeetasse in der Menüleiste, lege den Schalter auf an und schließe den Deckel. Es hält den Mac im Akkubetrieb wach, ohne externen Bildschirm, mithilfe von `pmset disablesleep`. Ein HDMI-Dummy-Stecker oder ein clamshell-Adapter ist nicht nötig.
</details>

<details>
<summary><b>Warum geht mein MacBook beim Schließen des Deckels in den Ruhezustand, sogar mit Amphetamine oder KeepingYouAwake?</b></summary>

Weil diese Werkzeuge auf den Power Assertions von macOS aufbauen, die den Leerlauf-Timer stoppen, aber den Hardware-Trigger beim Schließen des Deckels nicht überstimmen können. KeepingYouAwake umhüllt `caffeinate`, dessen Maintainer bestätigt, dass es "doesn't support this" ([Issue #66](https://github.com/newmarcel/KeepingYouAwake/issues/66)). Amphetamine versucht es, bricht aber Berichten zufolge auf Apple Silicon ab, sobald sich die Stromquelle ändert. `pmset disablesleep`, das Sleepless nutzt, ist eine tiefer liegende Einstellung, die den Ruhezustand beim Schließen des Deckels überstimmen kann.
</details>

<details>
<summary><b>Funktioniert <code>pmset disablesleep</code> auf Apple Silicon (M1/M2/M3) noch?</b></summary>

`pmset -a disablesleep 1` setzt das `SleepDisabled`-Flag auf Apple Silicon weiterhin und hält ein MacBook in Erfahrungsberichten aus erster Hand bei geschlossenem Deckel im Akkubetrieb wach, aber Apple dokumentiert die Einstellung nicht offiziell, daher kann ihr genaues Verhalten je nach Modell und macOS-Version variieren. Prüfe es auf deinem eigenen Rechner mit `pmset -g | grep SleepDisabled` (es sollte `1` anzeigen). Die meisten Behauptungen, es "funktioniere auf M1/M2/M3 nicht mehr", beschreiben in Wahrheit `caffeinate` oder Apps auf caffeinate-Basis (Amphetamine, KeepingYouAwake), die den Ruhezustand bei geschlossenem Deckel nie verhindern konnten, ein anderer Mechanismus, keine Regression von `pmset disablesleep`.
</details>

<details>
<summary><b>Kann ich mein MacBook im Akkubetrieb bei geschlossenem Deckel wach halten?</b></summary>

Ja. Das ist der ganze Sinn von Sleepless, und genau das unterscheidet es von Apps auf `caffeinate`-Basis. Setze einen Akku-Mindeststand und einen Abschalt-Timer, damit es den Mac nicht leerziehen kann, während es unbeaufsichtigt läuft.
</details>

<details>
<summary><b>Was ist der Unterschied zwischen <code>caffeinate</code> und dem Deaktivieren des Deckel-Ruhezustands?</b></summary>

`caffeinate` hält eine Power Assertion, die den *Leerlauf*-Ruhezustand bei offenem Deckel verhindert, und es kann einen geschlossenen Deckel nicht davon abhalten, den Mac schlafen zu legen. Das Deaktivieren des Deckel-Ruhezustands mit `pmset disablesleep` legt ein Kernel-Flag um, das den Trigger beim Schließen des Deckels selbst überstimmt, weshalb es bei geschlossenem Deckel funktioniert.
</details>

<details>
<summary><b>Wie unterscheidet sich Sleepless von Amphetamine und KeepingYouAwake?</b></summary>

Sleepless macht eine Sache, Wachhalten bei geschlossenem Deckel im Akkubetrieb, mit einem auf Sicherheit ausgelegten Design: ein Abschalt-Timer, eine Abschaltung bei Akku-Mindeststand, eine Auto-Abschaltung im Low Power Mode und ein Reset beim Neustart. Es ist Open Source (MIT), eine kleine AppKit-Datei ohne Daemon oder kext, und es nutzt `pmset disablesleep` statt der Assertion-Schicht, die die anderen einschränkt.
</details>

<details>
<summary><b>Ist es sicher, ein MacBook bei geschlossenem Deckel zu betreiben? Überhitzt es oder zieht es den Akku leer?</b></summary>

Für leichte, unbeaufsichtigte Arbeit wie Downloads, Synchronisierungen oder einen Hotspot ist es sicher. Schwere Dauerlast bei ganz geschlossenem Deckel verringert den Luftstrom, da solltest du also mit Augenmaß vorgehen. Um den Akku zu schützen, schaltet Sleepless sich beim von dir gesetzten Mindeststand und im Low Power Mode selbst ab, und der Abschalt-Timer begrenzt, wie lange es an bleibt.
</details>

<details>
<summary><b>Brauche ich einen HDMI-Dummy-Stecker, um den clamshell-Modus zu nutzen?</b></summary>

Nein. Apples offizieller clamshell-Modus braucht externe Stromversorgung und einen Bildschirm, aber Sleepless hält den Mac bei geschlossenem Deckel allein im Akkubetrieb wach, ohne Bildschirm und ohne HDMI-Dongle.
</details>

<details>
<summary><b>Braucht Sleepless sudo, eine Kernel-Erweiterung oder einen Hintergrund-Daemon?</b></summary>

Es braucht eine eng gefasste `sudo`-Berechtigung (zwei exakte `pmset`-Befehle, sonst nichts), damit eine GUI-App die Einstellung ohne Passwort-Abfrage umlegen kann. Es gibt keine Kernel-Erweiterung und keinen Hintergrund-Daemon. Die ganze App ist eine einzige AppKit-Datei.
</details>

<details>
<summary><b>Die Kaffeetasse erscheint nicht in meiner Menüleiste.</b></summary>

macOS 26 kann Elemente der Menüleiste ausblenden. Prüfe die Systemeinstellungen (Kontrollzentrum / Menüleiste) und erlaube Sleepless, sein Element anzuzeigen. Bestätige mit <code>pgrep -x Sleepless</code>, dass es läuft.
</details>

<details>
<summary><b>Wie stoppe ich Sleepless und stelle den normalen Ruhezustand wieder her?</b></summary>

Leg den Schalter auf aus, oder lass den Abschalt-Timer oder den Akku-Mindeststand abschalten, und der normale Ruhezustand kehrt sofort zurück. Ein Neustart setzt es ebenfalls zurück, und `./uninstall.sh` entfernt die App, den Anmelde-Eintrag und die sudoers-Berechtigung und belegt dann, dass die Berechtigung weg ist.
</details>

<details>
<summary><b>Kann ich KI-Agenten oder lange Jobs über Nacht bei geschlossenem Deckel laufen lassen?</b></summary>

Ja. Schalte Sleepless ein, setze einen Akku-Mindeststand, schließe den Deckel, und ein Agenten-Lauf, Build, Render oder Trainingsjob läuft weiter. Schließ für eine ganze Nacht das Netzteil an, oder bleib im Akkubetrieb mit Mindeststand und Timer, sodass es sich selbst stoppt, bevor der Akku knapp wird.
</details>

<details>
<summary><b>Warum ist es nicht notarisiert?</b></summary>

Es ist ein persönliches, quelloffenes Werkzeug ohne bezahlte Apple Developer ID, also ist es ad-hoc signiert. Baue es aus dem Quellcode, um Gatekeeper ganz zu umgehen, oder nutze den **Trotzdem öffnen**-Ablauf für die vorgefertigte App. Die Notarisierung ist in [docs/AUDIT.md](docs/AUDIT.md) als geplanter nächster Schritt dokumentiert.
</details>

<details>
<summary><b>Funktioniert es auf Intel oder älterem macOS?</b></summary>

Es ist auf **macOS 26 Apple Silicon** verifiziert. `disablesleep` ist undokumentiert, daher sind andere Versionen oder Hardware nicht garantiert. Probier es aus und melde dich zurück, ehrliche Berichte sind willkommen.
</details>

## Mitwirken

Issues und PRs sind willkommen, besonders Übersetzungen und Testberichte von anderer Hardware. Siehe [CONTRIBUTING.md](CONTRIBUTING.md) und den [Code of Conduct](CODE_OF_CONDUCT.md). Sleepless bleibt bewusst klein.

## Lizenz

[MIT](LICENSE) © 2026 Adam Boudjemaa.

<p align="center">
  <sub>Wenn Sleepless dir einen Ausflug ins Terminal erspart hat, hilft ein ⭐ anderen, es zu finden.</sub>
</p>
