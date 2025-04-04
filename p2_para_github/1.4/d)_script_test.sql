-- (a) Evitar posts de bibliotecas (tipo = 'L')

-- 1. Busca usuarios institucionales (bibliotecas)
SELECT user_id, name, type
FROM users
WHERE type = 'L';

-- 2. Intenta insertar un post (debe lanzar error)
INSERT INTO posts (signature, user_id, stopdate, post_date, text, likes, dislikes)
VALUES ('OC886', '9994309605', DATE '2024-11-19', SYSDATE, 'Esto es una prueba', 0, 0);

-- 3. Intenta modificar un post de biblioteca (también fallará)

-- busco primero un ejemplo real
SELECT p.signature, p.user_id, u.name, u.type, p.text
FROM posts p
         JOIN users u ON p.user_id = u.user_id
WHERE u.type = 'L';

UPDATE posts
SET text = 'Modificado por biblioteca'
WHERE signature = 'LG575'
  AND user_id = '9994309602';



----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
-- (b) Deterioro activa fecha de baja

-- 1. Resetea el estado de una copia:
UPDATE copies
SET condition    = 'G', -- good
    deregistered = NULL
WHERE signature = 'UD561';

--  Verifica el estado:
select *
from copies
WHERE signature = 'UD561';


-- 2. Cambia el estado a 'D' (deteriorado) y activa el trigger:
UPDATE copies
SET condition = 'D'
WHERE signature = 'UD561';


-- 3. Verifica que la fecha de baja (deregistered) se ha asignado con hora:
SELECT signature,
       isbn,
       condition,
       comments,
       TO_CHAR(deregistered, 'DD/MM/YYYY HH24:MI:SS') AS fecha_baja_con_hora
FROM copies
WHERE signature = 'UD561';
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
-- (c) Históricos al eliminar usuario

-- Buscar una biblio existente
SELECT user_id, name, surname1
FROM users
WHERE type = 'L';


-- 1. Verifica que el usuario existe y tiene préstamos:
SELECT *
FROM users
WHERE user_id = '9994309600'; -- por ejemplo

SELECT *
FROM loans
WHERE user_id = '9994309600';

-- 2. Elimina el usuario (activará el trigger trg_before_delete_users):
DELETE
FROM users
WHERE user_id = '9994309600';

-- 3. Comprueba que se han movido a históricos:
SELECT *
FROM users_hist
WHERE user_id = '9994309600';

SELECT *
FROM loans_hist
WHERE user_id = '9994309600';
