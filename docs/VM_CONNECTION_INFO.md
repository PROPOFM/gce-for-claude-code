# Claude Code VM 接続情報（共有用）

担当者へ渡すための接続手順です。公開鍵を `hirotososhizaki` の `~/.ssh/authorized_keys` に追加済みの方を対象にしています。

---

## 基本情報

| 項目 | 内容 |
|------|------|
| インスタンス名 | claude-code-vm |
| ゾーン | asia-northeast2-a |
| プロジェクトID | gce-for-claude-code |
| ログインユーザー | hirotososhizaki |

---

## 前提条件

- ローカルに **Google Cloud SDK（gcloud）** がインストールされていること
- この GCP プロジェクトへのアクセス権があること（ない場合は担当者に IAM 付与を依頼）

---

## 1. VM の起動

VM が停止している場合は、リポジトリのルートで以下を実行してください。

```bash
./scripts/vm-control.sh start
```

または gcloud のみで:

```bash
gcloud compute instances start claude-code-vm --zone=asia-northeast2-a --project=gce-for-claude-code
```

起動まで 1〜2 分かかることがあります。

---

## 2. 状態確認（任意）

```bash
./scripts/vm-control.sh status
```

または:

```bash
gcloud compute instances describe claude-code-vm --zone=asia-northeast2-a --project=gce-for-claude-code --format="value(status)"
```

`RUNNING` なら接続可能です。

---

## 3. SSH 接続

**リポジトリがある場合（推奨）:**

```bash
./scripts/vm-control.sh ssh
```

**gcloud のみで接続する場合:**

```bash
gcloud compute ssh claude-code-vm --zone=asia-northeast2-a --project=gce-for-claude-code --ssh-key-file=~/.ssh/id_ed25519 --ssh-flag="-l hirotososhizaki"
```

秘密鍵が `~/.ssh/id_rsa` の場合は `--ssh-key-file=~/.ssh/id_rsa` に読み替えてください。

**初回のみ:** プロジェクトで初めて SSH する場合は、事前に以下で Google アカウント認証してください。

```bash
gcloud auth login
```

---

## 4. VM 上で gcloud を使えるようにする（初回のみ）

VM 内で `gcloud` コマンドを使いたい場合は、VM に SSH した後に以下を実行してください。

### 4.1. gcloud CLI のインストール

VM に SSH した状態で、以下を実行します。

```bash
# Google Cloud SDK のリポジトリを追加
echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list

# 署名キーを追加
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -

# パッケージリストを更新
sudo apt update

# gcloud CLI をインストール
sudo apt install -y google-cloud-cli
```

### 4.2. gcloud の認証

VM にはブラウザがないため、`--no-launch-browser` オプションを使用します。

```bash
# ユーザー認証（gcloud コマンド用）
gcloud auth login --no-launch-browser
```

1. 表示された URL を**ローカルのブラウザ**で開きます。
2. Google アカウントでログインし、アクセスを許可します。
3. 表示される認証コードを VM のターミナルに貼り付けて Enter を押します。

### 4.3. プロジェクトの設定

```bash
# デフォルトプロジェクトを設定
gcloud config set project gce-for-claude-code

# デフォルトリージョン/ゾーンを設定（任意）
gcloud config set compute/region asia-northeast2
gcloud config set compute/zone asia-northeast2-a
```

### 4.4. Application Default Credentials の設定（オプション）

Python や Node.js などの SDK から GCP API を呼び出す場合は、Application Default Credentials も設定しておくと便利です。

```bash
gcloud auth application-default login --no-launch-browser
```

同様に、表示された URL をローカルのブラウザで開き、認証コードを VM に貼り付けます。

### 4.5. 動作確認

```bash
# 認証状態の確認
gcloud auth list

# プロジェクトの確認
gcloud config get-value project

# 動作確認（例: インデックス一覧を取得）
gcloud ai indexes list --region=us-central1 --project=gce-for-claude-code
```

---

## 5. 作業後の停止（任意）

---

## 5. 作業後の停止（任意）

使わないときは停止するとコスト削減になります。

```bash
./scripts/vm-control.sh stop
```

または:

```bash
gcloud compute instances stop claude-code-vm --zone=asia-northeast2-a --project=gce-for-claude-code
```

---

## トラブルシューティング

### VM 上で `gcloud` を実行すると「You do not currently have an active account selected」と出る

VM に SSH した**先（VM 内）**で `gcloud` コマンドを実行している場合、VM 上にはまだ Google アカウントの認証が入っていないためこのエラーになります。

**対処法は次のいずれかです。**

#### 方法 A: コマンドをローカルで実行する（いちばん簡単）

`gcloud ai indexes list` など GCP API を叩くだけの作業は、**自分の PC（ローカル）**で実行してください。ローカルで `gcloud auth login` 済みなら、そのまま動きます。

```bash
# ローカル（VM に SSH する前）で実行
gcloud ai indexes list --region=us-central1 --project=gce-for-claude-code
```

#### 方法 B: VM 上でも gcloud を使えるようにする

VM 内で gcloud を使い続けたい場合は、上記の「**4. VM 上で gcloud を使えるようにする（初回のみ）**」の手順に従って、gcloud CLI のインストールと認証を行ってください。

---

## コマンド早見表

| 操作 | コマンド |
|------|----------|
| 起動 | `./scripts/vm-control.sh start` |
| 接続 | `./scripts/vm-control.sh ssh` |
| 停止 | `./scripts/vm-control.sh stop` |
| 状態確認 | `./scripts/vm-control.sh status` |
