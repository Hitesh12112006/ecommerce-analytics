# prep.py  |  pip install pandas numpy
import numpy as np, pandas as pd, sqlite3
rng = np.random.default_rng(42)

# --- 1. synthetic raw data (skip if you have a real CSV) ---
n = 5000
raw = pd.DataFrame({
  "order_id": np.arange(1, n+1),
  "customer_id": rng.integers(1, 801, n),
  "order_date": pd.to_datetime("2025-01-01") + pd.to_timedelta(rng.integers(0, 365, n), unit="D"),
  "category": rng.choice(["Electronics","Fashion","Home","Beauty","Sports"], n, p=[.28,.27,.2,.15,.1]),
  "region": rng.choice(["North","South","East","West"], n),
  "quantity": rng.integers(1, 5, n),
  "unit_price": rng.choice([9.99,19.99,49.99,99.99,199.99], n),
  "discount": rng.choice([0,0,0.05,0.1,0.2], n),
})
raw.loc[rng.choice(n, 60, replace=False), "region"] = None      # inject dirty data
raw = pd.concat([raw, raw.sample(40, random_state=1)])           # duplicates
raw.to_csv("raw_orders.csv", index=False)

# --- 2. cleaning ---
df = pd.read_csv("raw_orders.csv", parse_dates=["order_date"])
df = df.drop_duplicates()
df["region"] = df["region"].fillna("Unknown")
df = df[(df.quantity > 0) & (df.unit_price > 0)]
df["revenue"] = (df.quantity * df.unit_price * (1 - df.discount)).round(2)
df["month"] = df.order_date.dt.to_period("M").astype(str)
print(df.shape, df.isna().sum().sum(), "missing values left")

# --- 3. load to SQL ---
con = sqlite3.connect("shop.db")
df.to_sql("orders", con, if_exists="replace", index=False)
df[["customer_id"]].drop_duplicates().to_sql("customers", con, if_exists="replace", index=False)
df.to_csv("clean_orders.csv", index=False)   # for Power BI
