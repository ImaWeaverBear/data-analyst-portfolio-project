--Cek jumlah data tiap tabel

SELECT 'orders' AS table_name, COUNT(*) AS total_rows
FROM train_data_olist_orderss

UNION ALL

SELECT 'order_items' AS table_name, COUNT(*) AS total_rows
FROM train_data_olist_order_items

UNION ALL

SELECT 'order_payments' AS table_name, COUNT(*) AS total_rows
FROM train_data_olist_order_payments;

--Cek struktur tabel dan tipe data
SELECT 
    table_name,
    column_name,
    data_type,
    character_maximum_length
FROM information_schema.columns
WHERE table_name IN (
    'train_data_olist_orderss',
    'train_data_olist_order_items',
    'train_data_olist_order_payments'
)
ORDER BY table_name, ordinal_position;

-- Dari sini, diketahui kolom yang mempunyai sistem date masih bertipe varchar, maka dari itu
-- harus diubah terlebih dahulu.

ALTER TABLE train_data_olist_orderss
ALTER COLUMN order_purchase_timestamp TYPE timestamp 
USING NULLIF(order_purchase_timestamp, '')::timestamp;

ALTER TABLE train_data_olist_orderss
ALTER COLUMN order_approved_at TYPE timestamp 
USING NULLIF(order_approved_at, '')::timestamp;

ALTER TABLE train_data_olist_orderss
ALTER COLUMN order_delivered_carrier_date TYPE timestamp 
USING NULLIF(order_delivered_carrier_date, '')::timestamp;

ALTER TABLE train_data_olist_orderss
ALTER COLUMN order_delivered_customer_date TYPE timestamp 
USING NULLIF(order_delivered_customer_date, '')::timestamp;

ALTER TABLE train_data_olist_orderss
ALTER COLUMN order_estimated_delivery_date TYPE timestamp 
USING NULLIF(order_estimated_delivery_date, '')::timestamp;

ALTER TABLE train_data_olist_order_items
ALTER COLUMN shipping_limit_date TYPE timestamp
USING NULLIF(shipping_limit_date, '')::timestamp;

-- Mengubah nilai uang dari float ke numeric
ALTER TABLE train_data_olist_order_items
ALTER COLUMN price TYPE numeric(10,2)
USING price::numeric(10,2);

ALTER TABLE train_data_olist_order_items
ALTER COLUMN freight_value TYPE numeric(10,2)
USING freight_value::numeric(10,2);

ALTER TABLE train_data_olist_order_payments
ALTER COLUMN payment_value TYPE numeric(10,2)
USING payment_value::numeric(10,2);

-- Cek
SELECT 
    table_name,
    column_name,
    data_type,
    character_maximum_length
FROM information_schema.columns
WHERE table_name IN (
    'train_data_olist_orderss',
    'train_data_olist_order_items',
    'train_data_olist_order_payments'
)
ORDER BY table_name, ordinal_position;

-- Primary key Unique Check
SELECT 
    COUNT(*) AS total_rows,
    COUNT(DISTINCT order_id) AS unique_order_id
FROM train_data_olist_orderss;

SELECT 
    COUNT(*) AS total_rows,
    COUNT(DISTINCT (order_id, order_item_id)) AS unique_combination
FROM train_data_olist_order_items;

SELECT 
    COUNT(*) AS total_rows,
    COUNT(DISTINCT (order_id, payment_sequential)) AS unique_combination
FROM train_data_olist_order_payments;

-- Membuat primary key
ALTER TABLE train_data_olist_orderss
ADD CONSTRAINT pk_orderss
PRIMARY KEY (order_id);

ALTER TABLE train_data_olist_order_items
ADD CONSTRAINT pk_order_items
PRIMARY KEY (order_id, order_item_id);

ALTER TABLE train_data_olist_order_payments
ADD CONSTRAINT pk_order_payments
PRIMARY KEY (order_id, payment_sequential);

-- Cek order_id pada order_items yang tidak ada di orderss
SELECT COUNT(*) AS missing_order_items
FROM train_data_olist_order_items oi
LEFT JOIN train_data_olist_orderss o
ON oi.order_id = o.order_id
WHERE o.order_id IS NULL;

-- Cek order_id pada order_payments yang tidak ada di orderss
SELECT COUNT(*) AS missing_order_payments
FROM train_data_olist_order_payments op
LEFT JOIN train_data_olist_orderss o
ON op.order_id = o.order_id
WHERE o.order_id IS NULL;

