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