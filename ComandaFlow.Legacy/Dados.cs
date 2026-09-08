using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;

namespace ComandaFlow.Legacy
{
    internal static class Dados
    {
        private static string Conexao
        {
            get
            {
                return ConfigurationManager
                    .ConnectionStrings["ComandaFlowDb"]
                    .ConnectionString;
            }
        }

        public static List<ProdutoDto> ListarProdutos(
            bool somenteAtivos = false)
        {
            var lista = new List<ProdutoDto>();

            const string sql = @"
                SELECT
                    Id_produto,
                    Descricao,
                    Valor_Unitario,
                    Permite_Valor_Informado,
                    Ativo
                FROM dbo.produto
                WHERE @Ativos = 0
                   OR Ativo = 1
                ORDER BY Descricao;";

            using (var cn = new SqlConnection(Conexao))
            using (var cmd = new SqlCommand(sql, cn))
            {
                cmd.Parameters
                    .Add("@Ativos", SqlDbType.Bit)
                    .Value = somenteAtivos;

                cn.Open();

                using (var reader = cmd.ExecuteReader())
                {
                    while (reader.Read())
                    {
                        lista.Add(new ProdutoDto
                        {
                            IdProduto = reader.GetInt64(0),
                            Descricao = reader.GetString(1),
                            ValorUnitario = reader.IsDBNull(2)
                                ? (decimal?)null
                                : reader.GetDecimal(2),
                            PermiteValorInformado = reader.GetBoolean(3),
                            Ativo = reader.GetBoolean(4)
                        });
                    }
                }
            }

            return lista;
        }

        public static ResultadoDto SalvarProduto(
            long id,
            string descricao,
            decimal? valor,
            bool permite,
            bool ativo)
        {
            if (string.IsNullOrWhiteSpace(descricao))
            {
                throw new ArgumentException("Informe a descrição.");
            }

            if (!permite && (!valor.HasValue || valor <= 0))
            {
                throw new ArgumentException("Informe um preço maior que zero.");
            }

            const string sql = @"
                IF @Id = 0
                BEGIN
                    INSERT INTO dbo.produto
                        (Descricao, Valor_Unitario,
                         Permite_Valor_Informado, Ativo)
                    VALUES
                        (@Descricao, @Valor, @Permite, @Ativo);

                    SELECT CAST(SCOPE_IDENTITY() AS bigint);
                END
                ELSE
                BEGIN
                    UPDATE dbo.produto
                    SET Descricao = @Descricao,
                        Valor_Unitario = @Valor,
                        Permite_Valor_Informado = @Permite,
                        Ativo = @Ativo
                    WHERE Id_produto = @Id;

                    SELECT @Id;
                END;";

            using (var cn = new SqlConnection(Conexao))
            using (var cmd = new SqlCommand(sql, cn))
            {
                cmd.Parameters.Add("@Id", SqlDbType.BigInt).Value = id;
                cmd.Parameters
                    .Add("@Descricao", SqlDbType.VarChar, 100)
                    .Value = descricao.Trim();

                SqlParameter parametroValor = cmd.Parameters.Add(
                    "@Valor",
                    SqlDbType.Decimal);
                parametroValor.Precision = 10;
                parametroValor.Scale = 2;
                parametroValor.Value = permite
                    ? (object)DBNull.Value
                    : valor.Value;

                cmd.Parameters
                    .Add("@Permite", SqlDbType.Bit)
                    .Value = permite;
                cmd.Parameters
                    .Add("@Ativo", SqlDbType.Bit)
                    .Value = ativo;

                cn.Open();

                return new ResultadoDto
                {
                    Sucesso = true,
                    Id = Convert.ToInt64(cmd.ExecuteScalar()),
                    Mensagem = "Produto salvo com sucesso."
                };
            }
        }

