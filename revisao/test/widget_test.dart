import 'package:flutter_test/flutter_test.dart';
import 'package:revisao/models/pedido.dart';
import 'package:revisao/viewmodels/pedido_viewmodel.dart';

void main() {
  group('Regras de negócio do Pedido', () {
    test('calcula o total: 2 x 25,00 = R\$ 50,00 (PEDIDO NORMAL)', () {
      final p = Pedido.novo(
          cliente: 'Richie',
          prato: 'Sanduíche Italiano',
          quantidade: 2,
          valorUnitario: 25);
      expect(p.total, 50);
      expect(p.totalFormatado, 'R\$ 50,00');
      expect(p.classificacao, Pedido.classificacaoNormal);
      expect(p.status, Pedido.statusPendente);
    });

    test('quantidade 6 x 20,00 = R\$ 120,00 (PEDIDO GRANDE)', () {
      final p = Pedido.novo(
          cliente: 'Richie', prato: 'Massa', quantidade: 6, valorUnitario: 20);
      expect(p.totalFormatado, 'R\$ 120,00');
      expect(p.classificacao, Pedido.classificacaoGrande);
    });

    test('limite: 4 é normal, 5 é grande', () {
      expect(Pedido.classificar(4), Pedido.classificacaoNormal);
      expect(Pedido.classificar(5), Pedido.classificacaoGrande);
    });

    test('formata milhares', () {
      expect(Pedido.formatarMoeda(1250.5), 'R\$ 1.250,50');
    });

    test('parse de valor aceita vírgula', () {
      expect(PedidoViewModel.parseValor('20,50'), 20.5);
      expect(PedidoViewModel.parseValor('abc'), isNull);
    });
  });
}
