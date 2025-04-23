create or replace TRIGGER trg_envia_censo_apos_insert
AFTER INSERT ON atend_paciente_unidade
FOR EACH ROW
DECLARE
    BEGIN
        envia_censo_e_saude_manual();        
    END;
