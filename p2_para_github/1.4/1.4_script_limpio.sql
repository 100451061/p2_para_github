-- (a) Evitar posts de bibliotecas (prohibido insertar o modificar posts de bibliotecas)

--     paso 1)

CREATE OR REPLACE TRIGGER trg_no_posts_bibliotecas
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

    IF v_type = 'L' THEN
        RAISE_APPLICATION_ERROR(-20011, 'ERROR: Las bibliotecas no pueden publicar posts.');
    END IF;
END;
/
COMMIT;
--     paso 2)
CREATE OR REPLACE TRIGGER trg_no_update_posts_bibliotecas
    BEFORE UPDATE
    ON posts
    FOR EACH ROW
DECLARE
    v_type users.type%TYPE;
BEGIN
    SELECT type
    INTO v_type
    FROM users
    WHERE user_id = :NEW.user_id;

    IF v_type = 'L' THEN
        RAISE_APPLICATION_ERROR(-20012, 'ERROR: Las bibliotecas no pueden modificar posts.');
    END IF;
END;
/
COMMIT;

-- (b) Actualizar el estado de las copias al devolverlas
CREATE OR REPLACE TRIGGER trg_copies_deteriorada
    BEFORE UPDATE
    ON copies
    FOR EACH ROW
BEGIN
    IF :NEW.condition = 'D' AND NVL(:OLD.condition, 'X') != 'D' THEN
        :NEW.deregistered := SYSDATE; -- Incluye hora, minutos y segundos
    END IF;
END;
/
COMMIT;

-- (c) Históricos al eliminar usuarios

-- paso 1) Crear tablas vacías idénticas
DROP TABLE users_hist;
DROP TABLE loans_hist;

COMMIT;

CREATE TABLE users_hist AS
SELECT *
FROM users
WHERE 1 = 0;
COMMIT;

CREATE TABLE loans_hist AS
SELECT *
FROM loans
WHERE 1 = 0;
COMMIT;

-- paso 2) Crear trigger
CREATE OR REPLACE TRIGGER trg_before_delete_users
    BEFORE DELETE
    ON users
    FOR EACH ROW
BEGIN
    -- Copiar usuario eliminado
    INSERT INTO users_hist
    VALUES (:OLD.user_id, :OLD.id_card, :OLD.name, :OLD.surname1, :OLD.surname2,
            :OLD.birthdate, :OLD.town, :OLD.province, :OLD.address, :OLD.email,
            :OLD.phone, :OLD.type, :OLD.ban_up2);

    -- Copiar sus préstamos
    INSERT INTO loans_hist
    SELECT *
    FROM loans
    WHERE user_id = :OLD.user_id;

    -- Eliminar préstamos originales
    DELETE
    FROM loans
    WHERE user_id = :OLD.user_id;
END;
/
COMMIT;
-- (a) Evitar posts de bibliotecas (prohibido insertar o modificar posts de bibliotecas)

--     paso 1)
CREATE OR REPLACE TRIGGER trg_no_posts_bibliotecas
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

    IF v_type = 'L' THEN
        RAISE_APPLICATION_ERROR(-20011, 'ERROR: Las bibliotecas no pueden publicar posts.');
    END IF;
END;
/
COMMIT;
--     paso 2)
CREATE OR REPLACE TRIGGER trg_no_update_posts_bibliotecas
    BEFORE UPDATE
    ON posts
    FOR EACH ROW
DECLARE
    v_type users.type%TYPE;
BEGIN
    SELECT type
    INTO v_type
    FROM users
    WHERE user_id = :NEW.user_id;

    IF v_type = 'L' THEN
        RAISE_APPLICATION_ERROR(-20012, 'ERROR: Las bibliotecas no pueden modificar posts.');
    END IF;
END;
/
COMMIT;

-- (b) Actualizar el estado de las copias al devolverlas
CREATE OR REPLACE TRIGGER trg_copies_deteriorada
    BEFORE UPDATE
    ON copies
    FOR EACH ROW
BEGIN
    IF :NEW.condition = 'D' AND NVL(:OLD.condition, 'X') != 'D' THEN
        :NEW.deregistered := SYSDATE; -- Incluye hora, minutos y segundos
    END IF;
END;
/
COMMIT;

-- (c) Históricos al eliminar usuarios

-- paso 1) Crear tablas vacías idénticas
DROP TABLE users_hist;
DROP TABLE loans_hist;

COMMIT;

CREATE TABLE users_hist AS
SELECT *
FROM users
WHERE 1 = 0;
COMMIT;

CREATE TABLE loans_hist AS
SELECT *
FROM loans
WHERE 1 = 0;
COMMIT;

-- paso 2) Crear trigger
CREATE OR REPLACE TRIGGER trg_before_delete_users
    BEFORE DELETE
    ON users
    FOR EACH ROW
BEGIN
    -- Copiar usuario eliminado
    INSERT INTO users_hist
    VALUES (:OLD.user_id, :OLD.id_card, :OLD.name, :OLD.surname1, :OLD.surname2,
            :OLD.birthdate, :OLD.town, :OLD.province, :OLD.address, :OLD.email,
            :OLD.phone, :OLD.type, :OLD.ban_up2);

    -- Copiar sus préstamos
    INSERT INTO loans_hist
    SELECT *
    FROM loans
    WHERE user_id = :OLD.user_id;

    -- Eliminar préstamos originales
    DELETE
    FROM loans
    WHERE user_id = :OLD.user_id;
END;
/
COMMIT;