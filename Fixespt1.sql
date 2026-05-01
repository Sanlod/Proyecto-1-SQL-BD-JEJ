-- SP_REGISTRAR_ADOPCION (correccion)
CREATE OR REPLACE PROCEDURE SP_REGISTRAR_ADOPCION (
    p_idPet        IN  VARCHAR2,
    p_idPerson     IN  VARCHAR2,
    p_notes        IN  VARCHAR2,
    p_photo        IN  BLOB,      
    p_photoNew     IN  BLOB,      
    p_createdBy    IN  VARCHAR2,
    p_result       OUT NUMBER,
    p_idRequest    OUT NUMBER
) AS
    v_idAdoption NUMBER;
    v_idStatus   NUMBER;
    v_idState    NUMBER;
    v_idRequest  NUMBER;
BEGIN
    INSERT INTO Adoption (
        id, idPet, idPerson, notes, photo, photoNew, adoptionDate,
        createdBy, createdAt, modifiedBy, modifiedAt
    ) VALUES (
        SEQ_ADOPTION.NEXTVAL,
        TO_NUMBER(p_idPet),
        TO_NUMBER(p_idPerson),
        p_notes,
        p_photo,
        p_photoNew,
        CURRENT_TIMESTAMP,
        p_createdBy, CURRENT_TIMESTAMP,
        p_createdBy, CURRENT_TIMESTAMP
    ) RETURNING id INTO v_idAdoption;

    SELECT id INTO v_idStatus FROM Status
    WHERE UPPER(name) = 'PENDIENTE' AND ROWNUM = 1;

    INSERT INTO AdoptionRequest (
        id, idStatus, idAdoption,
        createdBy, createdAt, modifiedBy, modifiedAt
    ) VALUES (
        SEQ_ADOPTIONREQUEST.NEXTVAL,
        v_idStatus,
        v_idAdoption,
        p_createdBy, CURRENT_TIMESTAMP,
        p_createdBy, CURRENT_TIMESTAMP
    ) RETURNING id INTO v_idRequest;

    p_idRequest := v_idRequest;

    SELECT id INTO v_idState FROM State
    WHERE UPPER(name) = 'EN ADOPCION' AND ROWNUM = 1;

    UPDATE Pet SET idState = v_idState WHERE id = TO_NUMBER(p_idPet);

    p_result := 0;
    COMMIT;
EXCEPTION
    WHEN NO_DATA_FOUND THEN ROLLBACK; p_result := 1; p_idRequest := -1;
    WHEN OTHERS THEN ROLLBACK; p_result := 1; p_idRequest := -1;
END SP_REGISTRAR_ADOPCION;
/
-- SP_GESTIONAR_SOLICITUD ADOPREQ (correccion)
CREATE OR REPLACE PROCEDURE SP_GESTIONAR_SOLICITUD (
    p_idSolicitud IN  VARCHAR2,
    p_nuevoEstado IN  VARCHAR2,
    p_usuario     IN  VARCHAR2,
    p_resultado   OUT NUMBER
) AS
    v_idEstadoAprobado NUMBER;
    v_idPet            NUMBER;
BEGIN
    UPDATE AdoptionRequest
    SET idStatus   = TO_NUMBER(p_nuevoEstado),
        modifiedBy = p_usuario,
        modifiedAt = CURRENT_TIMESTAMP
    WHERE id = TO_NUMBER(p_idSolicitud);

    IF SQL%ROWCOUNT = 0 THEN
        p_resultado := 1;
    ELSE
        SELECT id INTO v_idEstadoAprobado FROM Status
        WHERE UPPER(name) = 'APROBADA' AND ROWNUM = 1;

        IF TO_NUMBER(p_nuevoEstado) = v_idEstadoAprobado THEN
            SELECT a.idPet INTO v_idPet
            FROM Adoption a
            JOIN AdoptionRequest ar ON ar.idAdoption = a.id
            WHERE ar.id = TO_NUMBER(p_idSolicitud);

            UPDATE Pet SET idState = (
                SELECT id FROM State WHERE UPPER(name) = 'ADOPTADO' AND ROWNUM = 1)
            WHERE id = v_idPet;
        END IF;

        p_resultado := 0;
        COMMIT;
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        p_resultado := 1;
END SP_GESTIONAR_SOLICITUD;
/

--ESTADOS DE ADOPTION REQ 
INSERT INTO Status (id, name, createdBy, createdAt, modifiedBy, modifiedAt)
VALUES (SEQ_STATUS.NEXTVAL, 'PENDIENTE', 'SYSTEM', CURRENT_TIMESTAMP, 'SYSTEM', CURRENT_TIMESTAMP);

INSERT INTO Status (id, name, createdBy, createdAt, modifiedBy, modifiedAt)
VALUES (SEQ_STATUS.NEXTVAL, 'APROBADA', 'SYSTEM', CURRENT_TIMESTAMP, 'SYSTEM', CURRENT_TIMESTAMP);

INSERT INTO Status (id, name, createdBy, createdAt, modifiedBy, modifiedAt)
VALUES (SEQ_STATUS.NEXTVAL, 'RECHAZADA', 'SYSTEM', CURRENT_TIMESTAMP, 'SYSTEM', CURRENT_TIMESTAMP);

-- ESTADOS PET
INSERT INTO State (id, name, createdBy, createdAt, modifiedBy, modifiedAt)
VALUES (SEQ_STATE.NEXTVAL, 'PERDIDA', 'SYSTEM', CURRENT_TIMESTAMP, 'SYSTEM', CURRENT_TIMESTAMP);

INSERT INTO State (id, name, createdBy, createdAt, modifiedBy, modifiedAt)
VALUES (SEQ_STATE.NEXTVAL, 'HALLADA', 'SYSTEM', CURRENT_TIMESTAMP, 'SYSTEM', CURRENT_TIMESTAMP);

INSERT INTO State (id, name, createdBy, createdAt, modifiedBy, modifiedAt)
VALUES (SEQ_STATE.NEXTVAL, 'EN ADOPCION', 'SYSTEM', CURRENT_TIMESTAMP, 'SYSTEM', CURRENT_TIMESTAMP);

INSERT INTO State (id, name, createdBy, createdAt, modifiedBy, modifiedAt)
VALUES (SEQ_STATE.NEXTVAL, 'ADOPTADO', 'SYSTEM', CURRENT_TIMESTAMP, 'SYSTEM', CURRENT_TIMESTAMP);

COMMIT;

-- ESTADOS DE MATCH
INSERT INTO MatchStatus (id, name, createdby, createdat, modifiedby, modifiedat)
VALUES (1, 'Pendiente', 'SYSTEM', SYSDATE, 'SYSTEM', SYSDATE);

INSERT INTO MatchStatus (id, name, createdby, createdat, modifiedby, modifiedat)
VALUES (2, 'Confirmado', 'SYSTEM', SYSDATE, 'SYSTEM', SYSDATE);

INSERT INTO MatchStatus (id, name, createdby, createdat, modifiedby, modifiedat)
VALUES (3, 'Rechazado', 'SYSTEM', SYSDATE, 'SYSTEM', SYSDATE);

--SEQ STATUS STATE
CREATE SEQUENCE SEQ_STATUS START WITH 1 INCREMENT BY 1 NOCYCLE CACHE 20;
CREATE SEQUENCE SEQ_STATE  START WITH 1 INCREMENT BY 1 NOCYCLE CACHE 20;
