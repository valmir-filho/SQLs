CREATE OR REPLACE PROCEDURE envia_censo_e_saude AS
  -- Variáveis para armazenar os resultados da consulta.
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

  -- Variáveis para requisição HTTP.
  req_login           UTL_HTTP.REQ;
  resp_login          UTL_HTTP.RESP;
  line_login          VARCHAR2(32767);
  url_login           VARCHAR2(1000) := 'http://hom-esaudeprime.ici.curitiba.org.br/saude-ws/rest/censo-hospitalar/login-acesso';
  json_payload_login  VARCHAR2(32767) := '{"nmLogin": "FEAS-HOM", "dsSenha": "6737ADF1-A178-AF9D-0B3E-B7FDE99AFD5E"}';
  auth_token          VARCHAR2(32767);

  req         UTL_HTTP.REQ;
  resp        UTL_HTTP.RESP;
  json_body   CLOB;
  buffer      VARCHAR2(32767);
BEGIN
  -- Consulta que traz os dados do paciente.
  SELECT 
      NVL(pf.nr_cpf, 'VAZIO') AS nrCpf,
      pf.nm_pessoa_fisica AS nome,
      NVL((SELECT cp2.nm_contato
           FROM compl_pessoa_fisica cp2
           WHERE cp2.cd_pessoa_fisica = pf.cd_pessoa_fisica
             AND cp2.ie_tipo_complemento = 5
           FETCH FIRST 1 ROWS ONLY), 'NAO INFORMADO') AS nmMae,
      TO_CHAR(pf.dt_nascimento, 'DD/MM/YYYY') AS dtNascimento,
      NVL(cp.nr_endereco, '0') AS nrResidencia,
      NVL(TO_CHAR(cp.cd_cep), '00000000') AS nrCep,
      NVL(cp.nr_telefone_celular, '000000000') AS nrCelular,
      CASE 
        WHEN pf.NR_SEQ_COR_PELE = 1 THEN 'BRANCA'
        WHEN pf.NR_SEQ_COR_PELE = 2 THEN 'PRETA'
        WHEN pf.NR_SEQ_COR_PELE = 11 THEN 'PARDA'
        WHEN pf.NR_SEQ_COR_PELE = 4 THEN 'AMARELA'
        WHEN pf.NR_SEQ_COR_PELE = 3 THEN 'INDÍGENA'
        ELSE 'NAO INFORMADA'
      END AS racaCor,
      pf.IE_SEXO AS sexo,
      CASE 
        WHEN pf.CD_NACIONALIDADE = 10 THEN 'BRASILEIRO'
        WHEN pf.CD_NACIONALIDADE = 20 THEN 'NATURALIZADO'
        ELSE 'ESTRANGEIRO'
      END AS nacionalidade,
      pf.nr_ddd_celular AS ddd
  INTO 
      nrCpf, nome, nmMae, dtNascimento, nrResidencia, nrCep, nrCelular, racaCor, sexo, nacionalidade, ddd
  FROM pessoa_fisica pf
  LEFT JOIN compl_pessoa_fisica cp ON pf.cd_pessoa_fisica = cp.cd_pessoa_fisica
  JOIN atendimento_paciente ap ON ap.cd_pessoa_fisica = pf.cd_pessoa_fisica
  JOIN atend_paciente_unidade apu ON ap.nr_atendimento = apu.nr_atendimento
  WHERE apu.nr_atendimento = (
    SELECT MAX(nr_atendimento)
    FROM atend_paciente_unidade
  )
  AND ROWNUM = 1;

  -- Criação do corpo JSON.
  json_body := '{
  "boletim": {
    "nmSetor":"HIZA - CTI - GERAL",
    "dsLeito":"QUALQUER3",
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

  DBMS_OUTPUT.PUT_LINE('JSON Body: ' || json_body);

  -- Autenticação.
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
  DBMS_OUTPUT.PUT_LINE('Auth Token: ' || auth_token);

  UTL_HTTP.END_RESPONSE(resp_login);

  -- Requisição com token.
  req := UTL_HTTP.begin_request('http://hom-esaudeprime.ici.curitiba.org.br/saude-ws/rest/censo-hospitalar', 'POST', 'HTTP/1.1');
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
