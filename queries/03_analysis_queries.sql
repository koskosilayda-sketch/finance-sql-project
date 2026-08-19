-- ============================================================
-- ANALİZ SORGULARI
-- Basitten karmaşığa doğru sıralanmıştır.
-- Her sorgu gerçek bir iş sorusunu cevaplar.
-- ============================================================

-- ------------------------------------------------------------
-- SEVİYE 1: TEMEL SORGULAR (SELECT, WHERE, ORDER BY)
-- ------------------------------------------------------------

-- 1.1 En yüksek bakiyeye sahip 10 hesap
SELECT account_id, customer_id, account_type, balance
FROM accounts
ORDER BY balance DESC
LIMIT 10;

-- 1.2 Kredi skoru 700'ün üzerinde olan müşteriler
SELECT customer_id, first_name, last_name, credit_score
FROM customers
WHERE credit_score > 700
ORDER BY credit_score DESC;

-- 1.3 Aktif olmayan (kapalı/donmuş) hesaplar
SELECT account_id, customer_id, status, balance
FROM accounts
WHERE status <> 'ACTIVE';


-- ------------------------------------------------------------
-- SEVİYE 2: JOIN VE AGGREGATION
-- ------------------------------------------------------------

-- 2.1 Her şubenin toplam mevduat (deposit) hacmi
SELECT b.branch_name, b.city, COUNT(a.account_id) AS hesap_sayisi,
       SUM(a.balance) AS toplam_bakiye
FROM branches b
JOIN accounts a ON a.branch_id = b.branch_id
GROUP BY b.branch_id, b.branch_name, b.city
ORDER BY toplam_bakiye DESC;

-- 2.2 Müşteri başına toplam hesap sayısı ve toplam bakiye
SELECT c.customer_id, c.first_name, c.last_name,
       COUNT(a.account_id) AS hesap_sayisi,
       COALESCE(SUM(a.balance), 0) AS toplam_bakiye
FROM customers c
LEFT JOIN accounts a ON a.customer_id = c.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY toplam_bakiye DESC
LIMIT 15;

-- 2.3 İşlem tipine göre toplam işlem hacmi ve ortalama tutar
SELECT transaction_type,
       COUNT(*) AS islem_sayisi,
       ROUND(SUM(amount), 2) AS toplam_tutar,
       ROUND(AVG(amount), 2) AS ortalama_tutar
FROM transactions
GROUP BY transaction_type
ORDER BY toplam_tutar DESC;

-- 2.4 Kredi türüne göre ortalama faiz oranı ve toplam kredi hacmi
SELECT loan_type,
       COUNT(*) AS kredi_sayisi,
       ROUND(AVG(interest_rate), 2) AS ortalama_faiz,
       ROUND(SUM(principal_amount), 2) AS toplam_hacim
FROM loans
GROUP BY loan_type
ORDER BY toplam_hacim DESC;


-- ------------------------------------------------------------
-- SEVİYE 3: ALT SORGULAR (SUBQUERY) VE HAVING
-- ------------------------------------------------------------

-- 3.1 Ortalama hesap bakiyesinin üzerinde bakiyeye sahip hesaplar
SELECT account_id, customer_id, balance
FROM accounts
WHERE balance > (SELECT AVG(balance) FROM accounts)
ORDER BY balance DESC;

-- 3.2 Birden fazla hesabı olan müşteriler (HAVING kullanımı)
SELECT c.customer_id, c.first_name, c.last_name, COUNT(a.account_id) AS hesap_sayisi
FROM customers c
JOIN accounts a ON a.customer_id = c.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name
HAVING COUNT(a.account_id) > 1
ORDER BY hesap_sayisi DESC;

-- 3.3 Hiç kredi kartı olmayan müşteriler
SELECT c.customer_id, c.first_name, c.last_name
FROM customers c
WHERE c.customer_id NOT IN (
    SELECT DISTINCT a.customer_id
    FROM accounts a
    JOIN cards cd ON cd.account_id = a.account_id
    WHERE cd.card_type = 'CREDIT'
);

-- 3.4 Şube ortalamasının üzerinde maaş alan çalışanlar (correlated subquery)
SELECT e.employee_id, e.first_name, e.last_name, e.salary, e.branch_id
FROM employees e
WHERE e.salary > (
    SELECT AVG(e2.salary)
    FROM employees e2
    WHERE e2.branch_id = e.branch_id
)
ORDER BY e.branch_id;


-- ------------------------------------------------------------
-- SEVİYE 4: WINDOW FUNCTIONS (İleri Seviye)
-- ------------------------------------------------------------

-- 4.1 Her müşterinin şehrindeki bakiye sıralaması (RANK)
SELECT customer_id, city, toplam_bakiye,
       RANK() OVER (PARTITION BY city ORDER BY toplam_bakiye DESC) AS sehir_siralamasi
FROM (
    SELECT c.customer_id, c.city, SUM(a.balance) AS toplam_bakiye
    FROM customers c
    JOIN accounts a ON a.customer_id = c.customer_id
    GROUP BY c.customer_id, c.city
) t
ORDER BY city, sehir_siralamasi;