        public static void ExcluirProduto(long id)
        {
            const string sql = @"
                DELETE FROM dbo.produto
                WHERE Id_produto = @Id;";

            using (var cn = new SqlConnection(Conexao))
            using (var cmd = new SqlCommand(sql, cn))
            {
                cmd.Parameters.Add("@Id", SqlDbType.BigInt).Value = id;
                cn.Open();
                cmd.ExecuteNonQuery();
            }
        }

        public static List<ComandaDto> ListarComandas(string filtro)
        {
            var lista = new List<ComandaDto>();

            const string sql = @"
                SELECT Id_comanda, Numero, Disponivel
                FROM dbo.Comanda
                WHERE @Filtro = 'T'
                   OR (@Filtro = 'D' AND Disponivel = 1)
                   OR (@Filtro = 'U' AND Disponivel = 0)
                ORDER BY Numero;";

            using (var cn = new SqlConnection(Conexao))
            using (var cmd = new SqlCommand(sql, cn))
            {
                cmd.Parameters
                    .Add("@Filtro", SqlDbType.Char, 1)
                    .Value = string.IsNullOrEmpty(filtro) ? "T" : filtro;

                cn.Open();

                using (var reader = cmd.ExecuteReader())
                {
                    while (reader.Read())
                    {
                        lista.Add(new ComandaDto
                        {
                            IdComanda = reader.GetInt64(0),
                            Numero = reader.GetInt32(1),
                            Disponivel = reader.GetBoolean(2)
                        });
                    }
                }
            }

            return lista;
        }

        public static ResultadoDto AbrirComanda(int numero)
        {
            if (numero <= 0)
            {
                throw new ArgumentException(
                    "Informe um número de comanda válido.");
            }

            using (var cn = new SqlConnection(Conexao))
            using (var cmd = new SqlCommand("dbo.usp_AbrirComanda", cn))
            {
                cmd.CommandType = CommandType.StoredProcedure;
                cmd.Parameters
                    .Add("@Numero", SqlDbType.Int)
                    .Value = numero;

                cn.Open();

                using (var reader = cmd.ExecuteReader())
                {
                    reader.Read();

                    return new ResultadoDto
                    {
                        Sucesso = true,
                        Id = reader.GetInt64(0),
                        Numero = reader.GetInt32(1),
                        Mensagem = "Comanda aberta com sucesso."
                    };
                }
            }
        }

        public static AtendimentoDto ObterAberta(int numero)
        {
            const string sql = @"
                SELECT
                    m.Id_MovimentacaoComanda,
                    c.Numero,
                    m.Status,
                    m.DataAbertura,
                    m.DataFechamento,
                    COALESCE(SUM(i.Valor_Total), 0) AS Total
                FROM dbo.Comanda c
                INNER JOIN dbo.Movimentacao_Comanda m
                    ON m.Id_comanda = c.Id_comanda
                LEFT JOIN dbo.item_comanda i
                    ON i.Id_MovimentacaoComanda =
                       m.Id_MovimentacaoComanda
                WHERE c.Numero = @Numero
                  AND m.Status = 'A'
                GROUP BY
                    m.Id_MovimentacaoComanda,
                    c.Numero,
                    m.Status,
                    m.DataAbertura,
                    m.DataFechamento;";

            AtendimentoDto atendimento = null;

            using (var cn = new SqlConnection(Conexao))
            using (var cmd = new SqlCommand(sql, cn))
            {
                cmd.Parameters
                    .Add("@Numero", SqlDbType.Int)
                    .Value = numero;

                cn.Open();

                using (var reader = cmd.ExecuteReader())
                {
                    if (reader.Read())
                    {
                        atendimento = new AtendimentoDto
                        {
                            IdMovimentacao = reader.GetInt64(0),
                            Numero = reader.GetInt32(1),
                            Status = reader.GetString(2),
                            DataAbertura = reader.GetDateTime(3),
                            DataFechamento = reader.IsDBNull(4)
                                ? (DateTime?)null
                                : reader.GetDateTime(4),
                            Total = reader.GetDecimal(5),
                            Itens = new List<ItemDto>()
                        };
                    }
                }
            }

            if (atendimento != null)
            {
                atendimento.Itens = ListarItens(
                    atendimento.IdMovimentacao);
            }

            return atendimento;
        }

