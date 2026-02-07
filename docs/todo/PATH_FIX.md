# PATH設定の問題解決

スクリプトを実行しても`claude: command not found`エラーが出る場合、現在のシェルセッションにPATHが反映されていない可能性があります。

## 即座に解決する方法

インスタンス内のターミナルで、以下のコマンドを**直接実行**してください：

```bash
# 方法1: 直接PATHを設定（推奨）
export PATH="$PATH:$HOME/.local/bin"

# 確認
claude --version
```

これで即座に動作するはずです。

## 永続化する方法

現在のセッションで動作確認できたら、永続化します：

```bash
# ~/.bashrcに追加（まだ追加されていない場合）
grep -q '.local/bin' ~/.bashrc || echo 'export PATH="$PATH:$HOME/.local/bin"' >> ~/.bashrc

# 確認
cat ~/.bashrc | grep '.local/bin'
```

## 新しいシェルセッションで確認

次回SSH接続した際に自動的にPATHが設定されるようにするには：

```bash
# ~/.bashrcを読み込む
source ~/.bashrc

# または新しいシェルを開始
exec bash

# 確認
claude --version
```

## トラブルシューティング

### それでも動作しない場合

```bash
# 1. インストール先を確認
ls -la ~/.local/bin/claude

# 2. 直接実行してみる
~/.local/bin/claude --version

# 3. PATHを確認
echo $PATH

# 4. シンボリックリンクを確認
ls -la ~/.local/bin/claude
readlink -f ~/.local/bin/claude
```

### 別の場所にインストールされている場合

```bash
# システム全体を検索
find ~ -name "claude" -type f 2>/dev/null

# 見つかったパスをPATHに追加
export PATH="$PATH:見つかったパス"
```

