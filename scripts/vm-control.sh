#!/bin/bash
# VM制御スクリプト
# Compute Engineインスタンスの起動・停止・状態確認・SSH接続を簡単に行います
# 接続失敗時はエラーの種別に応じた対処案を表示します。

set -e

# デフォルト値
PROJECT_ID="${GCP_PROJECT_ID:-gce-for-claude-code}"
INSTANCE_NAME="${INSTANCE_NAME:-claude-code-vm}"
ZONE="${ZONE:-asia-northeast2-a}"

# エラー時の対処案を表示する関数
show_remediation_zone_exhausted() {
    cat << 'REMEDIATION'

----------------------------------------
【原因】
指定ゾーンで、このマシンタイプの空きリソースが一時的に不足しています。
（混雑や時間帯により発生します。あなたの設定ミスではありません。）

----------------------------------------
【対処法】

1. 時間をおいて再試行
   数分〜数時間後に、同じコマンドを再度実行してください。
   ./scripts/vm-control.sh start

2. 別ゾーンへインスタンスを移行する（確実な方法）
   スナップショットを作成し、別ゾーンでインスタンスを作り直す手順です。
   詳細は README の「起動失敗（ZONE_RESOURCE_POOL_EXHAUSTED）」を参照してください。
   - ファイル: README.md の「トラブルシューティング」セクション
   - 手順: スナップショット作成 → 別ゾーンにディスク作成 → 旧削除 → 新規作成

移行後は、起動・SSH・停止時にゾーンを指定してください。
例: ./scripts/vm-control.sh start -z asia-northeast2-a

----------------------------------------
REMEDIATION
}

show_remediation_instance_not_found() {
    echo ""
    echo "----------------------------------------"
    echo "【ヒント】インスタンスが別ゾーンにある場合"
    echo "----------------------------------------"
    echo "インスタンスを別ゾーンに移行済みの場合は、-z でゾーンを指定してください。"
    echo ""
    echo "例:"
    echo "  $0 start -z asia-northeast2-a"
    echo "  $0 ssh -z asia-northeast2-a"
    echo ""
    echo "どのゾーンにインスタンスがあるか確認するには:"
    echo "  gcloud compute instances list --project=$PROJECT_ID --filter=\"name=$INSTANCE_NAME\""
    echo ""
}

# 権限不足時の対処案（プロジェクト管理者向けのロール追加案内）
show_remediation_permission_denied() {
    cat << 'REMEDIATION'

----------------------------------------
【原因】
このアカウントに、Compute Engine を操作するための権限が不足しています。
プロジェクトの管理者に、以下のロールを付与するよう依頼してください。

----------------------------------------
【追加するロール】

  ロール名                          できること
  ----------------------------------------
  roles/compute.viewer               インスタンスの参照（一覧・詳細）
  roles/compute.osAdminLogin         SSH で VM にログイン
  roles/compute.instanceAdmin.v1     インスタンスの起動・停止・再起動など

----------------------------------------
【管理者が実行するコマンド例】

  1. 参照・起動・停止・SSH をまとめて付与する場合:
     gcloud projects add-iam-policy-binding PROJECT_ID \
       --member="user:メールアドレス@example.com" \
       --role="roles/compute.viewer"
     gcloud projects add-iam-policy-binding PROJECT_ID \
       --member="user:メールアドレス@example.com" \
       --role="roles/compute.osAdminLogin"
     gcloud projects add-iam-policy-binding PROJECT_ID \
       --member="user:メールアドレス@example.com" \
       --role="roles/compute.instanceAdmin.v1"

  2. または、インスタンス単位で付与する場合:
     gcloud compute instances add-iam-policy-binding INSTANCE_NAME \
       --zone=ZONE \
       --member="user:メールアドレス@example.com" \
       --role="roles/compute.instanceAdmin.v1"
     （viewer / osAdminLogin はプロジェクト単位で付与するのが一般的です）

  PROJECT_ID / INSTANCE_NAME / ZONE は実際の値に置き換えてください。

----------------------------------------
REMEDIATION
}

# gcloud のエラー出力が権限不足かどうかを判定
is_permission_denied() {
    local output="$1"
    echo "$output" | grep -qE "PERMISSION_DENIED|Permission denied|does not have permission|Required.*permission|403 Forbidden"
}

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
    -z, --zone ZONE                  ゾーン（デフォルト: asia-northeast2-a）
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
    
    if [[ "$status" == "NOT_FOUND" ]]; then
        echo ""
        echo "エラー: ゾーン $ZONE にインスタンス \"$INSTANCE_NAME\" が見つかりません。"
        set +e
        describe_err=$(gcloud compute instances describe "$INSTANCE_NAME" \
            --zone="$ZONE" \
            --project="$PROJECT_ID" 2>&1)
        set -e
        if is_permission_denied "$describe_err"; then
            show_remediation_permission_denied
        else
            show_remediation_instance_not_found
        fi
        exit 1
    fi
    
    echo "=========================================="
    echo "インスタンスを起動しています..."
    echo "=========================================="
    echo "プロジェクトID: $PROJECT_ID"
    echo "インスタンス名: $INSTANCE_NAME"
    echo "ゾーン: $ZONE"
    echo ""
    
    set +e
    gcloud_output=$(gcloud compute instances start "$INSTANCE_NAME" \
        --zone="$ZONE" \
        --project="$PROJECT_ID" 2>&1)
    gcloud_exit=$?
    set -e
    
    if [[ $gcloud_exit -ne 0 ]]; then
        echo ""
        echo "========================================"
        echo "起動に失敗しました"
        echo "========================================"
        echo ""
        echo "$gcloud_output"
        if is_permission_denied "$gcloud_output"; then
            show_remediation_permission_denied
        elif echo "$gcloud_output" | grep -q "ZONE_RESOURCE_POOL_EXHAUSTED"; then
            show_remediation_zone_exhausted
        else
            echo ""
            echo "----------------------------------------"
            echo "上記のエラーメッセージを確認し、必要に応じて README のトラブルシューティングを参照してください。"
            echo "----------------------------------------"
        fi
        exit $gcloud_exit
    fi
    
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
    
    set +e
    gcloud_output=$(gcloud compute instances stop "$INSTANCE_NAME" \
        --zone="$ZONE" \
        --project="$PROJECT_ID" 2>&1)
    gcloud_exit=$?
    set -e
    
    if [[ $gcloud_exit -ne 0 ]]; then
        echo ""
        echo "========================================"
        echo "停止に失敗しました"
        echo "========================================"
        echo ""
        echo "$gcloud_output"
        if is_permission_denied "$gcloud_output"; then
            show_remediation_permission_denied
        else
            echo ""
            echo "----------------------------------------"
            echo "上記のエラーメッセージを確認してください。"
            echo "----------------------------------------"
        fi
        exit $gcloud_exit
    fi
    
    echo ""
    echo "✓ インスタンスを停止しました"
    echo "  データは保持されています。次回起動時に復元されます。"
}

