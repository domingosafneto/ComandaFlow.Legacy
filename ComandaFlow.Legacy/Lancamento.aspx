<%@ Page Title="Registrar consumo"
    Language="C#"
    MasterPageFile="~/Site.Master"
    AutoEventWireup="true"
    CodeBehind="Lancamento.aspx.cs"
    Inherits="ComandaFlow.Legacy.Lancamento" %>

<asp:Content ID="Body"
    ContentPlaceHolderID="MainContent"
    runat="server">

    <main class="mvp-page">
        <h1>Registrar consumo</h1>

        <div class="panel-mvp">
            <h2 class="h4">Entregar comanda</h2>
            <label for="numeroEntrega" class="form-label">
                Número da comanda física
            </label>

            <div class="input-group">
                <input id="numeroEntrega"
                    type="text"
                    inputmode="numeric"
                    pattern="[0-9]*"
                    maxlength="3"
                    autocomplete="off"
                    class="form-control"
                    aria-describedby="validacaoEntrega" />

                <button type="button"
                    id="abrir"
                    class="btn btn-success">
                    Entregar ao cliente
                </button>
            </div>

            <div id="validacaoEntrega" class="form-text">
                Digite somente números.
            </div>
        </div>

        <div class="panel-mvp">
            <label for="numero" class="form-label">
                Número da comanda
            </label>

            <div class="input-group">
                <input id="numero"
                    type="number"
                    min="1"
                    class="form-control" />

                <button type="button"
                    id="buscar"
                    class="btn btn-primary">
                    Buscar
                </button>
            </div>
        </div>

        <div id="feedback" class="feedback" role="status"></div>

        <section id="lancador" class="panel-mvp d-none">
            <h2 class="h4" id="titulo"></h2>

            <div class="row g-3">
                <div class="col-md-4">
                    <label class="form-label">Produto</label>
                    <select id="produto" class="form-select"></select>
                </div>

                <div class="col-md-3">
                    <label class="form-label">Quantidade</label>
                    <input id="quantidade"
                        class="form-control"
                        type="number"
                        min="1"
                        value="1" />
                </div>

                <div class="col-md-3">
                    <label class="form-label">Valor do produto</label>
                    <input id="valor"
                        class="form-control"
                        inputmode="decimal"
                        placeholder="0,00"
                        disabled />
                </div>

                <div class="col-md-2 d-flex align-items-end">
                    <button type="button"
                        id="adicionar"
                        class="btn btn-success w-100">
                        Adicionar
                    </button>
                </div>
            </div>
        </section>

        <section id="resumo" class="panel-mvp d-none">
            <h2 class="h4">Itens lançados</h2>

            <div class="table-responsive">
                <table class="table">
                    <thead>
                        <tr>
                            <th>Produto</th>
                            <th>Qtd.</th>
                            <th class="money">Valor</th>
                            <th class="money">Total</th>
                        </tr>
                    </thead>
                    <tbody id="itens"></tbody>
                    <tfoot>
                        <tr>
                            <th colspan="3">Total</th>
                            <th id="total" class="money"></th>
                        </tr>
                    </tfoot>
                </table>
            </div>
        </section>
    </main>

</asp:Content>

