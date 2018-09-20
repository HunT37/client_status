SELECT
	# Dane są grupowane po dacie (konwersja z TIMESTAMP do DATE) a następnie sumowane ilości sukcesów, utrat oraz braków kontaktu w danym dniu
	DATE(x.kontakt_ts) AS data,
    SUM(CASE WHEN status = 'zainteresowany' THEN 1 ELSE 0 END) AS sukcesy,
    SUM(CASE WHEN status = 'niezainteresowany' THEN 1 ELSE 0 END) AS utraty,
    SUM(CASE WHEN status = 'poczta_glosowa' OR status = 'nie_ma_w_domu' THEN 1 ELSE 0 END) AS do_ponowienia,
    # Dane pobrane z LEFT JOIN, wktórym się znajdują dane dotyczące ilości zmian zdania klientów w danym dniu
    IFNULL(y.zainteresowani_utraty, 0) AS zainteresowani_utraty,
    IFNULL(y.niezainteresowani_sukcesy, 0) AS niezainteresowani_sukcesy
FROM ( # Pobieram zestaw danych, klient, daty kontaktów (tylko ostatni kontakt w danym dniu) oraz status tego kontaktu
	SELECT b.kontakt_id, a.klient_id, a.kontakt_ts, b.status FROM (
		# Klienci i ich daty kontaktów ograniczone do ostatniego kontaktu każdego dnia
		SELECT klient_id, MAX(kontakt_ts) AS kontakt_ts FROM janusz.client_status
		GROUP BY klient_id, DATE(kontakt_ts)
		ORDER BY klient_id, DATE(kontakt_ts)
	) a
    INNER JOIN (
		# Dla pobrania pozostałych parametrów jak status dla ostatniego kontaktu danego dnia
		SELECT * FROM janusz.client_status
    ) b
    ON a.klient_id = b.klient_id AND a.kontakt_ts = b.kontakt_ts
) x
LEFT JOIN (
	SELECT 
		a.klient_id,
		ostatni_stat.ost_data,
		#ostatni_stat.ostatni_status,
		#przed_ost_stat.przed_data,
		#przed_ost_stat.przed_ostatni_status,
		SUM(IF(ostatni_stat.ostatni_status = 'niezainteresowany' AND przed_ost_stat.przed_ostatni_status = 'zainteresowany', 1, 0)) AS zainteresowani_utraty,
		SUM(IF(ostatni_stat.ostatni_status = 'zainteresowany' AND przed_ost_stat.przed_ostatni_status = 'niezainteresowany', 1, 0)) AS niezainteresowani_sukcesy
	FROM (SELECT DISTINCT klient_id FROM janusz.client_status) a
		LEFT JOIN (
			# Pobieram dla każdego klienta datę jego ostatniego kontaktu oraz ostatni status tego kontaktu (ostatni_stat)
			SELECT a.klient_id, DATE(b.ostatni_kontakt) AS ost_data, c.ostatni_status
			FROM (SELECT DISTINCT klient_id FROM janusz.client_status) a
				INNER JOIN (
					SELECT kontakt_id, klient_id, MAX(kontakt_ts) AS ostatni_kontakt
					FROM janusz.client_status
					WHERE status != 'poczta_glosowa' AND status != 'nie_ma_w_domu'
					GROUP BY klient_id
				) b
				ON a.klient_id = b.klient_id
				INNER JOIN (
					SELECT klient_id, status AS ostatni_status, kontakt_ts FROM janusz.client_status
				) c
				ON b.klient_id = c.klient_id AND b.ostatni_kontakt = c.kontakt_ts
		) ostatni_stat
		ON a.klient_id = ostatni_stat.klient_id
		LEFT JOIN (
			# Pobieram podobnie jak wyżej statusy klientów, ale tym razem przedostatnie, dla porównania, czy klient zmienił zdanie (przed_ost_stat)
			SELECT a.klient_id, DATE(d.przed_ostatni_kontakt) AS przed_data, e.przed_ostatni_status
			FROM (SELECT DISTINCT klient_id FROM janusz.client_status) a
				INNER JOIN (
					SELECT m.kontakt_id, m.klient_id, MAX(kontakt_ts) AS przed_ostatni_kontakt
					FROM janusz.client_status m
					INNER JOIN (
						SELECT kontakt_id, klient_id, MAX(kontakt_ts) AS maxx
						FROM janusz.client_status
						WHERE status != 'poczta_glosowa' AND status != 'nie_ma_w_domu'
						GROUP BY klient_id
					) n
					ON kontakt_ts < n.maxx AND m.klient_id = n.klient_id
					WHERE status != 'poczta_glosowa' AND status != 'nie_ma_w_domu'
					GROUP BY klient_id
				) d
				ON a.klient_id = d.klient_id
				INNER JOIN (
					SELECT klient_id, status AS przed_ostatni_status, kontakt_ts FROM janusz.client_status
				) e
				ON d.klient_id = e.klient_id AND d.przed_ostatni_kontakt = e.kontakt_ts
		) przed_ost_stat
		ON a.klient_id = przed_ost_stat.klient_id
	# Grupuję po ostatniej dacie wystąpienia, gdyż ta nas interesuje, czy tego dnia klient zmienił zdanie po raz ostatni
	GROUP BY ost_data
	HAVING (zainteresowani_utraty > 0 OR niezainteresowani_sukcesy > 0) AND ost_data IS NOT NULL
) y
ON DATE(x.kontakt_ts) = y.ost_data
GROUP BY DATE(kontakt_ts)
ORDER BY DATE(kontakt_ts);