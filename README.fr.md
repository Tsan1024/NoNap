<!-- Language switcher. Keep this row identical across every README.<lang>.md. -->
<p align="center">
  <a href="README.md">English</a> &nbsp;·&nbsp;
  <a href="README.zh-CN.md">简体中文</a> &nbsp;·&nbsp;
  <a href="README.es.md">Español</a> &nbsp;·&nbsp;
  <a href="README.ja.md">日本語</a> &nbsp;·&nbsp;
  <b>Français</b> &nbsp;·&nbsp;
  <a href="README.de.md">Deutsch</a>
</p>

> Cette traduction est générée par la communauté ou par une machine et peut être en retard sur le README en anglais. La version anglaise fait foi. [English README](README.md).

<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="assets/hero-dark.gif">
    <source media="(prefers-color-scheme: light)" srcset="assets/hero-light.gif">
    <img alt="Sleepless: keep your Mac awake with the lid closed" src="assets/hero-light.gif" width="780">
  </picture>
</p>

<p align="center">
  <b>Sleepless garde votre MacBook éveillé capot fermé, sur batterie, sans écran externe.</b><br>
  <sub>Un seul interrupteur natif dans la barre des menus, avec une minuterie d'extinction automatique et une coupure au plancher de batterie pour ne jamais la vider complètement.</sub>
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
> Fermer le capot met normalement votre Mac en veille, et les applications basées sur `caffeinate` (KeepingYouAwake et consorts) **ne peuvent pas** changer cela, c'est voulu par conception. Sleepless bascule le seul réglage qui le permet, `pmset disablesleep`, puis le protège avec une minuterie d'extinction automatique et une coupure au plancher de batterie, de sorte que vous pouvez l'oublier sans risque.

## Ce que fait Sleepless

Sleepless est une minuscule application macOS pour la barre des menus qui garde votre MacBook éveillé capot fermé, sur batterie, sans écran externe et sans fiche HDMI factice. Vous cliquez sur la tasse de café dans la barre des menus, vous basculez un interrupteur et vous fermez le capot : votre Mac continue de tourner. Rebasculez-le, ou laissez la minuterie d'extinction automatique ou le plancher de batterie le couper pour vous, et la veille normale revient. Un redémarrage le réinitialise toujours.

C'est un seul fichier natif AppKit. Pas d'icône dans le Dock, pas de démon en arrière-plan, pas d'extension noyau, pas de dépendances. Si vous avez déjà tapé `sudo pmset -a disablesleep 1` dans le Terminal pour ensuite oublier de le désactiver, c'est cette commande sous la forme d'un interrupteur sûr, en un clic.

## Pourquoi les autres applications anti-veille n'y arrivent pas

