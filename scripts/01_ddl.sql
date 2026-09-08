USE [selfservice_legacy];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

------------------------------------------------------------
-- Remove o modelo anterior na ordem inversa das dependencias.
------------------------------------------------------------
IF OBJECT_ID(N'dbo.usp_AbrirComanda', N'P') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.usp_AbrirComanda;
    PRINT 'Procedure dbo.usp_AbrirComanda removida.';
END
GO

IF OBJECT_ID(N'dbo.item_comanda', N'U') IS NOT NULL
BEGIN
    DROP TABLE dbo.item_comanda;
    PRINT 'Tabela dbo.item_comanda removida.';
END
GO

IF OBJECT_ID(N'dbo.Movimentacao_Comanda', N'U') IS NOT NULL
BEGIN
    DROP TABLE dbo.Movimentacao_Comanda;
    PRINT 'Tabela dbo.Movimentacao_Comanda removida.';
END
GO

IF OBJECT_ID(N'dbo.Comanda', N'U') IS NOT NULL
BEGIN
    DROP TABLE dbo.Comanda;
    PRINT 'Tabela dbo.Comanda removida.';
END
GO

IF OBJECT_ID(N'dbo.produto', N'U') IS NOT NULL
BEGIN
    DROP TABLE dbo.produto;
    PRINT 'Tabela dbo.produto removida.';
END
GO


------------------------------------------------------------
-- Comanda representa o cartao fisico reutilizavel.
-- Disponivel = 1: pode ser entregue; 0: esta em atendimento.
------------------------------------------------------------
CREATE TABLE dbo.Comanda (
    Id_comanda bigint IDENTITY(1,1) NOT NULL,
    Numero int NOT NULL,
    Disponivel bit NOT NULL,
    CONSTRAINT PK_Comanda PRIMARY KEY CLUSTERED (Id_comanda),
    CONSTRAINT UQ_Comanda_Numero UNIQUE (Numero),
    CONSTRAINT CK_Comanda_Numero CHECK (Numero > 0)
);
GO

ALTER TABLE dbo.Comanda ADD CONSTRAINT DF_Comanda_Disponivel DEFAULT 1 FOR Disponivel;
GO

PRINT 'Tabela dbo.Comanda criada com sucesso.';
GO


------------------------------------------------------------
-- Cada movimentacao eh um atendimento diferente feito com a
-- mesma comanda fisica. Status: A = aberta; F = fechada.
------------------------------------------------------------
CREATE TABLE dbo.Movimentacao_Comanda (
    Id_MovimentacaoComanda bigint IDENTITY(1,1) NOT NULL,
    Id_comanda bigint NOT NULL,
    DataAbertura datetime2(0) NOT NULL,
    DataFechamento datetime2(0) NULL,
    Status char(1) NOT NULL,
    CONSTRAINT PK_Movimentacao_Comanda PRIMARY KEY CLUSTERED (Id_MovimentacaoComanda),
    CONSTRAINT FK_Movimentacao_Comanda_Comanda FOREIGN KEY (Id_comanda) REFERENCES dbo.Comanda (Id_comanda),
    CONSTRAINT CK_Movimentacao_Comanda_Status CHECK (Status IN ('A', 'F')),
    CONSTRAINT CK_Movimentacao_Comanda_Fechamento CHECK ((Status = 'A' AND DataFechamento IS NULL) OR (Status = 'F' AND DataFechamento IS NOT NULL))
);
GO

ALTER TABLE dbo.Movimentacao_Comanda ADD CONSTRAINT DF_Movimentacao_DataAbertura DEFAULT SYSDATETIME() FOR DataAbertura;
GO
ALTER TABLE dbo.Movimentacao_Comanda ADD CONSTRAINT DF_Movimentacao_Status DEFAULT 'A' FOR Status;
GO

-- Uma comanda fisica nao pode ter dois atendimentos abertos.
CREATE UNIQUE INDEX UX_Movimentacao_Comanda_Aberta ON dbo.Movimentacao_Comanda (Id_comanda) WHERE Status = 'A';
GO

PRINT 'Tabela dbo.Movimentacao_Comanda criada com sucesso.';
GO


------------------------------------------------------------
-- Catalogo de produtos.
------------------------------------------------------------
CREATE TABLE dbo.produto (
    Id_produto bigint IDENTITY(1,1) NOT NULL,
    Descricao varchar(100) NOT NULL,
    Valor_Unitario decimal(10,2) NULL,
    Permite_Valor_Informado bit NOT NULL,
    Ativo bit NOT NULL,

    CONSTRAINT PK_produto PRIMARY KEY CLUSTERED (Id_produto),
    CONSTRAINT UQ_produto_Descricao UNIQUE (Descricao),
    CONSTRAINT CK_produto_Valor CHECK ((Permite_Valor_Informado = 1 AND Valor_Unitario IS NULL) OR (Permite_Valor_Informado = 0 AND Valor_Unitario > 0))
);
GO

