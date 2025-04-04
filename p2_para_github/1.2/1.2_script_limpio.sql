CREATE OR REPLACE PACKAGE foundicu AS
    g_user_id CHAR(10);

    PROCEDURE set_current_user(p_user_id CHAR);
    FUNCTION get_current_user RETURN CHAR;
    PROCEDURE insertar_prestamo(p_signature CHAR);
    PROCEDURE insertar_reserva(p_isbn VARCHAR2, p_fecha DATE);
    PROCEDURE insertar_devolucion(p_signature CHAR);
END foundicu;
/

COMMIT;

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

            DBMS_OUTPUT.PUT_LINE('Reserva convertida en préstamo para --> ' || g_user_id);
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

        DBMS_OUTPUT.PUT_LINE('Estado final --> préstamo ' || p_signature || ' para usuario ' || g_user_id || ' (' || v_name || ' ' || v_surname || ')' ||
                             ' registrado correctamente.');
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('ERROR: Datos insuficientes: usuario o servicio no encontrado.');
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('ERROR inesperado: ' || SQLERRM);
    END insertar_prestamo;


    PROCEDURE insertar_reserva(p_isbn VARCHAR2, p_fecha DATE) IS
        -- No viene en el enunciado, asi que asumiré que el maximo de prestamos es 5, por ejemplo
        c_max_prestamos CONSTANT NUMBER             := 5;

        -- Variables de usuario
        v_user_id                users.user_id%TYPE := g_user_id; -- reultilizo get_current_user
        v_name                   users.name%TYPE;
        v_surname                users.surname1%TYPE;
        v_ban_up2                DATE;
        v_loans_active           NUMBER;

        -- Datos para la reserva
        v_signature              copies.signature%TYPE;
        v_town                   users.town%TYPE;
        v_province               users.province%TYPE;
        v_tipo_existente         CHAR(1);
    BEGIN
        -----------------------------------------------------------------------
        -- (1) Verificar que el usuario existe y obtener info
        -----------------------------------------------------------------------
        SELECT ban_up2, name, surname1, town, province
        INTO v_ban_up2, v_name, v_surname, v_town, v_province
        FROM users
        WHERE user_id = v_user_id;

        -----------------------------------------------------------------------
        -- (2) Verificar sanción
        -----------------------------------------------------------------------
        IF v_ban_up2 IS NOT NULL AND v_ban_up2 > SYSDATE THEN
            DBMS_OUTPUT.PUT_LINE('ERROR: Usuario ' || v_user_id || ' (' || v_name || ' ' || v_surname || ') sancionado hasta ' || v_ban_up2);
            RETURN;
        END IF;

        -----------------------------------------------------------------------
        -- (3) Verificar límite de préstamos o reservas activos
        -----------------------------------------------------------------------
        SELECT COUNT(*)
        INTO v_loans_active
        FROM loans
        WHERE user_id = v_user_id
          AND return IS NULL;

        IF v_loans_active >= c_max_prestamos THEN
            DBMS_OUTPUT.PUT_LINE('ERROR: Usuario ' || v_user_id || ' (' || v_name || ' ' || v_surname || ') ha alcanzado el límite de ' || c_max_prestamos ||
                                 ' préstamos o reservas (actualmente tiene ' || v_loans_active || ').');
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
                DBMS_OUTPUT.PUT_LINE('ERROR: No hay ninguna copia disponible del ISBN ' || p_isbn || ' durante las dos semanas a partir de ' || TO_CHAR(p_fecha, 'DD/MM/YYYY'));
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
              AND user_id = v_user_id
              AND stopdate = p_fecha;

            IF v_tipo_existente = 'R' THEN
                DBMS_OUTPUT.PUT_LINE('ERROR: Ya existe una RESERVA para esta copia, usuario y fecha.');
            ELSIF v_tipo_existente = 'L' THEN
                DBMS_OUTPUT.PUT_LINE('ERROR: Ya existe un PRÉSTAMO para esta copia, usuario y fecha.');
            END IF;
            RETURN;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                NULL; -- No existe duplicado, podemos continuar
        END;

        -----------------------------------------------------------------------
        -- (6) Insertar la reserva
        -----------------------------------------------------------------------
        INSERT INTO loans (signature, user_id, stopdate, town, province, type, time, return)
        VALUES (v_signature,
                v_user_id,
                p_fecha,
                v_town,
                v_province,
                'R',
                14,
                NULL);

        DBMS_OUTPUT.PUT_LINE('Reserva registrada --> ISBN ' || p_isbn || ', copia ' || v_signature || ' para usuario ' || v_user_id || ' (' || v_name || ' ' || v_surname || ')' ||
                             ' en fecha ' || TO_CHAR(p_fecha, 'DD/MM/YYYY'));

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('ERROR: Usuario ' || v_user_id || ' no existe.');
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('ERROR inesperado en insertar_reserva: ' || SQLERRM);
    END insertar_reserva;


    PROCEDURE insertar_devolucion(p_signature CHAR) IS
        v_user_id  users.user_id%TYPE := foundicu.get_current_user; -- Reutiliza función de sesión
        v_name     users.name%TYPE;
        v_surname  users.surname1%TYPE;
        v_stopdate DATE;
    BEGIN
        -----------------------------------------------------------------------
        -- (1) Verificar que el usuario existe
        -----------------------------------------------------------------------
        SELECT name, surname1
        INTO v_name, v_surname
        FROM users
        WHERE user_id = v_user_id;

        -----------------------------------------------------------------------
        -- (2) Verificar que el usuario tiene un préstamo activo con esa copia
        -----------------------------------------------------------------------
        BEGIN
            SELECT stopdate
            INTO v_stopdate
            FROM loans
            WHERE signature = p_signature
              AND user_id = v_user_id
              AND return IS NULL
              AND type = 'L'; -- Solo préstamos, no reservas

        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                DBMS_OUTPUT.PUT_LINE('ERROR: El usuario ' || v_user_id || ' (' || v_name || ' ' || v_surname || ') ' || 'no tiene ningún préstamo activo con la copia ' ||
                                     p_signature);
                RETURN;
        END;

        -----------------------------------------------------------------------
        -- (3) Registrar la devolución
        -----------------------------------------------------------------------
        UPDATE loans
        SET return = SYSDATE
        WHERE signature = p_signature
          AND user_id = v_user_id
          AND return IS NULL
          AND type = 'L';

        IF SQL%ROWCOUNT = 0 THEN -- Validar que el UPDATE realmente afectó a 1 fila (con %ROWCOUNT) esto ya es pro... no haría falta, pero aquí lo dejo por si acaso
            DBMS_OUTPUT.PUT_LINE('Aviso --> El préstamo ya había sido devuelto anteriormente.');
        ELSE
            DBMS_OUTPUT.PUT_LINE('Devolución registrada --> copia ' || p_signature || ' por usuario ' || v_user_id || ' (' || v_name || ' ' || v_surname || ')' || ' con fecha ' ||
                                 TO_CHAR(SYSDATE, 'DD/MM/YYYY'));
        END IF;

    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('ERROR inesperado en insertar_devolucion: ' || SQLERRM);
    END insertar_devolucion;

END foundicu;
/
COMMIT;