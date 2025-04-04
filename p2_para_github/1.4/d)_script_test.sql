--------------------------------------------------------------------------------------------------------------------------------
-- Trigger (c)
-- lo pruebo. 1ro verifico que el usuario exista
SELECT *
FROM users
WHERE user_id = '0230880540';

SELECT *
FROM loans
WHERE user_id = '0230880540';


-- lo borro
DELETE
FROM users
WHERE user_id = '0230880540';

select *
from users_hist; -- los datos del borrado se muestran en users_hist (ha funcionado)

select *
from loans_hist;
-- los datos del borrado se muestran en loans_hist (ha funcionado)


--------------------------------------------------------------------------------------------------------------------------------
-- Trigger (b)
UPDATE copies
SET condition    = 'G',
    deregistered = NULL
WHERE signature = 'UD561';


UPDATE copies
SET condition = 'D'
WHERE signature = 'UD561';

SELECT signature,
       condition,
       TO_CHAR(deregistered, 'DD/MM/YYYY HH24:MI:SS') AS fecha_baja
FROM copies
WHERE condition = 'D';

--------------------------------------------------------------------------------------------------------------------------------
-- Trigger (a)
SELECT user_id, name, type
FROM users
WHERE type = 'L'
  AND ROWNUM = 1;

-- Output: el trigger impedirá el INSERT y lanzará: ERROR: Las bibliotecas no pueden publicar posts.
INSERT INTO posts (signature, user_id, stopdate, post_date, text, likes, dislikes)
VALUES ('OC886', '9994309605', DATE '2024-11-19', SYSDATE, 'Esto es una prueba', 0, 0);


-- buscamos
SELECT user_id, name, type
FROM users
WHERE type = 'L';
-- 'L' = Library

-- [9994309605 ,9994309606,9994309607,9994309608]]

-- Output: el trigger impedirá el INSERT y lanzará: ERROR: Las bibliotecas no pueden publicar posts.
INSERT INTO posts (signature, user_id, stopdate, post_date, text, likes, dislikes)
VALUES ('OC886', '9994309607', DATE '2024-11-19', SYSDATE, 'Post de biblioteca', 0, 0);

-- Output: el trigger impedirá el UPDATE y lanzará: ERROR: Las bibliotecas no pueden modificar posts.
UPDATE posts
SET text = 'Modificado por biblioteca'
WHERE user_id = '9994309605'