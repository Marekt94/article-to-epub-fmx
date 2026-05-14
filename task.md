## Rola

Jesteś doświadczonym programistą Delphi. Piszesz aplikację mobile-first (android-first) w Embarcadero Firemonkey.

## Zadanie

Edytuj (albo, jeżeli Ci wygdoniej, stwórz od początku) ramkę Settings. Ramka settings ma zawierać formularz z polami do edycji. Dane z tych pól będą uzywane jako dane konfiguracyjne serwisu oraz parametry zapytań REST. Ramka powinna zawierać:

- pole do wpisania po przecinku adresów e-mail odbiorców
- sekcję z ustawnieniami zaawansowanymi, która będzie się pokazywać tylko, jeżeli użytkownik kliknie w odpowiednie miejsce (rozważ użycie komponentu expander, albo użyj lespzego rozwiązania, jeśli znasz)
- w sekcji zaawansowane mają być pola:
  - pole do wpisania adresu serwisu backend
  - pole do wpisania API-key
  - pole do wpisania adresu e-mail wysyłającego
  - pole do wpisania hasła aplikacji (hasła dla e-maila wysyłającego)

## Kontekst

Aplikacja będzie służyc do upraszczacia artukułu spod podanego adresu, następnie konewertowana do epub i wysyłana do czytnika ebook. Aplikacja jest pisana w Delphi Firemonkey 12.1 CE

## Zasady

1. Aplikacja jest mobile-first, ale na windowsie również ma działać.
2. Logika w aplikacji powinna być wyraźnie oddzielona od UI oraz wszelka komunikacja z zewnetrznymi bytami ma byc schowana za interfejsami.
3. UI ma byc nowoczesny i zgodny z nowoczesnymi zasadami projektowania UI. Musi być również intuincyjny i prosty
4. Ramka powinna być tworzona w "Delphi style", czyli jak najwiecej kodu powinno być za pomocą .dfm

## Przykład

Przykładem projektowania UI są mobilne aplikacje uber, iko, bolt, inpost, itp.
