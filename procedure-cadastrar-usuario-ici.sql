CREATE OR REPLACE PROCEDURE OS_CRIACAO_USUARIO_HIZA IS

  -- Declaração do cursor para selecionar os dados dos funcionários.
  CURSOR c1 IS        
    SELECT PF.CD_PESSOA_FISICA, 
           PF.NM_PESSOA_FISICA, 
           PF.NR_CPF, 
           PF.DT_NASCIMENTO, 
           PF.DT_ADMISSAO_HOSP,  
           REPLACE(REGEXP_REPLACE(PF.NR_DDD_CELULAR, '[^[:digit:]]'), 0, '') AS ddd_celular_,
           CASE WHEN LENGTH(REGEXP_REPLACE(PF.NR_TELEFONE_CELULAR, '[^[:digit:]]')) > 11 THEN
                SUBSTR(REGEXP_REPLACE(PF.NR_TELEFONE_CELULAR, '[^[:digit:]]'), 2, 11)
           ELSE
                REGEXP_REPLACE(PF.NR_TELEFONE_CELULAR, '[^[:digit:]]') 
           END AS telefone_celular_ 
    FROM PESSOA_FISICA PF
    LEFT JOIN USUARIO U 
    ON PF.CD_PESSOA_FISICA = U.CD_PESSOA_FISICA AND U.IE_SITUACAO <> 'I'
    LEFT JOIN MAN_ORDEM_SERVICO OS 
    ON OS.CD_PESSOA_SOLICITANTE = PF.CD_PESSOA_FISICA
    WHERE DT_ADMISSAO_HOSP IS NOT NULL
      AND DT_DEMISSAO_HOSP IS NULL
      AND IE_FUNCIONARIO = 'S'
      AND NVL(U.DS_LOGIN, U.NM_USUARIO) IS NULL
      AND PF.DT_ADMISSAO_HOSP >= SYSDATE - 30
    GROUP BY PF.CD_PESSOA_FISICA, 
             PF.NM_PESSOA_FISICA, 
             PF.NR_CPF, 
             PF.DT_NASCIMENTO, 
             PF.DT_ADMISSAO_HOSP, 
             PF.NR_DDD_CELULAR, 
             PF.NR_TELEFONE_CELULAR
    HAVING EXISTS (SELECT 1 
                   FROM MAN_ORDEM_SERVICO OS_AUX 
                   WHERE OS_AUX.DS_DANO_BREVE LIKE 'Inativar Usuário (Automático)%' 
                     AND OS_AUX.NR_SEQUENCIA = (SELECT MAX(NR_SEQUENCIA) 
                                                FROM MAN_ORDEM_SERVICO 
                                                WHERE CD_PESSOA_SOLICITANTE = PF.CD_PESSOA_FISICA)
                  ) 
       OR NOT EXISTS (SELECT 1 
                      FROM MAN_ORDEM_SERVICO 
                      WHERE CD_PESSOA_SOLICITANTE = PF.CD_PESSOA_FISICA);

  -- Declaração de variáveis.
  NR_SEQUENCIA_ NUMBER(10,0);
  CD_PESSOA_FISICA_ VARCHAR2(10);
  NM_PESSOA_FISICA_ VARCHAR2(60);
  NR_CPF_ VARCHAR2(11);
  DT_NASCIMENTO_ DATE;
  DT_ADMISSAO_HOSP_ DATE;
  DDD_CELULAR_ VARCHAR2(2);
  TELEFONE_CELULAR_ VARCHAR2(11);
  URL_ VARCHAR2(1000);
  BODY_ CLOB;
  REQ_ UTL_HTTP.REQ;
  RESP_ UTL_HTTP.RESP;
  OUTPUT_ CLOB;
  JSON_OBJ JSON_OBJECT_T;
  UID_ VARCHAR2(100);
  SENHA_ VARCHAR2(100);

