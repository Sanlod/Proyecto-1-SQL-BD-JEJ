CREATE OR REPLACE PROCEDURE SP_AGREGAR_PREGUNTA (
    p_text       IN VARCHAR2,
    p_answerType IN VARCHAR2,
    p_createdBy  IN VARCHAR2
) AS
BEGIN
    INSERT INTO Question (
        id, text, answerType,
        createdBy, createdAt, modifiedBy, modifiedAt
    ) VALUES (
        SEQ_QUESTION.NEXTVAL,
        p_text,
        p_answerType,
        p_createdBy, CURRENT_TIMESTAMP,
        p_createdBy, CURRENT_TIMESTAMP
    );
    COMMIT;
END SP_AGREGAR_PREGUNTA;
/

CREATE OR REPLACE PROCEDURE SP_EDITAR_PREGUNTA (
    p_id         IN NUMBER,
    p_text       IN VARCHAR2,
    p_answerType IN VARCHAR2,
    p_modifiedBy IN VARCHAR2
) AS
BEGIN
    UPDATE Question
    SET text       = p_text,
        answerType = p_answerType,
        modifiedBy = p_modifiedBy,
        modifiedAt = CURRENT_TIMESTAMP
    WHERE id = p_id;
    COMMIT;
END SP_EDITAR_PREGUNTA;
/
--No es de question pero hacía falta para eliminar del catalogo
CREATE OR REPLACE PROCEDURE SP_ELIMINAR_CATALOGO (
    p_tabla IN VARCHAR2,
    p_id    IN NUMBER
) AS
BEGIN
    EXECUTE IMMEDIATE
        'DELETE FROM ' || p_tabla || ' WHERE id = :1'
        USING p_id;
    COMMIT;
END SP_ELIMINAR_CATALOGO;
/

CREATE SEQUENCE SEQ_QUESTION
    START WITH 1
    INCREMENT BY 1
    MINVALUE 1
    MAXVALUE 999999
    NOCYCLE
    CACHE 20;