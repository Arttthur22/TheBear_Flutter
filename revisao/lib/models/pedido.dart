/// Model: representa um pedido da cozinha.
class Pedido {
  static const String statusPendente = 'Pendente';
  static const String statusFinalizado = 'Finalizado';

  static const String classificacaoNormal = 'PEDIDO NORMAL';
  static const String classificacaoGrande = 'PEDIDO GRANDE';

  /// Limite a partir do qual o pedido é considerado grande.
  static const int limitePedidoGrande = 5;

  final int? id;
  final String cliente;
  final String prato;
  final int quantidade;
  final double valorUnitario;
  final double total;
  final String classificacao;
  final String status;

  const Pedido({
    this.id,
    required this.cliente,
    required this.prato,
    required this.quantidade,
    required this.valorUnitario,
    required this.total,
    required this.classificacao,
    required this.status,
  });

  /// Cria um novo pedido aplicando as regras de negócio:
  /// total = quantidade × valor_unitario, classificação por quantidade
  /// e status inicial "Pendente".
  factory Pedido.novo({
    required String cliente,
    required String prato,
    required int quantidade,
    required double valorUnitario,
  }) {
    return Pedido(
      cliente: cliente,
      prato: prato,
      quantidade: quantidade,
      valorUnitario: valorUnitario,
      total: calcularTotal(quantidade, valorUnitario),
      classificacao: classificar(quantidade),
      status: statusPendente,
    );
  }

  static double calcularTotal(int quantidade, double valorUnitario) =>
      quantidade * valorUnitario;

  static String classificar(int quantidade) =>
      quantidade >= limitePedidoGrande
          ? classificacaoGrande
          : classificacaoNormal;

  bool get finalizado => status == statusFinalizado;

  Pedido copyWith({String? status}) => Pedido(
        id: id,
        cliente: cliente,
        prato: prato,
        quantidade: quantidade,
        valorUnitario: valorUnitario,
        total: total,
        classificacao: classificacao,
        status: status ?? this.status,
      );

  /// Formata um valor como moeda brasileira, ex.: 1250.5 -> "R$ 1.250,50".
  static String formatarMoeda(double valor) {
    final partes = valor.toStringAsFixed(2).split('.');
    final inteiro = partes[0];
    final buffer = StringBuffer();
    for (var i = 0; i < inteiro.length; i++) {
      final restantes = inteiro.length - i;
      buffer.write(inteiro[i]);
      if (restantes > 1 && restantes % 3 == 1 && inteiro[i] != '-') {
        buffer.write('.');
      }
    }
    return 'R\$ ${buffer.toString()},${partes[1]}';
  }

  String get totalFormatado => formatarMoeda(total);

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'cliente': cliente,
        'prato': prato,
        'quantidade': quantidade,
        'valor_unitario': valorUnitario,
        'total': total,
        'classificacao': classificacao,
        'status': status,
      };

  factory Pedido.fromMap(Map<String, dynamic> map) => Pedido(
        id: map['id'] as int?,
        cliente: map['cliente'] as String,
        prato: map['prato'] as String,
        quantidade: map['quantidade'] as int,
        valorUnitario: (map['valor_unitario'] as num).toDouble(),
        total: (map['total'] as num).toDouble(),
        classificacao: map['classificacao'] as String,
        status: map['status'] as String,
      );
}
