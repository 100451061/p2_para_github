-- Prueba 1 – Ver datos de usuario actual
BEGIN
    foundicu.set_current_user('0230880540');
END;
/

-- Ahora podemos ver el contenido de la vista
SELECT *
FROM my_data;

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


-- Paso 1: Establecer el usuario actual
BEGIN
    foundicu.set_current_user('0230880540');
END;
/

-- Paso 2: Ver los préstamos actuales del usuario
SELECT *
FROM my_loans;

-- Paso 3: Insertar un nuevo préstamo si no hay
BEGIN
    foundicu.insertar_prestamo('NE000'); -- Usa una copia libre
END;
/

-- Paso 4: Comprobar que el préstamo está pendiente
SELECT *
FROM my_loans
WHERE signature = 'NE000'
  AND return IS NULL;

-- Paso 5: Insertar o actualizar un post sobre el préstamo
UPDATE my_loans
SET post = 'Un libro muy útil y bien conservado.'
WHERE signature = 'NE000';

-- Paso 6: Verificar que el post se ha registrado
SELECT *
FROM my_loans
WHERE signature = 'NE000';

-- Paso 7: Confirmar directamente en la tabla posts (opcional)
SELECT *
FROM posts
WHERE signature = 'NE000'
  AND user_id = '0230880540';


-- paso 9 - Borrar de my loans (si se quiere) (para limpiar)
DELETE
FROM my_loans
WHERE signature = 'NE000'
  AND return IS NULL;

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
BEGIN
    foundicu.set_current_user('0230880540');
END;

-- no habrá nada, tranquilo
SELECT *
FROM my_reservations;


-- Busco una copia libre en el rango
-- No esta prestada ni reservada ni tiene return pendiente: AA001, AA003, AA004, AA007, AA008, AA010, AA012, AA013
SELECT c.signature, c.isbn
FROM copies c
WHERE NOT EXISTS (SELECT 1
                  FROM loans l
                  WHERE l.signature = c.signature
                    AND l.return IS NULL
                    AND l.stopdate BETWEEN DATE '2024-11-19' AND DATE '2024-12-03');


-- probamos con una copia libre
INSERT INTO my_reservations (signature, stopdate, town, province, time, return)
VALUES ('BA693', DATE '2024-11-19', 'Nava del Viento', 'Guadalajara', 14, NULL);


select *
from my_reservations;

-- por si lo quieres borrar
delete
from my_reservations
where signature = 'BA693';


---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------
-- PRUEBAS DE ERROR CONTROLADO (disparadores en acción)
-------------------------------------------------------------------
-- output: No hay ningún servicio en Nava del Viento (Guadalajara) el día 28/11/2024
INSERT INTO my_reservations (signature, stopdate, town, province, time, return)
VALUES ('AA001', DATE '2024-11-28', 'Nava del Viento', 'Guadalajara', 14, NULL);


-- output:  No hay ninguna copia disponible del ISBN 84-7668-038-4 para las dos semanas desde 19/11/2024
INSERT INTO my_reservations (signature, stopdate, town, province, time, return)
VALUES ('AA001', DATE '2024-11-19', 'Nava del Viento', 'Guadalajara', 14, NULL);


-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- obtener usuarios que tengan servicios en su localidad a partir de una fecha
-- output: 7754777810	Lucas	Buitron	23/11/24	Eriales del Canto Rodao	Lleida
SELECT u.user_id, u.name, u.surname1, s.taskdate, s.town, s.province
FROM users u
         JOIN services s
              ON u.town = s.town AND u.province = s.province
WHERE s.taskdate >= DATE '2024-11-19'
ORDER BY s.taskdate desc;


-- encontrar usuarios con múltiples fechas de servicio en su localidad:
-- output: num_fechas_servicio todos son 1 en la BBDD original
SELECT u.user_id,
       u.name,
       u.surname1,
       u.town,
       u.province,
       COUNT(s.taskdate) AS num_fechas_servicio
FROM users u
         JOIN services s
              ON u.town = s.town
                  AND u.province = s.province
GROUP BY u.user_id, u.name, u.surname1, u.town, u.province
ORDER BY num_fechas_servicio DESC;


-- añado una 2da fecha de servicio por mi mismo en la tabla services:

INSERT INTO services (town, province, bus, taskdate, passport)
VALUES ('Eriales del Canto Rodao', 'Lleida', 'BUS-999', DATE '2024-11-25', 'ESP>>9999999999');

-- antes hago eso

INSERT INTO routes (route_id)
VALUES ('R9999');

INSERT INTO bibuses (plate, last_itv, next_itv)
VALUES ('BUS-999', DATE '2024-01-01', DATE '2025-01-01');


INSERT INTO drivers (passport, email, fullname, birthdate, phone, address, cont_start)
VALUES ('ESP>>9999999999', 'test@email.com', 'Conductor Pruebas', DATE '1990-01-01', 600000000, 'Dirección Prueba', DATE '2023-01-01');


INSERT INTO assign_bus (plate, taskdate, route_id)
VALUES ('BUS-999', DATE '2024-11-25', 'R9999');

INSERT INTO assign_drv (passport, taskdate, route_id)
VALUES ('ESP>>9999999999', DATE '2024-11-25', 'R9999');


INSERT INTO services (town, province, bus, taskdate, passport)
VALUES ('Eriales del Canto Rodao', 'Lleida', 'BUS-999', DATE '2024-11-25', 'ESP>>9999999999');


SELECT c.signature, c.isbn
FROM copies c
WHERE NOT EXISTS (SELECT 1
                  FROM loans l
                  WHERE l.signature = c.signature
                    AND l.return IS NULL
                    AND l.stopdate BETWEEN DATE '2024-11-25' AND DATE '2024-12-09');


INSERT INTO my_reservations (signature, stopdate, town, province, time, return)
VALUES ('VB843', DATE '2024-11-25', 'Eriales del Canto Rodao', 'Lleida', 14, NULL);

SELECT *
FROM my_reservations
WHERE signature = 'VB843';



SELECT town, province, COUNT(*) AS num_fechas
FROM services
GROUP BY town, province
HAVING COUNT(*) >= 2;
