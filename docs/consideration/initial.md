# **Claude Code 実行ガイド：Google Cloud 活用とワークフロー**

Claude Code を Google Cloud 上で動作させ、自律的な開発エージェントとして活用するためのガイドです。特に、Compute Engine を使った「自律作業」とローカル環境での「人間によるレビュー」を組み合わせたハイブリッド構成に焦点を当てます。

## **1\. 実行環境の比較と選択**

| サービス | コンテキスト保持 | コスト | 用途 |
| ----- | ----- | ----- | ----- |
| **Cloud Run** | ❌ 毎回リセット | 極低 | 単発の自動化（ドキュメント生成等） |
| **Compute Engine** | ✅ **完全維持** | 中 | **自律的な実装代行・継続的な開発** |
| **Workstations** | ✅ 完全維持 | 高 | セキュアなブラウザベースのIDE環境 |

## **2\. 初期セットアップ：GCPプロジェクトとインスタンス作成**

### **2.0 環境構築の全体像**

本ガイドでは、以下の構成で環境を構築します：

1. **GCPプロジェクト:** 新規プロジェクトを作成し、Compute Engineインスタンスを構築
2. **接続方法:** Cursor内のターミナルからSSH接続して、インスタンス内でClaude Codeを操作
3. **環境管理:** インスタンス作成スクリプトや設定ファイルをGitHubの新規リポジトリで管理

詳細なセットアップ手順は `docs/todo/environment-setup.md` を参照してください。

### **2.0.1 GCPプロジェクトの作成**

* 新しいGCPプロジェクトを作成し、Compute Engine APIを有効化します
* プロジェクトIDを記録し、以降の作業で使用します

### **2.0.2 Cursorターミナルからの接続**

* **接続方法:** `gcloud compute ssh` コマンドを使用してCursor内のターミナルから接続
  ```bash
  gcloud compute ssh INSTANCE_NAME --zone=ZONE
  ```
* **操作フロー:** 
  1. Cursorのターミナルを開く
  2. `gcloud` CLIで認証済みであることを確認
  3. 上記コマンドでインスタンスに接続
  4. 接続後、インスタンス内でClaude Codeを起動・操作

### **2.0.3 環境管理リポジトリ**

* インスタンス作成スクリプト、設定ファイル、ドキュメントをGitHubの新規リポジトリで管理
* 認証情報（GitHub Token、GCP認証情報など）は `.gitignore` で除外し、Secret Manager等で安全に管理

### **2.1 推奨スペックとOS**

* **マシンタイプ:** `e2-standard-2` (2 vCPU, 8 GB RAM) 以上を推奨。  
  * Claude Code はビルドやテスト実行も行うため、メモリはある程度余裕があった方が安定します。  
* **OS:** Ubuntu 22.04 LTS または 24.04 LTS。  
* **ディスク:** 標準永続ディスク 50GB〜。`~/.claude/` の履歴を保持するために必須です。

### **2.2 認証とセキュリティの分離**

* **GitHub 連携:** インスタンス専用の **GitHub Fine-grained Personal Access Token** を発行し、リポジトリへの `push/pull` 権限のみを付与します。  
* **GCP 権限:** インスタンスのサービスアカウントには必要最小限の権限（Secret Manager の参照など）のみを付与します。

### **2.3 ハイブリッド・ワークフローの手順**

1. **GCE:** `TODO.md` や GitHub Issue を元に Claude が作業開始。  
2. **GCE:** 作業完了後、`feat/claude-task-xxx` のようなブランチを切って `push`。  
3. **Local:** MacBook の Cursor で `git fetch` し、該当ブランチを `checkout`。  
4. **Local:** 人間がレビュー・修正を行い、`main` へマージ。

## **3\. Compute Engine での自律運用ベストプラクティス**

GCE インスタンスを「AI 作業員」として自律稼働させるための最適設定です。

## **4\. 自律稼働のための実装例**

GCE 上で Claude に自律的なタスク（Issueの消化など）を依頼するための構成例です。

### **ステップ 1: プロジェクトルールの明文化 (`CLAUDE.md`)**

リポジトリのルートに `CLAUDE.md` を配置し、Claude が守るべきルールを記載します。

* 「作業は必ず新しいブランチで行うこと」  
* 「完了したら必ずテストを実行し、パスすること」  
* 「GitHub Issue \#123 の内容に従って実装すること」

### **ステップ 2: 自律実行スクリプト (`agent-loop.sh`)**

以下のようなスクリプトを `cron` や `systemd` で定期実行、あるいは手動でキックします。

```
#!/bin/bash
# 1. 最新の指示（TODOやIssue）を取り込む
git pull origin main

# 2. Claude Code に自律作業を指示
# --wait なしでバックグラウンド実行するか、特定のタスクを指定
claude "Read TODO.md and implement the first pending task. 
        Create a new branch, commit changes, and push it to origin. 
        Ensure all tests pass before pushing."

# 3. 完了通知（Slackやメール等、任意）
```

## **5\. 運用コストを抑える工夫**

### **4.1 インスタンス・スケジュール**

夜間や休日など、作業が発生しない時間はインスタンスを自動停止させます。

* `gcloud compute instance-templates` でスケジュールを設定可能。  
* 停止中もディスクは保持されるため、コンテキスト（履歴）は消えません。

### **4.2 スポット VM の活用**

コストを最大 60-91% 削減できます。ただし、作業中に突然シャットダウンされる可能性があるため、\*\*「Claude にこまめに `git commit` させる」\*\*という指示を `CLAUDE.md` に含めるのがコツです。

## **6\. ステートレス環境（Cloud Run）との使い分け**

| 特徴 | Cloud Run (Webhook型) | Compute Engine (常駐型) |
| ----- | ----- | ----- |
| **起動トリガー** | GitHub Webhook (Issue作成等) | スケジュールまたは手動 |
| **適した作業** | コードの静的解析、定型ドキュメント作成 | **複雑なロジックの実装、リファクタリング** |
| **履歴の扱い** | Cloud Storage への退避が必要 | 永続ディスクで自動保持 |
