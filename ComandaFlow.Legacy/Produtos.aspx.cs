using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data.SqlClient;
using System.Web.Services;

namespace ComandaFlow.Legacy
{
    public partial class Produtos : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
        }

        [WebMethod]
        public static List<ProdutoDto> ListarProdutos()
        {
            var produtos = new List<ProdutoDto>();

            var connectionString =
                ConfigurationManager
                    .ConnectionStrings["ComandaFlowDb"]
                    .ConnectionString;

            const string sql = @"
                SELECT
                    Id_produto,
                    Descricao,
                    Valor_Unitario,
                    Permite_Valor_Informado,
                    Ativo
                FROM dbo.produto
                ORDER BY Descricao;";

            using (var connection = new SqlConnection(connectionString))
            using (var command = new SqlCommand(sql, connection))
            {
                connection.Open();

                using (var reader = command.ExecuteReader())
                {
                    var vId = reader.GetOrdinal("Id_produto");
                    var vDescricao = reader.GetOrdinal("Descricao");
                    var vValorUnitario = reader.GetOrdinal("Valor_Unitario");
                    var vPermiteValorInformado = reader.GetOrdinal("Permite_Valor_Informado");
                    var vAtivo = reader.GetOrdinal("Ativo");

                    while (reader.Read())
                    {
                        var produto = new ProdutoDto
                        {
                            IdProduto = reader.GetInt64(vId),

                            Descricao = reader.GetString(vDescricao),

                            // "ALMOÇO PESO" possui Valor_Unitario nulo.
                            ValorUnitario = reader.IsDBNull(vValorUnitario)
                                    ? (decimal?)null
                                    : reader.GetDecimal(vValorUnitario),

                            PermiteValorInformado = reader.GetBoolean(vPermiteValorInformado),

                            Ativo = reader.GetBoolean(vAtivo)
                        };

                        produtos.Add(produto);
                    }
                }
            }

            return produtos;
        }
    }
}