--Cek Primary Key
SELECT
    tc.table_name,
    tc.constraint_name,
    kcu.column_name
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu
ON tc.constraint_name = kcu.constraint_name
AND tc.table_name = kcu.table_name
WHERE tc.constraint_type = 'PRIMARY KEY'
AND tc.table_name IN (
    'train_data_olist_orderss',
    'train_data_olist_order_items',
    'train_data_olist_order_payments',
    'clean_orders',
    'clean_order_items',
    'clean_order_payments'
)
ORDER BY tc.table_name, kcu.ordinal_position;

-- Dikarenakan banyak table yang tidak berelasi, akan lebih baik membuat tabel bersih
-- Membuat tabel clean_orders yang hanya berisi order_id
-- yang tersedia pada orderss, order_items, dan order_payments
CREATE TABLE clean_orders AS
SELECT DISTINCT o.*
FROM train_data_olist_orderss o
WHERE o.order_id IN (
    SELECT order_id FROM train_data_olist_order_items
)
AND o.order_id IN (
    SELECT order_id FROM train_data_olist_order_payments
);


CREATE TABLE clean_order_items AS
SELECT oi.*
FROM train_data_olist_order_items oi
JOIN clean_orders co
ON oi.order_id = co.order_id;

CREATE TABLE clean_order_payments AS
SELECT op.*
FROM train_data_olist_order_payments op
JOIN clean_orders co
ON op.order_id = co.order_id;

--Cek Jumlah Data Clean Table

SELECT 'clean_orders' AS table_name, COUNT(*) AS total_rows
FROM clean_orders

UNION ALL

SELECT 'clean_order_items' AS table_name, COUNT(*) AS total_rows
FROM clean_order_items

UNION ALL

SELECT 'clean_order_payments' AS table_name, COUNT(*) AS total_rows
FROM clean_order_payments;

--Buat Primary Key pada Clean Table
ALTER TABLE clean_orders
ADD CONSTRAINT pk_clean_orders
PRIMARY KEY (order_id);

ALTER TABLE clean_order_items
ADD CONSTRAINT pk_clean_order_items
PRIMARY KEY (order_id, order_item_id);

ALTER TABLE clean_order_payments
ADD CONSTRAINT pk_clean_order_payments
PRIMARY KEY (order_id, payment_sequential);

--Buat Foreign Key pada Clean Table
ALTER TABLE clean_order_items
ADD CONSTRAINT fk_clean_order_items_orders
FOREIGN KEY (order_id)
REFERENCES clean_orders(order_id);

ALTER TABLE clean_order_payments
ADD CONSTRAINT fk_clean_order_payments_orders
FOREIGN KEY (order_id)
REFERENCES clean_orders(order_id);


-- Cek apakah FK berhasil
SELECT
    conname AS constraint_name,
    conrelid::regclass AS table_name,
    confrelid::regclass AS referenced_table
FROM pg_constraint
WHERE conrelid IN (
    'clean_orders'::regclass,
    'clean_order_items'::regclass,
    'clean_order_payments'::regclass
);

SELECT
    tc.constraint_name,
    tc.table_name AS source_table,
    kcu.column_name AS source_column,
    ccu.table_name AS referenced_table,
    ccu.column_name AS referenced_column
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu
    ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage ccu
    ON ccu.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY'
AND tc.table_name IN (
    'clean_order_items',
    'clean_order_payments',
    'clean_orders'
)
ORDER BY tc.table_name, tc.constraint_name;

-- 2. DDL & DML PROCESS
----------------------------------------------------------
----------------------------------------------------------

-- Pada bagian ini dilakukan proses DDL dan DML.
-- DDL digunakan untuk memodifikasi struktur tabel dan constraint.
-- DML digunakan untuk menambahkan, memperbarui, dan menghapus data.

-- Cek apakah order_status pada clean_orders memiliki NULL
SELECT COUNT(*) AS null_order_status
FROM clean_orders
WHERE order_status IS NULL;

-- Menambahkan constraint NOT NULL pada kolom order_status
ALTER TABLE clean_orders
ALTER COLUMN order_status SET NOT NULL;

-- Cek apakah payment_type pada clean_order_payments memiliki NULL
SELECT COUNT(*) AS null_payment_type
FROM clean_order_payments
WHERE payment_type IS NULL;

-- Menambahkan constraint NOT NULL pada kolom payment_type
ALTER TABLE clean_order_payments
ALTER COLUMN payment_type SET NOT NULL;


-- Membuat tabel referensi status order
CREATE TABLE dim_order_status (
    status_id SERIAL PRIMARY KEY,
    order_status VARCHAR(50) UNIQUE NOT NULL,
    status_description VARCHAR(255)
);

