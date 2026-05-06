--SP_OBTENER_CALIFICACION_PERSONA
create or replace PROCEDURE SP_REGISTRAR_CALIF (
    p_idPerson   IN VARCHAR2,
    p_rating IN VARCHAR2,
    p_notes       IN VARCHAR2,
    p_modifiedBy  IN VARCHAR2
) AS
BEGIN
    UPDATE person
    SET notes      = p_notes,
        modifiedBy = p_modifiedBy,
        modifiedAt = CURRENT_TIMESTAMP
    WHERE id = TO_NUMBER(p_idPerson);
    COMMIT;
END SP_REGISTRAR_CALIF;
--SP_EXISTE_CATALOGO
create or replace PROCEDURE SP_EXISTE_CATALOGO (
    p_tabla  IN  VARCHAR2,
    p_valor  IN  VARCHAR2,
    p_existe OUT NUMBER
) AS
BEGIN
    IF UPPER(p_tabla) = 'QUESTION' THEN
        EXECUTE IMMEDIATE
            'SELECT COUNT(*) FROM ' || p_tabla || ' WHERE UPPER(text) = UPPER(:1)'
            INTO p_existe
            USING p_valor;
    ELSE
        EXECUTE IMMEDIATE
            'SELECT COUNT(*) FROM ' || p_tabla || ' WHERE UPPER(name) = UPPER(:1)'
            INTO p_existe
            USING p_valor;
        END IF;
END SP_EXISTE_CATALOGO;

--SP_ACTUALIZAR_PERSONA
create or replace PROCEDURE SP_ACTUALIZAR_PERSONA (
    p_id            IN NUMBER,
    p_firstName     IN VARCHAR2,
    p_secondName    IN VARCHAR2,
    p_firstSurname  IN VARCHAR2,
    p_secondSurname IN VARCHAR2,
    p_notes         IN VARCHAR2,
    p_rating        IN NUMBER,
    p_updatedBy     IN VARCHAR2,
    p_idBlackList   IN NUMBER
) AS
BEGIN
    UPDATE Person
    SET firstName = NVL(p_firstName, firstName),
        secondName = NVL(p_secondName, secondName),
        firstSurname = NVL(p_firstSurname, firstSurname),
        secondSurname = NVL(p_secondSurname, secondSurname),
        notes = NVL(p_notes, notes),
        rating = NVL(p_rating, rating),
        modifiedBy = NVL(p_updatedBy, USER),
        idBlacklist = NVL(p_idBlackList, idBlacklist),
        modifiedAt = CURRENT_TIMESTAMP
    WHERE id = p_id;

    COMMIT;
