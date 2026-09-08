<%@ Page Title="Caixa"
    Language="C#"
    MasterPageFile="~/Site.Master"
    AutoEventWireup="true"
    CodeBehind="Caixa.aspx.cs"
    Inherits="ComandaFlow.Legacy.Caixa" %>

<asp:Content ID="Body"
    ContentPlaceHolderID="MainContent"
    runat="server">

    <main class="mvp-page">
        <h1>Caixa</h1>

        <div class="panel-mvp">
            <label for="numero" class="form-label">
                Número da comanda
            </label>

            <div class="input-group">
                <input id="numero"
                    class="form-control"
                    type="number"
                    min="1" />

                <button id="buscar"
                    type="button"
                    class="btn btn-primary">
                    Buscar
                </button>
            </div>
        </div>

        <div id="feedback" role="status"></div>

        <section id="conta" class="panel-mvp d-none">
            <h2 id="titulo" class="h4"></h2>
            <p id="abertura"></p>

            <table class="table">
                <tbody id="itens"></tbody>
                <tfoot>
                    <tr>
                        <th>Total</th>
                        <th id="total" class="money"></th>
                    </tr>
                </tfoot>
            </table>

            <button id="fechar"
                type="button"
                class="btn btn-danger">
                Fechar comanda
            </button>
        </section>
    </main>

</asp:Content>

<asp:Content ID="Scripts"
    ContentPlaceHolderID="ScriptsContent"
    runat="server">

    <script>
        var atual = null;

        function moeda(valor) {
            return valor.toLocaleString("pt-BR", {
                style: "currency",
                currency: "BRL"
            });
        }

        function erro(xhr) {
            var mensagem = xhr.responseJSON && xhr.responseJSON.Message
                ? xhr.responseJSON.Message
                : "Falha na operação.";

            $("#feedback")
                .attr("class", "alert alert-danger")
                .text(mensagem);
        }

        function api(metodo, dados, sucesso) {
            $.ajax({
                type: "POST",
                url: "Caixa.aspx/" + metodo,
                data: JSON.stringify(dados),
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: function (resposta) {
                    sucesso(resposta.d);
                },
                error: erro
            });
        }

        function buscar() {
            var numero = parseInt($("#numero").val(), 10);

            if (!Number.isInteger(numero) || numero <= 0) {
                atual = null;
                $("#conta").addClass("d-none");
                $("#feedback")
                    .attr("class", "alert alert-warning")
                    .text(
                        "Informe o número da comanda para buscar " +
                        "uma movimentação."
                    );
                return;
            }

            api("Buscar", { numero: numero }, function (atendimento) {
                atual = atendimento;

                if (!atendimento) {
                    $("#conta").addClass("d-none");
                    $("#feedback")
                        .attr("class", "alert alert-warning")
                        .text(
                            "Não há movimentação aberta para a " +
                            "comanda informada."
                        );
                    return;
                }

                $("#feedback").empty().removeClass();
                $("#conta").removeClass("d-none");
                $("#titulo").text(
                    "Comanda " +
                    String(atendimento.Numero).padStart(3, "0")
                );
                $("#abertura").text(
                    "Aberta em: " +
                    new Date(
                        parseInt(atendimento.DataAbertura.substr(6), 10)
                    ).toLocaleString("pt-BR")
                );
                $("#itens").empty();

                $.each(atendimento.Itens, function (_, item) {
                    $("#itens").append(
                        $("<tr>").append(
                            $("<td>").text(
                                item.Produto + " × " + item.Quantidade
                            ),
                            $("<td class='money'>").text(
                                moeda(item.ValorTotal)
                            )
                        )
                    );
                });

                $("#total").text(moeda(atendimento.Total));
            });
        }

        $(function () {
            $("#buscar").click(buscar);

            $("#numero").on("keydown", function (evento) {
                if (evento.key === "Enter") {
                    evento.preventDefault();
                    buscar();
                }
            });

            $("#fechar").click(function () {
                if (!atual) {
                    return;
                }

                var confirmado = confirm(
                    "Confirmar fechamento da comanda " +
                    String(atual.Numero).padStart(3, "0") +
                    " no valor de " + moeda(atual.Total) + "?"
                );

                if (confirmado) {
                    api("Fechar", { numero: atual.Numero }, function (resultado) {
                        atual = null;
                        $("#conta").addClass("d-none");
                        $("#feedback")
                            .attr("class", "alert alert-success")
                            .text(resultado.Mensagem);
                    });
                }
            });
        });
    </script>

</asp:Content>
