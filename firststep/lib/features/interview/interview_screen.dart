import 'dart:async';
import 'dart:typed_data';
import 'dart:math';

import 'package:camera/camera.dart';
import 'package:firststep/widgets/camera_cover_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:speech_to_text/speech_to_text.dart'; // ✅ STT 추가

import '../../models/interview_result.dart';
import '../../state/interview_result_provider.dart';
import '../../theme/app_colors.dart';
import '../../services/face_analyzer.dart';

class InterviewScreen extends ConsumerStatefulWidget {
  const InterviewScreen({super.key});

  @override
  ConsumerState<InterviewScreen> createState() => _InterviewScreenState();
}

class _InterviewScreenState extends ConsumerState<InterviewScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final _answerCtrl = TextEditingController();

  // ✅ STT
  final SpeechToText _stt = SpeechToText();
  bool _sttReady = false;
  bool _listening = false;
  String _answerPrefix = '';

  // 질문
  final List<String> _questions = const [
    '본인의 장단점을 말해보세요.',
    '지원한 직무를 선택한 이유는 무엇인가요?',
    '협업 중 갈등이 생겼을 때 어떻게 해결했나요?',
    '가장 힘들었던 경험과 그걸 극복한 방법은?',
    '입사 후 1년 안에 이루고 싶은 목표는?',
  ];
  late String _question;

  // 카메라/분석
  CameraController? _camera;
  late final FaceDetector _faceDetector;

  bool _isRunning = false;
  bool _isBusy = false;
  int _frameCount = 0;
  int _frontCount = 0; // 정면 유지 프레임
  double _smileEma = 0;
  int _faceDetectedCount = 0;

  DateTime _lastProcess = DateTime.fromMillisecondsSinceEpoch(0);

  // UI 표시용
  double _gazePercent = 0;
  double _smileAvg = 0;
  double _faceDetectedPercent = 0;

  @override
  void initState() {
    super.initState();
    _question = _questions.first;

    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        performanceMode: FaceDetectorMode.accurate,
        enableClassification: true, // smilingProbability
        enableTracking: false,
        enableLandmarks: false,
        enableContours: false,
      ),
    );

    _initStt(); // ✅ STT 초기화
    _initCamera();
  }

  Future<void> _initStt() async {
    try {
      _sttReady = await _stt.initialize(
        onError: (e) => debugPrint('STT error: $e'),
        onStatus: (s) => debugPrint('STT status: $s'),
      );
      if (mounted) setState(() {});
    } catch (e) {
      _sttReady = false;
      if (mounted) setState(() {});
    }
  }

  Future<void> _startDictation() async {
    if (!_sttReady) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('음성인식을 사용할 수 없어요. 권한/설정을 확인해줘.')),
      );
      return;
    }
    if (_listening) return;

    // 기존 텍스트가 있으면 이어서 붙이기
    _answerPrefix = _answerCtrl.text.trimRight();
    if (_answerPrefix.isNotEmpty && !_answerPrefix.endsWith(' ')) {
      _answerPrefix = '$_answerPrefix ';
    }

    _listening = true;

    await _stt.listen(
      localeId: 'ko_KR',
      listenMode: ListenMode.dictation,
      partialResults: true,
      cancelOnError: false,
      onResult: (result) {
        final spoken = result.recognizedWords;

        // “말한 내용 그대로” 답변란에 반영 (기존 글 + 현재 세션 인식 텍스트)
        final combined = (_answerPrefix + spoken).trimLeft();

        _answerCtrl.value = _answerCtrl.value.copyWith(
          text: combined,
          selection: TextSelection.collapsed(offset: combined.length),
          composing: TextRange.empty,
        );

        // 필요하면 여기서 “말하는 중” UI 표시도 가능
        if (mounted) setState(() {});
      },
    );
  }

  Future<void> _stopDictation() async {
    if (!_listening) return;
    _listening = false;
    try {
      await _stt.stop();
    } catch (_) {}
    if (mounted) setState(() {});
  }

  Future<void> _initCamera() async {
    try {
      final cams = await availableCameras();
      // 전면 카메라 우선
      final front = cams.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cams.first,
      );

      final controller = CameraController(
        front,
        ResolutionPreset.medium,
        enableAudio: false, // MVP: 영상 분석만(마이크는 STT로 별도)
        imageFormatGroup: ImageFormatGroup.bgra8888, // iOS 안정적
      );

      await controller.initialize();

      if (!mounted) return;
      setState(() => _camera = controller);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('카메라 초기화 실패: $e')));
    }
  }

  @override
  void dispose() {
    final cam = _camera;

    // 화면 나갈 때 스트리밍 중이면 먼저 끊기(에러 무시)
    if (cam != null && cam.value.isStreamingImages) {
      cam.stopImageStream().catchError((_) {});
    }

    // ✅ STT 정리
    _stt.stop();

    _answerCtrl.dispose();
    _faceDetector.close();
    cam?.dispose();
    super.dispose();
  }

  void _nextQuestion() {
    final rnd = Random();
    setState(() {
      _question = _questions[rnd.nextInt(_questions.length)];
      _answerCtrl.clear();
      // 질문 바꾸면 “이어쓰기 prefix”도 리셋
      _answerPrefix = '';
    });
  }

  void _resetMetrics() {
    _frameCount = 0;
    _frontCount = 0;
    _smileEma = 0;
    _smileAvg = 0;
    _faceDetectedCount = 0;

    _gazePercent = 0;
    _smileAvg = 0;
    _faceDetectedPercent = 0;
  }

  Future<void> _start() async {
    final cam = _camera;
    if (cam == null || !cam.value.isInitialized) return;
    if (_isRunning) return;

    _resetMetrics();

    // ✅ STT 먼저 켜기(버튼 누르면 바로 받아쓰기)
    await _startDictation();

    setState(() => _isRunning = true);

    await cam.startImageStream((image) async {
      if (!_isRunning) return;

      // 처리 주기 제한 (약 4fps)
      final now = DateTime.now();
      if (now.difference(_lastProcess).inMilliseconds < 250) return;
      _lastProcess = now;

      if (_isBusy) return;
      _isBusy = true;

      try {
        await _processFrame(image);
      } catch (_) {
        // 프레임 처리 실패는 무시(스트림 유지)
      } finally {
        _isBusy = false;
      }
    });
  }

  Future<void> _stop() async {
    final cam = _camera;
    if (cam == null) return;

    if (!_isRunning) return;

    // ✅ STT 같이 끄기
    await _stopDictation();

    setState(() => _isRunning = false);

    try {
      await cam.stopImageStream();
    } catch (_) {}
  }

  Future<void> _processFrame(CameraImage image) async {
    // iOS(BGRA8888) 기준
    final inputImage = _toInputImage(
      image,
      _camera!.description.sensorOrientation,
    );
    final faces = await _faceDetector.processImage(inputImage);

    _frameCount++;

    if (faces.isNotEmpty) {
      _faceDetectedCount++;
      final f = faces.first;

      // 정면 판단(헤드포즈) - 대략적인 시선 안정 지표
      final yaw = (f.headEulerAngleY ?? 999).abs();
      final roll = (f.headEulerAngleZ ?? 999).abs();

      final isFront = yaw < 12 && roll < 12;
      if (isFront) _frontCount++;

      final smile = f.smilingProbability;
      if (smile != null) {
        final raw = (smile * 100).clamp(0.0, 100.0).toDouble();

        final mapped = (((raw - 15.0) / (60.0 - 15.0)) * 100.0)
            .clamp(0.0, 100.0)
            .toDouble();

        _smileEma = (_frameCount == 0)
            ? mapped
            : (_smileEma * 0.85 + mapped * 0.15);
      }
    }

    // UI 업데이트(가끔만)
    if (_frameCount % 3 == 0 && mounted) {
      setState(() {
        _gazePercent = _frameCount == 0 ? 0 : (_frontCount / _frameCount) * 100;
        _faceDetectedPercent = _frameCount == 0
            ? 0
            : (_faceDetectedCount / _frameCount) * 100;
        _smileAvg = _smileEma;
      });
    }
  }

  // CameraImage -> InputImage (iOS 안정 루트)
  InputImage _toInputImage(CameraImage image, int rotation) {
    final plane = image.planes.first;
    final bytes = plane.bytes;

    final inputImageData = InputImageMetadata(
      size: Size(image.width.toDouble(), image.height.toDouble()),
      rotation: _rotationFromSensor(rotation),
      format: InputImageFormat.bgra8888,
      bytesPerRow: plane.bytesPerRow,
    );

    return InputImage.fromBytes(bytes: bytes, metadata: inputImageData);
  }

  InputImageRotation _rotationFromSensor(int rotation) {
    switch (rotation) {
      case 90:
        return InputImageRotation.rotation90deg;
      case 180:
        return InputImageRotation.rotation180deg;
      case 270:
        return InputImageRotation.rotation270deg;
      case 0:
      default:
        return InputImageRotation.rotation0deg;
    }
  }

  // MVP 텍스트 기반 추임새
  int _countFillers(String text) {
    final re = RegExp(r'(어+|음+|그+|저기|뭐였더라)');
    return re.allMatches(text).length;
  }

  InterviewResult _evaluateMvp(String answer) {
    final trimmed = answer.trim();
    final length = trimmed.replaceAll(RegExp(r'\s+'), ' ').length;
    final fillers = _countFillers(trimmed);

    // 내용(40)
    int contentScore;
    if (length >= 220)
      contentScore = 40;
    else if (length >= 140)
      contentScore = 34;
    else if (length >= 80)
      contentScore = 28;
    else if (length >= 30)
      contentScore = 22;
    else
      contentScore = 14;

    // 시각(30): 정면 70%, 미소 30%
    final gazeScore = (_gazePercent.clamp(0, 100) * 0.7);
    final smileScore = (_smileAvg.clamp(0, 100) * 0.3);
    final visualScore = ((gazeScore + smileScore) / 100.0 * 30).round();

    // 음성/말버릇(30): 추임새 감점 (현재는 텍스트 기반)
    final penalty = min(20, fillers * 4);
    final voiceScore = max(0, 30 - penalty);

    int total = (contentScore + visualScore + voiceScore).clamp(0, 100);

    final logs = <String>[
      '답변 길이: $length자 → 내용 ${contentScore}/40',
      '정면 유지율: ${_gazePercent.toStringAsFixed(0)}%',
      '미소 점수(평균): ${_smileAvg.toStringAsFixed(0)}%',
      '시각 점수: $visualScore/30',
      '추임새: ${fillers}회 → 감점 -$penalty → 음성 ${voiceScore}/30',
    ];

    final feedback = <String>[
      if (_gazePercent < 70) '시선이 자주 흔들려요. 카메라 중앙을 “한 점”으로 고정 ㄱㄱ.',
      if (_smileAvg < 20) '표정이 무표정 쪽이에요. 입꼬리만 살짝 올려도 인상이 달라짐.',
      if (length < 80) '답변이 짧아요. 근거(경험) 1개 더 붙이면 점수 바로 오름.',
      if (fillers >= 3) '추임새가 많아요. “어/음” 대신 잠깐 멈추고 다음 문장 말하기.',
      '마지막에 결과(성과/배운 점) 한 줄로 딱 박으면 더 좋아요.',
    ];

    return InterviewResult(
      score: total,
      feedback: feedback.join('\n'),
      logs: logs,
    );
  }

  Future<void> _submit() async {
    final answer = _answerCtrl.text.trim();
    if (answer.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('답변을 입력해줘.')));
      return;
    }

    // ✅ 분석 중이면 멈추고 제출 (STT도 같이 꺼짐)
    await _stop();

    final result = _evaluateMvp(answer);
    ref.read(interviewResultProvider.notifier).state = result;

    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => _ResultSheet(
        score: result.score,
        feedback: result.feedback,
        logs: result.logs,
        onRetry: () {
          Navigator.pop(context);
          _answerCtrl.clear();
          _answerPrefix = '';
          _resetMetrics();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final cam = _camera;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '면접 연습',
              style: Theme.of(
                context,
              ).textTheme.displaySmall?.copyWith(color: AppColors.navy),
            ),
            const SizedBox(height: 12),

            // 카메라 프리뷰
            Container(
              height: 250,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.lightGray,
                borderRadius: BorderRadius.circular(16),
              ),
              child: cam == null || !cam.value.isInitialized
                  ? const Center(child: Text('카메라 준비중...'))
                  : CameraCoverPreview(controller: cam, radius: 16),
            ),

            const SizedBox(height: 10),

            // 시작/중지
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.navy,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed:
                          (cam == null ||
                              !cam.value.isInitialized ||
                              _isRunning)
                          ? null
                          : _start,
                      child: Text(_sttReady ? '시작' : '시작(마이크 준비중)'),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.navy,
                        side: const BorderSide(color: AppColors.navy),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _isRunning ? _stop : null,
                      child: Text(_listening ? '중지(듣는중)' : '중지'),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 실시간 지표
            _MetricRow(
              gaze: _gazePercent,
              smile: _smileAvg,
              face: _faceDetectedPercent,
              running: _isRunning,
            ),

            const SizedBox(height: 14),

            // 질문 + 답변
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Q.',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _question,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      IconButton(
                        onPressed: _nextQuestion,
                        icon: const Icon(Icons.refresh),
                        tooltip: '질문 바꾸기',
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _answerCtrl,
                    maxLines: 6,
                    decoration: InputDecoration(
                      hintText: _isRunning
                          ? '말하면 자동으로 입력돼요.'
                          : '답변을 입력해주세요. (시작 누르면 음성으로도 입력됨)',
                      filled: true,
                      fillColor: AppColors.lightGray,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // 답변 완료
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.navy,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _submit,
                child: const Text('답변 완료'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  final double gaze;
  final double smile;
  final double face;
  final bool running;

  const _MetricRow({
    required this.gaze,
    required this.smile,
    required this.face,
    required this.running,
  });

  @override
  Widget build(BuildContext context) {
    Widget chip(String label, String value) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.lightGray,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
      );
    }

    return Row(
      children: [
        Expanded(child: chip('시선(정면)', '${gaze.toStringAsFixed(0)}%')),
        const SizedBox(width: 8),
        Expanded(child: chip('표정(미소)', '${smile.toStringAsFixed(0)}%')),
        const SizedBox(width: 8),
        Expanded(
          child: chip('얼굴감지', running ? '${face.toStringAsFixed(0)}%' : '-'),
        ),
      ],
    );
  }
}

class _ResultSheet extends StatelessWidget {
  final int score;
  final String feedback;
  final List<String> logs;
  final VoidCallback onRetry;

  const _ResultSheet({
    required this.score,
    required this.feedback,
    required this.logs,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$score점',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Text(feedback),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.lightGray,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: logs.map((l) => Text('• $l')).toList(),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.navy,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: onRetry,
              child: const Text('다시 연습하기'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            blurRadius: 12,
            offset: Offset(0, 6),
            color: Color(0x14000000),
          ),
        ],
      ),
      child: child,
    );
  }
}
