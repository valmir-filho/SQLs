-- Seleciona informações das funções e seus parâmetros, comparando valores entre perfis "Gestão Tasy" e "Técnico em Informática".
SELECT  
    fun.cd_funcao,                      -- Código da Função.
    fun.ds_funcao,                      -- Descrição da Função.
    fp.nr_sequencia,                    -- Número de Sequência do Parâmetro da Função.
    fp.ds_parametro,                    -- Descrição do Parâmetro da Função.
    
    -- Informações e valores do perfil "Gestão Tasy".
    per_gestao_tasy.ds_perfil AS perfil_gestao, 
    gestao_tasy.vl_parametro AS vl_gestao_tasy,  
    
    -- Informações e valores do perfil "Técnico em Informática".
    per_tec_inf.ds_perfil AS perfil_tec_inf, 
    tec_inf.vl_parametro AS vl_tec_inf   
    
FROM funcao fun
INNER JOIN funcao_parametro fp ON fp.cd_funcao = fun.cd_funcao

-- Junta opcionalmente com parâmetros do perfil "Gestão Tasy" (cd_perfil = 1848).
LEFT JOIN funcao_param_perfil gestao_tasy
    ON gestao_tasy.cd_funcao = fp.cd_funcao 
    AND gestao_tasy.nr_sequencia = fp.nr_sequencia 
    AND gestao_tasy.cd_perfil = 1848

LEFT JOIN perfil per_gestao_tasy
    ON per_gestao_tasy.cd_perfil = gestao_tasy.cd_perfil

-- Junta opcionalmente com parâmetros do perfil "Técnico em Informática" (cd_perfil = 2154).
LEFT JOIN funcao_param_perfil tec_inf
    ON tec_inf.cd_funcao = fp.cd_funcao 
    AND tec_inf.nr_sequencia = fp.nr_sequencia 
    AND tec_inf.cd_perfil = 2154

LEFT JOIN perfil per_tec_inf
    ON per_tec_inf.cd_perfil = tec_inf.cd_perfil

-- Condições para selecionar diferenças entre valores dos perfis "Gestão Tasy" e "Técnico em Informática".
WHERE gestao_tasy.vl_parametro <> tec_inf.vl_parametro   -- Valores diferentes entre os dois perfis.
    OR (gestao_tasy.vl_parametro IS NULL AND tec_inf.vl_parametro IS NOT NULL)  -- Valores apenas no perfil "Técnico em Informática".

ORDER BY 5;  -- Ordena pelo quinto campo selecionado (perfil_gestao).

-- Inserção de novos parâmetros no perfil "Gestão Tasy" baseados nos valores do perfil "Técnico em Informática".
INSERT INTO funcao_param_perfil (cd_funcao, nr_sequencia, cd_perfil, dt_atualizacao, nm_usuario, vl_parametro, ds_observacao, cd_estabelecimento, nr_seq_interno)
SELECT  
    fun.cd_funcao,                       -- Código da Função.
    fp.nr_sequencia,                     -- Número de Sequência do Parâmetro da Função.
    1848 AS cd_perfil,                   -- Código do Perfil "Gestão Tasy".
    SYSDATE,                             -- Data de Atualização.
    'VAFILHO' AS nm_usuario,             -- Nome do Usuário que está atualizando.
    tec_inf.vl_parametro,                -- Valor do Parâmetro do Perfil "TI Funções".
    'Unificação de Perfis: valor recebido do perfil TI FUNCOES' AS ds_observacao,  -- Observação.
    NULL AS cd_estabelecimento,          -- Código do Estabelecimento (nulo).
    funcao_param_perfil_seq.nextval      -- Sequência Interna (próximo valor da sequência).
FROM funcao fun
INNER JOIN funcao_parametro fp ON fp.cd_funcao = fun.cd_funcao
LEFT JOIN funcao_param_perfil gestao_tasy
    ON gestao_tasy.cd_funcao = fp.cd_funcao 
    AND gestao_tasy.nr_sequencia = fp.nr_sequencia 
    AND gestao_tasy.cd_perfil = 1848
LEFT JOIN perfil per_gestao_tasy
    ON per_gestao_tasy.cd_perfil = gestao_tasy.cd_perfil
LEFT JOIN funcao_param_perfil tec_inf
    ON tec_inf.cd_funcao = fp.cd_funcao 
    AND tec_inf.nr_sequencia = fp.nr_sequencia 
    AND tec_inf.cd_perfil = 2154
LEFT JOIN perfil per_tec_inf
    ON per_tec_inf.cd_perfil = tec_inf.cd_perfil
WHERE gestao_tasy.vl_parametro IS NULL 
    AND tec_inf.vl_parametro IS NOT NULL;
/
COMMIT; -- Confirma as inserções feitas na tabela.

/*
Resumo da Operação:

Análise de Diferenças: Seleciona e compara os parâmetros entre os perfis "Gestão Tasy" e "Técnico em Informática", identificando os que possuem valores diferentes ou que existem apenas no "Técnico em Informática".

Inserção de Novos Parâmetros: Insere os parâmetros exclusivos do perfil "Técnico em Informática" no perfil "Gestão Tasy" com observação de unificação de perfis.

O script compara os valores dos parâmetros entre os dois perfis e prepara a inserção dos parâmetros que existem apenas no "Técnico em Informática" para o "Gestão Tasy", facilitando a unificação dos perfis.
*/