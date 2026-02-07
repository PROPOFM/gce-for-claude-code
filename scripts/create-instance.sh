#!/bin/bash
# GCP Compute Engine インスタンス作成スクリプト
# Claude Code実行環境用のインスタンスを作成します

set -e

# デフォルト値
PROJECT_ID="${GCP_PROJECT_ID:-}"
INSTANCE_NAME="${INSTANCE_NAME:-claude-code-vm}"
MACHINE_TYPE="${MACHINE_TYPE:-e2-standard-2}"
ZONE="${ZONE:-asia-northeast1-a}"
DISK_SIZE="${DISK_SIZE:-50}"
IMAGE_FAMILY="${IMAGE_FAMILY:-ubuntu-2204-lts}"
IMAGE_PROJECT="${IMAGE_PROJECT:-ubuntu-os-cloud}"

# 使用方法を表示
usage() {
    cat << EOF
使用方法: $0 [オプション]

オプション:
    -p, --project-id PROJECT_ID      GCPプロジェクトID（必須）
    -n, --instance-name NAME         インスタンス名（デフォルト: claude-code-vm）
    -m, --machine-type TYPE          マシンタイプ（デフォルト: e2-standard-2）
    -z, --zone ZONE                  ゾーン（デフォルト: asia-northeast1-a）
    -d, --disk-size SIZE             ディスクサイズ（GB、デフォルト: 50）
    -h, --help                        このヘルプを表示

環境変数でも指定可能:
    GCP_PROJECT_ID, INSTANCE_NAME, MACHINE_TYPE, ZONE, DISK_SIZE

例:
    $0 -p my-project-id
    $0 -p my-project-id -n my-vm -m e2-standard-4 -z us-central1-a
EOF
    exit 1
}

# 引数の解析
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
        -m|--machine-type)
            MACHINE_TYPE="$2"
            shift 2
            ;;
        -z|--zone)
            ZONE="$2"
            shift 2
            ;;
        -d|--disk-size)
            DISK_SIZE="$2"
            shift 2
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo "不明なオプション: $1"
            usage
            ;;
    esac
done

# プロジェクトIDの確認
if [[ -z "$PROJECT_ID" ]]; then
    echo "エラー: GCPプロジェクトIDが指定されていません"
    echo ""
    usage
fi

echo "=========================================="
echo "Compute Engine インスタンス作成"
echo "=========================================="
echo "プロジェクトID: $PROJECT_ID"
echo "インスタンス名: $INSTANCE_NAME"
echo "マシンタイプ: $MACHINE_TYPE"
echo "ゾーン: $ZONE"
echo "ディスクサイズ: ${DISK_SIZE}GB"
echo "OSイメージ: $IMAGE_FAMILY"
echo "=========================================="
echo ""

# プロジェクトの設定
echo "プロジェクトを設定しています..."
gcloud config set project "$PROJECT_ID"

# 必要なAPIの有効化
echo ""
echo "必要なAPIを有効化しています..."
gcloud services enable compute.googleapis.com --project="$PROJECT_ID"
gcloud services enable cloudresourcemanager.googleapis.com --project="$PROJECT_ID"
gcloud services enable iam.googleapis.com --project="$PROJECT_ID"

# インスタンスの作成
echo ""
echo "インスタンスを作成しています..."
gcloud compute instances create "$INSTANCE_NAME" \
    --project="$PROJECT_ID" \
    --zone="$ZONE" \
    --machine-type="$MACHINE_TYPE" \
    --network-interface=network-tier=PREMIUM,subnet=default \
    --maintenance-policy=MIGRATE \
    --provisioning-model=STANDARD \
    --no-service-account --no-scopes \
    --create-disk=auto-delete=yes,boot=yes,device-name="$INSTANCE_NAME",image=projects/$IMAGE_PROJECT/global/images/family/$IMAGE_FAMILY,mode=rw,size="${DISK_SIZE}GB",type=projects/$PROJECT_ID/zones/$ZONE/diskTypes/pd-standard \
    --no-shielded-secure-boot \
    --shielded-vtpm \
    --shielded-integrity-monitoring \
    --labels=env=claude-code,purpose=development \
    --reservation-affinity=any

echo ""
echo "=========================================="
echo "インスタンス作成が完了しました！"
echo "=========================================="
echo ""
echo "接続コマンド:"
echo "  gcloud compute ssh $INSTANCE_NAME --zone=$ZONE --project=$PROJECT_ID"
echo ""
echo "インスタンス情報の確認:"
echo "  gcloud compute instances describe $INSTANCE_NAME --zone=$ZONE --project=$PROJECT_ID"
echo ""

