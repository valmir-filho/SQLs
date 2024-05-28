CREATE OR REPLACE PROCEDURE UNIFICA_OS_LOGINS (nm_usuario_p VARCHAR2)
IS
  CURSOR c1 IS        
    SELECT NR_SEQUENCIA, DS_DANO
    FROM MAN_ORDEM_SERVICO OS 
    WHERE OS.DS_DANO_BREVE = 'Solicitação de login de usuário (automático)'
      AND IE_STATUS_ORDEM = 1
      AND NR_SEQ_ESTAGIO = 21
      AND NR_SEQUENCIA <> 147957;

  nr_sequencia_ NUMBER(10, 0);
  ds_dano_ VARCHAR2(32767) := '';

  cd_pessoa_solicitante_ NUMBER(10, 0);
  nova_os_ NUMBER(10, 0);
  concatenated_data_ VARCHAR2(32767) := '';

BEGIN
  nova_os_ := man_ordem_serv_tecnico_seq.NEXTVAL;
  
  SELECT MAX(cd_pessoa_fisica) 
  INTO cd_pessoa_solicitante_
  FROM pessoa_fisica 
  WHERE nm_usuario = nm_usuario_p;

  OPEN c1;
  LOOP
    FETCH c1 INTO nr_sequencia_, ds_dano_;
    EXIT WHEN c1%NOTFOUND;

    concatenated_data_ := concatenated_data_ || ds_dano_ || CHR(10) || CHR(10) || CHR(10);

    -- Inserir histórico, que é pré-requisito para encerrar as OS's antigas.
    INSERT INTO MAN_ORDEM_SERV_TECNICO (
      NR_SEQUENCIA, NR_SEQ_ORDEM_SERV, DT_HISTORICO, DT_ATUALIZACAO, 
      DT_LIBERACAO, NM_USUARIO, NM_USUARIO_LIB, DS_RELAT_TECNICO, 
      NR_SEQ_TIPO, IE_ORIGEM
    ) VALUES (
      MAN_ORDEM_SERV_TECNICO_SEQ.NEXTVAL, nr_sequencia_, SYSDATE, SYSDATE, 
      SYSDATE, nm_usuario_p, nm_usuario_p, 'OS concatenada na OS geral n.' || TO_CHAR(nova_os_), 1, 'I'
    );

    -- Fechamento das OS que foram concatenadas.
    UPDATE MAN_ORDEM_SERVICO 
    SET IE_STATUS_ORDEM = 3, NR_SEQ_ESTAGIO = 12, NM_USUARIO = nm_usuario_p, 
        NM_USUARIO_EXEC = nm_usuario_p, DT_INICIO_REAL = SYSDATE, DT_FIM_REAL = SYSDATE
    WHERE NR_SEQUENCIA = nr_sequencia_;
  END LOOP;
  CLOSE c1;

  DBMS_OUTPUT.PUT_LINE(concatenated_data_);

  -- Inserção da última OS concatenada.
  INSERT INTO MAN_ORDEM_SERVICO (
    NR_SEQUENCIA, NR_SEQ_LOCALIZACAO, CD_FUNCAO, NR_SEQ_EQUIPAMENTO, 
    CD_PESSOA_SOLICITANTE, DT_ORDEM_SERVICO, IE_PRIORIDADE, IE_PARADO, 
    DS_DANO_BREVE, DT_ATUALIZACAO, NM_USUARIO, DT_INICIO_DESEJADO, 
    DT_CONCLUSAO_DESEJADA, DS_DANO, IE_TIPO_ORDEM, IE_STATUS_ORDEM, 
    NR_GRUPO_PLANEJ, NR_GRUPO_TRABALHO, NR_SEQ_ESTAGIO, IE_CLASSIFICACAO, 
    NR_SEQ_CAUSA_DANO, IE_FORMA_RECEB, NR_SEQ_COMPLEX, DT_ATUALIZACAO_NREC, 
    NM_USUARIO_NREC, IE_OBRIGA_NEWS, DS_CONTATO_SOLICITANTE, IE_ORIGEM_OS, 
    DS_MAQUINA_CRIACAO, CD_CENTRO_CUSTO_OS, NM_USUARIO_EXEC, NR_SEQ_TIPO_ORDEM
  ) VALUES (
    nova_os_, 6060, NULL, 22120, 
    cd_pessoa_solicitante_, SYSDATE, 'M', 'N', 
    'Solicitação de login de usuário (unificada)', SYSDATE, nm_usuario_p, SYSDATE, 
    SYSDATE, concatenated_data_, 0, 1, 11, 91, 21, 'S', 
    8, 'I', 1, SYSDATE, nm_usuario_p, 'S', 'Ramal 3316-5999', 4, NULL, 717, NULL, 12
  );

  COMMIT;

EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
    RAISE_APPLICATION_ERROR(-20001, 'Erro ao criar as ordens de serviço.');
END UNIFICA_OS_LOGINS;