END SP_ACTUALIZAR_PERSONA;
--
CREATE OR REPLACE PROCEDURE SP_MARCAR_HALLADA (
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
    
    DELETE FROM Pet WHERE id = TO_NUMBER(p_idFoundPet);
    
    p_resultado := v_update_count;
    
    COMMIT;
END SP_MARCAR_HALLADA;
--
CREATE OR REPLACE PROCEDURE SP_REGISTRAR_REQUEST (
    p_idPet      IN  VARCHAR2,
    p_idPerson   IN  VARCHAR2,
    p_createdBy  IN  VARCHAR2,
    p_idRequest  OUT NUMBER,
    p_result     OUT NUMBER
) AS
    v_idRequest NUMBER;
    v_idStatus  NUMBER;
    v_idState   NUMBER;
BEGIN
    SELECT id INTO v_idStatus FROM Status
    WHERE UPPER(name) = 'PENDIENTE' AND ROWNUM = 1;

    INSERT INTO AdoptionRequest (
    id, idStatus, idPet, idPerson,
    createdBy, createdAt, modifiedBy, modifiedAt
        ) VALUES (
    SEQ_ADOPTIONREQUEST.NEXTVAL, v_idStatus,
    TO_NUMBER(p_idPet), TO_NUMBER(p_idPerson),
    p_createdBy, CURRENT_TIMESTAMP,
    p_createdBy, CURRENT_TIMESTAMP
        ) RETURNING id INTO v_idRequest;

    SELECT id INTO v_idState FROM State
    WHERE UPPER(name) = 'EN ADOPCION' AND ROWNUM = 1;

    UPDATE Pet SET idState = v_idState
    WHERE id = TO_NUMBER(p_idPet);

    p_idRequest := v_idRequest;
    p_result    := 0;
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN ROLLBACK; p_result := 1; p_idRequest := -1;
END SP_REGISTRAR_REQUEST;
/
--
CREATE OR REPLACE PROCEDURE SP_OBTENER_DETALLE_SOLICITUD(
    p_id_solicitud IN NUMBER,
    p_cursor_solicitud OUT SYS_REFCURSOR,
    p_cursor_preguntas OUT SYS_REFCURSOR
) AS
BEGIN
    OPEN p_cursor_solicitud FOR
        SELECT ar.id,
               ar.idPet,
               ar.idPerson,
               p.name AS pet_name,
               pe.firstName || ' ' || pe.firstSurname AS adoptant_name,
               s.name AS status_name,
               ar.createdAt,
               ar.createdBy
        FROM AdoptionRequest ar
        JOIN Pet p ON p.id = ar.idPet
        JOIN Person pe ON pe.id = ar.idPerson
        JOIN Status s ON s.id = ar.idStatus
        WHERE ar.id = p_id_solicitud;

    OPEN p_cursor_preguntas FOR
        SELECT q.id AS question_id,
               q.text AS question_text,
               a.value AS answer_value
        FROM Answer a
        JOIN Question q ON q.id = a.idQuestion
        WHERE a.idAdoptionRequest = p_id_solicitud  
        ORDER BY q.id;
END SP_OBTENER_DETALLE_SOLICITUD;
/
--
CREATE OR REPLACE PROCEDURE SP_CONSULTAR_SOLICITUDES (
    p_from         IN  DATE,
    p_until        IN  DATE,
    p_idPet        IN  VARCHAR2,
    p_idAdoptant   IN  VARCHAR2,
    p_cursor       OUT SYS_REFCURSOR,
    p_total        OUT NUMBER
) AS
BEGIN
    SELECT COUNT(*) INTO p_total
    FROM AdoptionRequest ar
    WHERE (p_from       IS NULL OR ar.createdAt >= p_from)
      AND (p_until      IS NULL OR ar.createdAt <= p_until)
      AND (p_idPet      IS NULL OR TO_CHAR(ar.idPet) = p_idPet)
      AND (p_idAdoptant IS NULL OR TO_CHAR(ar.idPerson) = p_idAdoptant);

    OPEN p_cursor FOR
        SELECT 
            ar.id,
            ar.idPet,
            ar.idPerson,
            (SELECT p.name FROM Pet p WHERE p.id = ar.idPet) AS pet,
            (SELECT pe.firstName || ' ' || pe.firstSurname FROM Person pe WHERE pe.id = ar.idPerson) AS adoptant,
            ar.createdAt AS request_date,
            (SELECT s.name FROM Status s WHERE s.id = ar.idStatus) AS status
        FROM AdoptionRequest ar
        WHERE (p_from       IS NULL OR ar.createdAt >= p_from)
          AND (p_until      IS NULL OR ar.createdAt <= p_until)
          AND (p_idPet      IS NULL OR TO_CHAR(ar.idPet) = p_idPet)
          AND (p_idAdoptant IS NULL OR TO_CHAR(ar.idPerson) = p_idAdoptant)
        ORDER BY ar.createdAt DESC;
END SP_CONSULTAR_SOLICITUDES;
/
--
CREATE OR REPLACE PROCEDURE SP_CONSULTAR_ADOPS (
    p_from         IN  DATE,
    p_until        IN  DATE,
    p_idPet        IN  VARCHAR2,
    p_idAdoptant   IN  VARCHAR2,
    p_cursor       OUT SYS_REFCURSOR,
    p_total        OUT NUMBER
) AS
BEGIN
    SELECT COUNT(*) INTO p_total
    FROM Adoption a
    JOIN Pet p       ON p.id  = a.idPet
    JOIN Person pe   ON pe.id = a.idPerson
    WHERE (p_from       IS NULL OR a.adoptionDate >= p_from)
      AND (p_until      IS NULL OR a.adoptionDate <= p_until)
      AND (p_idPet      IS NULL OR a.idPet    = TO_NUMBER(p_idPet))
      AND (p_idAdoptant IS NULL OR a.idPerson = TO_NUMBER(p_idAdoptant));

    OPEN p_cursor FOR
        SELECT
            a.id,
            a.idPet,
            a.idPerson,
            p.name   AS pet,
            pe.firstName || ' ' || pe.firstSurname AS adoptant,
            a.adoptionDate AS adopt_date
        FROM Adoption a
        JOIN Pet p       ON p.id  = a.idPet
        JOIN Person pe   ON pe.id = a.idPerson
        WHERE (p_from       IS NULL OR a.adoptionDate >= p_from)
          AND (p_until      IS NULL OR a.adoptionDate <= p_until)
          AND (p_idPet      IS NULL OR a.idPet    = TO_NUMBER(p_idPet))
          AND (p_idAdoptant IS NULL OR a.idPerson = TO_NUMBER(p_idAdoptant))
        ORDER BY a.adoptionDate DESC;
END SP_CONSULTAR_ADOPS;
/
--
CREATE OR REPLACE PROCEDURE SP_EJECUTAR_MATCH AS
    v_idStatus NUMBER;
    v_idLostState NUMBER;
    v_idFoundState NUMBER;
BEGIN
    SELECT id INTO v_idStatus FROM MatchStatus WHERE UPPER(name) = 'PENDIENTE' AND ROWNUM = 1;
    SELECT id INTO v_idLostState FROM State WHERE UPPER(name) = 'PERDIDA' AND ROWNUM = 1;
    SELECT id INTO v_idFoundState FROM State WHERE UPPER(name) = 'HALLADA' AND ROWNUM = 1;

    INSERT INTO Match (
        id, lostPetID, foundPetID, idMatchStatus,
        matchDate, similarityPercentage,
        createdBy, createdAt, modifiedBy, modifiedAt
    )
    SELECT
        SEQ_MATCH.NEXTVAL,
        lost.id,
        found.id,
        v_idStatus,
        SYSDATE,
        (
            CASE WHEN NVL(lost.idBreed, -1)    = NVL(found.idBreed, -1)    THEN 40 ELSE 0 END +
            CASE WHEN NVL(lost.idColour, -1)   = NVL(found.idColour, -1)   THEN 30 ELSE 0 END +
            CASE WHEN NVL(lost.idSeverity, -1) = NVL(found.idSeverity, -1) THEN 15 ELSE 0 END +
            CASE WHEN NVL(lost.idDistrict, -1) = NVL(found.idDistrict, -1) THEN 15 ELSE 0 END
        ),
        'SYSTEM', CURRENT_TIMESTAMP, 'SYSTEM', CURRENT_TIMESTAMP
    FROM Pet lost
    CROSS JOIN Pet found
    WHERE lost.idState = v_idLostState
      AND found.idState = v_idFoundState
      AND NOT EXISTS (
        SELECT 1 FROM Match m
        WHERE m.lostPetID = lost.id
          AND m.foundPetID = found.id
    );
    COMMIT;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20001, 'No se encontraron los estados necesarios (PERDIDA/HALLADA/MatchStatus)');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END SP_EJECUTAR_MATCH;
