using System;
using System.Globalization;
using System.Linq;
using System.Web.UI.WebControls;

namespace ComandaFlow.Legacy
{
    public partial class Produtos : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
            {
                Carregar();
            }
        }

        private void Carregar()
        {
            Lista.DataSource = Dados.ListarProdutos();
            Lista.DataBind();
        }

        protected string FormatarValor(object value)
        {
            return value == null
                ? "Informado no lançamento"
                : ((decimal)value).ToString(
                    "C",
                    CultureInfo.GetCultureInfo("pt-BR"));
        }

        protected void Salvar_Click(object sender, EventArgs e)
        {
            try
            {
                decimal valorConvertido;

                decimal? valor = decimal.TryParse(
                    Valor.Text,
                    NumberStyles.Currency,
                    CultureInfo.GetCultureInfo("pt-BR"),
                    out valorConvertido)
                        ? valorConvertido
                        : (decimal?)null;

                Dados.SalvarProduto(
                    string.IsNullOrEmpty(ProdutoId.Value)
                        ? 0
                        : long.Parse(ProdutoId.Value),
                    Descricao.Text,
                    valor,
                    PermiteValor.Checked,
                    Ativo.Checked);

                Limpar();
                Mensagem.CssClass = "alert alert-success d-block";
                Mensagem.Text = "Produto salvo com sucesso.";
                Carregar();
            }
            catch (Exception ex)
            {
                Mensagem.CssClass = "alert alert-danger d-block";
                Mensagem.Text = Server.HtmlEncode(ex.Message);
            }
        }

        protected void Cancelar_Click(object sender, EventArgs e)
        {
            Limpar();
            Carregar();
        }

        protected void Lista_ItemCommand(
            object source,
            RepeaterCommandEventArgs e)
        {
            try
            {
                long id = long.Parse((string)e.CommandArgument);

                if (e.CommandName == "Excluir")
                {
                    Dados.ExcluirProduto(id);
                    Limpar();
                }
                else if (e.CommandName == "Editar")
                {
                    ProdutoDto produto = Dados
                        .ListarProdutos()
                        .First(item => item.IdProduto == id);

                    ProdutoId.Value = id.ToString();
                    Descricao.Text = produto.Descricao;
                    Valor.Text = produto.ValorUnitario.HasValue
                        ? produto.ValorUnitario.Value.ToString("N2")
                        : string.Empty;
                    PermiteValor.Checked = produto.PermiteValorInformado;
                    Ativo.Checked = produto.Ativo;
                    TituloFormulario.Text = "Alterar produto";
                }

                Carregar();
            }
            catch (Exception ex)
            {
                Mensagem.CssClass = "alert alert-danger d-block";
                Mensagem.Text = Server.HtmlEncode(ex.Message);
            }
        }

        private void Limpar()
        {
            ProdutoId.Value = string.Empty;
            Descricao.Text = string.Empty;
            Valor.Text = string.Empty;
            PermiteValor.Checked = false;
            Ativo.Checked = true;
            TituloFormulario.Text = "Novo produto";
        }
    }
}