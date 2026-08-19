"""
Bankacılık veritabanı için gerçekçi sahte veri üretici.
Çıktı: seed/02_seed_data.sql
"""
import random
from datetime import date, timedelta, datetime

random.seed(42)

OUT = []

def esc(s):
    return s.replace("'", "''")

# ------------------------------------------------------------
# 1. BRANCHES
# ------------------------------------------------------------
branches = [
    ("Kadıköy Şubesi", "İstanbul"), ("Çankaya Şubesi", "Ankara"),
    ("Konak Şubesi", "İzmir"), ("Nilüfer Şubesi", "Bursa"),
    ("Muratpaşa Şubesi", "Antalya"), ("Şahinbey Şubesi", "Gaziantep"),
]
managers = ["Ayşe Kaya", "Mehmet Demir", "Elif Şahin", "Can Yıldız", "Zeynep Arslan", "Burak Çelik"]

OUT.append("-- 1. BRANCHES")
OUT.append("INSERT INTO branches (branch_name, city, opened_date, manager_name) VALUES")
rows = []
for i, (name, city) in enumerate(branches):
    opened = date(2010, 1, 1) + timedelta(days=random.randint(0, 3000))
    rows.append(f"('{esc(name)}', '{esc(city)}', '{opened}', '{esc(managers[i])}')")
OUT.append(",\n".join(rows) + ";\n")
n_branches = len(branches)

# ------------------------------------------------------------
# 2. CUSTOMERS
# ------------------------------------------------------------
first_names = ["Ahmet","Mehmet","Ayşe","Fatma","Ali","Zeynep","Mustafa","Elif","Hüseyin","Emine",
               "Hasan","Hatice","İbrahim","Merve","Yusuf","Büşra","Ömer","Sena","Emre","Gizem",
               "Burak","Aslı","Kerem","Deniz","Cem","Ece","Onur","Selin","Barış","Nazlı"]
last_names = ["Yılmaz","Kaya","Demir","Şahin","Çelik","Yıldız","Arslan","Doğan","Kılıç","Aydın",
              "Öztürk","Aslan","Çetin","Koç","Kurt","Özdemir","Şimşek","Polat","Erdoğan","Güneş"]
cities = ["İstanbul","Ankara","İzmir","Bursa","Antalya","Gaziantep","Konya","Adana"]

n_customers = 120
OUT.append("-- 2. CUSTOMERS")
OUT.append("INSERT INTO customers (first_name, last_name, email, phone, date_of_birth, join_date, city, credit_score) VALUES")
rows = []
for i in range(1, n_customers + 1):
    fn, ln = random.choice(first_names), random.choice(last_names)
    email = f"{fn.lower()}.{ln.lower()}{i}@example.com".replace('ı','i').replace('ş','s').replace('ğ','g').replace('ç','c').replace('ö','o').replace('ü','u')
    phone = f"05{random.randint(300000000,599999999)}"
    dob = date(1955,1,1) + timedelta(days=random.randint(0, 365*50))
    join = date(2015,1,1) + timedelta(days=random.randint(0, 365*10))
    city = random.choice(cities)
    score = random.randint(450, 850)
    rows.append(f"('{fn}', '{ln}', '{email}', '{phone}', '{dob}', '{join}', '{city}', {score})")
OUT.append(",\n".join(rows) + ";\n")

# ------------------------------------------------------------
# 3. EMPLOYEES
# ------------------------------------------------------------
positions = ["Şube Müdürü","Müşteri Temsilcisi","Kredi Uzmanı","Gişe Görevlisi","Operasyon Uzmanı"]
n_employees = 30
OUT.append("-- 3. EMPLOYEES")
OUT.append("INSERT INTO employees (branch_id, first_name, last_name, position, hire_date, salary) VALUES")
rows = []
for i in range(n_employees):
    branch_id = random.randint(1, n_branches)
    fn, ln = random.choice(first_names), random.choice(last_names)
    pos = random.choice(positions)
    hire = date(2012,1,1) + timedelta(days=random.randint(0, 365*12))
    salary = round(random.uniform(18000, 65000), 2)
    rows.append(f"({branch_id}, '{fn}', '{ln}', '{pos}', '{hire}', {salary})")
OUT.append(",\n".join(rows) + ";\n")

# ------------------------------------------------------------
# 4. ACCOUNTS
# ------------------------------------------------------------
account_types = ["CHECKING","SAVINGS","BUSINESS"]
accounts = []  # (customer_id, account_type, opened_date)
OUT.append("-- 4. ACCOUNTS")
OUT.append("INSERT INTO accounts (customer_id, branch_id, account_type, balance, opened_date, status) VALUES")
rows = []
account_id_counter = 1
for cust_id in range(1, n_customers + 1):
    num_accounts = random.choices([1,2,3],[0.55,0.35,0.10])[0]
    for _ in range(num_accounts):
        branch_id = random.randint(1, n_branches)
        acc_type = random.choice(account_types)
        opened = date(2016,1,1) + timedelta(days=random.randint(0, 365*9))
        balance = round(random.uniform(100, 85000), 2)
        status = random.choices(["ACTIVE","CLOSED","FROZEN"],[0.90,0.07,0.03])[0]
        rows.append(f"({cust_id}, {branch_id}, '{acc_type}', {balance}, '{opened}', '{status}')")
        accounts.append((account_id_counter, cust_id, opened, balance))
        account_id_counter += 1
OUT.append(",\n".join(rows) + ";\n")
n_accounts = account_id_counter - 1

