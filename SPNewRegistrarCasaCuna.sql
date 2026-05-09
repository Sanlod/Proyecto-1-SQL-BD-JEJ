CREATE OR REPLACE PROCEDURE SP_Registrar_CasaCuna (
    cc_requires IN NUMBER,
    cc_idDistrict IN NUMBER,
    cc_idPerson IN NUMBER,
    cc_acceptedSize IN VARCHAR2,   
    cc_id_generado OUT NUMBER
) AS 
    v_new_id NUMBER;
BEGIN
    v_new_id := seq_cribHouse.NEXTVAL;

    INSERT INTO cribHouse (
        id,
        requiresFoodDonations,
        idDistrict,
        idPerson,
        acceptedPetSize
    ) VALUES (
        v_new_id,
        cc_requires,
        cc_idDistrict,
        cc_idPerson,
        cc_acceptedSize
    );
    cc_id_generado := v_new_id;
    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        cc_id_generado := -1;
END;


CREATE OR REPLACE PROCEDURE SP_Insertar_Tipos_Crib (
    p_idCribhouse IN NUMBER,
    p_idPetType IN NUMBER
) AS
BEGIN
    INSERT INTO CRIBHOUSEXPETTYPE (idCribhouse, idPetType)
    VALUES (p_idCribhouse, p_idPetType);
    COMMIT;
END;
/

-- SP para insertarNiveles de Energía
CREATE OR REPLACE PROCEDURE SP_Insertar_Niveles_Crib (
    p_idCribhouse IN NUMBER,
    p_idEnergyLevel IN NUMBER
) AS
BEGIN
    INSERT INTO CRIBHOUSEXENERGYLEVEL (idCribhouse, idEnergyLevel)
    VALUES (p_idCribhouse, p_idEnergyLevel);
    COMMIT;
END;
/

CREATE OR REPLACE PROCEDURE SP_Listar_CribHouse (
    p_cursor OUT SYS_REFCURSOR
) 
AS
BEGIN
    OPEN p_cursor FOR
    SELECT 
        ch.idPerson,
        p.firstName || ' ' || p.firstSurname || ' ' || p.secondSurname AS Nombre_dueno,
        d.name AS Distrito,
        (SELECT LISTAGG(pt.name, ', ') WITHIN GROUP (ORDER BY pt.name) --Eso de listaGG es para concatenar los tipos por id
         FROM CRIBHOUSEXPETTYPE cxp
         JOIN PETTYPE pt ON cxp.idPetType = pt.id
         WHERE cxp.idCribhouse = ch.id) AS Tipos_mascota,
        ch.acceptedPetSize AS Tamanio_aceptado,
        (SELECT LISTAGG(el.name, ', ') WITHIN GROUP (ORDER BY el.name)
         FROM CRIBHOUSEXENERGYLEVEL cxe
         JOIN ENERGYLEVEL el ON cxe.idEnergyLevel = el.id
         WHERE cxe.idCribhouse = ch.id) AS Niveles_energia,
        CASE WHEN ch.requiresFoodDonations = 1 
             THEN 'Sí' ELSE 'No' END AS Donacion 
    FROM 
        cribHouse ch 
        JOIN person p ON ch.idPerson = p.id
        JOIN district d ON ch.idDistrict = d.id;
END;