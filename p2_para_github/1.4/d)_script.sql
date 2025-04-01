-- -------------------------------------------
-- - Creation Script -- FSDB Assignment 2025 -
-- -------------------------------------------
-- -------------------------------------------

-- DESTROY ALL TABLES
-- ------------------
DROP TABLE posts;
DROP TABLE loans;
DROP TABLE users;
DROP TABLE services;
DROP TABLE stops;
DROP TABLE assign_bus;
DROP TABLE assign_drv;
DROP TABLE bibuses;
DROP TABLE drivers;
DROP TABLE routes;
DROP TABLE municipalities;
DROP TABLE copies;
DROP TABLE editions;
DROP TABLE more_authors;
DROP TABLE books;

-- CREATE ALL TABLES
-- -----------------

CREATE TABLE books
(
    TITLE     VARCHAR2(200),
    AUTHOR    VARCHAR2(100),
    COUNTRY   VARCHAR2(50),
    LANGUAGE  VARCHAR2(50),
    PUB_DATE  NUMBER(4),
    ALT_TITLE VARCHAR2(200),
    TOPIC     VARCHAR2(200),
    CONTENT   VARCHAR2(2500),
    AWARDS    VARCHAR2(200),

    CONSTRAINT pk_books PRIMARY KEY (title, author)
);

--

CREATE TABLE More_Authors
(
    TITLE       VARCHAR2(200),
    MAIN_AUTHOR VARCHAR2(100),
    ALT_AUTHORS VARCHAR2(200),
    MENTIONS    VARCHAR2(200),

    CONSTRAINT pk_more_authors PRIMARY KEY (title, main_author, alt_authors),

    CONSTRAINT fk_more_authors_books FOREIGN KEY (title, main_author) REFERENCES books (title, author)
);

--

CREATE TABLE Editions
(
    ISBN            VARCHAR2(20),
    TITLE           VARCHAR2(200)                    NOT NULL,
    AUTHOR          VARCHAR2(100)                    NOT NULL,
    LANGUAGE        VARCHAR2(50) default ('Spanish') NOT NULL,
    ALT_LANGUAGES   VARCHAR2(50),
    EDITION         VARCHAR2(50),
    PUBLISHER       VARCHAR2(100),
    EXTENSION       VARCHAR2(50),
    SERIES          VARCHAR2(50),
    COPYRIGHT       VARCHAR2(20),
    PUB_PLACE       VARCHAR2(50),
    DIMENSIONS      VARCHAR2(50),
    PHY_FEATURES    VARCHAR2(200),
    MATERIALS       VARCHAR2(200),
    NOTES           VARCHAR2(500),
    NATIONAL_LIB_ID VARCHAR2(20)                     NOT NULL,
    URL             VARCHAR2(200),

    CONSTRAINT pk_editions PRIMARY KEY (isbn),

    CONSTRAINT uk_editions UNIQUE (national_lib_id),

    CONSTRAINT fk_editions_books FOREIGN KEY (title, author) REFERENCES books (title, author)
);

--

CREATE TABLE Copies
(
    SIGNATURE    CHAR(5),
    ISBN         VARCHAR2(20)          NOT NULL,
    CONDITION    CHAR(1) default ('G') NOT NULL,
    COMMENTS     VARCHAR2(20),
    DEREGISTERED DATE,

    CONSTRAINT pk_copies PRIMARY KEY (signature),

    CONSTRAINT ck_condition CHECK (condition in ('N', 'G', 'W', 'V', 'D') ),

    CONSTRAINT fk_copies_editions FOREIGN KEY (isbn) REFERENCES editions (isbn)
);

--

CREATE TABLE municipalities
(
    TOWN       VARCHAR2(50),
    PROVINCE   VARCHAR2(22),
    POPULATION NUMBER(5) NOT NULL,

    CONSTRAINT pk_municipalities PRIMARY KEY (town, province)
);

--

CREATE TABLE routes
(
    ROUTE_ID CHAR(5),

    CONSTRAINT pk_routes PRIMARY KEY (route_id)
);

--