-- INSERT data ke tabel dim_order_status
INSERT INTO dim_order_status (order_status, status_description)
SELECT DISTINCT
    order_status,
    CASE 
        WHEN order_status = 'delivered' THEN 'Order has been delivered to customer'
        WHEN order_status = 'shipped' THEN 'Order has been shipped'
        WHEN order_status = 'canceled' THEN 'Order has been canceled'
        WHEN order_status = 'invoiced' THEN 'Order has been invoiced'
        WHEN order_status = 'processing' THEN 'Order is being processed'
        ELSE 'Other order status'
    END AS status_description
FROM clean_orders
WHERE order_status IS NOT NULL;

-- Cek
SELECT *
FROM dim_order_status
ORDER BY status_id;

-- Menambahkan foreign key dari clean_orders ke dim_order_status
ALTER TABLE clean_orders
ADD CONSTRAINT fk_clean_orders_status
FOREIGN KEY (order_status)
REFERENCES dim_order_status(order_status);

SELECT
    conname AS constraint_name,
    conrelid::regclass AS table_name,
    confrelid::regclass AS referenced_table
FROM pg_constraint
WHERE conrelid IN (
    'clean_orders'::regclass,
    'clean_order_items'::regclass,
    'clean_order_payments'::regclass,
    'dim_order_status'::regclass
);

-- Menambahkan kolom data_source pada clean_orders
ALTER TABLE clean_orders
ADD COLUMN IF NOT EXISTS data_source VARCHAR(50);

-- UPDATE data_source untuk semua data clean_orders
UPDATE clean_orders
SET data_source = 'cleaned_olist_sample'
WHERE data_source IS NULL;

--Cek
SELECT order_id, order_status, data_source
FROM clean_orders
LIMIT 10;

-- Membuat tabel demo untuk proses DML
CREATE TABLE dml_demo_orders AS
SELECT *
FROM clean_orders
LIMIT 10;

-- Penambahan Primary key
ALTER TABLE dml_demo_orders
ADD CONSTRAINT pk_dml_demo_orders
PRIMARY KEY (order_id);

-- Menambahkan data baru ke tabel demo
INSERT INTO dml_demo_orders (
    order_id,
    customer_id,
    order_status,
    order_purchase_timestamp,
    order_approved_at,
    order_delivered_carrier_date,
    order_delivered_customer_date,
    order_estimated_delivery_date,
    data_source
)
VALUES (
    'demo_order_001',
    'demo_customer_001',
    'delivered',
    '2018-01-01 10:00:00',
    '2018-01-01 11:00:00',
    '2018-01-02 09:00:00',
    '2018-01-05 15:00:00',
    '2018-01-10 00:00:00',
    'manual_insert_demo'
);

-- Cek
SELECT *
FROM dml_demo_orders;

-- Memperbarui status order pada tabel demo
UPDATE dml_demo_orders
SET 
    order_status = 'shipped',
    data_source = 'manual_update_demo'
WHERE order_id = 'demo_order_001';

-- Cek
SELECT order_id, customer_id, order_status, data_source
FROM dml_demo_orders
WHERE order_id = 'demo_order_001';

-- Menghapus data demo
DELETE FROM dml_demo_orders
WHERE order_id = 'demo_order_001';

-- Cek
SELECT *
FROM dml_demo_orders
WHERE order_id = 'demo_order_001';

--Pada tahap DDL & DML Process, dilakukan modifikasi struktur tabel menggunakan ALTER TABLE, seperti penambahan kolom data_source dan penerapan constraint NOT NULL. 
--Selain itu, dibuat tabel referensi dim_order_status untuk menerapkan constraint PRIMARY KEY, UNIQUE, dan NOT NULL. 
--Tabel ini juga dihubungkan dengan clean_orders menggunakan FOREIGN KEY.
--Untuk proses DML, dibuat tabel dml_demo_orders agar manipulasi data tidak merusak dataset utama. 
--Pada tabel demo tersebut dilakukan proses INSERT untuk menambahkan data baru, UPDATE untuk memperbarui data, dan DELETE untuk menghapus data.


-- 3. BASIC SQL QUERY
----------------------------------------------------------
----------------------------------------------------------

-- Pada bagian ini dilakukan query dasar untuk menampilkan,
-- memfilter, mengurutkan, dan meringkas data menggunakan
-- SELECT, WHERE, ORDER BY, GROUP BY, HAVING, dan aggregate function.

-- Menampilkan 10 data pertama dari tabel orders
SELECT 
    order_id,
    customer_id,
    order_status,
    order_purchase_timestamp,
    order_estimated_delivery_date
FROM train_data_olist_orderss
LIMIT 10;

-- Menampilkan order dengan status delivered
SELECT 
    order_id,
    customer_id,
    order_status,
    order_purchase_timestamp
FROM train_data_olist_orderss
WHERE order_status = 'delivered'
LIMIT 10;

