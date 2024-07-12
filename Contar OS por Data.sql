SELECT 
    NM_USUARIO_EXEC AS "Usu�rio Executor",
    COUNT(NR_SEQUENCIA) AS "N� de OS Resolvidas 07/24"
FROM 
    MAN_ORDEM_SERVICO
WHERE 
    NM_USUARIO_EXEC IN ('GUGRACA', 'ISRFERREIRA', 'JBRUGEFF', 'JTOMASCHITZ', 'LHOFMANN', 'MAPENA', 'vafilho', 'VAGSOUZA')
    AND DT_FIM_REAL BETWEEN TO_DATE('01/07/2024', 'DD/MM/YYYY') AND TO_DATE('12/07/2024', 'DD/MM/YYYY')
GROUP BY 
    NM_USUARIO_EXEC
ORDER BY
    "N� de OS Resolvidas 07/24" DESC;
