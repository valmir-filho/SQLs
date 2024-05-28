-- Seleciona informa��es das fun��es e seus par�metros, comparando valores entre perfis "Gest�o Tasy" e "T�cnico em Inform�tica".
SELECT  
    fun.cd_funcao,                      -- C�digo da Fun��o.
    fun.ds_funcao,                      -- Descri��o da Fun��o.
    fp.nr_sequencia,                    -- N�mero de Sequ�ncia do Par�metro da Fun��o.
    fp.ds_parametro,                    -- Descri��o do Par�metro da Fun��o.
    
    -- Informa��es e valores do perfil "Gest�o Tasy".
    per_gestao_tasy.ds_perfil AS perfil_gestao, 
    gestao_tasy.vl_parametro AS vl_gestao_tasy,  
    
    -- Informa��es e valores do perfil "T�cnico em Inform�tica".
    per_tec_inf.ds_perfil AS perfil_tec_inf, 
    tec_inf.vl_parametro AS vl_tec_inf   
    
FROM funcao fun
INNER JOIN funcao_parametro fp ON fp.cd_funcao = fun.cd_funcao

-- Junta opcionalmente com par�metros do perfil "Gest�o Tasy" (cd_perfil = 1848).
LEFT JOIN funcao_param_perfil gestao_tasy
    ON gestao_tasy.cd_funcao = fp.cd_funcao 
    AND gestao_tasy.nr_sequencia = fp.nr_sequencia 
    AND gestao_tasy.cd_perfil = 1848

LEFT JOIN perfil per_gestao_tasy
    ON per_gestao_tasy.cd_perfil = gestao_tasy.cd_perfil

-- Junta opcionalmente com par�metros do perfil "T�cnico em Inform�tica" (cd_perfil = 2154).
LEFT JOIN funcao_param_perfil tec_inf
    ON tec_inf.cd_funcao = fp.cd_funcao 
    AND tec_inf.nr_sequencia = fp.nr_sequencia 
    AND tec_inf.cd_perfil = 2154

LEFT JOIN perfil per_tec_inf
    ON per_tec_inf.cd_perfil = tec_inf.cd_perfil

-- Condi��es para selecionar diferen�as entre valores dos perfis "Gest�o Tasy" e "T�cnico em Inform�tica".
WHERE gestao_tasy.vl_parametro <> tec_inf.vl_parametro   -- Valores diferentes entre os dois perfis.
    OR (gestao_tasy.vl_parametro IS NULL AND tec_inf.vl_parametro IS NOT NULL)  -- Valores apenas no perfil "T�cnico em Inform�tica".

ORDER BY 5;  -- Ordena pelo quinto campo selecionado (perfil_gestao).

-- Inser��o de novos par�metros no perfil "Gest�o Tasy" baseados nos valores do perfil "T�cnico em Inform�tica".
INSERT INTO funcao_param_perfil (cd_funcao, nr_sequencia, cd_perfil, dt_atualizacao, nm_usuario, vl_parametro, ds_observacao, cd_estabelecimento, nr_seq_interno)
SELECT  
    fun.cd_funcao,                       -- C�digo da Fun��o.
    fp.nr_sequencia,                     -- N�mero de Sequ�ncia do Par�metro da Fun��o.
    1848 AS cd_perfil,                   -- C�digo do Perfil "Gest�o Tasy".
    SYSDATE,                             -- Data de Atualiza��o.
    'VAFILHO' AS nm_usuario,             -- Nome do Usu�rio que est� atualizando.
    tec_inf.vl_parametro,                -- Valor do Par�metro do Perfil "TI Fun��es".
    'Unifica��o de Perfis: valor recebido do perfil TI FUNCOES' AS ds_observacao,  -- Observa��o.
    NULL AS cd_estabelecimento,          -- C�digo do Estabelecimento (nulo).
    funcao_param_perfil_seq.nextval      -- Sequ�ncia Interna (pr�ximo valor da sequ�ncia).
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
COMMIT; -- Confirma as inser��es feitas na tabela.

/*
Resumo da Opera��o:

An�lise de Diferen�as: Seleciona e compara os par�metros entre os perfis "Gest�o Tasy" e "T�cnico em Inform�tica", identificando os que possuem valores diferentes ou que existem apenas no "T�cnico em Inform�tica".

Inser��o de Novos Par�metros: Insere os par�metros exclusivos do perfil "T�cnico em Inform�tica" no perfil "Gest�o Tasy" com observa��o de unifica��o de perfis.

O script compara os valores dos par�metros entre os dois perfis e prepara a inser��o dos par�metros que existem apenas no "T�cnico em Inform�tica" para o "Gest�o Tasy", facilitando a unifica��o dos perfis.
*/