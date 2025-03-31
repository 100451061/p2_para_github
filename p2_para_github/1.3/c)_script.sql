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

----------------------------------------------------------------------
-- 0) LIMPIEZA: BORRAR EL PACKAGE (si ya existía)
----------------------------------------------------------------------
DROP PACKAGE foundicu;

----------------------------------------------------------------------
-- 1) ACTIVAR SALIDA DE DBMS_OUTPUT
----------------------------------------------------------------------
SET SERVEROUTPUT ON;

----------------------------------------------------------------------
-- 2) PACKAGE foundicu (SPEC)
----------------------------------------------------------------------
CREATE OR REPLACE PACKAGE foundicu AS
    ----------------------------------------------------------------------------
    -- Variable global para almacenar el usuario de la práctica,
    -- coincidente con la columna users.user_id
    ----------------------------------------------------------------------------
    current_user CHAR(10);

    ----------------------------------------------------------------------------
    -- Para establecer el usuario actual
    ----------------------------------------------------------------------------
    PROCEDURE set_current_user(p_user_id CHAR);

    ----------------------------------------------------------------------------
    -- Procedimientos requeridos por el enunciado
    ----------------------------------------------------------------------------
    PROCEDURE insertar_prestamo(p_signature CHAR);
    PROCEDURE insertar_reserva(p_isbn VARCHAR2, p_reserva_date DATE);
    PROCEDURE registrar_devolucion(p_signature CHAR);

END foundicu;
/

