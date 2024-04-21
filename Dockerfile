#ETAP 1
#syntax=docker/dockerfile:1.4
#budowanie obraz od podstaw i nadanie mu aliasu 'builder'
FROM scratch AS builder
#deklaracja zmiennej, do której będzie można przekazać wartość w procesie budowania
ARG TEMP_VERSION
ARG SSH_PRIVATE_KEY
#ustawienie katalogu do wykonywania instrukcji
WORKDIR /home/
#kopiowanie plików do wnętrza kontenera
ADD alpine-minirootfs-3.19.1-x86_64.tar /
#aktualizacja i instalacja pakietów oraz czyszczenie cache'a
RUN apk update && \
    apk add nodejs npm && \
    apk add git && \
    apk add openssh-client && \
    rm -f /var/cache/apk/*

#utworzenie nowego katalogu wewnątrz kontenera z uprawnieniami 0700, następnie skanowanie klucza serwera github i dodanie go do pliku known_hosts w katalogu .ssh wewnątrz kontenera, na koniec zostaje uruchomiony agent SSH
RUN mkdir -p -m 0700 ~/.ssh        \
    && ssh-keyscan github.com >> ~/.ssh/known_hosts \
    && eval $(ssh-agent)  

#ustawienie nowego katalogu bazowego
WORKDIR /usr/app

#skopiowanie zawartości repozytorium, który zawiera wszystkie składniki niezbędne do budowania obrazu
RUN --mount=type=ssh git clone git@github.com:r00j3K/zad2.git

#ustawienie nowego katalogu bazowego
WORKDIR /usr/app/zad2

#wywołanie polecenia npm install
RUN npm install


#ETAP 2
#tworzenie obrazu na podstawie nginx w wersji alpine
FROM nginx:alpine
#przechwycenie zmiennej przekazanej w procesie budowy i zapisanie jej jako globalnej zmiennej środowiskowej z uwzględnieniem
#domyślnej wartości w przypadku, gdy wartość nie zostanie nadana w procesie budowy
ARG TEMP_VERSION
ENV APP_VERSION=${TEMP_VERSION:-version0}
#ustawienie katalogu bazowego, w kótrym będą wykonywanie instrukcje
WORKDIR /usr/share/nginx/html/
#aktualizacja i instalacja pakietów oraz czyszczenie cache'a
RUN apk update && \
    apk add nodejs && \
    rm -rf /var/cache/apk/*
#skopiowanie wszystkich plików z katalogu /usr/app/zad2 pierwszego kontenera do katalogu /usr/share/nginx/html/ drugiego kontenera
COPY --from=builder /usr/app/zad2/ ./
#przeniesienie pliku konfiguracyjnego z pierwszego kontenera do odpowiedniego katalogu wewnątrz kontenera drugiego
COPY --from=build /usr/app/zad2/default.conf /etc/nginx/conf.d
#sprawdzenie poprawności działania kontenera
HEALTHCHECK --interval=15s --timeout=1s \
    CMD curl -f http://localhost:80
#przeładowanie serwera nginx i uruchomienie aplikacji JavaScript
CMD nginx -g "daemon off;" & node script.js
#wystawienie portu 80 do użytku na zewnątrz kontenera
EXPOSE 80	
