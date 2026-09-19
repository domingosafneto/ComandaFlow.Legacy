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

A procedure `dbo.pr_AbrirComanda` valida e abre a comanda escolhida em uma transação, bloqueando a linha para evitar duas entregas simultâneas do mesmo número. Uma trigger libera a comanda física quando a movimentação muda para `F`.

## Banco de dados

Execute, na ordem:

1. `scripts/00_create_database.sql`;
2. `scripts/01_ddl.sql` (recria as tabelas e portanto apaga dados anteriores);
3. `scripts/02_dml.sql` (insere as comandas 1–100 e os produtos iniciais);
4. `scripts/03_procedures.sql` (instala as rotinas compartilhadas pelo Web Forms e pela API).

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

## Rotinas compartilhadas com a API

O critério é centralizar comportamento e critérios compartilhados. O Dados.cs chama dez procedures: cinco operações de negócio e cinco consultas principais. A exclusão simples de produto continua como DELETE parametrizado no Web Forms, protegida pela chave estrangeira.

| Categoria | Procedures dbo.pr_* | Motivo |
| --- | --- | --- |
| Negócio | SalvarProduto, AbrirComanda, AdicionarItem, Fechar, AlterarDisponibilidade | Validações e gravações iguais no Web Forms e na API. |
| Catálogo compartilhado | ListarProdutos | Mesmos produtos, filtro de ativos e ordenação. |
| Disponibilidade compartilhada | ListarComandas | Mesmos filtros T/D/U para a situação das comandas. |
| Atendimento compartilhado | ObterComandaAberta, ListarItens | Mesmo atendimento aberto, total e detalhamento dos consumos. |
| Relatório | Historico | Mesmos joins, totais e ordenação dos atendimentos. |

**Banco existente:** execute o próprio `scripts/03_procedures.sql`, sem executar o DDL destrutivo. Ele cria/atualiza as dez procedures, migra somente a antiga usp_AbrirComanda para pr_AbrirComanda e mantém removida a procedure ExcluirProduto. Nenhum script adicional de migração é necessário. Instale as procedures antes de publicar o Web Forms atualizado.

A API deve usar essas mesmas procedures para os fluxos compartilhados e tratar os erros SQL de negócio (THROW). Conexões, parâmetros tipados, mapeamento para DTOs e apresentação continuam nos clientes. Consultas futuras simples e exclusivas de uma tela podem permanecer no Web Forms; não é obrigatório criar procedure para cada SELECT.

Abertura, consumo, fechamento e disponibilidade mantêm suas transações e bloqueios. A trigger existente libera a comanda ao fechar. As consultas de cabeçalho e itens continuam em chamadas separadas e não constituem uma fotografia atômica diante de lançamentos concorrentes.

### Validação local

`powershell -File scripts/validar-procedures.ps1` valida as dez procedures no fluxo operacional e o DELETE parametrizado do Dados.cs. Os registros de teste são revertidos; -Aplicar confirma a atualização das procedures. Execute em desenvolvimento: testes adquirem bloqueios e podem avançar contadores IDENTITY mesmo com rollback. O teste não simula concorrência nem cobre todos os erros de negócio.

Veja o [checklist e inventário](docs/checklist-sql.md).

Todas as procedures, incluindo pr_AbrirComanda, são definidas exclusivamente no script 03. O 01_ddl.sql mantém a estrutura das tabelas, índices, constraints e trigger.
