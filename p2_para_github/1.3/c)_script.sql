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


-- -------------------------------------------
-- - Insertion Script - FSDB Assignment 2025 -
-- -------------------------------------------
-- -------------------------------------------

-- heal books data, grouping by pk and projecting min
INSERT INTO books(TITLE, AUTHOR, COUNTRY, LANGUAGE, PUB_DATE, ALT_TITLE, TOPIC, CONTENT, AWARDS)
SELECT DISTINCT trim(TITLE),
                trim(MAIN_AUTHOR),
                min(trim(PUB_COUNTRY)),
                min(trim(ORIGINAL_LANGUAGE)),
                min(to_number(PUB_DATE)),
                min(trim(ALT_TITLE)),
                min(trim(TOPIC)),
                min(trim(CONTENT_NOTES)),
                min(trim(AWARDS))
FROM fsdb.acervus
group by title, main_author
;
-- 181435 rows
commit;

--

INSERT INTO More_Authors(TITLE, MAIN_AUTHOR, ALT_AUTHORS, MENTIONS)
SELECT DISTINCT trim(TITLE), trim(MAIN_AUTHOR), trim(OTHER_AUTHORS), max(trim(MENTION_AUTHORS))
FROM fsdb.acervus
where trim(OTHER_AUTHORS) is not null
group by (trim(TITLE), trim(MAIN_AUTHOR), trim(OTHER_AUTHORS))
;

-- 23333 rows

--

-- same isbn can take different nat_lib_id; group by pk and project min
INSERT INTO Editions(ISBN, TITLE, AUTHOR, LANGUAGE, ALT_LANGUAGES, EDITION, PUBLISHER, EXTENSION,
                     SERIES, COPYRIGHT, PUB_PLACE, DIMENSIONS, PHY_FEATURES, MATERIALS, NOTES, NATIONAL_LIB_ID, URL)
SELECT DISTINCT trim(ISBN),
                min(trim(TITLE)),
                min(trim(MAIN_AUTHOR)),
                nvl(min(trim(MAIN_LANGUAGE)), 'Spanish'),
                min(trim(OTHER_LANGUAGES)),
                min(trim(EDITION)),
                min(trim(PUBLISHER)),
                min(trim(EXTENSION)),
                min(trim(SERIES)),
                min(trim(COPYRIGHT)),
                min(trim(PUB_PLACE)),
                min(trim(DIMENSIONS)),
                min(trim(PHYSICAL_FEATURES)),
                min(trim(ATTACHED_MATERIALS)),
                min(trim(NOTES)),
                min(trim(NATIONAL_LIB_ID)),
                min(trim(URL))
FROM fsdb.acervus
group by trim(isbn)
;
-- 240632 rows

commit;

--

-- one copy with null pk (skip it & document)
INSERT INTO Copies(SIGNATURE, ISBN)
SELECT DISTINCT trim(SIGNATURE), trim(ISBN)
FROM fsdb.acervus
where signature is not null
;
-- 241572 rows
commit;

--

INSERT INTO municipalities (TOWN, PROVINCE, POPULATION)
SELECT DISTINCT trim(TOWN), trim(PROVINCE), trim(POPULATION)
FROM fsdb.busstops
;
-- 1365 rows
--

INSERT INTO routes (ROUTE_ID)
SELECT DISTINCT trim(ROUTE_ID)
FROM fsdb.busstops
;
-- 150 rows
--

-- there is an invalid date (29-02-1970); split into two cases
INSERT INTO drivers (PASSPORT, EMAIL, FULLNAME, BIRTHDATE, PHONE, ADDRESS, CONT_START, CONT_END)
SELECT DISTINCT trim(LIB_PASSPORT),
                trim(LIB_EMAIL),
                trim(LIB_FULLNAME),
                to_date(LIB_BIRTHDATE, 'DD-MM-YYYY'),
                to_number(LIB_PHONE),
                trim(LIB_ADDRESS),
                to_date(CONT_START, 'DD.MM.YYYY'),
                to_date(CONT_END, 'DD.MM.YYYY')
FROM fsdb.busstops
where lib_birthdate != '29-02-1970'
;
-- 12 rows
INSERT INTO drivers (PASSPORT, EMAIL, FULLNAME, BIRTHDATE, PHONE, ADDRESS, CONT_START, CONT_END)
SELECT DISTINCT trim(LIB_PASSPORT),
                trim(LIB_EMAIL),
                trim(LIB_FULLNAME),
                to_date('01-03-1970', 'DD-MM-YYYY'),
                to_number(LIB_PHONE),
                trim(LIB_ADDRESS),
                to_date(CONT_START, 'DD.MM.YYYY'),
                to_date(CONT_END, 'DD.MM.YYYY')
