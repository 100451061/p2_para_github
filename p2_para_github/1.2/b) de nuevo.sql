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
    CONSTRAINT fk_copies_editions FOREIGN KEY (isbn) REFERENCES editions (isbn),
    CONSTRAINT ck_condition CHECK (condition in ('N', 'G', 'W', 'V', 'D') )
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
    CONSTRAINT fk_stops_municipalities FOREIGN KEY (town, province)
        REFERENCES municipalities (town, province) ON DELETE CASCADE,
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
    CONSTRAINT fk_users_municipalities FOREIGN KEY (town, province)
        REFERENCES municipalities (town, province),
    CONSTRAINT ck_usr_phone CHECK (phone > 99999999)
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
    CONSTRAINT fk_loans_users FOREIGN KEY (user_id) REFERENCES users (user_id),
    CONSTRAINT fk_loans_copies FOREIGN KEY (signature) REFERENCES copies (signature),
    CONSTRAINT fk_loans_services FOREIGN KEY (town, province, stopdate)
        REFERENCES services (town, province, taskdate),
    CONSTRAINT ck_loans_dates CHECK (return is null or return > stopdate)
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
    CONSTRAINT fk_posts_loans FOREIGN KEY (signature, user_id, stopdate)
        REFERENCES loans (signature, user_id, stopdate) ON DELETE CASCADE,
    CONSTRAINT ck_posts_dates CHECK (stopdate < post_date)
);


--  El 1er procedimiento comprueba:
--
-- Que el usuario existe y no está sancionado.
--
-- Que hay o no hay una reserva para hoy.
--
-- Que la copia está disponible.
--
-- Que no se excede el límite de 5 préstamos.
--
-- Que hay un servicio válido (services) para stopdate.

-------------------------------------------------------------------------
-- El 2do procedimiento inserta un préstamo en la tabla loans.
-------------------------------------------------------------------------

CREATE OR REPLACE PACKAGE foundicu AS
    g_user_id CHAR(10);

    PROCEDURE set_current_user(p_user_id CHAR);
    FUNCTION get_current_user RETURN CHAR;
    PROCEDURE insertar_prestamo(p_signature CHAR);
    PROCEDURE insertar_reserva(p_isbn VARCHAR2, p_fecha DATE);
END foundicu;
/



