# GCE for Claude Code

Google Cloud Platform (GCP) の Compute Engine 上で Claude Code を実行するための環境構築リポジトリです。

## 概要

このリポジトリは、GCP上でClaude Codeを動作させるための環境構築スクリプトとドキュメントを管理します。

- **Compute Engineインスタンス**の作成と管理
- **Cursorターミナル**からのSSH接続
- **環境構築スクリプト**の提供
- **セットアップ手順**のドキュメント化

## 前提条件

- GCPアカウントとプロジェクト
- `gcloud` CLIがインストールされていること
- GitHubアカウント（環境管理用リポジトリ用）

## Gitユーザー名の使い分け

このプロジェクトでは、環境ごとに異なるGitユーザー名を使用します：

- **Cursor（ローカルマシン）：** `soshizaki`
- **VM内：** `PROPOFMDEV`

これにより、コミット履歴から作業環境を識別できます。

## クイックスタート

### スクリプトの実行場所について

- **ローカルマシンで実行するスクリプト：** `scripts/` 直下
  - `create-instance.sh` - インスタンス作成
  - `setup-functions.sh` - Cloud Functionsデプロイ
  - `setup-scheduler.sh` - Cloud Scheduler設定
  - `vm-control.sh` - VM制御（起動・停止）
  - `add-user-access.sh` - ユーザーアクセス権追加

- **VM内で実行するスクリプト：** `scripts/vm/` 配下
  - `setup-instance.sh` - 環境構築
  - `configure-git.sh` - Git設定
  - `configure-github.sh` - GitHub認証
  - `install-claude-code.sh` - Claude Codeインストール
  - `fix-claude-path.sh` - PATH修正

### 1. GCPプロジェクトの作成

GCPコンソールまたは`gcloud`コマンドで新しいプロジェクトを作成します。

```bash
gcloud projects create YOUR_PROJECT_ID --name="Claude Code Environment"
```

### 2. インスタンスの作成（ローカルマシンで実行）

```bash
# スクリプトに実行権限を付与
chmod +x scripts/create-instance.sh

# インスタンスを作成
./scripts/create-instance.sh -p YOUR_PROJECT_ID
```

### 3. SSH接続

```bash
gcloud compute ssh INSTANCE_NAME --zone=ZONE --project=YOUR_PROJECT_ID
```

### 4. インスタンス内での環境構築

SSH接続後、環境構築スクリプトを実行します。

```bash
# リポジトリをクローンしている場合
cd ~/gce-for-claude-code
chmod +x scripts/vm/setup-instance.sh
./scripts/vm/setup-instance.sh

# または、ホームディレクトリにスクリプトを配置している場合
chmod +x ~/scripts/setup-instance.sh
~/scripts/setup-instance.sh
```

**注意：** VM内で実行するスクリプトは `scripts/vm/` ディレクトリに配置されています。

## ディレクトリ構成

```
.
├── docs/                    # ドキュメント
│   ├── consideration/      # 検討事項・ガイド
│   ├── todo/               # TODOリスト
│   └── history/            # 履歴
├── functions/               # Cloud Functions
│   └── stop_instance/      # インスタンス停止用のCloud Function
│       ├── main.py         # 関数のコード
│       └── requirements.txt # 依存パッケージ
├── scripts/                 # スクリプト
│   ├── add-user-access.sh  # ユーザーアクセス権追加スクリプト（ローカル実行）
│   ├── create-instance.sh  # インスタンス作成スクリプト（ローカル実行）
│   ├── setup-functions.sh  # Cloud Functionsデプロイスクリプト（ローカル実行）
│   ├── setup-scheduler.sh  # Cloud Scheduler設定スクリプト（ローカル実行）
│   ├── vm-control.sh       # VM制御スクリプト（ローカル実行）
│   └── vm/                  # VM内で実行するスクリプト
│       ├── configure-git.sh      # Git設定スクリプト
│       ├── configure-github.sh   # GitHub認証設定スクリプト
│       ├── fix-claude-path.sh    # Claude Code PATH修正スクリプト
│       ├── install-claude-code.sh # Claude Codeインストールスクリプト
│       └── setup-instance.sh     # 環境構築スクリプト
├── .gitignore              # Git除外設定
└── README.md               # このファイル
```

## 詳細なセットアップ手順

詳細な手順は以下のドキュメントを参照してください。

- [環境構築ガイド](docs/consideration/initial.md)
- [環境準備TODO](docs/todo/environment-setup.md)
- [Claude Code利用ガイド](docs/consideration/CLAUDE_CODE_USAGE_GUIDE.md) - **VM内でのClaude Code使用方法**

## VM内でのディレクトリ構造

### 推奨ディレクトリ構造

