CREATE OR REPLACE PROCEDURE feas_altera_senha (
    ds_login_p IN VARCHAR2,
    senha_out OUT VARCHAR2
) IS
    senha_w VARCHAR2(255);
BEGIN
    -- Geração da senha aleatória.
    SELECT UPPER(DBMS_RANDOM.STRING('x', 8)) INTO senha_w FROM DUAL;
    
    -- Atualiza a senha na tabela.
    UPDATE usuario
    SET ds_senha = obter_sha2(senha_w || '$U@wlinu]tno@Pd', 256),
        ds_tec = '$U@wlinu]tno@Pd',
        dt_alteracao_senha = NULL
    WHERE UPPER(nm_usuario) = UPPER(ds_login_p);
    
    COMMIT;
    
    -- Retorna a senha gerada.
    senha_out := senha_w;
END feas_altera_senha;
