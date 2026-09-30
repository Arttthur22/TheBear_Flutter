import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/pedido.dart';
import '../models/usuario.dart';

/// Service: única camada que conversa com o SQLite.
class BancoService {
  static const String _nomeBanco = 'the_bear.db';
  static const int _versaoBanco = 1;

  Database? _db;

  Future<Database> get _database async {
    if (_db != null) return _db!;
    final caminho = join(await getDatabasesPath(), _nomeBanco);
    _db = await openDatabase(
      caminho,
      version: _versaoBanco,
      onCreate: (db, versao) async {
        await db.execute('''
          CREATE TABLE usuarios (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nome TEXT NOT NULL,
            email TEXT NOT NULL UNIQUE,
            senha TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE pedidos (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            cliente TEXT NOT NULL,
            prato TEXT NOT NULL,
            quantidade INTEGER NOT NULL,
            valor_unitario REAL NOT NULL,
            total REAL NOT NULL,
            classificacao TEXT NOT NULL,
            status TEXT NOT NULL
          )
        ''');
      },
    );
    return _db!;
  }

  // ---------------------------------------------------------------- Usuários

  Future<bool> emailExiste(String email) async {
    final db = await _database;
    final r = await db.query('usuarios',
        columns: ['id'], where: 'email = ?', whereArgs: [email], limit: 1);
    return r.isNotEmpty;
  }

  Future<int> inserirUsuario(Usuario usuario) async {
    final db = await _database;
    return db.insert('usuarios', usuario.toMap());
  }

  /// Retorna o usuário se e-mail e senha conferem; caso contrário, null.
  Future<Usuario?> autenticar(String email, String senha) async {
    final db = await _database;
    final r = await db.query(
      'usuarios',
      where: 'email = ? AND senha = ?',
      whereArgs: [email, senha],
      limit: 1,
    );
    return r.isEmpty ? null : Usuario.fromMap(r.first);
  }

  // ----------------------------------------------------------------- Pedidos

  Future<int> inserirPedido(Pedido pedido) async {
    final db = await _database;
    return db.insert('pedidos', pedido.toMap());
  }

  Future<List<Pedido>> listarPedidos() async {
    final db = await _database;
    final r = await db.query('pedidos', orderBy: 'id DESC');
    return r.map(Pedido.fromMap).toList();
  }

  Future<int> atualizarStatus(int id, String status) async {
    final db = await _database;
    return db.update('pedidos', {'status': status},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<int> excluirPedido(int id) async {
    final db = await _database;
    return db.delete('pedidos', where: 'id = ?', whereArgs: [id]);
  }
}
