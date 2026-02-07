# インスタンス内での設定手順

SSH接続後、以下の手順で設定を進めてください。

## 1. Git設定

インスタンス内のターミナルで以下を実行：

```bash
chmod +x ~/configure-git.sh
~/configure-git.sh
```

スクリプトが対話的にユーザー名とメールアドレスを尋ねますので、入力してください。

または、手動で設定する場合：

```bash
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"

# 設定確認
git config --global --list
```

## 2. GitHub認証設定

### 方法A: スクリプトを使用（推奨）

```bash
chmod +x ~/configure-github.sh
~/configure-github.sh
```

スクリプトが以下のオプションを提供します：
- **方法1:** Personal Access Tokenを使用（推奨）
- **方法2:** ブラウザで認証

### 方法B: 手動設定

#### Personal Access Tokenを使用する場合

1. GitHubでPersonal Access Tokenを作成
   - https://github.com/settings/tokens にアクセス
   - "Generate new token" → "Generate new token (classic)" を選択
   - 必要な権限を選択（repo, workflow等）
   - トークンをコピー

2. インスタンス内で設定

```bash
# GitHub CLIをインストール（まだの場合）
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
sudo apt update
sudo apt install -y gh

# トークンで認証
echo "YOUR_TOKEN_HERE" | gh auth login --with-token

# 認証確認
gh auth status
```

#### ブラウザで認証する場合

```bash
gh auth login
```

## 3. Claude Codeのインストール

### 方法A: スクリプトを使用（推奨）

```bash
chmod +x ~/install-claude-code.sh
~/install-claude-code.sh
```

### 方法B: 手動インストール

```bash
curl -fsSL https://claude.ai/install.sh | bash
```

### インストール確認

```bash
# Claude Codeコマンドが利用可能か確認
claude --version
claude --help

# もしコマンドが見つからない場合、PATHを確認
echo $PATH
which claude
```

## 動作確認

### Git設定の確認

```bash
git config --global --list
git config --global user.name
git config --global user.email
```

### GitHub認証の確認

```bash
gh auth status
gh repo list
```

### インストールしたツールの確認

```bash
which cursor  # またはインストールしたツール名
cursor --version  # バージョン確認
```

## トラブルシューティング

### GitHub認証が失敗する場合

```bash
# 認証をリセット
gh auth logout
gh auth login

# トークンの権限を確認
# GitHubの設定ページでトークンの権限を確認してください
```

### Git設定が反映されない場合

```bash
# 設定を確認
git config --global --list

# 設定を削除して再設定
git config --global --unset user.name
git config --global --unset user.email
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

