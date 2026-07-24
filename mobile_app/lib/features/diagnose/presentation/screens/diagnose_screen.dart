import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/localization/language_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/confidence_badge.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../data/disease_models.dart';
import '../../data/disease_repository.dart';

final diseaseRepositoryProvider = Provider<DiseaseRepository>((ref) => DiseaseRepository());

class DiagnoseScreen extends ConsumerStatefulWidget {
  const DiagnoseScreen({super.key});

  @override
  ConsumerState<DiagnoseScreen> createState() => _DiagnoseScreenState();
}

class _DiagnoseScreenState extends ConsumerState<DiagnoseScreen> {
  final _cropController = TextEditingController();
  final _symptomsController = TextEditingController();
  File? _photo;
  bool _organic = true;
  bool _submitting = false;
  String? _error;
  GuidanceEnvelope? _result;

  @override
  void dispose() {
    _cropController.dispose();
    _symptomsController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, maxWidth: 1600, imageQuality: 85);
    if (picked == null) return;
    setState(() {
      _photo = File(picked.path);
      _result = null;
    });
  }

  void _showPhotoSourceSheet() {
    final s = ref.read(appStringsProvider);
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(s.takePhoto),
              onTap: () {
                Navigator.of(context).pop();
                _pickPhoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(s.chooseFromGallery),
              onTap: () {
                Navigator.of(context).pop();
                _pickPhoto(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final s = ref.read(appStringsProvider);
    final repo = ref.read(diseaseRepositoryProvider);
    final language = ref.read(languageProvider);
    final crop = _cropController.text.trim();
    final symptoms = _symptomsController.text.trim();

    if (_photo == null && symptoms.isEmpty) {
      setState(() => _error = s.enterSymptomsOrPhotoError);
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
      _result = null;
    });

    try {
      // A photo drives a real Claude vision diagnosis (see
      // disease_kb/app/main.py's diagnose_photo + vision.py) constrained to
      // our curated disease knowledge base — this is the primary result
      // when a photo is present, not just an upload confirmation.
      final result = _photo != null
          ? await repo.diagnosePhoto(photo: _photo!, crop: crop, notes: symptoms, language: language)
          : _organic
              ? await repo.searchOrganicGuidance(
                  query: crop.isEmpty ? symptoms : '$crop: $symptoms',
                  crop: crop.isEmpty ? null : crop,
                  language: language,
                )
              : await repo.chemicalGuidance(
                  query: crop.isEmpty ? symptoms : '$crop: $symptoms',
                  crop: crop.isEmpty ? null : crop,
                  language: language,
                );

      setState(() {
        _submitting = false;
        _result = result;
      });
    } catch (e) {
      setState(() {
        _submitting = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(s.diagnoseTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Text(s.diagnoseSubtitle, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 20),
          Stack(
            children: [
              GestureDetector(
                onTap: _showPhotoSourceSheet,
                child: Container(
                  height: 160,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                    image: _photo != null ? DecorationImage(image: FileImage(_photo!), fit: BoxFit.cover) : null,
                  ),
                  child: _photo == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.add_a_photo_outlined, size: 32, color: AppColors.textSecondary),
                            const SizedBox(height: 8),
                            Text(s.addPhoto, style: Theme.of(context).textTheme.bodyMedium),
                          ],
                        )
                      : Align(
                          alignment: Alignment.bottomRight,
                          child: Container(
                            margin: const EdgeInsets.all(8),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(s.retakePhoto, style: const TextStyle(color: Colors.white, fontSize: 12)),
                          ),
                        ),
                ),
              ),
              if (_photo != null)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Tooltip(
                    message: s.removePhoto,
                    child: InkWell(
                      onTap: () => setState(() {
                        _photo = null;
                        _result = null;
                      }),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close_rounded, size: 18, color: Colors.white),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Text(s.cropLabel, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          TextFormField(controller: _cropController, decoration: InputDecoration(hintText: s.cropHint)),
          const SizedBox(height: 20),
          Text(s.symptomsLabel, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          TextFormField(
            controller: _symptomsController,
            maxLines: 3,
            decoration: InputDecoration(hintText: _photo != null ? s.symptomsHintWithPhoto : s.symptomsHint),
          ),
          const SizedBox(height: 20),
          Text(s.treatmentPreference, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          SegmentedButton<bool>(
            segments: [
              ButtonSegment(value: true, label: Text(s.organicOption), icon: const Icon(Icons.eco_outlined)),
              ButtonSegment(value: false, label: Text(s.chemicalOption), icon: const Icon(Icons.science_outlined)),
            ],
            selected: {_organic},
            onSelectionChanged: (v) => setState(() => _organic = v.first),
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: AppColors.danger)),
          ],
          const SizedBox(height: 24),
          PrimaryButton(label: s.getGuidance, onPressed: _submit, isLoading: _submitting),
          if (_submitting && _photo != null) ...[
            const SizedBox(height: 16),
            _NoteBanner(text: s.analyzingPhotoNote),
          ],
          if (_result != null) ...[
            const SizedBox(height: 24),
            _ResultCard(result: _result!, s: s),
          ],
        ],
      ),
    );
  }
}

class _NoteBanner extends StatelessWidget {
  const _NoteBanner({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, size: 18, color: AppColors.info),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: Theme.of(context).textTheme.bodySmall)),
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.result, required this.s});
  final GuidanceEnvelope result;
  final AppStrings s;

  @override
  Widget build(BuildContext context) {
    final match = result.topMatch;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        match?.diseaseName ?? s.diagnoseTitle,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ),
                    ConfidenceBadge(score: result.confidenceScore, compact: true),
                  ],
                ),
                if (match != null) ...[
                  const SizedBox(height: 4),
                  Text(match.pathogen, style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 4),
                  Text(s.matchPercent((match.similarityScore * 100).round()),
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.primary)),
                  const SizedBox(height: 16),
                  _Section(title: s.symptomsSectionTitle, body: match.symptoms),
                  _Section(title: s.organicTreatmentSectionTitle, body: match.organicTreatment),
                  _Section(title: s.preventionSectionTitle, body: match.prevention),
                  if (match.sources.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(s.sourcesSectionTitle, style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 4),
                    for (final src in match.sources)
                      Text('• ${src.name}', style: Theme.of(context).textTheme.bodySmall),
                  ],
                ],
                const SizedBox(height: 12),
                Text(result.reasoning, style: Theme.of(context).textTheme.bodySmall),
                if (result.actionPlan.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  for (final step in result.actionPlan)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.check_circle_outline_rounded, size: 16, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Expanded(child: Text(step, style: Theme.of(context).textTheme.bodySmall)),
                        ],
                      ),
                    ),
                ],
                if (result.assumptions.isNotEmpty) ...[
                  const Divider(height: 24),
                  for (final a in result.assumptions)
                    Text(a, style: Theme.of(context).textTheme.labelSmall),
                ],
              ],
            ),
          ),
        ),
        if (result.alternatives.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(s.otherPossibleMatches, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final alt in result.alternatives)
            Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(alt.diseaseName),
                subtitle: Text(s.matchPercent((alt.similarityScore * 100).round())),
              ),
            ),
        ],
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.body});
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    if (body.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(body, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
