# 🏦 Banking & Finance SQL Analytics Project

![SQL Validation](https://github.com/koskosilayda-sketch/finance-sql-project/actions/workflows/ci.yml/badge.svg)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16-blue?logo=postgresql)
![License](https://img.shields.io/badge/license-MIT-green)

Uçtan uca bir bankacılık veritabanı: normalize edilmiş şema tasarımı, gerçekçi sentetik veri, ve
temelden ileri seviyeye (window functions, CTE'ler, correlated subquery) uzanan 20 iş odaklı
SQL sorgusu.


---

## 📌 Proje Özeti

Bu proje bir bankanın çekirdek veri modelini simüle eder: müşteriler, şubeler, hesaplar,
işlemler, kartlar ve krediler. Amaç, gerçek bir finans kurumunda karşılaşılabilecek türde
sorulara SQL ile cevap vermek:

- Şube bazlı mevduat hacmi nedir?
- Hangi müşteriler "premium" segmentte?
- Hangi kredi türlerinde geç ödeme oranı en yüksek?
- Bir hesapta şüpheli işlem paterni var mı?

## 🗂️ Veritabanı Şeması

8 tablo, foreign key ilişkileri ve CHECK constraint'lerle tam normalize edilmiştir (3NF).

![ER Diagram](diagrams/er_diagram.md)

**Tablolar:** `branches`, `customers`, `employees`, `accounts`, `transactions`, `cards`, `loans`, `loan_payments`

Detaylı diyagram için [`diagrams/er_diagram.md`](diagrams/er_diagram.md) dosyasına bakın (GitHub'da otomatik render edilir).

## 📁 Proje Yapısı

```
finance-sql-project/
├── schema/
│   └── 01_schema.sql          # Tablo tanımları, constraint'ler, indeksler
├── seed/
│   └── 02_seed_data.sql       # 120 müşteri, 179 hesap, ~6600 işlem, 46 kredi
├── queries/
│   └── 03_analysis_queries.sql # 20 analiz sorgusu (5 seviyede)
├── diagrams/
│   └── er_diagram.md          # Mermaid ER diyagramı
├── generate_seed.py            # Seed veriyi üreten Python scripti
├── .github/workflows/ci.yml    # Her push'ta şemayı ve sorguları otomatik test eder
└── README.md
```

## 🚀 Kurulum ve Çalıştırma

### Gereksinimler
- PostgreSQL 14+ (yerel kurulum veya Docker)

### Adımlar

```bash
# 1. Veritabanını oluştur
createdb finance_db

# 2. Şemayı yükle
psql -d finance_db -f schema/01_schema.sql

# 3. Örnek veriyi yükle
psql -d finance_db -f seed/02_seed_data.sql

# 4. Analiz sorgularını çalıştır
psql -d finance_db -f queries/03_analysis_queries.sql
```

### Docker ile hızlı başlangıç

```bash
docker run --name finance-pg -e POSTGRES_PASSWORD=postgres -p 5432:5432 -d postgres:16
createdb -h localhost -U postgres finance_db
psql -h localhost -U postgres -d finance_db -f schema/01_schema.sql
psql -h localhost -U postgres -d finance_db -f seed/02_seed_data.sql
```

### Veriyi yeniden üretmek istersen

```bash
python3 generate_seed.py   # seed/02_seed_data.sql dosyasını yeniden oluşturur
```

## 🔍 Öne Çıkan Sorgular

Sorguların tamamı [`queries/03_analysis_queries.sql`](queries/03_analysis_queries.sql) içinde,
zorluk seviyesine göre 5 bölümde gruplanmıştır:

| Seviye | Konu | Örnek |
|---|---|---|
| 1 | Temel SELECT / WHERE / ORDER BY | En yüksek bakiyeli 10 hesap |
| 2 | JOIN + Aggregation | Şube bazlı toplam mevduat hacmi |
| 3 | Subquery + HAVING | Birden fazla hesabı olan müşteriler |
| 4 | Window Functions | `RANK()`, `LAG()`, kümülatif toplamlar |
| 5 | CTE + İş Zekası | Kredi geç ödeme risk analizi, müşteri segmentasyonu |

**Örnek — Şüpheli işlem tespiti (CTE ile):**
```sql
WITH gunluk_cekim AS (
    SELECT account_id, DATE(transaction_date) AS islem_gunu,
           COUNT(*) AS cekim_sayisi, SUM(amount) AS toplam_cekim
    FROM transactions
    WHERE transaction_type = 'WITHDRAWAL'
    GROUP BY account_id, DATE(transaction_date)
)
SELECT * FROM gunluk_cekim WHERE cekim_sayisi > 5
ORDER BY cekim_sayisi DESC;
```

## 🧪 Sürekli Entegrasyon (CI)

`.github/workflows/ci.yml`, her push ve pull request'te:
1. Geçici bir PostgreSQL servisi ayağa kaldırır
2. Şemayı uygular
3. Seed veriyi yükler
4. Tüm analiz sorgularını çalıştırıp hataya karşı doğrular

Bu sayede repo her zaman **çalışır durumda** kalır — işe alım yapan biri klonlayıp
tek komutla test edebilir.

## 🛠️ Kullanılan Teknikler

- Normalize şema tasarımı (3NF), foreign key & CHECK constraint'ler
- İndeksleme stratejisi (sık sorgulanan kolonlarda)
- `JOIN` türleri (INNER, LEFT)
- Aggregate fonksiyonlar (`SUM`, `AVG`, `COUNT`) + `GROUP BY` / `HAVING`
- Subquery ve correlated subquery
- Window functions: `RANK()`, `ROW_NUMBER()`, `LAG()`, running total
- CTE (`WITH`) ile çok adımlı analiz sorguları
- `CASE WHEN` ile segmentasyon mantığı
- GitHub Actions ile otomatik SQL doğrulama (CI)

## 📄 Lisans

Bu proje [MIT lisansı](LICENSE) ile paylaşılmıştır — istediğiniz gibi kullanabilir,
değiştirebilir ve kendi portföyünüz için referans alabilirsiniz.

---

⭐ Bu projeyi faydalı bulduysan yıldız vermeyi unutma!