VM内でClaude Codeを動かす際は、**ホームディレクトリ配下にプロジェクト用のディレクトリを作成**することを推奨します。

```
/home/USERNAME/
├── projects/                    # すべてのプロジェクトを管理する親ディレクトリ
│   ├── repo-name-1/            # リポジトリ1
│   ├── repo-name-2/            # リポジトリ2
│   └── repo-name-3/            # リポジトリ3
├── .claude/                    # Claude Codeの設定・履歴（自動生成）
└── .bashrc / .zshrc           # シェル設定
```

### 基本パス

**推奨パス:** `~/projects/`

環境構築スクリプト（`setup-instance.sh`）を実行すると、自動的に `~/projects/` ディレクトリが作成されます。

### リポジトリ単位での運用

各リポジトリは独立したディレクトリとして管理します：

```bash
~/projects/
├── my-web-app/          # Webアプリケーション
├── api-server/          # APIサーバー
├── cli-tool/            # CLIツール
└── documentation/       # ドキュメントプロジェクト
```

**メリット:**
- 各リポジトリが独立して管理できる
- パスが明確で、Claude Codeが理解しやすい
- 複数のプロジェクトを同時に扱いやすい
- Git操作がシンプル

### プロジェクトのクローン例

```bash
# VM内で実行
cd ~/projects
git clone https://github.com/USERNAME/REPO_NAME.git
cd REPO_NAME
```

詳細は [VM内でのClaude Code運用ガイド](docs/consideration/2026-02-07_活用相談.md) を参照してください。

## ブラウザでの確認方法

VM内で実装したアプリケーションをブラウザで確認する方法は、以下の3つがあります。

### 方法1: SSHポートフォワーディング（推奨・最も安全）

SSHトンネルを使って、ローカルマシン経由でVM内のサービスにアクセスします。

**手順:**

1. **SSH接続時にポートフォワーディングを設定**
   ```bash
   # ローカルマシン（MacBook）から実行
   gcloud compute ssh INSTANCE_NAME \
     --zone=ZONE \
     --project=PROJECT_ID \
     --ssh-flag="-L 8080:localhost:8080"
   ```

2. **VM内でサービスを起動**
   ```bash
   # VM内で実行
   cd ~/projects/my-web-app
   npm start  # または python -m http.server 8080 など
   ```

3. **ローカルブラウザでアクセス**
   - `http://localhost:8080` にアクセス

**メリット:**
- ファイアウォールルールを変更する必要がない（最も安全）
- 外部から直接アクセスできない
- 設定が簡単

### 方法2: ファイアウォールルールでポートを開放（直接アクセス）

GCPのファイアウォールルールで特定のポートを開放し、外部IP経由で直接アクセスします。

**手順:**

1. **ファイアウォールルールを作成**
   ```bash
   # ローカルマシンから実行
   gcloud compute firewall-rules create allow-http-dev \
     --allow tcp:8080 \
     --source-ranges 0.0.0.0/0 \
     --description "Allow HTTP for development"
   ```

2. **VM内でサービスを起動**
   ```bash
   # VM内で実行
   cd ~/projects/my-web-app
   npm start -- --host 0.0.0.0 --port 8080
   ```

3. **外部IPでアクセス**
   - VMの外部IPを確認してブラウザでアクセス

**注意:** セキュリティリスクが高いため、開発環境のみ推奨。可能であれば特定のIPアドレスのみ許可してください。

### 方法3: Cloud Load Balancer / Cloud Run（本番環境向け）

本番環境やより堅牢な構成が必要な場合に使用します。詳細は [環境構築ガイド](docs/consideration/initial.md) を参照してください。

**推奨:** 開発・検証段階では方法1（SSHポートフォワーディング）が最も適しています。

詳細は [VM内でのClaude Code運用ガイド](docs/consideration/2026-02-07_活用相談.md) を参照してください。

## セキュリティ

- 認証情報（GitHub Token、GCP認証情報など）は`.gitignore`で除外されています
- シークレットはGCP Secret Managerで管理することを推奨します
- インスタンス用のサービスアカウントには必要最小限の権限のみを付与してください

## ユーザーアクセス権管理

### ユーザーの追加

他のユーザーにVMへのアクセス権を付与するには、`add-user-access.sh`スクリプトを使用します。

```bash
# スクリプトに実行権限を付与（初回のみ）
chmod +x scripts/add-user-access.sh

# ユーザーを追加（デフォルト: SSH接続権限）
./scripts/add-user-access.sh user@example.com

# プロジェクトIDを指定する場合
./scripts/add-user-access.sh user@example.com -p YOUR_PROJECT_ID

# インスタンス管理権限を付与する場合
./scripts/add-user-access.sh user@example.com -r roles/compute.instanceAdmin
```

### 同一OSユーザーでSSH鍵を追加する方法（手軽）

