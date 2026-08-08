import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';

class ChatPage extends StatefulWidget {
  final ApiClient apiClient;
  const ChatPage({super.key, required this.apiClient});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  bool _loading = false;
  String? _sessionId;

  final List<String> _suggestions = [
    'Quelles universites me correspondent ?',
    'Quelles bourses puis-je obtenir ?',
    'Puis-je etudier au Maroc ?',
    'Quels programmes sont accessibles avec ma moyenne ?',
    'Quelle filiere choisir apres le bac ?',
  ];

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add({'role': 'user', 'content': text.trim()});
      _loading = true;
    });
    _messageController.clear();
    _scrollToBottom();

    try {
      // Utiliser smart query
      final response = await widget.apiClient.smartQuery(text.trim());
      final answer = response.data['answer'] ?? response.data['message'] ?? 'Je n\'ai pas trouve de reponse precise.';
      
      if (mounted) {
        setState(() {
          _messages.add({'role': 'assistant', 'content': answer});
          _loading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add({'role': 'assistant', 'content': 'Impossible de traiter votre question. Verifiez votre connexion.'});
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(gradient: AppTheme.primaryGradient, borderRadius: BorderRadius.circular(8)),
              child: Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 18),
            ),
            SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Assistant Orientia', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                Text('Intelligence artificielle', style: TextStyle(fontSize: 11, color: AppTheme.gray500)),
              ],
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Messages
          Expanded(
            child: _messages.isEmpty
                ? _buildWelcomeScreen()
                : ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.all(16),
                    itemCount: _messages.length + (_loading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length) return _buildTypingIndicator();
                      return _buildMessageBubble(_messages[index]);
                    },
                  ),
          ),
          // Input
          Container(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, -5))],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    onSubmitted: _sendMessage,
                    decoration: InputDecoration(
                      hintText: 'Posez votre question...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide(color: AppTheme.gray200)),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(22)),
                  child: IconButton(
                    icon: Icon(Icons.send_rounded, color: Colors.white, size: 20),
                    onPressed: () => _sendMessage(_messageController.text),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeScreen() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Column(
        children: [
          SizedBox(height: 40),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(gradient: AppTheme.primaryGradient, borderRadius: BorderRadius.circular(20)),
            child: Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 32),
          ),
          SizedBox(height: 20),
          Text('Comment puis-je vous aider ?', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.gray900)),
          SizedBox(height: 8),
          Text('Posez vos questions sur l\'orientation universitaire.', style: TextStyle(fontSize: 14, color: AppTheme.gray500)),
          SizedBox(height: 32),
          ..._suggestions.map((s) => _buildSuggestionChip(s)).toList(),
        ],
      ),
    );
  }

  Widget _buildSuggestionChip(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _sendMessage(text),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.gray200),
            ),
            child: Row(
              children: [
                Icon(Icons.chat_bubble_outline_rounded, size: 18, color: AppTheme.primary),
                SizedBox(width: 12),
                Expanded(child: Text(text, style: TextStyle(fontSize: 14, color: AppTheme.gray800))),
                Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppTheme.gray300),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final isUser = message['role'] == 'user';
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(gradient: AppTheme.primaryGradient, borderRadius: BorderRadius.circular(8)),
              child: Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 14),
            ),
            SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isUser ? AppTheme.primary : AppTheme.gray100,
                borderRadius: BorderRadius.circular(16).copyWith(
                  topLeft: isUser ? Radius.circular(16) : Radius.circular(4),
                  topRight: isUser ? Radius.circular(4) : Radius.circular(16),
                ),
              ),
              child: Text(
                message['content'] ?? '',
                style: TextStyle(
                  color: isUser ? Colors.white : AppTheme.gray800,
                  fontSize: 14,
                  height: 1.5,
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
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(gradient: AppTheme.primaryGradient, borderRadius: BorderRadius.circular(8)),
            child: Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 14),
          ),
          SizedBox(width: 8),
          Container(
            padding: EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppTheme.gray100, borderRadius: BorderRadius.circular(16)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.gray400)),
                SizedBox(width: 8),
                Text('En reflexion...', style: TextStyle(color: AppTheme.gray500, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
