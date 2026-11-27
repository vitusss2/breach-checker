
# Laboratorium 08 - zadanie samodzielne

## 1. Frontend w pipeline

- [Przebieg z błędem lintowania](https://github.com/vitusss2/breach-checker/actions/runs/46007915937)
- [Następny poprawny przebieg](https://github.com/vitusss2/breach-checker/actions/runs/46008863776)

Linia błędu htmlhint:

```text
Tag must be paired, missing: [ </h1> ], start tag match failed [ <h1> ] on line 14. (tag-pair)
```

Job verify pobiera produkcyjne obrazy backendu i frontendu z GHCR, oba oznaczone SHA sprawdzanego commita. We wcześniejszej wersji frontend był budowany lokalnie na runnerze, a z rejestru pochodził tylko backend.

## 2. Promocja latest po weryfikacji

- [Przebieg z celowo zepsutą konfiguracją backendu](https://github.com/vitusss2/breach-checker/actions/runs/46009395837)
- [Przebieg po przywróceniu poprawnej konfiguracji](https://github.com/vitusss2/breach-checker/actions/runs/46009410959)

Job promote jest zależny od verify, dlatego po nieudanej weryfikacji tag latest powinien nadal wskazywać obraz z poprzedniej udanej promocji. Osoba pobierająca obraz bez podania tagu otrzymuje domyślnie latest, czyli wersję, która przeszła test dymny.

## 3. Publiczny odczyt i kontrola zapisu

- [Publiczny pakiet backendu](https://github.com/users/vitusss2/packages/container/package/breach-checker-backend)
- [Publiczny pakiet frontendu](https://github.com/users/vitusss2/packages/container/package/breach-checker-frontend)

```text
$ docker pull ghcr.io/vitusss2/breach-checker-backend:latest

latest: Pulling from vitusss2/breach-checker-backend
Digest: sha256:d87f77a199573def1a07673c7a4a1144f08399674412d4da9f5e3b74906fc34a
Status: Image is up to date for ghcr.io/vitusss2/breach-checker-backend:latest
ghcr.io/vitusss2/breach-checker-backend:latest

$ docker pull ghcr.io/vitusss2/breach-checker-backend:2c9473ab101d3e2ef606a35a7bd00de3a1cf0fd9

2c9473ab101d3e2ef606a35a7bd00de3a1cf0fd9: Pulling from vitusss2/breach-checker-backend
Digest: sha256:d87f77a199573def1a07673c7a4a1144f08399674412d4da9f5e3b74906fc34a
Status: Downloaded newer image for ghcr.io/vitusss2/breach-checker-backend:2c9473ab101d3e2ef606a35a7bd00de3a1cf0fd9
ghcr.io/vitusss2/breach-checker-backend:2c9473ab101d3e2ef606a35a7bd00de3a1cf0fd9

$ docker images --digests ghcr.io/vitusss2/breach-checker-backend

REPOSITORY                              TAG                                        DIGEST                                                                    IMAGE ID       CREATED         SIZE
ghcr.io/vitusss2/breach-checker-backend  2c9473ab101d3e2ef606a35a7bd00de3a1cf0fd9   sha256:d87f77a199573def1a07673c7a4a1144f08399674412d4da9f5e3b74906fc34a   d87f77a19957   2 minutes ago   190MB
ghcr.io/vitusss2/breach-checker-backend  latest                                     sha256:d87f77a199573def1a07673c7a4a1144f08399674412d4da9f5e3b74906fc34a   d87f77a19957   2 minutes ago   190MB
```

Identyczne digesty obu tagów potwierdzają, że wskazują one ten sam obraz. Publiczna widoczność pakietu pozwala pobierać obraz bez uwierzytelnienia, natomiast publikacja wymaga uprawnień do zapisu, które przy ręcznej publikacji zapewniał token z zakresem write:packages.
