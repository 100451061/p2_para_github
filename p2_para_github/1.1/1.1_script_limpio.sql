-- 1) BoreBooks: libros con ediciones en, al menos, tres idiomas (language) distintos,
-- de los que nunca se haya prestado ninguna copia.

WITH Libros_3_Idiomas AS (SELECT title, author
                          FROM editions
                          GROUP BY title, author
                          HAVING COUNT(DISTINCT language) >= 3),

     Libros_Prestados AS (SELECT DISTINCT e.title, e.author
                          FROM editions e
                                   JOIN copies c ON e.isbn = c.isbn
                                   JOIN loans l ON c.signature = l.signature)
SELECT b.title, b.author
FROM books b
         JOIN Libros_3_Idiomas l3 ON (l3.title = b.title) AND (l3.author = b.author)

WHERE NOT EXISTS (SELECT 1
                  FROM Libros_Prestados lp
                  WHERE lp.title = b.title
                    AND lp.author = b.author);



-- 2) ) Informe de Empleados: para cada conductor, proporcionar su nombre
-- completo, edad, antigüedad de contrato (años completos), años activo (años
-- con al menos un día en carretera), número medio de paradas por año activo,
-- número medio de préstamos por año activo, y porcentaje de préstamos no
-- devueltos (con respecto al total operados por ese empleado).

WITH Años_Activos AS (SELECT a.passport,
                             COUNT(DISTINCT EXTRACT(YEAR FROM a.TASKDATE)) AS años_activos
                      FROM assign_drv a
                      GROUP BY a.passport),

     Paradas_Por_Conductor AS (SELECT a.passport,
                                      COUNT(stp.TOWN) AS total_paradas
                               FROM assign_drv a
                                        JOIN services srv ON (srv.taskdate = a.taskdate) AND (srv.passport = a.passport)
                                        JOIN stops stp ON (stp.town = srv.town) AND (stp.province = srv.province)
                               GROUP BY a.passport),

     Prestamos_Por_Conductor AS (SELECT a.passport,
                                        COUNT(l.SIGNATURE)                           AS total_prestamos,
                                        COUNT(CASE WHEN l.RETURN IS NULL THEN 1 END) AS prestamos_no_devueltos
                                 FROM assign_drv a
                                          JOIN services srv ON (srv.taskdate = a.taskdate) AND (srv.passport = a.passport)
                                          LEFT JOIN loans l ON (l.stopdate = srv.taskdate) AND (l.town = srv.town) AND (l.province = srv.province)
                                 GROUP BY a.passport)


SELECT d.FULLNAME                                                      AS nombre_completo,
       TRUNC((SYSDATE - d.birthdate) / 365.25625)                      AS edad,
       TRUNC((SYSDATE - d.cont_start) / 365.25625)                     AS antigüedad,
       NVL(a.años_activos, 0)                                          AS años_activos,
       ROUND(NVL(p.total_paradas, 0) / NULLIF(a.años_activos, 0), 2)   AS media_paradas_por_año,
       ROUND(NVL(l.total_prestamos, 0) / NULLIF(a.años_activos, 0), 2) AS media_prestamos_por_año,
       CASE
           WHEN l.total_prestamos > 0
               THEN ROUND(l.prestamos_no_devueltos / l.total_prestamos * 100, 2)
           ELSE 0
           END                                                         AS porcentaje_no_devueltos


FROM drivers d
         LEFT JOIN Años_Activos a ON (a.passport = d.passport)
         LEFT JOIN Paradas_Por_Conductor p ON (p.passport = d.passport)
         LEFT JOIN Prestamos_Por_Conductor l ON (l.passport = d.passport);
