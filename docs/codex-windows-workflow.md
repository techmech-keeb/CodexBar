---
summary: "Thin Codex working guide for this fork's Windows-port effort: scope, checks, restrictions, and reference-only external repos."
read_when:
  - Starting a Codex Cloud task on the Windows port
  - Deciding what Codex may change vs. reference in this fork
---

# Codex 作業導線（Windows 移植フォーク用）

このフォークで Codex を使って Windows 対応を進めるときの薄い作業導線。
共通ルールの複製は避け、このリポジトリ固有の目的・境界・確認コマンドに絞る。
運用ルールの正本は `techmech-keeb/AI-agent-playbook`（特に
`tools/codex/START-HERE.md`）、技術的事実は `techmech-keeb/knowledge-base`。

## Repository purpose（このフォークの目的）

upstream `steipete/CodexBar`（macOS メニューバーアプリ）の**フォーク**で、
共有エンジン（`CodexBarCore`）と CLI（`CodexBarCLI`）を土台に **Windows 対応**を
進める。方針の正本は [`docs/windows-port-feasibility.md`](windows-port-feasibility.md)。
macOS アプリ（`Sources/CodexBar`）は回帰リスクを避けるため原則据え置き、
Windows 作業は共有層の platform seam と別 tray シェルに寄せる。

## Working policy

- Codex Cloud では**変更対象リポジトリをこのフォーク1つ**に絞る。
  `AI-agent-playbook` と `knowledge-base` は参照専用（変更・コミット・PR に混ぜない）。
- 変更前に「目的・影響範囲・確認する既存ファイル/ルール・作業方針・実行予定の確認・
  未確認事項/リスク」を簡潔に整理してから着手する。
- 既存の `AGENTS.md`（リポジトリルート）の規約を優先する。矛盾する場合は現行仕様を優先。
- Windows 作業は既存の `#if os(Linux)` seam（`CodexBarCore` に約20か所）の書き方に倣い、
  `#if os(Windows)` を共有層に足す。AppKit / Security / WebKit / POSIX 専用 API を
  共有コードへ持ち込まない。
- 無関係な変更・大規模整形・依存追加を避ける（依存追加は要確認、下記 Restrictions）。

## 意思決定と確認の基準（重要 / 自律で進める範囲）

このフォークのオーナーは**プログラマーではない**。細かい実装仕様を都度質問しても
判断できないため、Codex は次の基準で「聞く／自律で進める」を切り分ける。
**原則は「十分に検討したうえで自律で進め、判断と理由を最終報告に残す」。**

### 人間に確認する（着手前に止めて聞く）— *動作・体験に影響する判断だけ*

- ユーザーが**見る・触れる**ものが変わる: tray アイコン/フライアウトの見え方、
  表示するプロバイダや並び、ラベル/文言、エラー表示の出し方、リフレッシュ間隔の
  既定値、通知の有無。
- **利用手順・前提が変わる**: インストール/更新方法（インストーラ形式・配布チャネル）、
  必要な権限、サインインやブラウザ Cookie 連携の要否、対応プロバイダの範囲（どれを
  最初の Windows 版に入れるか）。
- **後戻りしにくい/リスクがある**: 秘密情報の保存先方針、非互換な設定ファイル変更、
  データ削除を伴う挙動、外部公開を伴う操作。

確認するときは**コード用語ではなく体験の言葉で**、選択肢を2〜3個に絞り、推奨案を添えて
1回で聞く（例:「A: 主要5プロバイダだけ先に対応 / B: Cookie 不要な全プロバイダ」）。
細部を列挙して都度聞かない。

### 自律で進める（聞かずに決め、理由を報告に書く）— *内部実装は任せる*

- コード構造・命名・seam の設計（`CodexBarProcessRunner` 等のインターフェース形）、
  リファクタ、テスト方針、ビルド/リンク設定。
- どの Windows API/手法を使うか（SQLite のリンク方法、パス解決、資格情報バックエンドの
  実装選択など）、依存の内部的な扱い（seam 化を含む。ただし**新規依存の追加そのものは要確認**）。
- ユーザーから見えない挙動の等価な作り替え。

判断に迷い、かつ後戻り可能・低リスクなら、**止めて聞かずに妥当案で進め、代替案と理由を
報告に明記**する（「聞かずに決めた点」として列挙）。体験に関わるか不明なときだけ、上記
「確認する」基準に当てはめて短く確認する。

