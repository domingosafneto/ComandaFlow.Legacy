<%@ Page Title="Situação das comandas"
    Language="C#"
    MasterPageFile="~/Site.Master"
    AutoEventWireup="true"
    CodeBehind="Comandas.aspx.cs"
    Inherits="ComandaFlow.Legacy.Comandas" %>

<asp:Content ID="Body"
    ContentPlaceHolderID="MainContent"
    runat="server">

    <main class="mvp-page">
        <div class="d-flex justify-content-between">
            <h1>Situação das comandas</h1>
            <button id="atualizar"
                type="button"
                class="btn btn-outline-primary">
                Atualizar
            </button>
        </div>

        <div class="btn-group my-3" role="group">
            <button class="btn btn-primary filtro"
                data-f="T"
                type="button">
                Todas
            </button>
            <button class="btn btn-outline-primary filtro"
                data-f="D"
                type="button">
                Disponíveis
            </button>
            <button class="btn btn-outline-primary filtro"
                data-f="U"
                type="button">
                Em uso
            </button>
        </div>

        <div id="feedback"></div>

        <div class="panel-mvp table-responsive">
            <table class="table table-hover">
                <thead>
                    <tr>
                        <th>Número</th>
                        <th>Situação</th>
                        <th>Ação</th>
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
        var filtro = "T";

        function api(metodo, dados, sucesso) {
            $.ajax({
                type: "POST",
                url: "Comandas.aspx/" + metodo,
                data: JSON.stringify(dados),
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: function (resposta) {
                    sucesso(resposta.d);
                },
                error: function (xhr) {
                    var mensagem = xhr.responseJSON && xhr.responseJSON.Message
                        ? xhr.responseJSON.Message
                        : "Falha na operação.";

                    $("#feedback")
                        .attr("class", "alert alert-danger")
                        .text(mensagem);
                }
            });
        }

        function listar() {
            api("Listar", { filtro: filtro }, function (comandas) {
                $("#lista").empty();

                $.each(comandas, function (_, comanda) {
                    var botao = $(
                        "<button type='button' " +
                        "class='btn btn-sm btn-outline-secondary'>"
                    )
                        .text(
                            "Marcar " +
                            (comanda.Disponivel ? "em uso" : "disponível")
                        )
                        .click(function () {
                            api("Alterar", {
                                numero: comanda.Numero,
                                disponivel: !comanda.Disponivel
                            }, listar);
                        });

                    var situacao = $("<span class='status-pill'>")
                        .addClass(
                            comanda.Disponivel
                                ? "status-livre"
                                : "status-uso"
                        )
                        .text(
                            comanda.Disponivel
                                ? "DISPONÍVEL"
                                : "EM USO"
                        );

                    $("#lista").append(
                        $("<tr>").append(
                            $("<td>").text(
                                String(comanda.Numero).padStart(3, "0")
                            ),
                            $("<td>").append(situacao),
                            $("<td>").append(botao)
                        )
                    );
                });

                $("#feedback")
                    .attr("class", "text-muted mb-2")
                    .text(comandas.length + " comanda(s).");
            });
        }

        $(function () {
            listar();
            $("#atualizar").click(listar);

            $(".filtro").click(function () {
                filtro = $(this).data("f");
                $(".filtro")
                    .removeClass("btn-primary")
                    .addClass("btn-outline-primary");
                $(this)
                    .addClass("btn-primary")
                    .removeClass("btn-outline-primary");
                listar();
            });
        });
    </script>

</asp:Content>