/
--
CREATE OR REPLACE PROCEDURE SP_CONSULTAR_MATCHES (
    p_idMascotaPerdida IN VARCHAR2,
    p_idTipo           IN VARCHAR2,
    p_idRaza           IN VARCHAR2,
    p_nombre           IN VARCHAR2,
    p_idChip           IN VARCHAR2,
    p_idColor          IN VARCHAR2,
    p_idEstado         IN VARCHAR2,
    p_idProvincia      IN VARCHAR2,
    p_idCanton         IN VARCHAR2,
    p_idDistrito       IN VARCHAR2,
    p_idAsociacion     IN VARCHAR2,
    p_start_date       IN DATE,      
    p_end_date         IN DATE,      
    p_cursor           OUT SYS_REFCURSOR,
    p_total            OUT NUMBER
) AS
BEGIN
    SELECT COUNT(*) INTO p_total
    FROM Match m
    JOIN Pet pp         ON pp.id = m.lostPetID
    JOIN Pet ph         ON ph.id = m.foundPetID
    LEFT JOIN Breed b        ON b.id  = pp.idBreed
    LEFT JOIN PetType pt     ON pt.id = b.idPetType
    LEFT JOIN Colour col     ON col.id = pp.idColour
    LEFT JOIN Chip ch        ON ch.petID = pp.id
    JOIN MatchStatus ms      ON ms.id = m.idMatchStatus 
    LEFT JOIN District d     ON d.id   = pp.idDistrict
    LEFT JOIN Canton can     ON can.id = d.idCanton
    LEFT JOIN Province pr    ON pr.id  = can.idProvince
    LEFT JOIN Association a  ON a.id   = pp.idAssociation
    WHERE (p_idMascotaPerdida IS NULL OR m.lostPetID      = TO_NUMBER(p_idMascotaPerdida))
      AND (p_idTipo           IS NULL OR pt.id            = TO_NUMBER(p_idTipo))
      AND (p_idRaza           IS NULL OR b.id             = TO_NUMBER(p_idRaza))
      AND (p_nombre           IS NULL OR UPPER(pp.name)   LIKE '%' || UPPER(p_nombre) || '%')
      AND (p_idChip           IS NULL OR TO_CHAR(ch.chipNumber) LIKE '%' || p_idChip || '%')
      AND (p_idColor          IS NULL OR col.id           = TO_NUMBER(p_idColor))
      AND (p_idEstado         IS NULL OR ms.id            = TO_NUMBER(p_idEstado))
      AND (p_idProvincia      IS NULL OR pr.id            = TO_NUMBER(p_idProvincia))
      AND (p_idCanton         IS NULL OR can.id           = TO_NUMBER(p_idCanton))
      AND (p_idDistrito       IS NULL OR d.id             = TO_NUMBER(p_idDistrito))
      AND (p_idAsociacion     IS NULL OR a.id             = TO_NUMBER(p_idAsociacion))
      AND (p_start_date       IS NULL OR m.matchDate      >= p_start_date)
      AND (p_end_date         IS NULL OR m.matchDate      <= p_end_date);

    OPEN p_cursor FOR
        SELECT
            m.id,
            pp.name                AS mascota_perdida,
            ph.name                AS mascota_hallada,
            pt.name                AS tipo,
            b.name                 AS raza,
            col.name               AS color,
            m.similarityPercentage AS similitud,
            ms.name                AS estado_match,
            ch.chipNumber          AS chip,
            m.matchDate            AS fecha_match
        FROM Match m
        JOIN Pet pp         ON pp.id = m.lostPetID
        JOIN Pet ph         ON ph.id = m.foundPetID
        LEFT JOIN Breed b        ON b.id  = pp.idBreed
        LEFT JOIN PetType pt     ON pt.id = b.idPetType
        LEFT JOIN Colour col     ON col.id = pp.idColour
        JOIN MatchStatus ms      ON ms.id = m.idMatchStatus
        LEFT JOIN Chip ch        ON ch.petID = pp.id
        LEFT JOIN District d     ON d.id   = pp.idDistrict
        LEFT JOIN Canton can     ON can.id = d.idCanton
        LEFT JOIN Province pr    ON pr.id  = can.idProvince
        LEFT JOIN Association a  ON a.id   = pp.idAssociation
        WHERE (p_idMascotaPerdida IS NULL OR m.lostPetID      = TO_NUMBER(p_idMascotaPerdida))
          AND (p_idTipo           IS NULL OR pt.id            = TO_NUMBER(p_idTipo))
          AND (p_idRaza           IS NULL OR b.id             = TO_NUMBER(p_idRaza))
          AND (p_nombre           IS NULL OR UPPER(pp.name)   LIKE '%' || UPPER(p_nombre) || '%')
          AND (p_idChip           IS NULL OR TO_CHAR(ch.chipNumber) LIKE '%' || p_idChip || '%')
          AND (p_idColor          IS NULL OR col.id           = TO_NUMBER(p_idColor))
          AND (p_idEstado         IS NULL OR ms.id            = TO_NUMBER(p_idEstado))
          AND (p_idProvincia      IS NULL OR pr.id            = TO_NUMBER(p_idProvincia))
          AND (p_idCanton         IS NULL OR can.id           = TO_NUMBER(p_idCanton))
          AND (p_idDistrito       IS NULL OR d.id             = TO_NUMBER(p_idDistrito))
          AND (p_idAsociacion     IS NULL OR a.id             = TO_NUMBER(p_idAsociacion))
          AND (p_start_date       IS NULL OR m.matchDate      >= p_start_date)
          AND (p_end_date         IS NULL OR m.matchDate      <= p_end_date)
        ORDER BY m.matchDate DESC;
