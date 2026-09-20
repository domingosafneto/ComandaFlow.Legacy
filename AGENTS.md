# Padrao de formatacao

- Use `ComandaFlow.Legacy/Dados.cs` como referencia de legibilidade.
- Use quatro espacos por nivel, sem tabulacoes, e respeite `.editorconfig`.
- Em C#, coloque chaves de namespaces, classes, metodos e blocos em linhas proprias (Allman); mantenha cada using, atributo, membro e instrucao em sua propria linha.
- Separe metodos e grupos logicos com linhas em branco. Quebre assinaturas e chamadas longas com indentacao de continuacao. Propriedades automaticas simples podem ficar em uma linha, uma propriedade por linha.
- Em markup, CSS, JavaScript, XML, SQL e PowerShell, mantenha estrutura expandida e indentacao consistente, respeitando a sintaxe da linguagem. Nao compacte codigo-fonte em uma unica linha.
- No DML, mantenha as colunas do INSERT na mesma linha e cada registro de VALUES em uma linha, alinhado.
- Nao reformate bibliotecas de terceiros ou arquivos minificados. Preserve comportamento, textos e valores ao fazer ajustes de formatacao.
- Nao acrescente quebra de linha ao final dos arquivos; mantenha insert_final_newline = false.