USE [selfservice_legacy];
GO

SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

------------------------------------------------------------
-- Tabela comanda
-- Status: A = Aberta | F = Fechada
------------------------------------------------------------
IF OBJECT_ID(N'dbo.FK_item_comanda_comanda', N'F') IS NOT NULL
BEGIN
    ALTER TABLE dbo.item_comanda
        DROP CONSTRAINT FK_item_comanda_comanda;
END
GO

IF OBJECT_ID(N'dbo.comanda', N'U') IS NOT NULL
BEGIN
    DROP TABLE dbo.comanda;
    PRINT 'Tabela dbo.comanda removida.';
END
GO

CREATE TABLE dbo.comanda (
    Id_comanda          bigint          IDENTITY(1,1) NOT NULL,
    Numero              int             NOT NULL,
    Data_Abertura       datetime2(0)    NOT NULL,
    Data_Fechamento     datetime2(0)    NULL,
    Status              char(1)         NOT NULL,
    
    CONSTRAINT PK_comanda
        PRIMARY KEY CLUSTERED (Id_comanda),

    CONSTRAINT CK_comanda_Fechamento CHECK (
        (Status = 'A' AND Data_Fechamento IS NULL)
        OR
        (Status = 'F' AND Data_Fechamento IS NOT NULL)
    ),

    CONSTRAINT CK_comanda_Status
        CHECK (Status IN ('A', 'F'))
);
GO

ALTER TABLE dbo.comanda
    ADD CONSTRAINT DF_comanda_Data_Abertura
        DEFAULT SYSDATETIME() FOR Data_Abertura;
GO

ALTER TABLE dbo.comanda
    ADD CONSTRAINT DF_comanda_Status
        DEFAULT 'A' FOR Status;
GO

CREATE UNIQUE INDEX UX_comanda_Numero_Aberta
    ON dbo.comanda (Numero)
    WHERE Status = 'A';
GO

PRINT 'Tabela dbo.comanda criada com sucesso.';
GO

------------------------------------------------------------
-- Tabela produto
------------------------------------------------------------
IF OBJECT_ID(N'dbo.FK_item_comanda_produto', N'F') IS NOT NULL
BEGIN
    ALTER TABLE dbo.item_comanda
        DROP CONSTRAINT FK_item_comanda_produto;
END
GO

IF OBJECT_ID(N'dbo.produto', N'U') IS NOT NULL
BEGIN
    DROP TABLE dbo.produto;
    PRINT 'Tabela dbo.produto removida.';
END
GO

CREATE TABLE dbo.produto (
    Id_produto                  bigint          IDENTITY(1,1) NOT NULL,
    Descricao                   varchar(100)    NOT NULL,
    Valor_Unitario              decimal(10,2)   NULL,
    Permite_Valor_Informado     bit             NOT NULL,
    Ativo                       bit             NOT NULL,
    
    CONSTRAINT PK_produto
        PRIMARY KEY CLUSTERED (Id_produto),

    CONSTRAINT UQ_produto_Descricao
        UNIQUE (Descricao),

    CONSTRAINT CK_produto_Valor_Unitario CHECK (
        (Permite_Valor_Informado = 1 AND Valor_Unitario IS NULL)
        OR
        (Permite_Valor_Informado = 0 AND Valor_Unitario > 0)
    )
);
GO

ALTER TABLE dbo.produto
    ADD CONSTRAINT DF_produto_Permite_Valor_Informado
        DEFAULT 0 FOR Permite_Valor_Informado;
GO

ALTER TABLE dbo.produto
    ADD CONSTRAINT DF_produto_Ativo
        DEFAULT 1 FOR Ativo;
GO

PRINT 'Tabela dbo.produto criada com sucesso.';
GO

------------------------------------------------------------
-- Tabela item_comanda
------------------------------------------------------------
IF OBJECT_ID(N'dbo.item_comanda', N'U') IS NOT NULL
BEGIN
    DROP TABLE dbo.item_comanda;
    PRINT 'Tabela dbo.item_comanda removida.';
END
GO

CREATE TABLE dbo.item_comanda (
    Id_item_comanda     bigint          IDENTITY(1,1) NOT NULL,
    Id_comanda          bigint          NOT NULL,
    Id_produto          bigint          NOT NULL,
    Quantidade          int             NOT NULL,
    Valor_Unitario      decimal(10,2)   NOT NULL,
    Valor_Total         AS (
        CONVERT(decimal(12,2), Quantidade * Valor_Unitario)
    ) PERSISTED,
    Data_Hora           datetime2(0)    NOT NULL,
    
    CONSTRAINT PK_item_comanda
        PRIMARY KEY CLUSTERED (Id_item_comanda),

    CONSTRAINT FK_item_comanda_comanda
        FOREIGN KEY (Id_comanda)
        REFERENCES dbo.comanda (Id_comanda),

    CONSTRAINT FK_item_comanda_produto
        FOREIGN KEY (Id_produto)
        REFERENCES dbo.produto (Id_produto),

    CONSTRAINT CK_item_comanda_Quantidade
        CHECK (Quantidade > 0),

    CONSTRAINT CK_item_comanda_Valor_Unitario
        CHECK (Valor_Unitario > 0)
);
GO

ALTER TABLE dbo.item_comanda
    ADD CONSTRAINT DF_item_comanda_Quantidade
        DEFAULT 1 FOR Quantidade;
GO

ALTER TABLE dbo.item_comanda
    ADD CONSTRAINT DF_item_comanda_Data_Hora
        DEFAULT SYSDATETIME() FOR Data_Hora;
GO

CREATE INDEX IX_item_comanda_Id_comanda
    ON dbo.item_comanda (Id_comanda);
GO

CREATE INDEX IX_item_comanda_Id_produto
    ON dbo.item_comanda (Id_produto);
GO

PRINT 'Tabela dbo.item_comanda criada com sucesso.';
GO