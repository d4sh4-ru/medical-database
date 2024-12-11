DROP DATABASE IF EXISTS MedTrack;

CREATE DATABASE MedTrack;

\connect medtrack

CREATE SCHEMA IF NOT EXISTS core;

SET search_path = core;

-- Определение доменов

-- Email: Проверка на соответствие email-адресу
CREATE DOMAIN email_type AS VARCHAR(50)
    CHECK (VALUE ~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$');

-- RussianName: Проверка на корректность русских имен
CREATE DOMAIN russian_name AS VARCHAR(30)
    CHECK (VALUE ~ '^[А-Яа-я]+$');

-- PhoneNumber: Проверка на соответствие формату российского номера телефона
CREATE DOMAIN phone_number AS VARCHAR(12)
    CHECK (VALUE ~ '^\+7[0-9]{10}$');

-- Status: Проверка на корректность статуса (буквы и пробелы)
CREATE DOMAIN status_type AS VARCHAR(50)
    CHECK (VALUE ~ '^[A-Za-zА-Яа-я ]+$');

-- RoleName: Проверка на корректность имени роли (буквы)
CREATE DOMAIN role_name AS VARCHAR(11)
    CHECK (VALUE ~ '^[A-Za-zА-Яа-я]+$');

-- DosageString: Проверка на корректность строки дозировки
CREATE DOMAIN dosage_string AS VARCHAR(255)
    CHECK (VALUE ~ '^[0-9]+ ?[A-Za-zА-Яа-я]+$');

-- Country: Проверка на корректность названия страны
CREATE DOMAIN country_type AS VARCHAR(20)
    CHECK (VALUE ~ '^[A-Za-zА-Яа-я ]+$');

--
-- Создание таблиц
--

CREATE TABLE Roles (
    id SERIAL PRIMARY KEY,
    name role_name NOT NULL
);

CREATE TABLE Users (
    email email_type PRIMARY KEY,
    last_name russian_name,
    first_name russian_name,
    middle_name russian_name,
    phone_number phone_number,
    password_hash VARCHAR(60),
    role_id INT REFERENCES Roles(id) ON DELETE CASCADE ON UPDATE CASCADE,
    is_deleted BOOLEAN DEFAULT FALSE
);

CREATE TABLE RelatedUsers (
    patient_email email_type REFERENCES Users(email) ON DELETE CASCADE ON UPDATE CASCADE,
    related_email email_type REFERENCES Users(email) ON DELETE CASCADE ON UPDATE CASCADE,
    notification_settings JSON,
    is_deleted BOOLEAN DEFAULT FALSE,
    PRIMARY KEY (patient_email, related_email)
);

CREATE TABLE ReleaseForms (
    id SERIAL PRIMARY KEY,
    dosage_per_tablet dosage_string,
    tablets_count INT CHECK (tablets_count > 0)
);

CREATE TABLE PharmacologicalGroups (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) CHECK (name ~ '^[A-Za-zА-Яа-я0-9 ]+$')
);

CREATE TABLE LegalEntities (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) CHECK (name ~ '^[A-Za-zА-Яа-я0-9 ]+$'),
    country country_type
);

CREATE TABLE Medications (
    trade_name VARCHAR(255) PRIMARY KEY CHECK (trade_name ~ '^[A-Za-zА-Яа-я0-9 ]+$'),
    legal_entity_id INT REFERENCES LegalEntities(id) ON DELETE CASCADE ON UPDATE CASCADE,
    release_form_id INT REFERENCES ReleaseForms(id) ON DELETE CASCADE ON UPDATE CASCADE,
    pharmacological_group_id INT REFERENCES PharmacologicalGroups(id) ON DELETE CASCADE ON UPDATE CASCADE,
    storage_conditions TEXT,
    is_prescription BOOLEAN,
    is_dietary_supplement BOOLEAN
);

CREATE TABLE Instructions (
    id SERIAL PRIMARY KEY,
    medication_trade_name VARCHAR(255) REFERENCES Medications(trade_name) ON DELETE CASCADE ON UPDATE CASCADE,
    content TEXT
);

CREATE TABLE MedicationRestock (
    id SERIAL PRIMARY KEY,
    medication_trade_name VARCHAR(255) REFERENCES Medications(trade_name) ON DELETE CASCADE ON UPDATE CASCADE,
    user_email email_type REFERENCES Users(email) ON DELETE CASCADE ON UPDATE CASCADE,
    request_date TIMESTAMP,
    restock_date TIMESTAMP,
    remaining_quantity INT CHECK (remaining_quantity >= 0)
);

CREATE TABLE AdministrationMethods (
    id SERIAL PRIMARY KEY,
    medication_trade_name VARCHAR(255) REFERENCES Medications(trade_name) ON DELETE CASCADE ON UPDATE CASCADE,
    single_dosage dosage_string,
    interval INTERVAL
);

CREATE TABLE AdministrationTimes (
    id SERIAL PRIMARY KEY,
    method_id INT REFERENCES AdministrationMethods(id) ON DELETE CASCADE ON UPDATE CASCADE,
    time TIME NOT NULL
);

CREATE TABLE MedicationSchedules (
    id SERIAL PRIMARY KEY,
    medication_trade_name VARCHAR(255) REFERENCES Medications(trade_name) ON DELETE CASCADE ON UPDATE CASCADE,
    user_email email_type REFERENCES Users(email) ON DELETE CASCADE ON UPDATE CASCADE,
    start_date DATE,
    end_date DATE,
    administration_method_id INT REFERENCES AdministrationMethods(id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE MedicationNotifications (
    id SERIAL PRIMARY KEY,
    schedule_id INT REFERENCES MedicationSchedules(id) ON DELETE CASCADE ON UPDATE CASCADE,
    user_email email_type REFERENCES Users(email) ON DELETE CASCADE ON UPDATE CASCADE,
    related_user_email email_type REFERENCES Users(email) ON DELETE CASCADE ON UPDATE CASCADE,
    sent_at TIMESTAMP,
    status status_type,
    actual_taken_at TIMESTAMP
);

CREATE TABLE PharmacySearchTemplates (
    id SERIAL PRIMARY KEY,
    pharmacy_name VARCHAR(255) CHECK (pharmacy_name ~ '^[A-Za-zА-Яа-я ]+$'),
    search_url_template TEXT
);

--
-- Создание представлений
--



--
-- Создание индексов
--

-- Частичные

-- Индекс который возвращает всех неудалённых пользователей
CREATE INDEX idx_users_not_deleted ON core.users (email)
WHERE is_deleted = FALSE;

-- Индекс для поиска всех БАДов
CREATE INDEX idx_medications_is_prescription ON core.medications (trade_name)
WHERE is_dietary_supplement = TRUE;

-- Составные

-- Для запросов фильтрующих по пользователю и дате
CREATE INDEX idx_medication_schedules_user_date
ON core.medicationschedules (user_email, start_date, end_date);

-- Полнотекстовые

-- Текст инструкций
CREATE INDEX idx_instructions_content_fulltext
ON core.instructions USING gin (to_tsvector('russian', content));

-- Индекс на названия аптек, так как поиск может происходить как по id, так и по названию аптеки
CREATE INDEX idx_pharmacysearchtemplates_pharmacy_name
ON core.pharmacysearchtemplates (pharmacy_name);