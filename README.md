# ComandaFlow.Legacy

MVP de um sistema de comandas para restaurante self-service, desenvolvido em
ASP.NET Web Forms com acesso direto ao SQL Server por ADO.NET.

O projeto representa uma aplicação legada funcional que poderá ser modernizada
posteriormente por meio de uma Web API e de um aplicativo .NET MAUI.

## Funcionalidades atuais

- página inicial com acesso à listagem de produtos;
- listagem de produtos carregada sem recarregar a página;
- chamada AJAX com jQuery para um `WebMethod` no code-behind;
- consulta ao SQL Server utilizando ADO.NET;
- indicação de produtos com preço fixo ou valor informado na pesagem;
- página de contato do desenvolvedor;
- navegação de retorno para a página inicial.

## Tecnologias

- ASP.NET Web Forms;
- .NET Framework 4.8;
- C#;
- ADO.NET (`System.Data.SqlClient`);
- SQL Server;
- JavaScript e jQuery AJAX;
- Bootstrap;
- IIS Express;
- Visual Studio 2026.

## Estrutura principal

```text
ComandaFlow.Legacy/
├── ComandaFlow.Legacy.slnx
├── README.md
├── scripts/
│   ├── 00_create_database.sql
│   ├── 01_ddl.sql
│   └── 02_dml.sql
└── ComandaFlow.Legacy/
    ├── Default.aspx
    ├── Produtos.aspx
    ├── Contact.aspx
    ├── Site.Master
    ├── Web.config
    └── ConnectionStrings.example.config
```

## Modelo de dados do MVP

- `comanda`: registra abertura, fechamento e situação da comanda;
- `produto`: catálogo de almoço, bebidas e sobremesas;
- `item_comanda`: registra cada consumo lançado em uma comanda.

O preço atual fica em `produto.Valor_Unitario`. O preço efetivamente cobrado é
copiado para `item_comanda.Valor_Unitario`, preservando o histórico caso o preço
do produto seja alterado posteriormente.

O produto `ALMOÇO PESO` permite valor informado porque a balança já calcula o
valor do prato. Os demais produtos utilizam o preço cadastrado.

## Preparação do banco de dados

Execute os scripts na seguinte ordem:

1. `00_create_database.sql`: cria o banco `selfservice_legacy`;
2. `01_ddl.sql`: cria tabelas, chaves, restrições e índices;
3. `02_dml.sql`: insere os dados iniciais para demonstração.

## Configuração da conexão

As credenciais reais do banco não devem ser versionadas.

1. Copie `ConnectionStrings.example.config` para
   `ConnectionStrings.config` na pasta do projeto Web Forms.
2. Preencha servidor, usuário e senha com os dados do ambiente local.
3. Verifique se `ConnectionStrings.config` está incluído no `.gitignore`.

O `Web.config` referencia o arquivo local desta forma:

```xml
<connectionStrings configSource="ConnectionStrings.config" />
```

## Execução

1. Abra `ComandaFlow.Legacy.slnx` no Visual Studio.
2. Restaure os pacotes NuGet, se solicitado.
3. Compile a solução.
4. Execute pelo IIS Express.
5. Na página inicial, selecione **Listar produtos**.

## Fluxo da listagem de produtos

```text
Produtos.aspx
    → jQuery AJAX
    → Produtos.aspx/ListarProdutos
    → WebMethod no code-behind
    → ADO.NET
    → SQL Server
```

## Autor

Desenvolvido por **Domingos Neto**.
