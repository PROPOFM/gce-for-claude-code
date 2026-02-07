#!/bin/bash
# Cloud Functions デプロイスクリプト
# インスタンスを停止するCloud Functionをデプロイします

set -e

# デフォルト値
PROJECT_ID="${GCP_PROJECT_ID:-gce-for-claude-code}"
INSTANCE_NAME="${INSTANCE_NAME:-claude-code-vm}"
ZONE="${ZONE:-asia-northeast1-a}"
REGION="${REGION:-asia-northeast1}"
FUNCTION_NAME="stop-instance"

# 使用方法を表示
usage() {
    cat << EOF
使用方法: $0 [オプション]

このスクリプトは、インスタンスを停止するCloud Functionをデプロイします。

オプション:
    -p, --project-id PROJECT_ID      GCPプロジェクトID（デフォルト: gce-for-claude-code）
    -n, --instance-name NAME         インスタンス名（デフォルト: claude-code-vm）
    -z, --zone ZONE                  ゾーン（デフォルト: asia-northeast1-a）
    -r, --region REGION              リージョン（デフォルト: asia-northeast1）
    -h, --help                        このヘルプを表示

環境変数でも指定可能:
    GCP_PROJECT_ID, INSTANCE_NAME, ZONE, REGION

前提条件:
    1. Cloud Functions API が有効化されていること
    2. Cloud Build API が有効化されていること

例:
    $0
    $0 -p my-project-id -n my-instance
EOF
}

# オプション解析
while [[ $# -gt 0 ]]; do
    case $1 in
        -p|--project-id)
            PROJECT_ID="$2"
            shift 2
            ;;
        -n|--instance-name)
            INSTANCE_NAME="$2"
            shift 2
            ;;
        -z|--zone)
            ZONE="$2"
            shift 2
            ;;
        -r|--region)
            REGION="$2"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "エラー: 不明なオプション: $1"
            usage
            exit 1
            ;;
    esac
done

echo "=========================================="
echo "Cloud Functions デプロイ"
echo "=========================================="
echo "プロジェクトID: $PROJECT_ID"
echo "インスタンス名: $INSTANCE_NAME"
echo "ゾーン: $ZONE"
echo "リージョン: $REGION"
echo "関数名: $FUNCTION_NAME"
echo "=========================================="
echo ""

# プロジェクトの設定
echo "プロジェクトを設定しています..."
gcloud config set project "$PROJECT_ID"

# 必要なAPIの有効化
echo ""
echo "必要なAPIを有効化しています..."
gcloud services enable cloudfunctions.googleapis.com --project="$PROJECT_ID" || true
gcloud services enable cloudbuild.googleapis.com --project="$PROJECT_ID" || true
gcloud services enable run.googleapis.com --project="$PROJECT_ID" || true
gcloud services enable artifactregistry.googleapis.com --project="$PROJECT_ID" || true
echo "APIの有効化が完了しました。数分待ってからデプロイを再試行してください。"

# スクリプトのディレクトリを取得
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
FUNCTIONS_DIR="$PROJECT_ROOT/functions/stop_instance"

if [[ ! -d "$FUNCTIONS_DIR" ]]; then
    echo "エラー: Cloud Functions のコードが見つかりません: $FUNCTIONS_DIR"
    exit 1
fi

# Cloud Functionをデプロイ
echo ""
echo "Cloud Functionをデプロイしています..."
cd "$FUNCTIONS_DIR"

gcloud functions deploy "$FUNCTION_NAME" \
    --gen2 \
    --runtime=python311 \
    --region="$REGION" \
    --source=. \
    --entry-point=stop_instance \
    --trigger-http \
    --allow-unauthenticated \
    --set-env-vars="INSTANCE_NAME=$INSTANCE_NAME,ZONE=$ZONE,PROJECT_ID=$PROJECT_ID" \
    --project="$PROJECT_ID" \
    --memory=256MB \
    --timeout=60s

# 関数のURLを取得
FUNCTION_URL=$(gcloud functions describe "$FUNCTION_NAME" \
    --gen2 \
    --region="$REGION" \
    --project="$PROJECT_ID" \
    --format="get(serviceConfig.uri)" 2>/dev/null || \
    gcloud functions describe "$FUNCTION_NAME" \
    --region="$REGION" \
    --project="$PROJECT_ID" \
    --format="get(httpsTrigger.url)" 2>/dev/null || echo "")

echo ""
echo "=========================================="
echo "Cloud Function デプロイが完了しました！"
echo "=========================================="
echo ""
echo "関数名: $FUNCTION_NAME"
echo "URL: $FUNCTION_URL"
echo ""
echo "次のステップ:"
echo "  ./scripts/setup-scheduler.sh を実行してCloud Schedulerを設定してください"
echo ""

