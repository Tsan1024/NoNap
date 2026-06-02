# Listings & directories

Where Sleepless can be listed, what is automatable, and ready-to-fire drafts for the
places that need your own account. The narrative launch posts (Show HN, Reddit, Product
Hunt, AlternativeTo, MacUpdate) live in [LAUNCH.md](LAUNCH.md); this file is the directory
and awesome-list map.

Nothing here is auto-posted to a human channel. The awesome-list PRs and the megalist issue
are pure GitHub contributions and were opened from this repo's owner account (see status
below). Everything that needs a personal account on another site is a draft for you to fire.

Repo: https://github.com/Aboudjem/Sleepless · as of 2026-06.

## A. GitHub-native (owner self-serve)

| Item | Status |
|---|---|
| Topics (16/20: added apple-silicon, disablesleep, closed-display-mode, amphetamine-alternative, prevent-sleep) | Done |
| Repo description (≤350 chars) | Done |
| Discussions enabled | Done |
| Social preview image (1280×640) | Upload in repo Settings → Social preview |
| Homepage URL = GitHub Pages site | Set after Pages goes live |

## B. Awesome-list PRs (automatable, opened from the owner account)

One correct, rule-compliant entry per list. A spammy or wrong entry backfires as a fake
signal, so each follows the list's own contributing rules exactly. PR URLs are recorded in
the run report.

### 1. serhii-londar/open-source-mac-os-apps
Edit `applications.json` (not README, it is generated). Add to the `applications` array with
category `"menubar"` (lowercase). Descriptions end with a period. One PR.
```json
{
    "short_description": "Keep your MacBook awake with the lid closed, on battery, with no external display, with a battery-floor auto-off.",
    "categories": ["menubar"],
    "repo_url": "https://github.com/Aboudjem/Sleepless",
    "title": "Sleepless",
    "languages": ["swift"]
}
```
(Optional `icon_url`: a raw GitHub URL to an icon committed in this repo, e.g.
`https://raw.githubusercontent.com/Aboudjem/Sleepless/main/assets/Sleepless-1024.png`.)

### 2. jaywcjlove/awesome-mac
Edit `README.md` under `### System Related Tools`, alphabetical, insert just above `Sleepr`.
Mirror into `README-zh.md` / `README-ja.md` / `README-ko.md` (maintainer prefers all locales
synced). Description ends with a period.
```markdown
* [Sleepless](https://github.com/Aboudjem/Sleepless) - Keep your MacBook awake with the lid closed on battery, with a battery-floor auto-off. [![Open-Source Software][OSS Icon]](https://github.com/Aboudjem/Sleepless) ![Freeware][Freeware Icon]
```
`[OSS Icon]` and `[Freeware Icon]` reference labels are already defined in the file.

### 3. iCHAIT/awesome-macOS
Edit `README.md` under `### Utilities` (there is no Menu Bar section), alphabetical, insert
between `ShiftIt` and `SlowQuitApps`. Title case, description ends with a period, fill the PR
template fully (the maintainer closes non-compliant PRs). Native AppKit passes the no-Electron
rule.
```markdown
- [Sleepless](https://github.com/Aboudjem/Sleepless) - Menu bar utility that keeps your MacBook awake with the lid closed on battery, with a battery-floor auto-off. [![Open-Source Software][OSS Icon]](https://github.com/Aboudjem/Sleepless) ![Freeware][Freeware Icon]
```

### 4. jaywcjlove/awesome-swift-macos-apps
Edit `README.md` under `## Menubar` (not strictly alphabetical; place near `StayUp`). Uses
auto star + last-commit badges, no text badges. This list already has near-identical apps
(Aquarium, StayAwake, StayUp), so **lead with the battery-floor auto-off differentiator** to
avoid a redundancy flag.
```markdown
- [Sleepless](https://github.com/Aboudjem/Sleepless) <img align="bottom" height="13" src="https://badgen.net/github/stars/Aboudjem/Sleepless?style=flat&label=" /> <img align="bottom" height="13" src="https://img.shields.io/github/last-commit/Aboudjem/Sleepless?style=flat&label=" /> - Menu bar utility that keeps your MacBook awake with the lid closed on battery, with a battery-floor auto-off.
```

## C. Mac-Menubar-Megalist (issue, not PR)

Open an issue at https://github.com/SKaplanOfficial/Mac-Menubar-Megalist/issues/new. The
keep-awake cluster is `## Utilities → #### Caffeinators`. **Disambiguate from two existing
look-alikes**: "Sleepless Mac" (github.com/gsurma/sleepless_mac) and "Sleep Blocker (Sleepless
Mode)" (App Store). No entry named exactly "Sleepless" exists yet.

