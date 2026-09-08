<%@ Page Title="Movimentação de Comandas"
    Language="C#"
    MasterPageFile="~/Site.Master"
    AutoEventWireup="true"
    CodeBehind="Movimentacoes.aspx.cs"
    Inherits="ComandaFlow.Legacy.Movimentacoes" %>

<asp:Content ID="Body"
    ContentPlaceHolderID="MainContent"
    runat="server">

    <main class="mvp-page">
        <div class="d-flex justify-content-between">
            <h1>Movimentação de Comandas</h1>
            <button id="atualizar"
                type="button"
                class="btn btn-outline-primary">
                Atualizar
            </button>
        </div>

        <p>Atendimentos distintos podem reutilizar o mesmo número físico.</p>
        <div id="feedback"></div>

        <div class="panel-mvp table-responsive">
            <table class="table table-striped">
                <thead>
                    <tr>
                        <th>Número</th>
                        <th>Abertura</th>
                        <th>Fechamento</th>
                        <th>Status</th>
                        <th class="money">Total</th>
                    </tr>
                </thead>
                <tbody id="lista"></tbody>
            </table>
        </div>
    </main>

</asp:Content>

<asp:Content ID="Scripts"
    ContentPlaceHolderID="ScriptsContent"
    runat="server">

    <script>
        function formatarData(valor) {
            if (!valor) {
                return "—";
            }

            return new Date(
                parseInt(valor.substr(6), 10)
            ).toLocaleString("pt-BR");
        }

        function listar() {
            $.ajax({
                type: "POST",
                url: "Movimentacoes.aspx/Listar",
                data: "{}",
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: function (resposta) {
                    var movimentacoes = resposta.d;
                    $("#lista").empty();

                    $.each(movimentacoes, function (_, movimentacao) {
                        $("#lista").append(
                            $("<tr>").append(
                                $("<td>").text(
                                    String(movimentacao.Numero)
                                        .padStart(3, "0")
                                ),
                                $("<td>").text(
                                    formatarData(movimentacao.DataAbertura)
                                ),
                                $("<td>").text(
                                    formatarData(movimentacao.DataFechamento)
                                ),
                                $("<td>").text(
                                    movimentacao.Status === "A"
                                        ? "ABERTA"
                                        : "FECHADA"
                                ),
                                $("<td class='money'>").text(
                                    movimentacao.Total.toLocaleString(
                                        "pt-BR",
                                        {
                                            style: "currency",
                                            currency: "BRL"
                                        }
                                    )
                                )
                            )
                        );
                    });

                    $("#feedback")
                        .attr("class", "text-muted mb-2")
                        .text(
                            movimentacoes.length + " movimentação(ões)."
                        );
                },
                error: function () {
                    $("#feedback")
                        .attr("class", "alert alert-danger")
                        .text(
                            "Não foi possível carregar as movimentações."
                        );
                }
            });
        }

        $(function () {
            listar();
            $("#atualizar").click(listar);
        });
    </script>

</asp:Content>
