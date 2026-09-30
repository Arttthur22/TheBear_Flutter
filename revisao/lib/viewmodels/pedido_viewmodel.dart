import 'package:flutter/foundation.dart';

import '../models/pedido.dart';
import '../services/banco_service.dart';

/// ViewModel dos pedidos: mantém a lista em memória e sincroniza com o SQLite.
class PedidoViewModel extends ChangeNotifier {
  final BancoService _service;

  PedidoViewModel(this._service);

  List<Pedido> _pedidos = [];
  bool _carregando = false;
  String? _erro;

  List<Pedido> get pedidos => List.unmodifiable(_pedidos);
  bool get carregando => _carregando;
  String? get erro => _erro;

  Future<void> carregar() async {
    _carregando = true;
    _erro = null;
    notifyListeners();
    try {
      _pedidos = await _service.listarPedidos();
    } catch (_) {
      _erro = 'Não foi possível carregar os pedidos.';
    } finally {
      _carregando = false;
      notifyListeners();
    }
  }

  /// Valida os campos, cria o pedido (total, classificação e status são
  /// calculados no Model) e persiste. Retorna a mensagem de erro, ou null
  /// em caso de sucesso.
  Future<String?> adicionar({
    required String cliente,
    required String prato,
    required String quantidadeTexto,
    required String valorTexto,
  }) async {
    final quantidade = int.tryParse(quantidadeTexto.trim());
    final valor = parseValor(valorTexto);

    if (cliente.trim().isEmpty || prato.trim().isEmpty) {
      return 'Informe o cliente e o prato.';
    }
    if (quantidade == null || quantidade <= 0) {
      return 'Quantidade inválida.';
    }
    if (valor == null || valor <= 0) {
      return 'Valor unitário inválido.';
    }

    try {
      final pedido = Pedido.novo(
        cliente: cliente.trim(),
        prato: prato.trim(),
        quantidade: quantidade,
        valorUnitario: valor,
      );
      final id = await _service.inserirPedido(pedido);
      _pedidos = [
        Pedido(
          id: id,
          cliente: pedido.cliente,
          prato: pedido.prato,
          quantidade: pedido.quantidade,
          valorUnitario: pedido.valorUnitario,
          total: pedido.total,
          classificacao: pedido.classificacao,
          status: pedido.status,
        ),
        ..._pedidos,
      ];
      notifyListeners();
      return null;
    } catch (_) {
      return 'Erro ao salvar o pedido.';
    }
  }

  Future<void> finalizar(Pedido pedido) async {
    if (pedido.id == null || pedido.finalizado) return;
    try {
      await _service.atualizarStatus(pedido.id!, Pedido.statusFinalizado);
      _pedidos = [
        for (final p in _pedidos)
          p.id == pedido.id ? p.copyWith(status: Pedido.statusFinalizado) : p,
      ];
    } catch (_) {
      _erro = 'Não foi possível finalizar o pedido.';
    }
    notifyListeners();
  }

  Future<void> excluir(Pedido pedido) async {
    if (pedido.id == null) return;
    try {
      await _service.excluirPedido(pedido.id!);
      _pedidos = _pedidos.where((p) => p.id != pedido.id).toList();
    } catch (_) {
      _erro = 'Não foi possível excluir o pedido.';
    }
    notifyListeners();
  }

  void limpar() {
    _pedidos = [];
    _erro = null;
    notifyListeners();
  }

  // ------------------------------------------------ Apoio ao formulário (View)

  /// Converte "20", "20.5" ou "R$ 20,50" em double. Null se inválido.
  static double? parseValor(String texto) {
    final limpo = texto
        .replaceAll('R\$', '')
        .replaceAll(' ', '')
        .replaceAll(',', '.');
    return double.tryParse(limpo);
  }

  /// Prévia do total exibida enquanto o usuário digita.
  static String previaTotal(String quantidadeTexto, String valorTexto) {
    final q = int.tryParse(quantidadeTexto.trim());
    final v = parseValor(valorTexto);
    if (q == null || v == null) return Pedido.formatarMoeda(0);
    return Pedido.formatarMoeda(Pedido.calcularTotal(q, v));
  }

  /// Prévia da classificação exibida enquanto o usuário digita.
  static String previaClassificacao(String quantidadeTexto) {
    final q = int.tryParse(quantidadeTexto.trim());
    return q == null ? '—' : Pedido.classificar(q);
  }
}
