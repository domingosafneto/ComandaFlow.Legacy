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

            using (var cn = new SqlConnection(Conexao))
            using (var cmd = new SqlCommand("dbo.pr_ListarProdutos", cn))
            {
                cmd.CommandType = CommandType.StoredProcedure;
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
            using (var cn = new SqlConnection(Conexao))
            using (var cmd = new SqlCommand("dbo.pr_SalvarProduto", cn))
            {
                cmd.CommandType = CommandType.StoredProcedure;
                cmd.Parameters.Add("@Id", SqlDbType.BigInt).Value = id;
                cmd.Parameters
                    .Add("@Descricao", SqlDbType.VarChar, 100)
                    .Value = (object)descricao ?? DBNull.Value;

                SqlParameter parametroValor = cmd.Parameters.Add(
                    "@Valor",
                    SqlDbType.Decimal);
                parametroValor.Precision = 10;
                parametroValor.Scale = 2;
                parametroValor.Value = (object)valor ?? DBNull.Value;

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

            using (var cn = new SqlConnection(Conexao))
            using (var cmd = new SqlCommand("dbo.pr_ListarComandas", cn))
            {
                cmd.CommandType = CommandType.StoredProcedure;
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
            using (var cn = new SqlConnection(Conexao))
            using (var cmd = new SqlCommand("dbo.pr_AbrirComanda", cn))
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

        public static AtendimentoDto ObterComandaAberta(int numero)
        {
            AtendimentoDto atendimento = null;

            using (var cn = new SqlConnection(Conexao))
            using (var cmd = new SqlCommand("dbo.pr_ObterComandaAberta", cn))
            {
                cmd.CommandType = CommandType.StoredProcedure;
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

            using (var cn = new SqlConnection(Conexao))
            using (var cmd = new SqlCommand("dbo.pr_ListarItens", cn))
            {
                cmd.CommandType = CommandType.StoredProcedure;
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
            using (var cn = new SqlConnection(Conexao))
            using (var cmd = new SqlCommand("dbo.pr_AdicionarItem", cn))
            {
                cmd.CommandType = CommandType.StoredProcedure;
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
            using (var cn = new SqlConnection(Conexao))
            using (var cmd = new SqlCommand("dbo.pr_Fechar", cn))
            {
                cmd.CommandType = CommandType.StoredProcedure;
                cmd.Parameters
                    .Add("@Numero", SqlDbType.Int)
                    .Value = numero;

                cn.Open();

                cmd.ExecuteScalar();

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
            using (var cn = new SqlConnection(Conexao))
            using (var cmd = new SqlCommand("dbo.pr_AlterarDisponibilidade", cn))
            {
                cmd.CommandType = CommandType.StoredProcedure;
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

            using (var cn = new SqlConnection(Conexao))
            using (var cmd = new SqlCommand("dbo.pr_Historico", cn))
            {
                cmd.CommandType = CommandType.StoredProcedure;
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