        private static List<ItemDto> ListarItens(long id)
        {
            var lista = new List<ItemDto>();

            const string sql = @"
                SELECT
                    p.Descricao,
                    i.Quantidade,
                    i.Valor_Unitario,
                    i.Valor_Total
                FROM dbo.item_comanda i
                INNER JOIN dbo.produto p
                    ON p.Id_produto = i.Id_produto
                WHERE i.Id_MovimentacaoComanda = @Id
                ORDER BY i.Data_Hora, i.Id_item_comanda;";

            using (var cn = new SqlConnection(Conexao))
            using (var cmd = new SqlCommand(sql, cn))
            {
                cmd.Parameters.Add("@Id", SqlDbType.BigInt).Value = id;
                cn.Open();

                using (var reader = cmd.ExecuteReader())
                {
                    while (reader.Read())
                    {
                        lista.Add(new ItemDto
                        {
                            Produto = reader.GetString(0),
                            Quantidade = reader.GetInt32(1),
                            ValorUnitario = reader.GetDecimal(2),
                            ValorTotal = reader.GetDecimal(3)
                        });
                    }
                }
            }

            return lista;
        }

        public static ResultadoDto AdicionarItem(
            int numero,
            long produtoId,
            int quantidade,
            decimal? valorInformado)
        {
            if (quantidade <= 0)
            {
                throw new ArgumentException(
                    "A quantidade deve ser maior que zero.");
            }

            const string sql = @"
                DECLARE @Movimentacao bigint =
                (
                    SELECT m.Id_MovimentacaoComanda
                    FROM dbo.Movimentacao_Comanda m
                    INNER JOIN dbo.Comanda c
                        ON c.Id_comanda = m.Id_comanda
                    WHERE c.Numero = @Numero
                      AND m.Status = 'A'
                );

                IF @Movimentacao IS NULL
                    THROW 50002, 'Comanda não está aberta.', 1;

                DECLARE @Permite bit;
                DECLARE @Valor decimal(10,2);

                SELECT
                    @Permite = Permite_Valor_Informado,
                    @Valor = Valor_Unitario
                FROM dbo.produto
                WHERE Id_produto = @Produto
                  AND Ativo = 1;

                IF @Permite IS NULL
                    THROW 50003, 'Produto inválido ou inativo.', 1;

                IF @Permite = 1
                    SET @Valor = @Informado;

                IF @Valor IS NULL OR @Valor <= 0
                    THROW 50004, 'Informe um valor maior que zero.', 1;

                INSERT INTO dbo.item_comanda
                    (Id_MovimentacaoComanda, Id_produto,
                     Quantidade, Valor_Unitario)
                VALUES
                    (@Movimentacao, @Produto, @Quantidade, @Valor);

                SELECT CAST(SCOPE_IDENTITY() AS bigint);";

            using (var cn = new SqlConnection(Conexao))
            using (var cmd = new SqlCommand(sql, cn))
            {
                cmd.Parameters
                    .Add("@Numero", SqlDbType.Int)
                    .Value = numero;
                cmd.Parameters
                    .Add("@Produto", SqlDbType.BigInt)
                    .Value = produtoId;
                cmd.Parameters
                    .Add("@Quantidade", SqlDbType.Int)
                    .Value = quantidade;

                SqlParameter parametroValor = cmd.Parameters.Add(
                    "@Informado",
                    SqlDbType.Decimal);
                parametroValor.Precision = 10;
                parametroValor.Scale = 2;
                parametroValor.Value = valorInformado.HasValue
                    ? (object)valorInformado.Value
                    : DBNull.Value;

                cn.Open();

                return new ResultadoDto
                {
                    Sucesso = true,
                    Id = Convert.ToInt64(cmd.ExecuteScalar()),
                    Numero = numero,
                    Mensagem = "Consumo adicionado."
                };
            }
        }

