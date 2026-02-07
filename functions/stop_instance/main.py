"""
Cloud Function: インスタンスを停止する
毎朝6時にCloud Schedulerから呼び出される
"""
import os
from googleapiclient import discovery
from google.auth import default

# 環境変数から設定を取得
INSTANCE_NAME = os.environ.get('INSTANCE_NAME', 'claude-code-vm')
ZONE = os.environ.get('ZONE', 'asia-northeast1-a')
PROJECT_ID = os.environ.get('PROJECT_ID', '')


def stop_instance(request):
    """
    HTTPリクエストを受け取り、Compute Engineインスタンスを停止する
    
    Args:
        request: Flask request object
    
    Returns:
        dict: 実行結果
    """
    try:
        # 認証情報を取得
        credentials, default_project = default()
        
        # プロジェクトIDが環境変数で指定されていない場合は、デフォルトプロジェクトを使用
        project_id = PROJECT_ID if PROJECT_ID else default_project
        
        # Compute Engine API クライアントを作成
        compute = discovery.build('compute', 'v1', credentials=credentials)
        
        # インスタンスの状態を確認
        instance = compute.instances().get(
            project=project_id,
            zone=ZONE,
            instance=INSTANCE_NAME
        ).execute()
        
        current_status = instance.get('status', 'UNKNOWN')
        
        # 既に停止している場合は何もしない
        if current_status == 'TERMINATED':
            return {
                'status': 'success',
                'message': f'インスタンス {INSTANCE_NAME} は既に停止しています',
                'current_status': current_status
            }
        
        # インスタンスを停止
        result = compute.instances().stop(
            project=project_id,
            zone=ZONE,
            instance=INSTANCE_NAME
        ).execute()
        
        return {
            'status': 'success',
            'message': f'インスタンス {INSTANCE_NAME} の停止を開始しました',
            'current_status': current_status,
            'operation': result.get('name', '')
        }
        
    except Exception as e:
        return {
            'status': 'error',
            'message': f'エラーが発生しました: {str(e)}',
            'instance_name': INSTANCE_NAME,
            'zone': ZONE,
            'project_id': project_id
        }, 500

