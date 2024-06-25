PROCEDURE send_mail IS

  -- Parâmetros de configuração do servidor SMTP e credenciais de autenticação.
  p_mail_server_ip    VARCHAR(20)   := '172.31.11.10';
  p_port              NUMBER        := 587;
  p_sender            VARCHAR2(256) := 'tifeas@feas.curitiba.pr.gov.br';
  p_username          VARCHAR2(256) := 'tifeas@feas.curitiba.pr.gov.br';
  p_password          VARCHAR2(256) := '#!t3c2022@dm';
  p_email             VARCHAR(256)  := 'service@itscon.com.br';
  p_subject           VARCHAR(256)  := 'Inativar PIN Colaborador FEAS';

  -- Variáveis para manipulação da conexão SMTP e formatação do email.
  mailhost            VARCHAR2(100) := p_mail_server_ip;
  mail_conn           UTL_SMTP.connection;
  conn_reply          UTL_SMTP.reply;
  crlf                VARCHAR2(2)   := CHR(13) || CHR(10);
  p_body              VARCHAR2(32000) := '';

BEGIN
  -- Constrói o corpo do email com base nos resultados da query.
  FOR r IN (SELECT ds_usuario || ' - PIN: ' || nm_usuario_github AS aux
            FROM usuario
            WHERE nm_usuario_github IS NOT NULL
              AND ie_situacao = 'I'
            ORDER BY ds_usuario) LOOP
    p_body := p_body || r.aux || '<br>' || crlf;
  END LOOP;

  -- Formata o corpo do email como HTML.
  p_body := '<html><body><font color="blue" face="Verdana" size="2">' || p_body || '</font></body></html>';

  -- Abre a conexão SMTP.
  conn_reply := UTL_SMTP.open_connection(HOST => mailhost, port => p_port, c => mail_conn);
  UTL_SMTP.helo(mail_conn, mailhost);

  -- Inicia a autenticação SMTP usando AUTH LOGIN.
  UTL_SMTP.command(mail_conn, 'AUTH LOGIN');
  UTL_SMTP.command(mail_conn, 'ZGJhX21vbml0b3JhbWVudG9AaWNpLmN1cml0aWJhLm9yZy5icg=='); -- Base64 do username.
  UTL_SMTP.command(mail_conn, 'a2RBTjFvWVhobjRhQlhKZkNySG4='); -- Base64 da senha

  -- Configuração do email: remetente, destinatário, assunto e conteúdo.
  UTL_SMTP.mail(mail_conn, p_sender);
  UTL_SMTP.rcpt(mail_conn, p_email);
  UTL_SMTP.open_data(mail_conn);
  UTL_SMTP.write_data(mail_conn, 'From: ' || '<' || p_sender || '>' || crlf);
  UTL_SMTP.write_data(mail_conn, 'To: ' || p_email || crlf);
  UTL_SMTP.write_data(mail_conn, 'Subject: ' || p_subject || crlf);
  UTL_SMTP.write_data(mail_conn, 'MIME-Version: ' || '1.0' || crlf);
  UTL_SMTP.write_data(mail_conn, 'Content-Type: ' || 'text/html;' || crlf);
  UTL_SMTP.write_data(mail_conn, 'Content-Transfer-Encoding: ' || '"8Bit"' || crlf);
  UTL_SMTP.write_data(mail_conn, crlf);
  UTL_SMTP.write_data(mail_conn, p_body);
  UTL_SMTP.close_data(mail_conn);

  -- Finaliza a sessão SMTP.
  UTL_SMTP.quit(mail_conn);
  
  -- Atualiza os registros na tabela usuario após envio bem-sucedido do email.
  UPDATE usuario SET nm_usuario_github = NULL WHERE nm_usuario_github IS NOT NULL AND ie_situacao = 'I';

  COMMIT;
  
EXCEPTION
  -- Tratamento de erros SMTP.
  WHEN UTL_SMTP.transient_error OR UTL_SMTP.permanent_error THEN
    BEGIN
      UTL_SMTP.quit(mail_conn); -- Finaliza a conexão em caso de erro.
    EXCEPTION
      WHEN UTL_SMTP.transient_error OR UTL_SMTP.permanent_error OR UTL_SMTP.INVALID_OPERATION THEN
        NULL;    -- Ignora erros específicos de SMTP.
    END;
    raise_application_error(-20000, 'Failed to send mail due to the following error: ' || SQLERRM);
END send_mail;
