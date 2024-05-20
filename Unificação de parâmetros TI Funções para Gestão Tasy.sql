-- Seleciona informações das funções e seus parâmetros, comparando valores entre perfis "Gestão Tasy" e "TI Funções".
SELECT  
    fun.cd_funcao,                    -- Código da Função.
    fun.ds_funcao,                    -- Descrição da Função.
    fp.nr_sequencia,                  -- Número de Sequência do Parâmetro da Função.
    fp.ds_parametro,                  -- Descrição do Parâmetro da Função.
    
    -- Informações e valores do perfil "Gestão Tasy".
    per_gestao_tasy.ds_perfil perfil_gestao, 
    gestao_tasy.vl_parametro vl_gestao_tasy,  
    
    -- Informações e valores do perfil "TI Funções".
    per_ti_funcoes.ds_perfil AS perfil_ti_funcoes, 
    ti_funcoes.vl_parametro AS vl_ti_funcoes   
    
FROM funcao fun
-- Junta tabela de funções com tabela de parâmetros de funções.
INNER JOIN funcao_parametro fp ON fp.cd_funcao = fun.cd_funcao

-- Junta opcionalmente com parâmetros do perfil "Gestão Tasy" (cd_perfil = 1848).
LEFT JOIN funcao_param_perfil gestao_tasy
ON gestao_tasy.cd_funcao = fp.cd_funcao 
AND gestao_tasy.nr_sequencia = fp.nr_sequencia 
AND gestao_tasy.cd_perfil = 1848

LEFT JOIN perfil per_gestao_tasy
ON per_gestao_tasy.cd_perfil = gestao_tasy.cd_perfil

-- Junta opcionalmente com parâmetros do perfil "TI Funções" (cd_perfil = 1858).
LEFT JOIN funcao_param_perfil ti_funcoes
ON ti_funcoes.cd_funcao = fp.cd_funcao 
AND ti_funcoes.nr_sequencia = fp.nr_sequencia 
AND ti_funcoes.cd_perfil = 1858

LEFT JOIN perfil per_ti_funcoes
ON per_ti_funcoes.cd_perfil = ti_funcoes.cd_perfil

-- Condições para selecionar diferenças entre valores dos perfis "Gestão Tasy" e "TI Funções".
WHERE gestao_tasy.vl_parametro <> ti_funcoes.vl_parametro   -- Valores diferentes entre os dois perfis.
OR (gestao_tasy.vl_parametro IS NULL AND ti_funcoes.vl_parametro IS NOT NULL)  -- Valores apenas no perfil "TI Funções".   
ORDER BY 5;  -- Ordena pelo quinto campo selecionado (perfil_gestao).

-- Análise dos resultados:
-- Foi identificado um único parâmetro para UPDATE, mas não necessário pois o valor no "Gestão Tasy" é mais abrangente.
-- Todos os valores presentes exclusivamente no perfil "TI Funções" podem ser inseridos no "Gestão Tasy".

-- Inserção de novos parâmetros no perfil "Gestão Tasy" baseados nos valores do perfil "TI Funções".
INSERT INTO funcao_param_perfil (cd_funcao, nr_sequencia, cd_perfil, dt_atualizacao, nm_usuario, vl_parametro, ds_observacao, cd_estabelecimento, nr_seq_interno)

-- Seleciona parâmetros exclusivos do perfil "TI Funções" para inserção no perfil "Gestão Tasy".
SELECT  
    fun.cd_funcao,                     -- Código da Função.
    fp.nr_sequencia,                   -- Número de Sequência do Parâmetro da Função.
    1848 cd_perfil,                    -- Código do Perfil "Gestão Tasy".
    SYSDATE,                           -- Data de Atualização.
    'VAFILHO',                         -- Nome do Usuário que está atualizando.
    ti_funcoes.vl_parametro,           -- Valor do Parâmetro do Perfil "TI Funções".
    'Unificação de Perfis: valor recebido do perfil TI FUNCOES' obs,  -- Observação.
    NULL,                              -- Código do Estabelecimento (nulo).
    funcao_param_perfil_seq.nextval    -- Sequência Interna (próximo valor da sequência).
FROM funcao fun
INNER JOIN funcao_parametro fp
ON fp.cd_funcao = fun.cd_funcao
LEFT JOIN funcao_param_perfil gestao_tasy
ON gestao_tasy.cd_funcao = fp.cd_funcao 
AND gestao_tasy.nr_sequencia = fp.nr_sequencia 
AND gestao_tasy.cd_perfil = 1848
LEFT JOIN perfil per_gestao_tasy
ON per_gestao_tasy.cd_perfil = gestao_tasy.cd_perfil
LEFT JOIN funcao_param_perfil ti_funcoes
ON ti_funcoes.cd_funcao = fp.cd_funcao 
AND ti_funcoes.nr_sequencia = fp.nr_sequencia 
AND ti_funcoes.cd_perfil = 1858
LEFT JOIN perfil per_ti_funcoes
ON per_ti_funcoes.cd_perfil = ti_funcoes.cd_perfil
WHERE gestao_tasy.vl_parametro IS NULL 
AND ti_funcoes.vl_parametro IS NOT NULL;

COMMIT; -- Confirma as inserções feitas na tabela.

/*
Resumo da Operação:

Análise de Diferenças: Seleciona e compara os parâmetros entre os perfis "Gestão Tasy" e "TI Funções", identificando os que possuem valores diferentes ou que existem apenas no "TI Funções".

Inserção de Novos Parâmetros: Insere os parâmetros exclusivos do perfil "TI Funções" no perfil "Gestão Tasy" com observação de unificação de perfis.

O script compara os valores dos parâmetros entre os dois perfis e prepara a inserção dos parâmetros que existem apenas no "TI Funções" para o "Gestão Tasy", facilitando a unificação dos perfis.
*/
