USE [selfservice_legacy];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO


------------------------------------------------------------
-- Cadastra ou atualiza produtos e valida o tipo de preco.
-- Produtos com valor informado nao possuem preco fixo no catalogo.
------------------------------------------------------------
IF OBJECT_ID(N'dbo.pr_SalvarProduto', N'P') IS NULL
    EXEC(N'CREATE PROCEDURE dbo.pr_SalvarProduto AS BEGIN SET NOCOUNT ON; END');
GO
ALTER PROCEDURE dbo.pr_SalvarProduto
    @Id bigint, @Descricao varchar(100), @Valor decimal(10,2), @Permite bit, @Ativo bit
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @Descricao IS NULL OR LEN(LTRIM(RTRIM(@Descricao))) = 0
        THROW 50006, 'Informe a descrição.', 1;

    IF @Permite IS NULL OR @Ativo IS NULL
        THROW 50007, 'Informe o tipo de preço e a situação do produto.', 1;

    IF @Permite = 0 AND (@Valor IS NULL OR @Valor <= 0)
        THROW 50008, 'Informe um preço maior que zero.', 1;

    SET @Descricao = LTRIM(RTRIM(@Descricao));

    IF @Permite = 1 SET @Valor = NULL;

    IF @Id = 0
    BEGIN
        INSERT INTO dbo.produto
            (Descricao,
             Valor_Unitario,
             Permite_Valor_Informado,
             Ativo)
        VALUES
            (@Descricao,
             @Valor,
             @Permite,
             @Ativo);

        SELECT
            CAST(SCOPE_IDENTITY() AS bigint);
    END
    ELSE
    BEGIN
        UPDATE dbo.produto
        SET
            Descricao = @Descricao,
            Valor_Unitario = @Valor,
            Permite_Valor_Informado = @Permite,
            Ativo = @Ativo
        WHERE
            Id_produto = @Id;

        SELECT
            @Id;
    END;
END;
GO

PRINT 'Procedure dbo.pr_SalvarProduto criada ou atualizada com sucesso.';
GO


------------------------------------------------------------
-- Abre uma comanda cadastrada e disponivel.
-- Reserva o numero e cria o atendimento na mesma transacao.
------------------------------------------------------------
-- Migra o nome anterior preservando permissoes do objeto.
IF OBJECT_ID(N'dbo.usp_AbrirComanda', N'P') IS NOT NULL
   AND OBJECT_ID(N'dbo.pr_AbrirComanda', N'P') IS NULL
BEGIN
    EXEC sys.sp_rename N'dbo.usp_AbrirComanda', N'pr_AbrirComanda', N'OBJECT';
    PRINT 'Procedure dbo.usp_AbrirComanda renomeada para dbo.pr_AbrirComanda.';
END
GO

IF OBJECT_ID(N'dbo.pr_AbrirComanda', N'P') IS NULL
    EXEC(N'CREATE PROCEDURE dbo.pr_AbrirComanda AS BEGIN SET NOCOUNT ON; END');
GO
ALTER PROCEDURE dbo.pr_AbrirComanda
    @Numero int
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @Numero IS NULL OR @Numero <= 0
        THROW 50010, 'Informe um número de comanda válido.', 1;

    BEGIN TRY
        BEGIN TRANSACTION;

            DECLARE @Id_comanda bigint;
            DECLARE @Disponivel bit;

            SELECT
                @Id_comanda = Id_comanda,
                @Disponivel = Disponivel
            FROM
                dbo.Comanda WITH (UPDLOCK, HOLDLOCK, ROWLOCK)
            WHERE
                Numero = @Numero;

            IF @Id_comanda IS NULL
                THROW 50001, 'Comanda não cadastrada.', 1;

            IF @Disponivel = 0
                THROW 50002, 'Comanda já está em uso.', 1;

            UPDATE dbo.Comanda SET Disponivel = 0
            WHERE
                Id_comanda = @Id_comanda;

            INSERT INTO dbo.Movimentacao_Comanda
                (Id_comanda,
                 Status)
            VALUES
                (@Id_comanda,
                 'A');

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

