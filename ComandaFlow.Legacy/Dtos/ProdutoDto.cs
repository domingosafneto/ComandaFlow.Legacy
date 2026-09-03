namespace ComandaFlow.Legacy
{
    public class ProdutoDto
    {
        public long IdProduto { get; set; }

        public string Descricao { get; set; }

        public decimal? ValorUnitario { get; set; }

        public bool PermiteValorInformado { get; set; }

        public bool Ativo { get; set; }
    }
}
