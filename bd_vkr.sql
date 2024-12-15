DROP DATABASE IF EXISTS MedTrack;

CREATE DATABASE MedTrack;

\connect medtrack

CREATE SCHEMA IF NOT EXISTS core;

SET search_path = core;

-- Создание таблиц

-- Таблица: Roles
-- Содержит информацию о ролях пользователей
CREATE TABLE Roles (
    id SERIAL PRIMARY KEY, -- Уникальный идентификатор роли
    name VARCHAR(11) NOT NULL CHECK (name ~ '^[A-Za-zА-Яа-я]+$') -- Название роли (только буквы)
);

-- Таблица: Users
-- Содержит информацию о пользователях
CREATE TABLE Users (
    email VARCHAR(50) PRIMARY KEY CHECK (email ~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$') NOT NULL, -- Электронная почта пользователя (идентификатор)
    last_name VARCHAR(30) CHECK (last_name ~ '^[А-Яа-я]+$') NOT NULL, -- Фамилия пользователя
    first_name VARCHAR(30) CHECK (first_name ~ '^[А-Яа-я]+$') NOT NULL, -- Имя пользователя
    middle_name VARCHAR(30) CHECK (middle_name ~ '^[А-Яа-я]+$'), -- Отчество пользователя
    phone_number VARCHAR(12) CHECK (phone_number ~ '^\+7[0-9]{10}$'), -- Номер телефона пользователя
    password_hash VARCHAR(60) NOT NULL, -- Хэш пароля bcrypt
    role_id INT REFERENCES Roles(id) ON DELETE CASCADE ON UPDATE CASCADE, -- Ссылка на роль пользователя
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE -- Указатель на удаление записи
);

-- Таблица: RelatedUsers
-- Содержит информацию о связанных пользователях (например, родственники или опекуны)
CREATE TABLE RelatedUsers (
    patient_email VARCHAR(50) REFERENCES Users(email) ON DELETE CASCADE ON UPDATE CASCADE, -- Ссылка на пользователя-пациента
    related_email VARCHAR(50) REFERENCES Users(email) ON DELETE CASCADE ON UPDATE CASCADE, -- Ссылка на связанного пользователя
    notification_settings JSON, -- Настройки уведомлений
    is_deleted BOOLEAN DEFAULT FALSE, -- Указатель на удаление связи
    PRIMARY KEY (patient_email, related_email) -- Композитный первичный ключ
);

-- Таблица: ReleaseForms
-- Содержит информацию о формах выпуска лекарственных препаратов
CREATE TABLE ReleaseForms (
    id SERIAL PRIMARY KEY, -- Уникальный идентификатор формы выпуска
    dosage_per_tablet VARCHAR(15) CHECK (dosage_per_tablet ~ '^[0-9]+(\.[0-9]+)? ?[A-Za-zА-Яа-я]+$'), -- Дозировка на одну таблетку
    tablets_count INT CHECK (tablets_count > 0), -- Количество таблеток в упаковке
    UNIQUE (dosage_per_tablet, tablets_count)
);

-- Таблица: PharmacologicalGroups
-- Содержит информацию о фармакологических группах препаратов
CREATE TABLE PharmacologicalGroups (
    id SERIAL PRIMARY KEY, -- Уникальный идентификатор фармакологической группы
    name VARCHAR(255) CHECK (name ~ '^[A-Za-zА-Яа-я0-9 -]+$') NOT NULL, -- Название фармакологической группы
    UNIQUE (name)
);

-- Таблица: LegalEntities
-- Содержит информацию о юридических лицах, производителях лекарств
CREATE TABLE LegalEntities (
    id SERIAL PRIMARY KEY, -- Уникальный идентификатор юридического лица
    name VARCHAR(255) CHECK (name ~ '^[A-Za-zА-Яа-я0-9 ]+$') NOT NULL, -- Название юридического лица
    country VARCHAR(30) CHECK (country ~ '^[A-Za-zА-Яа-я ]+$') NOT NULL, -- Страна регистрации юридического лица
    UNIQUE (name, country)
);

-- Таблица: Medications
-- Содержит информацию о лекарственных препаратах
CREATE TABLE Medications (
    id SERIAL PRIMARY KEY,
    trade_name VARCHAR(255) CHECK (trade_name ~ '^[A-Za-zА-Яа-я0-9 ]+$'), -- Торговое наименование препарата (идентификатор)
    storage_conditions TEXT, -- Условия хранения препарата
    is_prescription BOOLEAN NOT NULL DEFAULT FALSE, -- Препарат по рецепту
    is_dietary_supplement BOOLEAN NOT NULL DEFAULT TRUE, -- Является ли БАДом
    UNIQUE (trade_name) 
);

-- Таблица: MedicationLegalEntities
-- Связка между лекарственными препаратами и юридическими лицами
CREATE TABLE MedicationLegalEntities (
    medication_id VARCHAR(255) REFERENCES core.Medications(trade_name) ON DELETE CASCADE ON UPDATE CASCADE,
    legal_entity_id INT REFERENCES core.LegalEntities(id) ON DELETE CASCADE ON UPDATE CASCADE,
    PRIMARY KEY (medication_id, legal_entity_id)
);

-- Таблица: MedicationPharmacologicalGroups
-- Связка между лекарственными препаратами и фармакологическими группами
CREATE TABLE MedicationPharmacologicalGroups (
    medication_id VARCHAR(255) REFERENCES core.Medications(trade_name) ON DELETE CASCADE ON UPDATE CASCADE,
    pharmacological_group_id INT REFERENCES core.PharmacologicalGroups(id) ON DELETE CASCADE ON UPDATE CASCADE,
    PRIMARY KEY (medication_id, pharmacological_group_id)
);

-- Таблица: MedicationReleaseForms
-- Содержит информацию о лекарственных препаратах и их формах выпуска
CREATE TABLE MedicationReleaseForms (
    medication_id VARCHAR(255) REFERENCES core.Medications(trade_name) ON DELETE CASCADE,
    release_form_id INT REFERENCES core.ReleaseForms(id) ON DELETE CASCADE,
    PRIMARY KEY (medication_id, release_form_id)
);

-- Таблица: Instructions
-- Содержит текст инструкций для лекарственных препаратов
CREATE TABLE Instructions (
    id SERIAL PRIMARY KEY, -- Уникальный идентификатор инструкции
    medication_trade_name VARCHAR(255) REFERENCES Medications(trade_name) ON DELETE CASCADE ON UPDATE CASCADE, -- Ссылка на торговое наименование препарата
    content TEXT -- Содержимое инструкции
);

-- Таблица: MedicationRestock
-- Содержит информацию о пополнении запаса лекарств
CREATE TABLE MedicationRestock (
    id SERIAL PRIMARY KEY, -- Уникальный идентификатор пополнения
    medication_trade_name VARCHAR(255) REFERENCES Medications(trade_name) ON DELETE CASCADE ON UPDATE CASCADE, -- Ссылка на препарат
    user_email VARCHAR(50) REFERENCES Users(email) ON DELETE CASCADE ON UPDATE CASCADE, -- Ссылка на пользователя
    request_date TIMESTAMP, -- Дата запроса пополнения
    restock_date TIMESTAMP, -- Дата фактического пополнения
    remaining_quantity INT CHECK (remaining_quantity >= 0) -- Остаточное количество препарата
);

-- Таблица: AdministrationMethods
-- Содержит информацию о способах применения лекарств
CREATE TABLE AdministrationMethods (
    id SERIAL PRIMARY KEY, -- Уникальный идентификатор способа применения
    medication_trade_name VARCHAR(255) REFERENCES Medications(trade_name) ON DELETE CASCADE ON UPDATE CASCADE, -- Ссылка на препарат
    single_dosage VARCHAR(255) CHECK (single_dosage ~ '^[0-9]+ ?[A-Za-zА-Яа-я]+$'), -- Разовая дозировка
    interval INT -- Интервал между приёмами
);

-- Таблица: AdministrationTimes
-- Содержит информацию о времени приёма для конкретного способа применения
CREATE TABLE AdministrationTimes (
    id SERIAL PRIMARY KEY, -- Уникальный идентификатор записи
    method_id INT REFERENCES AdministrationMethods(id) ON DELETE CASCADE ON UPDATE CASCADE, -- Ссылка на способ применения
    time TIME NOT NULL -- Время приёма
);

-- Таблица: MedicationSchedules
-- Содержит информацию о графиках приёма лекарств
CREATE TABLE MedicationSchedules (
    id SERIAL PRIMARY KEY, -- Уникальный идентификатор графика приёма
    medication_trade_name VARCHAR(255) REFERENCES Medications(trade_name) ON DELETE CASCADE ON UPDATE CASCADE, -- Ссылка на препарат
    user_email VARCHAR(50) REFERENCES Users(email) ON DELETE CASCADE ON UPDATE CASCADE, -- Ссылка на пользователя
    start_date DATE, -- Дата начала приёма
    end_date DATE, -- Дата окончания приёма
    administration_method_id INT REFERENCES AdministrationMethods(id) ON DELETE CASCADE ON UPDATE CASCADE -- Ссылка на способ применения
);

-- Таблица: MedicationNotifications
-- Содержит информацию об уведомлениях о приёме лекарств
CREATE TABLE MedicationNotifications (
    id SERIAL PRIMARY KEY, -- Уникальный идентификатор уведомления
    schedule_id INT REFERENCES MedicationSchedules(id) ON DELETE CASCADE ON UPDATE CASCADE, -- Ссылка на график приёма
    user_email VARCHAR(50) REFERENCES Users(email) ON DELETE CASCADE ON UPDATE CASCADE, -- Ссылка на пользователя
    related_user_email VARCHAR(50) REFERENCES Users(email) ON DELETE CASCADE ON UPDATE CASCADE, -- Ссылка на связанного пользователя
    sent_at TIMESTAMP, -- Время отправки уведомления
    status VARCHAR(50) CHECK (status ~ '^[A-Za-zА-Яа-я ]+$'), -- Статус уведомления
    actual_taken_at TIMESTAMP -- Фактическое время приёма
);

-- Таблица: PharmacySearchTemplates
-- Содержит шаблоны URL для поиска лекарств в аптеках
CREATE TABLE PharmacySearchTemplates (
    id SERIAL PRIMARY KEY, -- Уникальный идентификатор записи
    pharmacy_name VARCHAR(255) CHECK (pharmacy_name ~ '^[A-Za-zА-Яа-я ]+$'), -- Наименование торговой сети аптек
    search_url_template TEXT -- Шаблон URL для поиска
);