-- 4.2 Her hesap için işlem geçmişinde bakiyenin bir önceki işleme göre değişimi
SELECT account_id, transaction_date, transaction_type, amount, balance_after,
       balance_after - LAG(balance_after) OVER (
           PARTITION BY account_id ORDER BY transaction_date
       ) AS bakiye_degisimi
FROM transactions
WHERE account_id = 1
ORDER BY transaction_date;

-- 4.3 Aylık toplam işlem hacmi ve kümülatif (running total) toplam
SELECT ay, aylik_hacim,
       SUM(aylik_hacim) OVER (ORDER BY ay) AS kumulatif_hacim
FROM (
    SELECT DATE_TRUNC('month', transaction_date) AS ay,
           SUM(amount) AS aylik_hacim
    FROM transactions
    GROUP BY DATE_TRUNC('month', transaction_date)
) t
ORDER BY ay;

-- 4.4 Her müşterinin en yüksek bakiyeli hesabı (ROW_NUMBER ile)
SELECT customer_id, account_id, account_type, balance
FROM (
    SELECT customer_id, account_id, account_type, balance,
           ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY balance DESC) AS rn
    FROM accounts
) ranked
WHERE rn = 1
ORDER BY balance DESC
LIMIT 10;


-- ------------------------------------------------------------
-- SEVİYE 5: CTE (WITH) VE İŞ ZEKASI SORULARI
-- ------------------------------------------------------------

-- 5.1 Geç ödeme oranı en yüksek olan kredi türleri (risk analizi)
WITH odeme_istatistikleri AS (
    SELECT l.loan_type,
           COUNT(lp.payment_id) AS toplam_odeme,
           SUM(CASE WHEN lp.is_late THEN 1 ELSE 0 END) AS gecikmeli_odeme
    FROM loans l
    JOIN loan_payments lp ON lp.loan_id = l.loan_id
    GROUP BY l.loan_type
)
SELECT loan_type, toplam_odeme, gecikmeli_odeme,
       ROUND(100.0 * gecikmeli_odeme / NULLIF(toplam_odeme,0), 2) AS gecikme_orani_yuzde
FROM odeme_istatistikleri
ORDER BY gecikme_orani_yuzde DESC;

-- 5.2 "Değerli müşteri" segmentasyonu: toplam bakiye + aktif kredi durumu
WITH musteri_bakiye AS (
    SELECT customer_id, SUM(balance) AS toplam_bakiye
    FROM accounts
    WHERE status = 'ACTIVE'
    GROUP BY customer_id
),
musteri_kredi AS (
    SELECT customer_id, COUNT(*) AS aktif_kredi_sayisi
    FROM loans
    WHERE status = 'ACTIVE'
    GROUP BY customer_id
)
SELECT c.customer_id, c.first_name, c.last_name,
       COALESCE(mb.toplam_bakiye, 0) AS toplam_bakiye,
       COALESCE(mk.aktif_kredi_sayisi, 0) AS aktif_kredi_sayisi,
       CASE
           WHEN COALESCE(mb.toplam_bakiye,0) > 50000 THEN 'PREMIUM'
           WHEN COALESCE(mb.toplam_bakiye,0) > 15000 THEN 'STANDART'
           ELSE 'TEMEL'
       END AS musteri_segmenti
FROM customers c
LEFT JOIN musteri_bakiye mb ON mb.customer_id = c.customer_id
LEFT JOIN musteri_kredi mk ON mk.customer_id = c.customer_id
ORDER BY toplam_bakiye DESC;

-- 5.3 Şüpheli işlem tespiti: aynı gün içinde 5'ten fazla para çekme işlemi yapan hesaplar
WITH gunluk_cekim AS (
    SELECT account_id, DATE(transaction_date) AS islem_gunu, COUNT(*) AS cekim_sayisi,
           SUM(amount) AS toplam_cekim
    FROM transactions
    WHERE transaction_type = 'WITHDRAWAL'
    GROUP BY account_id, DATE(transaction_date)
)
SELECT account_id, islem_gunu, cekim_sayisi, toplam_cekim
FROM gunluk_cekim
WHERE cekim_sayisi > 5
ORDER BY cekim_sayisi DESC;

-- 5.4 Müşteri elde tutma (retention) analizi: kayıt yılına göre aktif müşteri oranı
SELECT EXTRACT(YEAR FROM join_date) AS kayit_yili,
       COUNT(*) AS toplam_musteri,
       SUM(CASE WHEN customer_id IN (
           SELECT customer_id FROM accounts WHERE status = 'ACTIVE'
       ) THEN 1 ELSE 0 END) AS aktif_musteri,
       ROUND(100.0 * SUM(CASE WHEN customer_id IN (
           SELECT customer_id FROM accounts WHERE status = 'ACTIVE'
       ) THEN 1 ELSE 0 END) / COUNT(*), 2) AS aktif_oran_yuzde
FROM customers
GROUP BY EXTRACT(YEAR FROM join_date)
ORDER BY kayit_yili;