-- Menampilkan order delivered yang dibeli setelah tahun 2017
SELECT 
    order_id,
    customer_id,
    order_status,
    order_purchase_timestamp
FROM train_data_olist_orderss
WHERE order_status = 'delivered'
AND order_purchase_timestamp >= '2018-01-01'
ORDER BY order_purchase_timestamp ASC
LIMIT 10;

-- Menampilkan order status yang mengandung huruf 'deliv'
SELECT 
    order_id,
    customer_id,
    order_status
FROM train_data_olist_orderss
WHERE order_status LIKE '%deliv%'
LIMIT 10;

-- Mengurutkan pembayaran dari nilai terbesar
SELECT 
    order_id,
    payment_type,
    payment_installments,
    payment_value
FROM train_data_olist_order_payments
ORDER BY payment_value DESC
LIMIT 10;

-- Menghitung jumlah order berdasarkan status
SELECT 
    order_status,
    COUNT(*) AS total_orders
FROM train_data_olist_orderss
GROUP BY order_status
ORDER BY total_orders DESC;

-- Menampilkan status order yang memiliki jumlah order lebih dari 100
SELECT 
    order_status,
    COUNT(*) AS total_orders
FROM train_data_olist_orderss
GROUP BY order_status
HAVING COUNT(*) > 100
ORDER BY total_orders DESC;

-- Aggregate function pada data pembayaran
SELECT 
    COUNT(*) AS total_transactions,
    SUM(payment_value) AS total_payment_value,
    AVG(payment_value) AS average_payment_value,
    MIN(payment_value) AS minimum_payment_value,
    MAX(payment_value) AS maximum_payment_value
FROM train_data_olist_order_payments;

-- Ringkasan pembayaran berdasarkan metode pembayaran
SELECT 
    payment_type,
    COUNT(*) AS total_transactions,
    SUM(payment_value) AS total_payment_value,
    AVG(payment_value) AS average_payment_value,
    MIN(payment_value) AS minimum_payment_value,
    MAX(payment_value) AS maximum_payment_value
FROM train_data_olist_order_payments
GROUP BY payment_type
ORDER BY total_payment_value DESC;

-- Query ini digunakan untuk mengidentifikasi masalah awal
-- yang berkaitan dengan kualitas data dan performa order fulfillment.

--Cek missing delivery information
SELECT 
    COUNT(*) AS total_orders,
    COUNT(*) FILTER (WHERE order_approved_at IS NULL) AS missing_approved_at,
    COUNT(*) FILTER (WHERE order_delivered_carrier_date IS NULL) AS missing_carrier_date,
    COUNT(*) FILTER (WHERE order_delivered_customer_date IS NULL) AS missing_customer_delivery_date,
    COUNT(*) FILTER (WHERE order_estimated_delivery_date IS NULL) AS missing_estimated_delivery_date
FROM train_data_olist_orderss;

-- Cek delivery performance
SELECT 
    CASE
        WHEN order_delivered_customer_date IS NULL THEN 'Missing Delivery Date'
        WHEN order_delivered_customer_date > order_estimated_delivery_date THEN 'Late Delivery'
        ELSE 'On Time Delivery'
    END AS delivery_performance,
    COUNT(*) AS total_orders,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS percentage
FROM train_data_olist_orderss
GROUP BY delivery_performance
ORDER BY total_orders DESC;

-- Cek rata-rata lama pengiriman
SELECT 
    ROUND(AVG(DATE_PART('day', order_delivered_customer_date - order_purchase_timestamp))::numeric, 2) AS avg_delivery_days,
    MIN(DATE_PART('day', order_delivered_customer_date - order_purchase_timestamp)) AS min_delivery_days,
    MAX(DATE_PART('day', order_delivered_customer_date - order_purchase_timestamp)) AS max_delivery_days
FROM train_data_olist_orderss
WHERE order_delivered_customer_date IS NOT NULL;

--Cek kontribusi metode pembayaran
SELECT 
    payment_type,
    COUNT(*) AS total_transactions,
    SUM(payment_value) AS total_payment_value,
    ROUND(SUM(payment_value) * 100.0 / SUM(SUM(payment_value)) OVER (), 2) AS payment_contribution_pct,
    AVG(payment_value) AS avg_payment_value
FROM train_data_olist_order_payments
GROUP BY payment_type
ORDER BY total_payment_value DESC;

