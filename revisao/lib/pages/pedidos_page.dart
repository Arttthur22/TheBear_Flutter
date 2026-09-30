import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/pedido.dart';
import '../viewmodels/login_viewmodel.dart';
import '../viewmodels/pedido_viewmodel.dart';
import 'login_page.dart';

class PedidosPage extends StatefulWidget {
  const PedidosPage({super.key});

  @override
  State<PedidosPage> createState() => _PedidosPageState();
}

class _PedidosPageState extends State<PedidosPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PedidoViewModel>().carregar();
    });
  }

  void _sair() {
    context.read<PedidoViewModel>().limpar();
    context.read<LoginViewModel>().logout();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  void _abrirFormulario() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _NovoPedidoForm(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PedidoViewModel>();
    final usuario = context.watch<LoginViewModel>().usuarioLogado;

    return Scaffold(
      appBar: AppBar(
        title: Text(usuario == null ? 'Pedidos' : 'Pedidos • ${usuario.nome}'),
        actions: [
          IconButton(
            tooltip: 'Sair',
            icon: const Icon(Icons.logout),
            onPressed: _sair,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirFormulario,
        icon: const Icon(Icons.add),
        label: const Text('Novo pedido'),
      ),
      body: Builder(builder: (_) {
        if (vm.carregando && vm.pedidos.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (vm.pedidos.isEmpty) {
          return const Center(child: Text('Nenhum pedido registrado.'));
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
          itemCount: vm.pedidos.length,
          itemBuilder: (_, i) => _PedidoCard(pedido: vm.pedidos[i]),
        );
      }),
    );
  }
}

class _PedidoCard extends StatelessWidget {
  final Pedido pedido;

  const _PedidoCard({required this.pedido});

  @override
  Widget build(BuildContext context) {
    final vm = context.read<PedidoViewModel>();
    final grande = pedido.classificacao == Pedido.classificacaoGrande;
    final cores = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cliente: ${pedido.cliente} | Prato: ${pedido.prato}',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('Quantidade: ${pedido.quantidade} | '
                'Total: ${pedido.totalFormatado}'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                Chip(
                  label: Text(pedido.classificacao),
                  backgroundColor:
                      grande ? cores.errorContainer : cores.surfaceContainerHighest,
                ),
                Chip(
                  label: Text('Status: ${pedido.status}'),
                  backgroundColor: pedido.finalizado
                      ? Colors.green.shade100
                      : Colors.amber.shade100,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed:
                      pedido.finalizado ? null : () => vm.finalizar(pedido),
                  child: const Text('FINALIZAR'),
                ),
                TextButton(
                  style: TextButton.styleFrom(foregroundColor: cores.error),
                  onPressed: () => vm.excluir(pedido),
                  child: const Text('EXCLUIR'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NovoPedidoForm extends StatefulWidget {
  const _NovoPedidoForm();

  @override
  State<_NovoPedidoForm> createState() => _NovoPedidoFormState();
}

class _NovoPedidoFormState extends State<_NovoPedidoForm> {
  final _clienteController = TextEditingController();
  final _pratoController = TextEditingController();
  final _quantidadeController = TextEditingController();
  final _valorController = TextEditingController();
  String? _erro;

  @override
  void dispose() {
    _clienteController.dispose();
    _pratoController.dispose();
    _quantidadeController.dispose();
    _valorController.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    final erro = await context.read<PedidoViewModel>().adicionar(
          cliente: _clienteController.text,
          prato: _pratoController.text,
          quantidadeTexto: _quantidadeController.text,
          valorTexto: _valorController.text,
        );
    if (!mounted) return;
    if (erro != null) {
      setState(() => _erro = erro);
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 0, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Novo pedido',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(
              controller: _clienteController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                  labelText: 'Cliente', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _pratoController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                  labelText: 'Prato', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _quantidadeController,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                        labelText: 'Quantidade',
                        border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _valorController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                        labelText: 'Valor unitário',
                        prefixText: 'R\$ ',
                        border: OutlineInputBorder()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Total: ${PedidoViewModel.previaTotal(_quantidadeController.text, _valorController.text)}'
              '  •  ${PedidoViewModel.previaClassificacao(_quantidadeController.text)}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const Text('Status inicial: Pendente'),
            if (_erro != null) ...[
              const SizedBox(height: 8),
              Text(_erro!,
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height: 16),
            FilledButton(onPressed: _salvar, child: const Text('Salvar pedido')),
          ],
        ),
      ),
    );
  }
}
