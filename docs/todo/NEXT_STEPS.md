# 次のステップ

環境構築を進めるための手順です。

## 完了した作業

✅ **スクリプトと設定ファイルの作成**
- `scripts/create-instance.sh` - インスタンス作成スクリプト
- `scripts/vm/setup-instance.sh` - 環境構築スクリプト（VM内で実行）
- `.gitignore` - Git除外設定
- `README.md` - プロジェクト説明

## 次のステップ

### 1. Gitリポジトリの初期化（手動で実行）

```bash
# リポジトリを初期化
git init

# ファイルをステージング
git add .

# 初回コミット
git commit -m "Initial commit: GCE for Claude Code environment setup"
```

### 2. GitHubリポジトリの作成（手動で実行）

1. GitHubで新しいリポジトリを作成
   - リポジトリ名を決定（例: `gce-for-claude-code`）
   - 説明を設定
   - プライベート/パブリックを選択

2. リモートリポジトリに接続

```bash
# リモートリポジトリを追加（YOUR_USERNAMEとREPO_NAMEを置き換え）
git remote add origin https://github.com/YOUR_USERNAME/REPO_NAME.git

# またはSSHを使用する場合
git remote add origin git@github.com:YOUR_USERNAME/REPO_NAME.git

# 初回プッシュ
git branch -M main
git push -u origin main
```

### 3. GCPプロジェクトの作成（手動で実行）

```bash
# プロジェクトを作成
gcloud projects create YOUR_PROJECT_ID --name="Claude Code Environment"

# プロジェクトを設定
gcloud config set project YOUR_PROJECT_ID

# 請求先アカウントを設定（GCPコンソールからも可能）
```

### 4. インスタンスの作成

```bash
# スクリプトに実行権限が付いていることを確認
chmod +x scripts/create-instance.sh

# インスタンスを作成
./scripts/create-instance.sh -p YOUR_PROJECT_ID
```

### 5. SSH接続と環境構築

```bash
# SSH接続
gcloud compute ssh INSTANCE_NAME --zone=ZONE --project=YOUR_PROJECT_ID

# 接続後、環境構築スクリプトを実行
# まず、スクリプトをインスタンスに転送するか、直接作成
# リポジトリをクローンしている場合
cd ~/gce-for-claude-code
chmod +x scripts/vm/setup-instance.sh
./scripts/vm/setup-instance.sh
```

## 環境変数の設定

インスタンス内で環境構築スクリプトを実行する前に、以下の環境変数を設定してください：

```bash
export GIT_USER_NAME="Your Name"
export GIT_USER_EMAIL="your.email@example.com"
export GITHUB_TOKEN="ghp_your_token_here"
```

## 注意事項

- `gcloud` CLIが正しくインストール・認証されていることを確認してください
- GitHub Personal Access Tokenは、必要最小限の権限（push/pull）のみを付与してください
- 認証情報は`.gitignore`で除外されていますが、誤ってコミットしないよう注意してください

## トラブルシューティング

### gcloudコマンドが動作しない

```bash
# gcloud CLIの再インストールを検討
# または、Python環境を確認
which python3
```

### SSH接続できない

- インスタンスが起動しているか確認
- ファイアウォールルールを確認
- 正しいゾーンを指定しているか確認

