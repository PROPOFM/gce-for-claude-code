#!/bin/bash
# Claude CodeのPATH設定スクリプト
# インスタンス内で実行してください

set -e

echo "=========================================="
echo "Claude CodeのPATH設定"
echo "=========================================="
echo ""

# 一般的なインストール先を確認
INSTALL_PATHS=(
    "$HOME/.local/bin"
    "$HOME/.claude/bin"
    "/usr/local/bin"
    "$HOME/bin"
)

FOUND_PATH=""

for path in "${INSTALL_PATHS[@]}"; do
    if [ -f "$path/claude" ]; then
        FOUND_PATH="$path"
        echo "✅ Claude Codeが見つかりました: $path/claude"
        break
    fi
done

# 見つからない場合、findで検索
if [ -z "$FOUND_PATH" ]; then
    echo "Claude Codeを検索しています..."
    FOUND_PATH=$(find "$HOME" -name "claude" -type f 2>/dev/null | head -1 | xargs dirname 2>/dev/null || echo "")
    
    if [ -n "$FOUND_PATH" ]; then
        echo "✅ Claude Codeが見つかりました: $FOUND_PATH/claude"
    else
        echo "❌ Claude Codeが見つかりませんでした"
        echo ""
        echo "手動でインストール先を確認してください:"
        echo "  find ~ -name 'claude' -type f 2>/dev/null"
        exit 1
    fi
fi

# PATHに追加
if [[ ":$PATH:" != *":$FOUND_PATH:"* ]]; then
    echo ""
    echo "PATHに追加しています..."
    
    # .bashrcに追加
    if ! grep -q "$FOUND_PATH" ~/.bashrc; then
        echo "" >> ~/.bashrc
        echo "# Claude Code PATH" >> ~/.bashrc
        echo "export PATH=\"\$PATH:$FOUND_PATH\"" >> ~/.bashrc
        echo "✅ ~/.bashrcにPATHを追加しました"
    else
        echo "⚠️  ~/.bashrcに既にPATHが設定されています"
    fi
    
    # 現在のセッションにも追加
    export PATH="$PATH:$FOUND_PATH"
    echo "✅ 現在のセッションのPATHを更新しました"
else
    echo "✅ PATHは既に設定されています"
fi

echo ""
echo "=========================================="
echo "設定が完了しました！"
echo "=========================================="
echo ""

# 動作確認
if command -v claude &> /dev/null; then
    echo "✅ Claude Codeコマンドが利用可能です"
    claude --version 2>/dev/null || claude --help 2>/dev/null | head -5
else
    echo "⚠️  新しいシェルセッションを開始してください:"
    echo "  source ~/.bashrc"
    echo "  または"
    echo "  exec bash"
fi

echo ""

