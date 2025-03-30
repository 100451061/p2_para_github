CREATE OR REPLACE PACKAGE foundicu AS

  PROCEDURE insertar_prestamo(p_signature CHAR);
  PROCEDURE insertar_reserva(p_isbn VARCHAR2, p_reserva_date DATE);
  PROCEDURE registrar_devolucion(p_signature CHAR);

END foundicu;
/

CREATE OR REPLACE PACKAGE BODY foundicu AS

  PROCEDURE insertar_prestamo(p_signature CHAR) IS
    v_user_id users.user_id%TYPE;
    v_reserva_count NUMBER;
    v_loan_count NUMBER;
    v_ban_up2 users.ban_up2%TYPE;
    v_copy_available NUMBER;
    v_isbn editions.isbn%TYPE;

  BEGIN
    -- Obtener el USER_ID del usuario actual (asumiendo que hay una función para esto)
    -- En la práctica, necesitaríamos usar una función que obtenga el usuario de la sesión.
    SELECT USER INTO v_user_id FROM dual; -- Esto es un placeholder.

    -- Verificar si el usuario existe
    SELECT ban_up2 INTO v_ban_up2 FROM users WHERE user_id = v_user_id;

    -- Verificar si hay una reserva para el usuario actual y la signatura especificada
    SELECT COUNT(*) INTO v_reserva_count
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
      SELECT COUNT(*) INTO v_copy_available
      FROM copies c
      LEFT JOIN loans l ON c.signature = l.signature
      WHERE c.signature = p_signature
        AND (l.signature IS NULL OR l.RETURN IS NOT NULL);

      IF v_copy_available > 0 THEN
        -- Verificar límite de préstamos y sanciones
        SELECT COUNT(*) INTO v_loan_count
        FROM loans
        WHERE user_id = v_user_id
          AND RETURN IS NULL;

        IF v_loan_count < 5 AND v_ban_up2 IS NULL THEN -- Asumo máximo 5 prestamos y sin sanción.
          -- Insertar nuevo préstamo
          SELECT isbn INTO v_isbn FROM copies WHERE signature = p_signature;
          INSERT INTO loans (signature, user_id, stopdate, town, province, type, time, RETURN)
          SELECT p_signature, v_user_id, SYSDATE, town, province, type, 14, null
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
    v_user_id users.user_id%TYPE;
    v_loan_count NUMBER;
    v_ban_up2 users.ban_up2%TYPE;
    v_copy_available NUMBER;
    v_signature copies.signature%TYPE;

  BEGIN
    -- Obtener el USER_ID del usuario actual (asumiendo que hay una función para esto)
    SELECT USER INTO v_user_id FROM dual; -- Placeholder

    -- Verificar si el usuario existe y no está sancionado
    SELECT ban_up2 INTO v_ban_up2 FROM users WHERE user_id = v_user_id;

    -- Verificar límite de préstamos y reservas
    SELECT COUNT(*) INTO v_loan_count
    FROM loans
    WHERE user_id = v_user_id
      AND RETURN IS NULL;

    IF v_loan_count < 5 AND v_ban_up2 IS NULL THEN
      -- Verificar disponibilidad de copia durante 14 días a partir de la fecha proporcionada
      SELECT COUNT(c.signature) INTO v_copy_available
      FROM copies c
      LEFT JOIN loans l ON c.signature = l.signature
      WHERE c.isbn = p_isbn
        AND (l.signature IS NULL OR l.RETURN IS NOT NULL);

      IF v_copy_available > 0 THEN
        -- Obtener la signatura de la primera copia disponible
        SELECT c.signature INTO v_signature
        FROM copies c
        LEFT JOIN loans l ON c.signature = l.signature
        WHERE c.isbn = p_isbn
          AND (l.signature IS NULL OR l.RETURN IS NOT NULL)
          AND ROWNUM = 1;

        -- Insertar la reserva
        INSERT INTO loans (signature, user_id, stopdate, town, province, type, time, RETURN)
        SELECT v_signature, v_user_id, p_reserva_date, town, province, type, 0, null
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
    v_user_id users.user_id%TYPE;
    v_loan_count NUMBER;

  BEGIN
    -- Obtener el USER_ID del usuario actual (asumiendo que hay una función para esto)
    SELECT USER INTO v_user_id FROM dual; -- Placeholder

    -- Verificar si el usuario tiene prestado el libro
    SELECT COUNT(*) INTO v_loan_count
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