CREATE TABLE drivers
(
    PASSPORT   CHAR(17),
    EMAIL      VARCHAR2(100) NOT NULL,
    FULLNAME   VARCHAR2(80)  NOT NULL,
    BIRTHDATE  DATE          NOT NULL,
    PHONE      NUMBER(9)     NOT NULL,
    ADDRESS    VARCHAR2(100) NOT NULL,
    CONT_START DATE          NOT NULL,
    CONT_END   DATE,

    CONSTRAINT pk_drivers PRIMARY KEY (passport),

    CONSTRAINT ck_drv_phone CHECK (phone > 99999999),
    CONSTRAINT ck_drv_dates CHECK (cont_end is null or cont_start < cont_end)
);

--

CREATE TABLE bibuses
(
    PLATE    CHAR(8),
    LAST_ITV DATE NOT NULL,
    NEXT_ITV DATE NOT NULL,

    CONSTRAINT pk_bibuses PRIMARY KEY (plate),

    CONSTRAINT ck_bus_dates CHECK (last_itv < next_itv)
);

--

CREATE TABLE assign_drv
(
    PASSPORT CHAR(17),
    TASKDATE DATE,
    ROUTE_ID CHAR(5),

    CONSTRAINT pk_assign_drv PRIMARY KEY (passport, taskdate),

    CONSTRAINT fk_assign_drv_drivers FOREIGN KEY (passport) REFERENCES drivers (passport) ON DELETE CASCADE,
    CONSTRAINT fk_assign_drv_routes FOREIGN KEY (route_id) REFERENCES routes (route_id) ON DELETE CASCADE
);

--

CREATE TABLE assign_bus
(
    PLATE    CHAR(8),
    TASKDATE DATE,
    ROUTE_ID CHAR(5) NOT NULL,

    CONSTRAINT pk_assign_bus PRIMARY KEY (plate, taskdate),

    CONSTRAINT uk_assign_bus UNIQUE (taskdate, route_id),

    CONSTRAINT fk_assign_bus_bibuses FOREIGN KEY (plate) REFERENCES bibuses (plate) ON DELETE CASCADE,
    CONSTRAINT fk_assign_bus_route_id FOREIGN KEY (route_id) REFERENCES routes (route_id) ON DELETE CASCADE
);

--

CREATE TABLE stops
(
    TOWN     VARCHAR2(50),
    PROVINCE VARCHAR2(22),
    ADDRESS  VARCHAR2(100) NOT NULL,
    ROUTE_ID CHAR(5)       NOT NULL,
    STOPTIME NUMBER(4)     NOT NULL,

    CONSTRAINT pk_stops PRIMARY KEY (town, province),

    CONSTRAINT fk_stops_municipalities FOREIGN KEY (town, province) REFERENCES municipalities (town, province) ON DELETE CASCADE,
    CONSTRAINT fk_stops_routes FOREIGN KEY (route_id) REFERENCES routes (route_id)
);

--

CREATE TABLE services
(
    TOWN     VARCHAR2(50),
    PROVINCE VARCHAR2(22),
    BUS      CHAR(8)  NOT NULL,
    TASKDATE DATE,
    PASSPORT CHAR(17) NOT NULL,

    CONSTRAINT pk_services PRIMARY KEY (town, province, taskdate),

    CONSTRAINT fk_services_stops FOREIGN KEY (town, province) REFERENCES stops (town, province) ON DELETE CASCADE,
    CONSTRAINT fk_services_asgn_bus FOREIGN KEY (bus, taskdate) REFERENCES assign_bus (plate, taskdate),
    CONSTRAINT fk_services_asgn_drv FOREIGN KEY (passport, taskdate) REFERENCES assign_drv (passport, taskdate)
);

--

