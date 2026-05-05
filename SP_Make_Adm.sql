create or replace PROCEDURE SP_MAKE_ADM
(p_user_id IN NUMBER) IS
    v_current_type NUMBER;
BEGIN
    SELECT idUserType INTO v_current_type FROM appUser WHERE id = p_user_id;
    
    --Verificar que no sea admin
    IF v_current_type = 1 THEN
        RAISE_APPLICATION_ERROR(-20003, 'El usuario ya es un Administrador.');
    END IF;

    --En caso de no serlo, modificar
    UPDATE appUser 
    SET idUserType = 1,
        modifiedAt = CURRENT_TIMESTAMP,
        modifiedBy = 'SYSTEM_CHANGE'
    WHERE id = p_user_id;

    COMMIT;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20002, 'El ID de usuario no existe.');
END;