create or replace PROCEDURE envia_censo_e_saude_manual AS
  -- Variáveis de dados do paciente.
  nrCpf         VARCHAR2(15);
  nome          VARCHAR2(100);
  nmMae         VARCHAR2(100);
  dtNascimento  VARCHAR2(10);
  nrResidencia  VARCHAR2(20);
  nrCep         VARCHAR2(20);
  nrCelular     VARCHAR2(20);
  racaCor       VARCHAR2(20);
  sexo          VARCHAR2(1);
  nacionalidade VARCHAR2(20);
  ddd           VARCHAR2(2);
  v_dsLeito     VARCHAR2(300);
  v_setor       VARCHAR2(100);
  v_unidade     VARCHAR2(20);
  v_unidade_compl VARCHAR2(100);
  v_dt_alta     VARCHAR2(10);
  v_cd_setor    NUMBER;

  -- Variáveis de controle.
  v_nr_atendimento      NUMBER;
  v_qtd_movimentacoes   NUMBER;
  v_ie_tipo_atendimento NUMBER;

  -- Variáveis de requisição HTTP.
  req_login           UTL_HTTP.REQ;
  resp_login          UTL_HTTP.RESP;
  line_login          VARCHAR2(32767);
  url_login           VARCHAR2(1000) := 'http://esaudeprime.curitiba.pr.gov.br/saude-ws/rest/censo-hospitalar/login-acesso';
  json_payload_login  VARCHAR2(32767) := '{"nmLogin": "xxxx-xxx", "dsSenha": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"}';
  auth_token          VARCHAR2(32767);
  req         UTL_HTTP.REQ;
  resp        UTL_HTTP.RESP;
  json_body   CLOB;
  buffer      VARCHAR2(32767);