ALTER TABLE dbo.produto ADD CONSTRAINT DF_produto_Permite DEFAULT 0 FOR Permite_Valor_Informado;
GO
ALTER TABLE dbo.produto ADD CONSTRAINT DF_produto_Ativo DEFAULT 1 FOR Ativo;
GO

PRINT 'Tabela dbo.produto criada com sucesso.';
GO


------------------------------------------------------------
-- Itens pertencem ao atendimento, nao ao cartao fisico.
-- O valor cobrado e copiado para preservar o historico.
------------------------------------------------------------
CREATE TABLE dbo.item_comanda (
    Id_item_comanda bigint IDENTITY(1,1) NOT NULL,
    Id_MovimentacaoComanda bigint NOT NULL,
    Id_produto bigint NOT NULL,
    Quantidade int NOT NULL,
    Valor_Unitario decimal(10,2) NOT NULL,
    Valor_Total AS CONVERT(decimal(12,2), Quantidade * Valor_Unitario) PERSISTED,
    Data_Hora datetime2(0) NOT NULL,

    CONSTRAINT PK_item_comanda PRIMARY KEY CLUSTERED (Id_item_comanda),
    CONSTRAINT FK_item_movimentacao FOREIGN KEY (Id_MovimentacaoComanda) REFERENCES dbo.Movimentacao_Comanda (Id_MovimentacaoComanda),
    CONSTRAINT FK_item_produto FOREIGN KEY (Id_produto) REFERENCES dbo.produto (Id_produto),
    CONSTRAINT CK_item_quantidade CHECK (Quantidade > 0),
    CONSTRAINT CK_item_valor CHECK (Valor_Unitario > 0)
);
GO

ALTER TABLE dbo.item_comanda ADD CONSTRAINT DF_item_quantidade DEFAULT 1 FOR Quantidade;
GO

ALTER TABLE dbo.item_comanda ADD CONSTRAINT DF_item_data DEFAULT SYSDATETIME() FOR Data_Hora;
GO

CREATE INDEX IX_item_movimentacao ON dbo.item_comanda (Id_MovimentacaoComanda);
GO

CREATE INDEX IX_item_produto ON dbo.item_comanda (Id_produto);
GO

PRINT 'Tabela dbo.item_comanda criada com sucesso.';
GO


------------------------------------------------------------
-- Abre uma comanda fisica escolhida pelo funcionario.
-- A verificacao e a reserva ficam na mesma transacao para
-- impedir duas entregas simultaneas do mesmo numero.
------------------------------------------------------------
CREATE PROCEDURE dbo.usp_AbrirComanda
    @Numero int
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @Id_comanda bigint;
        DECLARE @Disponivel bit;

        SELECT
            @Id_comanda = Id_comanda,
            @Disponivel = Disponivel
        FROM dbo.Comanda WITH (UPDLOCK, HOLDLOCK, ROWLOCK)
        WHERE Numero = @Numero;

        IF @Id_comanda IS NULL
            THROW 50001, 'Comanda não cadastrada.', 1;

        IF @Disponivel = 0
            THROW 50002, 'Comanda já está em uso.', 1;

        UPDATE dbo.Comanda
        SET Disponivel = 0
        WHERE Id_comanda = @Id_comanda;

        INSERT INTO dbo.Movimentacao_Comanda (Id_comanda, Status)
        VALUES (@Id_comanda, 'A');

        SELECT
            CAST(SCOPE_IDENTITY() AS bigint) AS Id_MovimentacaoComanda,
            @Numero AS Numero;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH
END;
GO

PRINT 'Procedure dbo.usp_AbrirComanda criada com sucesso.';
GO


------------------------------------------------------------
-- Ao fechar o atendimento, libera automaticamente o numero
-- fisico correspondente. A trigger trata updates em lote.
------------------------------------------------------------
CREATE TRIGGER dbo.TR_Movimentacao_Comanda_Liberar ON dbo.Movimentacao_Comanda AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;

    IF UPDATE(Status)
    BEGIN
        UPDATE c SET c.Disponivel = 1
          FROM dbo.Comanda c
          INNER JOIN inserted i ON i.Id_comanda = c.Id_comanda
          INNER JOIN deleted d ON d.Id_MovimentacaoComanda = i.Id_MovimentacaoComanda
         WHERE i.Status = 'F' AND d.Status <> 'F';
    END
END;
GO

PRINT 'Trigger dbo.TR_Movimentacao_Comanda_Liberar criada com sucesso.';


PRINT 'Estrutura do MVP criada com sucesso.';
GO