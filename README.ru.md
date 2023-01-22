# пакет автозапуска для Synology NAS
Выполняет сценарии при подключении внешних накопителей (USB / eSATA) на Synology NAS с DSM 7.x. Обычно используется для копирования или резервного копирования некоторых файлов.
В планировщике задач Synologies есть возможность создавать триггерные задачи. Но для триггерного события доступны только Boot-up и Shutdown. События USB отсутствуют. Этот недостаток компенсируется данным инструментом.

## [Лицензия](https://htmlpreview.github.io/?https://github.com/schmidhorst/synology-autorun/blob/main/package/ui/licence_rus.html)

## Отказ от ответственности и отслеживание проблем
Вы используете все здесь на свой страх и риск.
Для решения проблем, пожалуйста, используйте [issue tracker](https://github.com/schmidhorst/synology-autorun/issues) с немецким или английским языком.

# Установка
* Загрузите файл *.spk из ["Releases"](https://github.com/schmidhorst/synology-autorun/releases), "Assets" на свой компьютер и используйте "Manual Install" в Центре пакетов.

Пакеты сторонних разработчиков ограничены компанией Synology в DSM 7. Поскольку для автозапуска требуются права root
для выполнения своей работы требуется дополнительный ручной шаг после установки.

Войдите в NAS по SSH (от имени пользователя admin) и выполните следующую команду:
```shell
sudo cp /var/packages/autorun/conf/privilege.root /var/packages/autorun/conf/privilege
```
Альтернатива SSH:
Перейдите в Панель управления => Планировщик задач => Создать => Запланированная задача => Пользовательский сценарий. На вкладке "Общие" задайте любое имя задачи, в качестве пользователя выберите 'root'. На вкладке "Параметры задачи" введите
```shell
cp /var/packages/autorun/conf/privilege.root /var/packages/autorun/conf/privilege
```
в качестве "Выполнить команду". Завершите его нажатием кнопки OK. Когда во время установки пакета вам будет предложено выполнить эту команду, зайдите в планировщик задач, выберите эту задачу и "Запустить" ее.

В разделе https://www.cphub.net/ в Центре пакетов доступны [старшие версии](https://github.com/reidemei/synology-autorun) для старших версий DSM:
* DSM 7: фактически все еще только 1.8
* DSM 6: 1.7
* DSM 5: 1.6
* elder: 1.3

## Кредиты и ссылки
- Спасибо [Jan Reidemeister](https://github.com/reidemei) за его [Версия 1.8](https://github.com/reidemei/synology-autorun) и его [Лицензия](https://github.com/reidemei/synology-autorun/blob/main/LICENSE)
- Спасибо [Тема форума Synology о пакете автозапуска](https://www.synology-forum.de/threads/autorun-fuer-ext-datentraeger.18360/)
- Спасибо [toafez Tommes](https://github.com/toafez) и его [Demo Package](https://github.com/toafez/DSM7DemoSPK)
- Спасибо [geimist Stephan Geisler](https://github.com/geimist) и за совет использовать [DeepL API](https://www.deepl.com/docs-api) для перевода на другие языки.

