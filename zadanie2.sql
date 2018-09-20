# Dla każdego z klientów podaj liczbę prób kontaktu, czas ostatniego kontaktu oraz jego status
SELECT a.klient_id, b.liczba_kontaktów, c.ostatni_kontakt, d.ostatni_status
FROM janusz.client_status a
	INNER JOIN ( # Klienci, z którymi podjęto próbę kontktu przynajmniej 3 razy
		SELECT klient_id, COUNT(kontakt_id) AS liczba_kontaktów
		FROM janusz.client_status
		GROUP BY klient_id
		HAVING liczba_kontaktów >= 3
	) b
    ON a.klient_id = b.klient_id
    INNER JOIN ( # Czas ostatniego kontaktu z każdym klientem
		SELECT klient_id, status, MAX(kontakt_ts) AS ostatni_kontakt
		FROM janusz.client_status
		GROUP BY klient_id
    ) c
    ON a.klient_id = c.klient_id AND a.kontakt_ts = c.ostatni_kontakt
    INNER JOIN ( # Status ostatniego kontaktu z klientem
		SELECT klient_id, status AS ostatni_status, kontakt_ts FROM janusz.client_status
	) d
	ON c.klient_id = d.klient_id AND c.ostatni_kontakt = d.kontakt_ts
ORDER BY klient_id;