FROM fsdb.busstops
where lib_birthdate = '29-02-1970'
;
-- 1 row

-- several last-itv dates for each bus; the later (max) will be taken as valid
INSERT INTO bibuses(PLATE, LAST_ITV, NEXT_ITV)
SELECT p, max(l), min(n)
FROM (SELECT trim(PLATE) p, to_date(trim(LAST_ITV), 'DD.MM.YYYY // HH24:MI:SS') l, to_date(trim(NEXT_ITV), 'DD.MM.YYYY') n
      FROM fsdb.busstops)
group by p
;
-- 14 rows

INSERT INTO assign_drv (PASSPORT, TASKDATE, ROUTE_ID)
SELECT DISTINCT trim(LIB_PASSPORT), to_date(STOPDATE, 'DD-MM-YYYY'), trim(ROUTE_ID)
FROM fsdb.busstops
;
-- 150 rows

INSERT INTO assign_bus (PLATE, TASKDATE, ROUTE_ID)
SELECT DISTINCT trim(PLATE), to_date(STOPDATE, 'DD-MM-YYYY'), trim(ROUTE_ID)
FROM fsdb.busstops
;
-- 150 rows

-- stoptime with minute granularity
INSERT INTO stops (TOWN, PROVINCE, ADDRESS, ROUTE_ID, STOPTIME)
SELECT DISTINCT trim(TOWN),
                trim(PROVINCE),
                trim(ADDRESS),
                trim(ROUTE_ID),
                to_number(substr(STOPTIME, 1, 2)) * 60 + to_number(substr(STOPTIME, 4, 2))
FROM fsdb.busstops
;
-- 1365 rows

INSERT INTO services (TOWN, PROVINCE, BUS, TASKDATE, PASSPORT)
SELECT DISTINCT trim(TOWN), trim(PROVINCE), trim(PLATE), to_date(STOPDATE, 'DD-MM-YYYY'), trim(LIB_PASSPORT)
FROM fsdb.busstops
;
-- 1365 rows
commit;

--

-- some users appear to be in several towns; solution: skip&doc
-- (or heal by imp. sem assumption: assume first one is the valid, so keep first)
--skip BAN_UP2 to take null value

INSERT INTO users (USER_ID, ID_CARD, NAME, SURNAME1, SURNAME2, BIRTHDATE,
                   TOWN, PROVINCE, ADDRESS, EMAIL, PHONE, TYPE)
SELECT a1,
       a2,
       a3,
       a4,
       a5,
       a6,
       a7,
       a8,
       a9,
       a10,
       a11,
       a12
FROM (SELECT a1,
             a2,
             a3,
             a4,
             a5,
             a6,
             town                                              a7,
             a8,
             a9,
             a10,
             a11,
             a12,
             row_number() over (partition by a1 order by null) rn
      FROM (SELECT DISTINCT trim(USER_ID)                                   a1,
                            trim(PASSPORT)                                  a2,
                            trim(NAME)                                      a3,
                            trim(SURNAME1)                                  a4,
                            trim(SURNAME2)                                  a5,
                            to_date(BIRTHDATE, 'DD/MM/YYYY')                a6,
                            trim(TOWN)                                      town,
                            to_date(substr(DATE_TIME, 1, 10), 'DD/MM/YYYY') taskdate,
                            trim(ADDRESS)                                   a9,
                            trim(EMAIL)                                     a10,
                            to_number(PHONE)                                a11
            FROM fsdb.loans) a
               JOIN (SELECT DISTINCT trim(TOWN)                              town,
                                     trim(PROVINCE)                          a8,
                                     to_date(STOPDATE, 'DD-MM-YYYY')         taskdate,
                                     DECODE(HAS_LIBRARY, 'Y', 'L', 'N', 'P') a12
                     FROM fsdb.busstops) b
                    using (town, taskdate))
WHERE rn = 1;
-- 2771 rows


