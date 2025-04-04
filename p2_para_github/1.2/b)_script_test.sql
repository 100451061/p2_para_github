-- probar el 1.2.a)

SET SERVEROUTPUT ON;

BEGIN
    foundicu.set_current_user('0230880540');
END;
/


-- Ver el usuario actual
BEGIN
    DBMS_OUTPUT.PUT_LINE('Usuario actual: ' || foundicu.get_current_user());
END;
/

-- Probar insertar_prestamo con el usuario actual asignado
BEGIN
    foundicu.insertar_prestamo('AA001');
END;
/

-- AA001
-- AA003
-- AA004
-- AA007
-- AA008
-- AA010
-- AA012
-- AA013
-- AA014
-- AA015

-- ayuda; ver que copias no están prestadas
SELECT signature
FROM copies
WHERE signature NOT IN (SELECT signature
                        FROM loans
                        WHERE user_id = '0230880540')
order by signature;


------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- probar el 1.2.b)
-- encontrar un ISBN válido para probar?
-- Copias disponibles entre el 19 de noviembre y el 3 de diciembre de 2024
SELECT c.signature, c.isbn
FROM copies c
WHERE NOT EXISTS (SELECT 1
                  FROM loans l
                  WHERE l.signature = c.signature
                    AND l.return IS NULL
                    AND l.stopdate BETWEEN DATE '2024-11-19' AND DATE '2024-12-03')
order by c.signature;


-- pruebo
-- ISBN: '84-283-2141-8' (su signature es PD137)
-- Fecha: DATE '2024-11-19'


BEGIN
    foundicu.set_current_user('0230880540');
END;
/

-- insertar reserva con isbn y fecha
BEGIN
    foundicu.insertar_reserva('84-283-2141-8', DATE '2024-11-19');
END;
/


-- verificar
SELECT *
FROM loans
WHERE user_id = '0230880540'
  AND stopdate = DATE '2024-11-19'
  AND type = 'R';

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- probar el 1.2.c)
BEGIN
    foundicu.set_current_user('0230880540');
END;
/

-- Registrar un préstamo real con esa signatura y ese usuario actual (si no lo tiene ya).
BEGIN
    foundicu.insertar_prestamo('NE000'); -- o cualquier otra copia libre
END;
/

--Luego confirma que sigue pendiente:
SELECT *
FROM loans
WHERE user_id = '0230880540'
  AND signature = 'NE000'
  AND return IS NULL;


-- Insertar la devolución
BEGIN
    foundicu.insertar_devolucion('NE000');
END;
/
