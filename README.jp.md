# autorun
Synology NAS で外部ストレージ (USB / eSATA) を接続する際にスクリプトを実行します。一般的な使用方法は、ファイルのコピーやバックアップです。
Synologies Task Scheduler では、トリガーされたタスクを作成することができます。しかし、トリガー イベントには、起動とシャットダウンしかありません。USB イベントはありません。この欠点は、このツールで補うことができます。 

# インストール
* Github の "Releases", "Assets" から *.spk ファイルをダウンロードし、パッケージセンターで "Manual Install" を利用します。

パッケージセンターの https://www.cphub.net/ の下には、古いDSMのバージョンに対応したものが用意されています。
* DSM 7: 実はまだ1.8しかありません。
* DSM 6: 1.7
* DSM 5: 1.6
* elder: 1.3

DSM 7 では、サードパーティ パッケージが Synology によって制限されています。自動実行には root 権限が必要なため 
権限が必要なため、インストール後に追加の手動手順が必要です。

NAS に SSH して (管理者ユーザーとして)、次のコマンドを実行します。

```shell
sudo cp /var/packages/autorun/conf/privilege.root /var/packages/autorun/conf/privilege
```
SSHの代替。
コントロールパネル => タスクスケジューラー => 作成 => スケジュールされたタスク => ユーザー定義スクリプト を実行します。General "タブで任意のタスク名を設定し、ユーザーとして "root "を選択します。タスクの設定 "タブで、次のように入力します。 
```shell
cp /var/packages/autorun/conf/privilege.root /var/packages/autorun/conf/privilege
```
を "Run command "として実行します。OKで終了します。パッケージのインストール中にそのコマンドの実行を要求されたら、タスクスケジューラーでそのタスクを選択し、「実行」してください。