# ------------------------------------------------------------
# 5. TRANSACTIONS
# ------------------------------------------------------------
tx_types_flow = {
    "DEPOSIT": 1, "TRANSFER_IN": 1, "INTEREST": 1,
    "WITHDRAWAL": -1, "TRANSFER_OUT": -1, "FEE": -1
}
descriptions = {
    "DEPOSIT": "Nakit yatırma", "WITHDRAWAL": "ATM para çekme",
    "TRANSFER_IN": "Gelen havale", "TRANSFER_OUT": "Giden havale",
    "FEE": "İşlem ücreti", "INTEREST": "Faiz ödemesi"
}

OUT.append("-- 5. TRANSACTIONS")
OUT.append("INSERT INTO transactions (account_id, transaction_date, transaction_type, amount, balance_after, description) VALUES")
rows = []
for (acc_id, cust_id, opened, current_balance) in accounts:
    running_balance = round(random.uniform(500, 5000), 2)
    n_tx = random.randint(15, 60)
    start_dt = datetime.combine(opened, datetime.min.time())
    end_dt = datetime(2025, 12, 31)
    days_range = max((end_dt - start_dt).days, 1)
    tx_dates = sorted([start_dt + timedelta(days=random.randint(0, days_range), hours=random.randint(8,20)) for _ in range(n_tx)])
    for tx_dt in tx_dates:
        tx_type = random.choices(
            list(tx_types_flow.keys()),
            weights=[0.28,0.22,0.05,0.22,0.18,0.05]
        )[0]
        amount = round(random.uniform(20, 4000), 2)
        direction = tx_types_flow[tx_type]
        running_balance = max(round(running_balance + direction*amount, 2), 0)
        rows.append(f"({acc_id}, '{tx_dt}', '{tx_type}', {amount}, {running_balance}, '{descriptions[tx_type]}')")
OUT.append(",\n".join(rows) + ";\n")

# ------------------------------------------------------------
# 6. CARDS
# ------------------------------------------------------------
OUT.append("-- 6. CARDS")
OUT.append("INSERT INTO cards (account_id, card_type, issue_date, expiry_date, credit_limit, status) VALUES")
rows = []
for (acc_id, cust_id, opened, _) in accounts:
    if random.random() < 0.85:
        card_type = random.choices(["DEBIT","CREDIT"],[0.65,0.35])[0]
        issue = opened + timedelta(days=random.randint(0,60))
        expiry = issue + timedelta(days=365*4)
        limit = round(random.uniform(2000,50000),2) if card_type=="CREDIT" else "NULL"
        status = random.choices(["ACTIVE","BLOCKED","EXPIRED"],[0.88,0.05,0.07])[0]
        rows.append(f"({acc_id}, '{card_type}', '{issue}', '{expiry}', {limit}, '{status}')")
OUT.append(",\n".join(rows) + ";\n")

# ------------------------------------------------------------
# 7. LOANS
# ------------------------------------------------------------
loan_types = ["PERSONAL","MORTGAGE","AUTO","BUSINESS"]
loans = []
OUT.append("-- 7. LOANS")
OUT.append("INSERT INTO loans (customer_id, loan_type, principal_amount, interest_rate, term_months, start_date, status) VALUES")
rows = []
loan_id_counter = 1
for cust_id in range(1, n_customers + 1):
    if random.random() < 0.4:
        loan_type = random.choice(loan_types)
        principal = {"PERSONAL": (5000,50000), "MORTGAGE": (200000,1500000),
                     "AUTO": (100000,600000), "BUSINESS": (50000,800000)}[loan_type]
        amount = round(random.uniform(*principal), 2)
        rate = round(random.uniform(1.5, 4.5), 2)
        term = random.choice([12,24,36,48,60,120,240])
        start = date(2018,1,1) + timedelta(days=random.randint(0, 365*7))
        status = random.choices(["ACTIVE","PAID_OFF","DEFAULTED"],[0.6,0.32,0.08])[0]
        rows.append(f"({cust_id}, '{loan_type}', {amount}, {rate}, {term}, '{start}', '{status}')")
        loans.append((loan_id_counter, start, term, amount, status))
        loan_id_counter += 1
OUT.append(",\n".join(rows) + ";\n")

# ------------------------------------------------------------
# 8. LOAN_PAYMENTS
# ------------------------------------------------------------
OUT.append("-- 8. LOAN_PAYMENTS")
OUT.append("INSERT INTO loan_payments (loan_id, payment_date, amount_paid, is_late) VALUES")
rows = []
for (loan_id, start, term, amount, status) in loans:
    monthly = round(amount / term, 2)
    n_payments = term if status == "PAID_OFF" else random.randint(1, max(term//2,1))
    for m in range(n_payments):
        pay_date = start + timedelta(days=30*(m+1))
        if pay_date > date(2025,12,31):
            break
        is_late = random.random() < 0.12
        rows.append(f"({loan_id}, '{pay_date}', {monthly}, {str(is_late).upper()})")
OUT.append(",\n".join(rows) + ";\n")

with open("seed/02_seed_data.sql", "w", encoding="utf-8") as f:
    f.write("-- ============================================================\n")
    f.write("-- SEED DATA - Otomatik üretilen gerçekçi test verisi\n")
    f.write("-- ============================================================\n\n")
    f.write("\n".join(OUT))

print(f"Üretildi: {n_customers} müşteri, {n_accounts} hesap, {len(loans)} kredi")