END SP_CONSULTAR_MATCHES;
/
--
CREATE OR REPLACE PROCEDURE SP_OBTENER_DETALLE_SOLICITUD(
    p_id_solicitud IN NUMBER,
    p_cursor_solicitud OUT SYS_REFCURSOR,
    p_cursor_preguntas OUT SYS_REFCURSOR
) AS
BEGIN
    OPEN p_cursor_solicitud FOR
        SELECT ar.id,
               ar.idPet,
               ar.idPerson,
               p.name AS pet_name,
               per.firstName || ' ' || per.firstSurname AS adoptant_name,
               s.name AS status_name,
               ar.notes,
               ar.photo,
               ar.photoNew,
               ar.createdAt,
               ar.createdBy
        FROM AdoptionRequest ar
        JOIN Pet p ON p.id = ar.idPet
        JOIN Person per ON per.id = ar.idPerson
        JOIN Status s ON s.id = ar.idStatus
        WHERE ar.id = p_id_solicitud;

    OPEN p_cursor_preguntas FOR
        SELECT q.id AS question_id,
               q.text AS question_text,
               a.value AS answer_value
        FROM Answer a
        JOIN Question q ON q.id = a.idQuestion
        WHERE a.idAdoptionRequest = p_id_solicitud
        ORDER BY q.id;