La plupart des applications anti-veille (KeepingYouAwake, Caffeine, Theine, Lungo, et la commande `caffeinate` intégrée) reposent sur les assertions d'alimentation de macOS. Les assertions d'alimentation arrêtent la minuterie d'*inactivité*, mais elles ne peuvent pas passer outre le déclencheur matériel de fermeture du capot, donc un capot fermé met quand même le Mac en veille. Le mainteneur de KeepingYouAwake le dit clairement : « caffeinate doesn't support this. KYA uses caffeinate under the hood » ([issue #66](https://github.com/newmarcel/KeepingYouAwake/issues/66)).

Le seul réglage qui passe outre la veille à la fermeture du capot est `pmset disablesleep`, qui positionne le drapeau `SleepDisabled` du noyau. Sleepless bascule exactement cela, relit la valeur pour que la barre des menus ne mente jamais, et l'entoure de filets de sécurité. Amphetamine peut aussi maintenir le capot fermé, mais il s'appuie sur la même couche d'assertions et est largement signalé comme défaillant sur Apple Silicon lors d'un changement de source d'alimentation ([Amphetamine-Enhancer #28](https://github.com/x74353/Amphetamine-Enhancer/issues/28)).

## Fonctionnalités

|  |  |
|---|---|
| ☕ **Un seul interrupteur** | Cliquez sur la tasse de café dans la barre des menus, basculez l'interrupteur. Une tasse vide signifie veille normale, une tasse pleine signifie éveillé, une tasse pleine avec un point signifie éveillé sur batterie avec le filet de sécurité actif. |
| ⏲️ **Minuterie d'extinction automatique** | Restez éveillé pendant 1 heure ou 2 heures avec un compte à rebours en direct, puis l'application se désactive d'elle-même. La minuterie ne vit qu'en mémoire, donc quitter l'application ou redémarrer l'efface. |
| 🔋 **Coupure au plancher de batterie** | Choisissez un plancher (5 à 50 %, par défaut 15 %). Sur batterie, Sleepless se désactive d'elle-même avant que vous ne soyez à plat. |
| 🪫 **Extinction automatique en mode Économie d'énergie** | Sur batterie, si le mode Économie d'énergie est actif, Sleepless s'efface et laisse le Mac se mettre en veille, selon le même principe de sécurité que le plancher de batterie. |
| 🖥️ **Pas d'écran, pas de dongle** | Juste le capot fermé, sur batterie. Pas de moniteur externe, pas de fiche HDMI factice, pas d'adaptateur clamshell. |
| 🚀 **Lancer à l'ouverture de session** | Optionnel, désactivé par défaut. L'application démarre toujours à l'état désactivé et ne réactive jamais la prévention de veille d'elle-même. |
| 🪶 **Minuscule et native** | Un seul fichier AppKit avec SF Symbols. Pas d'icône dans le Dock, pas de démon en arrière-plan, pas de kext, pas de dépendances. |

## Installation

**Homebrew** (recommandé) :

```sh
brew install --cask aboudjem/tap/sleepless
# one-time: add the passwordless grant (it prints exactly what it writes first)
/Applications/Sleepless.app/Contents/Resources/grant.sh
```

**Compiler depuis les sources** (la voie de la confiance : lisez-le, compilez-le, sans invite Gatekeeper) :

```sh
git clone https://github.com/Aboudjem/Sleepless.git
cd Sleepless && ./install.sh
```

**Ou téléchargez l'application :** récupérez la [dernière version](https://github.com/Aboudjem/Sleepless/releases/latest), décompressez-la et déplacez `Sleepless.app` vers `/Applications`. Elle est signée de façon ad-hoc, alors approuvez le premier lancement dans **Réglages Système → Confidentialité et sécurité → Ouvrir quand même** (l'ancienne astuce du clic droit → Ouvrir a été supprimée dans macOS 15).

Vous avez téléchargé une version ? Vous pouvez confirmer qu'il s'agit bien de la compilation de ce projet, sans aucun compte Apple :

```sh
shasum -a 256 -c SHA256SUMS
gh attestation verify Sleepless-*.app.zip -R Aboudjem/Sleepless
```

Le guide de vérification complet se trouve dans [docs/AUDIT.md](docs/AUDIT.md).

## Comment l'utiliser

1. Cliquez sur la tasse de café dans la barre des menus.
2. Activez **Keep awake with lid closed**.
3. Optionnellement, choisissez une minuterie d'extinction automatique de 1 h ou 2 h, et réglez le plancher de batterie qui vous met en confiance.
4. Fermez le capot. Votre Mac continue de tourner sur batterie.

Désactivez l'interrupteur, laissez la minuterie ou le plancher de batterie le couper, ou redémarrez, et la veille normale revient. `./uninstall.sh` supprime tout et prouve que l'autorisation a disparu.

## Sleepless face aux alternatives

| | **Sleepless** | Amphetamine | KeepingYouAwake | `caffeinate` |
|---|:---:|:---:|:---:|:---:|
| Éveillé, capot fermé, sans écran | ✅ ¹ | ⚠️ ² | ❌ ³ | ❌ |
| Sur batterie | ✅ | ✅ | ✅ (capot ouvert) | ⚠️ ⁴ |
| Minuterie d'extinction automatique | ✅ | ✅ | ✅ | ❌ |
| Extinction automatique à batterie faible | ✅ | ✅ | ✅ | ❌ |
| Open source | ✅ MIT | ❌ App Store | ✅ MIT | Apple |
| Coût | Gratuit | Gratuit | Gratuit | Gratuit |

<sub>Au 2026-06. ¹ Sleepless utilise `pmset disablesleep`, le mécanisme conçu pour la fermeture du capot, et relit le drapeau pour que l'interface reflète la réalité ; le comportement de tout outil anti-veille reste dépendant du matériel et de la version de macOS. ² Amphetamine documente le mode écran fermé mais est largement signalé comme défaillant sur Apple Silicon lors d'un changement de source d'alimentation ([Amphetamine-Enhancer #28](https://github.com/x74353/Amphetamine-Enhancer/issues/28) ; la propre [note du développeur sur les sessions échouées](https://iffy.freshdesk.com/support/solutions/articles/48001180528)) ; l'application elle-même est propriétaire (seul son dépôt de support est ouvert). ³ KeepingYouAwake ne peut pas maintenir le capot fermé, par conception, puisqu'il enveloppe `caffeinate` ([issue #66](https://github.com/newmarcel/KeepingYouAwake/issues/66)). ⁴ `caffeinate -i` tourne sur batterie ; `-s` est réservé au secteur d'après la page de manuel. Corrections bienvenues.</sub>

## À utiliser pour…

- 🤖 **Terminer une longue tâche après votre départ.** Une exécution d'agent IA, une compilation, un rendu, un entraînement ML, une grosse installation `brew`/`npm` : activez-le, fermez le capot, glissez-le dans votre sac, et revenez à une tâche terminée.
- 📡 **Partager votre connexion en déplacement.** Le partage Internet ou le Point d'accès personnel depuis le Mac continue de servir capot fermé.
- ⬇️ **Laisser tourner de gros transferts.** De grands téléchargements, des envois ou une sauvegarde Time Machine se terminent pendant votre absence.
- 🖥️ **Garder un serveur ou une session SSH active.** Un serveur de dev local, un démon de synchronisation ou une session distante reste joignable, capot fermé.
- 🎧 **Continuer la lecture audio.** De la musique ou un long rendu continue de tourner dans le sac.

> [!TIP]
> Réglez le plancher de batterie à un niveau de confiance (disons 20 %) et une minuterie d'extinction automatique, et vous pouvez faire tout ce qui précède sans surveiller la batterie.

## Comment ça marche

`caffeinate` et les assertions d'alimentation qu'il utilise ne peuvent pas passer outre le déclencheur matériel de fermeture du capot, donc un capot fermé met toujours le Mac en veille. Le seul réglage système qui le contourne est `pmset disablesleep`, qui bascule le drapeau `SleepDisabled` du noyau. Sleepless le bascule depuis un interrupteur natif, relit la valeur en direct pour que l'interface ne mente jamais, et le rétablit à votre plancher de batterie, en mode Économie d'énergie, ou à la fin de la minuterie. Un redémarrage le réinitialise également.

Comme une application graphique ne peut pas saisir de mot de passe, l'installateur ajoute une règle `/etc/sudoers.d` au périmètre strict (propriété de root, `0440`) qui autorise **exactement deux commandes et rien d'autre** :

```
<you> ALL=(root) NOPASSWD: /usr/bin/pmset -a disablesleep 0, /usr/bin/pmset -a disablesleep 1
```

- **Elle ne peut pas être élargie.** `sudoers` compare les arguments littéralement sans jokers, donc toute autre commande redemande un mot de passe.
- **Aucun démon, aucun script auxiliaire** qu'un attaquant pourrait détourner. Elle appelle directement le `/usr/bin/pmset` d'Apple avec un tableau argv, sans shell.
- **Toujours réversible.** Un redémarrage réinitialise le drapeau, le plancher de batterie et la minuterie le désactivent, et `./uninstall.sh` supprime l'autorisation et le prouve.

Le modèle de menace complet, les preuves bien réelles (mais non documentées) de `disablesleep`, la raison pour laquelle l'application ne peut pas figurer sur le Mac App Store, et la marche à suivre pour vérifier un téléchargement se trouvent dans **[SECURITY.md](SECURITY.md)** et **[docs/AUDIT.md](docs/AUDIT.md)**.

## FAQ

<details>
<summary><b>Comment garder mon MacBook éveillé capot fermé sans écran externe ?</b></summary>

Installez Sleepless, cliquez sur la tasse de café dans la barre des menus, activez l'interrupteur et fermez le capot. Il garde le Mac éveillé sur batterie sans écran externe, en utilisant `pmset disablesleep`. Aucune fiche HDMI factice ni adaptateur clamshell n'est nécessaire.
</details>

<details>
<summary><b>Pourquoi mon MacBook se met-il en veille à la fermeture du capot, même avec Amphetamine ou KeepingYouAwake ?</b></summary>

Parce que ces outils reposent sur les assertions d'alimentation de macOS, qui arrêtent la minuterie d'inactivité mais ne peuvent pas passer outre le déclencheur matériel de fermeture du capot. KeepingYouAwake enveloppe `caffeinate`, dont le mainteneur confirme qu'il « doesn't support this » ([issue #66](https://github.com/newmarcel/KeepingYouAwake/issues/66)). Amphetamine essaie, mais est largement signalé comme défaillant sur Apple Silicon lors d'un changement de source d'alimentation. `pmset disablesleep`, que Sleepless utilise, est un réglage de plus bas niveau capable de passer outre la veille à la fermeture du capot.
</details>

<details>
<summary><b>Est-ce que <code>pmset disablesleep</code> fonctionne encore sur Apple Silicon (M1/M2/M3) ?</b></summary>

`pmset -a disablesleep 1` positionne toujours le drapeau `SleepDisabled` sur Apple Silicon et, d'après des retours de première main, garde un MacBook éveillé capot fermé sur batterie, mais Apple ne documente pas officiellement ce réglage, donc son comportement exact peut varier selon le modèle et la version de macOS. Vérifiez-le sur votre propre machine avec `pmset -g | grep SleepDisabled` (il devrait afficher `1`). La plupart des affirmations selon lesquelles cela « ne fonctionne plus sur M1/M2/M3 » décrivent en réalité `caffeinate` ou des applications basées sur caffeinate (Amphetamine, KeepingYouAwake), qui n'ont jamais été capables d'empêcher la veille capot fermé, un mécanisme différent, et non une régression de `pmset disablesleep`.
</details>

<details>
<summary><b>Puis-je garder mon MacBook éveillé sur batterie capot fermé ?</b></summary>

Oui. C'est tout l'intérêt de Sleepless, et c'est ce qui le distingue des applications basées sur `caffeinate`. Réglez un plancher de batterie et une minuterie d'extinction automatique pour qu'il ne puisse pas vider le Mac pendant qu'il tourne sans surveillance.
</details>

<details>
<summary><b>Quelle est la différence entre <code>caffeinate</code> et la désactivation de la veille à la fermeture du capot ?</b></summary>

`caffeinate` maintient une assertion d'alimentation qui empêche la veille d'*inactivité* tant que le capot est ouvert, et il ne peut pas empêcher un capot fermé de mettre le Mac en veille. Désactiver la veille à la fermeture du capot avec `pmset disablesleep` bascule un drapeau du noyau qui passe outre le déclencheur de fermeture du capot lui-même, ce qui explique pourquoi cela fonctionne capot fermé.
</details>

<details>
<summary><b>En quoi Sleepless est-il différent d'Amphetamine et de KeepingYouAwake ?</b></summary>

Sleepless fait une seule chose, l'anti-veille capot fermé sur batterie, avec une conception axée sur la sécurité : une minuterie d'extinction automatique, une coupure au plancher de batterie, une extinction automatique en mode Économie d'énergie et une réinitialisation au redémarrage. Il est open source (MIT), un seul petit fichier AppKit sans démon ni kext, et il utilise `pmset disablesleep` plutôt que la couche d'assertions qui limite les autres.
</details>

<details>
<summary><b>Est-il sûr de faire tourner un MacBook capot fermé ? Va-t-il surchauffer ou vider la batterie ?</b></summary>

C'est sûr pour des tâches légères et sans surveillance comme des téléchargements, des synchronisations ou un point d'accès. Une charge soutenue et intense capot complètement fermé réduit la circulation de l'air, donc faites preuve de jugement dans ces cas-là. Pour protéger la batterie, Sleepless se désactive au plancher que vous avez défini et en mode Économie d'énergie, et la minuterie d'extinction automatique limite la durée pendant laquelle il reste actif.
</details>

<details>
<summary><b>Ai-je besoin d'une fiche HDMI factice pour utiliser le mode clamshell ?</b></summary>

Non. Le mode clamshell officiel d'Apple nécessite une alimentation externe et un écran, mais Sleepless garde le Mac éveillé capot fermé sur la seule batterie, sans écran et sans dongle HDMI.
</details>

<details>
<summary><b>Sleepless nécessite-t-il sudo, une extension noyau ou un démon en arrière-plan ?</b></summary>

Il nécessite une seule autorisation `sudo` au périmètre strict (deux commandes `pmset` exactes, rien d'autre) pour qu'une application graphique puisse basculer le réglage sans invite de mot de passe. Il n'y a aucune extension noyau ni aucun démon en arrière-plan. Toute l'application tient dans un seul fichier AppKit.
</details>

<details>
<summary><b>La tasse de café n'apparaît pas dans ma barre des menus.</b></summary>

macOS 26 peut masquer les éléments de la barre des menus. Vérifiez les Réglages Système (Centre de contrôle / Barre des menus) et autorisez Sleepless à afficher son élément. Confirmez qu'il tourne avec <code>pgrep -x Sleepless</code>.
</details>

<details>
<summary><b>Comment arrêter Sleepless et rétablir la veille normale ?</b></summary>

Désactivez l'interrupteur, ou laissez la minuterie d'extinction automatique ou le plancher de batterie le couper, et la veille normale revient immédiatement. Un redémarrage le réinitialise également, et `./uninstall.sh` supprime l'application, l'élément de connexion et l'autorisation sudoers, puis prouve que l'autorisation a disparu.
</details>

<details>
<summary><b>Puis-je faire tourner des agents IA ou de longues tâches toute la nuit capot fermé ?</b></summary>

Oui. Activez Sleepless, réglez un plancher de batterie, fermez le capot, et une exécution d'agent, une compilation, un rendu ou une tâche d'entraînement continue de tourner. Branchez l'alimentation pour une nuit entière, ou restez sur batterie avec un plancher et une minuterie pour qu'il s'arrête de lui-même avant que la batterie ne soit basse.
</details>

<details>
<summary><b>Pourquoi n'est-il pas notarisé ?</b></summary>

C'est un outil personnel et open source sans identifiant Apple Developer payant, il est donc signé de façon ad-hoc. Compilez depuis les sources pour contourner entièrement Gatekeeper, ou utilisez le flux **Ouvrir quand même** pour l'application préfabriquée. La notarisation est documentée comme une prochaine étape prévue dans [docs/AUDIT.md](docs/AUDIT.md).
</details>

<details>
<summary><b>Fonctionne-t-il sur Intel ou sur d'anciennes versions de macOS ?</b></summary>

Il est vérifié sur **macOS 26 Apple Silicon**. `disablesleep` n'est pas documenté, donc les autres versions ou matériels ne sont pas garantis. Essayez-le et faites un retour, les rapports honnêtes sont les bienvenus.
</details>

## Contribuer

Les tickets et les PR sont les bienvenus, en particulier les traductions et les rapports de test depuis d'autres matériels. Consultez [CONTRIBUTING.md](CONTRIBUTING.md) et le [Code de conduite](CODE_OF_CONDUCT.md). Sleepless reste délibérément petit.

## Licence

[MIT](LICENSE) © 2026 Adam Boudjemaa.

<p align="center">
  <sub>Si Sleepless vous a évité un détour par le Terminal, une ⭐ aide d'autres personnes à le trouver.</sub>
</p>
