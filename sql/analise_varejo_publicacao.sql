-- Projeto: Analise do varejo brasileiro (jul/2025 a jul/2026)
-- Fonte: IBGE/PMC, Tabela 5, julho de 2026
-- Pre-requisito: banco portfolio_varejo e tabela pmc_varejo previamente criados e populados.
-- Este script cria apenas views analiticas; nao contem credenciais ou administracao de usuarios.

USE portfolio_varejo;

CREATE OR REPLACE VIEW vw_atividades AS
SELECT
    data,
    ano,
    mes,
    codigo_atividade,
    atividade,
    indice_volume_vendas
FROM pmc_varejo
WHERE tipo_indicador = 'Atividade';

CREATE OR REPLACE VIEW vw_variacao_anual AS
SELECT
    a.atividade,
    a.data AS data_inicial,
    b.data AS data_final,
    ROUND(a.indice_volume_vendas, 2) AS indice_inicial,
    ROUND(b.indice_volume_vendas, 2) AS indice_final,
    ROUND(
        ((b.indice_volume_vendas / a.indice_volume_vendas) - 1) * 100,
        2
    ) AS variacao_percentual
FROM pmc_varejo a
INNER JOIN pmc_varejo b
    ON a.atividade = b.atividade
    AND b.data = DATE_ADD(a.data, INTERVAL 12 MONTH)
WHERE
    a.tipo_indicador = 'Atividade'
    AND b.tipo_indicador = 'Atividade';
    
CREATE OR REPLACE VIEW vw_volatilidade AS
SELECT
    atividade,
    ROUND(AVG(indice_volume_vendas), 2) AS media,
    ROUND(MIN(indice_volume_vendas), 2) AS minimo,
    ROUND(MAX(indice_volume_vendas), 2) AS maximo,
    ROUND(STDDEV_SAMP(indice_volume_vendas), 2) AS desvio_padrao,
    ROUND(
        STDDEV_SAMP(indice_volume_vendas)
        / AVG(indice_volume_vendas) * 100,
        2
    ) AS cv_percentual
FROM pmc_varejo
WHERE tipo_indicador = 'Atividade'
GROUP BY atividade;

CREATE OR REPLACE VIEW vw_variacao_mensal AS
SELECT
    data,
    atividade,
    indice_volume_vendas,
    ROUND(
        ((indice_volume_vendas / indice_anterior) - 1) * 100,
        2
    ) AS variacao_mensal
FROM (
    SELECT
        data,
        atividade,
        indice_volume_vendas,
        LAG(indice_volume_vendas) OVER (
            PARTITION BY atividade
            ORDER BY data
        ) AS indice_anterior
    FROM pmc_varejo
    WHERE tipo_indicador = 'Atividade'
) AS dados;

SHOW FULL TABLES
WHERE Table_type = 'VIEW';
