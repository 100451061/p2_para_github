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
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE PACKAGE foundicu AS

    PROCEDURE insertar_prestamo(p_signature CHAR);
    PROCEDURE insertar_reserva(p_isbn VARCHAR2, p_reserva_date DATE);
    PROCEDURE registrar_devolucion(p_signature CHAR);

END foundicu;
/

CREATE OR REPLACE PACKAGE BODY foundicu AS

    PROCEDURE insertar_prestamo(p_signature CHAR) IS
        v_user_id        users.user_id%TYPE;
        v_reserva_count  NUMBER;
        v_loan_count     NUMBER;
        v_ban_up2        users.ban_up2%TYPE;
        v_copy_available NUMBER;
        v_isbn           editions.isbn%TYPE;

    BEGIN
        -- Obtener el USER_ID del usuario actual (asumiendo que hay una función para esto)
        -- En la práctica, necesitaríamos usar una función que obtenga el usuario de la sesión.
        SELECT USER INTO v_user_id FROM dual;
        -- Esto es un placeholder.

        -- Verificar si el usuario existe
        SELECT ban_up2 INTO v_ban_up2 FROM users WHERE user_id = v_user_id;

        -- Verificar si hay una reserva para el usuario actual y la signatura especificada
        SELECT COUNT(*)
        INTO v_reserva_count
        FROM loans
        WHERE signature = p_signature
          AND user_id = v_user_id
          AND stopdate = TRUNC(SYSDATE);

        IF v_reserva_count > 0 THEN
            -- La reserva existe, convertirla en préstamo
            UPDATE loans
            SET RETURN = NULL
            WHERE signature = p_signature
              AND user_id = v_user_id
              AND stopdate = TRUNC(SYSDATE);

            DBMS_OUTPUT.PUT_LINE('Préstamo creado desde la reserva.');
        ELSE
            -- No hay reserva, verificar disponibilidad y condiciones para préstamo
            SELECT COUNT(*)
            INTO v_copy_available
            FROM copies c
                     LEFT JOIN loans l ON c.signature = l.signature
            WHERE c.signature = p_signature
              AND (l.signature IS NULL OR l.RETURN IS NOT NULL);

            IF v_copy_available > 0 THEN
                -- Verificar límite de préstamos y sanciones
                SELECT COUNT(*)
                INTO v_loan_count
                FROM loans
                WHERE user_id = v_user_id
                  AND RETURN IS NULL;

                IF v_loan_count < 5 AND v_ban_up2 IS NULL THEN -- Asumo máximo 5 prestamos y sin sanción.
                -- Insertar nuevo préstamo
                    SELECT isbn INTO v_isbn FROM copies WHERE signature = p_signature;
                    INSERT INTO loans (signature, user_id, stopdate, town, province, type, time, RETURN)
                    SELECT p_signature,
                           v_user_id,
                           SYSDATE,
                           town,
                           province,
                           type,
                           14,
                           null
                    FROM users
                    WHERE user_id = v_user_id;

                    DBMS_OUTPUT.PUT_LINE('Préstamo creado correctamente.');
                ELSE
                    DBMS_OUTPUT.PUT_LINE('El usuario ha alcanzado el límite de préstamos o está sancionado.');
                END IF;
            ELSE
                DBMS_OUTPUT.PUT_LINE('La copia no está disponible para préstamo.');
            END IF;
        END IF;

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('Usuario o copia no encontrados.');
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
    END insertar_prestamo;

    PROCEDURE insertar_reserva(p_isbn VARCHAR2, p_reserva_date DATE) IS
        v_user_id        users.user_id%TYPE;
        v_loan_count     NUMBER;
        v_ban_up2        users.ban_up2%TYPE;
        v_copy_available NUMBER;
        v_signature      copies.signature%TYPE;

    BEGIN
        -- Obtener el USER_ID del usuario actual (asumiendo que hay una función para esto)
        SELECT USER INTO v_user_id FROM dual;
        -- Placeholder

        -- Verificar si el usuario existe y no está sancionado
        SELECT ban_up2 INTO v_ban_up2 FROM users WHERE user_id = v_user_id;

        -- Verificar límite de préstamos y reservas
        SELECT COUNT(*)
        INTO v_loan_count
        FROM loans
        WHERE user_id = v_user_id
          AND RETURN IS NULL;

        IF v_loan_count < 5 AND v_ban_up2 IS NULL THEN
            -- Verificar disponibilidad de copia durante 14 días a partir de la fecha proporcionada
            SELECT COUNT(c.signature)
            INTO v_copy_available
            FROM copies c
                     LEFT JOIN loans l ON c.signature = l.signature
            WHERE c.isbn = p_isbn
              AND (l.signature IS NULL OR l.RETURN IS NOT NULL);

            IF v_copy_available > 0 THEN
                -- Obtener la signatura de la primera copia disponible
                SELECT c.signature
                INTO v_signature
                FROM copies c
                         LEFT JOIN loans l ON c.signature = l.signature
                WHERE c.isbn = p_isbn
                  AND (l.signature IS NULL OR l.RETURN IS NOT NULL)
                  AND ROWNUM = 1;

                -- Insertar la reserva
                INSERT INTO loans (signature, user_id, stopdate, town, province, type, time, RETURN)
                SELECT v_signature,
                       v_user_id,
                       p_reserva_date,
                       town,
                       province,
                       type,
                       0,
                       null
                FROM users
                WHERE user_id = v_user_id;

                DBMS_OUTPUT.PUT_LINE('Reserva creada correctamente.');
            ELSE
                DBMS_OUTPUT.PUT_LINE('No hay copias disponibles para reservar en la fecha especificada.');
            END IF;
        ELSE
            DBMS_OUTPUT.PUT_LINE('El usuario ha alcanzado el límite de préstamos o está sancionado.');
        END IF;

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('Usuario o ISBN no encontrados.');
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
    END insertar_reserva;

    PROCEDURE registrar_devolucion(p_signature CHAR) IS
        v_user_id    users.user_id%TYPE;
        v_loan_count NUMBER;

    BEGIN
        -- Obtener el USER_ID del usuario actual (asumiendo que hay una función para esto)
        SELECT USER INTO v_user_id FROM dual;
        -- Placeholder

        -- Verificar si el usuario tiene prestado el libro
        SELECT COUNT(*)
        INTO v_loan_count
        FROM loans
        WHERE signature = p_signature
          AND user_id = v_user_id
          AND RETURN IS NULL;

        IF v_loan_count > 0 THEN
            -- Registrar la devolución
            UPDATE loans
            SET RETURN = SYSDATE
            WHERE signature = p_signature
              AND user_id = v_user_id
              AND RETURN IS NULL;

            DBMS_OUTPUT.PUT_LINE('Devolución registrada correctamente.');
        ELSE
            DBMS_OUTPUT.PUT_LINE('El usuario no tiene prestado este libro.');
        END IF;

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('Usuario o signatura no encontrados.');
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
    END registrar_devolucion;

END foundicu;
/