PRINT 'Procedure dbo.pr_AbrirComanda criada ou atualizada com sucesso.';
GO


------------------------------------------------------------
-- Registra consumo em um atendimento aberto.
-- Valida produto, quantidade e preco e preserva o valor cobrado.
------------------------------------------------------------
IF OBJECT_ID(N'dbo.pr_AdicionarItem', N'P') IS NULL
    EXEC(N'CREATE PROCEDURE dbo.pr_AdicionarItem AS BEGIN SET NOCOUNT ON; END');
GO
ALTER PROCEDURE dbo.pr_AdicionarItem
    @Numero int, @Produto bigint, @Quantidade int, @Informado decimal(10,2) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;
            DECLARE @ComandaBloqueada bigint;

            SELECT
                @ComandaBloqueada = Id_comanda
            FROM
                dbo.Comanda WITH (UPDLOCK, HOLDLOCK)
            WHERE
                Numero = @Numero;

            IF @Quantidade IS NULL OR @Quantidade <= 0
                THROW 50009, 'A quantidade deve ser maior que zero.', 1;

            DECLARE @Movimentacao bigint =
            (
                SELECT
                    m.Id_MovimentacaoComanda
                FROM
                    dbo.Movimentacao_Comanda m
                    INNER JOIN dbo.Comanda c ON c.Id_comanda = m.Id_comanda
                WHERE
                    c.Numero = @Numero
                AND m.Status = 'A'
                );

            IF @Movimentacao IS NULL
                THROW 50002, 'Comanda não está aberta.', 1;

            DECLARE @Permite bit;
            DECLARE @Valor decimal(10,2);

            SELECT
                @Permite = Permite_Valor_Informado,
                @Valor = Valor_Unitario
            FROM
                dbo.produto
            WHERE
                Id_produto = @Produto
            AND Ativo = 1;

            IF @Permite IS NULL
                THROW 50003, 'Produto inválido ou inativo.', 1;

            IF @Permite = 1
                SET @Valor = @Informado;

            IF @Valor IS NULL OR @Valor <= 0
                THROW 50004, 'Informe um valor maior que zero.', 1;

            INSERT INTO dbo.item_comanda
                (Id_MovimentacaoComanda,
                 Id_produto,
                 Quantidade,
                 Valor_Unitario)
            VALUES
                (@Movimentacao,
                 @Produto,
                 @Quantidade,
                 @Valor);

            SELECT
                CAST(SCOPE_IDENTITY() AS bigint);
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

PRINT 'Procedure dbo.pr_AdicionarItem criada ou atualizada com sucesso.';
GO


------------------------------------------------------------
-- Fecha o atendimento aberto e registra a data de fechamento.
-- A trigger libera a comanda fisica na mesma transacao.
------------------------------------------------------------
IF OBJECT_ID(N'dbo.pr_Fechar', N'P') IS NULL
    EXEC(N'CREATE PROCEDURE dbo.pr_Fechar AS BEGIN SET NOCOUNT ON; END');
GO
ALTER PROCEDURE dbo.pr_Fechar
    @Numero int
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;
            DECLARE @ComandaBloqueada bigint;

            SELECT
                @ComandaBloqueada = Id_comanda
            FROM
                dbo.Comanda WITH (UPDLOCK, HOLDLOCK)
            WHERE
                Numero = @Numero;

            UPDATE m
            SET
                Status = 'F',
                DataFechamento = SYSDATETIME()
            FROM
                dbo.Movimentacao_Comanda m
                INNER JOIN dbo.Comanda c ON c.Id_comanda = m.Id_comanda
            WHERE
                c.Numero = @Numero
            AND m.Status = 'A';

            DECLARE @Afetadas int = @@ROWCOUNT;

            IF @Afetadas = 0
                THROW 50002, 'Comanda não está aberta.', 1;

            SELECT
                @Afetadas;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