担当者から**公開鍵**（1行の文字列）を受け取り、同じOSユーザー（例: `hirotososhizaki`）でログインできるようにする手順です。

**1. あなたのPCからVMにSSH接続する**

```bash
./scripts/vm-control.sh ssh
# または
gcloud compute ssh claude-code-vm --zone=asia-northeast2-a --project=gce-for-claude-code \
  --ssh-key-file=~/.ssh/id_ed25519 --ssh-flag="-l hirotososhizaki"
```

**2. VM内で受け取った公開鍵を1行で追加する**

すでに自分でSSH接続している場合は `~/.ssh` と `~/.ssh/authorized_keys` は存在するので、次の追加だけでよい。（存在しない場合のみ: `mkdir -p ~/.ssh && chmod 700 ~/.ssh && touch ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys` を先に実行する。）

担当者から受け取った公開鍵（`ssh-ed25519 AAAA...` や `ssh-rsa AAAA...` で始まる1行）を、そのまま末尾に追加します。

```bash
# 方法A: echo で追加（公開鍵を PASTE_ME の部分に貼り付ける）
echo "ssh-ed25519 AAAA...担当者の公開鍵1行..." >> ~/.ssh/authorized_keys

# 方法B: エディタで追加
nano ~/.ssh/authorized_keys
# ファイルの末尾に1行貼り付けて保存
```

**3. 内容を確認する**

```bash
cat ~/.ssh/authorized_keys
# 既存の鍵と、追加した1行が表示されればOK
```

**4. 担当者に伝える接続コマンド**

担当者は自分のPCで、自分の秘密鍵（例: `~/.ssh/id_ed25519`）を使って次で接続できます。

```bash
gcloud compute ssh claude-code-vm --zone=asia-northeast2-a --project=gce-for-claude-code \
  --ssh-key-file=~/.ssh/id_ed25519 --ssh-flag="-l hirotososhizaki"
```

**注意:** 担当者のPCには `gcloud` CLI のインストールと、同じGCPプロジェクトへのアクセス権（少なくともインスタンス一覧・SSH用）が必要です。プロジェクトへのアクセス権がない場合は、先に `./scripts/add-user-access.sh 担当者@example.com` でIAMを付与してください。

### 利用可能なロール

- `roles/compute.osAdminLogin` - SSH接続権限（推奨・デフォルト）
- `roles/compute.instanceAdmin` - インスタンス管理権限（起動・停止・削除など）
- `roles/compute.viewer` - インスタンス情報の閲覧のみ

### 初回ログイン時の手順

追加されたユーザーは、初回ログイン時に以下のコマンドで認証する必要があります：

```bash
# GCPアカウントでログイン
gcloud auth login

# SSH接続
gcloud compute ssh claude-code-vm --zone=asia-northeast2-a --project=gce-for-claude-code
```

## コスト最適化

### VM制御スクリプト

インスタンスの起動・停止を簡単に行うためのスクリプトを用意しています：

```bash
# スクリプトに実行権限を付与（初回のみ）
chmod +x scripts/vm-control.sh

# インスタンスを起動
./scripts/vm-control.sh start

# インスタンスを停止
./scripts/vm-control.sh stop

# インスタンスの状態を確認
./scripts/vm-control.sh status

# SSH接続
./scripts/vm-control.sh ssh

# 再起動
./scripts/vm-control.sh restart
```

### コスト削減の効果

- **停止中はCPU/メモリの料金が発生しません**（ディスク料金のみ）
- **データは完全に保持されます**（`~/.claude/`の履歴、`~/projects/`のプロジェクトなど）
- **起動が速い**（約30秒〜1分）

**コスト削減例：**
- 平日9:00-18:00のみ使用：約67%削減
- 週末のみ使用：約87%削減
- 使用時のみ起動（1日2時間）：約90%削減

### 推奨運用方法

#### 方法1: 手動停止（シンプル）

1. **使用開始時：** `./scripts/vm-control.sh start` で起動
2. **使用中：** Claude Codeで作業、定期的に `git commit` を実行
3. **使用終了時：** `./scripts/vm-control.sh stop` で停止

#### 方法2: 毎朝6時の自動停止（推奨）

毎朝6時に自動的にインスタンスを停止し、使用時は手動で起動する方法です。

**セットアップ手順（ローカルマシンで実行）：**

```bash
# 1. Cloud Functionsをデプロイ
chmod +x scripts/setup-functions.sh
./scripts/setup-functions.sh -p YOUR_PROJECT_ID

# 2. Cloud Schedulerを設定（毎朝6時に自動停止）
chmod +x scripts/setup-scheduler.sh
./scripts/setup-scheduler.sh -p YOUR_PROJECT_ID
```

