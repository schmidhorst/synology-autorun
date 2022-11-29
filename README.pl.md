# autorun
Wykonywanie skryptów podczas podłączania zewnętrznej pamięci masowej (USB / eSATA) do serwera Synology NAS. Typowym zastosowaniem jest kopiowanie lub tworzenie kopii zapasowych niektórych plików. 
W Harmonogramie zadań Synology istnieje możliwość tworzenia zadań wyzwalanych, ale dla zdarzenia wyzwalającego dostępne są tylko Uruchomienie i Zamknięcie. Nie ma dostępnych zdarzeń USB. Ten brak jest kompensowany przez to narzędzie.  

# install
* Pobierz plik *.spk z "Releases", "Assets" w Githubie i użyj "Manual Install" w Centrum Pakietów.

Pod https://www.cphub.net/ w Centrum pakietów dostępne są starsze wersje dla starszych wersji DSM:
* DSM 7: właściwie wciąż tylko 1.8
* DSM 6: 1.7
* DSM 5: 1.6
* elder: 1.3

Pakiety stron trzecich są ograniczone przez Synology w DSM 7. Ponieważ autorun wymaga uprawnień roota 
aby wykonać swoje zadanie, po instalacji wymagany jest dodatkowy krok ręczny.

SSH do swojego NAS-a (jako użytkownik admin) i wykonaj następujące polecenie:

``Shell
sudo cp /var/packages/autorun/conf/privilege.root /var/packages/autorun/conf/privilege
```
Alternatywa dla SSH: 
Goto Control Panelel => Task Scheduler => Create => Scheduled Task => User-defined Script. W zakładce "General" ustaw dowolną nazwę zadania, wybierz 'root' jako użytkownika. W zakładce "Ustawienia zadania" wpisz  
```shell
cp /var/packages/autorun/conf/privilege.root /var/packages/autorun/conf/privilege
```
jako "Uruchom polecenie". Zakończ go przyciskiem OK. Kiedy zostaniesz poproszony o wykonanie tego polecenia teraz podczas instalacji pckage, przejdź do harmonogramu zadań, wybierz to zadanie i "Uruchom" je. 

