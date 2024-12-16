\connect medtrack

SET search_path = core;

INSERT INTO core.pharmacy_search_templates (id, pharmacy_name, search_url_template)
VALUES 
    (1, 'april', 'https://april.example.com/search?={text}'),
    (2, 'eapteka', 'https://eapteka.example.com/search?={text}'),
    (3, 'Планета здоровья', 'https://planetazdorovo.ru/search/?q={text}'),
    (4, 'Аптечество', 'https://kirov.aptechestvo.ru/catalog/?q={text}'),
    (5, 'Вита Экспресс', 'https://vitaexpress.ru/search/?q={text}'),
    (6, 'Бережная Аптека', 'https://b-apteka.ru/search?q={text}'),
    (7, 'Сердце Вятки', 'https://sr.farm/search/index.php?q={text}');

