\connect medtrack

SET search_path = core;

INSERT INTO core.pharmacysearchtemplates (id, pharmacy_name, search_url_template)
VALUES 
    (1, 'april', 'https://april.example.com/search?={text}'),
    (2, 'eapteka', 'https://eapteka.example.com/search?={text}');