PRINT 'Procedure dbo.pr_Fechar criada ou atualizada com sucesso.';
GO


------------------------------------------------------------
-- Altera a disponibilidade da comanda fisica.
-- Impede liberar uma comanda enquanto houver atendimento aberto.
------------------------------------------------------------
IF OBJECT_ID(N'dbo.pr_AlterarDisponibilidade', N'P') IS NULL
    EXEC(N'CREATE PROCEDURE dbo.pr_AlterarDisponibilidade AS BEGIN SET NOCOUNT ON; END');
GO
ALTER PROCEDURE dbo.pr_AlterarDisponibilidade
    @Numero int, @Disponivel bit
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

            DECLARE @ComandaBloqueada bigint;

            SELECT
                @ComandaBloqueada = Id_comanda
            FROM
                dbo.Comanda WITH (UPDLOCK, HOLDLOCK)
            WHERE
                Numero = @Numero;

            IF @Disponivel = 1
               AND EXISTS
               (
                   SELECT
                       1
                   FROM
                       dbo.Movimentacao_Comanda m
                       INNER JOIN dbo.Comanda c ON c.Id_comanda = m.Id_comanda
                   WHERE
                       c.Numero = @Numero
                   AND m.Status = 'A'
                   )
            THROW 50005, 'Feche o atendimento antes de liberar a comanda.', 1;

            UPDATE dbo.Comanda
            SET
                Disponivel = @Disponivel
            WHERE
                Numero = @Numero;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

PRINT 'Procedure dbo.pr_AlterarDisponibilidade criada ou atualizada com sucesso.';
GO


------------------------------------------------------------
-- Remove as procedures antigas de exclusao de produto.
-- A exclusao simples permanece no Web Forms, em Dados.cs.
------------------------------------------------------------
IF OBJECT_ID(N'dbo.pr_ExcluirProduto', N'P') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.pr_ExcluirProduto;
    PRINT 'Procedure dbo.pr_ExcluirProduto removida com sucesso.';
END
GO

IF OBJECT_ID(N'dbo.usp_ExcluirProduto', N'P') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.usp_ExcluirProduto;
    PRINT 'Procedure dbo.usp_ExcluirProduto removida com sucesso.';
END
GO


-- Consultas compartilhadas: catalogo, disponibilidade, atendimento e historico.
------------------------------------------------------------
-- Lista o historico dos atendimentos com seus totais.
-- Ordena os resultados pela data de abertura mais recente.
------------------------------------------------------------
IF OBJECT_ID(N'dbo.pr_Historico', N'P') IS NULL
    EXEC(N'CREATE PROCEDURE dbo.pr_Historico AS BEGIN SET NOCOUNT ON; END');
GO
ALTER PROCEDURE dbo.pr_Historico

AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        m.Id_MovimentacaoComanda,
        c.Numero,
        m.Status,
        m.DataAbertura,
        m.DataFechamento,
        COALESCE(SUM(i.Valor_Total), 0) AS Total
    FROM
        dbo.Movimentacao_Comanda m
        INNER JOIN dbo.Comanda c ON c.Id_comanda = m.Id_comanda
        LEFT JOIN dbo.item_comanda i ON i.Id_MovimentacaoComanda = m.Id_MovimentacaoComanda
    GROUP BY
        m.Id_MovimentacaoComanda,
        c.Numero,
        m.Status,
        m.DataAbertura,
        m.DataFechamento
    ORDER BY
        m.DataAbertura DESC;
END;
GO

PRINT 'Procedure dbo.pr_Historico criada ou atualizada com sucesso.';
GO


------------------------------------------------------------
-- Lista os itens de uma movimentacao e os precos registrados.
-- Ordena os consumos pela data e pelo identificador do item.
------------------------------------------------------------
IF OBJECT_ID(N'dbo.pr_ListarItens', N'P') IS NULL
    EXEC(N'CREATE PROCEDURE dbo.pr_ListarItens AS BEGIN SET NOCOUNT ON; END');