CREATE TABLE users
(
    USER_ID   CHAR(10),
    ID_CARD   CHAR(17)      NOT NULL,
    NAME      VARCHAR2(80)  NOT NULL,
    SURNAME1  VARCHAR2(80)  NOT NULL,
    SURNAME2  VARCHAR2(80),
    BIRTHDATE DATE          NOT NULL,
    TOWN      VARCHAR2(50)  NOT NULL,
    PROVINCE  VARCHAR2(22)  NOT NULL,
    ADDRESS   VARCHAR2(150) NOT NULL,
    EMAIL     VARCHAR2(100),
    PHONE     NUMBER(9)     NOT NULL,
    TYPE      CHAR(1)       NOT NULL,
    BAN_UP2   DATE,

    CONSTRAINT pk_users PRIMARY KEY (user_id),

    CONSTRAINT ck_usr_phone CHECK (phone > 99999999),

    CONSTRAINT fk_users_municipalities FOREIGN KEY (town, province) REFERENCES municipalities (town, province)
);

--

CREATE TABLE loans
(
    SIGNATURE CHAR(5),
    USER_ID   CHAR(10),
    STOPDATE  DATE,
    TOWN      VARCHAR2(50)          NOT NULL,
    PROVINCE  VARCHAR2(22)          NOT NULL,
    TYPE      CHAR(1)               NOT NULL,
    TIME      NUMBER(5) default (0) NOT NULL,
    RETURN    DATE,

    CONSTRAINT pk_loans PRIMARY KEY (signature, user_id, stopdate),

    CONSTRAINT ck_loans_dates CHECK (return is null or return > stopdate),

    CONSTRAINT fk_loans_users FOREIGN KEY (user_id) REFERENCES users (user_id),
    CONSTRAINT fk_loans_copies FOREIGN KEY (signature) REFERENCES copies (signature),
    CONSTRAINT fk_loans_services FOREIGN KEY (town, province, stopdate) REFERENCES services (town, province, taskdate)
);

--

CREATE TABLE posts
(
    SIGNATURE CHAR(5),
    USER_ID   CHAR(10),
    STOPDATE  DATE,
    POST_DATE DATE                  NOT NULL,
    TEXT      VARCHAR2(2000)        NOT NULL,
    LIKES     NUMBER(7) default (0) NOT NULL,
    DISLIKES  NUMBER(7) default (0) NOT NULL,

    CONSTRAINT pk_posts PRIMARY KEY (signature, user_id, stopdate),

    CONSTRAINT ck_posts_dates CHECK (stopdate < post_date),

    CONSTRAINT fk_posts_loans FOREIGN KEY (signature, user_id, stopdate) REFERENCES loans (signature, user_id, stopdate) ON DELETE CASCADE
);


--  (1) Evitar los "posts" de usuarios institucionales (bibliotecas municipales)
CREATE OR REPLACE TRIGGER trg_no_post_institucional
    BEFORE INSERT
    ON posts
    FOR EACH ROW
DECLARE
    v_type users.type%TYPE;
BEGIN
    SELECT type
    INTO v_type
    FROM users
    WHERE user_id = :NEW.user_id;

    IF v_type = 'I' THEN
        RAISE_APPLICATION_ERROR(-20010, 'Los usuarios institucionales no pueden crear posts.');
    END IF;
END;
/


-- (2) Establecer automáticamente la "fecha de baja" si el estado de una copia es "deteriorado"
CREATE OR REPLACE TRIGGER trg_drop_date_deteriorado
    BEFORE INSERT OR UPDATE
    ON copies
    FOR EACH ROW
BEGIN
    IF :NEW.status = 'deteriorado' THEN
        :NEW.drop_date := SYSDATE;
    END IF;
END;
/


-- (3) Crear "tablas de históricos" tanto para usuarios como para préstamos (no vistas,
-- sino otras dos tablas idénticas). Cuando se elimina un usuario, crear un registro
-- histórico de ese usuario y mover todos sus préstamos al histórico de préstamos.


-----------------------------
-- 0. LIMPIEZA (si ya existen)
-----------------------------
SET SERVEROUTPUT ON;

BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE loans_historico';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE users_historico';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP TRIGGER trg_users_to_historico';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

-----------------------------
-- 1. CREAR TABLAS DE HISTÓRICO
-----------------------------
CREATE TABLE users_historico AS
SELECT *
FROM users
WHERE 1 = 0; --WHERE 1 = 0 nunca se cumple, por lo tanto, no copia datos, solo copia la estructura de la tabla.