CREATE OR REPLACE PACKAGE BODY foundicu AS

    PROCEDURE set_current_user(p_user_id CHAR) IS
        v_name    users.name%TYPE;
        v_surname users.surname1%TYPE;
    BEGIN
        g_user_id := p_user_id;

        -- Obtener nombre y apellido
        SELECT name, surname1
        INTO v_name, v_surname
        FROM users
        WHERE user_id = g_user_id;

        -- Mostrar usuario completo
        DBMS_OUTPUT.PUT_LINE('Set Usuario actual --> ' || g_user_id || ' (' || v_name || ' ' || v_surname || ')');

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('Usuario ' || p_user_id || ' no encontrado en la tabla users.');
    END set_current_user;


    FUNCTION get_current_user RETURN CHAR IS
    BEGIN
        RETURN g_user_id;
    END get_current_user;


    PROCEDURE insertar_prestamo(p_signature CHAR) IS
        v_name           users.name%TYPE;
        v_surname        users.surname1%TYPE;
        v_ban_up2        DATE;
        v_reserva_count  NUMBER;
        v_loans_active   NUMBER;
        v_copy_available NUMBER;
        v_stopdate       DATE;
        v_town           VARCHAR2(50);
        v_province       VARCHAR2(22);
        v_tipo_existente CHAR(1);
        v_dummy          NUMBER;
    BEGIN
        -----------------------------------------------------------------------
        -- (0) Verificar que la copia existe
        -----------------------------------------------------------------------
        BEGIN
            SELECT 1
            INTO v_dummy
            FROM copies
            WHERE signature = p_signature;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                DBMS_OUTPUT.PUT_LINE('ERROR: La copia ' || p_signature || ' no existe.');
                RETURN;
        END;

        -----------------------------------------------------------------------
        -- (1) Verificar si el usuario existe y obtener datos de localidad
        -----------------------------------------------------------------------
        SELECT ban_up2, town, province, name, surname1
        INTO v_ban_up2, v_town, v_province, v_name, v_surname
        FROM users
        WHERE user_id = g_user_id;

        -----------------------------------------------------------------------
        -- (2) Verificar sanción
        -----------------------------------------------------------------------
        IF v_ban_up2 IS NOT NULL AND v_ban_up2 > SYSDATE THEN
            DBMS_OUTPUT.PUT_LINE('ERROR: Usuario ' || g_user_id || ' sancionado hasta ' || v_ban_up2);
            RETURN;
        END IF;

        -----------------------------------------------------------------------
        -- (3) Verificar si hay reserva activa para hoy
        -----------------------------------------------------------------------
        SELECT COUNT(*)
        INTO v_reserva_count
        FROM loans
        WHERE signature = p_signature
          AND user_id = g_user_id
          AND type = 'R'
          AND return IS NULL
          AND stopdate = TRUNC(SYSDATE);

        IF v_reserva_count > 0 THEN
            UPDATE loans
            SET type = 'L'
            WHERE signature = p_signature
              AND user_id = g_user_id
              AND type = 'R'
              AND return IS NULL
              AND stopdate = TRUNC(SYSDATE);

            DBMS_OUTPUT.PUT_LINE('Reserva convertida en préstamo para ' || g_user_id);
            RETURN;
        END IF;

        -----------------------------------------------------------------------
        -- (4) Verificar disponibilidad de la copia
        -----------------------------------------------------------------------
        SELECT COUNT(*)
        INTO v_copy_available
        FROM loans
        WHERE signature = p_signature
          AND return IS NULL
          AND stopdate BETWEEN TRUNC(SYSDATE) AND TRUNC(SYSDATE) + 14;

        IF v_copy_available > 0 THEN
            DBMS_OUTPUT.PUT_LINE('ERROR: La copia ' || p_signature || ' no está disponible.');
            RETURN;
        END IF;

        -----------------------------------------------------------------------
        -- (5) Verificar límite de préstamos activos
        -----------------------------------------------------------------------
        SELECT COUNT(*)
        INTO v_loans_active
        FROM loans
        WHERE user_id = g_user_id
          AND return IS NULL;

        IF v_loans_active >= 5 THEN
            DBMS_OUTPUT.PUT_LINE('ERROR: Límite de 5 préstamos o reservas alcanzado.');
            RETURN;
        END IF;

        -----------------------------------------------------------------------
        -- (6) Obtener fecha de servicio válida para esa localidad
        -----------------------------------------------------------------------
        SELECT taskdate
        INTO v_stopdate
        FROM services
        WHERE town = v_town
          AND province = v_province
          AND ROWNUM = 1;

        -----------------------------------------------------------------------
        -- (6.5) Verificar si ya existe préstamo o reserva
        -----------------------------------------------------------------------
        BEGIN
            SELECT type
            INTO v_tipo_existente
            FROM loans
            WHERE signature = p_signature
              AND user_id = g_user_id
              AND stopdate = v_stopdate;

            IF v_tipo_existente = 'R' THEN
                DBMS_OUTPUT.PUT_LINE('ERROR: Ya existe una RESERVA con esa firma, usuario y fecha.');
            ELSIF v_tipo_existente = 'L' THEN
                DBMS_OUTPUT.PUT_LINE('ERROR: Ya existe un PRÉSTAMO con esa firma, usuario y fecha.');
            END IF;
            RETURN;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                NULL;
        END;

        -----------------------------------------------------------------------
        -- (7) Insertar préstamo usando datos obtenidos
        -----------------------------------------------------------------------
        INSERT INTO loans (signature, user_id, stopdate, town, province, type, time, return)
        VALUES (p_signature,
                g_user_id,
                v_stopdate,
                v_town,
                v_province,
                'L',
                14,
                NULL);

        DBMS_OUTPUT.PUT_LINE('Estado final: préstamo ' || p_signature || ' para usuario ' || g_user_id || ' (' || v_name || ' ' || v_surname || ')' ||
                             ' registrado correctamente.');
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('ERROR: Datos insuficientes: usuario o servicio no encontrado.');
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('ERROR inesperado: ' || SQLERRM);
    END insertar_prestamo;


    PROCEDURE insertar_reserva(p_isbn VARCHAR2, p_fecha DATE) IS
        v_name           users.name%TYPE;
        v_surname        users.surname1%TYPE;
        v_ban_up2        DATE;
        v_loans_active   NUMBER;
        v_signature      copies.signature%TYPE;
        v_town           users.town%TYPE;
        v_province       users.province%TYPE;
        v_tipo_existente CHAR(1);
    BEGIN
        -----------------------------------------------------------------------
        -- (1) Verificar que el usuario existe y obtener info
        -----------------------------------------------------------------------
        SELECT ban_up2, name, surname1, town, province
        INTO v_ban_up2, v_name, v_surname, v_town, v_province
        FROM users
        WHERE user_id = g_user_id;

        -----------------------------------------------------------------------
        -- (2) Verificar sanción
        -----------------------------------------------------------------------
        IF v_ban_up2 IS NOT NULL AND v_ban_up2 > SYSDATE THEN
            DBMS_OUTPUT.PUT_LINE('ERROR: Usuario ' || g_user_id || ' (' || v_name || ' ' || v_surname || ') sancionado hasta ' || v_ban_up2);
            RETURN;
        END IF;

        -----------------------------------------------------------------------
        -- (3) Verificar límite de préstamos o reservas
        -----------------------------------------------------------------------
        SELECT COUNT(*)
        INTO v_loans_active
        FROM loans
        WHERE user_id = g_user_id
          AND return IS NULL;

        IF v_loans_active >= 5 THEN -- Limite de 5 prestamos o reservas (lo asumo)
            DBMS_OUTPUT.PUT_LINE('ERROR: Usuario ' || g_user_id || ' (' || v_name || ' ' || v_surname || ') ha alcanzado el límite de préstamos o reservas.');
            RETURN;
        END IF;

        -----------------------------------------------------------------------
        -- (4) Buscar una copia del ISBN disponible durante 14 días desde p_fecha
        -----------------------------------------------------------------------
        BEGIN
            SELECT c.signature
            INTO v_signature
            FROM copies c
            WHERE c.isbn = p_isbn
              AND NOT EXISTS (SELECT 1
                              FROM loans l
                              WHERE l.signature = c.signature
                                AND l.return IS NULL
                                AND l.stopdate BETWEEN p_fecha AND p_fecha + 14)
              AND ROWNUM = 1;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                DBMS_OUTPUT.PUT_LINE('ERROR: No hay ninguna copia disponible del ISBN ' || p_isbn ||
                                     ' durante las dos semanas a partir de ' || TO_CHAR(p_fecha, 'DD/MM/YYYY'));
                RETURN;
        END;

        -----------------------------------------------------------------------
        -- (5) Verificar si ya existe una reserva o préstamo para esa copia en esa fecha
        -----------------------------------------------------------------------
        BEGIN
            SELECT type
            INTO v_tipo_existente
            FROM loans
            WHERE signature = v_signature
              AND user_id = g_user_id
              AND stopdate = p_fecha;

            IF v_tipo_existente = 'R' THEN
                DBMS_OUTPUT.PUT_LINE('ERROR: Ya existe una RESERVA para esta copia, usuario y fecha.');
            ELSIF v_tipo_existente = 'L' THEN
                DBMS_OUTPUT.PUT_LINE('ERROR: Ya existe un PRÉSTAMO para esta copia, usuario y fecha.');
            END IF;
            RETURN;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                NULL; -- no hay duplicado, podemos continuar
        END;

        -----------------------------------------------------------------------
        -- (6) Insertar la reserva
        -----------------------------------------------------------------------
        INSERT INTO loans (signature, user_id, stopdate, town, province, type, time, return)
        VALUES (v_signature,
                g_user_id,
                p_fecha,
                v_town,
                v_province,
                'R',
                14,
                NULL);

        DBMS_OUTPUT.PUT_LINE(' Reserva registrada: ISBN ' || p_isbn || ', copia ' || v_signature || ' para usuario ' || g_user_id || ' (' || v_name || ' ' || v_surname ||
                             ') en fecha ' || TO_CHAR(p_fecha, 'DD/MM/YYYY'));

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('ERROR: Usuario ' || g_user_id || ' no existe.');
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('ERROR inesperado en insertar_reserva: ' || SQLERRM);
    END insertar_reserva;


END foundicu;
/


