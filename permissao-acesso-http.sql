BEGIN
  DBMS_NETWORK_ACL_ADMIN.create_acl (
    acl         => 'http_access.xml', 
    description => 'Permissão para acessar HTTP', 
    principal   => 'TASY', 
    is_grant    => TRUE, 
    privilege   => 'connect'
  );
  COMMIT;
END;
