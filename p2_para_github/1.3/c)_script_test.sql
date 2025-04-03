BEGIN
    foundicu.set_current_user('0230880540');
END;
/

SELECT *
FROM my_data;

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


BEGIN
    foundicu.set_current_user('0230880540');
END;


SELECT *
FROM my_loans;

-- Asegurar de que habia un préstamo real con esa signatura y ese usuario actual (si no lo tiene ya).
BEGIN
    foundicu.insertar_prestamo('NE000'); -- o cualquier otra copia libre
END;
/

UPDATE my_loans
SET post = 'Un libro muy útil y bien conservado.'
WHERE signature = 'NE000';


-- Luego confirma que sigue pendiente:
SELECT *
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
SELECT c.signature, c.isbn
FROM copies c
WHERE NOT EXISTS (SELECT 1
                  FROM loans l
                  WHERE l.signature = c.signature
                    AND l.return IS NULL
                    AND l.stopdate BETWEEN DATE '2024-11-25' AND DATE '2024-12-09');

-- probamos con una copia libre
INSERT INTO my_reservations (signature, stopdate, town, province, time, return)
VALUES ('BA693', DATE '2024-11-19', 'Nava del Viento', 'Guadalajara', 14, NULL);

-- por si lo quieres borrar
delete
from my_reservations
where signature = 'BA693';