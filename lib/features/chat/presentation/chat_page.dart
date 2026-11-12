import '../../../core/widgets/business_scaffold.dart';
import 'package:flutter/material.dart';
import '../../../core/data/orientation_repository.dart';
import '../../../core/models/academic_models.dart';
import '../../../core/network/api_client.dart';
import '../../../core/widgets/academic_widgets.dart';
import '../../decisions/presentation/decision_page.dart';
import '../../catalog/presentation/catalog_page.dart';

class ChatPage extends StatefulWidget {
  final ApiClient apiClient;
  const ChatPage({super.key, required this.apiClient});
  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late final repo = OrientationRepository(widget.apiClient);
  final message = TextEditingController(), average = TextEditingController();
  final scroll = ScrollController();
  String? session, recommendation;
  String intent = 'FREE';
  Set<String> selectedPrograms = {};
  List<Json> sessions = [], messages = [], programs = [], recommendations = [];
  int sessionPage = 0, messagePage = 0, generation = 0;
  bool busy = false, sessionNext = false, messageNext = false;
  Object? error;
  @override
  void initState() {
    super.initState();
    loadSessions();
  }

  @override
  void dispose() {
    message.dispose();
    average.dispose();
    scroll.dispose();
    super.dispose();
  }

  Future<void> loadSessions() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final response = object((await widget.apiClient.call('/ai/chat/sessions',
              query: {'page': sessionPage, 'size': 20}))
          .data);
      if (mounted) {
        setState(() {
          sessions = objects(response['content']);
          sessionNext = response['last'] == false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => error = e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> create() async {
    if (busy) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final data = object((await widget.apiClient.createChatSession()).data);
      if (mounted) {
        setState(() {
          session = data['sessionId'] as String;
          messages = [];
          messagePage = 0;
          generation++;
          recommendation = null;
          selectedPrograms.clear();
          average.clear();
          intent = 'FREE';
          message.clear();
          sessionPage = 0;
        });
        await loadSessions();
        if (mounted) await loadMessages(latest: true);
      }
    } catch (e) {
      if (mounted) setState(() => error = e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> loadMessages({bool latest = false}) async {
    final id = session, request = ++generation;
    if (id == null) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      var data = object((await widget.apiClient.call(
              '/ai/chat/sessions/$id/messages',
              query: {'page': latest ? 0 : messagePage, 'size': 20}))
          .data);
      var targetPage = latest
          ? ((data['totalPages'] as num?)?.toInt() ?? 1) - 1
          : messagePage;
      if (targetPage < 0) targetPage = 0;
      if (latest && targetPage > 0) {
        data = object((await widget.apiClient.call(
                '/ai/chat/sessions/$id/messages',
                query: {'page': targetPage, 'size': 20}))
            .data);
      }
      if (mounted && request == generation) {
        setState(() {
          messages = objects(data['content'])
              .map((j) => {...object(j['result']), 'id': j['id']})
              .toList();
          messagePage = targetPage;
          messageNext = data['last'] == false;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && request == generation && scroll.hasClients) {
            scroll.jumpTo(latest ? scroll.position.maxScrollExtent : 0);
          }
        });
      }
    } catch (e) {
      if (mounted && request == generation) setState(() => error = e);
    } finally {
      if (mounted && request == generation) setState(() => busy = false);
    }
  }

  Future<void> parameters() async {
    try {
      final p = await repo.catalog('programs');
      final r = await repo.recommendations();
      if (mounted) {
        setState(() {
          programs = [for (final item in p.content) item.fields];
          recommendations = [
            for (final item in r.content) {'id': item.id, 'name': item.name}
          ];
        });
      }
    } catch (e) {
      if (mounted) setState(() => error = e);
    }
  }

  Future<void> send() async {
    if (busy || session == null || message.text.trim().isEmpty) return;
    final id = session, request = ++generation;
    final question = message.text.trim();
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final params = <String, dynamic>{
        if (selectedPrograms.isNotEmpty)
          'programIds': selectedPrograms.toList(),
        if (recommendation != null) 'recommendationId': recommendation,
      };
      if (intent == 'SIMULATION') {
        final n = double.tryParse(average.text.trim().replaceAll(',', '.'));
        if (n == null || !n.isFinite) {
          throw const FormatException('Moyenne explicite requise');
        }
        params['simulation'] = {'modifiedGeneralAverage': n};
      }
      object((await widget.apiClient
              .sendChatMessage(id!, question, parameters: params))
          .data);
      if (mounted && request == generation && id == session) {
        setState(() {
          message.clear();
        });
        await loadMessages(latest: true);
      }
    } catch (e) {
      if (mounted && request == generation) setState(() => error = e);
    } finally {
      if (mounted && request == generation) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => BusinessScaffold(
      appBar: AppBar(title: const Text('Assistant Orientia'), actions: [
        IconButton(
            onPressed: busy ? null : create,
            icon: const Icon(Icons.add_comment_outlined),
            tooltip: 'Nouvelle conversation')
      ]),
      body: Column(children: [
        if (busy) const LinearProgressIndicator(),
        if (error != null)
          ErrorNotice(error!,
              onRetry: busy
                  ? null
                  : () {
                      session == null
                          ? loadSessions()
                          : loadMessages(latest: true);
                    }),
        Expanded(
            child: ListView(
                controller: scroll,
                padding: const EdgeInsets.all(12),
                children: [
              const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Notice(
                      'Des réponses à partir de votre dossier et des sources disponibles. Aucune admission ni bourse garantie.')),
              ExpansionTile(
                  title: const Text('Reprendre une conversation'),
                  children: [
                    if (!busy && sessions.isEmpty)
                      const ListTile(
                          title: Text('Aucune conversation enregistrée.')),
                    for (final s in sessions)
                      ListTile(
                          title:
                              Text('Conversation du ${text(s['computedAt'])}'),
                          onTap: busy
                              ? null
                              : () {
                                  setState(() {
                                    session = s['id'] as String;
                                    recommendation = null;
                                    selectedPrograms.clear();
                                    average.clear();
                                    intent = 'FREE';
                                    message.clear();
                                    messagePage = 0;
                                    messages = [];
                                  });
                                  loadMessages(latest: true);
                                }),
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                              onPressed: sessionPage > 0 && !busy
                                  ? () {
                                      sessionPage--;
                                      loadSessions();
                                    }
                                  : null,
                              child: const Text('Précédent')),
                          TextButton(
                              onPressed: sessionNext && !busy
                                  ? () {
                                      sessionPage++;
                                      loadSessions();
                                    }
                                  : null,
                              child: const Text('Suivant'))
                        ]),
                  ]),
              if (session == null)
                Center(
                    child: FilledButton.icon(
                        onPressed: busy ? null : create,
                        icon: const Icon(Icons.chat_bubble_outline),
                        label: const Text('Commencer une conversation'))),
              if (session != null && messages.isEmpty && !busy && error == null)
                const Notice(
                    'Votre conversation est prête. Posez une question sur votre orientation.'),
              for (final m in messages)
                Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(
                          alignment: Alignment.centerRight,
                          child: Card(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer,
                              child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Text(text(m['question']))))),
                      Card(
                          child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                        switch (m['status']) {
                                          'ANSWERED' =>
                                            'Réponse fondée sur les données disponibles',
                                          'NEEDS_INPUT' =>
                                            'Paramètres nécessaires',
                                          'INSUFFICIENT_DATA' =>
                                            'Données insuffisantes',
                                          'HISTORICAL' => 'Résultat historique',
                                          'UNSUPPORTED' =>
                                            'Demande non prise en charge',
                                          _ => 'État inconnu'
                                        },
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold)),
                                    SelectableText(text(m['content'])),
                                    ...structured(m['data']),
                                    SourceDetails(objects(m['sources'])),
                                  ]))),
                    ]),
              if (session != null)
                Wrap(alignment: WrapAlignment.spaceBetween, children: [
                  TextButton(
                      onPressed: messagePage > 0 && !busy
                          ? () {
                              messagePage--;
                              loadMessages();
                            }
                          : null,
                      child: const Text('Messages précédents')),
                  TextButton(
                      onPressed: messageNext && !busy
                          ? () {
                              messagePage++;
                              loadMessages();
                            }
                          : null,
                      child: const Text('Messages suivants'))
                ]),
            ])),
        if (session != null)
          SafeArea(
              top: false,
              child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: ConstrainedBox(
                      constraints: BoxConstraints(
                          maxHeight: (MediaQuery.sizeOf(context).height -
                                  MediaQuery.viewInsetsOf(context).bottom) *
                              .45),
                      child: SingleChildScrollView(
                          child:
                              Column(mainAxisSize: MainAxisSize.min, children: [
                        ExpansionTile(
                            title: const Text(
                                'Aider l’assistant : paramètres explicites'),
                            onExpansionChanged: (open) {
                              if (open && programs.isEmpty) parameters();
                            },
                            children: [
                              DropdownButtonFormField<String>(
                                  initialValue: intent,
                                  decoration: const InputDecoration(
                                      labelText: 'Type de demande'),
                                  items: const [
                                    DropdownMenuItem(
                                        value: 'FREE',
                                        child: Text('Question libre')),
                                    DropdownMenuItem(
                                        value: 'COMPARISON',
                                        child: Text('Comparer des formations')),
                                    DropdownMenuItem(
                                        value: 'SIMULATION',
                                        child: Text('Simuler une moyenne')),
                                    DropdownMenuItem(
                                        value: 'EXPLANATION',
                                        child: Text(
                                            'Expliquer une recommandation')),
                                    DropdownMenuItem(
                                        value: 'SCHOLARSHIPS',
                                        child: Text('Évaluer les bourses')),
                                  ],
                                  onChanged: (v) {
                                    setState(() {
                                      intent = v!;
                                      message.text = switch (intent) {
                                        'COMPARISON' =>
                                          'Comparer ces formations',
                                        'SIMULATION' => 'Simuler ma moyenne',
                                        'EXPLANATION' =>
                                          'Pourquoi cette recommandation ?',
                                        'SCHOLARSHIPS' =>
                                          'Quelles bourses pour mon profil ?',
                                        _ => ''
                                      };
                                    });
                                  }),
                              if (intent == 'SIMULATION')
                                TextField(
                                    controller: average,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                            decimal: true),
                                    decoration: const InputDecoration(
                                        labelText:
                                            'Moyenne hypothétique dans votre barème confirmé')),
                              if (intent == 'EXPLANATION')
                                referenceSelect(
                                    label: 'Recommandation',
                                    items: recommendations,
                                    value: recommendation,
                                    onChanged: (v) =>
                                        setState(() => recommendation = v)),
                              if (['COMPARISON', 'SCHOLARSHIPS']
                                  .contains(intent))
                                ConstrainedBox(
                                    constraints:
                                        const BoxConstraints(maxHeight: 200),
                                    child:
                                        ListView(shrinkWrap: true, children: [
                                      for (final p in programs)
                                        CheckboxListTile(
                                            title: Text(text(p['name'])),
                                            value: selectedPrograms
                                                .contains(p['id']),
                                            onChanged: (v) {
                                              setState(() {
                                                if (v == true &&
                                                    selectedPrograms.length <
                                                        6) {
                                                  selectedPrograms
                                                      .add(p['id'] as String);
                                                }
                                                if (v == false) {
                                                  selectedPrograms
                                                      .remove(p['id']);
                                                }
                                              });
                                            }),
                                    ])),
                              if (['COMPARISON', 'SCHOLARSHIPS']
                                  .contains(intent))
                                TextButton(
                                    onPressed: () async {
                                      try {
                                        final next = await repo.catalog(
                                            'programs',
                                            page: programs.length ~/ 20);
                                        if (mounted) {
                                          setState(() => programs = [
                                                ...programs,
                                                ...next.content
                                                    .map((p) => p.fields)
                                              ]);
                                        }
                                      } catch (e) {
                                        if (mounted) setState(() => error = e);
                                      }
                                    },
                                    child: const Text(
                                        'Charger d’autres formations')),
                            ]),
                        Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                  child: TextField(
                                      controller: message,
                                      enabled: !busy,
                                      minLines: 1,
                                      maxLines: 3,
                                      maxLength: 2000,
                                      decoration: const InputDecoration(
                                          labelText: 'Votre question'))),
                              IconButton(
                                  onPressed: busy ? null : send,
                                  icon: const Icon(Icons.send),
                                  tooltip: 'Envoyer la question')
                            ]),
                      ]))))),
      ]));
  List<Widget> structured(Object? data) {
    if (data is List) return [for (final row in objects(data)) _card(row)];
    if (data is Map) {
      final value = object(data);
      final payload = value['result'] is Map ? object(value['result']) : value;
      if (payload['programs'] is List ||
          payload['scholarships'] is List ||
          payload['after'] is List) {
        return [DecisionContent(payload, apiClient: widget.apiClient)];
      }
      if (payload['explanation'] is Map) {
        return [
          _card({
            ...object(payload['explanation']),
            'programId': payload['programId'],
            'score': payload['score'],
            'eligibilityStatus': payload['eligibilityStatus']
          })
        ];
      }
    }
    return [];
  }

  Widget _card(Json row) {
    if (row['entityId'] is String && row['entityType'] is String) {
      final resource = const {
        'UNIVERSITY': 'universities',
        'CAMPUS': 'campuses',
        'FACULTY': 'faculties',
        'PROGRAM': 'programs',
        'SCHOLARSHIP': 'scholarships'
      }[row['entityType']];
      return Card(
          child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(text(row['name']),
                        style: Theme.of(context).textTheme.titleMedium),
                    SelectableText(text(row['content'])),
                    SourceDetails(objects(row['sources'])),
                    if (resource != null)
                      TextButton(
                          onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                  builder: (_) => CatalogDetailPage(
                                      apiClient: widget.apiClient,
                                      resource: resource,
                                      id: row['entityId'] as String))),
                          child: const Text('Consulter la fiche')),
                  ])));
    }
    return ResultCard(row,
        actions: row['programId'] is String
            ? TextButton(
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                        builder: (_) => CatalogDetailPage(
                            apiClient: widget.apiClient,
                            resource: 'programs',
                            id: row['programId'] as String))),
                child: const Text('Consulter la formation'))
            : row['scholarshipId'] is String
                ? TextButton(
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                            builder: (_) => CatalogDetailPage(
                                apiClient: widget.apiClient,
                                resource: 'scholarships',
                                id: row['scholarshipId'] as String))),
                    child: const Text('Consulter la bourse'))
                : null);
  }
}
