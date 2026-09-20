param(
    [switch]$Aplicar
)

$ErrorActionPreference = 'Stop'
$config = [xml](Get-Content "$PSScriptRoot/../ComandaFlow.Legacy/ConnectionStrings.config")
$cn = [System.Data.SqlClient.SqlConnection]::new($config.connectionStrings.add.connectionString)

try
{
    $cn.Open()
    $tx = $cn.BeginTransaction()

    try
    {
        $sql = [IO.File]::ReadAllText("$PSScriptRoot/03_procedures.sql")

        foreach ($batch in [regex]::Split($sql, '(?m)^GO\s*\r?$'))
        {
            if ([string]::IsNullOrWhiteSpace($batch))
            {
                continue
            }

            $cmd = $cn.CreateCommand()
            $cmd.Transaction = $tx
            $cmd.CommandText = $batch
            [void]$cmd.ExecuteNonQuery()
            $cmd.Dispose()
        }

        $cmd = $cn.CreateCommand()
        $cmd.Transaction = $tx
        $cmd.CommandText = @"
SAVE TRANSACTION TesteProcedures;
DECLARE @Numero int = 2147483647;
WHILE EXISTS (
    SELECT
        1
    FROM
        dbo.Comanda
    WHERE
        Numero = @Numero
)
    SET @Numero -= 1;
INSERT dbo.Comanda
    (Numero,
     Disponivel)
VALUES
    (@Numero,
     1);
DECLARE @Produto TABLE (Id bigint);
DECLARE @Descricao varchar(100) = CONVERT(varchar(36), NEWID());
INSERT @Produto
    EXEC dbo.pr_SalvarProduto 0, @Descricao, 12.50, 0, 1;
DECLARE @Id bigint = (
    SELECT
        Id
    FROM
        @Produto
);
EXEC dbo.pr_AbrirComanda @Numero;
EXEC dbo.pr_AdicionarItem @Numero, @Id, 2, NULL;
IF NOT EXISTS (
    SELECT
        1
    FROM
        dbo.item_comanda
    WHERE
        Id_produto = @Id
    AND Valor_Total = 25
)
    THROW 51000, 'Falha no total do consumo.', 1;
DECLARE @Mov bigint = (
    SELECT
        m.Id_MovimentacaoComanda
    FROM
        dbo.Movimentacao_Comanda m
        JOIN dbo.Comanda c ON c.Id_comanda = m.Id_comanda
    WHERE
        c.Numero = @Numero
);
EXEC dbo.pr_ListarProdutos @Ativos = 1;
EXEC dbo.pr_ListarComandas @Filtro = 'U';
EXEC dbo.pr_ObterComandaAberta @Numero;
EXEC dbo.pr_ListarItens @Mov;
EXEC dbo.pr_Historico;
EXEC dbo.pr_Fechar @Numero;
IF NOT EXISTS (
    SELECT
        1
    FROM
        dbo.Comanda
    WHERE
        Numero = @Numero
    AND Disponivel = 1
)
    THROW 51000, 'Falha na liberacao.', 1;
EXEC dbo.pr_AlterarDisponibilidade @Numero, 0;
EXEC dbo.pr_AlterarDisponibilidade @Numero, 1;
DECLARE @Outro TABLE (Id bigint);
SET @Descricao = CONVERT(varchar(36), NEWID());
INSERT @Outro
    EXEC dbo.pr_SalvarProduto 0, @Descricao, NULL, 1, 1;
DECLARE @Excluir bigint = (
    SELECT
        Id
    FROM
        @Outro
);
DELETE FROM dbo.produto
WHERE
    Id_produto = @Excluir;
ROLLBACK TRANSACTION TesteProcedures;
"@
        [void]$cmd.ExecuteNonQuery()
        $cmd.Dispose()

        # Valida o SQL parametrizado realmente utilizado pelo Web Forms.
        $dados = [IO.File]::ReadAllText("$PSScriptRoot/../ComandaFlow.Legacy/Dados.cs")
        $consultas = [regex]::Matches($dados, 'const string sql = @"([\s\S]*?)";')

        if ($consultas.Count -ne 1)
        {
            throw 'Esperada somente a exclusao simples no Dados.cs.'
        }

        foreach ($consulta in $consultas)
        {
            $cmd = $cn.CreateCommand()
            $cmd.Transaction = $tx
            $cmd.CommandText = $consulta.Groups[1].Value
            [void]$cmd.Parameters.AddWithValue('@Ativos', $false)
            [void]$cmd.Parameters.AddWithValue('@Filtro', 'T')
            [void]$cmd.Parameters.AddWithValue('@Numero', -1)
            [void]$cmd.Parameters.AddWithValue('@Id', [long]-1)
            [void]$cmd.ExecuteNonQuery()
            $cmd.Dispose()
        }

        if ($Aplicar)
        {
            $tx.Commit()
            'Procedures aplicadas; teste funcional revertido.'
        }
        else
        {
            $tx.Rollback()
            'Procedures compiladas e fluxo funcional validado; transacao revertida.'
        }
    }
    catch
    {
        if ($tx.Connection)
        {
            $tx.Rollback()
        }

        throw
    }
}
finally
{
    $cn.Dispose()
}