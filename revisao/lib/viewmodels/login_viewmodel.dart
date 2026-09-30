import 'package:flutter/foundation.dart';

import '../models/usuario.dart';
import '../services/banco_service.dart';

/// ViewModel de autenticação e cadastro de usuários.
class LoginViewModel extends ChangeNotifier {
  final BancoService _service;

  LoginViewModel(this._service);

  Usuario? _usuarioLogado;
  String? _erro;
  bool _carregando = false;

  Usuario? get usuarioLogado => _usuarioLogado;
  String? get erro => _erro;
  bool get carregando => _carregando;

  void limparErro() {
    if (_erro == null) return;
    _erro = null;
    notifyListeners();
  }

  /// Retorna true se as credenciais são válidas.
  Future<bool> login(String email, String senha) async {
    final emailNorm = email.trim().toLowerCase();
    if (emailNorm.isEmpty || senha.isEmpty) {
      _erro = 'Informe e-mail e senha.';
      notifyListeners();
      return false;
    }

    _carregando = true;
    _erro = null;
    notifyListeners();

    try {
      final usuario = await _service.autenticar(emailNorm, senha);
      if (usuario == null) {
        _erro = 'E-mail ou senha inválidos.';
        return false;
      }
      _usuarioLogado = usuario;
      return true;
    } catch (_) {
      _erro = 'Erro ao acessar o banco de dados.';
      return false;
    } finally {
      _carregando = false;
      notifyListeners();
    }
  }

  /// Retorna true se o cadastro foi concluído.
  Future<bool> cadastrar(String nome, String email, String senha) async {
    final nomeNorm = nome.trim();
    final emailNorm = email.trim().toLowerCase();

    if (nomeNorm.isEmpty || emailNorm.isEmpty || senha.isEmpty) {
      _erro = 'Preencha todos os campos.';
      notifyListeners();
      return false;
    }
    if (!emailNorm.contains('@') || !emailNorm.contains('.')) {
      _erro = 'Informe um e-mail válido.';
      notifyListeners();
      return false;
    }

    _carregando = true;
    _erro = null;
    notifyListeners();

    try {
      if (await _service.emailExiste(emailNorm)) {
        _erro = 'Este e-mail já está cadastrado.';
        return false;
      }
      await _service.inserirUsuario(
        Usuario(nome: nomeNorm, email: emailNorm, senha: senha),
      );
      return true;
    } catch (_) {
      _erro = 'Erro ao salvar o usuário.';
      return false;
    } finally {
      _carregando = false;
      notifyListeners();
    }
  }

  void logout() {
    _usuarioLogado = null;
    _erro = null;
    notifyListeners();
  }
}