-- Pada tahap Basic SQL Query, dilakukan proses pembacaan dan eksplorasi data menggunakan SELECT, WHERE, 
-- ORDER BY, GROUP BY, HAVING, dan aggregate function. Query 
-- SELECT digunakan untuk menampilkan data utama, 
-- WHERE digunakan untuk memfilter data berdasarkan kondisi tertentu, 
-- ORDER BY digunakan untuk mengurutkan data, sedangkan GROUP BY dan 
-- HAVING digunakan untuk menghasilkan ringkasan data berdasarkan kategori tertentu. 
-- Aggregate function yang digunakan meliputi COUNT, SUM, AVG, MIN, 
-- dan MAX untuk menganalisis jumlah transaksi, total nilai pembayaran, rata-rata pembayaran, serta nilai minimum dan maksimum pembayaran.

-- 4. INTERMEDIATE SQL QUERY
----------------------------------------------------------
----------------------------------------------------------

-- Pada bagian ini dilakukan analisis SQL tingkat menengah
-- menggunakan CASE WHEN, INNER JOIN, UNION ALL, dan subquery.

-- Membuat kategori performa pengiriman berdasarkan tanggal aktual dan estimasi
SELECT 
    order_id,
    customer_id,
    order_status,
    order_purchase_timestamp,
    order_delivered_customer_date,
    order_estimated_delivery_date,
    CASE
        WHEN order_delivered_customer_date IS NULL THEN 'Missing Delivery Date'
        WHEN order_delivered_customer_date > order_estimated_delivery_date THEN 'Late Delivery'
        ELSE 'On Time Delivery'
    END AS delivery_performance
FROM train_data_olist_orderss
LIMIT 20;

-- Membuat segmentasi nilai pembayaran
SELECT 
    order_id,
    payment_type,
    payment_installments,
    payment_value,
    CASE
        WHEN payment_value < 50 THEN 'Low Payment'
        WHEN payment_value BETWEEN 50 AND 200 THEN 'Medium Payment'
        ELSE 'High Payment'
    END AS payment_segment
FROM train_data_olist_order_payments
ORDER BY payment_value DESC
LIMIT 100;

-- INNER JOIN antara clean_orders dan clean_order_payments
-- untuk menampilkan order yang memiliki data pembayaran valid
SELECT 
    co.order_id,
    co.customer_id,
    co.order_status,
    cop.payment_type,
    cop.payment_value
FROM clean_orders co
INNER JOIN clean_order_payments cop
ON co.order_id = cop.order_id
LIMIT 20;

-- UNION ALL untuk menggabungkan beberapa hasil pengecekan masalah data
SELECT 
    'Missing Customer Delivery Date' AS issue_type,
    COUNT(*) AS total_issue
FROM train_data_olist_orderss
WHERE order_delivered_customer_date IS NULL

UNION ALL

SELECT 
    'Late Delivery' AS issue_type,
    COUNT(*) AS total_issue
FROM train_data_olist_orderss
WHERE order_delivered_customer_date > order_estimated_delivery_date

UNION ALL

SELECT 
    'Missing Approved Date' AS issue_type,
    COUNT(*) AS total_issue
FROM train_data_olist_orderss
WHERE order_approved_at IS NULL;

-- Subquery untuk menampilkan transaksi dengan nilai pembayaran
-- di atas rata-rata seluruh transaksi
SELECT 
    order_id,
    payment_type,
    payment_installments,
    payment_value
FROM train_data_olist_order_payments
WHERE payment_value > (
    SELECT AVG(payment_value)
    FROM train_data_olist_order_payments
)
ORDER BY payment_value DESC
LIMIT 20;

-- LEFT JOIN untuk melihat order yang belum memiliki data pembayaran
SELECT 
    co.order_id,
    co.customer_id,
    co.order_status,
    cop.payment_type,
    cop.payment_value
FROM clean_orders co
LEFT JOIN clean_order_payments cop
ON co.order_id = cop.order_id
WHERE cop.order_id IS NULL;

-- FULL JOIN untuk mengecek ketidaksesuaian order_id antara order dan payment
SELECT 
    COALESCE(co.order_id, cop.order_id) AS order_id,
    co.order_status,
    cop.payment_type,
    cop.payment_value,
    CASE 
        WHEN co.order_id IS NULL THEN 'Payment without Order'
        WHEN cop.order_id IS NULL THEN 'Order without Payment'
        ELSE 'Matched Data'
    END AS relation_status
FROM clean_orders co
FULL JOIN clean_order_payments cop
ON co.order_id = cop.order_id;

-- Subquery pada SELECT untuk membandingkan payment_value dengan rata-rata keseluruhan
SELECT 
    order_id,
    payment_type,
    payment_value,
    (
        SELECT AVG(payment_value)
        FROM clean_order_payments
    ) AS overall_avg_payment,
    payment_value - (
        SELECT AVG(payment_value)
        FROM clean_order_payments
    ) AS difference_from_avg
FROM clean_order_payments
LIMIT 20;

