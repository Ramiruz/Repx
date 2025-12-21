import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../utils/app_colors.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

/// Pantalla de Chatbot - Asistente virtual de entrenamiento conectado a n8n
class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen>
    with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;

  // Configuración del webhook n8n (PRODUCCIÓN)
  static const String _webhookUrl =
      'https://n8n-practica.jesus-martinez.me/webhook/entrenador';
  late String _sessionId;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Generar sessionId único para esta conversación
    _sessionId = const Uuid().v4().replaceAll('-', '');

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Mensaje de bienvenida - se carga después para tener contexto
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!mounted) return;
        final l10n = AppLocalizations.of(context)!;
        final locale = l10n.localeName;

        final welcomeMessage = locale == 'es'
            ? '¡Hola! 👋 Soy tu entrenador personal con IA.\n\n'
                'Puedo ayudarte con:\n'
                '• Crear rutinas personalizadas\n'
                '• Evaluar tu nivel de entrenamiento\n'
                '• Técnicas de ejercicios\n'
                '• Consejos de nutrición y recuperación\n\n'
                'Para empezar, cuéntame: ¿Cuántas dominadas y flexiones puedes hacer?'
            : 'Hello! 👋 I\'m your AI personal trainer.\n\n'
                'I can help you with:\n'
                '• Creating personalized routines\n'
                '• Assessing your training level\n'
                '• Exercise techniques\n'
                '• Nutrition and recovery tips\n\n'
                'To get started, tell me: How many pull-ups and push-ups can you do?';

        _addBotMessage(welcomeMessage);
      });
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _addBotMessage(String text) {
    setState(() {
      _isTyping = true;
    });

    // Simular tiempo de escritura
    Future.delayed(
        Duration(milliseconds: 800 + (text.length * 10).clamp(0, 1500)), () {
      if (!mounted) return;
      setState(() {
        _isTyping = false;
        _messages.add(ChatMessage(text: text, isUser: false));
      });
      _scrollToBottom();
    });
  }

  void _handleSubmit(String text) {
    if (text.trim().isEmpty) return;

    _messageController.clear();
    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
    });
    _scrollToBottom();

    // Enviar mensaje al webhook de n8n
    _sendMessageToN8N(text);
  }

  /// Envía el mensaje al webhook de n8n y procesa la respuesta
  Future<void> _sendMessageToN8N(String message) async {
    setState(() {
      _isTyping = true;
    });

    try {
      final response = await http.post(
        Uri.parse(_webhookUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'sessionId': _sessionId,
          'action': 'sendMessage',
          'chatInput': message,
        }),
      );

      if (!mounted) return;

      // Debug: imprimir respuesta cruda
      debugPrint('=== N8N Response ===');
      debugPrint('Status: ${response.statusCode}');
      debugPrint('Body: ${response.body}');
      debugPrint('====================');

      if (response.statusCode == 200) {
        final responseBody = response.body.trim();

        // Verificar si la respuesta está vacía
        if (responseBody.isEmpty) {
          setState(() {
            _isTyping = false;
            _messages.add(ChatMessage(
              text: '⚠️ El servidor respondió pero sin contenido.',
              isUser: false,
            ));
          });
          return;
        }

        // Intentar parsear JSON
        dynamic data;
        try {
          data = jsonDecode(responseBody);
        } catch (jsonError) {
          // Si no es JSON válido, mostrar la respuesta como texto
          setState(() {
            _isTyping = false;
            _messages.add(ChatMessage(text: responseBody, isUser: false));
          });
          return;
        }

        // El webhook de n8n puede devolver:
        // 1. Array: [{"output": "mensaje"}]
        // 2. Objeto: {"message": "mensaje"} o {"output": "mensaje"}
        String botMessage;

        if (data is List && data.isNotEmpty) {
          // Respuesta es un array
          botMessage =
              data[0]['output'] ?? data[0]['message'] ?? 'Sin respuesta';
        } else if (data is Map) {
          // Respuesta es un objeto
          botMessage = data['output'] ?? data['message'] ?? 'Sin respuesta';
        } else {
          botMessage = 'Formato de respuesta no reconocido';
        }

        setState(() {
          _isTyping = false;
          _messages.add(ChatMessage(text: botMessage, isUser: false));
        });
      } else {
        final l10n = AppLocalizations.of(context)!;
        setState(() {
          _isTyping = false;
          _messages.add(ChatMessage(
            text: '⚠️ ${l10n.connectionError}',
            isUser: false,
          ));
        });
      }
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      setState(() {
        _isTyping = false;
        _messages.add(ChatMessage(
          text: '⚠️ ${l10n.connectionError}\n\nDetalles: ${e.toString()}',
          isUser: false,
        ));
      });
    }

    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topLeft,
            radius: 1.8,
            colors: [
              AppColors.primaryCyan.withOpacity(0.06),
              AppColors.darkBg,
              AppColors.darkBg,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(child: _buildMessageList()),
              if (_isTyping) _buildTypingIndicator(),
              _buildInputArea(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBg.withOpacity(0.3),
        border: Border(
          bottom: BorderSide(
            color: AppColors.primaryCyan.withOpacity(0.15),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            color: Colors.white,
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primaryCyan.withOpacity(0.8),
                        AppColors.primaryPurple.withOpacity(0.6),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryCyan.withOpacity(0.3),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.smart_toy_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'FitBot',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: AppColors.successGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Online • Asistente IA',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    if (_messages.isEmpty && !_isTyping) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              size: 64,
              color: AppColors.primaryCyan.withOpacity(0.2),
            ),
            const SizedBox(height: 16),
            Text(
              'Iniciando conversación...',
              style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        return _buildMessageBubble(message);
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.isUser;

    return Padding(
      padding: EdgeInsets.only(
        bottom: 12,
        left: isUser ? 48 : 0,
        right: isUser ? 0 : 48,
      ),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryCyan.withOpacity(0.7),
                    AppColors.primaryPurple.withOpacity(0.5),
                  ],
                ),
              ),
              child: const Icon(
                Icons.smart_toy_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser
                    ? AppColors.primaryCyan.withOpacity(0.2)
                    : AppColors.cardBg.withOpacity(0.5),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 18),
                ),
                border: Border.all(
                  color: isUser
                      ? AppColors.primaryCyan.withOpacity(0.3)
                      : Colors.white.withOpacity(0.08),
                  width: 1,
                ),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryCyan.withOpacity(0.7),
                  AppColors.primaryPurple.withOpacity(0.5),
                ],
              ),
            ),
            child: const Icon(
              Icons.smart_toy_rounded,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.cardBg.withOpacity(0.5),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.white.withOpacity(0.08),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (index) {
                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: Duration(milliseconds: 600 + (index * 200)),
                  builder: (context, value, child) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.primaryCyan
                            .withOpacity(0.3 + (value * 0.5)),
                        shape: BoxShape.circle,
                      ),
                    );
                  },
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg.withOpacity(0.3),
        border: Border(
          top: BorderSide(
            color: AppColors.primaryCyan.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.darkBg.withOpacity(0.6),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Builder(
                builder: (context) {
                  final l10n = AppLocalizations.of(context)!;
                  return TextField(
                    controller: _messageController,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: l10n.typeMessage,
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.35),
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                    ),
                    onSubmitted: _handleSubmit,
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => _handleSubmit(_messageController.text),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primaryCyan,
                    AppColors.primaryPurple.withOpacity(0.8),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryCyan.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Modelo de mensaje de chat
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}