END;
/
--
CREATE OR REPLACE PROCEDURE SP_GESTIONAR_SOLICITUD (
    p_idSolicitud IN  NUMBER,
    p_idPet       IN  NUMBER,
    p_idPerson    IN  NUMBER,
    p_photo       IN  BLOB,
    p_notas       IN  VARCHAR2,
    p_nuevoEstado IN  NUMBER,
    p_usuario     IN  VARCHAR2,
    p_resultado   OUT NUMBER
) AS
    v_idEstadoAprobado NUMBER;
    v_idEstadoRechazado NUMBER;
    v_idAdoption       NUMBER;
    v_idEstadoAdoptado NUMBER;
    v_idEstadoEnAdopcion NUMBER;
BEGIN
    SELECT id INTO v_idEstadoAprobado FROM Status WHERE UPPER(name) = 'APROBADA' AND ROWNUM = 1;
    SELECT id INTO v_idEstadoRechazado FROM Status WHERE UPPER(name) = 'RECHAZADA' AND ROWNUM = 1;
    SELECT id INTO v_idEstadoAdoptado FROM State WHERE UPPER(name) = 'ADOPTADO' AND ROWNUM = 1;
    SELECT id INTO v_idEstadoEnAdopcion FROM State WHERE UPPER(name) = 'EN ADOPCION' AND ROWNUM = 1;

    UPDATE AdoptionRequest
    SET IDSTATUS   = p_nuevoEstado,
        MODIFIEDBY = p_usuario,
        MODIFIEDAT = CURRENT_TIMESTAMP
    WHERE ID = p_idSolicitud;

    IF SQL%ROWCOUNT = 0 THEN
        p_resultado := 1;  
        RETURN;
    END IF;

    IF p_nuevoEstado = v_idEstadoAprobado THEN
        INSERT INTO Adoption (
            ID, IDPET, IDPERSON, NOTES, PHOTO, ADOPTIONDATE,
            CREATEDBY, CREATEDAT, MODIFIEDBY, MODIFIEDAT
        ) VALUES (
            SEQ_ADOPTION.NEXTVAL,
            p_idPet,
            p_idPerson,
            p_notas,
            p_photo,
            CURRENT_TIMESTAMP,
            p_usuario, CURRENT_TIMESTAMP,
            p_usuario, CURRENT_TIMESTAMP
        ) RETURNING ID INTO v_idAdoption;

        UPDATE AdoptionRequest
        SET IDADOPTION = v_idAdoption
        WHERE ID = p_idSolicitud;

        UPDATE Pet
        SET IDSTATE = v_idEstadoAdoptado,
            MODIFIEDBY = p_usuario,
            MODIFIEDAT = CURRENT_TIMESTAMP
        WHERE ID = p_idPet;

    ELSIF p_nuevoEstado = v_idEstadoRechazado THEN
        UPDATE Pet
        SET IDSTATE = v_idEstadoEnAdopcion,
            MODIFIEDBY = p_usuario,
            MODIFIEDAT = CURRENT_TIMESTAMP
        WHERE ID = p_idPet;
    END IF;

    p_resultado := 0;
    COMMIT;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        ROLLBACK;
        p_resultado := 2;  
    WHEN OTHERS THEN
        ROLLBACK;
        p_resultado := 1;
        RAISE;
