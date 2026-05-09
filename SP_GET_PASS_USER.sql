CREATE OR REPLACE PROCEDURE SP_Get_Pass_User(
    p_username IN VARCHAR2,
    p_hash OUT VARCHAR2
) 
AS
BEGIN
    SELECT password INTO p_hash
    FROM appUser
    WHERE username = p_username;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        p_hash := NULL;
END;