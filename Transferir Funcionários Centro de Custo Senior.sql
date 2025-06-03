/*
Inserção de novo registro na tabela de histórico de centro de custo (R038HCC)
da Senior para colaboradores ATIVOS cujo centro de custo ATUAL é '717',
transferindo-os para o novo centro de custo '9020'.
*/

INSERT INTO R038HCC (
    NUMEMP,    -- Número da empresa.
    TIPCOL,    -- Tipo de colaborador.
    NUMCAD,    -- Número do cadastro (identificador do colaborador).
    DATALT,    -- Data da alteração (novo histórico).
    CODCCU,    -- Novo centro de custo a ser atribuído.
    STAHIS,    -- Status histórico.
    CONFIN     -- Código de configuração interna.
)
SELECT 
    h.NUMEMP,                 -- Mantém a empresa original do colaborador.
    h.TIPCOL,                 -- Mantém o tipo de colaborador original.
    h.NUMCAD,                 -- Mantém o mesmo número de cadastro.
    h.DATALT + 1,             -- Nova data: 1 dia após a última alteração registrada.
    '9020',                   -- Novo centro de custo.
    h.STAHIS,                 -- Mantém o status histórico.
    h.CONFIN                  -- Mantém a configuração interna.
FROM R038HCC h
-- Garante que estamos pegando apenas o registro mais recente (centro de custo atual).
JOIN (
    SELECT 
        NUMEMP, 
        TIPCOL, 
        NUMCAD, 
        MAX(DATALT) AS DATALT
    FROM R038HCC
    GROUP BY NUMEMP, TIPCOL, NUMCAD
) ult
  ON h.NUMEMP = ult.NUMEMP
 AND h.TIPCOL = ult.TIPCOL
 AND h.NUMCAD = ult.NUMCAD
 AND h.DATALT = ult.DATALT
-- Junta com a tabela de funcionários para considerar apenas os ativos.
JOIN R034FUN f
  ON h.NUMEMP = f.NUMEMP
 AND h.TIPCOL = f.TIPCOL
 AND h.NUMCAD = f.NUMCAD
WHERE h.CODCCU = '717'        -- Somente os que atualmente estão no centro de custo 717.
  AND f.SITAFA = 1;           -- E que estão com situação ativa.
