-- =====================================================
--  ANÁLISE DE FATURAMENTO - SALÃO DE BELEZA
-- =====================================================
-- Sistema completo de análise de performance e segmentação de clientes
-- Autor: [Seu Nome]
-- Data: Setembro 2025

-- =====================================================
--  ESTRUTURA DO BANCO DE DADOS
-- =====================================================

-- Criação do banco de dados
IF DB_ID('Atendimentos') IS NULL
BEGIN
    CREATE DATABASE Atendimentos;
END;
USE Atendimentos;

-- Tabela: Servico
IF OBJECT_ID('Servico', 'U') IS NOT NULL DROP TABLE Servico;
CREATE TABLE Servico
(
    IDServico SMALLINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    Descricao VARCHAR(255) NOT NULL
);

-- Tabela: ControleAtendimento
IF OBJECT_ID('ControleAtendimento', 'U') IS NOT NULL DROP TABLE ControleAtendimento;
CREATE TABLE ControleAtendimento
(
    ID_Dados SMALLINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    Data DATE NOT NULL DEFAULT GETDATE(),
    Comanda INT NOT NULL CHECK (Comanda > 0),
    Cliente VARCHAR(255) NOT NULL,
    Servico SMALLINT NOT NULL,
    Valores DECIMAL(10,2) NOT NULL CHECK (Valores >= 0),
    TipoPagamento VARCHAR(20) NOT NULL CHECK (TipoPagamento IN ('Dinheiro', 'VC', 'PIX', 'VE')),
    SaoClientes VARCHAR(10) CHECK (SaoClientes IN ('Sim', 'Não')),
    TipoAtendimento VARCHAR(20) CHECK (TipoAtendimento IN ('Salão', 'Domicilio')),
    CONSTRAINT FK_ControleAtendimento_Servico FOREIGN KEY (Servico) REFERENCES Servico(IDServico)
);

-- =====================================================
--  INSERÇÃO DE DADOS DE EXEMPLO
-- =====================================================

INSERT INTO Servico (Descricao)
VALUES 
('Corte Masculino'),
('Penteado'),
('Barba'),
('Coloração'),
('Corte Feminino');

INSERT INTO ControleAtendimento (Data, Comanda, Cliente, Servico, Valores, TipoPagamento, SaoClientes, TipoAtendimento)
VALUES 
('2025-01-15', 100, 'Cliente 01', 1, 30.00, 'PIX', 'Sim', 'Salão'),
('2025-01-15', 101, 'Cliente 02', 2, 45.00, 'Dinheiro', 'Não', 'Salão'),
('2025-01-16', 102, 'Cliente 03', 3, 20.00, 'VC', 'Sim', 'Domicilio'),
('2025-01-16', 103, 'Cliente 04', 4, 80.00, 'PIX', 'Sim', 'Salão'),
('2025-01-17', 104, 'Cliente 05', 1, 35.00, 'VE', 'Não', 'Salão');

-- =====================================================
--  SEGMENTAÇÃO E ANÁLISE DE CLIENTES
-- =====================================================

WITH ClassificacaoCliente AS (
    SELECT 
        Cliente,
        SUM(Valores) AS total_gasto,
        COUNT(*) AS total_atendimentos,
        ROUND(AVG(Valores), 2) AS ticket_medio,
        MAX(Data) AS ultima_visita,
        MIN(Data) AS primeira_visita,
        DATEDIFF(DAY, MIN(Data), MAX(Data)) AS dias_como_cliente,
        CASE 
            WHEN SUM(Valores) > 300 THEN 'VIP'
            WHEN SUM(Valores) BETWEEN 250 AND 300 THEN 'Premium'
            ELSE 'Regular'
        END AS categoria_cliente
    FROM ControleAtendimento
    GROUP BY Cliente
)
SELECT 
    Cliente,
    total_atendimentos,
    total_gasto,
    ticket_medio,
    FORMAT(ultima_visita, 'dd/MM/yyyy') AS ultima_visita,
    FORMAT(primeira_visita, 'dd/MM/yyyy') AS primeira_visita,
    dias_como_cliente,
    categoria_cliente
FROM ClassificacaoCliente
ORDER BY total_gasto DESC;

-- =====================================================
--  RESUMO POR CATEGORIA DE CLIENTE
-- =====================================================

WITH ClassificacaoCliente AS (
    SELECT 
        Cliente,
        SUM(Valores) AS total_gasto,
        COUNT(*) AS total_atendimentos,
        CASE 
            WHEN SUM(Valores) > 300 THEN 'VIP'
            WHEN SUM(Valores) BETWEEN 250 AND 300 THEN 'Premium'
            ELSE 'Regular'
        END AS categoria_cliente
    FROM ControleAtendimento
    GROUP BY Cliente
)
SELECT 
    categoria_cliente,
    COUNT(*) AS quantidade_clientes,
    SUM(total_gasto) AS faturamento_categoria,
    ROUND(AVG(total_gasto), 2) AS gasto_medio_categoria,
    ROUND((SUM(total_gasto) * 100.0 / (SELECT SUM(Valores) FROM ControleAtendimento)), 2) AS percentual_faturamento
