#!/bin/bash
# Claude Codeインストールスクリプト
# インスタンス内で実行してください

set -e

echo "=========================================="
echo "Claude Codeのインストール"
echo "=========================================="
echo ""

# Claude Codeのインストール
echo "Claude Codeをインストールしています..."
curl -fsSL https://claude.ai/install.sh | bash

echo ""
echo "=========================================="
echo "インストールが完了しました！"
echo "=========================================="
echo ""

# インストール確認
if command -v claude &> /dev/null; then
    echo "✅ Claude Codeがインストールされました"
    claude --version 2>/dev/null || echo "バージョン情報の取得に失敗しました"
else
    echo "⚠️  Claude Codeコマンドが見つかりません"
    echo "PATHを確認してください:"
    echo "  echo \$PATH"
    echo "  which claude"
fi

echo ""
echo "次のステップ:"
echo "1. Claude Codeの動作確認: claude --help"
echo "2. 必要に応じてPATHを設定"
echo ""

