import 'package:flutter/material.dart';
import '../services/backend_service.dart';
import '../theme/app_colors.dart';

class RecommendationsScreen extends StatefulWidget {
  final int audioScore;
  final int digitalScore;
  final int physicalScore;

  const RecommendationsScreen({
    super.key,
    required this.audioScore,
    required this.digitalScore,
    required this.physicalScore,
  });

  @override
  State<RecommendationsScreen> createState() => _RecommendationsScreenState();
}

class _RecommendationsScreenState extends State<RecommendationsScreen> {
  late BackendService _backendService;
  bool _isLoading = true;
  Map<String, dynamic>? _recommendations;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _backendService = BackendService();
    _loadRecommendations();
  }

  /// Load recommendations from backend
  Future<void> _loadRecommendations() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final result = await _backendService.getRecommendations(
        audioScore: widget.audioScore,
        digitalScore: widget.digitalScore,
        physicalScore: widget.physicalScore,
      );

      if (mounted) {
        setState(() {
          if (result['status'] == 'success' ||
              result['status'] == 'cached' ||
              result['status'] == 'fallback') {
            _recommendations = result['data'];
          } else {
            _errorMessage =
                result['message'] ?? 'Failed to load recommendations';
            _recommendations = result['data'];
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error: $e';
          _isLoading = false;
        });
      }
    }
  }

  /// Retry loading recommendations
  void _retryLoading() {
    _loadRecommendations();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.getBackgroundColor(context),
      appBar: AppBar(
        backgroundColor: AppColors.getSurfaceColor(context),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.getTextColor(context)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Stress Management Recommendations',
          style: TextStyle(
            color: AppColors.getTextColor(context),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? _buildLoadingView()
          : _errorMessage != null && _recommendations == null
              ? _buildErrorView()
              : _buildRecommendationsView(),
    );
  }

  /// Build loading view
  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppColors.primary),
          const SizedBox(height: 16),
          Text(
            'Loading personalized recommendations...',
            style: TextStyle(
              color: AppColors.getSecondaryTextColor(context),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  /// Build error view
  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.warning_rounded,
            color: AppColors.warning,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage ?? 'Failed to load recommendations',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.getTextColor(context),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _retryLoading,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build recommendations view
  Widget _buildRecommendationsView() {
    if (_recommendations == null) {
      return _buildErrorView();
    }

    final stressAnalysis =
        _recommendations!['stress_analysis'] as Map<String, dynamic>?;
    final recommendations =
        (_recommendations!['recommendations'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stress Overall Summary
          _buildStressSummaryCard(stressAnalysis),
          const SizedBox(height: 24),

          // Stress Scores
          _buildScoresCard(),
          const SizedBox(height: 24),

          // Recommendations Header
          Text(
            'Personalized Recommendations',
            style: TextStyle(
              color: AppColors.getTextColor(context),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Follow these recommendations to manage your stress effectively',
            style: TextStyle(
              color: AppColors.getSecondaryTextColor(context),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),

          // Recommendations List
          ...List.generate(
            recommendations.length,
            (index) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildRecommendationCard(
                recommendations[index],
                index + 1,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Footer note
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.3),
              ),
            ),
            child: Text(
              '💡 Tip: Try implementing one recommendation at a time. Consistency is key to seeing improvements!',
              style: TextStyle(
                color: AppColors.getTextColor(context),
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build stress summary card
  Widget _buildStressSummaryCard(Map<String, dynamic>? analysis) {
    if (analysis == null) return const SizedBox.shrink();

    final level = analysis['level'] as String? ?? 'Unknown';
    final category = analysis['category'] as String? ?? '';
    final primaryStressor = analysis['primary_stressor'] as String? ?? '';

    Color getLevelColor(String level) {
      switch (level.toLowerCase()) {
        case 'low':
          return Colors.green;
        case 'moderate':
          return Colors.orange;
        case 'high':
          return Colors.deepOrange;
        case 'critical':
          return Colors.red;
        default:
          return AppColors.primary;
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: getLevelColor(level).withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: getLevelColor(level).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.psychology,
                  color: getLevelColor(level),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Stress Level: ${level.toUpperCase()}',
                      style: TextStyle(
                        color: AppColors.getTextColor(context),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      category,
                      style: TextStyle(
                        color: AppColors.getSecondaryTextColor(context),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (primaryStressor.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Primary Stressor: ${primaryStressor.replaceAll('_', ' ').toUpperCase()}',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Build stress scores card
  Widget _buildScoresCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Stress Scores',
            style: TextStyle(
              color: AppColors.getTextColor(context),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildScoreRow(
            'Audio/Environment',
            widget.audioScore,
            '🔊',
          ),
          const SizedBox(height: 12),
          _buildScoreRow(
            'Digital Habits',
            widget.digitalScore,
            '📱',
          ),
          const SizedBox(height: 12),
          _buildScoreRow(
            'Physical Activity',
            widget.physicalScore,
            '🏃',
          ),
        ],
      ),
    );
  }

  /// Build score row
  Widget _buildScoreRow(String label, int score, String emoji) {
    return Row(
      children: [
        Text(
          emoji,
          style: const TextStyle(fontSize: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: AppColors.getTextColor(context),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: score / 100,
                  minHeight: 6,
                  backgroundColor: AppColors.primary.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    score < 40
                        ? Colors.green
                        : score < 70
                            ? Colors.orange
                            : Colors.red,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '$score/100',
          style: TextStyle(
            color: AppColors.getTextColor(context),
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  /// Build recommendation card
  Widget _buildRecommendationCard(Map<String, dynamic> rec, int index) {
    final title = rec['title'] as String? ?? 'Recommendation';
    final action = rec['action'] as String? ?? '';
    final duration = rec['duration'] as String? ?? '';
    final benefit = rec['benefit'] as String? ?? '';
    final motivation = rec['motivation'] as String? ?? '';
    final priority = rec['priority'] as String? ?? 'medium';

    Color getPriorityColor(String priority) {
      switch (priority.toLowerCase()) {
        case 'high':
          return Colors.red;
        case 'medium':
          return Colors.orange;
        default:
          return Colors.blue;
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(
            color: getPriorityColor(priority),
            width: 4,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with index and priority
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '#$index',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: AppColors.getTextColor(context),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: getPriorityColor(priority).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  priority.toUpperCase(),
                  style: TextStyle(
                    color: getPriorityColor(priority),
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Duration
          if (duration.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 16,
                    color: AppColors.getSecondaryTextColor(context),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    duration,
                    style: TextStyle(
                      color: AppColors.getSecondaryTextColor(context),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

          // Action
          if (action.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.getBackgroundColor(context),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  action,
                  style: TextStyle(
                    color: AppColors.getTextColor(context),
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),

          // Benefit
          if (benefit.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 16,
                    color: Colors.green,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Benefit: $benefit',
                      style: TextStyle(
                        color: AppColors.getSecondaryTextColor(context),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Motivation
          if (motivation.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      motivation,
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
