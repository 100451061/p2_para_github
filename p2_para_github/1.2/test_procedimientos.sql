SET SERVEROUTPUT ON;

-- Inserción de datos de prueba
INSERT INTO users (USER_ID, ID_CARD, NAME, SURNAME1, BIRTHDATE, TOWN, PROVINCE, ADDRESS, PHONE, TYPE)
VALUES ('USER001', '12345678A', 'Juan', 'Perez', TO_DATE('1990-01-01', 'YYYY-MM-DD'), 'Madrid', 'Madrid', 'Calle Mayor 1', 123456789, 'A');

INSERT INTO editions (ISBN, TITLE, AUTHOR, NATIONAL_LIB_ID)
VALUES ('ISBN123', 'Libro de Prueba', 'Autor de Prueba', 'NLID001');

INSERT INTO copies (SIGNATURE, ISBN) VALUES ('SIG01', 'ISBN123');
INSERT INTO copies (SIGNATURE, ISBN) VALUES ('SIG02', 'ISBN123');

INSERT INTO loans (SIGNATURE, USER_ID, STOPDATE, TOWN, PROVINCE, TYPE, TIME)
VALUES ('SIG02', 'USER001', SYSDATE - 7, 'Madrid', 'Madrid', 'A', 14);

COMMIT;

-- Pruebas de insertar_prestamo
-- Prueba con Reserva
INSERT INTO loans (SIGNATURE, USER_ID, STOPDATE, TOWN, PROVINCE, TYPE, TIME)
VALUES ('SIG01', 'USER001', TRUNC(SYSDATE), 'Madrid', 'Madrid', 'A', 0);
COMMIT;
EXEC foundicu.insertar_prestamo('SIG01');
SELECT RETURN from loans where SIGNATURE = 'SIG01';
DELETE from LOANS where SIGNATURE = 'SIG01';
COMMIT;

-- Prueba sin Reserva (préstamo directo)
EXEC foundicu.insertar_prestamo('SIG01');
SELECT * from loans where SIGNATURE = 'SIG01' AND USER_ID = 'USER001';
DELETE from LOANS where SIGNATURE = 'SIG01';
COMMIT;

-- Prueba con Copia No Disponible
INSERT INTO loans (SIGNATURE, USER_ID, STOPDATE, TOWN, PROVINCE, TYPE, TIME)
VALUES ('SIG01', 'USER002', TRUNC(SYSDATE), 'Madrid', 'Madrid', 'A', 14);
COMMIT;
EXEC foundicu.insertar_prestamo('SIG01');
DELETE FROM loans WHERE SIGNATURE = 'SIG01' and USER_ID = 'USER002';
commit;

-- Prueba con Límite de Préstamos
INSERT INTO loans (SIGNATURE, USER_ID, STOPDATE, TOWN, PROVINCE, TYPE, TIME)
VALUES ('SIG01', 'USER001', SYSDATE - 1, 'Madrid', 'Madrid', 'A', 14);
INSERT INTO loans (SIGNATURE, USER_ID, STOPDATE, TOWN, PROVINCE, TYPE, TIME)
VALUES ('SIG02', 'USER001', SYSDATE - 2, 'Madrid', 'Madrid', 'A', 14);
INSERT INTO loans (SIGNATURE, USER_ID, STOPDATE, TOWN, PROVINCE, TYPE, TIME)
VALUES ('SIG03', 'USER001', SYSDATE - 3, 'Madrid', 'Madrid', 'A', 14);
INSERT INTO loans (SIGNATURE, USER_ID, STOPDATE, TOWN, PROVINCE, TYPE, TIME)
VALUES ('SIG04', 'USER001', SYSDATE - 4, 'Madrid', 'Madrid', 'A', 14);
INSERT INTO loans (SIGNATURE, USER_ID, STOPDATE, TOWN, PROVINCE, TYPE, TIME)
VALUES ('SIG05', 'USER001', SYSDATE - 5, 'Madrid', 'Madrid', 'A', 14);
commit;

EXEC foundicu.insertar_prestamo('SIG01');
delete from loans where USER_ID = 'USER001' and SIGNATURE in ('SIG01','SIG02', 'SIG03','SIG04','SIG05');
commit;

-- Pruebas de insertar_reserva
-- Prueba de Reserva Exitosa
EXEC foundicu.insertar_reserva('ISBN123', SYSDATE + 7);
SELECT * from loans where USER_ID = 'USER001' AND SIGNATURE = 'SIG01';
delete from loans where USER_ID = 'USER001' AND SIGNATURE = 'SIG01';
commit;

-- Prueba con Copia No Disponible
INSERT into loans (SIGNATURE, USER_ID, STOPDATE, TOWN, PROVINCE, TYPE, TIME)
VALUES ('SIG01', 'USER002', TRUNC(SYSDATE + 7), 'Madrid', 'Madrid', 'A', 14);
commit;
EXEC foundicu.insertar_reserva('ISBN123', SYSDATE + 7);
delete from loans where USER_ID = 'USER002' and SIGNATURE = 'SIG01';
commit;

-- Pruebas de registrar_devolucion
-- Prueba de Devolución Exitosa
EXEC foundicu.registrar_devolucion('SIG02');
SELECT RETURN from loans where SIGNATURE = 'SIG02';
update loans set RETURN = NULL where SIGNATURE = 'SIG02';
commit;

-- Prueba con Libro No Prestado
EXEC foundicu.registrar_devolucion('SIG01');

-- Limpieza de datos de prueba
DELETE FROM loans WHERE USER_ID IN ('USER001', 'USER002');
DELETE FROM copies WHERE SIGNATURE IN ('SIG01', 'SIG02');
DELETE FROM editions WHERE ISBN = 'ISBN123';
DELETE FROM users WHERE USER_ID IN ('USER001','USER002');

COMMIT;