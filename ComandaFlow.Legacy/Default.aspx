<%@ Page Title="Menu inicial"
    Language="C#"
    MasterPageFile="~/Site.Master"
    AutoEventWireup="true"
    CodeBehind="Default.aspx.cs"
    Inherits="ComandaFlow.Legacy._Default" %>

<asp:Content ID="BodyContent"
    ContentPlaceHolderID="MainContent"
    runat="server">

    <main class="mvp-page">
        <h1>Menu inicial</h1>
        <p class="lead">Selecione uma operação do ComandaFlow.</p>

        <div class="menu-grid">
            <!-- Chamadas que navegam diretamente para a página. -->
            <a class="menu-card" href="Lancamento.aspx">
                <strong>Registrar consumo</strong>
                <span>Lançar almoço, bebidas e sobremesas</span>
            </a>

            <a class="menu-card" href="Caixa.aspx">
                <strong>Caixa / Fechar comanda</strong>
                <span>Consultar total e encerrar atendimento</span>
            </a>

            <a class="menu-card" href="Produtos.aspx">
                <strong>Produtos</strong>
                <span>Manter o catálogo</span>
            </a>

            <%-- Chamadas que navegam via JavaScript. --%>
            <button type="button"
                id="btnComandas"
                class="menu-card menu-card-button">
                <strong>Comandas</strong>
                <span>Ver números disponíveis e em uso</span>
            </button>

            <button type="button"
                id="btnMovimentacoes"
                class="menu-card menu-card-button">
                <strong>Movimentação de Comandas</strong>
                <span>Consultar atendimentos anteriores</span>
            </button>
        </div>
    </main>

</asp:Content>

<asp:Content ID="Scripts"
    ContentPlaceHolderID="ScriptsContent"
    runat="server">

    <script>
        $(function () {
            $("#btnComandas").click(function () {
                window.location.href =
                    '<%= ResolveUrl("~/Comandas.aspx") %>';
            });

            $("#btnMovimentacoes").click(function () {
                window.location.href =
                    '<%= ResolveUrl("~/Movimentacoes.aspx") %>';
            });
        });
    </script>

</asp:Content>
