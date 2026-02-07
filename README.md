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

## クイックスタート

### 1. GCPプロジェクトの作成

GCPコンソールまたは`gcloud`コマンドで新しいプロジェクトを作成します。

```bash
gcloud projects create YOUR_PROJECT_ID --name="Claude Code Environment"
```

### 2. インスタンスの作成

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
# スクリプトをインスタンスに転送して実行
# または、直接インスタンス内で実行
chmod +x setup-instance.sh
./setup-instance.sh
```

## ディレクトリ構成

```
.
├── docs/                    # ドキュメント
│   ├── consideration/      # 検討事項・ガイド
│   ├── todo/               # TODOリスト
│   └── history/            # 履歴
├── scripts/                 # スクリプト
│   ├── create-instance.sh  # インスタンス作成スクリプト
│   └── setup-instance.sh   # 環境構築スクリプト
├── .gitignore              # Git除外設定
└── README.md               # このファイル
```

## 詳細なセットアップ手順

詳細な手順は以下のドキュメントを参照してください。

- [環境構築ガイド](docs/consideration/initial.md)
- [環境準備TODO](docs/todo/environment-setup.md)

## セキュリティ

- 認証情報（GitHub Token、GCP認証情報など）は`.gitignore`で除外されています
- シークレットはGCP Secret Managerで管理することを推奨します
- インスタンス用のサービスアカウントには必要最小限の権限のみを付与してください

## コスト最適化

- インスタンスの自動停止/起動スケジュールを設定できます
- 使用しない時間帯はインスタンスを停止することでコストを削減できます
- 詳細は[環境構築ガイド](docs/consideration/initial.md)を参照してください

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

## ライセンス

このリポジトリは個人利用・学習目的で作成されています。