<asp:Content ID="Scripts"
    ContentPlaceHolderID="ScriptsContent"
    runat="server">

    <script>
        var produtos = [];

        function moeda(valor) {
            return valor.toLocaleString("pt-BR", {
                style: "currency",
                currency: "BRL"
            });
        }

        function erro(xhr) {
            var mensagem = xhr.responseJSON && xhr.responseJSON.Message
                ? xhr.responseJSON.Message
                : "Não foi possível concluir a operação.";

            $("#feedback")
                .attr("class", "alert alert-danger")
                .text(mensagem);
        }

        function api(metodo, dados, sucesso) {
            $.ajax({
                type: "POST",
                url: "Lancamento.aspx/" + metodo,
                data: JSON.stringify(dados || {}),
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: function (resposta) {
                    sucesso(resposta.d);
                },
                error: erro
            });
        }

        function carregarProdutos() {
            api("ListarProdutos", {}, function (resultado) {
                produtos = resultado;
                $("#produto").empty();

                $.each(produtos, function (_, produto) {
                    $("#produto").append(
                        $("<option>")
                            .val(produto.IdProduto)
                            .text(produto.Descricao)
                    );
                });

                $("#produto").trigger("change");
            });
        }

        function numeroEntregaValido() {
            var texto = $("#numeroEntrega").val();
            var valido = /^[0-9]+$/.test(texto) &&
                parseInt(texto, 10) > 0;

            $("#numeroEntrega").toggleClass("is-invalid", !valido);
            $("#validacaoEntrega")
                .text(valido
                    ? "Número válido."
                    : "Informe a comanda usando somente números.")
                .toggleClass("text-danger", !valido);

            return valido;
        }

        function buscar() {
            var numero = parseInt($("#numero").val(), 10);

            api("Buscar", { numero: numero }, function (atendimento) {
                if (!atendimento) {
                    $("#lancador, #resumo").addClass("d-none");
                    $("#feedback")
                        .attr("class", "alert alert-warning")
                        .text("Não há atendimento aberto para esta comanda.");
                    return;
                }

                $("#feedback").empty().removeClass();
                $("#titulo").text(
                    "Comanda " +
                    String(atendimento.Numero).padStart(3, "0") +
                    " — ABERTA"
                );
                $("#lancador, #resumo").removeClass("d-none");
                $("#itens").empty();

                $.each(atendimento.Itens, function (_, item) {
                    $("#itens").append(
                        $("<tr>").append(
                            $("<td>").text(item.Produto),
                            $("<td>").text(item.Quantidade),
                            $("<td class='money'>").text(
                                moeda(item.ValorUnitario)
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
            carregarProdutos();

            $("#produto").change(function () {
                var produtoId = parseInt($(this).val(), 10);
                var selecionado = produtos.find(function (produto) {
                    return produto.IdProduto === produtoId;
                });

                if (!selecionado) {
                    return;
                }

                var valorInformado = selecionado.PermiteValorInformado;
                var valor = valorInformado
                    ? ""
                    : selecionado.ValorUnitario.toLocaleString("pt-BR", {
                        minimumFractionDigits: 2,
                        maximumFractionDigits: 2
                    });

                $("#valor")
                    .prop("disabled", !valorInformado)
                    .val(valor);
            });

            $("#buscar").click(buscar);

            $("#numeroEntrega")
                .on("input", function () {
                    this.value = this.value.replace(/[^0-9]/g, "");

                    if (this.value) {
                        numeroEntregaValido();
                    }
                })
                .on("keydown", function (evento) {
                    if (evento.key === "Enter") {
                        evento.preventDefault();
                        $("#abrir").click();
                    }
                });

            $("#abrir").click(function () {
                if (!numeroEntregaValido()) {
                    return;
                }

                var numero = parseInt($("#numeroEntrega").val(), 10);

                api("Abrir", { numero: numero }, function (resultado) {
                    $("#numero").val(resultado.Numero);
                    $("#numeroEntrega").val("");
                    $("#feedback")
                        .attr("class", "alert alert-success")
                        .text(
                            "Comanda " +
                            String(resultado.Numero).padStart(3, "0") +
                            " entregue e aberta com sucesso."
                        );
                    buscar();
                });
            });

            $("#adicionar").click(function () {
                var valorTexto = $("#valor").val().replace(",", ".");

                api("Adicionar", {
                    numero: parseInt($("#numero").val(), 10),
                    produtoId: parseInt($("#produto").val(), 10),
                    quantidade: parseInt($("#quantidade").val(), 10),
                    valorInformado: valorTexto
                        ? parseFloat(valorTexto)
                        : null
                }, function () {
                    buscar();
                });
            });
        });
    </script>

</asp:Content>