--time in minutes
INSERT INTO loans (SIGNATURE, USER_ID, STOPDATE, TOWN, PROVINCE, TYPE, TIME, RETURN)
SELECT *
FROM (SELECT DISTINCT trim(l.SIGNATURE)                                 c1,
                      trim(USER_ID),
                      to_date(substr(l.DATE_TIME, 1, 10), 'DD/MM/YYYY') s1,
                      trim(u.TOWN)                                      s2,
                      trim(u.PROVINCE)                                  s3,
                      'L',
                      to_number(substr(DATE_TIME, 13, 2)) * 60 + to_number(substr(DATE_TIME, 16, 2)),
                      to_date(l.RETURN, 'DD/MM/YYYY  HH24:MI:SS')
      FROM users u
               JOIN fsdb.loans l using (user_ID))
where (s1, s2, s3) in (select taskdate, town, province from services)
  and c1 in (select signature from copies);
-- 23709 rows

INSERT INTO posts (SIGNATURE, USER_ID, STOPDATE, POST_DATE, TEXT, LIKES, DISLIKES)
SELECT *
FROM (SELECT DISTINCT trim(SIGNATURE)                                 p1,
                      trim(USER_ID)                                   p2,
                      to_date(substr(DATE_TIME, 1, 10), 'DD/MM/YYYY') p3,
                      to_date(POST_DATE, 'DD/MM/YYYY  HH24:MI:SS'),
                      trim(POST)                                      text,
                      to_number(LIKES),
                      to_number(DISLIKES)
      FROM fsdb.loans)
where TEXT is not null
  AND (p1, p2, p3) in (select signature, user_id, stopdate from loans);
-- 5447 rows

commit;


drop view my_data;
COMMIT;

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
WHERE user_id = foundicu.get_current_user
WITH READ ONLY;
COMMIT;
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
drop view my_loans;
COMMIT;
-- paso 1)
CREATE OR REPLACE VIEW my_loans AS
SELECT l.signature,
       l.stopdate,
       l.town,
       l.province,
       l.type,
       l.time,
       l.return,
       p.text AS post,
       p.post_date,
       p.likes,
       p.dislikes
FROM loans l
         LEFT JOIN posts p
                   ON (p.signature = l.signature) AND (p.user_id = l.user_id) AND (p.stopdate = l.stopdate)
WHERE l.user_id = foundicu.get_current_user
-- aseguramos que solo se pueden modificar filas del usuario actual
WITH CHECK OPTION CONSTRAINT my_loans_chk;

COMMIT;

-- paso 2)
-- crear el trigger INSTEAD OF UPDATE para la vista my_loans
-- este trigger permite solo actualizar el post (valor text), y gestiona si hay o no un post previo.

CREATE OR REPLACE TRIGGER trg_update_my_loans
    INSTEAD OF UPDATE
    ON my_loans
    FOR EACH ROW
DECLARE
    v_exists NUMBER;
BEGIN
    -- Verificar si ya existe post para ese préstamo
    SELECT COUNT(*)
    INTO v_exists
    FROM posts
    WHERE signature = :OLD.signature
      AND user_id = foundicu.get_current_user
      AND stopdate = :OLD.stopdate;

    IF v_exists > 0 THEN
        -- Actualizar post existente
        UPDATE posts
        SET text      = :NEW.post,
            post_date = SYSDATE
        WHERE signature = :OLD.signature
          AND user_id = foundicu.get_current_user
          AND stopdate = :OLD.stopdate;
    ELSE
        -- Insertar nuevo post
        INSERT INTO posts (signature, user_id, stopdate, post_date, text, likes, dislikes)
        VALUES (:OLD.signature,
                foundicu.get_current_user,
                :OLD.stopdate,
                SYSDATE,
                :NEW.post,
                0,
                0);
    END IF;
END;
/
COMMIT;

-----------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

drop view my_reservations;
COMMIT;

-- paso 1)
CREATE OR REPLACE VIEW my_reservations AS
SELECT l.signature,
       l.stopdate,
       l.town,
       l.province,
       l.time,
       l.return
FROM loans l
WHERE l.user_id = foundicu.get_current_user
  AND l.type = 'R'
WITH CHECK OPTION CONSTRAINT my_reservations_chk;
COMMIT;
-----------------------------------------------------------------------------------------------------------------------------------
-- paso 2) INSERT
-----------------------------------------------------------------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER trg_insert_my_reservations
    INSTEAD OF INSERT
    ON my_reservations
    FOR EACH ROW
DECLARE
    v_user_id  users.user_id%TYPE := foundicu.get_current_user;
    v_isbn     editions.isbn%TYPE;
    v_count    NUMBER;
    v_town     users.town%TYPE;
    v_province users.province%TYPE;