- **Title:** `Add app: Sleepless`
- **Body:**
  > **App Name:** Sleepless
  > **URL:** https://github.com/Aboudjem/Sleepless
  > **Website:** https://aboudjem.github.io/Sleepless/
  > **Category:** Utilities → Caffeinators
  > **License:** MIT (free, open source)
  >
  > Paste-ready list line:
  > `- [Sleepless](https://github.com/Aboudjem/Sleepless) by [Adam Boudjemaa](https://github.com/Aboudjem). Keeps your MacBook awake with the lid closed on battery, with no external display and a battery-floor auto-off. Free, open source.`
  >
  > Note: this is "Sleepless" by Aboudjem, distinct from the existing "Sleepless Mac"
  > (gsurma) and "Sleep Blocker (Sleepless Mode)" entries already in the Caffeinators list.

## D. Human-account drafts (fire these yourself; do not automate)

### MacMenuBar.com
Submit at https://macmenubar.com/submit-your-menu-bar-app/ (menu-bar-only directory; check it
is not already listed first).
> **Name:** Sleepless
> **Category:** Utilities / Menu Bar
> **Description:** Open-source macOS menu-bar app that keeps your MacBook awake with the lid
> closed, on battery, with no external display, using `pmset disablesleep`. Adds an auto-off
> timer and a battery-floor cutoff so it is safe to forget. Native AppKit, MIT licensed.
> **Link:** https://github.com/Aboudjem/Sleepless

### Uptodown
https://en.uptodown.com/developers-console (must be the rights-holder; icon ≥256px; upload the
`.app`/zip). Likely accept.
> Same description as MacMenuBar. Use `assets/Sleepless-1024.png` as the icon.

### Softpedia (Mac)
https://mac.softpedia.com/ (editor-reviewed). The "100% Clean" badge is a nice README asset.
> Category: Utilities. Description as above. Note macOS 26 / Apple Silicon requirement.

### opensourcealternative.to
https://www.opensourcealternative.to/submit (OSS-only; Sleepless qualifies).
> Position as an open-source alternative to Amphetamine and KeepingYouAwake. Tags: macOS,
> menu-bar, keep-awake, productivity, open-source.

### macosmenubar.com
Second menu-bar directory; submission mechanism is uncertain. Check for a submit form before
spending time.

### r/SideProject
Self-post; promotion is welcomed here. Lead with the demo GIF.
> **Title:** Sleepless – a tiny open-source Mac menu-bar app that keeps your MacBook awake with the lid closed (on battery, no external display)
> **Body:** I kept typing `sudo pmset -a disablesleep 1` to keep my MacBook running with the
> lid shut for overnight jobs, then forgetting to turn it back off. Sleepless is that command
> as a one-click menu-bar switch, with an auto-off timer and a battery-floor cutoff so it can't
> drain the battery. Native AppKit, no daemon, no kext, MIT. Build from source or `brew install
> --cask aboudjem/tap/sleepless`. Feedback welcome. https://github.com/Aboudjem/Sleepless

### r/swift
Frame as an engineering write-up (90/10 etiquette: mostly substance, light promo). Read the
sidebar first.
> **Title:** How I keep a MacBook awake lid-closed from a single-file AppKit menu-bar app (`pmset disablesleep` + a scoped sudoers grant)
> **Body:** A short write-up of the mechanism (`pmset disablesleep` sets the kernel
> `SleepDisabled` flag, unlike `caffeinate` which can't override lid-close), how a GUI app runs
> it passwordless via a tightly scoped `/etc/sudoers.d` rule (two exact commands, no wildcards),
> and the Swift 6 single-file `@main` setup. Source: https://github.com/Aboudjem/Sleepless

### MacRumors macOS Apps forum
Evergreen thread, ranks in Google. Post in the macOS Apps forum with the demo + a short,
honest description (ad-hoc signed, undocumented `disablesleep`, verified on macOS 26).

### Lobsters
Invite-gated, so you need a member invite. Good fit for the `pmset`/Swift systems story. Tag
`mac`, `programming`. Post the repo or a short write-up, not a marketing blurb.

### Editorial (email, low hit-rate)
9to5Mac (Indie App Spotlight, iOS-leaning so uncertain), MacStories, MacSparky, SharewareOnSale.
Pitch the lid-closed-on-battery angle + the security model, with the demo GIF.

## E. Blocked / cannot submit

- **Homebrew core cask**: self-submission needs 90 forks / 90 watchers / 225★ (or 75★ if an
  unaffiliated person submits). Sleepless is far under, so stay on `aboudjem/tap`. Revisit after
  225★. https://docs.brew.sh/Acceptable-Casks
- **Changelog Nightly**: algorithmic from GitHub Archive; can't submit, only earned via a
  star-velocity spike. Coordinate with a launch.
- **Slant**: a conflict-of-interest rule bars the owner from self-adding; needs a neutral user.
- **matteocrippa/awesome-swift**: curates libraries, not apps; out of scope.
- **Mac App Store**: permanently ineligible (root escalation, see SECURITY.md). Not a channel.