FROM ClassificacaoCliente
GROUP BY categoria_cliente
ORDER BY faturamento_categoria DESC;

-- =====================================================
--  ANÁLISE DE TICKET MÉDIO
-- =====================================================

-- Métricas gerais
SELECT 
    COUNT(*) AS total_atendimentos,
    COUNT(DISTINCT Cliente) AS clientes_unicos,
    SUM(Valores) AS faturamento_total,
    ROUND(AVG(Valores), 2) AS ticket_medio,
    MAX(Valores) AS maior_venda,
    MIN(Valores) AS menor_venda
FROM ControleAtendimento;

-- Análise de impacto dos atendimentos acima da média
WITH AnaliseTicket AS (
    SELECT 
        (SELECT SUM(Valores) 
         FROM ControleAtendimento 
         WHERE Valores >= (SELECT AVG(Valores) FROM ControleAtendimento)
        ) AS faturamento_acima_media,
        (SELECT SUM(Valores) FROM ControleAtendimento) AS faturamento_total,
        (SELECT COUNT(*) 
         FROM ControleAtendimento 
         WHERE Valores >= (SELECT AVG(Valores) FROM ControleAtendimento)
        ) AS atendimentos_acima_media,
        (SELECT COUNT(*) FROM ControleAtendimento) AS total_atendimentos
)
SELECT 
    faturamento_acima_media,
    faturamento_total,
    atendimentos_acima_media,
    total_atendimentos,
    ROUND((faturamento_acima_media * 100.0 / faturamento_total), 2) AS percentual_faturamento,
    ROUND((atendimentos_acima_media * 100.0 / total_atendimentos), 2) AS percentual_atendimentos
FROM AnaliseTicket;

-- =====================================================
--  TOP PERFORMERS
-- =====================================================

-- Top 5 Clientes
SELECT TOP 5
    Cliente,
    SUM(Valores) AS total_gasto,
    COUNT(*) AS total_atendimentos,
    ROUND(AVG(Valores), 2) AS ticket_medio
FROM ControleAtendimento
GROUP BY Cliente
ORDER BY SUM(Valores) DESC;

-- Top 5 Serviços
SELECT TOP 5
    s.Descricao,
    COUNT(*) AS quantidade_vendida,
    SUM(c.Valores) AS faturamento_servico,
    ROUND(AVG(c.Valores), 2) AS ticket_medio_servico
FROM ControleAtendimento c
INNER JOIN Servico s ON c.Servico = s.IDServico
GROUP BY s.Descricao
ORDER BY SUM(c.Valores) DESC;

-- =====================================================
--  ANÁLISE TEMPORAL
-- =====================================================

-- Performance por dia da semana
SELECT 
    DATENAME(WEEKDAY, Data) AS dia_semana,
    COUNT(*) AS total_atendimentos,
    SUM(Valores) AS faturamento_dia,
    ROUND(AVG(Valores), 2) AS ticket_medio_dia
FROM ControleAtendimento
GROUP BY DATENAME(WEEKDAY, Data), DATEPART(WEEKDAY, Data)
ORDER BY DATEPART(WEEKDAY, Data);

-- Análise mensal (últimos 12 meses)
SELECT 
    YEAR(Data) AS ano,
    MONTH(Data) AS mes,
    DATENAME(MONTH, Data) AS nome_mes,
    COUNT(*) AS total_atendimentos,
    SUM(Valores) AS faturamento_mensal,
    ROUND(AVG(Valores), 2) AS ticket_medio_mensal,
    COUNT(DISTINCT Cliente) AS clientes_unicos
FROM ControleAtendimento
WHERE Data >= DATEADD(MONTH, -12, GETDATE())
GROUP BY YEAR(Data), MONTH(Data), DATENAME(MONTH, Data)
ORDER BY ano DESC, mes DESC;

-- =====================================================
--  ANÁLISE POR TIPO DE PAGAMENTO
-- =====================================================

SELECT 
    TipoPagamento,
    COUNT(*) AS quantidade_transacoes,
    SUM(Valores) AS total_faturamento,
    ROUND(AVG(Valores), 2) AS ticket_medio,
    ROUND((SUM(Valores) * 100.0 / (SELECT SUM(Valores) FROM ControleAtendimento)), 2) AS percentual_faturamento
FROM ControleAtendimento
GROUP BY TipoPagamento
ORDER BY total_faturamento DESC;

-- =====================================================
--  ATENDIMENTOS ACIMA DO TICKET MÉDIO
-- =====================================================

SELECT 
    c.Data,
    c.Cliente,
    c.Valores,
    c.TipoPagamento,
    s.Descricao AS servico,
    c.Tipo_Atendimento
FROM ControleAtendimento c
INNER JOIN Servico s ON c.Servico = s.IDServico
WHERE c.Valores >= (SELECT AVG(Valores) FROM ControleAtendimento);

