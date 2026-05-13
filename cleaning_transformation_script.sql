-- ======================================================================
-- PROJECT      : Nickel Mining Data Preparation
-- ROLE         : Data Engineer (Cinta)
-- DESCRIPTION  : Script for Data Profiling, Cleaning, and Transformation
-- ======================================================================

-- ==========================================
-- TAHAP 1: DATA PROFILING (PENGECEKAN AWAL)
-- ==========================================

-- 1A. Mengecek sebaran statistik luas wilayah (Mendeteksi anomali nilai 0)
SELECT 
    MIN(luas_wilayah) AS luas_terkecil,
    ROUND(AVG(luas_wilayah), 2) AS rata_rata_luas,
    MAX(luas_wilayah) AS luas_terbesar,
    COUNT(luas_wilayah) AS total_data_tambang
FROM mines;

-- 1B. Mengecek duplikasi pada nama pelabuhan
SELECT name, COUNT(*) as jumlah_muncul
FROM ports
GROUP BY name
HAVING COUNT(*) > 1;

-- 1C. Mengecek "Data Menyamar" di tabel pelabuhan (UNLCODE)
SELECT unlcode, COUNT(*) 
FROM ports 
WHERE unlcode = '-' OR TRIM(unlcode) = '' 
GROUP BY unlcode;

-- ==========================================
-- TAHAP 2: DATA CLEANING & STANDARDIZATION
-- ==========================================

-- 2A. Standardisasi Nama Provinsi (Key untuk proses JOIN nantinya)
UPDATE mines SET provinsi = UPPER(TRIM(provinsi));
UPDATE ports SET province = UPPER(TRIM(province));

-- 2B. Standardisasi Status Penyelidikan
UPDATE mines SET status_penyelidikan = UPPER(TRIM(status_penyelidikan));

-- 2C. Menangani Missing Values & Data Menyamar ('-' menjadi NULL)
UPDATE ports SET unlcode = NULL WHERE unlcode = '-' OR TRIM(unlcode) = '';
UPDATE mines SET bijih_terbukti = NULL WHERE bijih_terbukti = 0;

-- 2D. Mencari tahu nilai rata-ratanya
SELECT 
    kabupaten, 
    status_penyelidikan, 
    AVG(luas_wilayah) AS rata_rata_luas,
    COUNT(*) AS jumlah_tambang_referensi
FROM mines

-- 2E. Imputasi Statistik (Menambal luas wilayah dengan rata-rata 5479.82 ha)
UPDATE mines SET luas_wilayah = 5479.82 
WHERE (nama_objek = 'Nikel Fayaul') 
AND luas_wilayah IS NULL;

-- ==========================================
-- TAHAP 3: DATA TRANSFORMATION & STRUCTURE
-- ==========================================

-- 3A. Membuat Data Mart Detail Tambang (Siap untuk EDA)
CREATE OR REPLACE VIEW vw_fact_mines AS
SELECT
    objectid, 
    nomor_lokasi, 
    nama_objek,
    UPPER(TRIM(kecamatan)) AS kecamatan,
    UPPER(TRIM(kabupaten)) AS kabupaten,
    UPPER(TRIM(provinsi))  AS provinsi,
    komoditi,
    UPPER(TRIM(status_penyelidikan)) AS status_penyelidikan,
    jenis_izin,
    bijih_terbukti,
    logam_terbukti,
    luas_wilayah,
    -- Feature Engineering: Kategori Luas
    CASE 
        WHEN luas_wilayah > 5000 THEN 'Besar'
        WHEN luas_wilayah >= 1000 AND luas_wilayah <= 5000 THEN 'Menengah'
        ELSE 'Kecil'
    END AS kategori_luas,
    license_status,
    ROUND(license_duration_years, 1) AS durasi_izin_tahun,
    tanggal_berlaku_sk,
    tanggal_berakhir_sk,
    latitude,
    longitude,
    -- Konversi Unit ke Kilometer
    ROUND(mine_port_meter / 1000, 2) AS jarak_pelabuhan_km,
    ROUND(mine_road_meter / 1000, 2) AS jarak_jalan_km,
    ROUND(mine_smelter_meter / 1000, 2) AS jarak_smelter_km
FROM mines;

-- 3B. Membuat Ringkasan Eksekutif (Agregasi per Provinsi)
CREATE OR REPLACE VIEW vw_summary_provinsi AS
SELECT 
    m.provinsi,
    COUNT(DISTINCT m.objectid) AS jumlah_tambang,
    SUM(m.bijih_terbukti) AS total_bijih_ton,
    ROUND(AVG(m.luas_wilayah), 2) AS rata_luas_ha,
    COUNT(DISTINCT p.name) AS jumlah_pelabuhan,
    SUM(p.vessel_in_port) AS total_aktivitas_kapal,
    ROUND(AVG(m.mine_port_meter / 1000), 2) AS rata_jarak_pelabuhan_km,
    ROUND(AVG(m.mine_road_meter / 1000), 2) AS rata_jarak_jalan_km,
    ROUND(AVG(m.mine_smelter_meter / 1000), 2) AS rata_jarak_smelter_km,
    SUM(CASE WHEN m.license_status = 'Active' THEN 1 ELSE 0 END) AS izin_aktif,
    SUM(CASE WHEN m.license_status = 'Expired' THEN 1 ELSE 0 END) AS izin_expired
FROM mines m
LEFT JOIN ports p ON m.provinsi = p.province
GROUP BY m.provinsi;