----------------------------------------------------------------------
-- 3) PACKAGE BODY foundicu
----------------------------------------------------------------------
CREATE OR REPLACE PACKAGE BODY foundicu AS
    --------------------------------------------------------------------------
    -- 3.1) Procedimiento para fijar el usuario actual
    --------------------------------------------------------------------------
    PROCEDURE set_current_user(p_user_id CHAR) IS
    BEGIN
        current_user := p_user_id;
        DBMS_OUTPUT.PUT_LINE('Usuario actual establecido en: ' || p_user_id);
    END set_current_user;

    --------------------------------------------------------------------------
    -- 3.2) insertar_prestamo
    --------------------------------------------------------------------------
    PROCEDURE insertar_prestamo(p_signature CHAR) IS
        v_ban_up2        DATE;
        v_reserva_count  NUMBER;
        v_loans_active   NUMBER;
        v_copy_available NUMBER;
    BEGIN
        -----------------------------------------------------------------------
        -- (1) Verificar si current_user existe en la tabla users
        -----------------------------------------------------------------------
        SELECT ban_up2
        INTO v_ban_up2
        FROM users
        WHERE user_id = current_user;

        -----------------------------------------------------------------------
        -- (2) Verificar si el usuario está sancionado (ban_up2 > SYSDATE)
        -----------------------------------------------------------------------
        IF v_ban_up2 IS NOT NULL AND v_ban_up2 > SYSDATE THEN
            DBMS_OUTPUT.PUT_LINE('ERROR: Usuario ' || current_user || ' sancionado hasta ' || v_ban_up2);
            RETURN;
        END IF;

        -----------------------------------------------------------------------
        -- (3) Verificar si hay una reserva para HOY en esa signatura
        -----------------------------------------------------------------------
        SELECT COUNT(*)
        INTO v_reserva_count
        FROM loans
        WHERE signature = p_signature
          AND user_id = current_user
          AND type = 'R' -- 'R' = reserva
          AND return IS NULL
          AND stopdate = TRUNC(SYSDATE);

        IF v_reserva_count > 0 THEN
            -- Convertir la reserva en préstamo (UPDATE type='L')
            UPDATE loans
            SET type = 'L'
            WHERE signature = p_signature
              AND user_id = current_user
              AND type = 'R'
              AND return IS NULL
              AND stopdate = TRUNC(SYSDATE);

            DBMS_OUTPUT.PUT_LINE('Reserva convertida en préstamo para ' || current_user);
            RETURN;
        END IF;

        -----------------------------------------------------------------------
        -- (3b) Si NO hay reserva para hoy, intentar préstamo
        -- Verificamos disponibilidad de la copia (básico: no está en uso)
        -----------------------------------------------------------------------
        SELECT COUNT(*)
        INTO v_copy_available
        FROM copies c
                 LEFT JOIN loans l ON c.signature = l.signature
        WHERE c.signature = p_signature
          AND (l.signature IS NULL OR l.return IS NOT NULL);

        IF v_copy_available = 0 THEN
            DBMS_OUTPUT.PUT_LINE('ERROR: La copia ' || p_signature || ' no está disponible.');
            RETURN;
        END IF;

        -----------------------------------------------------------------------
        -- (4) Verificar que el usuario no supere su límite de préstamos+reservas
        -----------------------------------------------------------------------
        SELECT COUNT(*)
        INTO v_loans_active
        FROM loans
        WHERE user_id = current_user
          AND return IS NULL;
        -- activo

        -- Ejemplo: límite de 5
        IF v_loans_active >= 5 THEN
            DBMS_OUTPUT.PUT_LINE('ERROR: Límite de 5 préstamos/reservas para ' ||
                                 current_user || '.');
            RETURN;
        END IF;

        -----------------------------------------------------------------------
        -- (5) Insertar el préstamo
        --     (town, province, stopdate) deben existir en services
        -----------------------------------------------------------------------
        INSERT INTO loans (signature, user_id, stopdate, town, province, type, time, return)
        VALUES (p_signature,
                current_user,
                DATE '2025-05-10', -- Ajusta a la fecha que uses en services
                'TestTown', -- Ajusta al municipio que creaste
                'TestProv',
                'L', -- 'L' = préstamo
                14, -- 14 días
                NULL);

        DBMS_OUTPUT.PUT_LINE('Préstamo insertado: copia ' || p_signature || ' para usuario ' || current_user || '.');

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('ERROR: El usuario ' || current_user || ' no existe en tabla users o la copia no se halló.');
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('ERROR en insertar_prestamo: ' || SQLERRM);
    END insertar_prestamo;

    --------------------------------------------------------------------------
    -- 3.3) insertar_reserva
    --------------------------------------------------------------------------
    PROCEDURE insertar_reserva(p_isbn VARCHAR2, p_reserva_date DATE) IS
        v_ban_up2      DATE;
        v_loans_active NUMBER;
        v_signature    copies.signature%TYPE;
    BEGIN
        -----------------------------------------------------------------------
        -- (1) Verificar usuario actual en tabla users
        -----------------------------------------------------------------------
        SELECT ban_up2
        INTO v_ban_up2
        FROM users
        WHERE user_id = current_user;

        -----------------------------------------------------------------------
        -- (2) Verificar sanción
        -----------------------------------------------------------------------
        IF v_ban_up2 IS NOT NULL AND v_ban_up2 > SYSDATE THEN
            DBMS_OUTPUT.PUT_LINE('ERROR: Usuario ' || current_user || ' sancionado hasta ' || v_ban_up2);
            RETURN;
        END IF;

        -----------------------------------------------------------------------
        -- (3) Verificar límite
        -----------------------------------------------------------------------
        SELECT COUNT(*)
        INTO v_loans_active
        FROM loans
        WHERE user_id = current_user
          AND return IS NULL;

        IF v_loans_active >= 5 THEN
            DBMS_OUTPUT.PUT_LINE('ERROR: Límite activo de 5 préstamos/reservas para ' || current_user);
            RETURN;
        END IF;

        -----------------------------------------------------------------------
        -- (4) Buscar una copia libre de ese ISBN para [p_reserva_date, p_reserva_date+14]
        -----------------------------------------------------------------------
        SELECT c.signature
        INTO v_signature
        FROM copies c
        WHERE c.isbn = p_isbn
          AND NOT EXISTS (SELECT 1
                          FROM loans l
                          WHERE l.signature = c.signature
                            AND l.return IS NULL
                            AND l.stopdate BETWEEN p_reserva_date AND (p_reserva_date + 14))
          AND ROWNUM = 1;

        -----------------------------------------------------------------------
        -- (5) Insertar reserva (town,province,stopdate) -> services
        -----------------------------------------------------------------------
        INSERT INTO loans(signature, user_id, stopdate, town, province, type, time, return)
        VALUES (v_signature,
                current_user,
                p_reserva_date,
                'TestTown', -- Debe existir en services
                'TestProv',
                'R', -- 'R' = reserva
                0,
                NULL);

        DBMS_OUTPUT.PUT_LINE('Reserva creada: copia ' || v_signature || ' para usuario ' || current_user);

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('ERROR: No hay copia disponible para ISBN=' || p_isbn || ' o usuario ' || current_user || ' no existe.');
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('ERROR en insertar_reserva: ' || SQLERRM);
    END insertar_reserva;

    --------------------------------------------------------------------------
    -- 3.4) registrar_devolucion
    --------------------------------------------------------------------------
    PROCEDURE registrar_devolucion(p_signature CHAR) IS
        v_count NUMBER;
    BEGIN
        -----------------------------------------------------------------------
        -- (1) Verificar si hay un préstamo activo (type='L') para current_user
        -----------------------------------------------------------------------
        SELECT COUNT(*)
        INTO v_count
        FROM loans
        WHERE signature = p_signature
          AND user_id = current_user
          AND type = 'L'
          AND return IS NULL;

        IF v_count = 0 THEN
            DBMS_OUTPUT.PUT_LINE('ERROR: El usuario ' || current_user || ' no tiene un préstamo activo para ' || p_signature);
            RETURN;
        END IF;

        -----------------------------------------------------------------------
        -- (2) Registrar devolución (return=SYSDATE)
        -----------------------------------------------------------------------
        UPDATE loans
        SET return = SYSDATE
        WHERE signature = p_signature
          AND user_id = current_user
          AND type = 'L'
          AND return IS NULL;

        DBMS_OUTPUT.PUT_LINE('Devolución registrada para ' || current_user || ' y la copia ' || p_signature);

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('ERROR: No se encontró la copia ' || p_signature || ' o el usuario ' || current_user || ' en loans.');
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('ERROR en registrar_devolucion: ' || SQLERRM);
    END registrar_devolucion;

END foundicu;
/



-- apartado a)
--Usuario actual es gestionado por la variable de package foundicu.current_user.
--Para crear la vista, te apoyas en una función (my_current_user()) que nos devuelve el usuario actual.
--Resultado: una vista que solo muestra los datos de "ese" usuario y deniega modificaciones

drop function my_current_user;
drop view my_data;

-- me aseguro de que el usuario actual sea U000000001.
BEGIN
    foundicu.set_current_user('U000000001');
END;
/

-- comprueba el usuario actual
SELECT my_current_user()
FROM dual;

-- hacemos una función que nos devuelve el usuario actual
CREATE OR REPLACE FUNCTION my_current_user
    RETURN CHAR
    IS
BEGIN
    RETURN foundicu.current_user;
END;
/


-- creamos la vista my_data que solo muestra los datos de "ese" usuario
CREATE OR REPLACE VIEW my_data AS
SELECT user_id,
       id_card,
       name,
       surname1,
       surname2,
       birthdate,
       town,
       province,
       address,
       email,
       phone,
       type,
       ban_up2
FROM users
WHERE user_id = my_current_user()
WITH READ ONLY;

-- comprobamos la vista
select *
from my_data;