BEGIN
  DBMS_NETWORK_ACL_ADMIN.assign_acl (
    acl => 'http_access.xml', 
    host => 'wsldap.ici.curitiba.org.br'
  );
  COMMIT;
END;
