# Parte II – Respostas Teóricas

**5. Conceito de MVVM e responsabilidade de cada camada**
MVVM (Model–View–ViewModel) separa a aplicação em três papéis para que interface, lógica de apresentação e dados não fiquem misturados.
- **Model:** representa os dados e as regras de negócio (ex.: `Pedido`, com o cálculo do total e a classificação NORMAL/GRANDE; `Usuario`).
- **View:** é a interface (widgets/páginas). Só desenha o estado atual e encaminha eventos do usuário (cliques, textos digitados). Não contém regra de negócio nem acesso a dados.
- **ViewModel:** intermediário entre View e Model. Guarda o estado da tela (lista de pedidos, mensagem de erro, "carregando"), expõe ações (`login`, `finalizar`, `excluir`) e avisa a View quando algo muda (`notifyListeners()`).

**6. Papel da camada Service (MVVM + SQLite)**
O Service encapsula o acesso à fonte de dados. No projeto, o `BancoService` é o único lugar que abre o banco, cria tabelas e executa `insert/query/update/delete`. A ViewModel pede "insira este pedido" sem saber como o SQL é feito; se o banco mudar (SQLite → API), só o Service é alterado.

**7. Por que não acessar o banco direto nos widgets**
- Mistura responsabilidades: a View passa a conhecer SQL, tabelas e colunas.
- Dificulta testes, pois não dá para testar a lógica sem renderizar widgets e ter um banco real.
- Gera duplicação de código entre telas.
- Torna a manutenção arriscada: qualquer mudança no banco quebra várias telas.
- Operações assíncronas dentro de `build`/callbacks podem causar erros de ciclo de vida (ex.: usar `context` após o widget ser removido).

**8. Função do Provider**
O Provider é um mecanismo de injeção de dependência e observação de estado. Ele disponibiliza uma instância da ViewModel para a árvore de widgets (`ChangeNotifierProvider`) e faz a View se reconstruir quando a ViewModel notifica mudança (`context.watch`, `Consumer`). Para apenas chamar ações sem reconstruir, usa-se `context.read`. Assim a View se comunica com a ViewModel sem criá-la nem passá-la manualmente de widget em widget.

**9. `ChangeNotifier` e `notifyListeners()`**
`ChangeNotifier` é uma classe que implementa o padrão Observer: mantém uma lista de "ouvintes". `notifyListeners()` avisa todos os ouvintes que o estado mudou. Com o Provider, isso faz os widgets que dependem daquela ViewModel serem reconstruídos com os novos dados.

**10. Alterar dados sem chamar `notifyListeners()`**
Os dados mudam na memória da ViewModel, mas a interface **não é reconstruída** e continua exibindo os valores antigos, até que algo force um rebuild por outro motivo (rotação de tela, outro `notifyListeners`, hot reload). É um erro comum de "tela desatualizada".

**11. O que é SQLite e vantagens**
SQLite é um banco de dados relacional embutido, em um único arquivo, sem servidor. Vantagens em apps móveis:
- Funciona offline e é local (rápido, sem latência de rede).
- Leve, sem configuração e já presente em Android e iOS.
- Usa SQL, com consultas, filtros, ordenação e integridade (chaves, `UNIQUE`, transações).
- Os dados persistem entre execuções do app.
- Gratuito e muito estável e testado.

**12. RAM (variáveis) × SQLite**
Dados em variáveis ficam na memória volátil: são rápidos, mas **perdidos** quando o app é fechado ou o processo é encerrado pelo sistema. No SQLite os dados são gravados em disco (armazenamento persistente) e sobrevivem a reinícios do app e do aparelho. Na prática, a memória serve como estado de tela e o SQLite como fonte durável da verdade.

**13. CRUD**
Acrônimo de quatro operações básicas sobre dados:
- **C**reate (criar): inserir um novo registro.
- **R**ead (ler): consultar/listar registros.
- **U**pdate (atualizar): modificar um registro existente.
- **D**elete (excluir): remover um registro.

