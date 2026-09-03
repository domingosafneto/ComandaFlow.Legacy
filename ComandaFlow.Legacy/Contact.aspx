<%@ Page Title="Contato"
    Language="C#"
    MasterPageFile="~/Site.Master"
    AutoEventWireup="true"
    CodeBehind="Contact.aspx.cs"
    Inherits="ComandaFlow.Legacy.Contact" %>

<asp:Content ID="BodyContent"
             ContentPlaceHolderID="MainContent"
             runat="server">

    <main>
        <section class="mt-4"
                 aria-labelledby="tituloContato">
            <h1 id="tituloContato">Contato</h1>
            <p>
                Projeto desenvolvido por
                <strong>Domingos Neto</strong>.
            </p>
            <p>
                <a href="https://www.linkedin.com/in/domingosafneto/"
                   target="_blank"
                   rel="noopener noreferrer"
                   class="btn btn-primary">

                    Acessar LinkedIn de Domingos Neto

                </a>

                <a runat="server"
                   href="~/"
                   class="btn btn-secondary">
                    Voltar
                </a>
            </p>
        </section>
    </main>

</asp:Content>