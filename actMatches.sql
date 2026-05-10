
create or replace PROCEDURE SP_CONSULTAR_MASCOTAS (
    p_type         IN VARCHAR2,
    p_breed        IN VARCHAR2,
    p_name         IN VARCHAR2,
    p_chip         IN VARCHAR2,
    p_rescuer      IN VARCHAR2,
    p_status       IN VARCHAR2,
    p_color        IN VARCHAR2,
    p_province     IN VARCHAR2,
    p_canton       IN VARCHAR2,
    p_district     IN VARCHAR2,
    p_association  IN VARCHAR2,
    p_start_date   IN DATE,
    p_end_date     IN DATE,
    p_cursor       OUT SYS_REFCURSOR,
    p_total        OUT NUMBER
) AS
BEGIN
  
    SELECT COUNT(DISTINCT p.id) INTO p_total
    FROM Pet p
    JOIN Breed b            ON b.id     = p.idBreed
    JOIN PetType pt         ON pt.id    = b.idPetType
    JOIN Colour c            ON c.id     = p.idColour
    JOIN State st            ON st.id    = p.idState
    JOIN District d         ON d.id     = p.idDistrict
    JOIN Canton can         ON can.id   = d.idCanton
    JOIN Province pr        ON pr.id    = can.idProvince
    LEFT JOIN Rescuer r     ON r.id     = p.idRescuer
    LEFT JOIN Association a ON a.id     = p.idAssociation
    LEFT JOIN Chip ch        ON ch.petId = p.id
    WHERE st.name <> 'PROCESADA' 
      AND (p_type         IS NULL OR pt.id  = TO_NUMBER(p_type))
      AND (p_breed        IS NULL OR b.id   = TO_NUMBER(p_breed))
      AND (p_name         IS NULL OR UPPER(p.name)        LIKE '%' || UPPER(p_name)  || '%')
      AND (p_chip         IS NULL OR UPPER(ch.chipNumber) LIKE '%' || UPPER(p_chip) || '%')
      AND (p_rescuer      IS NULL OR r.id   = TO_NUMBER(p_rescuer))
      AND (p_status       IS NULL OR st.id  = TO_NUMBER(p_status))
      AND (p_color        IS NULL OR c.id   = TO_NUMBER(p_color))
      AND (p_province     IS NULL OR pr.id  = TO_NUMBER(p_province))
      AND (p_canton       IS NULL OR can.id = TO_NUMBER(p_canton))
      AND (p_district     IS NULL OR d.id   = TO_NUMBER(p_district))
      AND (p_association  IS NULL OR a.id   = TO_NUMBER(p_association))
      AND (p_start_date   IS NULL OR TRUNC(p.createdat) >= TRUNC(p_start_date))
      AND (p_end_date     IS NULL OR TRUNC(p.createdat) <= TRUNC(p_end_date));

    OPEN p_cursor FOR
        SELECT DISTINCT
            p.id,
            p.name                                          AS nombre,
            pt.name                                         AS tipo,
            b.name                                          AS raza,
            c.name                                          AS color,
            ch.chipNumber                                   AS chip,
            st.name                                         AS estado,
            TRUNC(p.createdat)                              AS fecha_registro,
            pr.name || ', ' || can.name || ', ' || d.name AS ubicacion,
            per.firstName || ' ' || per.firstSurname      AS rescatista,
            a.name                                          AS asociacion
        FROM Pet p
        LEFT JOIN Breed b            ON b.id     = p.idBreed
        LEFT JOIN PetType pt         ON pt.id    = b.idPetType
        LEFT JOIN Colour c            ON c.id     = p.idColour
        LEFT JOIN State st            ON st.id    = p.idState
        LEFT JOIN District d         ON d.id     = p.idDistrict
        LEFT JOIN Canton can         ON can.id   = d.idCanton
        LEFT JOIN Province pr        ON pr.id    = can.idProvince
        LEFT JOIN Rescuer r          ON r.id     = p.idRescuer
        LEFT JOIN Person per         ON per.id    = r.id
        LEFT JOIN Association a      ON a.id     = p.idAssociation
        LEFT JOIN Chip ch            ON ch.petId = p.id
        WHERE st.name <> 'PROCESADA' 
          AND (p_type         IS NULL OR pt.id  = TO_NUMBER(p_type))
          AND (p_breed        IS NULL OR b.id   = TO_NUMBER(p_breed))
          AND (p_name         IS NULL OR UPPER(p.name)        LIKE '%' || UPPER(p_name)  || '%')
          AND (p_chip         IS NULL OR UPPER(ch.chipNumber) LIKE '%' || UPPER(p_chip) || '%')
          AND (p_rescuer      IS NULL OR r.id   = TO_NUMBER(p_rescuer))
          AND (p_status       IS NULL OR st.id  = TO_NUMBER(p_status))
          AND (p_color        IS NULL OR c.id   = TO_NUMBER(p_color))
          AND (p_province     IS NULL OR pr.id  = TO_NUMBER(p_province))
          AND (p_canton       IS NULL OR can.id = TO_NUMBER(p_canton))
          AND (p_district     IS NULL OR d.id   = TO_NUMBER(p_district))
          AND (p_association  IS NULL OR a.id   = TO_NUMBER(p_association))
          AND (p_start_date   IS NULL OR TRUNC(p.createdat) >= TRUNC(p_start_date))
          AND (p_end_date     IS NULL OR TRUNC(p.createdat) <= TRUNC(p_end_date))
        ORDER BY fecha_registro DESC;
END SP_CONSULTAR_MASCOTAS
;

create or replace PROCEDURE SP_MARCAR_HALLADA (
    p_idPet      IN  VARCHAR2,
    p_idFoundPet IN  VARCHAR2,
    p_modifiedBy IN  VARCHAR2,
    p_resultado  OUT NUMBER
) AS
    v_update_count NUMBER;
BEGIN

    UPDATE Pet 
    SET idState = (SELECT id FROM State WHERE UPPER(name) = 'HALLADA'),
        modifiedBy = p_modifiedBy,
        modifiedAt = CURRENT_TIMESTAMP
    WHERE id = TO_NUMBER(p_idPet);
    
    v_update_count := SQL%ROWCOUNT;

    UPDATE Pet 
    SET idState = (SELECT id FROM State WHERE UPPER(name) = 'PROCESADA'),
        modifiedBy = p_modifiedBy,
        modifiedAt = CURRENT_TIMESTAMP
    WHERE id = TO_NUMBER(p_idFoundPet); 
    
    p_resultado := v_update_count;
    
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        p_resultado := 0;
END SP_MARCAR_HALLADA;