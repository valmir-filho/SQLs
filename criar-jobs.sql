DECLARE x integer; 
BEGIN
      dbms_job.submit (x, 'ATUALIZAR_LOC_EQUIP_ADIC;', to_date('05-06-2024 11:00:00', 'dd-mm-yyyy hh24:mi:ss'),'SYSDATE + 1/24/60*5');
      COMMIT;
END;

/
DECLARE x integer; 
BEGIN
      dbms_job.submit (x, 'UNIFICA_OS_LOGINS(''VAFILHO'');', to_date('05-06-2024 11:00:00', 'dd-mm-yyyy hh24:mi:ss'),'SYSDATE + 1/24/60*5');
      COMMIT;
END;
/

/*
O primeiro parâmetro não deve ser preenchido;
O segundo é o nome da procedure ou comando SQL a ser executado;
O terceiro é a data de início da execução (primeira execução);
O último dita a peridiciodade de execução. No exemplo acima: a cada dia, a uma hora da manhã;
*/