BEGIN
    -- Comprobar que la signatura existe
    SELECT isbn INTO v_isbn FROM copies WHERE signature = :NEW.signature;

    -- Obtener la localidad del usuario
    SELECT town, province
    INTO v_town, v_province
    FROM users
    WHERE user_id = v_user_id;

    -- Verificar que hay un servicio ese día
    SELECT COUNT(*)
    INTO v_count
    FROM services
    WHERE town = v_town
      AND province = v_province
      AND taskdate = :NEW.stopdate;

    IF v_count = 0 THEN
        RAISE_APPLICATION_ERROR(-20010, 'ERROR: No hay ningún servicio en ' || v_town || ' (' || v_province || ') el día ' || TO_CHAR(:NEW.stopdate, 'DD/MM/YYYY'));
    END IF;

    -- Verificar disponibilidad de cualquier copia de ese ISBN en ese rango
    SELECT COUNT(*)
    INTO v_count
    FROM copies c
    WHERE c.isbn = v_isbn
      AND NOT EXISTS (SELECT 1
                      FROM loans l
                      WHERE l.signature = c.signature
                        AND l.return IS NULL
                        AND l.stopdate BETWEEN :NEW.stopdate AND :NEW.stopdate + 14);

    IF v_count = 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'ERROR: No hay ninguna copia disponible del ISBN ' || v_isbn || ' para las dos semanas desde ' || TO_CHAR(:NEW.stopdate, 'DD/MM/YYYY'));
    END IF;

    -- Insertar la reserva
    INSERT INTO loans(signature, user_id, stopdate, town, province, type, time, return)
    VALUES (:NEW.signature, v_user_id, :NEW.stopdate, :NEW.town, :NEW.province, 'R', 14, NULL);
END;
/
COMMIT;
--------------------------------------------------------------------------------------------------------------------------------
-- paso 3) DELETE
--------------------------------------------------------------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER trg_delete_my_reservations
    INSTEAD OF DELETE
    ON my_reservations
    FOR EACH ROW
BEGIN
    DELETE
    FROM loans
    WHERE signature = :OLD.signature
      AND user_id = foundicu.get_current_user
      AND stopdate = :OLD.stopdate
      AND type = 'R';
END;
/
COMMIT;
---------------------------------------------------------------------------------------------------------------------------------
-- paso 4) UPDATE
---------------------------------------------------------------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER trg_update_my_reservations
    INSTEAD OF UPDATE
    ON my_reservations
    FOR EACH ROW
DECLARE
    v_isbn     editions.isbn%TYPE;
    v_count    NUMBER;
    v_town     users.town%TYPE;
    v_province users.province%TYPE;
BEGIN
    -- Obtener el municipio del usuario actual
    SELECT town, province
    INTO v_town, v_province
    FROM users
    WHERE user_id = foundicu.get_current_user;

    -- Verificar que la nueva fecha está en services
    SELECT COUNT(*)
    INTO v_count
    FROM services
    WHERE town = v_town
      AND province = v_province
      AND taskdate = :NEW.stopdate;

    IF v_count = 0 THEN
        RAISE_APPLICATION_ERROR(-20003, 'ERROR: No hay ningún servicio en ' || v_town || ' (' || v_province || ') para el día ' || TO_CHAR(:NEW.stopdate, 'DD/MM/YYYY'));
    END IF;

    -- Obtener el ISBN de la copia
    SELECT isbn
    INTO v_isbn
    FROM copies
    WHERE signature = :OLD.signature;

    -- Verificar disponibilidad del ISBN en la nueva fecha
    SELECT COUNT(*)
    INTO v_count
    FROM copies c
    WHERE c.isbn = v_isbn
      AND NOT EXISTS (SELECT 1
                      FROM loans l
                      WHERE l.signature = c.signature
                        AND l.return IS NULL
                        AND l.stopdate BETWEEN :NEW.stopdate AND :NEW.stopdate + 14);

    IF v_count = 0 THEN
        RAISE_APPLICATION_ERROR(-20002, 'ERROR: No hay disponibilidad del ISBN para la nueva fecha ' || TO_CHAR(:NEW.stopdate, 'DD/MM/YYYY'));
    END IF;

    -- Actualizar la reserva
    UPDATE loans
    SET stopdate = :NEW.stopdate
    WHERE signature = :OLD.signature
      AND user_id = foundicu.get_current_user
      AND stopdate = :OLD.stopdate
      AND type = 'R';
END;
/
COMMIT;