## External context

必要時のみ参照専用で参照する。

- `techmech-keeb/AI-agent-playbook`：Codex 作業ルール・プロンプト・Skill の正本。
  Windows 作業開始時は `tools/codex/START-HERE.md` と
  `prompts/implement-feature.md` / `prompts/fix-ci.md` を使う。
- `techmech-keeb/knowledge-base`：技術的事実・過去判断・用語の正本。

採用した外部知見は、参照元と採用理由を最終報告に含める。

## Required checks

変更内容に応じて実行する（Windows CI は未整備のため、当面は下記が Windows 前の関所）。

- `swift build --product CodexBarCLI`（共有層とCLIのビルド）
- `swift build -c release --product CodexBarCLI --static-swift-stdlib`（リリース相当）
- `swift test --parallel`（Linux/共有テスト。Windows 実機前の互換プロキシとして）
- `make check`（SwiftFormat + SwiftLint。macOS ローカルがある場合）

実行できない確認（Windows 実機ビルド等）は、その旨と理由を報告に明記する。
Windows 固有の失敗を検証する際は、まず
[`docs/windows-port-feasibility.md`](windows-port-feasibility.md) の
「Compatibility findings」で既知ブロッカー（SweetCookieKit 無条件依存・SQLite リンク・
Commander）を確認し、既知分は「発見」として扱わない。

## Repository-specific restrictions

- **macOS 専用ターゲットを壊さない**：`Sources/CodexBar`（アプリ）、`CodexBarWidget`、
  `CodexBarClaudeWatchdog`、`CodexBarClaudeWebProbe` と Sparkle/KeyboardShortcuts/Vortex
  依存は Windows 作業で触れない（`Package.swift` の `#if os(macOS)` ブロックは維持）。
- **依存を勝手に追加しない**（既存 `AGENTS.md` の Agent Notes に従う）。SweetCookieKit を
  Windows 化する場合も、seam 化（`CodexBarCookieStore`）を優先し、まず要確認。
- **プロバイダのデータ分離を守る**：あるプロバイダの identity/plan/usage を別プロバイダの
  値で表示しない（既存 `AGENTS.md` の siloed 原則）。
- 秘密情報（APIキー・トークン・cookie・実アカウントの usage）をログ・診断・JSON 出力・
  コミットに残さない。テストは fake store / stub を使い、OS の資格情報プロンプトを出さない。
- 生成物（`appcast.xml`、ルートの zip 等）はリリース時以外編集しない。

## Reporting

最終報告は日本語で以下をまとめる。

- 変更内容
- 変更ファイル
- 実行した確認（コマンドと結果。未実行は理由も）
- 未確認事項 / リスク
- 外部リポジトリを参照した場合の参照元・採用理由
- **聞かずに自律で決めた点**（判断・代替案・理由）
- **人間に確認したい点**（あれば。体験に影響するもののみ、選択肢と推奨付き）
- `knowledge-base` / `AI-agent-playbook` へ反映すべき知見の**候補**（還流自体は別タスク）

## Codex への依頼文（コピペ用テンプレート）

作業依頼のたびに毎回この方針を説明しなくて済むよう、依頼文の冒頭に貼る定型。

```text
このリポジトリ（CodexBar フォーク）を変更対象として、Windows 対応を進めてください。
作業前に docs/codex-windows-workflow.md と docs/windows-port-feasibility.md を読んでください。

進め方（重要）:
- 私はプログラマーではありません。内部実装（コード構造・命名・seam 設計・テスト方針・
  ビルド/リンク設定・使う Windows API 等）は、十分に検討したうえで自律で決めて進めてください。
  そのつど細かい仕様は聞かないでください。決めた点と理由は最終報告にまとめてください。
- 確認してよいのは「動作・体験に影響する判断」だけです（表示の見え方、対応プロバイダの範囲、
  インストール/更新方法、必要な権限、後戻りしにくい/リスクのある変更）。その場合も、コード用語
  ではなく体験の言葉で、選択肢2〜3個と推奨案を添えて1回にまとめて聞いてください。
- AI-agent-playbook と knowledge-base は参照専用です。変更・コミット・PR に混ぜないでください。

まず「目的・影響範囲・確認する既存ファイル・作業方針・聞かずに決める予定の点・
（あれば）確認したい体験上の点」を簡潔に整理してから着手してください。
報告は日本語でお願いします。
```
