--DROP DATABASE IF EXISTS MedTrack;

--CREATE DATABASE MedTrack;

--\connect medtrack

CREATE SCHEMA IF NOT EXISTS core;

SET search_path = core;

-- Создание таблиц

-- Таблица: Roles
-- Содержит информацию о ролях пользователей
CREATE TABLE roles (
    id SERIAL PRIMARY KEY, -- Уникальный идентификатор роли
    name VARCHAR(11) NOT NULL CHECK (name ~ '^[A-Za-zА-Яа-я]+$') -- Название роли (только буквы)
);

-- Таблица: users
-- Содержит информацию о пользователях
CREATE TABLE users (
    email VARCHAR(50) PRIMARY KEY CHECK (email ~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$') NOT NULL, -- Электронная почта пользователя (идентификатор)
    last_name VARCHAR(30) CHECK (last_name ~ '^[А-Яа-я]+$') NOT NULL, -- Фамилия пользователя
    first_name VARCHAR(30) CHECK (first_name ~ '^[А-Яа-я]+$') NOT NULL, -- Имя пользователя
    middle_name VARCHAR(30) CHECK (middle_name ~ '^[А-Яа-я]+$'), -- Отчество пользователя
    phone_number VARCHAR(12) CHECK (phone_number ~ '^\+7[0-9]{10}$'), -- Номер телефона пользователя
    password_hash VARCHAR(60) NOT NULL, -- Хэш пароля bcrypt
    role_id INT REFERENCES Roles(id) ON DELETE CASCADE ON UPDATE CASCADE, -- Ссылка на роль пользователя
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE -- Указатель на удаление записи
);

-- Таблица: related_users
-- Содержит информацию о связанных пользователях (например, родственники или опекуны)
CREATE TABLE related_user (
    patient_email VARCHAR(50) REFERENCES users(email) ON DELETE CASCADE ON UPDATE CASCADE, -- Ссылка на пользователя-пациента
    related_email VARCHAR(50) REFERENCES users(email) ON DELETE CASCADE ON UPDATE CASCADE, -- Ссылка на связанного пользователя
    notification_settings JSON, -- Настройки уведомлений
    is_deleted BOOLEAN DEFAULT FALSE, -- Указатель на удаление связи
    PRIMARY KEY (patient_email, related_email) -- Композитный первичный ключ
);

-- Таблица: release_forms
-- Содержит информацию о формах выпуска лекарственных препаратов
CREATE TABLE release_forms (
    id SERIAL PRIMARY KEY, -- Уникальный идентификатор формы выпуска
    dosage_per_tablet VARCHAR(15) CHECK (dosage_per_tablet ~ '^[0-9]+(\.[0-9]+)? ?[A-Za-zА-Яа-я]+$'), -- Дозировка на одну таблетку
    tablets_count INT CHECK (tablets_count > 0), -- Количество таблеток в упаковке
    UNIQUE (dosage_per_tablet, tablets_count)
);

-- Таблица: pharmacological_groups
-- Содержит информацию о фармакологических группах препаратов
CREATE TABLE pharmacological_groups (
    id SERIAL PRIMARY KEY, -- Уникальный идентификатор фармакологической группы
    name VARCHAR(255) CHECK (name ~ '^[A-Za-zА-Яа-я0-9 -]+$') NOT NULL, -- Название фармакологической группы
    UNIQUE (name)
);

-- Таблица: legal_entities
-- Содержит информацию о юридических лицах, производителях лекарств
CREATE TABLE legal_entities (
    id SERIAL PRIMARY KEY, -- Уникальный идентификатор юридического лица
    name VARCHAR(255) CHECK (name ~ '^[A-Za-zА-Яа-я0-9 ]+$') NOT NULL, -- Название юридического лица
    country VARCHAR(30) CHECK (country ~ '^[A-Za-zА-Яа-я ]+$') NOT NULL, -- Страна регистрации юридического лица
    UNIQUE (name, country)
);

-- Таблица: medications
-- Содержит информацию о лекарственных препаратах
CREATE TABLE medications (
    id SERIAL PRIMARY KEY,
    trade_name VARCHAR(255) CHECK (trade_name ~ '^[A-Za-zА-Яа-я0-9 ]+$') NOT NULL, -- Торговое наименование препарата (идентификатор)
    storage_conditions TEXT, -- Условия хранения препарата
    is_prescription BOOLEAN NOT NULL DEFAULT FALSE, -- Препарат по рецепту
    is_dietary_supplement BOOLEAN NOT NULL DEFAULT TRUE, -- Является ли БАДом
    UNIQUE (trade_name) 
);

-- Таблица: medication_legal_entities
-- Связка между лекарственными препаратами и юридическими лицами
CREATE TABLE medication_legal_entities (
    medication_id INT REFERENCES core.medications(id) ON DELETE CASCADE ON UPDATE CASCADE,
    legal_entity_id INT REFERENCES core.legal_entities(id) ON DELETE CASCADE ON UPDATE CASCADE,
    PRIMARY KEY (medication_id, legal_entity_id)
);

-- Таблица: medication_pharmacological_groups
-- Связка между лекарственными препаратами и фармакологическими группами
CREATE TABLE medication_pharmacological_groups (
    medication_id INT REFERENCES core.medications(id) ON DELETE CASCADE ON UPDATE CASCADE,
    pharmacological_group_id INT REFERENCES core.pharmacological_groups(id) ON DELETE CASCADE ON UPDATE CASCADE,
    PRIMARY KEY (medication_id, pharmacological_group_id)
);

-- Таблица: medication_release_forms
-- Содержит информацию о лекарственных препаратах и их формах выпуска
CREATE TABLE medication_release_forms (
    medication_id INT REFERENCES core.medications(id) ON DELETE CASCADE,
    release_form_id INT REFERENCES core.release_forms(id) ON DELETE CASCADE,
    PRIMARY KEY (medication_id, release_form_id)
);

-- Таблица: instructions
-- Содержит текст инструкций для лекарственных препаратов
CREATE TABLE instructions (
    id SERIAL PRIMARY KEY, -- Уникальный идентификатор инструкции
    medication_id INT REFERENCES medications(id) ON DELETE CASCADE ON UPDATE CASCADE, -- Ссылка на торговое наименование препарата
    content TEXT -- Содержимое инструкции
);

-- Таблица: medication_restock
-- Содержит информацию о пополнении запаса лекарств
CREATE TABLE medication_restock (
    id SERIAL PRIMARY KEY, -- Уникальный идентификатор пополнения
    medication_id INT REFERENCES medications(id) ON DELETE CASCADE ON UPDATE CASCADE, -- Ссылка на препарат
    user_email VARCHAR(50) REFERENCES users(email) ON DELETE CASCADE ON UPDATE CASCADE, -- Ссылка на пользователя
    request_date TIMESTAMP, -- Дата запроса пополнения
    restock_date TIMESTAMP, -- Дата фактического пополнения
    remaining_quantity INT CHECK (remaining_quantity >= 0) -- Остаточное количество препарата
);

-- Таблица: administration_methods
-- Содержит информацию о способах применения лекарств
CREATE TABLE administration_methods (
    id SERIAL PRIMARY KEY,
    medication_id INT REFERENCES medications(id) ON DELETE CASCADE ON UPDATE CASCADE,
    single_dosage VARCHAR(255) CHECK (single_dosage ~ '^[0-9]+ ?[A-Za-zА-Яа-я]+$') NOT NULL,
    interval INT NOT NULL,
    administration_times VARCHAR(255) NOT NULL
);

-- Таблица: medication_schedules
-- Содержит информацию о графиках приёма лекарств
CREATE TABLE medication_schedules (
    id SERIAL PRIMARY KEY, -- Уникальный идентификатор графика приёма
    medication_id INT REFERENCES medications(id) ON DELETE CASCADE ON UPDATE CASCADE, -- Ссылка на препарат
    user_email VARCHAR(50) REFERENCES users(email) ON DELETE CASCADE ON UPDATE CASCADE, -- Ссылка на пользователя
    start_date DATE, -- Дата начала приёма
    end_date DATE, -- Дата окончания приёма
    administration_method_id INT REFERENCES administration_methods(id) ON DELETE CASCADE ON UPDATE CASCADE -- Ссылка на способ применения
);

-- Таблица: medication_notifications
-- Содержит информацию об уведомлениях о приёме лекарств
CREATE TABLE medication_notifications (
    id SERIAL PRIMARY KEY, -- Уникальный идентификатор уведомления
    schedule_id INT REFERENCES medication_schedules(id) ON DELETE CASCADE ON UPDATE CASCADE, -- Ссылка на график приёма
    user_email VARCHAR(50) REFERENCES users(email) ON DELETE CASCADE ON UPDATE CASCADE, -- Ссылка на пользователя
    related_user_email VARCHAR(50) REFERENCES users(email) ON DELETE CASCADE ON UPDATE CASCADE, -- Ссылка на связанного пользователя
    sent_at TIMESTAMP, -- Время отправки уведомления
    status VARCHAR(50) CHECK (status ~ '^[A-Za-zА-Яа-я ]+$'), -- Статус уведомления
    actual_taken_at TIMESTAMP -- Фактическое время приёма
);

-- Таблица: pharmacy_search_templates
-- Содержит шаблоны URL для поиска лекарств в аптеках
CREATE TABLE pharmacy_search_templates (
    id SERIAL PRIMARY KEY, -- Уникальный идентификатор записи
    pharmacy_name VARCHAR(255) CHECK (pharmacy_name ~ '^[A-Za-zА-Яа-я ]+$'), -- Наименование торговой сети аптек
    search_url_template TEXT -- Шаблон URL для поиска
);
