CREATE OR REPLACE PROCEDURE SP_LISTAR_MASCOTAS_SIN_CASA (
    p_cursor OUT SYS_REFCURSOR
    ) 
AS
BEGIN
    OPEN p_cursor FOR
        SELECT p.id, p.name, b.name AS breed, p.pet_size, p.idenergylevel
        FROM pet p JOIN breed b ON p.idbreed = b.id
        WHERE p.idcribhouse IS NULL;
END;

CREATE OR REPLACE PROCEDURE SP_LISTAR_MASCOTAS_CON_CASA (
    p_cursor OUT SYS_REFCURSOR
    ) 
AS
BEGIN
    OPEN p_cursor FOR
        SELECT p.id, p.name, b.name AS breed, p.pet_size, p.idenergylevel
        FROM pet p JOIN breed b ON p.idbreed = b.id
        WHERE p.idcribhouse IS NOT NULL;
END;

CREATE OR REPLACE PROCEDURE SP_CASAS_COMPATIBLES (
    p_idPet  IN NUMBER,
    p_cursor OUT SYS_REFCURSOR
    ) 
AS
    v_size pet.pet_size%TYPE;
    v_idEnergy pet.idEnergylevel%TYPE;
    v_idPetType breed.idPetType%TYPE;
BEGIN
    SELECT p.pet_size, p.idenergylevel, b.idpettype
    INTO v_size, v_idEnergy, v_idPetType
    FROM pet p
    JOIN breed b ON p.idBreed = b.id
    WHERE p.id = p_idPet;

    OPEN p_cursor FOR
        SELECT DISTINCT ch.id, ch.acceptedpetsize, ch.iddistrict
        FROM cribhouse ch 
        JOIN cribhousexpettype chpt ON ch.id = chpt.idcribhouse
        JOIN cribhousexenergylevel chel ON ch.id = chel.idcribhouse
        WHERE ch.acceptedpetsize LIKE '%' || v_size || '%' --Es asi porque es un varchar entonces es necesario el like 
        AND chpt.idpettype = v_idPetType
        AND chel.idenergylevel = v_idEnergy
        AND ch.id NOT IN (SELECT idcribhouse FROM pet WHERE idcribhouse IS NOT NULL);
END;

CREATE OR REPLACE PROCEDURE SP_ASIGNAR_MASCOTA_CASA (
    p_idPet IN NUMBER,
    p_idCribHouse IN NUMBER
    ) 
AS
BEGIN
    UPDATE pet SET 
    idcribhouse = p_idCribHouse,
    modifiedby  = 'SYSTEM',
    modifiedat  = CURRENT_TIMESTAMP
    WHERE id = p_idPet;
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END;

CREATE OR REPLACE PROCEDURE SP_Null_Pet_Crib
(p_id IN NUMBER) IS
    v_current_value NUMBER;
BEGIN
    SELECT idCribHouse INTO v_current_value FROM pet WHERE id = p_id;

    IF v_current_value IS NULL THEN
        RAISE_APPLICATION_ERROR(-20003, 'La mascota no está en ninguna casa cuna.');
    END IF;

    UPDATE pet 
    SET idCribHouse = NULL,
        modifiedAt = CURRENT_TIMESTAMP,
        modifiedBy = 'ADMIN_CHANGE'
    WHERE id = p_id;

    COMMIT;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20002, 'El ID de la mascota no existe.');
END;