        public static ResultadoDto Fechar(int numero)
        {
            const string sql = @"
                UPDATE m
                SET Status = 'F',
                    DataFechamento = SYSDATETIME()
                FROM dbo.Movimentacao_Comanda m
                INNER JOIN dbo.Comanda c
                    ON c.Id_comanda = m.Id_comanda
                WHERE c.Numero = @Numero
                  AND m.Status = 'A';

                SELECT @@ROWCOUNT;";

            using (var cn = new SqlConnection(Conexao))
            using (var cmd = new SqlCommand(sql, cn))
            {
                cmd.Parameters
                    .Add("@Numero", SqlDbType.Int)
                    .Value = numero;

                cn.Open();

                if (Convert.ToInt32(cmd.ExecuteScalar()) == 0)
                {
                    throw new InvalidOperationException(
                        "Comanda não está aberta.");
                }

                return new ResultadoDto
                {
                    Sucesso = true,
                    Numero = numero,
                    Mensagem = "Comanda fechada e número liberado " +
                               "para novo atendimento."
                };
            }
        }

        public static void AlterarDisponibilidade(
            int numero,
            bool disponivel)
        {
            const string sql = @"
                IF @Disponivel = 1
                   AND EXISTS
                   (
                       SELECT 1
                       FROM dbo.Movimentacao_Comanda m
                       INNER JOIN dbo.Comanda c
                           ON c.Id_comanda = m.Id_comanda
                       WHERE c.Numero = @Numero
                         AND m.Status = 'A'
                   )
                    THROW 50005,
                          'Feche o atendimento antes de liberar a comanda.',
                          1;

                UPDATE dbo.Comanda
                SET Disponivel = @Disponivel
                WHERE Numero = @Numero;";

            using (var cn = new SqlConnection(Conexao))
            using (var cmd = new SqlCommand(sql, cn))
            {
                cmd.Parameters
                    .Add("@Numero", SqlDbType.Int)
                    .Value = numero;
                cmd.Parameters
                    .Add("@Disponivel", SqlDbType.Bit)
                    .Value = disponivel;

                cn.Open();
                cmd.ExecuteNonQuery();
            }
        }

        public static List<AtendimentoDto> Historico()
        {
            var lista = new List<AtendimentoDto>();

            const string sql = @"
                SELECT
                    m.Id_MovimentacaoComanda,
                    c.Numero,
                    m.Status,
                    m.DataAbertura,
                    m.DataFechamento,
                    COALESCE(SUM(i.Valor_Total), 0) AS Total
                FROM dbo.Movimentacao_Comanda m
                INNER JOIN dbo.Comanda c
                    ON c.Id_comanda = m.Id_comanda
                LEFT JOIN dbo.item_comanda i
                    ON i.Id_MovimentacaoComanda =
                       m.Id_MovimentacaoComanda
                GROUP BY
                    m.Id_MovimentacaoComanda,
                    c.Numero,
                    m.Status,
                    m.DataAbertura,
                    m.DataFechamento
                ORDER BY m.DataAbertura DESC;";

            using (var cn = new SqlConnection(Conexao))
            using (var cmd = new SqlCommand(sql, cn))
            {
                cn.Open();

                using (var reader = cmd.ExecuteReader())
                {
                    while (reader.Read())
                    {
                        lista.Add(new AtendimentoDto
                        {
                            IdMovimentacao = reader.GetInt64(0),
                            Numero = reader.GetInt32(1),
                            Status = reader.GetString(2),
                            DataAbertura = reader.GetDateTime(3),
                            DataFechamento = reader.IsDBNull(4)
                                ? (DateTime?)null
                                : reader.GetDateTime(4),
                            Total = reader.GetDecimal(5)
                        });
                    }
                }
            }

            return lista;
        }
    }
}
