# ComandaFlow.Legacy

MVP de controle de comandas físicas reutilizáveis para restaurante self-service, em ASP.NET Web Forms 4.8 e SQL Server via ADO.NET.

## Funcionalidades

- menu inicial com acesso aos fluxos do MVP;
- entrega manual de uma comanda física, após validação de existência e disponibilidade;
- lançamento de produtos com preço fixo ou valor informado pela balança;
- consulta e fechamento no caixa, com confirmação e liberação automática do número;
- situação das 100 comandas, filtros e edição controlada da disponibilidade;
- CRUD de produtos com postback clássico do Web Forms;
- histórico em **Movimentação de Comandas**, permitindo visualizar vários atendimentos com o mesmo número físico.

As telas operacionais usam chamadas AJAX para `WebMethod`. Por requisito do MVP, somente `Produtos.aspx` usa postback clássico.

## Modelo de dados

- `Comanda`: objeto físico (`Id_comanda`, `Numero`, `Disponivel`);
- `Movimentacao_Comanda`: um ciclo de atendimento (`DataAbertura`, `DataFechamento`, `Status`);
- `produto`: catálogo e regra do tipo de preço;
- `item_comanda`: consumos ligados à movimentação, com o preço cobrado preservado.

A procedure `dbo.usp_AbrirComanda` valida e abre a comanda escolhida em uma transação, bloqueando a linha para evitar duas entregas simultâneas do mesmo número. Uma trigger libera a comanda física quando a movimentação muda para `F`.

## Banco de dados

Execute, na ordem:

1. `scripts/00_create_database.sql`;
2. `scripts/01_ddl.sql` (recria as tabelas e portanto apaga dados anteriores);
3. `scripts/02_dml.sql` (insere as comandas 1–100 e os produtos iniciais).

Copie `ComandaFlow.Legacy/ConnectionStrings.example.config` para `ConnectionStrings.config`, configure o SQL Server e mantenha esse arquivo fora do versionamento.

## Execução

Abra `ComandaFlow.Legacy.slnx` no Visual Studio, restaure os pacotes, compile e execute pelo IIS Express. O fluxo principal é:

```text
entregar comanda → registrar consumo → consultar no caixa → fechar
→ liberar número → reutilizar em uma nova movimentação
```

## Tecnologias

ASP.NET Web Forms, .NET Framework 4.8, C#, ADO.NET, SQL Server, jQuery AJAX e Bootstrap.

Desenvolvido por **Domingos Neto**.
