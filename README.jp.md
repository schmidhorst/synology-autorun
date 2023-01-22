# Synology NAS 用自動実行パッケージ
DSM 7.x を搭載した Synology NAS に外部ストレージ (USB / eSATA) を接続すると、スクリプトを実行することができます。
Synologies Task Scheduler では、トリガーされたタスクを作成することができます。しかし、トリガー イベントには、起動とシャットダウンのみが用意されています。USB イベントはありません。この欠点は、このツールで補うことができます。

## [ライセンス](https://htmlpreview.github.io/?https://github.com/schmidhorst/synology-autorun/blob/main/package/ui/licence_jpn.html)

## 免責事項および問題追跡システム
ここにあるものはすべて自己責任で使用してください。
問題は[issue tracker](https://github.com/schmidhorst/synology-autorun/issues)を使って、ドイツ語か英語で解決してください。

# インストール
* ["Releases"](https://github.com/schmidhorst/synology-autorun/releases) の "Assets" から *.spk ファイルをコンピュータにダウンロードし、 パッケージセンターで "Manual Install" を使ってください。

DSM 7 では、サードパーティパッケージが Synology によって制限されています。自動実行には root 権限が必要なため
権限が必要なため、インストール後に追加の手動手順が必要です。

NAS に SSH して (管理ユーザーとして)、次のコマンドを実行します。
```shell
sudo cp /var/packages/autorun/conf/privilege.root /var/packages/autorun/conf/privilege
```
SSHの代わり。
コントロールパネル => タスクスケジューラー => 作成 => スケジュールされたタスク => ユーザー定義スクリプト と進みます。一般」タブで、任意のタスク名を設定し、ユーザーとして「root」を選択します。タスクの設定 "タブで、次のように入力します。
```shell
cp /var/packages/autorun/conf/privilege.root /var/packages/autorun/conf/privilege
```
を "Run command "として実行します。OKで終了します。パッケージのインストール中にそのコマンドの実行を要求されたら、タスクスケジューラでそのタスクを選択し、「実行」してください。

パッケージセンターの https://www.cphub.net/ の下に、古い DSM バージョンのための [elder versions](https://github.com/reidemei/synology-autorun) が用意されています。
* DSM 7: 実際にはまだ1.8しかありません。
* DSM 6: 1.7
* DSM 5: 1.6
* elder: 1.3

## クレジットとリファレンス
- Jan Reidemeister](https://github.com/reidemei) の [Version 1.8](https://github.com/reidemei/synology-autorun) と [License](https://github.com/reidemei/synology-autorun/blob/main/LICENSE) に感謝します。
- 自動実行パッケージに関する Synology フォーラムのスレッド](https://www.synology-forum.de/threads/autorun-fuer-ext-datentraeger.18360/) に感謝します。
- toafez Tommes](https://github.com/toafez) と彼の [デモパッケージ](https://github.com/toafez/DSM7DemoSPK) に感謝します。
- geimist Stephan Geisler](https://github.com/geimist) と、他の言語への翻訳に [DeepL API](https://www.deepl.com/docs-api) を使用するためのヒントをありがとうございました。


