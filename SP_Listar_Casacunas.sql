CREATE OR REPLACE PROCEDURE SP_LISTAR_CRIBHOUSE (
    p_cursor OUT SYS_REFCURSOR
) 
AS
BEGIN
    OPEN p_cursor FOR
    SELECT 
        ch.idPerson,
        p.firstName || ' ' || p.firstSurname || ' ' || p.secondSurname AS NOMBRE_DUEÑO,
        d.name,
        ch.acceptedPetType,
        ch.acceptedPetSize,
        ch.acceptedEnergyLevel,
        --Case va a traducir de este binario a un si/no en la interfaz
        CASE WHEN ch.requiresFoodDonations = 1 
        THEN 'Sí' ELSE 'No' END AS DONACION 
    FROM 
        cribHouse ch JOIN person p ON ch.idPerson = p.id
        JOIN district d ON ch.idDistrict = d.id;
END;