-- Subquery pada FROM untuk menganalisis ringkasan pembayaran
SELECT 
    payment_type,
    total_transactions,
    ROUND(total_payment_value::numeric, 2) AS total_payment_value,
    ROUND(avg_payment_value::numeric, 2) AS avg_payment_value
FROM (
    SELECT 
        payment_type,
        COUNT(*) AS total_transactions,
        SUM(payment_value) AS total_payment_value,
        AVG(payment_value) AS avg_payment_value
    FROM clean_order_payments
    GROUP BY payment_type
) payment_summary
WHERE total_payment_value > 1000
ORDER BY total_payment_value DESC;


-- RIGHT JOIN untuk melihat data pembayaran dan mencocokkannya dengan data order
SELECT 
    co.order_id AS order_id_from_orders,
    cop.order_id AS order_id_from_payments,
    co.order_status,
    cop.payment_type,
    cop.payment_value
FROM clean_orders co
RIGHT JOIN clean_order_payments cop
ON co.order_id = cop.order_id
LIMIT 20;

-- Pada tahap Intermediate SQL Query, digunakan CASE WHEN untuk membuat kategori performa
-- pengiriman dan segmentasi nilai pembayaran.
-- INNER JOIN digunakan untuk menggabungkan data order dan pembayaran yang valid.
-- LEFT JOIN digunakan untuk mengecek order yang tidak memiliki data pembayaran.
-- RIGHT JOIN digunakan untuk melihat data pembayaran dan mencocokkannya dengan data order.
-- FULL JOIN digunakan untuk mengecek ketidaksesuaian relasi order_id antara tabel order dan payment.
-- UNION ALL digunakan untuk menggabungkan beberapa hasil pengecekan masalah data,
-- seperti missing delivery date, late delivery, dan missing approved date.
-- Subquery digunakan pada WHERE, SELECT, dan FROM untuk membandingkan nilai pembayaran
-- dengan rata-rata keseluruhan serta membuat ringkasan pembayaran.

-- 5. ADVANCED SQL ANALYSIS
----------------------------------------------------------
----------------------------------------------------------

-- Pada bagian ini dilakukan analisis SQL lanjutan menggunakan
-- Common Table Expression (CTE), Window Function, OVER(),
-- PARTITION BY, ORDER BY, dan Top-N Analysis.

-- Top-N Analysis:
-- Mencari 5 transaksi pembayaran terbesar pada setiap payment_type
-- menggunakan RANK() sebagai window function.

WITH payment_rank AS (
    SELECT
        order_id,
        payment_type,
        payment_installments,
        payment_value,
        RANK() OVER (
            PARTITION BY payment_type
            ORDER BY payment_value DESC
        ) AS payment_rank
    FROM train_data_olist_order_payments
)
SELECT
    order_id,
    payment_type,
    payment_installments,
    payment_value,
    payment_rank
FROM payment_rank
WHERE payment_rank <= 5
ORDER BY payment_type, payment_rank;

-- Advanced SQL: Monthly payment trend, cumulative revenue, dan growth analysis
WITH monthly_payment AS (
    SELECT 
        DATE_TRUNC('month', co.order_purchase_timestamp) AS order_month,
        SUM(cop.payment_value) AS total_payment_value,
        COUNT(*) AS total_transactions
    FROM clean_orders co
    INNER JOIN clean_order_payments cop
    ON co.order_id = cop.order_id
    GROUP BY DATE_TRUNC('month', co.order_purchase_timestamp)
),

monthly_growth AS (
    SELECT 
        order_month,
        total_payment_value,
        total_transactions,
        LAG(total_payment_value) OVER (
            ORDER BY order_month
        ) AS previous_month_payment
    FROM monthly_payment
),

monthly_final AS (
    SELECT 
        order_month,
        total_payment_value,
        total_transactions,
        previous_month_payment,
        total_payment_value - previous_month_payment AS payment_growth,
        SUM(total_payment_value) OVER (
            ORDER BY order_month
        ) AS cumulative_payment_value,
        ROW_NUMBER() OVER (
            ORDER BY total_payment_value DESC
        ) AS row_number_rank,
        RANK() OVER (
            ORDER BY total_payment_value DESC
        ) AS payment_rank,
        DENSE_RANK() OVER (
            ORDER BY total_payment_value DESC
        ) AS dense_payment_rank
    FROM monthly_growth
)

SELECT *
FROM monthly_final
ORDER BY order_month;