# インスタンスの状態を確認
check_status() {
    local status=$(get_status)
    
    if [[ "$status" == "NOT_FOUND" ]]; then
        echo ""
        echo "エラー: ゾーン $ZONE にインスタンス \"$INSTANCE_NAME\" が見つかりません。"
        set +e
        describe_err=$(gcloud compute instances describe "$INSTANCE_NAME" \
            --zone="$ZONE" \
            --project="$PROJECT_ID" 2>&1)
        set -e
        if is_permission_denied "$describe_err"; then
            show_remediation_permission_denied
        else
            show_remediation_instance_not_found
        fi
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
    
    if [[ "$status" == "NOT_FOUND" ]]; then
        echo ""
        echo "エラー: ゾーン $ZONE にインスタンス \"$INSTANCE_NAME\" が見つかりません。"
        echo "（別ゾーンに移行済みの場合は -z でゾーンを指定してください）"
        set +e
        describe_err=$(gcloud compute instances describe "$INSTANCE_NAME" \
            --zone="$ZONE" \
            --project="$PROJECT_ID" 2>&1)
        set -e
        if is_permission_denied "$describe_err"; then
            show_remediation_permission_denied
        else
            show_remediation_instance_not_found
        fi
        exit 1
    fi
    
    if [[ "$status" != "RUNNING" ]]; then
        echo ""
        echo "エラー: インスタンスが起動していません（現在の状態: $status）"
        echo ""
        echo "先にインスタンスを起動してください:"
        echo "  $0 start"
        if [[ "$status" == "TERMINATED" ]]; then
            echo ""
            echo "ゾーンを指定する場合: $0 start -z <ゾーン名>"
        fi
        exit 1
    fi
    
    echo "SSH接続中..."
    echo ""
    
    # hirotososhizakiユーザーで接続（SSH鍵ファイルを指定）
    local ssh_key_file="${HOME}/.ssh/id_ed25519"
    if [[ ! -f "$ssh_key_file" ]]; then
        ssh_key_file="${HOME}/.ssh/id_rsa"
    fi
    
    if [[ -f "$ssh_key_file" ]]; then
        gcloud compute ssh "$INSTANCE_NAME" \
            --zone="$ZONE" \
            --project="$PROJECT_ID" \
            --ssh-key-file="$ssh_key_file" \
            --ssh-flag="-l hirotososhizaki" \
            --ssh-flag="-t"
    else
        # SSH鍵が見つからない場合はデフォルトの接続方法を使用
        gcloud compute ssh "$INSTANCE_NAME" \
            --zone="$ZONE" \
            --project="$PROJECT_ID" \
            --ssh-flag="-t"
    fi
}

# インスタンスを再起動
restart_instance() {
    local status=$(get_status)
    
    if [[ "$status" == "NOT_FOUND" ]]; then
        echo ""
        echo "エラー: ゾーン $ZONE にインスタンス \"$INSTANCE_NAME\" が見つかりません。"
        set +e
        describe_err=$(gcloud compute instances describe "$INSTANCE_NAME" \
            --zone="$ZONE" \
            --project="$PROJECT_ID" 2>&1)
        set -e
        if is_permission_denied "$describe_err"; then
            show_remediation_permission_denied
        else
            show_remediation_instance_not_found
        fi
        exit 1
    fi
    
    echo "=========================================="
    echo "インスタンスを再起動しています..."
    echo "=========================================="
    
    set +e
    gcloud_output=$(gcloud compute instances reset "$INSTANCE_NAME" \
        --zone="$ZONE" \
        --project="$PROJECT_ID" 2>&1)
    gcloud_exit=$?
    set -e
    
    if [[ $gcloud_exit -ne 0 ]]; then
        echo ""
        echo "========================================"
        echo "再起動に失敗しました"
        echo "========================================"
        echo ""
        echo "$gcloud_output"
        if is_permission_denied "$gcloud_output"; then
            show_remediation_permission_denied
        elif echo "$gcloud_output" | grep -q "ZONE_RESOURCE_POOL_EXHAUSTED"; then
            show_remediation_zone_exhausted
        else
            echo ""
            echo "----------------------------------------"
            echo "上記のエラーメッセージを確認してください。"
            echo "----------------------------------------"
        fi
        exit $gcloud_exit
    fi
    
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