CREATE TABLE loans_historico AS
SELECT *
FROM loans
WHERE 1 = 0;

-----------------------------
-- 2. INSERTAR DATOS DE PRUEBA (opcional)
-----------------------------
-- Asegúrate de que exista esta copia:
INSERT INTO copies(signature, isbn)
VALUES ('S999', '978-0-13-110362-7');

-- Usuario de prueba
INSERT INTO users(user_id, id_card, name, surname1, surname2, birthdate, town, province, address, phone, email, type, ban_up2)
VALUES ('U000DELETE', 'DNI123456', 'Usuario', 'A', 'B', DATE '2000-01-01', 'TestTown', 'TestProv', 'Calle falsa 123', 123456789, 'correo@prueba.com', 'P', NULL);

-- 1. Asegúrate de tener un conductor
INSERT INTO drivers (passport, email, fullname, birthdate, phone, address, cont_start)
VALUES ('PASS9999999', 'demo@uc3m.es', 'Demo Driver', DATE '1970-01-01', 123456789, 'Demo Address', DATE '2020-01-01');
COMMIT;

-- 2. Asegúrate de tener un bibús
INSERT INTO bibuses (plate, last_itv, next_itv)
VALUES ('PLATE999', DATE '2020-01-01', DATE '2026-01-01');
COMMIT;

-- 3. Insertar entrada en SERVICES con los mismos town, province y fecha
INSERT INTO services (town, province, bus, taskdate, passport)
VALUES ('TestTown', 'TestProv', TRIM('PLATE999'), TRUNC(SYSDATE), 'PASS9999999');
COMMIT;


-- Préstamo de prueba
INSERT INTO loans(signature, user_id, stopdate, town, province, type, time, return)
VALUES ('S999', 'U000DELETE', SYSDATE, 'TestTown', 'TestProv', 'L', 14, NULL);

COMMIT;

-----------------------------
-- 3. CREAR TRIGGER
-----------------------------
CREATE OR REPLACE TRIGGER trg_users_to_historico
    BEFORE DELETE
    ON users
    FOR EACH ROW
BEGIN
    -- 1. Copiar usuario eliminado al histórico
    INSERT INTO users_historico
    VALUES (:OLD.user_id, :OLD.id_card, :OLD.name, :OLD.surname1, :OLD.surname2,
            :OLD.birthdate, :OLD.town, :OLD.province, :OLD.address,
            :OLD.phone, :OLD.email, :OLD.type, :OLD.ban_up2);

    -- 2. Copiar sus préstamos al histórico
    INSERT INTO loans_historico
    SELECT *
    FROM loans
    WHERE user_id = :OLD.user_id;

    -- 3. Eliminar préstamos originales (por FK)
    DELETE
    FROM loans
    WHERE user_id = :OLD.user_id;
END;
/

-----------------------------
-- 4. PRUEBA FINAL
-----------------------------
-- Ejecuta este DELETE:
DELETE
FROM users
WHERE user_id = 'U000DELETE';
COMMIT;

-- Verifica que se movió todo:
SELECT *
FROM users_historico
WHERE user_id = 'U000DELETE';
SELECT *
FROM loans_historico
WHERE user_id = 'U000DELETE';


-- (4) Contar lecturas al prestar un libro
ALTER TABLE books
    ADD lecturas NUMBER DEFAULT 0;

CREATE OR REPLACE TRIGGER trg_sumar_lectura
    AFTER INSERT
    ON loans
    FOR EACH ROW
DECLARE
    v_isbn editions.isbn%TYPE;
BEGIN
    IF :NEW.type = 'L' THEN
        SELECT isbn
        INTO v_isbn
        FROM copies
        WHERE signature = :NEW.signature;

        UPDATE books
        SET lecturas = lecturas + 1
        WHERE (title, author) IN (SELECT title, author
                                  FROM editions
                                  WHERE isbn = v_isbn);
    END IF;
END;
/