-- Pada tahap Advanced SQL Analysis, digunakan Common Table Expression (CTE)
-- untuk membangun query yang lebih modular dan kompleks.
-- CTE yang digunakan terdiri dari monthly_payment, monthly_growth, dan monthly_final.
-- Window function yang digunakan meliputi LAG(), ROW_NUMBER(), RANK(), 
-- DENSE_RANK(), dan SUM() OVER().
-- LAG() digunakan untuk membandingkan nilai pembayaran bulan berjalan 
-- dengan bulan sebelumnya.
-- SUM() OVER() digunakan untuk menghitung cumulative payment value.
-- ROW_NUMBER(), RANK(), dan DENSE_RANK() digunakan untuk membuat ranking
-- berdasarkan total nilai pembayaran bulanan.
-- Analisis ini digunakan untuk melihat tren pembayaran bulanan,
-- pertumbuhan pembayaran, cumulative total, dan ranking performa bulanan.

-- 6. DATA CLEANING
----------------------------------------------------------
----------------------------------------------------------
-- Pada bagian ini dilakukan proses data cleaning menggunakan SQL.
-- Proses cleaning mencakup pengecekan missing values, duplicate data,
-- data inconsistency, handling missing values, standardisasi data,
-- dan validasi kualitas data.

-- Mengecek missing values pada kolom penting di tabel orders
SELECT 
    COUNT(*) AS total_orders,
    COUNT(*) FILTER (WHERE order_id IS NULL) AS missing_order_id,
    COUNT(*) FILTER (WHERE customer_id IS NULL) AS missing_customer_id,
    COUNT(*) FILTER (WHERE order_status IS NULL) AS missing_order_status,
    COUNT(*) FILTER (WHERE order_purchase_timestamp IS NULL) AS missing_purchase_date,
    COUNT(*) FILTER (WHERE order_delivered_customer_date IS NULL) AS missing_delivery_date
FROM train_data_olist_orderss;

-- Mengecek duplicate order_id pada tabel orders
SELECT 
    order_id,
    COUNT(*) AS duplicate_count
FROM train_data_olist_orderss
GROUP BY order_id
HAVING COUNT(*) > 1;

-- Mengecek data pengiriman yang tidak konsisten
-- yaitu tanggal diterima customer lebih awal dari tanggal pembelian
SELECT 
    order_id,
    order_purchase_timestamp,
    order_delivered_customer_date
FROM train_data_olist_orderss
WHERE order_delivered_customer_date < order_purchase_timestamp;


-- Handling missing value pada order_status menggunakan COALESCE
SELECT 
    order_id,
    customer_id,
    COALESCE(order_status, 'unknown') AS cleaned_order_status,
    order_purchase_timestamp,
    order_delivered_customer_date
FROM train_data_olist_orderss
LIMIT 50;

-- Membuat view orders_clean untuk kebutuhan analisis
CREATE OR REPLACE VIEW vw_orders_clean AS
SELECT
    order_id,
    customer_id,
    COALESCE(order_status, 'unknown') AS order_status,
    order_purchase_timestamp,
    order_approved_at,
    order_delivered_carrier_date,
    order_delivered_customer_date,
    order_estimated_delivery_date,
    CASE
        WHEN order_delivered_customer_date IS NULL THEN 'Missing Delivery Date'
        WHEN order_delivered_customer_date > order_estimated_delivery_date THEN 'Late Delivery'
        ELSE 'On Time Delivery'
    END AS delivery_performance
FROM train_data_olist_orderss;

-- Validasi hasil cleaning dari view orders_clean
SELECT 
    delivery_performance,
    COUNT(*) AS total_orders
FROM vw_orders_clean
GROUP BY delivery_performance
ORDER BY total_orders DESC;

-- Mendeteksi duplicate berdasarkan order_id menggunakan ROW_NUMBER
WITH duplicate_check AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (
            PARTITION BY order_id
            ORDER BY order_purchase_timestamp
        ) AS row_num
    FROM train_data_olist_orderss
)

SELECT *
FROM duplicate_check
WHERE row_num > 1;

-- Mendeteksi outlier pada payment_value menggunakan batas rata-rata + 3 standar deviasi
WITH payment_stats AS (
    SELECT 
        AVG(payment_value) AS avg_payment,
        STDDEV(payment_value) AS std_payment
    FROM clean_order_payments
),

payment_outlier AS (
    SELECT 
        cop.*,
        ps.avg_payment,
        ps.std_payment,
        CASE 
            WHEN cop.payment_value > ps.avg_payment + (3 * ps.std_payment)
            THEN 'Outlier'
            ELSE 'Normal'
        END AS outlier_status
    FROM clean_order_payments cop
    CROSS JOIN payment_stats ps
)

SELECT *
FROM payment_outlier
WHERE outlier_status = 'Outlier'
ORDER BY payment_value DESC;

-- Membuat view clean payment tanpa outlier
CREATE OR REPLACE VIEW vw_clean_order_payments_no_outlier AS
WITH payment_stats AS (
    SELECT 
        AVG(payment_value) AS avg_payment,
        STDDEV(payment_value) AS std_payment
    FROM clean_order_payments
)