**注意：** `setup-functions.sh` と `setup-scheduler.sh` は**ローカルマシン**で実行します。VM内で実行するスクリプトは `scripts/vm/` ディレクトリに配置されています。

**使用フロー：**

1. **使用開始時（手動）：** `./scripts/vm-control.sh start` で起動
2. **使用中：** Claude Codeで作業、夜中も使用可能
3. **毎朝6時（自動）：** Cloud Schedulerが自動的にインスタンスを停止
4. **次回使用時（手動）：** `./scripts/vm-control.sh start` で起動

**メリット：**
- 忘れずに毎朝停止される
- 夜中も使用可能（朝6時まで）
- 使用時は手動で起動（柔軟性）

詳細は [VM内でのClaude Code運用ガイド](docs/consideration/2026-02-07_活用相談.md) の「5. VMのコスト削減戦略」セクションを参照してください。

## トラブルシューティング

### gcloudコマンドが動作しない

`gcloud` CLIが正しくインストールされているか確認してください。

```bash
gcloud --version
gcloud auth login
gcloud config set project YOUR_PROJECT_ID
```

### SSH接続できない

- ファイアウォールルールを確認してください
- インスタンスが起動しているか確認してください
- 正しいゾーンを指定しているか確認してください

### 起動失敗（ZONE_RESOURCE_POOL_EXHAUSTED）

`./scripts/vm-control.sh start` で次のようなエラーが出る場合があります。

```
ERROR: (gcloud.compute.instances.start) ---
code: ZONE_RESOURCE_POOL_EXHAUSTED
message: The zone '.../asia-northeast2-a' does not have enough resources available...
```

**原因:** 指定ゾーン（例: asia-northeast2-a）で、そのマシンタイプの空きリソースが一時的に不足しています。

**対処法:**

1. **時間をおいて再試行**
   ```bash
   # 数分〜数時間後に再度
   ./scripts/vm-control.sh start
   ```

2. **別ゾーンへインスタンスを移行（推奨）**
   
   `gcloud compute instances move` は廃止されているため、**スナップショットを作成して別ゾーンに新規インスタンスを作り直す**手順です。インスタンスは停止した状態で実行してください。

   **手順（例: asia-northeast2-a → asia-northeast2-b）:**

   ```bash
   PROJECT=gce-for-claude-code
   INSTANCE=claude-code-vm
   ZONE_A=asia-northeast2-a
   ZONE_B=asia-northeast2-b
   SNAPSHOT_NAME=claude-code-vm-migrate

   # 1. ブートディスクのスナップショットを作成
   gcloud compute disks snapshot $INSTANCE \
     --zone=$ZONE_A \
     --snapshot-names=$SNAPSHOT_NAME \
     --project=$PROJECT

   # 2. 移行先ゾーンにスナップショットからディスクを作成
   gcloud compute disks create ${INSTANCE}-boot-b \
     --source-snapshot=$SNAPSHOT_NAME \
     --zone=$ZONE_B \
     --project=$PROJECT \
     --type=pd-standard \
     --size=50GB

   # 3. 旧インスタンスを削除（ブートディスクは auto-delete のため一緒に削除される）
   gcloud compute instances delete $INSTANCE --zone=$ZONE_A --project=$PROJECT

   # 4. 移行先ゾーンにインスタンスを新規作成
   gcloud compute instances create $INSTANCE \
     --project=$PROJECT \
     --zone=$ZONE_B \
     --machine-type=e2-standard-2 \
     --network-interface=network-tier=PREMIUM,subnet=default \
     --maintenance-policy=MIGRATE \
     --provisioning-model=STANDARD \
     --no-service-account --no-scopes \
     --disk=name=${INSTANCE}-boot-b,boot=yes,mode=rw,auto-delete=yes \
     --no-shielded-secure-boot \
     --shielded-vtpm \
     --shielded-integrity-monitoring \
     --labels=env=claude-code,purpose=development
   ```

   移行後は、起動・SSH・停止時に**新しいゾーン**を指定してください。

   ```bash
   ./scripts/vm-control.sh start -z asia-northeast2-b
   ./scripts/vm-control.sh ssh -z asia-northeast2-b
   ./scripts/vm-control.sh stop -z asia-northeast2-b
   ```

   **毎朝6時自動停止について:** Cloud Function は環境変数 `ZONE` で停止するゾーンを指定しています。**移行後は Cloud Function を新しいゾーンで再デプロイしてください。**

   ```bash
   ./scripts/setup-functions.sh -p gce-for-claude-code -z asia-northeast2-b
   ```

   **補足:** スナップショット `claude-code-vm-migrate` は残ります。不要なら削除して構いません: `gcloud compute snapshots delete claude-code-vm-migrate --project=$PROJECT`

## ライセンス

このリポジトリは個人利用・学習目的で作成されています。

