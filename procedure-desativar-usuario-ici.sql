CREATE OR REPLACE PROCEDURE desativa_usuario_ici (cd_pessoa_fisica_p NUMBER)
IS
  
    nm_pessoa_fisica_w VARCHAR2(250);
    nr_cpf_w VARCHAR2(15);
    nm_usuario_w VARCHAR2(50);
    dt_admissao_w DATE;
    dt_demissao_w DATE;
    nr_seq_os_w NUMBER(12);
    ie_sit_usuario_w CHAR(1);
    ds_texto_os_w VARCHAR2(400);
    cd_funcionario_w VARCHAR2(15);
    ie_status_exportar_w CHAR(1);
    nr_celular_w VARCHAR2(16);
    nr_ddd_celular_w VARCHAR2(2);
    vReq UTL_HTTP.req;
    vResp UTL_HTTP.resp;
    vUrl VARCHAR2(32767);
    vBody VARCHAR2(32767);
    vOutput VARCHAR2(32767);
    sucesso BOOLEAN := FALSE;
    
BEGIN
    SELECT  p.nm_pessoa_fisica,
            p.nr_cpf,
            p.dt_demissao_hosp,
            p.dt_admissao_hosp,
            u.nm_usuario,
            u.ie_situacao,
            p.cd_funcionario,
            p.ie_status_exportar,
            p.nr_ddd_celular,
            p.nr_telefone_celular
    INTO    nm_pessoa_fisica_w,
            nr_cpf_w,
            dt_demissao_w,
            dt_admissao_w,
            nm_usuario_w,
            ie_sit_usuario_w,
            cd_funcionario_w,
            ie_status_exportar_w,
            nr_ddd_celular_w,
            nr_celular_w
    FROM    pessoa_fisica p
    LEFT JOIN usuario u ON u.cd_pessoa_fisica = p.cd_pessoa_fisica
    WHERE p.cd_pessoa_fisica = cd_pessoa_fisica_p;

    ds_texto_os_w := '' || 
      'Inativar o acesso a rede, e-mail e internet do usuário abaixo.' || CHR(10) || CHR(13) ||
      'Verificar se possui login no PACS (suite, arya, webviewer) e acesso à bilhetagem.' || CHR(10) || CHR(13) ||
      'Nome: ' || nm_pessoa_fisica_w || CHR(13) ||
      'CPF: ' || nr_cpf_w || CHR(13) ||
      'Login: ' || nm_usuario_w || CHR(13) ||
      'Matrícula: ' || cd_funcionario_w || CHR(13) ||
      'Data Dem.: ' || TO_CHAR(dt_demissao_w, 'dd/mm/yyyy') || CHR(13) ||
      'Telefone Celular: (' || TO_CHAR(NVL(nr_ddd_celular_w, '00')) || ') ' || TO_CHAR(NVL(nr_celular_w, '00000-0000'));
      
    IF ( dt_demissao_w IS NOT NULL AND ie_status_exportar_w = 'D') THEN
        IF ( dt_demissao_w >= dt_admissao_w ) THEN
            SELECT man_ordem_servico_seq.nextval INTO nr_seq_os_w FROM dual;
            INSERT INTO man_ordem_servico(
                nr_sequencia,
                nr_seq_localizacao,
                nr_seq_equipamento,
                cd_pessoa_solicitante,
                dt_ordem_servico,
                ie_prioridade,
                ie_parado,
                ds_dano_breve,
                dt_atualizacao,
                nm_usuario,
                dt_inicio_desejado,
                dt_conclusao_desejada,
                ds_dano,
                ie_tipo_ordem,
                ie_status_ordem,
                nr_grupo_planej,
                nr_grupo_trabalho,
                nr_seq_estagio,
                ie_classificacao,
                nr_seq_causa_dano,
                ie_forma_receb,
                dt_atualizacao_nrec,
                nm_usuario_nrec,
                ie_obriga_news,
                ds_contato_solicitante,
                ie_origem_os,
                ds_maquina_criacao,
                cd_centro_custo_os,
                nr_seq_tipo_solucao,
                nr_seq_complex,
                NR_SEQ_TIPO_ORDEM 
            ) VALUES (
                nr_seq_os_w, 
                6060,
                22120, 
                cd_pessoa_fisica_p,
                SYSDATE,
                'M',
                'N',
                'Inativar Usuário (Automático)' || ' - Login: ' || nm_usuario_w,
                SYSDATE,
                'TASY',
                SYSDATE, 
                SYSDATE,
                ds_texto_os_w,
                0,
                1,
                11,
                91,
                21,
                'S',
                6,
                'I',
                SYSDATE,
                'TASY',
                'S',
                'Ramal: 5999',
                4,
                'PC-30495',
                717,
                50,
                1,
                8
            );
                  
            INSERT INTO man_ordem_servico_exec(
                nr_sequencia,
                nr_seq_ordem,
                dt_atualizacao,
                dt_atualizacao_nrec,
                nm_usuario_exec,
                nm_usuario,
                nm_usuario_nrec
            ) 
            SELECT man_ordem_servico_exec_seq.nextval, nr_seq_os_w, SYSDATE, SYSDATE, nm_usuario_param, 'TASY', 'TASY'
            FROM man_grupo_trab_usuario
            WHERE nr_seq_grupo_trab = 91;

            -- Endpoint do método do ICI "desativarUsuario".
            vUrl := 'https://opendc-desenv.ici.curitiba.org.br/opendcws/webresources/openDocAutenticar/desativarUsuario';
            
            -- Parâmetros de acesso ao método do ICI "desativarUsuario".
            vBody := '{"contaUsuario": "rhfeas", "senhaUsuario": "{MD5}stH0dW6UkG0C8eMYiAtgAA==", "cpf": "' || nr_cpf_w || '"}';
            
            -- Caminho e senha para o acesso ao wallet (consumo do certificado SSL).
            UTL_HTTP.set_wallet('file:/u01/app/oracle/admin/tasy/wallet', 'a21de42193');
            
            -- Criação da requisição HTTP POST.
            vReq := UTL_HTTP.begin_request(vUrl, 'POST', 'HTTP/1.1');
            
            -- Definição do cabeçalho Content-Type para application/json.
            UTL_HTTP.set_header(vReq, 'Content-Type', 'application/json');
            UTL_HTTP.set_header(vReq, 'Content-Length', LENGTH(vBody));
            
            -- Escrita no corpo da requisição.
            UTL_HTTP.write_text(vReq, vBody);
            
            -- Envio da requisição e obtenção da resposta.
            vResp := UTL_HTTP.get_response(vReq);
            
            -- Verificação do consumo do web service.
            IF vResp.status_code = 200 THEN
                sucesso := TRUE;
                UTL_HTTP.read_text(vResp, vOutput);
                -- Verificação do conteúdo da resposta para determinar se o usuário foi desativado.
                IF vOutput = '{"resultado":"true"}' THEN
                    DBMS_OUTPUT.put_line('Usuário desativado com sucesso!');
                    
                    -- Fechamento das OS.
                    UPDATE MAN_ORDEM_SERVICO
                    SET IE_STATUS_ORDEM = 3, NR_SEQ_ESTAGIO = 12, NM_USUARIO = 'VAFILHO', NM_USUARIO_EXEC = 'VAFILHO',
                        DT_INICIO_REAL = SYSDATE, DT_FIM_REAL = SYSDATE
                    WHERE NR_SEQUENCIA = nr_seq_os_w;
                ELSE
                    DBMS_OUTPUT.put_line('Falha ao desativar o usuário!' || vOutput);
                END IF;                
            ELSE
                sucesso := FALSE;
                DBMS_OUTPUT.put_line('Falha na requisição. Código de status: ' || vResp.status_code);
            END IF;

            -- Fechamento da requisição.
            UTL_HTTP.end_response(vResp);
            
            COMMIT;
        END IF;
    END IF;
    
END desativa_usuario_ici;