GO
ALTER PROCEDURE dbo.pr_ListarItens
    @Id bigint
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        p.Descricao,
        i.Quantidade,
        i.Valor_Unitario,
        i.Valor_Total
    FROM
        dbo.item_comanda i
        INNER JOIN dbo.produto p ON p.Id_produto = i.Id_produto
    WHERE
        i.Id_MovimentacaoComanda = @Id
    ORDER BY
        i.Data_Hora, i.Id_item_comanda;
END;
GO

PRINT 'Procedure dbo.pr_ListarItens criada ou atualizada com sucesso.';
GO


------------------------------------------------------------
-- Consulta o atendimento aberto pelo numero da comanda.
-- Retorna os dados do atendimento e a soma dos consumos.
------------------------------------------------------------
IF OBJECT_ID(N'dbo.pr_ObterComandaAberta', N'P') IS NULL
    EXEC(N'CREATE PROCEDURE dbo.pr_ObterComandaAberta AS BEGIN SET NOCOUNT ON; END');
GO
ALTER PROCEDURE dbo.pr_ObterComandaAberta
    @Numero int
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        m.Id_MovimentacaoComanda,
        c.Numero,
        m.Status,
        m.DataAbertura,
        m.DataFechamento,
        COALESCE(SUM(i.Valor_Total), 0) AS Total
    FROM
        dbo.Comanda c
        INNER JOIN dbo.Movimentacao_Comanda m ON m.Id_comanda = c.Id_comanda
        LEFT JOIN dbo.item_comanda i ON i.Id_MovimentacaoComanda = m.Id_MovimentacaoComanda
    WHERE
        c.Numero = @Numero
    AND m.Status = 'A'
    GROUP BY
        m.Id_MovimentacaoComanda,
        c.Numero,
        m.Status,
        m.DataAbertura,
        m.DataFechamento;
END;
GO

PRINT 'Procedure dbo.pr_ObterComandaAberta criada ou atualizada com sucesso.';
GO


------------------------------------------------------------
-- Lista comandas conforme a disponibilidade.
-- Filtros: T = todas; D = disponiveis; U = em uso.
------------------------------------------------------------
IF OBJECT_ID(N'dbo.pr_ListarComandas', N'P') IS NULL
    EXEC(N'CREATE PROCEDURE dbo.pr_ListarComandas AS BEGIN SET NOCOUNT ON; END');
GO
ALTER PROCEDURE dbo.pr_ListarComandas
    @Filtro char(1) = 'T'
AS
BEGIN
    SET NOCOUNT ON;

    IF @Filtro IS NULL OR @Filtro = '' SET @Filtro = 'T';

    SELECT
        Id_comanda,
        Numero,
        Disponivel
    FROM
        dbo.Comanda
    WHERE
        (@Filtro = 'T')
     OR (@Filtro = 'D' AND Disponivel = 1)
     OR (@Filtro = 'U' AND Disponivel = 0)
    ORDER BY
        Numero;
END;
GO

PRINT 'Procedure dbo.pr_ListarComandas criada ou atualizada com sucesso.';
GO


------------------------------------------------------------
-- Lista o catalogo de produtos em ordem de descricao.
-- Ativos = 1 retorna somente produtos ativos; 0 retorna todos.
------------------------------------------------------------
IF OBJECT_ID(N'dbo.pr_ListarProdutos', N'P') IS NULL
    EXEC(N'CREATE PROCEDURE dbo.pr_ListarProdutos AS BEGIN SET NOCOUNT ON; END');
GO
ALTER PROCEDURE dbo.pr_ListarProdutos
    @Ativos bit = 0
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        Id_produto,
        Descricao,
        Valor_Unitario,
        Permite_Valor_Informado,
        Ativo
    FROM
        dbo.produto
    WHERE
        @Ativos = 0
     OR Ativo = 1
    ORDER BY
        Descricao;
END;
GO

PRINT 'Procedure dbo.pr_ListarProdutos criada ou atualizada com sucesso.';
GO