SELECT 
    cop.*
FROM clean_order_payments cop
CROSS JOIN payment_stats ps
WHERE cop.payment_value <= ps.avg_payment + (3 * ps.std_payment);

-- Berdasarkan hasil pengecekan duplicate, tidak ditemukan duplicate order_id.
-- Oleh karena itu, proses duplicate removal tidak dilakukan secara fisik.
-- Validasi tetap dilakukan menggunakan ROW_NUMBER() untuk memastikan kualitas data.

-- 7. DASHBOARD & REPORTING
----------------------------------------------------------
----------------------------------------------------------

-- Pada bagian ini dibuat minimal 3 view berbeda untuk dashboard sederhana.
-- View digunakan untuk menampilkan summary, ranking, trend analysis,
-- dan segmentasi data berdasarkan hasil query SQL.

-- Melihat ringkasan performa pengiriman.
CREATE OR REPLACE VIEW vw_dashboard_delivery_summary AS
SELECT 
    delivery_performance,
    COUNT(*) AS total_orders,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS percentage
FROM vw_orders_clean
GROUP BY delivery_performance
ORDER BY total_orders DESC;

-- Cek
SELECT *
FROM vw_dashboard_delivery_summary;

-- Payment Type Performance
CREATE OR REPLACE VIEW vw_dashboard_payment_ranking AS
SELECT 
    payment_type,
    COUNT(*) AS total_transactions,
    SUM(payment_value) AS total_payment_value,
    AVG(payment_value) AS avg_payment_value,
    RANK() OVER (
        ORDER BY SUM(payment_value) DESC
    ) AS payment_rank
FROM train_data_olist_order_payments
GROUP BY payment_type
ORDER BY payment_rank;

--Cek
SELECT *
FROM vw_dashboard_payment_ranking;

--Trend & Segmentation
CREATE OR REPLACE VIEW vw_dashboard_monthly_payment_segment AS
SELECT 
    DATE_TRUNC('month', co.order_purchase_timestamp) AS order_month,
    CASE
        WHEN cop.payment_value < 50 THEN 'Low Payment'
        WHEN cop.payment_value BETWEEN 50 AND 200 THEN 'Medium Payment'
        ELSE 'High Payment'
    END AS payment_segment,
    COUNT(*) AS total_transactions,
    SUM(cop.payment_value) AS total_payment_value,
    AVG(cop.payment_value) AS avg_payment_value
FROM clean_orders co
INNER JOIN clean_order_payments cop
ON co.order_id = cop.order_id
GROUP BY 
    DATE_TRUNC('month', co.order_purchase_timestamp),
    CASE
        WHEN cop.payment_value < 50 THEN 'Low Payment'
        WHEN cop.payment_value BETWEEN 50 AND 200 THEN 'Medium Payment'
        ELSE 'High Payment'
    END
ORDER BY order_month, payment_segment;

--Cek
SELECT *
FROM vw_dashboard_monthly_payment_segment;

--View All Dashboard
SELECT table_name
FROM information_schema.views
WHERE table_name IN (
    'vw_dashboard_delivery_summary',
    'vw_dashboard_payment_ranking',
    'vw_dashboard_monthly_payment_segment'
);

-- view Advanced Dashboard untuk trend bulanan.
CREATE OR REPLACE VIEW vw_dashboard_monthly_payment_trend AS
WITH monthly_payment AS (
    SELECT 
        DATE_TRUNC('month', co.order_purchase_timestamp) AS order_month,
        SUM(cop.payment_value) AS total_payment_value,
        COUNT(*) AS total_transactions
    FROM clean_orders co
    INNER JOIN clean_order_payments cop
    ON co.order_id = cop.order_id
    GROUP BY DATE_TRUNC('month', co.order_purchase_timestamp)
)
SELECT 
    order_month,
    total_transactions,
    total_payment_value,
    SUM(total_payment_value) OVER (
        ORDER BY order_month
    ) AS cumulative_payment_value,
    LAG(total_payment_value) OVER (
        ORDER BY order_month
    ) AS previous_month_payment,
    total_payment_value - LAG(total_payment_value) OVER (
        ORDER BY order_month
    ) AS monthly_payment_growth
FROM monthly_payment
ORDER BY order_month;

--Cek
SELECT *
FROM vw_dashboard_monthly_payment_trend;

--Cek all
SELECT table_name
FROM information_schema.views
WHERE table_name IN (
    'vw_dashboard_delivery_summary',
    'vw_dashboard_payment_ranking',
    'vw_dashboard_monthly_payment_segment',
    'vw_dashboard_monthly_payment_trend'
);