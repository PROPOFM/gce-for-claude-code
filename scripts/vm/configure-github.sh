#!/bin/bash
# GitHub認証設定スクリプト
# インスタンス内で実行してください

set -e

echo "=========================================="
echo "GitHub認証設定"
echo "=========================================="
echo ""

# GitHub CLIのインストール確認
if ! command -v gh &> /dev/null; then
    echo "GitHub CLIをインストールしています..."
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
    sudo apt update
    sudo apt install -y gh
    echo "✅ GitHub CLIのインストールが完了しました"
    echo ""
fi

# GitHub認証の確認
if gh auth status &>/dev/null; then
    echo "既にGitHub認証が設定されています:"
    gh auth status
    echo ""
    read -p "認証を再設定しますか？ (y/N): " REAUTH
    if [[ "$REAUTH" != "y" && "$REAUTH" != "Y" ]]; then
        echo "認証設定をスキップしました"
        exit 0
    fi
    gh auth logout
fi

echo "GitHub認証を設定します"
echo ""
echo "方法1: Personal Access Tokenを使用（推奨）"
echo "方法2: ブラウザで認証"
echo ""
read -p "認証方法を選択してください (1/2): " AUTH_METHOD

if [[ "$AUTH_METHOD" == "1" ]]; then
    read -p "GitHub Personal Access Tokenを入力してください: " GITHUB_TOKEN
    if [[ -n "$GITHUB_TOKEN" ]]; then
        echo "$GITHUB_TOKEN" | gh auth login --with-token
        echo "✅ GitHub認証が完了しました"
    else
        echo "❌ トークンが入力されていません"
        exit 1
    fi
elif [[ "$AUTH_METHOD" == "2" ]]; then
    echo "ブラウザで認証を開始します..."
    gh auth login
    echo "✅ GitHub認証が完了しました"
else
    echo "❌ 無効な選択です"
    exit 1
fi

# 認証状態の確認
echo ""
echo "認証状態:"
gh auth status

# 環境変数にトークンを設定（オプション）
if [[ -n "$GITHUB_TOKEN" ]]; then
    echo ""
    echo "環境変数GITHUB_TOKENを設定しますか？ (y/N): "
    read -p "（~/.bashrcに追加されます）: " SET_ENV
    if [[ "$SET_ENV" == "y" || "$SET_ENV" == "Y" ]]; then
        if ! grep -q "GITHUB_TOKEN" ~/.bashrc; then
            echo "export GITHUB_TOKEN=\"$GITHUB_TOKEN\"" >> ~/.bashrc
            echo "✅ 環境変数を~/.bashrcに追加しました"
        else
            echo "⚠️  環境変数は既に設定されています"
        fi
    fi
fi

echo ""
echo "=========================================="

