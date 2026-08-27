# SelfService Legacy — Banco de dados V1

Base SQL Server do MVP em ASP.NET Web Forms para comandas de um restaurante
self-service.

## Estrutura

```text
selfservice-legacy/
└── scripts/
    ├── 00_create_database.sql
    ├── 01_ddl.sql
    └── 02_dml.sql
```

## Ordem de execução

1. Execute `00_create_database.sql` conectado à instância do SQL Server.
2. Execute `01_ddl.sql` para criar as tabelas e restrições.
3. Execute `02_dml.sql` para cadastrar os produtos iniciais.

## Modelo do MVP

- `comanda`: registra abertura, fechamento e situação da comanda.
- `produto`: catálogo de almoço, bebidas e sobremesas.
- `item_comanda`: registra cada consumo lançado em uma comanda.

O preço atual fica em `produto.valor_unitario`. O preço efetivamente cobrado
também é copiado para `item_comanda.valor_unitario`, preservando o histórico
caso o preço do produto seja alterado posteriormente.

O produto `ALMOÇO PESO` permite valor informado porque a balança já calcula o
valor do prato. Os demais produtos usam o preço cadastrado.

