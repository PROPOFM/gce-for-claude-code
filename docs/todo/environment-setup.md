# 環境準備 TODO

GCP上でClaude Codeを実行するための環境構築タスクリストです。

## 1. GCPプロジェクトの準備

- [ ] GCPに新しいプロジェクトを作成
  - [ ] プロジェクト名を決定
  - [ ] プロジェクトIDを確認
  - [ ] 請求先アカウントを設定
- [ ] 必要なAPIを有効化
  - [ ] Compute Engine API
  - [ ] Cloud Resource Manager API
  - [ ] IAM API
  - [ ] Secret Manager API（必要に応じて）

## 2. GitHubリポジトリの準備

- [ ] 環境管理用の新しいGitHubリポジトリを作成
  - [ ] リポジトリ名を決定
  - [ ] リポジトリの説明を設定
  - [ ] 初期README.mdを作成
  - [ ] `.gitignore`を設定（GCP認証情報など）
- [ ] ローカルリポジトリを初期化
  - [ ] `git init`
  - [ ] 初期コミットを作成
  - [ ] リモートリポジトリに接続
  - [ ] 初回プッシュ

## 3. Compute Engineインスタンスの作成

- [ ] インスタンスの仕様を決定
  - [ ] マシンタイプ: `e2-standard-2` (2 vCPU, 8 GB RAM) 以上
  - [ ] OS: Ubuntu 22.04 LTS または 24.04 LTS
  - [ ] ディスク: 標準永続ディスク 50GB以上
  - [ ] リージョン/ゾーンを選択
- [ ] インスタンスを作成
  - [ ] `gcloud compute instances create` コマンドを実行
  - [ ] またはGCPコンソールから作成
- [ ] ファイアウォールルールの設定
  - [ ] SSH接続用のルールを確認（デフォルトで有効）
  - [ ] 必要に応じて追加のポートを開放

## 4. SSH接続の設定

- [ ] ローカル環境の準備
  - [ ] `gcloud` CLIがインストールされていることを確認
  - [ ] `gcloud auth login` で認証
  - [ ] デフォルトプロジェクトを設定: `gcloud config set project PROJECT_ID`
- [ ] SSH接続のテスト
  - [ ] `gcloud compute ssh INSTANCE_NAME --zone=ZONE` で接続確認
  - [ ] Cursor内のターミナルから接続できることを確認

## 5. インスタンス内の環境構築

- [ ] 基本パッケージのインストール
  - [ ] `sudo apt update && sudo apt upgrade -y`
  - [ ] 必要な開発ツールをインストール（git, curl, wget等）
- [ ] Claude Codeのセットアップ
  - [ ] Claude Codeのインストール手順を確認
  - [ ] インストールを実行
  - [ ] 動作確認
- [ ] Git設定
  - [ ] `git config` でユーザー名・メールアドレスを設定
  - [ ] GitHub認証の設定（Personal Access Token等）

## 6. セキュリティ設定

- [ ] GitHub認証トークンの準備
  - [ ] Fine-grained Personal Access Tokenを発行
  - [ ] 必要最小限の権限（push/pull）のみを付与
  - [ ] Secret Managerに保存（推奨）または安全に管理
- [ ] GCPサービスアカウントの設定
  - [ ] インスタンス用のサービスアカウントを作成
  - [ ] 必要最小限の権限のみを付与
  - [ ] インスタンスにサービスアカウントを割り当て

## 7. 環境管理リポジトリへの反映

- [x] インスタンス作成用のスクリプトを作成
  - [x] `scripts/create-instance.sh` を作成（パラメータ化済み）
  - [x] `scripts/vm/setup-instance.sh` を作成（環境構築用、VM内で実行）
- [x] 設定ファイルの管理
  - [x] `.gitignore` を作成（認証情報を除外）
  - [x] 環境変数やシークレットの管理方法を文書化（READMEに記載）
- [x] ドキュメントの整備
  - [x] セットアップ手順をREADMEに記載
  - [x] トラブルシューティング情報を追加

## 8. 動作確認

- [ ] Cursorターミナルからの接続確認
  - [ ] SSH接続が正常に確立できること
  - [ ] ターミナル内でコマンドが実行できること
- [ ] Claude Codeの動作確認
  - [ ] インスタンス内でClaude Codeが起動できること
  - [ ] 基本的な操作が可能であること
- [ ] Git連携の確認
  - [ ] GitHubリポジトリへのpush/pullが可能であること
  - [ ] 認証が正常に動作すること

## 9. 運用準備

- [ ] インスタンスのスケジュール設定（任意）
  - [ ] 自動停止/起動のスケジュールを設定
  - [ ] コスト最適化の検討
- [ ] 監視・アラートの設定（任意）
  - [ ] インスタンスの状態監視
  - [ ] 異常時の通知設定
- [ ] バックアップ戦略の検討
  - [ ] ディスクのスナップショット設定
  - [ ] 重要なデータのバックアップ方法

