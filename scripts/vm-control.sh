#!/bin/bash
# VM制御スクリプト
# Compute Engineインスタンスの起動・停止・状態確認・SSH接続を簡単に行います

set -e

# デフォルト値
PROJECT_ID="${GCP_PROJECT_ID:-gce-for-claude-code}"
INSTANCE_NAME="${INSTANCE_NAME:-claude-code-vm}"
ZONE="${ZONE:-asia-northeast1-a}"

# 使用方法を表示
usage() {
    cat << EOF
使用方法: $0 {start|stop|status|ssh|restart} [オプション]

コマンド:
    start       インスタンスを起動
    stop        インスタンスを停止
    status      インスタンスの状態を確認
    ssh         SSH接続
    restart     インスタンスを再起動

オプション:
    -p, --project-id PROJECT_ID      GCPプロジェクトID（デフォルト: gce-for-claude-code）
    -n, --instance-name NAME         インスタンス名（デフォルト: claude-code-vm）
    -z, --zone ZONE                  ゾーン（デフォルト: asia-northeast1-a）
    -h, --help                        このヘルプを表示

環境変数でも指定可能:
    GCP_PROJECT_ID, INSTANCE_NAME, ZONE

例:
    $0 start
    $0 stop
    $0 status
    $0 ssh
    $0 start -p my-project-id -n my-instance
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
        -h|--help)
            usage
            exit 0
            ;;
        *)
            COMMAND="$1"
            shift
            ;;
    esac
done

# コマンドが指定されていない場合
if [[ -z "$COMMAND" ]]; then
    echo "エラー: コマンドが指定されていません"
    echo ""
    usage
    exit 1
fi

# インスタンスの状態を取得
get_status() {
    gcloud compute instances describe "$INSTANCE_NAME" \
        --zone="$ZONE" \
        --project="$PROJECT_ID" \
        --format="get(status)" 2>/dev/null || echo "NOT_FOUND"
}

# インスタンスを起動
start_instance() {
    local status=$(get_status)
    
    if [[ "$status" == "RUNNING" ]]; then
        echo "✓ インスタンスは既に起動しています"
        return 0
    fi
    
    echo "=========================================="
    echo "インスタンスを起動しています..."
    echo "=========================================="
    echo "プロジェクトID: $PROJECT_ID"
    echo "インスタンス名: $INSTANCE_NAME"
    echo "ゾーン: $ZONE"
    echo ""
    
    gcloud compute instances start "$INSTANCE_NAME" \
        --zone="$ZONE" \
        --project="$PROJECT_ID"
    
    echo ""
    echo "✓ インスタンスの起動を開始しました"
    echo "  SSH接続まで約30秒〜1分お待ちください"
    echo ""
    echo "接続コマンド:"
    echo "  $0 ssh"
    echo "  または"
    echo "  gcloud compute ssh $INSTANCE_NAME --zone=$ZONE --project=$PROJECT_ID"
}

# インスタンスを停止
stop_instance() {
    local status=$(get_status)
    
    if [[ "$status" == "TERMINATED" ]]; then
        echo "✓ インスタンスは既に停止しています"
        return 0
    fi
    
    if [[ "$status" == "NOT_FOUND" ]]; then
        echo "エラー: インスタンスが見つかりません"
        exit 1
    fi
    
    echo "=========================================="
    echo "インスタンスを停止しています..."
    echo "=========================================="
    echo "プロジェクトID: $PROJECT_ID"
    echo "インスタンス名: $INSTANCE_NAME"
    echo "ゾーン: $ZONE"
    echo ""
    
    # 確認プロンプト（オプション）
    read -p "インスタンスを停止しますか？ (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "停止をキャンセルしました"
        exit 0
    fi
    
    gcloud compute instances stop "$INSTANCE_NAME" \
        --zone="$ZONE" \
        --project="$PROJECT_ID"
    
    echo ""
    echo "✓ インスタンスを停止しました"
    echo "  データは保持されています。次回起動時に復元されます。"
}

# インスタンスの状態を確認
check_status() {
    local status=$(get_status)
    
    if [[ "$status" == "NOT_FOUND" ]]; then
        echo "エラー: インスタンスが見つかりません"
        exit 1
    fi
    
    echo "=========================================="
    echo "インスタンスの状態"
    echo "=========================================="
    echo "プロジェクトID: $PROJECT_ID"
    echo "インスタンス名: $INSTANCE_NAME"
    echo "ゾーン: $ZONE"
    echo "状態: $status"
    echo ""
    
    case "$status" in
        RUNNING)
            echo "✓ インスタンスは起動中です"
            echo ""
            echo "外部IPアドレス:"
            gcloud compute instances describe "$INSTANCE_NAME" \
                --zone="$ZONE" \
                --project="$PROJECT_ID" \
                --format="get(networkInterfaces[0].accessConfigs[0].natIP)" 2>/dev/null || echo "  (取得できませんでした)"
            ;;
        TERMINATED)
            echo "⚠ インスタンスは停止中です"
            echo "  起動するには: $0 start"
            ;;
        *)
            echo "⚠ インスタンスの状態: $status"
            ;;
    esac
}

# SSH接続
ssh_connect() {
    local status=$(get_status)
    
    if [[ "$status" != "RUNNING" ]]; then
        echo "エラー: インスタンスが起動していません（現在の状態: $status）"
        echo ""
        echo "先にインスタンスを起動してください:"
        echo "  $0 start"
        exit 1
    fi
    
    echo "SSH接続中..."
    echo ""
    
    gcloud compute ssh "$INSTANCE_NAME" \
        --zone="$ZONE" \
        --project="$PROJECT_ID"
}

# インスタンスを再起動
restart_instance() {
    local status=$(get_status)
    
    if [[ "$status" == "NOT_FOUND" ]]; then
        echo "エラー: インスタンスが見つかりません"
        exit 1
    fi
    
    echo "=========================================="
    echo "インスタンスを再起動しています..."
    echo "=========================================="
    
    gcloud compute instances reset "$INSTANCE_NAME" \
        --zone="$ZONE" \
        --project="$PROJECT_ID"
    
    echo ""
    echo "✓ インスタンスを再起動しました"
}

# コマンド実行
case "$COMMAND" in
    start)
        start_instance
        ;;
    stop)
        stop_instance
        ;;
    status)
        check_status
        ;;
    ssh)
        ssh_connect
        ;;
    restart)
        restart_instance
        ;;
    *)
        echo "エラー: 不明なコマンド: $COMMAND"
        echo ""
        usage
        exit 1
        ;;
esac

