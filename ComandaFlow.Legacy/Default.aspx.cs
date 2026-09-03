using System;
using System.Configuration;
using System.Data.SqlClient;
using System.Web.Services;
using System.Web.UI;

namespace ComandaFlow.Legacy
{
    public partial class _Default : Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {

        }

        [WebMethod]        
        public static string TestarConexao()
        {
            var connectionString =
                ConfigurationManager
                    .ConnectionStrings["ComandaFlowDb"]
                    .ConnectionString;


            using (var connection = new SqlConnection(connectionString))
            {
                connection.Open();

                using (var command = new SqlCommand("SELECT 1", connection))
                {
                    var resultado = command.ExecuteScalar();

                    if (resultado.ToString() == "1")
                    {
                        return "Conexão com o banco realizada com sucesso.";
                    }

                    return "Falha no teste da conexão.";
                }
            }
        }
    }
}