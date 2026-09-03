USE [selfservice_legacy];
GO

SET NOCOUNT ON;
GO

------------------------------------------------------------
-- Carga inicial de produtos
------------------------------------------------------------
INSERT INTO dbo.produto (Descricao, Valor_Unitario, Permite_Valor_Informado, Ativo)
    VALUES ('ALMOÇO PESO', NULL, 1, 1);
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

PRINT 'Dados da tabela dbo.produto inseridos com sucesso.';
GO


------------------------------------------------------------
-- Carga inicial de comandas
------------------------------------------------------------
INSERT INTO dbo.comanda (Numero, Data_Abertura, Data_Fechamento, Status)
    VALUES (101, '2026-08-31T11:30:00', NULL, 'A');
GO

INSERT INTO dbo.comanda (Numero, Data_Abertura, Data_Fechamento, Status)
    VALUES (102, '2026-08-31T11:45:00', '2026-08-31T12:35:00', 'F');
GO

INSERT INTO dbo.comanda (Numero, Data_Abertura, Data_Fechamento, Status)
    VALUES (103, '2026-08-31T12:00:00', NULL, 'A');
GO

PRINT 'Dados da tabela dbo.comanda inseridos com sucesso.';
GO


------------------------------------------------------------
-- Carga inicial de itens das comandas
-- O valor cobrado e gravado no item para preservar o historico.
------------------------------------------------------------
INSERT INTO dbo.item_comanda (Id_comanda, Id_produto, Quantidade, Valor_Unitario, Data_Hora)
    VALUES (1, 1, 1, 25.50, '2026-08-31T11:35:00');
GO

INSERT INTO dbo.item_comanda (Id_comanda, Id_produto, Quantidade, Valor_Unitario, Data_Hora)
    VALUES (1, 3, 1, 7.00, '2026-08-31T11:36:00');
GO

INSERT INTO dbo.item_comanda (Id_comanda, Id_produto, Quantidade, Valor_Unitario, Data_Hora)
    VALUES (2, 1, 1, 31.20, '2026-08-31T11:50:00');
GO

INSERT INTO dbo.item_comanda (Id_comanda, Id_produto, Quantidade, Valor_Unitario, Data_Hora)
    VALUES (2, 4, 2, 6.00, '2026-08-31T11:51:00');
GO

INSERT INTO dbo.item_comanda (Id_comanda, Id_produto, Quantidade, Valor_Unitario, Data_Hora)
    VALUES (2, 6, 1, 8.00, '2026-08-31T12:10:00');
GO

INSERT INTO dbo.item_comanda (Id_comanda, Id_produto, Quantidade, Valor_Unitario, Data_Hora)
    VALUES (3, 1, 1, 28.75, '2026-08-31T12:05:00');
GO

INSERT INTO dbo.item_comanda (Id_comanda, Id_produto, Quantidade, Valor_Unitario, Data_Hora)
    VALUES (3, 5, 1, 4.00, '2026-08-31T12:06:00');
GO

PRINT 'Dados da tabela dbo.item_comanda inseridos com sucesso.';
GO
