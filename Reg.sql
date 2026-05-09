create or replace PROCEDURE SP_REGISTRAR_MASCOTA (
    p_name                        IN VARCHAR2,
    p_idBreed                     IN VARCHAR2,
    p_chip                        IN VARCHAR2,  
    p_idColour                    IN VARCHAR2,
    p_idState                     IN VARCHAR2,
    p_idSeverity                  IN VARCHAR2,
    p_idEnergyLevel               IN VARCHAR2,
    p_idDistrict                  IN VARCHAR2,
    p_petSize                     IN VARCHAR2,
    p_requiresMuchSpace           IN NUMBER,
    p_telephone                   IN VARCHAR2,
    p_email                       IN VARCHAR2,
    p_abandonSituationDescription IN VARCHAR2,
    p_descriptionNotes            IN VARCHAR2,
    p_idTrainingDifficulty        IN VARCHAR2,
    p_lossDate                    IN DATE,
    p_foundDate                   IN DATE,
    p_idVeterinarian              IN VARCHAR2,
    p_idCribHouse                 IN VARCHAR2,
    p_idRescuer                   IN VARCHAR2,
    p_idAssociation               IN VARCHAR2,
    p_beforePicture               IN BLOB,
    p_afterPicture                IN BLOB,
    p_createdBy                   IN VARCHAR2,
    p_birthDate IN DATE,
    p_id_generado                 OUT NUMBER
) AS
    v_id NUMBER;
BEGIN
    INSERT INTO Pet (
        id, name, idBreed, idColour,
        idState, idSeverity, idEnergyLevel, idDistrict,
        pet_size, requiresMuchSpace, telephone, email,
        abandonSituationDescription, descriptionNotes,
        idTrainingDifficulty, loss_date, foundDate,
        idVeterinarian, idCribHouse, idRescuer, idAssociation,
        beforePicture, afterPicture,
        createdBy, createdAt, modifiedBy, modifiedAt, birthDate
    ) VALUES (
        SEQ_PET.NEXTVAL,
        p_name,
        TO_NUMBER(p_idBreed),
        TO_NUMBER(p_idColour),
        TO_NUMBER(p_idState),
        TO_NUMBER(p_idSeverity),
        TO_NUMBER(p_idEnergyLevel),
        TO_NUMBER(p_idDistrict),
        p_petSize,
        p_requiresMuchSpace,
        p_telephone,
        p_email,
        p_abandonSituationDescription,
        p_descriptionNotes,
        TO_NUMBER(p_idTrainingDifficulty),
        p_lossDate,
        p_foundDate,
        p_idVeterinarian,
        TO_NUMBER(p_idCribHouse),
        TO_NUMBER(p_idRescuer),
        TO_NUMBER(p_idAssociation),
        p_beforePicture,
        p_afterPicture,
        p_createdBy, CURRENT_TIMESTAMP,
        p_createdBy, CURRENT_TIMESTAMP,
        p_birthDate
    ) RETURNING id INTO v_id;

    IF p_chip IS NOT NULL THEN
    INSERT INTO Chip (id, petID, chipNumber, createdBy, createdAt, modifiedBy, modifiedAt)
    VALUES (SEQ_CHIP.NEXTVAL, v_id, TO_NUMBER(p_chip), p_createdBy, CURRENT_TIMESTAMP, p_createdBy, CURRENT_TIMESTAMP);
    END IF;

    p_id_generado := v_id;
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        p_id_generado := -1;
        RAISE;
END SP_REGISTRAR_MASCOTA;