BEGIN

  OPEN c1;
  LOOP
    FETCH c1 INTO CD_PESSOA_FISICA_, NM_PESSOA_FISICA_, NR_CPF_, DT_NASCIMENTO_, DT_ADMISSAO_HOSP_, DDD_CELULAR_, TELEFONE_CELULAR_;
    EXIT WHEN c1%NOTFOUND;

    -- Ajuste do DDD do celular caso esteja nulo ou seja 0.
    IF DDD_CELULAR_ IS NULL OR DDD_CELULAR_ = '0' THEN
      IF TELEFONE_CELULAR_ IS NOT NULL THEN
        BEGIN
          DDD_CELULAR_ := '41';
          IF LENGTH(DDD_CELULAR_) = 2 THEN
            DDD_CELULAR_ := DDD_CELULAR_;
          ELSIF LENGTH(DDD_CELULAR_) = 3 THEN
            DDD_CELULAR_ := SUBSTR(DDD_CELULAR_, 2, 2);
          END IF;
        END;
      END IF;
    END IF;

    -- Obtenção de nova sequência para a ordem de serviço.
    NR_SEQUENCIA_ := MAN_ORDEM_SERVICO_SEQ.NEXTVAL;

    -- Inserção da ordem de serviço.
    INSERT INTO MAN_ORDEM_SERVICO (
      NR_SEQUENCIA, NR_SEQ_LOCALIZACAO, CD_FUNCAO, NR_SEQ_EQUIPAMENTO, CD_PESSOA_SOLICITANTE, DT_ORDEM_SERVICO, IE_PRIORIDADE,
      IE_PARADO, DS_DANO_BREVE, DT_ATUALIZACAO, NM_USUARIO, DT_INICIO_DESEJADO, DT_CONCLUSAO_DESEJADA, DS_DANO,
      IE_TIPO_ORDEM, IE_STATUS_ORDEM, NR_GRUPO_PLANEJ, NR_GRUPO_TRABALHO, NR_SEQ_ESTAGIO, IE_CLASSIFICACAO, NR_SEQ_CAUSA_DANO, IE_FORMA_RECEB,
      NR_SEQ_COMPLEX, DT_ATUALIZACAO_NREC, NM_USUARIO_NREC, IE_OBRIGA_NEWS, DS_CONTATO_SOLICITANTE, IE_ORIGEM_OS, DS_MAQUINA_CRIACAO,
      CD_CENTRO_CUSTO_OS, NM_USUARIO_EXEC, NR_SEQ_TIPO_ORDEM
    ) VALUES (
      NR_SEQUENCIA_, 6060, NULL, 22120, CD_PESSOA_FISICA_, SYSDATE, 'M',
      'N', 'Solicitação de login de usuário (automático)', SYSDATE, 'TASY', SYSDATE, SYSDATE,                 
      'Favor solicitar login de rede para o colaborador: ' || CHR(10) || CHR(10) || 'Nome: ' || NM_PESSOA_FISICA_ || ' ' || CHR(10) ||
      'CPF: '|| NR_CPF_ || ' ' || CHR(10) || 'Nascimento: ' || TO_CHAR(DT_NASCIMENTO_, 'DD/MM/YYYY') || ' ' || CHR(10) ||
      'Admissão: ' || TO_CHAR(DT_ADMISSAO_HOSP_, 'DD/MM/YYYY') || CHR(10) || 'Telefone: ' || DDD_CELULAR_ || ' ' || TELEFONE_CELULAR_ || ' ' || CHR(10),
      0, 1, 11, 91, 21, 'S', 8, 'I',
      1, SYSDATE, 'TASY', 'S', 'Ramal 5999', 4, NULL,
      717, NULL, 12
    );

    -- Inserção na tabela de execução da ordem de serviço.
    INSERT INTO MAN_ORDEM_SERVICO_EXEC (
      NR_SEQUENCIA, NR_SEQ_ORDEM, DT_ATUALIZACAO, DT_ATUALIZACAO_NREC, NM_USUARIO_EXEC, NM_USUARIO, NM_USUARIO_NREC
    ) SELECT 
      MAN_ORDEM_SERVICO_EXEC_SEQ.NEXTVAL, NR_SEQUENCIA_, SYSDATE, SYSDATE, NM_USUARIO_PARAM, 'TASY', 'TASY'
    FROM MAN_GRUPO_TRAB_USUARIO
    WHERE NR_SEQ_GRUPO_TRAB = 91;

    -- Definição do endpoint do método do ICI "cadastrarUsuario".
    URL_ := 'https://wsldap.ici.curitiba.org.br/opendcws/webresources/openDocAutenticar/cadastrarUsuario';
    
    -- Definição dos parâmetros de acesso ao método do ICI "cadastrarUsuario".
    BODY_ := '{
      "contaUsuario": "rhfeas",
      "senhaUsuario": "{MD5}lszO6k4SztXtiuL6tJA2Jg==",
      "dominio": "FEAES",
      "cn": "' || NM_PESSOA_FISICA_ || '",
      "telephoneNumber": "(' || DDD_CELULAR_ || ') ' || TELEFONE_CELULAR_ || '",
      "mobile": "(' || DDD_CELULAR_ || ') ' || TELEFONE_CELULAR_ || '",
      "dataNascimento": "' || TO_CHAR(DT_NASCIMENTO_, 'DD/MM/YYYY') || '",
      "tipoUsuario": "colaborador",
      "cpf": "' || NR_CPF_ || '"
    }';   

    -- Caminho e senha para o acesso ao wallet (consumo do certificado SSL).
    UTL_HTTP.SET_WALLET('file:/u01/app/oracle/admin/tasy/wallet', 'a21de42193');

    -- Criação da requisição HTTP POST.
    REQ_ := UTL_HTTP.BEGIN_REQUEST(URL_, 'POST', 'HTTP/1.1');

    -- Definição dos cabeçalhos da requisição.
    UTL_HTTP.SET_HEADER(REQ_, 'Content-Type', 'application/json');
    UTL_HTTP.SET_HEADER(REQ_, 'Content-Length', LENGTH(BODY_));

    -- Gravação do corpo da requisição.
    UTL_HTTP.WRITE_TEXT(REQ_, BODY_);

    -- Envio da requisição e obtenção da resposta.
    RESP_ := UTL_HTTP.GET_RESPONSE(REQ_);

    BEGIN
      -- Leitura da resposta.
      UTL_HTTP.READ_TEXT(RESP_, OUTPUT_);
      DBMS_OUTPUT.PUT_LINE(OUTPUT_);
      
      -- Processamento da resposta JSON.
      JSON_OBJ := JSON_OBJECT_T(OUTPUT_);
      UID_ := JSON_OBJ.GET_STRING('uid');
      SENHA_ := JSON_OBJ.GET_STRING('senha');

      -- Atualização do campo DS_RELAT_TECNICO da tabela MAN_ORDEM_SERV_TECNICO.
      UPDATE MAN_ORDEM_SERV_TECNICO
      SET DS_RELAT_TECNICO = 'Criação do usuário realizada com sucesso. UID: ' || UID_ || ', Senha: ' || SENHA_
      WHERE NR_SEQUENCIA = NR_SEQUENCIA_;
    EXCEPTION
      WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Erro ao ler ou processar a resposta: ' || SQLERRM);
    END;

    -- Encerramento da resposta HTTP.
    UTL_HTTP.END_RESPONSE(RESP_);

  END LOOP;
  CLOSE c1;

  COMMIT;

EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Erro durante a execução da procedure: ' || SQLERRM);
    ROLLBACK;
END OS_CRIACAO_USUARIO_HIZA;
