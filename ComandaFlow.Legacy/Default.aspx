<%@ Page Title="Home Page" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="Default.aspx.cs" Inherits="ComandaFlow.Legacy._Default" %>

<asp:Content ID="BodyContent" ContentPlaceHolderID="MainContent" runat="server">
    
    <main>
        <div class="row">
        
            <section>
                <h2>Listagem de produtos</h2>

                <button type="button"
                        id="btnListarProdutos"
                        class="btn btn-success">
                    Listar produtos
                </button>
            </section>
        </div>
    </main>

</asp:Content>

<asp:Content ID="Scripts"
             ContentPlaceHolderID="ScriptsContent"
             runat="server">
<script>
    $(document).ready(function() {

        $("#btnListarProdutos").click(function() {
            
            window.location.href =
                    '<%= ResolveUrl("~/Produtos.aspx") %>';
            });
        });
</script>
</asp:Content>