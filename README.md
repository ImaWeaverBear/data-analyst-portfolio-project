# Data Analyst Portfolio Project - Superstore Sales Analysis

## Overview
Project ini bertujuan untuk menganalisis performa bisnis Superstore menggunakan pendekatan Data Analytics yang mencakup data cleaning, exploratory data analysis (EDA), visualisasi dashboard, serta penyusunan insight dan rekomendasi bisnis.

Hasil analisis digunakan untuk menjawab permasalahan terkait profitabilitas perusahaan, performa kategori produk, serta dampak discount terhadap profit.

---

## Business Problem

Meskipun Superstore memiliki nilai penjualan (Sales) yang tinggi, profit yang dihasilkan belum optimal. Beberapa kategori dan sub-category bahkan menghasilkan profit yang rendah atau negatif.

Analisis ini dilakukan untuk menjawab beberapa pertanyaan utama:

1. Apakah tingginya sales sudah menghasilkan profit yang optimal?
2. Kategori dan sub-category mana yang paling menguntungkan dan paling merugikan?
3. Apakah pemberian discount yang tinggi berdampak terhadap profit perusahaan?

---

## Project Workflow

### 1. Data Understanding
Memahami struktur dataset Superstore yang terdiri dari informasi:

- Customer
- Product
- Category & Sub-Category
- Sales
- Quantity
- Discount
- Profit
- Order Date
- Region

Output:
- Identifikasi tipe data
- Jumlah data
- Struktur tabel
- Deskripsi setiap kolom

---

### 2. Data Cleaning

Proses pembersihan data dilakukan untuk memastikan kualitas data sebelum dianalisis.

Aktivitas:

- Memeriksa Missing Values
- Memeriksa Duplicate Data
- Memeriksa Outlier
- Memastikan Konsistensi Data
- Mengubah format data yang diperlukan

Output:
- Dataset bersih (Clean Dataset)
- Data siap digunakan untuk analisis

---

### 3. Exploratory Data Analysis (EDA)

Analisis eksploratif dilakukan untuk menemukan pola dan insight awal.

Aktivitas:

- Analisis Sales dan Profit
- Analisis Category dan Sub-Category
- Analisis Customer
- Analisis Discount
- Analisis Profit Ratio
- Analisis Tren Penjualan

Output:
- Statistik deskriptif
- Temuan awal terkait profitabilitas bisnis

---

### 4. Dashboard Development

Dashboard dibuat menggunakan Microsoft Power BI untuk memvisualisasikan hasil analisis secara interaktif.

Dashboard yang dibuat:

#### Profitability Overview Dashboard
Menampilkan:

- Total Sales
- Total Profit
- Total Customer
- Sales vs Profit Comparison
- Sales and Profit Trend
- Profit Ratio per Discount Level

#### Category Dashboard
Menampilkan:

- Profit by Category
- Profit by Sub-Category
- Customer Distribution
- Transaction Percentage by Category

#### Discount Dashboard
Menampilkan:

- Average Discount
- Discount vs Profit
- Average Discount by Sub-Category

Output:
- Interactive Dashboard (.pbix)

---

### 5. Business Insight & Recommendation

Berdasarkan hasil analisis ditemukan bahwa:

#### Insight 1
Sales yang tinggi belum tentu menghasilkan profit yang tinggi.

#### Insight 2
Technology merupakan kategori paling menguntungkan.

#### Insight 3
Furniture memiliki beberapa sub-category dengan profit negatif.

#### Insight 4
Discount tinggi (>40%) cenderung menghasilkan kerugian.

---

### Recommendation

- Fokus pada peningkatan profit, bukan hanya sales.
- Evaluasi strategi pricing dan biaya pengiriman pada kategori Furniture.
- Batasi pemberian discount berlebih.
- Prioritaskan kategori dan produk dengan profit ratio tinggi.

---

## Project Structure

```text
data-analyst-portfolio-project
│
├── README.md
│
├── data/
│   └── sales_data.csv
│
├── notebook/
│   └── analysis.ipynb
│
├── dashboard/
│   └── powerbi_dashboard.pbix
│
├── output/
│   └── visualization.png
│
└── report/
    └── summary.pdf
```

---

## Tools Used

- Python
  - Pandas
  - NumPy
  - Matplotlib
  - Seaborn

- Microsoft Power BI

- Jupyter Notebook

- GitHub

---

## Key Findings

| Metric | Value |
|----------|----------|
| Total Sales | $2.30M |
| Total Profit | $286.40K |
| Total Customers | 9,994 |
| Best Category | Technology |
| Worst Sub-Category | Tables |
| Avg. Discount | 15.62% |

---

## Conclusion

Superstore berhasil menghasilkan penjualan yang tinggi, namun profit belum optimal. Faktor utama yang memengaruhi profit adalah performa kategori tertentu dan strategi discount yang terlalu agresif. Dengan optimalisasi pricing dan discount policy, profit perusahaan berpotensi meningkat secara signifikan.
