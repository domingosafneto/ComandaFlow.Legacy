# Checklist — comportamento e critérios compartilhados

- [x] Mapear as 11 rotinas de Dados.cs e seus consumidores.
- [x] Separar cinco gravações com regras, cinco consultas compartilhadas e uma exclusão simples.
- [x] Centralizar dez procedures no banco, com prefixo pr_, no próprio script 03.
- [x] Ajustar o Web Forms para consumir as dez procedures; manter ExcluirProduto como DELETE parametrizado.

## Gravações com regras — banco

| Procedure dbo.pr_* | Consumidor | Responsabilidade |
| --- | --- | --- |
| SalvarProduto | Produtos | Descrição, tipo de preço, preço positivo e normalização de preço informado; inserir/atualizar. |
| AbrirComanda | Lançamento | Cadastro, disponibilidade e abertura transacional. |
| AdicionarItem | Lançamento | Atendimento aberto, quantidade, produto ativo e definição do preço cobrado. |
| Fechar | Caixa | Estado aberto, fechamento e liberação pela trigger. |
| AlterarDisponibilidade | Comandas | Impedir liberação manual durante atendimento aberto. |

## Consultas compartilhadas — banco

| Procedure dbo.pr_* | Consumidores atuais | Por que compartilhar com a API |
| --- | --- | --- |
| ListarProdutos | Produtos e Lançamento | Catálogo e critério de produto ativo; @Ativos bit = 0 permite listar todos. |
| ListarComandas | Comandas | Mesmos filtros de disponibilidade; @Filtro char(1) = T aceita T/D/U. |
| ObterComandaAberta | Caixa e Lançamento | Mesmo atendimento em estado A e mesma soma de consumos, por @Numero int. |
| ListarItens | ObterComandaAberta | Detalhamento compartilhado do atendimento, por @Id bigint da movimentação. |
| Historico | Movimentações | Relatório com joins, totais e ordenação comuns, sem parâmetros. |

Essas consultas continuam classificadas como leitura. Ficam no banco por compartilharem critérios ou agregações relevantes, mesmo quando o SELECT é simples. Não foram criadas procedures diferentes para cada filtro ou tela. A futura API ainda não está implementada; essas são as consultas principais preparadas para seu consumo.

Os retornos e a ordem das colunas foram preservados, mantendo o mapeamento dos DTOs. Cabeçalho e itens continuam em chamadas separadas, sem garantia de fotografia atômica entre elas.

## Persistência simples — Web Forms

ExcluirProduto, usado pela tela Produtos, mantém DELETE por ID no Dados.cs. A FK impede excluir um produto já utilizado. A procedure pr_ExcluirProduto permanece removida.

Consultas futuras muito simples e exclusivas da interface podem permanecer no Web Forms. O inventário atual não identificou uma consulta principal que devesse ficar exclusiva da interface.

## Regras estruturais mantidas

Constraints, chaves estrangeiras, índice único de atendimento aberto, coluna calculada Valor_Total e trigger de liberação continuam no banco. Transações e bloqueios das operações de comanda foram preservados.

## Implantação e verificação

O script 03 cria/atualiza dez procedures e remove versões antigas da procedure de exclusão. Execute-o antes de publicar o Web Forms atualizado. Nenhum novo script de migração foi criado.

O teste existente validar-procedures.ps1 exercita as dez procedures, confere o total e a liberação da comanda e executa o SQL de exclusão do Dados.cs. Os dados de teste são revertidos. Não simula concorrência nem cobre todos os cenários de erro.

A definição de pr_AbrirComanda fica exclusivamente no script 03. O único rename mantido é usp_AbrirComanda para pr_AbrirComanda, para bancos criados pelo DDL antigo.