END SP_GESTIONAR_SOLICITUD;
/
--
CREATE OR REPLACE PROCEDURE SP_GET_DETALLES_PET (
    p_id_pet IN NUMBER,
    p_record OUT SYS_REFCURSOR
) AS
BEGIN
    OPEN p_record FOR
        SELECT 
            p.id, 
            p.name, 
            pt.name AS tipo, 
            b.name AS raza, 
            col.name AS color,
            chp.CHIPNUMBER AS chip, 
            st.name AS estado, 
            sev.name AS severidad, 
            en.name AS nivel_energia,
            p.pet_size AS tamanio, 
            p.requiresMuchSpace AS requiere_espacio,
            p.telephone, 
            p.email,
            pr.name || ', ' || can.name || ', ' || d.name AS ubicacion,
            per.firstName || ' ' || per.firstSurname AS rescatista,
            a.name AS asociacion,
            pv.firstName || ' ' || pv.firstSurname AS veterinario,
            pc.firstName || ' ' || pc.firstSurname AS casa_cuna,
            td.name AS dificultad,
            TO_CHAR(p.loss_date, 'DD/MM/YYYY') AS fecha_perdida,
            TO_CHAR(p.foundDate, 'DD/MM/YYYY') AS fecha_hallada,
            p.abandonSituationDescription, 
            p.descriptionNotes,
            p.beforePicture, 
            p.afterPicture
        FROM Pet p
        JOIN Breed b ON b.id = p.idBreed
        JOIN PetType pt ON pt.id = b.idPetType
        LEFT JOIN CHIP chp ON chp.PETID = p.id 
        LEFT JOIN Colour col ON col.id = p.idColour
        LEFT JOIN State st ON st.id = p.idState
        LEFT JOIN Severity sev ON sev.id = p.idSeverity
        LEFT JOIN EnergyLevel en ON en.id = p.idEnergyLevel
        LEFT JOIN District d ON d.id = p.idDistrict
        LEFT JOIN Canton can ON can.id = d.idCanton
        LEFT JOIN Province pr ON pr.id = can.idProvince
        LEFT JOIN Rescuer r ON r.id = p.idRescuer
        LEFT JOIN Person per ON per.id = r.id
        LEFT JOIN Association a ON a.id = p.idAssociation
        LEFT JOIN Veterinarian v ON v.id = p.idVeterinarian
        LEFT JOIN Person pv ON pv.id = v.id
        LEFT JOIN CribHouse cnh ON cnh.id = p.idCribHouse
        LEFT JOIN Person pc ON pc.id = cnh.id
        LEFT JOIN TrainingDifficulty td ON td.id = p.idTrainingDifficulty
        WHERE p.id = p_id_pet;
END SP_GET_DETALLES_PET;
/
--JOB
BEGIN
  DBMS_SCHEDULER.CREATE_JOB (
    job_name        => 'JOB_EJECUTAR_MATCH',
    job_type        => 'STORED_PROCEDURE',
    job_action      => 'SP_EJECUTAR_MATCH',
    start_date      => SYSTIMESTAMP,
    repeat_interval => 'FREQ=HOURLY; INTERVAL=4', 
    enabled         => TRUE,
    comments        => 'Job para hacer matches de mascotas perdidas'
  );
END;
/
--alter adopreq
ALTER TABLE AdoptionRequest ADD idPet    NUMBER;
ALTER TABLE AdoptionRequest ADD idPerson NUMBER;
ALTER TABLE AdoptionRequest ADD CONSTRAINT fk_ar_pet    FOREIGN KEY (idPet)    REFERENCES Pet(id);
ALTER TABLE AdoptionRequest ADD CONSTRAINT fk_ar_person FOREIGN KEY (idPerson) REFERENCES Person(id);

--Secs faltantes
CREATE SEQUENCE SEQ_COLOUR START WITH 1 INCREMENT BY 1 NOCYCLE CACHE 20;
CREATE SEQUENCE SEQ_PETTYPE START WITH 1 INCREMENT BY 1 NOCYCLE CACHE 20;
CREATE SEQUENCE SEQ_BREED START WITH 1 INCREMENT BY 1 NOCYCLE CACHE 20;
CREATE SEQUENCE SEQ_SEVERITY START WITH 1 INCREMENT BY 1 NOCYCLE CACHE 20;
CREATE SEQUENCE SEQ_ENERGYLEVEL START WITH 1 INCREMENT BY 1 NOCYCLE CACHE 20;
CREATE SEQUENCE SEQ_TRAININGDIFFICULTY START WITH 1 INCREMENT BY 1 NOCYCLE CACHE 20;
CREATE SEQUENCE SEQ_CURRENCY START WITH 1 INCREMENT BY 1 NOCYCLE CACHE 20;
CREATE SEQUENCE SEQ_DISEASE START WITH 1 INCREMENT BY 1 NOCYCLE CACHE 20;
CREATE SEQUENCE SEQ_TREATMENT START WITH 1 INCREMENT BY 1 NOCYCLE CACHE 20;
CREATE SEQUENCE SEQ_MEDICATION START WITH 1 INCREMENT BY 1 NOCYCLE CACHE 20;
