--LISTA MASCOTAS ESTADO EN ADOPCION
CREATE OR REPLACE PROCEDURE SP_LISTAR_MASC_EN_ADOP (
    p_record OUT SYS_REFCURSOR
) AS
BEGIN
    OPEN p_record FOR
        SELECT 
            p.id, 
            p.name, 
            pt.name AS tipo, 
            b.name AS raza
        FROM Pet p
        JOIN Breed b ON p.idBreed = b.id
        JOIN PetType pt ON b.idPetType = pt.id
        JOIN State s ON p.idState = s.id
        WHERE UPPER(s.name) = 'EN ADOPCION' 
        ORDER BY p.name;
END;
--CONVERTIR A RESCATISTA
CREATE OR REPLACE PROCEDURE SP_MAKE_RESCATISTA (
    p_idPerson  IN NUMBER,
    p_createdBy IN VARCHAR2,
    p_resultado OUT VARCHAR2
) AS
    v_existe NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_existe 
    FROM Rescuer 
    WHERE id = p_idPerson;

    IF v_existe > 0 THEN
        p_resultado := 'La persona ya está registrada como rescatista.';
        RETURN;
    END IF;

    INSERT INTO Rescuer (
        id
    ) VALUES (
        p_idPerson
    );

    p_resultado := 'EXITO';
    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        p_resultado := 'ERROR: ';
END SP_MAKE_RESCATISTA;





















