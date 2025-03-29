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



-- consultas intermedias del view 1)

-- Ver libros con ≥ 3 idiomas distintos, asi me corrijo y compruebo
SELECT title, author, COUNT(DISTINCT language) as cantidad_idiomas
FROM editions
GROUP BY title, author
HAVING COUNT(DISTINCT language) >= 3;


-- Aquí ya ves las ediciones completas solo de los libros que tienen ≥ 3 idiomas.
SELECT e.ISBN, e.TITLE, e.AUTHOR, e.LANGUAGE
FROM editions e
         JOIN (SELECT title, author
               FROM editions
               GROUP BY title, author
               HAVING COUNT(DISTINCT language) >= 3) sub1 ON (sub1.title = e.title) AND (sub1.author = e.author);


-- Ver qué copias físicas existen de esas ediciones.
SELECT c.signature, e.isbn, e.title, e.author
FROM copies c
         JOIN editions e ON (c.isbn = e.isbn)
         JOIN (SELECT title, author
               FROM editions
               GROUP BY title, author
               HAVING COUNT(DISTINCT language) >= 3) sub1 ON (sub1.title = e.title) AND (sub1.author = e.author);


-- Ver si la copia ha sido prestada (sí o no)
SELECT b.title,
       b.author,
       e.isbn,
       NVL(c.signature, 'sin_copia')   AS copia,
       NVL(l.signature, 'no_prestada') AS prestada

FROM (SELECT title, author
      FROM editions
      GROUP BY title, author
      HAVING COUNT(DISTINCT language) >= 3) sub1
         JOIN books b ON (sub1.title = b.title) AND (sub1.author = b.author)
         JOIN editions e ON (e.title = b.title) AND (e.author = b.author)
         LEFT JOIN copies c ON (c.isbn = e.isbn)
         LEFT JOIN loans l ON (l.signature = c.signature);



-- consultas intermedias del view 2)

-- oracle no tiene una operación years_between, oracle nos da months_between, tenemos que hacerlo nosotros
-- calculamos los meses completos entre la fecha actual y la fecha de nacimiento, luego dividimos entre 12 para obtener la edad,
-- como hay decimales, los truncamos y me quedo con la parte entera

-- calculo de la edad
SELECT fullname,
       TRUNC(MONTHS_BETWEEN(SYSDATE, birthdate) / 12) AS edad
FROM drivers;

-- calculo de la antiguedad
SELECT fullname,
       TRUNC(MONTHS_BETWEEN(SYSDATE, cont_start) / 12) AS antiguedad
FROM drivers;


-- Calculo para cada conductor; queremos saber en cuántos años diferentes ha trabajado al menos un día
-- (i.e; ha sido asignado a una ruta en al menos una fecha del año).
-- Un año activo es un año en el que el conductor ha trabajado al menos un día.
-- Si hay al menos una fila en assign_drv para un año determinado → ese año cuenta como activo.

-- Años con al menos un día en carretera.
-- EXTRACT(YEAR FROM taskdate) -> 2021, 2021, 2022, 2023, 2023, 2023
-- DISTINCT -> 2021, 2022, 2023
-- COUNT -> 3 años activos

SELECT d.fullname,
       d.PASSPORT,
       COUNT(DISTINCT EXTRACT(YEAR FROM a.taskdate)) AS años_activos
FROM drivers d
         JOIN assign_drv a ON (a.passport = d.passport)
GROUP BY d.fullname, d.PASSPORT;
-- agrupo tb por passport, en el caso de que fullname se repita


-- número medio de paradas por año activo.
-- drivers -> assign_drv -> services
-- Contar todas las paradas que ha hecho en total.
-- Dividir ese número entre los años activos
SELECT d.fullname,
       COUNT(*)                                                 AS num_paradas,
       COUNT(DISTINCT EXTRACT(YEAR FROM a.taskdate))            AS años_activos,
       COUNT(*) / COUNT(DISTINCT EXTRACT(YEAR FROM a.taskdate)) AS media_paradas_por_año
FROM drivers d
         JOIN assign_drv a ON (a.passport = d.passport)
         JOIN services s ON (s.taskdate = a.taskdate) AND (s.passport = a.passport)
GROUP BY d.passport, d.fullname;


-- número medio de préstamos por año activo,
-- drivers -> assign_drv -> services -> loans
SELECT d.fullname,
       COUNT(*)                                                 AS num_prestamos,
       COUNT(DISTINCT EXTRACT(YEAR FROM a.taskdate))            AS años_activos,
       COUNT(*) / COUNT(DISTINCT EXTRACT(YEAR FROM a.taskdate)) AS media_prestamos_por_año
FROM drivers d
         JOIN assign_drv a ON (a.passport = d.passport)
         JOIN services s ON (s.taskdate = a.taskdate) AND (s.passport = a.passport)
         JOIN loans l ON (l.STOPDATE = s.taskdate) AND (l.town = s.town) AND (l.province = s.province)
GROUP BY d.passport, d.fullname;



-- porcentaje de préstamos no devueltos (con respecto al total operados por ese empleado).
-- Para cada conductor, queremos saber ¿Qué porcentaje de los préstamos que ha gestionado no han sido devueltos?
-- (SUMA de préstamos no devueltos) / (TOTAL de préstamos gestionados) * 100
SELECT d.fullname,
       COUNT(*)               AS total_prestamos,

       SUM(CASE
               WHEN l.return IS NULL THEN 1
               ELSE 0
           END)               AS prestamos_no_devueltos, -- he comprobado, y no hay préstamos sin devolver, asi que arroja 0.

       SUM(CASE
               WHEN l.return IS NULL THEN 1
               ELSE 0
           END)
           * 100.0 / COUNT(*) AS porcentaje_no_devueltos -- arroja 0

FROM drivers d
         JOIN services s
              ON (s.passport = d.passport)
         JOIN loans l ON (l.town = s.town AND l.province = s.province AND l.stopdate = s.taskdate)
GROUP BY d.passport, d.fullname;
d