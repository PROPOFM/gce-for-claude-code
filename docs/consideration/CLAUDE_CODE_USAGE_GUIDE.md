# Claude Code 利用ガイド

VM内でClaude Codeを使用して開発を行うための手順をまとめます。

## 目次

1. [初期セットアップ](#初期セットアップ)
2. [プロジェクトのクローン](#プロジェクトのクローン)
3. [Claude Codeの起動方法](#claude-codeの起動方法)
4. [基本的な実装開始手順](#基本的な実装開始手順)
5. [複数プロジェクトの同時実行](#複数プロジェクトの同時実行)
6. [よくある操作](#よくある操作)

## 初期セットアップ

### 1. VMへの接続

```bash
# ローカルマシン（Cursor）から実行
./scripts/vm-control.sh start  # VMを起動
./scripts/vm-control.sh ssh     # SSH接続
```

### 2. 環境確認

VM内で以下を確認：

```bash
# Claude Codeがインストールされているか確認
claude --version

# Git設定を確認
git config --global user.name   # PROPOFMDEV が設定されているか
git config --global user.email  # メールアドレスが設定されているか

# GitHub認証を確認
gh auth status
```

### 3. プロジェクト用ディレクトリの確認

```bash
# projectsディレクトリが存在するか確認
ls -la ~/projects

# 存在しない場合は作成
mkdir -p ~/projects
```

## プロジェクトのクローン

### 基本的なクローン手順

```bash
# projectsディレクトリに移動
cd ~/projects

# リポジトリをクローン
git clone https://github.com/USERNAME/REPO_NAME.git

# リポジトリに移動
cd REPO_NAME

# ブランチを確認
git branch -a
```

### 複数のプロジェクトをクローンする場合

```bash
cd ~/projects

# プロジェクト1
git clone https://github.com/USERNAME/project1.git
cd project1
git checkout main
cd ..

# プロジェクト2
git clone https://github.com/USERNAME/project2.git
cd project2
git checkout develop
cd ..

# プロジェクト3
git clone https://github.com/USERNAME/project3.git
cd project3
git checkout feature/xxx
cd ..
```

**推奨ディレクトリ構造：**

```
~/projects/
├── project1/
│   ├── .git/
│   ├── src/
│   └── README.md
├── project2/
│   ├── .git/
│   ├── src/
│   └── README.md
└── project3/
    ├── .git/
    ├── src/
    └── README.md
```

## Claude Codeの起動方法

### 基本的な起動方法

```bash
# プロジェクトディレクトリに移動
cd ~/projects/my-project

# Claude Codeを起動（対話形式）
claude

# または、直接指示を渡す
claude "このプロジェクトのREADMEを読んで、最初のタスクを実装してください"
```

### プロジェクトコンテキストを指定して起動

```bash
# 特定のプロジェクトディレクトリで起動
cd ~/projects/my-project
claude "TODO.mdの最初のタスクを実装してください"
```

### バックグラウンドで実行

```bash
# 長時間実行するタスクの場合
cd ~/projects/my-project
nohup claude "大規模なリファクタリングを実行してください" > claude.log 2>&1 &

# プロセスIDを確認
ps aux | grep claude

# ログを確認
tail -f claude.log
```

## 基本的な実装開始手順

### ステップ1: プロジェクトの理解

```bash
cd ~/projects/my-project

# プロジェクトの構造を確認
claude "このプロジェクトの構造を説明してください。主要なファイルとディレクトリを教えてください"
```

### ステップ2: タスクの確認

```bash
# TODOやIssueを確認
claude "TODO.mdを読んで、優先順位の高いタスクを3つリストアップしてください"

# または、GitHub Issueを確認
gh issue list
claude "GitHub Issue #123の内容を確認して、実装方針を提案してください"
```

### ステップ3: ブランチの作成

```bash
# 新しいブランチを作成
git checkout -b feat/claude-task-001

# ブランチを確認
git branch
```

### ステップ4: 実装の開始

```bash
# Claude Codeに実装を依頼
claude "TODO.mdの最初のタスクを実装してください。新しいブランチで作業し、完了したらコミットしてください"
```

### ステップ5: 実装の確認とコミット

```bash
# 変更内容を確認
git status
git diff

# Claude Codeに確認を依頼
claude "実装した変更をレビューして、問題がないか確認してください"

# コミット
git add .
git commit -m "feat: タスク001を実装"

# プッシュ
git push origin feat/claude-task-001
```

### ステップ6: 次のタスクへ

```bash
# 次のタスクに進む
claude "次のタスクを実装してください"
```

## 複数プロジェクトの同時実行

**重要：** 以下の操作はすべて**VM内**で実行します。ローカルマシン（Cursor）からVMにSSH接続した後、VM内のターミナルで操作してください。

### 方法1: 複数のターミナルセッションを使用（推奨）

**tmuxを使用する場合：**

**操作場所：** VM内のターミナル

**手順：**

1. **ローカルマシンからVMにSSH接続**
   ```bash
   # ローカルマシン（Cursor）で実行
   ./scripts/vm-control.sh ssh
   # または
   gcloud compute ssh claude-code-vm --zone=asia-northeast1-a --project=gce-for-claude-code
   ```

2. **VM内でtmuxセッションを開始**
   ```bash
   # VM内のターミナルで実行
   tmux new -s claude
   ```

3. **プロジェクト1で作業開始**
   ```bash
   # tmuxセッション内で実行
   cd ~/projects/project1
   claude "タスクAを実装してください"
   ```

4. **新しいペインを作成してプロジェクト2で作業**
   ```bash
   # Ctrl+b, c を押して新しいペインを作成
   # 新しいペインで実行
   cd ~/projects/project2
   claude "タスクBを実装してください"
   ```

5. **ペインの切り替え**
   - `Ctrl+b, n`: 次のペインに移動
   - `Ctrl+b, p`: 前のペインに移動
   - `Ctrl+b, x`: 現在のペインを閉じる

6. **セッションをデタッチ（バックグラウンドで実行継続）**
   ```bash
   # Ctrl+b, d を押すとセッションがデタッチされる
   # SSH接続を切断しても、VM内でClaude Codeは実行され続ける
   ```

7. **セッションに再接続**
   ```bash
   # 再度VMにSSH接続後、tmuxセッションに再接続
   tmux attach -t claude
   ```

**tmuxの基本操作：**
- `Ctrl+b, c`: 新しいペインを作成
- `Ctrl+b, %`: ペインを縦に分割
- `Ctrl+b, "`: ペインを横に分割
- `Ctrl+b, n`: 次のペイン
- `Ctrl+b, p`: 前のペイン
- `Ctrl+b, d`: セッションをデタッチ
- `tmux ls`: セッション一覧を表示
- `tmux attach -t <session-name>`: セッションに再接続

**screenを使用する場合：**

**操作場所：** VM内のターミナル

```bash
# VM内でSSH接続後、screenセッションを開始
screen -S claude

# セッション1: プロジェクト1
cd ~/projects/project1
claude "タスクAを実装してください"

# 新しいウィンドウを作成（Ctrl+a, c）
# セッション2: プロジェクト2
cd ~/projects/project2
claude "タスクBを実装してください"

# ウィンドウの切り替え
# Ctrl+a, n: 次のウィンドウ
# Ctrl+a, p: 前のウィンドウ
# Ctrl+a, d: セッションをデタッチ

# セッションに再接続
screen -r claude
```

### 方法2: バックグラウンドジョブを使用

**操作場所：** VM内のターミナル

```bash
# VM内でSSH接続後、以下を実行

# プロジェクト1をバックグラウンドで実行
cd ~/projects/project1
nohup claude "タスクAを実装してください" > project1.log 2>&1 &
JOB1=$!

# プロジェクト2をバックグラウンドで実行
cd ~/projects/project2
nohup claude "タスクBを実装してください" > project2.log 2>&1 &
JOB2=$!

# ジョブの状態を確認
jobs

# ログを確認
tail -f project1.log
tail -f project2.log

# ジョブの終了を待つ
wait $JOB1
wait $JOB2
```

### 方法3: プロジェクトごとに別々のSSHセッション

**操作場所：** ローカルマシン（Cursor）から複数のSSH接続を開く

**手順：**

1. **ローカルマシンでターミナル1を開く**
   ```bash
   # ローカルマシン（Cursor）で実行
   gcloud compute ssh claude-code-vm --zone=asia-northeast1-a --project=gce-for-claude-code
   
   # VM内で実行
   cd ~/projects/project1
   claude "タスクAを実装してください"
   ```

2. **ローカルマシンでターミナル2を開く（新しいターミナルウィンドウ）**
   ```bash
   # ローカルマシン（Cursor）で実行（新しいターミナルウィンドウ）
   gcloud compute ssh claude-code-vm --zone=asia-northeast1-a --project=gce-for-claude-code
   
   # VM内で実行
   cd ~/projects/project2
   claude "タスクBを実装してください"
   ```

**注意：** この方法では、ローカルマシンで複数のターミナルウィンドウを開く必要があります。tmuxを使用する方法の方が、1つのSSH接続で複数のプロジェクトを管理できるため推奨です。

### 推奨アプローチ

**複数のプロジェクトを同時に実行する場合：**

1. **tmuxを使用（推奨）**
   - **操作場所：** VM内のターミナル
   - **メリット：**
     - 1つのSSH接続で複数のペインを管理
     - セッションをデタッチしても実行継続（SSH接続を切断してもVM内で実行され続ける）
     - ログの確認が容易
     - リソース効率が良い

2. **プロジェクトごとに明確なタスクを設定**
   - 各プロジェクトで独立したタスクを実行
   - タスクが完了したらコミット・プッシュ

3. **リソースの監視**
   ```bash
   # VM内で実行
   # CPU/メモリの使用状況を確認
   htop
   
   # 実行中のClaude Codeプロセスを確認
   ps aux | grep claude
   ```

### 操作場所のまとめ

| 方法 | 操作場所 | 説明 |
|------|---------|------|
| tmux | **VM内** | VMにSSH接続後、VM内でtmuxを使用 |
| screen | **VM内** | VMにSSH接続後、VM内でscreenを使用 |
| バックグラウンドジョブ | **VM内** | VM内でnohupを使用してバックグラウンド実行 |
| 複数SSHセッション | **ローカルマシン** | ローカルマシンから複数のSSH接続を開く |

**推奨：** tmuxを使用する方法（VM内で操作）

## よくある操作

### プロジェクトの更新

```bash
cd ~/projects/my-project
git pull origin main
```

### ブランチの切り替え

```bash
cd ~/projects/my-project
git fetch origin
git checkout feature/new-feature
```

### 変更の確認

```bash
cd ~/projects/my-project
git status
git diff
git log --oneline -10
```

### コミットとプッシュ

```bash
cd ~/projects/my-project
git add .
git commit -m "feat: 新機能を実装"
git push origin feat/new-feature
```

### Claude Codeの履歴確認

```bash
# Claude Codeの会話履歴を確認
# （履歴の場所はClaude Codeのバージョンによって異なる）
ls -la ~/.claude/
```

### エラーの対処

```bash
# Claude Codeが応答しない場合
ps aux | grep claude
kill <PID>  # 必要に応じてプロセスを終了

# 再起動
claude "前回のタスクを続けてください"
```

## ベストプラクティス

### 1. プロジェクトごとに独立したブランチで作業

```bash
# 各タスクごとに新しいブランチを作成
git checkout -b feat/task-description
# 実装
git commit -m "feat: タスクの説明"
git push origin feat/task-description
```

### 2. 定期的なコミット

```bash
# 作業が進んだらこまめにコミット
git add .
git commit -m "WIP: 作業中"
git push origin feat/branch-name
```

### 3. タスクの明確化

```bash
# 曖昧な指示ではなく、具体的な指示を出す
# ❌ 悪い例
claude "改善してください"

# ✅ 良い例
claude "TODO.mdのタスク#3を実装してください。テストも追加し、すべてのテストがパスすることを確認してください"
```

### 4. プロジェクトの状態を確認してから作業開始

```bash
# 作業開始前にプロジェクトの状態を確認
git status
git log --oneline -5
claude "このプロジェクトの現在の状態を確認してください。最新のコミットを確認して、次のタスクを提案してください"
```

### 5. 複数プロジェクトの管理

```bash
# プロジェクト一覧を確認
ls -la ~/projects/

# 各プロジェクトの状態を確認するスクリプト例
for project in ~/projects/*; do
    if [ -d "$project/.git" ]; then
        echo "=== $(basename $project) ==="
        cd "$project"
        git status --short
        echo ""
    fi
done
```

## トラブルシューティング

### Claude Codeが起動しない

```bash
# PATHを確認
which claude
echo $PATH

# Claude Codeのパスを修正
~/gce-for-claude-code/scripts/vm/fix-claude-path.sh
```

### Git認証エラー

```bash
# GitHub認証を再設定
~/gce-for-claude-code/scripts/vm/configure-github.sh
```

### メモリ不足

```bash
# メモリ使用状況を確認
free -h
htop

# 不要なプロセスを終了
ps aux | grep claude
kill <PID>
```

## まとめ

1. **初期セットアップ**: VMに接続し、環境を確認
2. **プロジェクトのクローン**: `~/projects/`配下にクローン
3. **Claude Codeの起動**: プロジェクトディレクトリで`claude`コマンドを実行
4. **実装開始**: タスクを明確に指示し、ブランチで作業
5. **複数プロジェクト**: tmuxやscreenを使用して同時実行

詳細は各セクションを参照してください。

