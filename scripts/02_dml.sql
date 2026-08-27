USE [selfservice_legacy];
GO

SET NOCOUNT ON;
GO

------------------------------------------------------------
-- Carga inicial de produtos
------------------------------------------------------------
INSERT INTO dbo.produto
    (Descricao, Valor_Unitario, Permite_Valor_Informado, Ativo)
VALUES
    ('ALMOÇO PESO', NULL, 1, 1);
GO

INSERT INTO dbo.produto (Descricao, Valor_Unitario, Permite_Valor_Informado, Ativo)
    VALUES ('REFRIGERANTE 200ML', 4.00, 0, 1);
GO

INSERT INTO dbo.produto (Descricao, Valor_Unitario, Permite_Valor_Informado, Ativo)
    VALUES ('REFRIGERANTE LATA', 7.00, 0, 1);
GO

INSERT INTO dbo.produto (Descricao, Valor_Unitario, Permite_Valor_Informado, Ativo)
    VALUES ('SUCO COPO', 6.00, 0, 1);
GO

INSERT INTO dbo.produto (Descricao, Valor_Unitario, Permite_Valor_Informado, Ativo)
    VALUES ('ÁGUA MINERAL', 4.00, 0, 1);
GO

INSERT INTO dbo.produto (Descricao, Valor_Unitario, Permite_Valor_Informado, Ativo)
    VALUES ('SOBREMESA', 8.00, 0, 1);
GO

SELECT
    Id_produto,
    Descricao,
    Valor_Unitario,
    Permite_Valor_Informado,
    Ativo
FROM dbo.produto
ORDER BY Descricao;
GO
