#!/bin/bash
# Cloud Scheduler設定スクリプト
# 毎朝6時にインスタンスを自動停止するスケジュールを設定します

set -e

# デフォルト値
PROJECT_ID="${GCP_PROJECT_ID:-gce-for-claude-code}"
INSTANCE_NAME="${INSTANCE_NAME:-claude-code-vm}"
ZONE="${ZONE:-asia-northeast1-a}"
REGION="${REGION:-asia-northeast1}"
FUNCTION_NAME="stop-instance"
SCHEDULER_JOB_NAME="stop-instance-daily-6am"
SCHEDULE="0 6 * * *"  # 毎朝6時（JST）
TIMEZONE="Asia/Tokyo"

# 使用方法を表示
usage() {
    cat << EOF
使用方法: $0 [オプション]

このスクリプトは、毎朝6時にインスタンスを自動停止するCloud Schedulerジョブを設定します。

オプション:
    -p, --project-id PROJECT_ID      GCPプロジェクトID（デフォルト: gce-for-claude-code）
    -n, --instance-name NAME         インスタンス名（デフォルト: claude-code-vm）
    -z, --zone ZONE                  ゾーン（デフォルト: asia-northeast1-a）
    -r, --region REGION              リージョン（デフォルト: asia-northeast1）
    -s, --schedule SCHEDULE          Cron形式のスケジュール（デフォルト: "0 6 * * *"）
    -t, --timezone TIMEZONE          タイムゾーン（デフォルト: Asia/Tokyo）
    -h, --help                        このヘルプを表示

環境変数でも指定可能:
    GCP_PROJECT_ID, INSTANCE_NAME, ZONE, REGION

前提条件:
    1. Cloud Functions API が有効化されていること
    2. Cloud Scheduler API が有効化されていること
    3. Cloud Functions が既にデプロイされていること（setup-functions.sh を先に実行）

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
        -s|--schedule)
            SCHEDULE="$2"
            shift 2
            ;;
        -t|--timezone)
            TIMEZONE="$2"
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
echo "Cloud Scheduler設定"
echo "=========================================="
echo "プロジェクトID: $PROJECT_ID"
echo "インスタンス名: $INSTANCE_NAME"
echo "ゾーン: $ZONE"
echo "リージョン: $REGION"
echo "スケジュール: $SCHEDULE ($TIMEZONE)"
echo "=========================================="
echo ""

# プロジェクトの設定
echo "プロジェクトを設定しています..."
gcloud config set project "$PROJECT_ID"

# 必要なAPIの有効化
echo ""
echo "必要なAPIを有効化しています..."
gcloud services enable cloudscheduler.googleapis.com --project="$PROJECT_ID" || true
gcloud services enable cloudfunctions.googleapis.com --project="$PROJECT_ID" || true

# Cloud Functions のURLを取得（Gen2対応）
FUNCTION_URL=$(gcloud functions describe "$FUNCTION_NAME" \
    --gen2 \
    --region="$REGION" \
    --project="$PROJECT_ID" \
    --format="get(serviceConfig.uri)" 2>/dev/null || \
    gcloud functions describe "$FUNCTION_NAME" \
    --region="$REGION" \
    --project="$PROJECT_ID" \
    --format="get(httpsTrigger.url)" 2>/dev/null || echo "")

if [[ -z "$FUNCTION_URL" ]]; then
    echo ""
    echo "エラー: Cloud Function '$FUNCTION_NAME' が見つかりません"
    echo "先に setup-functions.sh を実行してCloud Functionをデプロイしてください"
    exit 1
fi

echo ""
echo "Cloud Function URL: $FUNCTION_URL"

# サービスアカウントの作成（既に存在する場合はスキップ）
SERVICE_ACCOUNT_NAME="cloud-scheduler-sa"
SERVICE_ACCOUNT_EMAIL="${SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"

echo ""
echo "サービスアカウントを確認しています..."
if ! gcloud iam service-accounts describe "$SERVICE_ACCOUNT_EMAIL" --project="$PROJECT_ID" &>/dev/null; then
    echo "サービスアカウントを作成しています..."
    gcloud iam service-accounts create "$SERVICE_ACCOUNT_NAME" \
        --display-name="Cloud Scheduler Service Account" \
        --project="$PROJECT_ID"
    
    # 必要な権限を付与
    echo "権限を付与しています..."
    gcloud projects add-iam-policy-binding "$PROJECT_ID" \
        --member="serviceAccount:${SERVICE_ACCOUNT_EMAIL}" \
        --role="roles/cloudfunctions.invoker"
    
    gcloud projects add-iam-policy-binding "$PROJECT_ID" \
        --member="serviceAccount:${SERVICE_ACCOUNT_EMAIL}" \
        --role="roles/compute.instanceAdmin.v1"
else
    echo "サービスアカウントは既に存在します"
fi

# 既存のスケジュールジョブを削除（存在する場合）
echo ""
echo "既存のスケジュールジョブを確認しています..."
if gcloud scheduler jobs describe "$SCHEDULER_JOB_NAME" \
    --location="$REGION" \
    --project="$PROJECT_ID" &>/dev/null; then
    echo "既存のスケジュールジョブを削除しています..."
    gcloud scheduler jobs delete "$SCHEDULER_JOB_NAME" \
        --location="$REGION" \
        --project="$PROJECT_ID" \
        --quiet
fi

# Cloud Schedulerジョブを作成
echo ""
echo "Cloud Schedulerジョブを作成しています..."
gcloud scheduler jobs create http "$SCHEDULER_JOB_NAME" \
    --location="$REGION" \
    --schedule="$SCHEDULE" \
    --time-zone="$TIMEZONE" \
    --uri="$FUNCTION_URL" \
    --http-method=POST \
    --oidc-service-account-email="$SERVICE_ACCOUNT_EMAIL" \
    --description="毎朝6時にインスタンスを自動停止" \
    --project="$PROJECT_ID"

echo ""
echo "=========================================="
echo "Cloud Scheduler設定が完了しました！"
echo "=========================================="
echo ""
echo "スケジュールジョブ: $SCHEDULER_JOB_NAME"
echo "実行スケジュール: 毎朝6時（$TIMEZONE）"
echo "対象インスタンス: $INSTANCE_NAME"
echo ""
echo "確認コマンド:"
echo "  gcloud scheduler jobs describe $SCHEDULER_JOB_NAME --location=$REGION --project=$PROJECT_ID"
echo ""
echo "手動実行（テスト）:"
echo "  gcloud scheduler jobs run $SCHEDULER_JOB_NAME --location=$REGION --project=$PROJECT_ID"
echo ""

