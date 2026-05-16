# ⛏️ Nickel Mining Data Preparation & Integration

## 📌 Project Overview
Proyek ini bertujuan untuk membangun struktur dataset yang bersih dan terintegrasi mengenai potensi pertambangan nikel dan infrastruktur pelabuhan di wilayah Sulawesi dan Maluku. Dataset ini disiapkan sebagai pondasi awal (*Data Mart*) untuk tahapan Exploratory Data Analysis (EDA).

**Role:** Data Engineer 2 (Data Preparation)  
**Tools Used:** MySQL, PHPMyAdmin, SQL

## 🎯 Key Responsibilities & Workflow
Sebagai Data Engineer, fokus utama pada fase ini adalah memastikan kualitas data (*Data Quality*) sebelum diserahkan ke tim Data Analyst. 

### 1. Data Profiling & Quality Check
* Melakukan investigasi pada anomali nilai seperti luas wilayah `0` hektar.
* Mendeteksi isu *Data Type Masquerading* di mana missing values pada tabel pelabuhan tertulis sebagai karakter `-` (sebanyak 35 baris).

### 2. Data Cleaning & Handling Missing Values
* **Nullification:** Mengubah data palsu (`0` dan `-`) menjadi `NULL` agar tidak merusak perhitungan statistik (*skewness*).
* **Statistical Imputation:** Mengisi data lahan kosong pada beberapa tambang (misal: Nikel Fayaul) menggunakan pendekatan rata-rata wilayah (*mean imputation*) sebesar `5479.82 ha`.
* **Standardization:** Menyeragamkan format teks kunci penghubung menggunakan `UPPER()` dan `TRIM()` untuk meminimalisir kegagalan saat proses *Join*.

### 3. Data Transformation & Structuring
* **Feature Engineering:** Membuat kolom analitik baru, `kategori_luas` (Besar/Menengah/Kecil) berdasarkan distribusi kuartil statistik lahan.
* **Unit Conversion:** Mengonversi satuan ukur jarak spasial dari meter menjadi kilometer.
* **Data Mart Creation:** Membuat 2 struktur *View* siap pakai:
  1. `vw_fact_mines`: Tabel fakta granular per entitas tambang.
  2. `vw_summary_provinsi`: Tabel agregasi ringkasan eksekutif performa per provinsi.

## 📂 Repository Structure
* `database nickel` : database yang berisikan seluruh data berformat sql (`table mines`, `table ports`, `vw_fact_mines.csv`)
* `data clean fr db/can used for analytics` : Hasil akhir berupa *View* yang diekspor (`vw_fact_mines.csv`)
* `data clean fr db/tabel fr db` : Hasil akhir tabel mines dan tabel port yang diekspor dengan format csv
* `cleaning_and_transformation.sql` berisi seluruh riwayat *query*.
