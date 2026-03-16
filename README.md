# ClipAI

**⌘⌥I** でクリップボードの内容をAIに即座に聞けるmacOSアプリ。

Spotlight のように一瞬で現れて、一瞬で消える。それだけ。

## Demo

<!-- スクリーンショットやGIFをここに -->

## Install

1. [Releases](https://github.com/preferred-inc/ClipAI/releases) から `.dmg` をダウンロード
2. `ClipAI.app` を Applications にドラッグ
3. 起動 → メニューバーの ✦ から Settings → API Keyを設定

## Usage

1. テキストをコピー
2. **⌘⌥I**
3. 回答がストリーミング表示される

プロンプト欄に質問を入力すれば、クリップボードの内容をコンテキストとして使える。
空欄のままなら要約・説明を自動で返す。

**Esc** で閉じる。パネル外をクリックしても閉じる。

## Features

- Spotlight風フローティングパネル
- Claude API ストリーミング応答
- メニューバー常駐（Dockに出ない）
- ネイティブ Swift/SwiftUI（軽量・高速）
- バックグラウンドでのクリップボード監視なし

## Requirements

- macOS 13.0+
- [Anthropic API Key](https://console.anthropic.com/settings/keys)

## Build

```bash
git clone https://github.com/preferred-inc/ClipAI.git
cd ClipAI
xcodegen generate
xcodebuild -scheme ClipAI -configuration Release build
```

## Release Build (署名 + DMG)

```bash
./scripts/build-release.sh --sign
./scripts/build-release.sh --notarize --apple-id=YOU --team-id=TEAM --app-password=PASS
```

## Privacy

- クリップボードは **⌘⌥I を押したときだけ** 読み取る
- データはAnthropicのAPIにのみ送信される
- アナリティクス・テレメトリなし

詳細: [Privacy Policy](privacy-policy.md)

## License

MIT
