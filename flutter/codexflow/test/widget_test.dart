import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:xiaoqiao_android_codex/main.dart';
import 'package:xiaoqiao_android_codex/models/app_models.dart';
import 'package:xiaoqiao_android_codex/screens/dashboard_screen.dart';
import 'package:xiaoqiao_android_codex/services/api_client.dart';
import 'package:xiaoqiao_android_codex/state/app_model.dart';

void main() {
  testWidgets('renders xiaoqiao-android-codex shell', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(XiaoqiaoAndroidCodexApp(prefs: prefs));
    await tester.pumpAndSettle();

    expect(find.text('会话'), findsWidgets);
    expect(find.text('审批'), findsOneWidget);
    expect(find.text('设置'), findsOneWidget);
  });

  test('sends Basic auth from URL user info', () async {
    final client = ApiClient(
      baseUrlString: 'http://codexflow:secret@192.168.50.190:4318',
      client: MockClient((request) async {
        expect(
          request.url.toString(),
          'http://192.168.50.190:4318/api/v1/dashboard',
        );
        expect(
          request.headers['Authorization'],
          'Basic ${base64Encode(utf8.encode('codexflow:secret'))}',
        );
        expect(request.headers['User-Agent'], ApiClient.appUserAgent);
        return http.Response(jsonEncode(_dashboardPayload()), 200);
      }),
    );

    final dashboard = await client.dashboard();

    expect(dashboard.agent.connected, isTrue);
  });

  test('decodes escaped Basic auth user info', () async {
    final client = ApiClient(
      baseUrlString:
          'https://codexflow:sec%40ret%3Awith%2Fslash%3Fand%23hash@example.trycloudflare.com',
      client: MockClient((request) async {
        expect(
          request.url.toString(),
          'https://example.trycloudflare.com/api/v1/dashboard',
        );
        expect(
          request.headers['Authorization'],
          'Basic ${base64Encode(utf8.encode('codexflow:sec@ret:with/slash?and#hash'))}',
        );
        expect(request.headers['User-Agent'], ApiClient.appUserAgent);
        return http.Response(jsonEncode(_dashboardPayload()), 200);
      }),
    );

    final dashboard = await client.dashboard();

    expect(dashboard.agent.connected, isTrue);
  });

  test('treats sessions without lifecycle stage as history', () {
    final session = SessionSummary.fromJson(<String, dynamic>{
      'id': 'session-1',
      'agentId': null,
      'cwd': '/tmp/example',
      'status': 'notLoaded',
      'loaded': false,
      'ended': false,
      'lifecycleStage': null,
      'historyAvailable': null,
      'runtimeAvailable': null,
    });

    expect(session.agentId, 'codex');
    expect(session.lifecycleStage, 'history_only');
    expect(session.historyAvailable, isTrue);
  });

  testWidgets('renders missing-lifecycle sessions in history group', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    final model = AppModel(prefs)
      ..isAgentOnline = true
      ..dashboard = DashboardResponse.fromJson(
        _dashboardPayload(
          sessions: <Object?>[
            <String, Object?>{
              'id': 'session-1',
              'name': '历史任务',
              'preview': '可以打开的历史会话',
              'cwd': '/tmp/example',
              'source': 'vscode',
              'status': 'notLoaded',
              'loaded': false,
              'ended': false,
              'updatedAt': 1780072476,
              'createdAt': 1780072000,
            },
          ],
        ),
      );

    tester.view.physicalSize = const Size(430, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ChangeNotifierProvider<AppModel>.value(
        value: model,
        child: const MaterialApp(home: DashboardScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('列表'), findsOneWidget);
    expect(find.text('历史会话'), findsOneWidget);
    expect(find.text('历史任务'), findsOneWidget);
    expect(find.text('查看详情'), findsOneWidget);
  });
}

Map<String, Object?> _dashboardPayload({List<Object?> sessions = const []}) {
  return <String, Object?>{
    'agent': <String, Object?>{
      'connected': true,
      'startedAt': '2026-05-29T00:00:00Z',
      'listenAddr': '127.0.0.1:4319',
      'codexBinaryPath': 'codex',
    },
    'agents': <Object?>[
      <String, Object?>{
        'id': 'codex',
        'name': 'Codex',
        'available': true,
        'default': true,
        'capabilities': <String, Object?>{
          'supportsInterruptTurn': true,
          'supportsApprovals': true,
          'supportsArchive': true,
          'supportsResume': true,
          'supportsHistoryImport': false,
        },
      },
    ],
    'defaultAgent': 'codex',
    'stats': <String, Object?>{
      'totalSessions': sessions.length,
      'loadedSessions': 0,
      'activeSessions': 0,
      'pendingApprovals': 0,
    },
    'sessions': sessions,
    'approvals': <Object?>[],
  };
}
