#!/bin/bash
# ユーザーアクセス権追加スクリプト
# GCPプロジェクトにユーザーを追加し、Compute Engineインスタンスへのアクセス権を付与します

set -e

# デフォルト値
PROJECT_ID="${GCP_PROJECT_ID:-gce-for-claude-code}"

# 使用方法を表示
usage() {
    cat << EOF
使用方法: $0 EMAIL [オプション]

引数:
    EMAIL         追加するユーザーのメールアドレス（例: user@example.com）

オプション:
    -p, --project-id PROJECT_ID      GCPプロジェクトID（デフォルト: gce-for-claude-code）
    -r, --role ROLE                  付与するロール（デフォルト: compute.osAdminLogin）
    -h, --help                        このヘルプを表示

環境変数でも指定可能:
    GCP_PROJECT_ID

利用可能なロール:
    compute.osAdminLogin      - SSH接続権限（推奨）
    compute.instanceAdmin     - インスタンス管理権限（起動・停止・削除など）
    compute.viewer            - インスタンス情報の閲覧のみ

例:
    $0 develop@propo.fm
    $0 user@example.com -p my-project-id
    $0 user@example.com -r roles/compute.instanceAdmin
EOF
}

# オプション解析
ROLE="roles/compute.osAdminLogin"
while [[ $# -gt 0 ]]; do
    case $1 in
        -p|--project-id)
            PROJECT_ID="$2"
            shift 2
            ;;
        -r|--role)
            ROLE="$2"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            if [[ -z "$USER_EMAIL" ]]; then
                USER_EMAIL="$1"
            else
                echo "エラー: 不明なオプション: $1"
                echo ""
                usage
                exit 1
            fi
            shift
            ;;
    esac
done

# メールアドレスの確認
if [[ -z "$USER_EMAIL" ]]; then
    echo "エラー: メールアドレスが指定されていません"
    echo ""
    usage
    exit 1
fi

# メールアドレスの形式チェック（簡易）
if [[ ! "$USER_EMAIL" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
    echo "エラー: 無効なメールアドレス形式: $USER_EMAIL"
    exit 1
fi

echo "=========================================="
echo "ユーザーアクセス権の追加"
echo "=========================================="
echo "プロジェクトID: $PROJECT_ID"
echo "ユーザー: $USER_EMAIL"
echo "ロール: $ROLE"
echo "=========================================="
echo ""

# 確認プロンプト
read -p "このユーザーにアクセス権を付与しますか？ (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "処理をキャンセルしました"
    exit 0
fi

# IAMポリシーバインディングの追加
echo ""
echo "IAMポリシーバインディングを追加しています..."
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
    --member="user:$USER_EMAIL" \
    --role="$ROLE"

echo ""
echo "=========================================="
echo "✓ アクセス権の追加が完了しました"
echo "=========================================="
echo ""
echo "ユーザー $USER_EMAIL は以下の権限でアクセスできます:"
echo "  - ロール: $ROLE"
echo ""
echo "SSH接続方法:"
echo "  gcloud compute ssh claude-code-vm --zone=asia-northeast2-a --project=$PROJECT_ID"
echo ""
echo "注意: ユーザーが初回ログインする際は、GCPアカウントで認証が必要です。"
echo "      gcloud auth login を実行してください。"

