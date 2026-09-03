<%@ Page Title="Produtos"
    Language="C#"
    MasterPageFile="~/Site.Master"
    AutoEventWireup="true"
    CodeBehind="Produtos.aspx.cs"
    Inherits="ComandaFlow.Legacy.Produtos" %>

<asp:Content ID="BodyContent"
             ContentPlaceHolderID="MainContent"
             runat="server">
    <main>
        <section class="mt-4" aria-labelledby="tituloProdutos">

            <div class="d-flex justify-content-between align-items-center mb-3">
                <h1 id="tituloProdutos">Produtos</h1>

                <div class="d-flex gap-2">
                    <button type="button"
                            id="btnAtualizar"
                            class="btn btn-primary">
                        Atualizar
                    </button>

                    <a runat="server"
                       href="~/"
                       class="btn btn-secondary">
                        Voltar
                    </a>
                </div>
            </div>

            <div id="mensagem" class="mb-3"></div>

            <div class="table-responsive">
                <table class="table table-striped table-bordered">
                    <thead>
                        <tr>
                            <th>Código</th>
                            <th>Descrição</th>
                            <th>Valor</th>
                            <th>Tipo de valor</th>
                            <th>Status</th>
                        </tr>
                    </thead>

                    <tbody id="corpoTabelaProdutos">
                    </tbody>
                </table>
            </div>

        </section>
    </main>
</asp:Content>

<asp:Content ID="ScriptsContent"
             ContentPlaceHolderID="ScriptsContent"
             runat="server">
    <script>
        $(document).ready(function () {

            // Carrega os produtos assim que a página estiver pronta.
            listarProdutos();

            // Permite atualizar a listagem sem recarregar a página.
            $("#btnAtualizar").click(function () {
                listarProdutos();
            });
        });


        function listarProdutos() {

            $("#mensagem").text("Carregando produtos...");
            $("#corpoTabelaProdutos").empty();

            $.ajax({
                type: "POST",
                
                url: '<%= ResolveUrl("~/Produtos.aspx/ListarProdutos") %>',

                data: "{}",

                contentType: "application/json; charset=utf-8",
                dataType: "json",

                success: function(response) {
                    var produtos = response.d;

                    $.each(produtos, function(indice, produto) {

                        var valor;

                        if (produto.ValorUnitario === null) {
                            valor = "Informado na pesagem";
                        } else {
                            valor = produto.ValorUnitario.toLocaleString(
                                "pt-BR",
                                {
                                    style: "currency",
                                    currency: "BRL"
                                }
                            );
                        }

                        var linha = $("<tr>");

                        linha.append(
                            $("<td>").text(produto.IdProduto)
                        );

                        linha.append(
                            $("<td>").text(produto.Descricao)
                        );

                        linha.append(
                            $("<td>").text(valor)
                        );

                        linha.append(
                            $("<td>").text(
                                produto.PermiteValorInformado
                                    ? "Valor informado"
                                    : "Preço fixo"
                            )
                        );

                        linha.append(
                            $("<td>").text(
                                produto.Ativo ? "Ativo" : "Inativo"
                            )
                        );

                        $("#corpoTabelaProdutos").append(linha);
                    });

                    $("#mensagem").text(
                        produtos.length + " produto(s) encontrado(s)."
                    );
                },

                error: function(xhr, status, error) {
                    console.log(xhr.responseText);

                    $("#mensagem").text(
                        "Não foi possível carregar os produtos. HTTP " +
                        xhr.status
                    );
                }
            });
        }
    </script>
</asp:Content>
