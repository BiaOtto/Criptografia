import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

void main() {
  runApp(const CofreApp());
}

class CofreApp extends StatelessWidget {
  const CofreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cofrinho de Recados',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color.fromARGB(255, 250, 250, 250), // Cor preta para o tema
        scaffoldBackgroundColor: const Color.fromARGB(255, 255, 255, 255), // Cor de fundo preta
        appBarTheme: AppBarTheme(
          backgroundColor: const Color.fromARGB(255, 255, 255, 255), // Cor preta para a AppBar
        ),
        textTheme: TextTheme(
          bodyLarge: TextStyle(color: const Color.fromARGB(255, 0, 0, 0)), // Texto branco
          bodyMedium: TextStyle(color: const Color.fromARGB(255, 0, 0, 0)),
        ),
      ),
      home: const CofrePage(),
    );
  }
}

class CofrePage extends StatefulWidget {
  const CofrePage({super.key});

  @override
  State<CofrePage> createState() => _CofrePageState();
}

class _CofrePageState extends State<CofrePage> {
  final TextEditingController _controller = TextEditingController();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  final _key = encrypt.Key.fromUtf8('1234567890123456'); // 16 chars
  final _iv = encrypt.IV.fromLength(16);
  late final encrypt.Encrypter _encrypter;

  String? _recadoCriptografado;
  String? _recadoDescriptografado;
  String? _dataDeCriacao;
  String? _emocaoSelecionada;

  @override
  void initState() {
    super.initState();
    _encrypter = encrypt.Encrypter(encrypt.AES(_key));
  }

  String _criptografar(String texto) {
    final encrypted = _encrypter.encrypt(texto, iv: _iv);
    return encrypted.base64;
  }

  String _descriptografar(String texto) {
    return _encrypter.decrypt64(texto, iv: _iv);
  }

  Future<void> _salvarRecado() async {
    final texto = _controller.text;
    if (texto.isEmpty) return;

    final criptografado = _criptografar(texto);
    final dataDeCriacao = DateTime.now().toString(); // Captura a data e hora atual

    await _secureStorage.write(key: 'recado', value: criptografado);
    await _secureStorage.write(key: 'data', value: dataDeCriacao);
    await _secureStorage.write(key: 'emocao', value: _emocaoSelecionada ?? '😶'); // Definir emoção selecionada ou padrão

    setState(() {
      _recadoCriptografado = criptografado;
      _recadoDescriptografado = null;
      _dataDeCriacao = dataDeCriacao;
    });

    _controller.clear();
  }

  Future<void> _lerRecado() async {
    final criptografado = await _secureStorage.read(key: 'recado');
    if (criptografado == null) return;

    final textoOriginal = _descriptografar(criptografado);

    final dataDeCriacao = await _secureStorage.read(key: 'data');
    final emocao = await _secureStorage.read(key: 'emocao');

    setState(() {
      _recadoCriptografado = criptografado;
      _recadoDescriptografado = textoOriginal;
      _dataDeCriacao = dataDeCriacao;
      _emocaoSelecionada = emocao;
    });
  }

  Future<void> _apagarRecado() async {
    await _secureStorage.delete(key: 'recado');
    await _secureStorage.delete(key: 'data');
    await _secureStorage.delete(key: 'emocao');

    setState(() {
      _recadoCriptografado = null;
      _recadoDescriptografado = null;
      _dataDeCriacao = null;
      _emocaoSelecionada = null;
    });
  }

  Future<void> _recriptografar() async {
    if (_recadoDescriptografado != null) {
      final recriptografado = _criptografar(_recadoDescriptografado!);
      await _secureStorage.write(key: 'recado', value: recriptografado);

      setState(() {
        _recadoCriptografado = recriptografado;
        _recadoDescriptografado = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('🔐 Cofrinho de Recados')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Digite seu recado secreto',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton.icon(
                  onPressed: _salvarRecado,
                  icon: const Icon(Icons.lock),
                  label: const Text('Salvar'),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color.fromARGB(255, 166, 234, 255)),
                ),
                ElevatedButton.icon(
                  onPressed: _lerRecado,
                  icon: const Icon(Icons.lock_open),
                  label: const Text('Mostrar'),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color.fromARGB(255, 171, 255, 169)),
                ),
                ElevatedButton.icon(
                  onPressed: _apagarRecado,
                  icon: const Icon(Icons.delete),
                  label: const Text('Apagar'),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color.fromARGB(255, 255, 164, 158)),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (_recadoCriptografado != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🔒 Recado criptografado:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(_recadoCriptografado!),
                  const SizedBox(height: 16),
                  if (_dataDeCriacao != null)
                    Text('📅 Data de criação: $_dataDeCriacao'),
                  if (_emocaoSelecionada != null)
                    Text('Emoção do recado: $_emocaoSelecionada'),
                ],
              ),
            if (_recadoDescriptografado != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🔓 Recado original:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(_recadoDescriptografado!),
                ],
              ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildEmojiButton('😄', 'Feliz'),
                _buildEmojiButton('😢', 'Triste'),
                _buildEmojiButton('😠', 'Bravo'),
              ],
            ),
            const SizedBox(height: 16),
            // Novo botão para re-criptografar o recado
            if (_recadoDescriptografado != null)
              ElevatedButton.icon(
                onPressed: _recriptografar,
                icon: const Icon(Icons.lock),
                label: const Text('Re-criptografar'),
                style: ElevatedButton.styleFrom(backgroundColor: const Color.fromARGB(255, 255, 254, 166)),
              ),
          ],
        ),
      ),
    );
  }

  ElevatedButton _buildEmojiButton(String emoji, String label) {
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _emocaoSelecionada = emoji;
        });
      },
      child: Text(emoji, style: const TextStyle(fontSize: 24)),
    );
  }
}
