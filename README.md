# VoicePolishInput

Push-to-talk speech → live draft → (stop) polish → insert into the currently focused text field.

音声入力をトグルし、下書き表示しながら、停止時に整形して現在フォーカス中の入力欄へ挿入します。

## Quick Install / 最短導入

### From local clone / ローカルcloneから

```sh
./scripts/install.sh
```

### One-liner from GitHub / GitHubからワンライナー

```sh
git clone https://github.com/taaaaryu/voice-polish-input.git && cd voice-polish-input && ./scripts/install.sh
```

### Update / 更新

```sh
./scripts/update.sh
```

### Uninstall / 削除

```sh
./scripts/uninstall.sh
```

### Start localhost admin page (Docker) / 管理ページ起動（Docker）

```sh
./scripts/admin-up.sh
```

Open: `http://localhost:8765`

Stop:

```sh
./scripts/admin-down.sh
```

## Features / 機能

- `F13` を押している間だけ録音（離すと停止）
- 録音中はメニューバーUIに下書きを表示
- 停止後にテキスト整形して、フォーカス中の入力欄へ挿入
- Hold `F13` to record, release to stop
- Live draft appears while speaking
- On stop, text is polished and inserted into the focused text field
- 設定画面でフィラー語とユーザー辞書（置換ルール）を管理
- Manage filler words and custom replace rules in Settings
- ローカルホスト管理ページ（Docker）で辞書編集と履歴確認
- Localhost admin page (Docker) for dictionary and history

## Requirements / 動作要件

- macOS 26 + Apple Silicon 推奨
- Xcode 26 SDK（`SpeechAnalyzer` / `FoundationModels` を使う場合）
- Apple Intelligence 有効（オンデバイス整形を使う場合）
- Recommended: macOS 26 + Apple Silicon
- Xcode 26 SDK for `SpeechAnalyzer` / `FoundationModels`
- Apple Intelligence enabled for on-device polishing

## Build / ビルド

```sh
swift build
```

`xcode-select` が CLT を向いている場合:

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift build
```

If needed, switch globally:

```sh
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
```

## Run / 起動

```sh
swift run VoicePolishInput
```

`xcode-select` 未切替なら:

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift run VoicePolishInput
```

## Shared State File / 共有データファイル

アプリ本体とDocker管理ページは同じ状態ファイルを使います:

- `~/Library/Application Support/VoicePolishInput/state.json`

このファイルに以下が保存されます:

- `fillerWords`
- `replacementEntries`
- `historyEntries`（音声入力後の履歴。raw/polished/時刻/挿入成否/エラー）

## Permissions Setup / 権限設定

初回起動時または設定画面で、以下を許可してください:

- Microphone（マイク）
- Speech Recognition（音声認識）
- Accessibility（入力欄へ直接挿入）
- Input Monitoring（キーストロークfallbackを使う場合のみ）

権限は `System Settings > Privacy & Security` から再設定できます。

## How To Use / 使い方

1. `swift run VoicePolishInput` で起動（Dockには常駐表示されず、メニューバーに出ます）
2. チャットなど、入力したいテキスト欄にカーソルを置く
3. `F13` を押し続けて録音開始（離すまで録音）
4. 話す（メニューバーUIで下書き確認）
5. 同じホットキーで録音停止
6. 自動整形後、フォーカス中の入力欄に挿入される
7. 辞書を編集したい場合はメニューバーの `VoicePolishInput` を開いて `Open Management` を押し、以下を編集:
   - Filler Words: 削除したい口癖語
   - User Dictionary: `From -> To` 置換ルール
8. ブラウザで管理したい場合は `./scripts/admin-up.sh` を実行し、`http://localhost:8765` を開く
9. `Speech History` で音声入力後の履歴（日時、raw、polished、挿入成否、エラー）を確認
10. メニューバーUIの `Key Debug` に、直近のキーコード（`keyCode=...`）が表示されるのでホットキー検証に使える

## Dictation Key (Fn Fn) / 音声入力キー(Fn Fn)について

macOS標準の Dictation キー動作は、サードパーティアプリから安定してフックできません。
Fn Fn を使いたい場合は、Karabiner-Elements などで `F13` へリマップし、`押下時=F13 down / 離した時=F13 up` になるよう設定してください。

## Engine Selection / エンジン切り替え

- macOS 26 SDK でビルドし、実行環境が macOS 26 の場合:
  - 音声認識: `SpeechAnalyzer` + `SpeechTranscriber`
  - 整形: `FoundationModels`（利用可能時）
- 条件を満たさない場合:
  - 音声認識: `SFSpeechRecognizer` に自動フォールバック
  - 整形: ルールベース整形のみ

## Troubleshooting / よくある問題

- `xcodebuild requires Xcode`:
  - `xcode-select` が CLT を向いています。上記 `DEVELOPER_DIR=...` 付きコマンドか `sudo xcode-select -s ...` を使用してください。
- 入力欄に挿入されない:
  - Accessibility 権限を確認してください。アプリによっては AX 挿入が制限される場合があります。
- 録音が始まらない:
  - Microphone / Speech Recognition 権限を確認し、アプリを再起動してください。
- 管理ページが開かない:
  - Docker Desktop が起動しているか確認してください。
  - `./scripts/admin-up.sh` を再実行してください。
