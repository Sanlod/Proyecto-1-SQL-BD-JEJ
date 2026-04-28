ALTER TABLE BOUNTY
ADD claimed NUMBER(1)
CHECK (claimed IN (0,1));

CREATE OR REPLACE PROCEDURE SP_OBTENER_CALIF_PERSONA (
    p_idPerson IN NUMBER,
    p_cursor   OUT SYS_REFCURSOR
) AS
BEGIN
    OPEN p_cursor FOR
        SELECT rating 
        FROM Person 
        WHERE id = p_idPerson;
END SP_OBTENER_CALIF_PERSONA;
/

CREATE OR REPLACE PROCEDURE SP_REGISTRAR_TRAT_MASCOTA (
    p_idPet       IN VARCHAR2,
    p_idTreatment IN VARCHAR2,
    p_startDate   IN DATE,
    p_createdBy   IN VARCHAR2
) AS
BEGIN
    INSERT INTO PetTreatment (
        id, idPet, idTreatment, startDate,
        createdBy, createdAt
    ) VALUES (
        SEQ_PETTREATMENT.NEXTVAL,
        TO_NUMBER(p_idPet),
        TO_NUMBER(p_idTreatment),
        p_startDate,
        p_createdBy,
        CURRENT_TIMESTAMP
    );
    COMMIT;
END SP_REGISTRAR_TRAT_MASCOTA;
/


CREATE OR REPLACE PROCEDURE SP_REGISTRAR_MED_MASCOTA (
    p_idPet        IN VARCHAR2,
    p_idMedication IN VARCHAR2,
    p_dose         IN VARCHAR2,
    p_startDate    IN DATE,
    p_createdBy    IN VARCHAR2
) AS
BEGIN
    INSERT INTO PetMedication (
        id, idPet, idMedication, dose, startDate,
        createdBy, createdAt
    ) VALUES (
        SEQ_PETMEDICATION.NEXTVAL,
        TO_NUMBER(p_idPet),
        TO_NUMBER(p_idMedication),
        p_dose,
        p_startDate,
        p_createdBy,
        CURRENT_TIMESTAMP
    );
    COMMIT;
END SP_REGISTRAR_MED_MASCOTA;
/