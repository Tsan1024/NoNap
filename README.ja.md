<!-- Language switcher. Keep this row identical across every README.<lang>.md. -->
<p align="center">
  <a href="README.md">English</a> &nbsp;·&nbsp;
  <a href="README.zh-CN.md">简体中文</a> &nbsp;·&nbsp;
  <a href="README.es.md">Español</a> &nbsp;·&nbsp;
  <b>日本語</b> &nbsp;·&nbsp;
  <a href="README.fr.md">Français</a> &nbsp;·&nbsp;
  <a href="README.de.md">Deutsch</a>
</p>

> この翻訳はコミュニティまたは機械によって作成されたものであり、英語版の README より内容が古い場合があります。正となるのは英語版です。最新かつ正確な情報については [English README](README.md) を参照してください。

<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="assets/hero-dark.gif">
    <source media="(prefers-color-scheme: light)" srcset="assets/hero-light.gif">
    <img alt="Sleepless: keep your Mac awake with the lid closed" src="assets/hero-light.gif" width="780">
  </picture>
</p>

<p align="center">
  <b>Sleepless は、フタを閉じたままでも、バッテリー駆動でも、外部ディスプレイなしでも、MacBook をスリープさせずに動かし続けます。</b><br>
  <sub>ネイティブなメニューバーのスイッチひとつ。自動オフタイマーとバッテリー下限カットオフを備えているので、うっかり空っぽにしてしまう心配もありません。</sub>
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
> 通常、フタを閉じると Mac はスリープします。そして `caffeinate` ベースのアプリ（KeepingYouAwake やその仲間）には、仕様上これを変える**ことはできません**。Sleepless はそれを変えられる唯一の設定、`pmset disablesleep` を切り替え、さらに自動オフタイマーとバッテリー下限カットオフでガードするので、安心して放っておけます。

## Sleepless にできること

Sleepless は、フタを閉じたままでも、バッテリー駆動でも、外部ディスプレイもダミー HDMI プラグもなしで MacBook をスリープさせずに動かし続ける、小さな macOS メニューバーアプリです。メニューバーのコーヒーカップをクリックし、スイッチをひとつ切り替えてフタを閉じれば、Mac は動き続けます。スイッチを戻すか、自動オフタイマーまたはバッテリー下限に任せてオフにすれば、通常のスリープが戻ります。再起動すれば必ずリセットされます。

中身はネイティブな AppKit ファイル 1 つだけ。Dock アイコンも、バックグラウンドのデーモンも、カーネル拡張も、依存関係もありません。ターミナルで `sudo pmset -a disablesleep 1` と打って、そのまま戻し忘れた経験があるなら、Sleepless はそのコマンドを安全なワンクリックのスイッチにしたものです。

## なぜ他のキープアウェイ系アプリにはこれができないのか