**14. Comandos SQL**
- `INSERT`: adiciona novas linhas a uma tabela (`INSERT INTO pedidos (...) VALUES (...)`).
- `SELECT`: consulta e retorna dados (`SELECT * FROM pedidos`).
- `UPDATE`: altera dados existentes (`UPDATE pedidos SET status='Finalizado' WHERE id=1`).
- `DELETE`: remove linhas (`DELETE FROM pedidos WHERE id=1`).

**15. Fluxo View ➔ ViewModel ➔ Service ➔ SQLite ao cadastrar um registro**
1. **View:** o usuário preenche o formulário e toca em "Salvar". A View apenas lê os campos e chama `context.read<PedidoViewModel>().adicionar(...)`.
2. **ViewModel:** valida os dados, converte os textos em números, cria o `Pedido` (total, classificação e status "Pendente" via Model), chama o Service, atualiza a lista em memória e executa `notifyListeners()`.
3. **Service:** `BancoService.inserirPedido` converte o objeto em `Map` e executa `db.insert(...)`.
4. **SQLite:** grava a linha em disco e devolve o `id` gerado, que sobe de volta pelo Service e ViewModel; o Provider reconstrói a View e o novo card aparece.

**16. Dados somem ao reiniciar o app**
Causa provável: os dados estavam apenas em memória (listas/variáveis) e nunca foram gravados no SQLite. Outras causas técnicas: o `insert` não foi aguardado (`await`) ou falhou silenciosamente; o banco foi aberto em memória (`inMemoryDatabasePath`); o arquivo do banco é apagado/recriado a cada inicialização (`deleteDatabase` ou caminho diferente a cada execução).

**17. Registro alterado no SQLite, mas a tela mostra o valor antigo**
O banco foi atualizado, mas o estado da ViewModel não. Possíveis causas: (a) a lista em memória não foi atualizada ou recarregada após o `UPDATE`; (b) faltou chamar `notifyListeners()`; (c) a View usa `context.read` (que não escuta mudanças) em vez de `watch`/`Consumer`; (d) a View guarda uma cópia local dos dados (em `setState`/variável) em vez de ler da ViewModel; (e) o widget está sob outra instância de Provider, não a que foi alterada.

**18/19. Análise do código do botão**
```dart
onPressed: () async {
  await BancoService().inserirPedido(nomeController.text);
}
```
**Violação:** a View acessa diretamente a camada Service (e, por consequência, o SQLite), pulando a ViewModel. Isso quebra o fluxo `VIEW ➔ VIEWMODEL ➔ SERVICE ➔ SQLITE`. Além disso, cria uma nova instância de `BancoService` a cada clique, não valida dados, não atualiza a lista e não notifica a interface.

**Forma correta:**
```dart
// View
onPressed: () async {
  final erro = await context.read<PedidoViewModel>().adicionar(
    cliente: clienteController.text,
    prato: pratoController.text,
    quantidadeTexto: qtdController.text,
    valorTexto: valorController.text,
  );
  if (!mounted) return;
  if (erro == null) Navigator.pop(context);
}

// ViewModel
Future<String?> adicionar({...}) async {
  // valida, cria o Pedido, chama _service.inserirPedido(pedido),
  // atualiza a lista e chama notifyListeners()
}
```
O `BancoService` é injetado na ViewModel (via `Provider`), e só a ViewModel o utiliza.

**Última questão – Benefícios da separação View / ViewModel / Model / Service**
- **Manutenção:** cada camada tem uma responsabilidade; mudanças ficam localizadas (trocar o visual não afeta a lógica; trocar o banco só afeta o Service). O código fica mais legível e com menos duplicação.
- **Testabilidade:** ViewModels e Models são classes Dart puras, testáveis sem interface; o Service pode ser substituído por um *mock*/*fake*, permitindo testes rápidos e isolados das regras (ex.: total e classificação).
- **Escalabilidade:** novas telas, funcionalidades e fontes de dados (API, cache) são adicionadas sem reescrever o que já existe; equipes podem trabalhar em paralelo em camadas diferentes; o crescimento do projeto continua organizado.
