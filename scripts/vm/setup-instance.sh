#!/bin/bash
# インスタンス内での環境構築スクリプト
# このスクリプトはインスタンスにSSH接続後に実行します

set -e

echo "=========================================="
echo "Claude Code環境のセットアップ"
echo "=========================================="
echo ""

# システムの更新
echo "システムパッケージを更新しています..."
sudo apt update
sudo apt upgrade -y

# 基本ツールのインストール
echo ""
echo "基本開発ツールをインストールしています..."
sudo apt install -y \
    git \
    curl \
    wget \
    build-essential \
    ca-certificates \
    gnupg \
    lsb-release \
    vim \
    tmux \
    htop \
    unzip

# プロジェクト用ディレクトリの作成
echo ""
echo "プロジェクト用ディレクトリを作成しています..."
mkdir -p ~/projects
echo 'export PROJECTS_DIR="$HOME/projects"' >> ~/.bashrc
echo "✓ ~/projects/ ディレクトリを作成しました"

# Git設定（環境変数から取得、または手動設定が必要）
if [[ -n "$GIT_USER_NAME" && -n "$GIT_USER_EMAIL" ]]; then
    echo ""
    echo "Git設定を行っています..."
    git config --global user.name "$GIT_USER_NAME"
    git config --global user.email "$GIT_USER_EMAIL"
else
    echo ""
    echo "警告: GIT_USER_NAME と GIT_USER_EMAIL が設定されていません"
    echo "後で手動で設定してください:"
    echo "  git config --global user.name 'Your Name'"
    echo "  git config --global user.email 'your.email@example.com'"
fi

# Claude Codeのインストール
# 注意: Claude Codeの実際のインストール手順は公式ドキュメントを確認してください
echo ""
echo "=========================================="
echo "Claude Codeのインストール"
echo "=========================================="
echo "注意: Claude Codeのインストール手順は公式ドキュメントを参照してください"
echo ""

# Google Cloud SDK (gcloud) のインストール
echo ""
echo "=========================================="
echo "Google Cloud SDK のインストール"
echo "=========================================="
if ! command -v gcloud &> /dev/null; then
    echo "Google Cloud SDK をインストールしています..."
    echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -
    sudo apt update
    sudo apt install -y google-cloud-cli
    echo "✓ Google Cloud SDK をインストールしました"
else
    echo "✓ Google Cloud SDK は既にインストールされています"
fi

# gcloud の初期設定（プロジェクト設定のみ、認証は手動で行う）
if command -v gcloud &> /dev/null; then
    echo ""
    echo "Google Cloud SDK の初期設定を行っています..."
    gcloud config set project gce-for-claude-code || true
    gcloud config set compute/region asia-northeast2 || true
    gcloud config set compute/zone asia-northeast2-a || true
    echo "✓ デフォルトプロジェクトとリージョンを設定しました"
    echo ""
    echo "注意: gcloud の認証は手動で行ってください:"
    echo "  gcloud auth login --no-launch-browser"
    echo "  gcloud auth application-default login --no-launch-browser  # SDK から API を呼ぶ場合"
fi

# GitHub認証の設定（Personal Access Tokenが必要）
if [[ -n "$GITHUB_TOKEN" ]]; then
    echo ""
    echo "GitHub認証を設定しています..."
    # GitHub CLIのインストール（オプション）
    if ! command -v gh &> /dev/null; then
        echo "GitHub CLIをインストールしています..."
        curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
        sudo apt update
        sudo apt install -y gh
    fi
    
    # GitHub CLIで認証
    echo "$GITHUB_TOKEN" | gh auth login --with-token
else
    echo ""
    echo "警告: GITHUB_TOKEN が設定されていません"
    echo "GitHub認証を手動で設定してください"
fi

echo ""
echo "=========================================="
echo "セットアップが完了しました！"
echo "=========================================="
echo ""
echo "次のステップ:"
echo "1. Claude Codeをインストール（公式手順に従って）"
echo "2. GitHub認証を設定（Personal Access Tokenを使用）"
echo "3. gcloud の認証（VM 上で gcloud を使う場合）: gcloud auth login --no-launch-browser"
echo "4. 動作確認"
echo ""

