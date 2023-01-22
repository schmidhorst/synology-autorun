# pakiet autorun dla Synology NAS
Wykonuje skrypty podczas podłączania zewnętrznych pamięci masowych (USB / eSATA) do serwera Synology NAS z DSM 7.x. Typowym zastosowaniem jest kopiowanie lub tworzenie kopii zapasowych niektórych plików.
W Harmonogramie zadań Synology istnieje możliwość tworzenia zadań wyzwalanych. Jednak dla zdarzeń wyzwalających dostępne są tylko Uruchomienie i Zamknięcie. Nie ma dostępnych zdarzeń USB. Ten brak jest rekompensowany przez to narzędzie.

## [Licencja](https://htmlpreview.github.io/?https://github.com/schmidhorst/synology-autorun/blob/main/package/ui/licence_plk.html)

## Disclaimer and Issue Tracker
Używasz wszystkiego tutaj na własne ryzyko.
Do rozwiązywania problemów używaj [issue tracker](https://github.com/schmidhorst/synology-autorun/issues) z niemieckim lub angielskim językiem.

# Instalacja
* Pobierz plik *.spk z ["Releases"](https://github.com/schmidhorst/synology-autorun/releases), "Assets" na swój komputer i użyj "Manual Install" w Centrum Pakietów.

Pakiety stron trzecich są ograniczone przez firmę Synology w DSM 7. Ponieważ autorun wymaga uprawnień roota
aby wykonać swoje zadanie, po instalacji wymagany jest dodatkowy krok ręczny.

Zaloguj się przez SSH do swojego NAS-a (jako użytkownik admin) i wykonaj następujące polecenie:
```Shell
sudo cp /var/packages/autorun/conf/privilege.root /var/packages/autorun/conf/privilege
```
Alternatywa dla SSH:
Przejdź do Panel sterowania => Harmonogram zadań => Utwórz => Zaplanowane zadanie => Skrypt zdefiniowany przez użytkownika. W zakładce "General" ustaw dowolną nazwę zadania, wybierz 'root' jako użytkownika. W zakładce "Ustawienia zadania" wpisz
```shell
cp /var/packages/autorun/conf/privilege.root /var/packages/autorun/conf/privilege
```
jako "Uruchom polecenie". Zakończ go przyciskiem OK. Jeśli zostaniesz poproszony o wykonanie tego polecenia teraz podczas instalacji pakietu, przejdź do harmonogramu zadań, wybierz to zadanie i "Uruchom" je.

Pod https://www.cphub.net/ w Centrum Pakietów są [starsze wersje](https://github.com/reidemei/synology-autorun) dla starszych wersji DSM dostępne:
* DSM 7: właściwie wciąż tylko 1.8
* DSM 6: 1.7
* DSM 5: 1.6
* elder: 1.3

## Kredyty i odniesienia
- Podziękowania dla [Jana Reidemeistera](https://github.com/reidemei) za jego [Wersję 1.8](https://github.com/reidemei/synology-autorun) i jego [Licencję](https://github.com/reidemei/synology-autorun/blob/main/LICENSE)
- Podziękowania dla [Forum Synology - wątek o tym pakiecie autorun](https://www.synology-forum.de/threads/autorun-fuer-ext-datentraeger.18360/)
- Podziękowania dla [toafez Tommes](https://github.com/toafez) i jego [Demo Package](https://github.com/toafez/DSM7DemoSPK)
- Podziękowania dla [geimist Stephan Geisler](https://github.com/geimist) i trafiona wskazówka, aby użyć [DeepL API](https://www.deepl.com/docs-api) do tłumaczenia na inne języki.


