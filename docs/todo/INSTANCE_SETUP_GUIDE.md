# インスタンス内での設定手順

SSH接続後、以下の手順で設定を進めてください。

## 0. スクリプトの配置について

VM内で実行するスクリプトは `scripts/vm/` ディレクトリに配置されています。

**推奨方法：リポジトリをクローン**

```bash
# VM内で実行
cd ~/projects
git clone https://github.com/YOUR_USERNAME/gce-for-claude-code.git
cd gce-for-claude-code
```

これにより、すべてのスクリプトが `scripts/vm/` 配下で利用可能になります。

**代替方法：スクリプトを個別に配置**

```bash
# VM内で実行
mkdir -p ~/scripts
# ローカルマシンからスクリプトを転送
# gcloud compute scp scripts/vm/*.sh VM_NAME:~/scripts/ --zone=ZONE
```

## 1. Git設定

インスタンス内のターミナルで以下を実行：

```bash
# リポジトリをクローンしている場合
cd ~/gce-for-claude-code
chmod +x scripts/vm/configure-git.sh
./scripts/vm/configure-git.sh

# または、ホームディレクトリにスクリプトを配置している場合
chmod +x ~/scripts/configure-git.sh
~/scripts/configure-git.sh
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
# リポジトリをクローンしている場合
cd ~/gce-for-claude-code
chmod +x scripts/vm/configure-github.sh
./scripts/vm/configure-github.sh

# または、ホームディレクトリにスクリプトを配置している場合
chmod +x ~/scripts/configure-github.sh
~/scripts/configure-github.sh
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
# リポジトリをクローンしている場合
cd ~/gce-for-claude-code
chmod +x scripts/vm/install-claude-code.sh
./scripts/vm/install-claude-code.sh

# または、ホームディレクトリにスクリプトを配置している場合
chmod +x ~/scripts/install-claude-code.sh
~/scripts/install-claude-code.sh
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
```

## 4. Claude Codeの認証

Claude Codeを使用するには、認証が必要です。以下のいずれかの方法で認証を行ってください。

### 4.1 認証方法の確認

まず、利用可能な認証コマンドを確認します：

```bash
claude auth --help
# または
claude login --help
```

### 4.2 方法1: Claude Consoleアカウントで認証（推奨）

Claude Consoleアカウントを使用する場合：

1. **Claude Consoleアカウントの準備**
   - Claude Console（https://console.claude.com）にアクセス
   - アカウントを作成またはログイン
   - 必要に応じて、チーム管理者から「Claude Code」または「Developer」ロールの招待を受ける

2. **VM内で認証を実行**

```bash
# 認証コマンドを実行（ブラウザ認証）
claude auth login
# または
claude login
```

認証プロセスが開始され、認証URLが表示されます。SSHポートフォワーディングを使用している場合、ローカルマシンのブラウザで認証URLにアクセスして認証を完了してください。

**SSHポートフォワーディングを使用する場合：**
```bash
# ローカルマシンからSSH接続（ポートフォワーディング付き）
gcloud compute ssh claude-code-vm \
  --zone=asia-northeast1-a \
  --project=gce-for-claude-code \
  --ssh-flag="-L 8080:localhost:8080"
```

### 4.3 方法2: APIキーを使用した認証

APIキーを使用する場合：

1. **APIキーの取得**
   - Claude Console（https://console.claude.com）にアクセス
   - Settings → API Keys からAPIキーを生成
   - キーを安全にコピー

2. **環境変数に設定**

```bash
# 環境変数にAPIキーを設定
export ANTHROPIC_API_KEY="your-api-key-here"

# 永続化する場合（.bashrcに追加）
echo 'export ANTHROPIC_API_KEY="your-api-key-here"' >> ~/.bashrc
source ~/.bashrc
```

**セキュリティ注意事項：**
- APIキーは機密情報です。`.gitignore`に追加し、リポジトリにコミットしないでください
- 可能であれば、GCP Secret Managerを使用して安全に管理してください

### 4.4 方法3: クラウドプロバイダー認証

Google Vertex AIを使用する場合：

```bash
# Google Cloud認証を設定
gcloud auth application-default login

# Claude CodeでVertex AIを使用するように設定
# （設定方法はClaude Codeのドキュメントを参照）
```

### 4.5 認証の確認

認証が完了したら、以下のコマンドで確認します：

```bash
# 認証状態の確認
claude auth status
# または
claude whoami

# 簡単なテスト実行
claude "Hello, can you hear me?"
```

認証が成功していれば、Claude Codeが応答を返します。

### PATHの問題が発生した場合

もし`claude: command not found`エラーが出た場合：

```bash
# PATH修正スクリプトを実行
# リポジトリをクローンしている場合
cd ~/gce-for-claude-code
chmod +x scripts/vm/fix-claude-path.sh
./scripts/vm/fix-claude-path.sh

# または、ホームディレクトリにスクリプトを配置している場合
chmod +x ~/scripts/fix-claude-path.sh
~/scripts/fix-claude-path.sh

# 新しいシェルセッションを開始（または）
source ~/.bashrc

# 再度確認
claude --version
```

または手動でPATHを設定：

```bash
# インストール先を確認
find ~ -name "claude" -type f 2>/dev/null

# PATHに追加（例: ~/.local/bin/claudeが見つかった場合）
export PATH="$PATH:$HOME/.local/bin"

# 永続化する場合
echo 'export PATH="$PATH:$HOME/.local/bin"' >> ~/.bashrc
source ~/.bashrc
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

### Claude Codeの認証確認

```bash
# 認証状態の確認
claude auth status
# または
claude whoami

# バージョン確認
claude --version

# 簡単な動作確認
claude "Hello, this is a test message."
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

### Claude Codeの認証が失敗する場合

```bash
# 認証状態を確認
claude auth status

# 認証をリセット
claude auth logout
# または
claude logout

# 再認証
claude auth login

# APIキーを使用する場合、環境変数を確認
echo $ANTHROPIC_API_KEY

# 設定ファイルの場所を確認
ls -la ~/.claude/
# または
ls -la ~/.config/claude/
```

### Claude Codeが応答しない場合

```bash
# バージョンを確認
claude --version

# ヘルプを確認
claude --help

# ログを確認（ログファイルの場所はバージョンによって異なる場合があります）
# ~/.claude/logs/ または ~/.local/share/claude/logs/ などを確認
```