ほとんどのキープアウェイ系アプリ（KeepingYouAwake、Caffeine、Theine、Lungo、そして組み込みの `caffeinate` コマンド）は、macOS の power assertion を土台にしています。power assertion は*アイドル*タイマーを止めますが、ハードウェアのフタ閉じトリガーを上書きすることはできないため、フタを閉じれば Mac はやはりスリープします。KeepingYouAwake のメンテナーもこれをはっきり認めています。「caffeinate はこれをサポートしていない。KYA は内部で caffeinate を使っている」（[issue #66](https://github.com/newmarcel/KeepingYouAwake/issues/66)）。

フタ閉じスリープを上書きできる唯一の設定が `pmset disablesleep` で、これはカーネルの `SleepDisabled` フラグを立てます。Sleepless はまさにそれだけを切り替え、値を読み戻すのでメニューバーが嘘をつくことはなく、安全装置でくるんでいます。Amphetamine もフタを閉じたままにできますが、同じ assertion レイヤーの上に作られており、電源が切り替わったときに Apple Silicon で動作しなくなるという報告が広く寄せられています（[Amphetamine-Enhancer #28](https://github.com/x74353/Amphetamine-Enhancer/issues/28)）。

## 機能

|  |  |
|---|---|
| ☕ **スイッチひとつ** | メニューバーのコーヒーカップをクリックし、トグルを切り替えるだけ。空のカップは通常のスリープ、満たされたカップはスリープ防止オン、満たされたカップにドットが付くとバッテリー駆動で安全装置が作動中であることを示します。 |
| ⏲️ **自動オフタイマー** | 1 時間または 2 時間だけスリープを防ぎ、ライブのカウントダウンを表示してから自分でオフになります。タイマーはメモリ上にのみ存在するため、終了や再起動でクリアされます。 |
| 🔋 **バッテリー下限カットオフ** | 下限を選びます（5〜50%、初期値は 15%）。バッテリー駆動時は、空になる前に Sleepless が自分でオフになります。 |
| 🪫 **Low Power Mode で自動オフ** | バッテリー駆動時に Low Power Mode がオンなら、Sleepless は身を引いて Mac をスリープさせます。バッテリー下限と同じ安全設計です。 |
| 🖥️ **ディスプレイ不要、ドングル不要** | 必要なのはフタを閉じてバッテリー駆動にすることだけ。外部モニターも、ダミー HDMI プラグも、クラムシェル用アダプターも要りません。 |
| 🚀 **ログイン時に起動** | 任意で、初期状態はオフ。必ずオフの状態で起動し、勝手にスリープ防止を有効化することはありません。 |
| 🪶 **小さくてネイティブ** | SF Symbols を使った AppKit ファイル 1 つだけ。Dock アイコンなし、バックグラウンドのデーモンなし、kext なし、依存関係なし。 |

## インストール

**Homebrew**（推奨）:

```sh
brew install --cask aboudjem/tap/sleepless
# one-time: add the passwordless grant (it prints exactly what it writes first)
/Applications/Sleepless.app/Contents/Resources/grant.sh
```

**ソースからビルド**（信頼できる方法: 読んで、ビルドして、Gatekeeper の確認も出ません）:

```sh
git clone https://github.com/Aboudjem/Sleepless.git
cd Sleepless && ./install.sh
```

**またはアプリをダウンロード:** [最新リリース](https://github.com/Aboudjem/Sleepless/releases/latest) を入手し、解凍して、`Sleepless.app` を `/Applications` に移動します。アドホック署名されているため、初回起動時は **システム設定 → プライバシーとセキュリティ → このまま開く** で許可してください（右クリック → 開く という従来の方法は macOS 15 で廃止されました）。

リリースをダウンロードしましたか？ Apple アカウントなしで、これが本当にこのプロジェクトのビルドであることを確認できます:

```sh
shasum -a 256 -c SHA256SUMS
gh attestation verify Sleepless-*.app.zip -R Aboudjem/Sleepless
```

検証の手順全体は [docs/AUDIT.md](docs/AUDIT.md) にまとめてあります。

## 使い方

1. メニューバーのコーヒーカップをクリックします。
2. **フタを閉じてもスリープしない** をオンに切り替えます。
3. 必要に応じて 1 時間または 2 時間の自動オフタイマーを選び、信頼できるバッテリー下限を設定します。
4. フタを閉じます。Mac はバッテリー駆動のまま動き続けます。

スイッチをオフにするか、タイマーまたはバッテリー下限に任せてオフにするか、再起動すれば、通常のスリープが戻ります。`./uninstall.sh` ですべて削除され、付与した権限がなくなったことも確認できます。

## Sleepless と他の選択肢の比較

| | **Sleepless** | Amphetamine | KeepingYouAwake | `caffeinate` |
|---|:---:|:---:|:---:|:---:|
| フタを閉じ、モニターなしでスリープしない | ✅ ¹ | ⚠️ ² | ❌ ³ | ❌ |
| バッテリー駆動 | ✅ | ✅ | ✅（フタ開き） | ⚠️ ⁴ |
| 自動オフタイマー | ✅ | ✅ | ✅ | ❌ |
| 低残量で自動オフ | ✅ | ✅ | ✅ | ❌ |
| オープンソース | ✅ MIT | ❌ App Store | ✅ MIT | Apple |
| 価格 | 無料 | 無料 | 無料 | 無料 |

<sub>2026-06 時点。¹ Sleepless はフタ閉じのために用意された仕組みである `pmset disablesleep` を使い、フラグを読み戻して UI に実態を反映します。ただし、どのキープアウェイ系ツールでも挙動はハードウェアと macOS のバージョンに依存します。² Amphetamine はクローズドディスプレイモードを文書化していますが、電源が切り替わったときに Apple Silicon で動作しなくなるという報告が広く寄せられています（[Amphetamine-Enhancer #28](https://github.com/x74353/Amphetamine-Enhancer/issues/28)、開発者自身による[セッション失敗のメモ](https://iffy.freshdesk.com/support/solutions/articles/48001180528)）。アプリ本体はクローズドソースです（オープンなのはサポート用リポジトリだけ）。³ KeepingYouAwake は `caffeinate` をラップしているため、仕様上フタを閉じたまま維持できません（[issue #66](https://github.com/newmarcel/KeepingYouAwake/issues/66)）。⁴ `caffeinate -i` はバッテリー駆動でも動きますが、man ページによれば `-s` は AC 電源時のみです。訂正は歓迎します。</sub>

## こんな使い方に…

- 🤖 **席を離れた後に長時間のジョブを完了させる。** AI エージェントの実行、ビルド、レンダリング、ML 学習、大きな `brew`/`npm` のインストールなど。オンにしてフタを閉じ、カバンに入れて、戻ってくれば完了しています。
- 📡 **移動中にホットスポットを共有する。** Mac のインターネット共有 / 個人用ホットスポットは、フタを閉じても配信し続けます。
- ⬇️ **大きな転送を実行したままにする。** 大容量のダウンロードやアップロード、Time Machine のバックアップが、離席中に完了します。
- 🖥️ **サーバーや SSH セッションを生かしておく。** ローカルの開発サーバー、同期デーモン、リモートセッションが、フタを閉じても到達可能なまま保たれます。
- 🎧 **オーディオを再生し続ける。** 音楽や長いレンダリングが、カバンの中でも再生され続けます。

> [!TIP]
> バッテリー下限を信頼できる値（たとえば 20%）に設定し、自動オフタイマーも組み合わせれば、バッテリーを気にせず上記すべてを実行できます。

## 仕組み

`caffeinate` とそれが使う power assertion では、ハードウェアによるフタ閉じトリガーを上書きできないため、フタを閉じれば Mac は必ずスリープします。これを上書きできる唯一のシステム設定が `pmset disablesleep` で、これはカーネルの `SleepDisabled` フラグを立てます。Sleepless はネイティブなスイッチからこれを切り替え、ライブの値を読み戻すので UI が嘘をつくことはなく、バッテリー下限に達したとき、Low Power Mode のとき、またはタイマーが切れたときに元へ戻します。再起動でもリセットされます。

GUI アプリはパスワードを入力できないため、インストーラーは厳密に範囲を絞った `/etc/sudoers.d` ルール（root 所有、`0440`）を追加します。これが許可するのは**ちょうど 2 つのコマンドだけ、それ以外は一切なし**です:

```
<you> ALL=(root) NOPASSWD: /usr/bin/pmset -a disablesleep 0, /usr/bin/pmset -a disablesleep 1
```

- **範囲を広げられません。** `sudoers` はワイルドカードなしで引数を文字どおり照合するため、他のコマンドはすべて改めてパスワードを要求します。
- 攻撃者に乗っ取られる**デーモンもヘルパースクリプトもありません。** Apple の `/usr/bin/pmset` を argv 配列で直接呼び出します（シェルは介しません）。
- **常に元に戻せます。** 再起動でフラグはリセットされ、バッテリー下限とタイマーでオフになり、`./uninstall.sh` で付与した権限が削除され、それも確認できます。

完全な脅威モデル、文書化されていないが実在する `disablesleep` の証拠、なぜ Mac App Store に出せないのか、そしてダウンロードの検証方法については **[SECURITY.md](SECURITY.md)** と **[docs/AUDIT.md](docs/AUDIT.md)** にまとめてあります。

## FAQ

<details>
<summary><b>MacBook を蓋を閉じたまま、モニターなしでスリープさせない方法は？</b></summary>

Sleepless をインストールし、メニューバーのコーヒーカップをクリックして、スイッチをオンに切り替え、フタを閉じてください。`pmset disablesleep` を使い、外部ディスプレイなしでもバッテリー駆動のまま Mac を起こし続けます。ダミー HDMI プラグもクラムシェル用アダプターも不要です。
</details>

<details>
<summary><b>Amphetamine や KeepingYouAwake を使っても蓋を閉じると MacBook がスリープするのはなぜ？</b></summary>

それらのツールが macOS の power assertion を土台にしているからで、power assertion はアイドルタイマーを止めても、ハードウェアのフタ閉じトリガーを上書きできません。KeepingYouAwake は `caffeinate` をラップしており、そのメンテナーは「これはサポートしていない」と認めています（[issue #66](https://github.com/newmarcel/KeepingYouAwake/issues/66)）。Amphetamine は試みますが、電源が切り替わると Apple Silicon で動作しなくなるという報告が広く寄せられています。Sleepless が使う `pmset disablesleep` は、フタ閉じスリープを上書きできる、より低レベルの設定です。
</details>

<details>
<summary><b><code>pmset disablesleep</code> は Apple Silicon（M1/M2/M3）でもまだ機能する？</b></summary>

`pmset -a disablesleep 1` は Apple Silicon でも `SleepDisabled` フラグを立て、実体験の報告では、バッテリー駆動でフタを閉じたまま MacBook を起こし続けます。ただし Apple はこの設定を公式に文書化していないため、正確な挙動はモデルや macOS のバージョンによって変わる可能性があります。ご自身のマシンで `pmset -g | grep SleepDisabled` を実行して確認してください（`1` と表示されるはずです）。「M1/M2/M3 ではもう動かない」という主張の多くは、実際には `caffeinate` や caffeinate ベースのアプリ（Amphetamine、KeepingYouAwake）の話で、これらはもともとフタ閉じスリープを防げない別の仕組みであり、`pmset disablesleep` のリグレッションではありません。
</details>

<details>
<summary><b>蓋を閉じたまま、バッテリー駆動で MacBook をスリープさせずに使える？</b></summary>

はい。それこそが Sleepless の存在意義であり、`caffeinate` ベースのアプリと一線を画す点です。バッテリー下限と自動オフタイマーを設定しておけば、放置して動かしている間に Mac を空にしてしまうことはありません。
</details>

<details>
<summary><b><code>caffeinate</code> とフタ閉じスリープの無効化は何が違う？</b></summary>

`caffeinate` はフタが開いている間*アイドル*スリープを防ぐ power assertion を保持するだけで、フタを閉じた状態で Mac がスリープするのを止めることはできません。`pmset disablesleep` でフタ閉じスリープを無効化すると、フタ閉じトリガーそのものを上書きするカーネルフラグが立つため、フタを閉じても機能します。
</details>

<details>
<summary><b>Sleepless は Amphetamine や KeepingYouAwake とどう違う？</b></summary>

Sleepless は、バッテリー駆動でのフタ閉じキープアウェイという 1 つのことを、安全第一の設計で行います。自動オフタイマー、バッテリー下限カットオフ、Low Power Mode での自動オフ、そして再起動でのリセットを備えています。オープンソース（MIT）で、デーモンも kext もない小さな AppKit ファイル 1 つであり、他のツールを制限している assertion レイヤーではなく `pmset disablesleep` を使います。
</details>

<details>
<summary><b>MacBook を蓋を閉じたまま使っても安全？ 発熱やバッテリーの消耗は？</b></summary>

ダウンロード、同期、ホットスポットのような軽い無人作業なら安全です。フタを完全に閉じたまま重い負荷を持続させると通気が悪くなるので、そこは見極めが必要です。バッテリーを守るため、Sleepless は設定した下限と Low Power Mode で自分をオフにし、自動オフタイマーがオンでいられる時間を制限します。
</details>

<details>
<summary><b>クラムシェルモードを使うのにダミー HDMI ディスプレイプラグは必要？</b></summary>

いいえ。Apple 公式のクラムシェルモードには外部電源とディスプレイが必要ですが、Sleepless はディスプレイも HDMI ドングルもなしで、バッテリーだけでフタを閉じたまま Mac を起こし続けます。
</details>

<details>
<summary><b>Sleepless に sudo、カーネル拡張、バックグラウンドのデーモンは必要？</b></summary>

GUI アプリがパスワードの確認なしに設定を切り替えられるよう、厳密に範囲を絞った `sudo` 権限が 1 つだけ必要です（ちょうど 2 つの `pmset` コマンドだけ、それ以外は一切なし）。カーネル拡張もバックグラウンドのデーモンもありません。アプリ全体が AppKit ファイル 1 つです。
</details>

<details>
<summary><b>メニューバーにコーヒーカップが表示されません。</b></summary>

macOS 26 はメニューバーの項目を隠すことがあります。システム設定（コントロールセンター / メニューバー）を確認し、Sleepless の項目を表示するよう許可してください。<code>pgrep -x Sleepless</code> で実行中かどうかを確認できます。
</details>

<details>
<summary><b>Sleepless を止めて通常のスリープに戻す方法は？</b></summary>

スイッチをオフにするか、自動オフタイマーまたはバッテリー下限に任せてオフにすれば、すぐに通常のスリープが戻ります。再起動でもリセットされ、`./uninstall.sh` はアプリ、ログイン項目、sudoers の権限を削除したうえで、その権限がなくなったことを確認します。
</details>

<details>
<summary><b>蓋を閉じたまま AI エージェントや長時間ジョブを一晩中走らせられる？</b></summary>

はい。Sleepless をオンにし、バッテリー下限を設定してフタを閉じれば、エージェントの実行、ビルド、レンダリング、学習ジョブが動き続けます。徹夜で回すなら電源につなぐか、下限とタイマーを設定したままバッテリー駆動にしておけば、残量が少なくなる前に自分で止まります。
</details>

<details>
<summary><b>なぜ公証（notarized）されていないのですか？</b></summary>

これは有料の Apple Developer ID を持たない、個人のオープンソースツールなので、アドホック署名になっています。Gatekeeper を完全に回避するにはソースからビルドするか、ビルド済みアプリでは **このまま開く** のフローを使ってください。公証は次の予定ステップとして [docs/AUDIT.md](docs/AUDIT.md) に記載しています。
</details>

<details>
<summary><b>Intel や古い macOS でも動きますか？</b></summary>

検証済みなのは **macOS 26 Apple Silicon** です。`disablesleep` は文書化されていないため、他のバージョンやハードウェアでの動作は保証されません。試してみて、結果を報告してください。正直な報告を歓迎します。
</details>

## コントリビューション

Issue や PR を歓迎します。特に翻訳や、他のハードウェアでのテスト報告は大歓迎です。[CONTRIBUTING.md](CONTRIBUTING.md) と [行動規範](CODE_OF_CONDUCT.md) をご覧ください。Sleepless はあえて小さく保たれています。

## ライセンス

[MIT](LICENSE) © 2026 Adam Boudjemaa.

<p align="center">
  <sub>Sleepless のおかげでターミナルを開かずに済んだなら、⭐ をつけてもらえると他の人にも見つけてもらいやすくなります。</sub>
</p>
