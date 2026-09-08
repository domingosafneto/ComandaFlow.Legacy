USE [selfservice_legacy];
GO

SET NOCOUNT ON;
GO

-------------------------------------------------------------------
-- Cem comandas fisicas numeradas de 1 a 100, inicialmente livres.
-------------------------------------------------------------------
WITH Numeros AS (
    SELECT 1 AS Numero
    UNION ALL
    SELECT Numero + 1 FROM Numeros WHERE Numero < 100
)
INSERT INTO dbo.Comanda (Numero, Disponivel)
    SELECT Numero, 1 FROM Numeros OPTION (MAXRECURSION 100);
GO


------------------------------------------------------------
-- Catalogo minimo para demonstrar valor informado e preco fixo.
------------------------------------------------------------
INSERT INTO dbo.produto (Descricao, Valor_Unitario, Permite_Valor_Informado, Ativo) VALUES
('ALMOÇO PESO', NULL, 1, 1),
('REFRIGERANTE 200ML', 4.00, 0, 1),
('REFRIGERANTE LATA', 7.00, 0, 1),
('SUCO COPO', 6.00, 0, 1),
('ÁGUA MINERAL', 4.00, 0, 1),
('SOBREMESA', 8.00, 0, 1);
GO


PRINT 'Carga inicial concluida: 100 comandas e 6 produtos.';
GO