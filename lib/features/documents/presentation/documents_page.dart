import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import 'package:file_picker/file_picker.dart';

class DocumentsPage extends StatefulWidget {
  final ApiClient apiClient;
  const DocumentsPage({super.key, required this.apiClient});

  @override
  State<DocumentsPage> createState() => _DocumentsPageState();
}

class _DocumentsPageState extends State<DocumentsPage> {
  List<dynamic> _documents = [];
  bool _loading = true;
  bool _uploading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    setState(() { _loading = true; _error = null; });
    try {
      final response = await widget.apiClient.getDocuments();
      if (mounted) setState(() { _documents = response.data['content'] ?? []; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = 'Impossible de charger les documents.'; _loading = false; });
    }
  }

  Future<void> _pickAndUpload() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );
      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      setState(() => _uploading = true);

      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(file.bytes!, filename: file.name),
      });

      await widget.apiClient.uploadDocument(formData);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Document envoye avec succes'), backgroundColor: AppTheme.success),
        );
        _loadDocuments();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de l\'envoi'), backgroundColor: AppTheme.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mes documents'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : RefreshIndicator(
              onRefresh: _loadDocuments,
              child: SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Upload card
                    GestureDetector(
                      onTap: _uploading ? null : _pickAndUpload,
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            _uploading
                                ? CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                                : Icon(Icons.cloud_upload_rounded, color: Colors.white, size: 40),
                            SizedBox(height: 12),
                            Text(
                              _uploading ? 'Envoi en cours...' : 'Importer un document',
                              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Bulletin, releve de notes, diplome (PDF, JPG, PNG)',
                              style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 24),
                    
                    // Pipeline info
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.infoSurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.info.withOpacity(0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Icon(Icons.auto_awesome_rounded, color: AppTheme.info, size: 18),
                            SizedBox(width: 8),
                            Text('Analyse intelligente', style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.gray900)),
                          ]),
                          SizedBox(height: 8),
                          Text(
                            'Vos documents sont analyses automatiquement : OCR, extraction des notes, detection des matieres, construction du profil academique.',
                            style: TextStyle(fontSize: 12, color: AppTheme.gray600, height: 1.5),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24),
                    
                    // Documents list
                    Text('${_documents.length} documents', style: Theme.of(context).textTheme.titleMedium),
                    SizedBox(height: 12),
                    
                    if (_documents.isEmpty)
                      _buildEmptyState()
                    else
                      ..._documents.map((doc) => _buildDocumentCard(doc)).toList(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildDocumentCard(dynamic doc) {
    final name = doc['fileName'] ?? doc['name'] ?? 'Document';
    final status = doc['status'] ?? 'UPLOADED';
    final type = doc['documentType'] ?? doc['type'] ?? 'Document';
    final date = doc['createdAt'] ?? '';
    
    Color statusColor;
    String statusText;
    IconData statusIcon;
    
    switch (status) {
      case 'ANALYZED':
      case 'COMPLETED':
        statusColor = AppTheme.success;
        statusText = 'Analyse terminee';
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'PROCESSING':
      case 'ANALYZING':
        statusColor = AppTheme.info;
        statusText = 'Analyse en cours...';
        statusIcon = Icons.hourglass_top_rounded;
        break;
      case 'ERROR':
        statusColor = AppTheme.danger;
        statusText = 'Erreur d\'analyse';
        statusIcon = Icons.error_rounded;
        break;
      default:
        statusColor = AppTheme.warning;
        statusText = 'En attente';
        statusIcon = Icons.schedule_rounded;
    }

    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showDocumentDetail(doc),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.gray200),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.description_rounded, color: statusColor, size: 22),
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.gray900)),
                      SizedBox(height: 4),
                      Row(children: [
                        Icon(statusIcon, size: 14, color: statusColor),
                        SizedBox(width: 4),
                        Text(statusText, style: TextStyle(fontSize: 12, color: statusColor, fontWeight: FontWeight.w500)),
                      ]),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.gray300),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDocumentDetail(dynamic doc) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (ctx, scrollController) => Padding(
          padding: EdgeInsets.all(24),
          child: ListView(
            controller: scrollController,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.gray300, borderRadius: BorderRadius.circular(2)))),
              SizedBox(height: 20),
              Text(doc['fileName'] ?? 'Document', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              SizedBox(height: 16),
              _buildDetailRow('Type', doc['documentType'] ?? 'Document'),
              _buildDetailRow('Statut', doc['status'] ?? 'Inconnu'),
              _buildDetailRow('Date', doc['createdAt'] ?? ''),
              if (doc['extractedText'] != null) ...[
                SizedBox(height: 16),
                Text('Texte extrait', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppTheme.gray100, borderRadius: BorderRadius.circular(8)),
                  child: Text(doc['extractedText'], style: TextStyle(fontSize: 13, color: AppTheme.gray700, height: 1.5)),
                ),
              ],
              SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('Fermer'),
                  style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text(label, style: TextStyle(fontSize: 13, color: AppTheme.gray500))),
          Expanded(child: Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.gray800))),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(32),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.gray200)),
      child: Column(
        children: [
          Icon(Icons.folder_open_rounded, size: 48, color: AppTheme.gray400),
          SizedBox(height: 12),
          Text('Aucun document', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.gray700)),
          SizedBox(height: 8),
          Text('Importez votre premier bulletin ou releve de notes pour commencer l\'analyse.', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: AppTheme.gray500, height: 1.5)),
        ],
      ),
    );
  }
}
