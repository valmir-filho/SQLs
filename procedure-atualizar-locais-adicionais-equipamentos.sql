CREATE OR REPLACE PROCEDURE ATUALIZAR_LOC_EQUIP_ADIC IS
    CURSOR c1 IS
        SELECT NR_SEQUENCIA FROM MAN_EQUIPAMENTO WHERE IE_SITUACAO = 'A' AND IE_CONTROLE_SETOR = 'N';
BEGIN
    FOR r_equip IN c1 LOOP
        INSERT INTO MAN_EQUIP_LOCAL_ADIC (NR_SEQUENCIA, DT_ATUALIZACAO, NM_USUARIO, DT_ATUALIZACAO_NREC, NM_USUARIO_NREC, NR_SEQ_EQUIPAMENTO, NR_SEQ_LOCAL)
        SELECT MAN_EQUIP_LOCAL_ADIC_SEQ.nextval, SYSDATE, 'VAFILHO', SYSDATE, 'VAFILHO', r_equip.NR_SEQUENCIA, l.NR_SEQUENCIA
        FROM MAN_LOCALIZACAO l WHERE l.IE_SITUACAO = 'A'
        AND NOT EXISTS (
            SELECT 1 FROM MAN_EQUIP_LOCAL_ADIC m 
            WHERE m.NR_SEQ_EQUIPAMENTO = r_equip.NR_SEQUENCIA AND m.NR_SEQ_LOCAL = l.NR_SEQUENCIA
        );
    END LOOP;
    COMMIT;
END ATUALIZAR_LOC_EQUIP_ADIC;