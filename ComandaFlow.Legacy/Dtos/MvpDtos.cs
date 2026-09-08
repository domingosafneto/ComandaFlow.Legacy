using System;
using System.Collections.Generic;

namespace ComandaFlow.Legacy
{
    public class ResultadoDto { public bool Sucesso { get; set; } public string Mensagem { get; set; } public long Id { get; set; } public int Numero { get; set; } }
    public class ComandaDto { public long IdComanda { get; set; } public int Numero { get; set; } public bool Disponivel { get; set; } }
    public class ItemDto { public string Produto { get; set; } public int Quantidade { get; set; } public decimal ValorUnitario { get; set; } public decimal ValorTotal { get; set; } }
    public class AtendimentoDto
    {
        public long IdMovimentacao { get; set; }
        public int Numero { get; set; }
        public string Status { get; set; }
        public DateTime DataAbertura { get; set; }
        public DateTime? DataFechamento { get; set; }
        public decimal Total { get; set; }
        public List<ItemDto> Itens { get; set; }
    }
}
