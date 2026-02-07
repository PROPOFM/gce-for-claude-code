#!/bin/bash
# Git設定スクリプト
# インスタンス内で実行してください
# 注意: VM内では PROPOFMDEV をユーザー名として使用します

set -e

echo "=========================================="
echo "Git設定"
echo "=========================================="
echo ""
echo "注意: VM内では 'PROPOFMDEV' をユーザー名として使用します"
echo ""

# 現在の設定を確認
echo "現在のGit設定:"
git config --global --list 2>/dev/null | grep -E "(user.name|user.email)" || echo "未設定"
echo ""

# ユーザー名とメールアドレスの設定
read -p "Gitユーザー名を入力してください [デフォルト: PROPOFMDEV]: " GIT_USER_NAME
GIT_USER_NAME=${GIT_USER_NAME:-PROPOFMDEV}

read -p "Gitメールアドレスを入力してください: " GIT_USER_EMAIL

if [[ -n "$GIT_USER_NAME" && -n "$GIT_USER_EMAIL" ]]; then
    git config --global user.name "$GIT_USER_NAME"
    git config --global user.email "$GIT_USER_EMAIL"
    echo ""
    echo "✅ Git設定が完了しました:"
    git config --global --list | grep -E "(user.name|user.email)"
else
    echo "❌ ユーザー名とメールアドレスの両方を入力してください"
    exit 1
fi

echo ""
echo "=========================================="