BEGIN
  -- 1. Obtem o último atendimento.
  SELECT MAX(nr_atendimento)
  INTO v_nr_atendimento
  FROM atend_paciente_unidade;

  -- 2. Verifica tipo de atendimento.
  SELECT ap.ie_tipo_atendimento
  INTO v_ie_tipo_atendimento
  FROM atendimento_paciente ap
  WHERE ap.nr_atendimento = v_nr_atendimento;

  IF v_ie_tipo_atendimento != 1 THEN
    DBMS_OUTPUT.PUT_LINE('Atendimento ignorado. Tipo de atendimento diferente de 1.');
    RETURN;
  END IF;

  -- 3. Conta movimentações.
  SELECT COUNT(*)
  INTO v_qtd_movimentacoes
  FROM atend_paciente_unidade
  WHERE nr_atendimento = v_nr_atendimento;

  -- 4. Dados do paciente.
  SELECT 
      NVL(pf.nr_cpf, 'VAZIO'),
      pf.nm_pessoa_fisica,
      NVL((SELECT cp2.nm_contato
           FROM compl_pessoa_fisica cp2
           WHERE cp2.cd_pessoa_fisica = pf.cd_pessoa_fisica
             AND cp2.ie_tipo_complemento = 5
           FETCH FIRST 1 ROWS ONLY), 'NAO INFORMADO'),
      TO_CHAR(pf.dt_nascimento, 'DD/MM/YYYY'),
      NVL(cp.nr_endereco, '0'),
      NVL(TO_CHAR(cp.cd_cep), '00000000'),
      NVL(cp.nr_telefone_celular, '000000000'),
      CASE 
        WHEN pf.NR_SEQ_COR_PELE = 1 THEN 'BRANCA'
        WHEN pf.NR_SEQ_COR_PELE = 2 THEN 'PRETA'
        WHEN pf.NR_SEQ_COR_PELE = 11 THEN 'PARDA'
        WHEN pf.NR_SEQ_COR_PELE = 4 THEN 'AMARELA'
        WHEN pf.NR_SEQ_COR_PELE = 3 THEN 'INDÍGENA'
        ELSE 'NAO INFORMADA'
      END,
      pf.IE_SEXO,
      CASE 
        WHEN pf.CD_NACIONALIDADE = 10 THEN 'BRASILEIRO'
        WHEN pf.CD_NACIONALIDADE = 20 THEN 'NATURALIZADO'
        ELSE 'ESTRANGEIRO'
      END,
      pf.nr_ddd_celular
  INTO 
      nrCpf, nome, nmMae, dtNascimento, nrResidencia, nrCep, nrCelular, racaCor, sexo, nacionalidade, ddd
  FROM pessoa_fisica pf
  LEFT JOIN compl_pessoa_fisica cp ON pf.cd_pessoa_fisica = cp.cd_pessoa_fisica
  JOIN atendimento_paciente ap ON ap.cd_pessoa_fisica = pf.cd_pessoa_fisica
  JOIN atend_paciente_unidade apu ON ap.nr_atendimento = apu.nr_atendimento
  WHERE apu.nr_atendimento = v_nr_atendimento
  AND ROWNUM = 1;

  -- 5. Login no Web Service.
  req_login := UTL_HTTP.BEGIN_REQUEST(url_login, 'POST', 'HTTP/1.1');
  UTL_HTTP.SET_HEADER(req_login, 'Content-Type', 'application/json');
  UTL_HTTP.SET_HEADER(req_login, 'Content-Length', LENGTH(json_payload_login));
  UTL_HTTP.WRITE_TEXT(req_login, json_payload_login);
  resp_login := UTL_HTTP.GET_RESPONSE(req_login);

  LOOP
    UTL_HTTP.READ_LINE(resp_login, line_login, TRUE);
    EXIT WHEN line_login LIKE '%"retorno":"%';
  END LOOP;

  auth_token := REGEXP_SUBSTR(line_login, '"retorno":"([^"]+)"', 1, 1, NULL, 1);
  UTL_HTTP.END_RESPONSE(resp_login);

  -- 6. Monta JSON e envia dados conforme movimentações.
  IF v_qtd_movimentacoes = 1 THEN
    SELECT sa.ds_setor_atendimento, apu.cd_unidade_basica, apu.cd_unidade_compl
    INTO v_setor, v_unidade, v_unidade_compl
    FROM atend_paciente_unidade apu
    JOIN setor_atendimento sa ON apu.cd_setor_atendimento = sa.cd_setor_atendimento
    WHERE apu.nr_atendimento = v_nr_atendimento
    AND apu.nr_sequencia = (
      SELECT MIN(nr_sequencia)
      FROM atend_paciente_unidade
      WHERE nr_atendimento = v_nr_atendimento
    );

    v_dsLeito := TRIM(v_setor) || ' ' || TRIM(v_unidade) || ' ' || TRIM(v_unidade_compl);

    json_body := '{
      "boletim": {
        "nmSetor":"HIZA - ENFERMARIA",
        "dsLeito":"' || v_dsLeito || '",
        "idMotivoInternamento":4,
        "idOrigemOcupacao":1,
        "idTipoLeito":2,
        "cbo": "411010",
        "cnes": "6388671",
        "nrCpf":"72414898020",
        "dsSistemaOrigem":"TASY"
      },
      "usuario": {
        "nrCpf": "' || nrCpf || '",
        "nome": "' || nome || '",
        "nmMae": "' || nmMae || '",
        "dtNascimento": "' || dtNascimento || '",
        "nrResidencia": "' || nrResidencia || '",
        "nrCep": "' || nrCep || '",
        "nrCelular": "' || nrCelular || '",
        "racaCor": "' || racaCor || '",
        "sexo": "' || sexo || '",
        "nacionalidade": "' || nacionalidade || '",
        "ddd":' || TRIM(ddd) || '
      }}';

    req := UTL_HTTP.begin_request('http://esaudeprime.curitiba.pr.gov.br/saude-ws/rest/censo-hospitalar', 'POST', 'HTTP/1.1');

  ELSE
    SELECT sa.ds_setor_atendimento, apu.cd_unidade_basica, apu.cd_unidade_compl, TO_CHAR(apu.dt_saida_unidade, 'DD/MM/YYYY'), apu.cd_setor_atendimento
    INTO v_setor, v_unidade, v_unidade_compl, v_dt_alta, v_cd_setor
    FROM atend_paciente_unidade apu
    JOIN setor_atendimento sa ON apu.cd_setor_atendimento = sa.cd_setor_atendimento
    WHERE apu.nr_atendimento = v_nr_atendimento
    AND apu.nr_sequencia = (
      SELECT MAX(nr_sequencia)
      FROM atend_paciente_unidade
      WHERE nr_atendimento = v_nr_atendimento
    );

    -- Filtro de setores autorizados.
    IF v_cd_setor NOT IN (697, 678, 679, 680, 491, 673) THEN
      DBMS_OUTPUT.PUT_LINE('Setor não autorizado para envio. Processo interrompido.');
      RETURN;
    END IF;

    v_dsLeito := TRIM(v_setor) || ' ' || TRIM(v_unidade) || ' ' || TRIM(v_unidade_compl);

    json_body := '{
      "boletim": {
        "nmSetor":"HIZA - ENFERMARIA",
        "dsLeito":"' || v_dsLeito || '",
        "idMotivoInternamento":4,
        "idOrigemOcupacao":1,
        "idTipoLeito":2,
        "cbo": "411010",
        "cnes": "6388671",
        "nrCpf":"06306555960",
        "dsSistemaOrigem":"TASY"
      },
      "usuario": {
        "nrCpf": "' || nrCpf || '",
        "nome": "' || nome || '",
        "nmMae": "' || nmMae || '",
        "dtNascimento": "' || dtNascimento || '",
        "nrResidencia": "' || nrResidencia || '",
        "nrCep": "' || nrCep || '",
        "nrCelular": "' || nrCelular || '",
        "racaCor": "' || racaCor || '",
        "sexo": "' || sexo || '",
        "nacionalidade": "' || nacionalidade || '",
        "ddd":' || TRIM(ddd) || '
      }}';

    req := UTL_HTTP.begin_request('http://esaudeprime.curitiba.pr.gov.br/saude-ws/rest/censo-hospitalar', 'PUT', 'HTTP/1.1');
  END IF;

  -- Envia JSON.
  UTL_HTTP.set_header(req, 'Authorization', 'Bearer ' || auth_token);
  UTL_HTTP.set_header(req, 'Content-Type', 'application/json');
  UTL_HTTP.set_header(req, 'Content-Length', DBMS_LOB.getlength(json_body));
  UTL_HTTP.write_text(req, json_body);
  resp := UTL_HTTP.get_response(req);

  LOOP
    BEGIN
      UTL_HTTP.read_text(resp, buffer, 32767);
      DBMS_OUTPUT.PUT_LINE('Response: ' || buffer);
    EXCEPTION
      WHEN UTL_HTTP.end_of_body THEN
        EXIT;
    END;
  END LOOP;

  UTL_HTTP.end_response(resp);

EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Erro: ' || SQLERRM);
END;
