import 'dart:async';

import 'package:cooking_assistant/access/local_access_manager.dart';
import 'package:cooking_assistant/database/database_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

@immutable
class KitchenStep {
  const KitchenStep(this.title, this.instruction, this.icon, {this.timerSeconds, this.safetyTip});
  final String title;
  final String instruction;
  final IconData icon;
  final int? timerSeconds;
  final String? safetyTip;
}

@immutable
class KitchenRecipe {
  const KitchenRecipe({required this.id, required this.name, required this.culture, required this.minutes, required this.isStarter, required this.color, required this.icon, required this.steps});
  final String id;
  final String name;
  final String culture;
  final int minutes;
  final bool isStarter;
  final Color color;
  final IconData icon;
  final List<KitchenStep> steps;

  static Future<KitchenRecipe> fromDatabase(Map<String, dynamic> row) async {
    final id = row['id'].toString();
    final rawSteps = await DatabaseHelper.getRecipeSteps(id);
    final steps = rawSteps.map((row) {
      final instruction = row['instructionText'] as String;
      final firstSentence = instruction.split(RegExp(r'[,.:;]')).first.trim();
      final title = firstSentence.length > 42 ? '${firstSentence.substring(0, 39)}…' : firstSentence;
      return KitchenStep(
        title.isEmpty ? 'Step ${row['stepOrder']}' : title,
        instruction,
        _iconForInstruction(instruction, fallback: _iconFor(id)),
      );
    }).toList();
    return KitchenRecipe(
      id: id,
      name: row['name'] as String,
      culture: row['cultureTag'] as String? ?? 'International',
      minutes: (row['prepTimeMinutes'] as num?)?.toInt() ?? 0,
      isStarter: (row['isStarterRecipe'] as num?)?.toInt() == 1,
      color: _colorFor(id),
      icon: _iconFor(id),
      steps: steps,
    );
  }

  /// Picks a step-specific icon by scanning the instruction text for
  /// common cooking actions, so steps within the same recipe look
  /// different from each other instead of repeating one fixed icon.
  /// Falls back to the recipe-level icon if nothing matches.
  static IconData _iconForInstruction(
    String instruction, {
    required IconData fallback,
  }) {
    final text = instruction.toLowerCase();
    if (text.contains('chop') ||
        text.contains('dice') ||
        text.contains('slice') ||
        text.contains('cut')) {
      return Icons.content_cut;
    }
    if (text.contains('fry') ||
        text.contains('sauté') ||
        text.contains('saute') ||
        text.contains('sear')) {
      return Icons.local_fire_department;
    }
    if (text.contains('boil') ||
        text.contains('simmer') ||
        text.contains('poach')) {
      return Icons.soup_kitchen;
    }
    if (text.contains('bake') || text.contains('toast') || text.contains('oven')) {
      return Icons.bakery_dining;
    }
    if (text.contains('mix') ||
        text.contains('combine') ||
        text.contains('stir') ||
        text.contains('whisk')) {
      return Icons.blender;
    }
    if (text.contains('season') ||
        text.contains('salt') ||
        text.contains('spice')) {
      return Icons.grain;
    }
    if (text.contains('marinate') || text.contains('rest') || text.contains('chill')) {
      return Icons.hourglass_bottom;
    }
    if (text.contains('serve') || text.contains('plate') || text.contains('garnish')) {
      return Icons.restaurant_menu;
    }
    return fallback;
  }

  static IconData _iconFor(String id) => switch (id) {
    '2' => Icons.ramen_dining,
    '5' || '9' || '12' || '15' => Icons.egg_alt,
    '1' || '6' || '10' => Icons.rice_bowl,
    '7' || '8' || '4' => Icons.dinner_dining,
    '11' || '13' || '14' => Icons.restaurant,
    '3' => Icons.soup_kitchen,
    _ => Icons.restaurant_menu,
  };

  static Color _colorFor(String id) => switch (id) {
    '2' => const Color(0xFFD88936),
    '5' || '9' || '12' || '15' => const Color(0xFF5E8D57),
    '1' || '6' || '10' => const Color(0xFFD85D3D),
    _ => const Color(0xFF527D69),
  };
}

class VirtualKitchenHomePage extends StatefulWidget {
  const VirtualKitchenHomePage({super.key, this.accessManager});

  final LocalAccessManager? accessManager;

  @override
  State<VirtualKitchenHomePage> createState() => _VirtualKitchenHomePageState();
}

class _VirtualKitchenHomePageState extends State<VirtualKitchenHomePage> {
  late final LocalAccessManager _access =
      widget.accessManager ?? LocalAccessManager();
  AccessStatus _status = const AccessStatus();
  bool _loading = true;
  bool _searching = false;
  List<KitchenRecipe> _recipes = [];
  List<KitchenRecipe> _visibleRecipes = [];
  final Set<String> _selectedIngredients = {};
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  int _searchGeneration = 0;

  // New filter state: culture, time available, energy level, dietary
  // restriction. All optional (null = "no preference").
  String? _selectedCulture;
  int? _selectedMinutes;
  String? _selectedEnergy;
  String? _selectedDietaryRestriction;

  bool get _isPremium => _status.isPremium;

  Map<String, Map<String, dynamic>> get _recipeRowsById => {
        for (final row in _allRecipeRows) row['id'].toString(): row,
      };

  List<String> get _availableCultures => _allRecipeRows
      .map((row) => row['cultureTag'] as String?)
      .whereType<String>()
      .where((c) => c.trim().isNotEmpty)
      .toSet()
      .toList()
    ..sort();

  List<String> get _availableDietaryTags => _allRecipeRows
      .expand(
        (row) => (row['dietaryTags']?.toString() ?? '').split(','),
      )
      .map((tag) => tag.trim())
      .where((tag) => tag.isNotEmpty)
      .toSet()
      .toList()
    ..sort();

  bool get _hasActiveFilters =>
      _selectedIngredients.isNotEmpty ||
      _selectedCulture != null ||
      _selectedMinutes != null ||
      _selectedEnergy != null ||
      _selectedDietaryRestriction != null;

  List<KitchenRecipe> get _displayRecipes {
    if (!_hasActiveFilters) return _visibleRecipes;
    final rowsById = _recipeRowsById;
    final ranked = DatabaseHelper.getRankedRecommendations(
      _visibleRecipes
          .map((recipe) {
            final row = rowsById[recipe.id];
            return {
              'id': recipe.id,
              'name': recipe.name,
              'dietaryTags': row?['dietaryTags']?.toString() ?? '',
              'cultureTag': row?['cultureTag'] as String?,
              'prepTimeMinutes': (row?['prepTimeMinutes'] as num?)?.toInt(),
              'energyLevel': row?['energyLevel'] as String?,
              'ingredientSet': _recipeIngredients[recipe.id] ?? <String>{},
            };
          })
          .toList(),
      _selectedIngredients,
      _selectedDietaryRestriction,
      userMinutes: _selectedMinutes,
      userCulture: _selectedCulture,
      userEnergy: _selectedEnergy,
    );
    final recipesById = {for (final recipe in _visibleRecipes) recipe.id: recipe};
    return ranked
        .where((row) => recipesById.containsKey(row['id'].toString()))
        .map((row) => recipesById[row['id'].toString()]!)
        .toList();
  }

  Map<String, Set<String>> get _recipeIngredients => {
        for (final row in _allRecipeRows)
          row['id'].toString(): (row['ingredientSet'] as Set<String>? ?? {}),
      };
  List<Map<String, dynamic>> _allRecipeRows = [];
  List<String> get _availableIngredients => _allRecipeRows
      .expand((row) => row['ingredientSet'] as Set<String>? ?? <String>{})
      .toSet()
      .toList()
    ..sort();

  @override
  void initState() {
    super.initState();
    _initialize();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    try {
      await DatabaseHelper.initDatabase();
      final rows = await DatabaseHelper.getRecipes();
      _allRecipeRows = rows;
      final recipes = <KitchenRecipe>[];
      for (final row in rows) {
        recipes.add(await KitchenRecipe.fromDatabase(row));
      }
      if (mounted) {
        setState(() {
          _recipes = recipes;
          _visibleRecipes = recipes;
          _loading = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not load recipes: $error')),
        );
      }
    }
    await _refreshStatus();
  }

  void _onSearchChanged() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(
      const Duration(milliseconds: 250),
      _performSearch,
    );
  }

  Future<void> _performSearch() async {
    final generation = ++_searchGeneration;
    final query = _searchController.text.trim();

    if (query.isEmpty) {
      if (!mounted) return;
      setState(() {
        _visibleRecipes = _recipes;
        _searching = false;
      });
      return;
    }

    setState(() => _searching = true);
    try {
      final rows = await DatabaseHelper.searchRecipes(query);
      final matches = <KitchenRecipe>[];
      for (final row in rows) {
        matches.add(await KitchenRecipe.fromDatabase(row));
      }
      if (!mounted || generation != _searchGeneration) return;
      setState(() {
        _visibleRecipes = matches;
        _searching = false;
      });
    } catch (error) {
      if (!mounted || generation != _searchGeneration) return;
      setState(() => _searching = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Recipe search failed: $error')),
      );
    }
  }

  Future<void> _refreshStatus() async {
    try {
      final status = await _access.load();
      if (!mounted) return;
      setState(() => _status = status);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not read account status: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayRecipes = _displayRecipes;
    final starters = displayRecipes.where((recipe) => recipe.isStarter);
    final otherRecipes = displayRecipes.where((recipe) => !recipe.isStarter);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cooking Assistant'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Text(
                _isPremium
                    ? 'PREMIUM'
                    : '${_status.recipesUsedToday}/${_status.dailyLimit} TODAY',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          TextButton(
            key: const ValueKey('redeem-code'),
            onPressed: _isPremium ? null : _redeemCode,
            child: Text(_isPremium ? 'Unlocked' : 'Redeem code'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Text(
                'VIRTUAL KITCHEN',
                style: TextStyle(
                  color: Color(0xFFD85D3D),
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Find something\nto cook.',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: const Color(0xFF234C3B),
                  fontSize: 38,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Search by recipe, cuisine, ingredient, or dietary preference.',
                style: TextStyle(color: Color(0xFF666960), fontSize: 16),
              ),
              const SizedBox(height: 22),
              TextField(
                key: const ValueKey('recipe-search-field'),
                controller: _searchController,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Search recipes, e.g. rice, chicken, tomato...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear search',
                          onPressed: () => _searchController.clear(),
                          icon: const Icon(Icons.close),
                        ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFD9DED7)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ExpansionTile(
                key: const ValueKey('ingredient-picker'),
                title: Text(
                  _selectedIngredients.isEmpty
                      ? 'Match recipes to your ingredients'
                      : '${_selectedIngredients.length} ingredients selected',
                ),
                subtitle: const Text('Choose what you have on hand'),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      for (final ingredient in _availableIngredients)
                        FilterChip(
                          label: Text(ingredient),
                          selected: _selectedIngredients.contains(ingredient),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedIngredients.add(ingredient);
                              } else {
                                _selectedIngredients.remove(ingredient);
                              }
                            });
                          },
                        ),
                    ],
                  ),
                  if (_selectedIngredients.isNotEmpty)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () =>
                            setState(_selectedIngredients.clear),
                        child: const Text('Clear ingredients'),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Tune your match',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: const Color(0xFF234C3B),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _FilterDropdown<String?>(
                    label: 'Culture',
                    value: _selectedCulture,
                    items: [null, ..._availableCultures],
                    labelBuilder: (v) => v ?? 'Any culture',
                    onChanged: (v) => setState(() => _selectedCulture = v),
                  ),
                  _FilterDropdown<int?>(
                    label: 'Time I have',
                    value: _selectedMinutes,
                    items: const [null, 15, 30, 45, 60],
                    labelBuilder: (v) =>
                        v == null ? 'Any time' : '$v min or less',
                    onChanged: (v) => setState(() => _selectedMinutes = v),
                  ),
                  _FilterDropdown<String?>(
                    label: 'Energy',
                    value: _selectedEnergy,
                    items: const [null, 'low', 'medium', 'high'],
                    labelBuilder: (v) => v == null
                        ? 'Any energy'
                        : '${v[0].toUpperCase()}${v.substring(1)}',
                    onChanged: (v) => setState(() => _selectedEnergy = v),
                  ),
                  _FilterDropdown<String?>(
                    label: 'Diet',
                    value: _selectedDietaryRestriction,
                    items: [null, ..._availableDietaryTags],
                    labelBuilder: (v) => v ?? 'No restriction',
                    onChanged: (v) =>
                        setState(() => _selectedDietaryRestriction = v),
                  ),
                  if (_hasActiveFilters)
                    TextButton(
                      onPressed: () => setState(() {
                        _selectedCulture = null;
                        _selectedMinutes = null;
                        _selectedEnergy = null;
                        _selectedDietaryRestriction = null;
                      }),
                      child: const Text('Reset filters'),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.all(28),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_searching)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (displayRecipes.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 36),
                  child: Column(
                    children: [
                      const Text(
                        'No matching recipes found. Try different ingredients or clear the selection.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => _searchController.clear(),
                        child: const Text('Clear search'),
                      ),
                    ],
                  ),
                )
              else ...[
                Text(
                  _selectedIngredients.isEmpty
                      ? '${displayRecipes.length} ${displayRecipes.length == 1 ? 'recipe' : 'recipes'}'
                      : '${displayRecipes.length} matching recipes, ranked by ingredient compatibility',
                  style: const TextStyle(
                    color: Color(0xFF666960),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (_selectedIngredients.isNotEmpty) ...[
                  const _SectionHeading('Best ingredient matches', 'MATCHED'),
                  for (final recipe in displayRecipes)
                    _RecipeTile(
                      recipe: recipe,
                      onTap: () => _open(recipe),
                    ),
                ] else if (starters.isNotEmpty) ...[
                  const _SectionHeading('Easy recipes', 'STARTER'),
                  for (final recipe in starters)
                    _RecipeTile(
                      recipe: recipe,
                      onTap: () => _open(recipe),
                    ),
                ],
                if (otherRecipes.isNotEmpty) ...[
                    _SectionHeading(
                      'More recipes',
                      _isPremium ? 'UNLIMITED' : '7 PER DAY',
                    ),
                  for (final recipe in otherRecipes)
                    _RecipeTile(
                        recipe: recipe,
                        onTap: () => _open(recipe),
                      ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _redeemCode() async {
    final code = await showDialog<String>(
      context: context,
      builder: (_) => const _RedeemCodeDialog(),
    );
    if (!mounted || code == null) return;
    final accepted = await _access.redeemCode(code);
    await _refreshStatus();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          accepted
              ? 'Premium unlocked on this device.'
              : 'That redeem code is not valid.',
        ),
      ),
    );
  }

  Future<void> _open(KitchenRecipe recipe) async {
    // FR8: Freemium only gets the Interactive Virtual Kitchen on starter
    // recipes. Premium bypasses this entirely. This was previously missing
    // — any Freemium user could open any recipe's full cooking screen as
    // long as they were under the daily cap.
    if (!_isPremium && !recipe.isStarter) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'The Interactive Virtual Kitchen is free on starter recipes. '
            'Redeem a Premium code to unlock it for every recipe.',
          ),
        ),
      );
      return;
    }
    late final bool allowed;
    try {
      allowed = await _access.consumeRecipe(recipe.id);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not record daily recipe usage: $error')),
        );
      }
      return;
    }
    await _refreshStatus();
    if (!mounted) return;
    if (!allowed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'You have reached the 7-recipe daily limit. Redeem a Premium code for unlimited recipes.',
          ),
        ),
      );
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => VirtualKitchenCookingScreen(recipe: recipe),
      ),
    );
    await _refreshStatus();
  }
}

class _RedeemCodeDialog extends StatefulWidget {
  const _RedeemCodeDialog();

  @override
  State<_RedeemCodeDialog> createState() => _RedeemCodeDialogState();
}

class _RedeemCodeDialogState extends State<_RedeemCodeDialog> {
  final TextEditingController _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    icon: const Icon(Icons.card_giftcard),
    title: const Text('Redeem Premium'),
    content: TextField(
      controller: _controller,
      autofocus: true,
      textCapitalization: TextCapitalization.characters,
      autocorrect: false,
      decoration: InputDecoration(
        labelText: 'Redeem code',
        hintText: 'COOK-PREMIUM-001',
        errorText: _error,
      ),
      onSubmitted: (_) => _submit(),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(onPressed: _submit, child: const Text('Unlock')),
    ],
  );

  void _submit() {
    if (_controller.text.trim().isEmpty) {
      setState(() => _error = 'Enter a redeem code.');
      return;
    }
    Navigator.pop(context, _controller.text);
  }
}

class VirtualKitchenCookingScreen extends StatefulWidget {
  const VirtualKitchenCookingScreen({
    super.key,
    required this.recipe,
  });

  final KitchenRecipe recipe;

  @override
  State<VirtualKitchenCookingScreen> createState() =>
      _VirtualKitchenCookingScreenState();
}

class _VirtualKitchenCookingScreenState
    extends State<VirtualKitchenCookingScreen> {
  final FlutterTts _tts = FlutterTts();
  Timer? _timer;
  int _index = 0;
  int _remaining = 0;
  bool _timerComplete = false;
  bool _speaking = false;
  bool _paused = false;
  bool _resumeTimerAfterPause = false;
  bool _resumeSpeechAfterPause = false;

  KitchenStep get _step => widget.recipe.steps[_index];
  bool get _lastStep =>
      widget.recipe.steps.isEmpty || _index >= widget.recipe.steps.length - 1;

  @override
  void initState() {
    super.initState();
    _resetTimer();
    _tts.setCompletionHandler(() {
      if (mounted) setState(() => _speaking = false);
    });
    _tts.setCancelHandler(() {
      if (mounted) setState(() => _speaking = false);
    });
    _tts.setErrorHandler((_) {
      if (mounted) setState(() => _speaking = false);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    if (_speaking) {
      unawaited(
        _tts.stop().catchError((Object error) {
          debugPrint('Could not stop recipe narration during disposal: $error');
        }),
      );
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.recipe.steps.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.recipe.name)),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'No cooking steps are saved for this recipe yet.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Leave kitchen',
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(Icons.close),
        ),
        title: Text(widget.recipe.name),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 8),
            child: Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: (_index + 1) / widget.recipe.steps.length,
                    minHeight: 7,
                  ),
                ),
                const SizedBox(width: 12),
                Text('${_index + 1} / ${widget.recipe.steps.length}'),
              ],
            ),
          ),
          if (_paused)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Text(
                'Paused. Resume when you are ready; the next step will wait for you.',
                key: ValueKey('pause-status'),
                style: TextStyle(color: Color(0xFF666960)),
              ),
            ),
          Expanded(
            child: ListView(
              key: const ValueKey('kitchen-step-content'),
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              children: [
                _StepVisual(
                  icon: _step.icon,
                  color: widget.recipe.color,
                  number: _index + 1,
                ),
                const SizedBox(height: 22),
                Text(
                  'STEP ${(_index + 1).toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    color: Color(0xFFD85D3D),
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _step.title,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: const Color(0xFF234C3B),
                    fontSize: 30,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _step.instruction,
                  style: const TextStyle(
                    fontSize: 17,
                    height: 1.5,
                    color: Color(0xFF42463F),
                  ),
                ),
                if (_step.safetyTip != null) ...[
                  const SizedBox(height: 18),
                  _SafetyTip(_step.safetyTip!),
                ],
                if (_step.timerSeconds != null) ...[
                  const SizedBox(height: 16),
                  _TimerPanel(
                    remaining: _remaining,
                    running: _timer?.isActive ?? false,
                    complete: _timerComplete,
                    onToggle: _paused ? null : _toggleTimer,
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    IconButton.filledTonal(
                      tooltip: _speaking ? 'Stop narration' : 'Read this step',
                      onPressed: _paused
                          ? null
                          : _speaking
                          ? _stopSpeech
                          : _speak,
                      icon: Icon(
                        _speaking ? Icons.stop : Icons.volume_up_outlined,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'This step stays on screen until you choose Next step. Nothing advances automatically.',
                        style: TextStyle(color: Color(0xFF666960)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: Row(
                children: [
                  IconButton.outlined(
                    tooltip: 'Previous step',
                    onPressed: _paused || _index == 0 ? null : _previous,
                    icon: const Icon(Icons.arrow_back),
                  ),
                  const SizedBox(width: 12),
                  IconButton.filledTonal(
                    tooltip: _paused ? 'Resume cooking' : 'Pause cooking',
                    onPressed: _togglePause,
                    icon: Icon(_paused ? Icons.play_arrow : Icons.pause),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      key: const ValueKey('next-step'),
                      onPressed: _paused ? null : _next,
                      icon: Icon(_lastStep ? Icons.check : Icons.arrow_forward),
                      label: Text(_lastStep ? 'Finish cooking' : 'Next step'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF234C3B),
                        minimumSize: const Size.fromHeight(50),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _resetTimer() {
    if (widget.recipe.steps.isEmpty) {
      _remaining = 0;
      _timerComplete = false;
      return;
    }
    _remaining = _step.timerSeconds ?? 0;
    _timerComplete = false;
  }

  void _toggleTimer() {
    if (_timer?.isActive ?? false) {
      _timer?.cancel();
      setState(() {});
      return;
    }
    if (_timerComplete || _remaining == 0) {
      _remaining = _step.timerSeconds ?? 0;
      _timerComplete = false;
    }
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return timer.cancel();
      setState(() {
        if (_remaining <= 1) {
          _remaining = 0;
          _timerComplete = true;
          timer.cancel();
        } else {
          _remaining--;
        }
      });
    });
    setState(() {});
  }

  Future<void> _togglePause() async {
    if (!_paused) {
      _resumeTimerAfterPause = _timer?.isActive ?? false;
      _timer?.cancel();
      _resumeSpeechAfterPause = _speaking;
      setState(() => _paused = true);
      if (_resumeSpeechAfterPause) {
        try {
          final paused = await _tts.pause();
          if (paused != true && paused != 1) {
            await _stopSpeech();
            _resumeSpeechAfterPause = false;
          }
        } catch (error) {
          await _stopSpeech();
          _resumeSpeechAfterPause = false;
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Narration could not pause: $error')),
            );
          }
        }
      }
      return;
    }

    final resumeTimer = _resumeTimerAfterPause;
    final resumeSpeech = _resumeSpeechAfterPause;
    _resumeTimerAfterPause = false;
    _resumeSpeechAfterPause = false;
    setState(() => _paused = false);
    if (resumeTimer) _toggleTimer();
    if (resumeSpeech) unawaited(_speak());
  }

  Future<void> _speak() async {
    try {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.45);
      if (mounted) setState(() => _speaking = true);
      await _tts.speak('${_step.title}. ${_step.instruction}');
    } catch (error) {
      if (mounted) {
        setState(() => _speaking = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Speech is not available on this device: $error'),
          ),
        );
      }
    }
  }

  Future<void> _stopSpeech() async {
    try {
      await _tts.stop();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not stop narration: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _speaking = false);
    }
  }

  void _previous() {
    _timer?.cancel();
    unawaited(_stopSpeech());
    setState(() {
      _index--;
      _paused = false;
      _resetTimer();
    });
  }

  void _next() {
    _timer?.cancel();
    unawaited(_stopSpeech());
    if (_lastStep) return Navigator.pop(context);
    setState(() {
      _index++;
      _paused = false;
      _resetTimer();
    });
  }
}

/// A small labelled dropdown used for the Culture / Time / Energy / Diet
/// filters on the home screen. Generic so it works for both String? and
/// int? options with one shared widget.
class _FilterDropdown<T> extends StatelessWidget {
  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.labelBuilder,
    required this.onChanged,
    super.key,
  });

  final String label;
  final T value;
  final List<T> items;
  final String Function(T) labelBuilder;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 168,
    child: DropdownButtonFormField<T>(
      value: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD9DED7)),
        ),
      ),
      items: [
        for (final item in items)
          DropdownMenuItem<T>(
            value: item,
            child: Text(
              labelBuilder(item),
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
      onChanged: (selected) => onChanged(selected as T),
    ),
  );
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading(this.title, this.trailing);
  final String title;
  final String trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 18, bottom: 10),
    child: Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: const Color(0xFF234C3B)),
          ),
        ),
        Text(
          trailing,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ],
    ),
  );
}

class _RecipeTile extends StatelessWidget {
  const _RecipeTile({
    required this.recipe,
    required this.onTap,
  });
  final KitchenRecipe recipe;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: recipe.color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(recipe.icon, color: recipe.color, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: recipe.color.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            recipe.culture,
                            style: TextStyle(
                              color: recipe.color,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.schedule,
                          size: 13,
                          color: Color(0xFF77796F),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${recipe.minutes} min',
                          style: const TextStyle(
                            color: Color(0xFF77796F),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: Color(0xFFBFC4BA),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _StepVisual extends StatelessWidget {
  const _StepVisual({
    required this.icon,
    required this.color,
    required this.number,
  });
  final IconData icon;
  final Color color;
  final int number;

  @override
  Widget build(BuildContext context) => Container(
    height: 190,
    decoration: BoxDecoration(
      color: color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Stack(
      alignment: Alignment.center,
      children: [
        Positioned(
          right: 18,
          top: 10,
          child: Text(
            number.toString().padLeft(2, '0'),
            style: TextStyle(
              color: color.withOpacity(0.22),
              fontSize: 64,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        Container(
          width: 112,
          height: 112,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.85),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 58, color: color),
        ),
      ],
    ),
  );
}

class _SafetyTip extends StatelessWidget {
  const _SafetyTip(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF0D8),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.health_and_safety_outlined, color: Color(0xFF9B5A18)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Color(0xFF68471F), height: 1.35),
          ),
        ),
      ],
    ),
  );
}

class _TimerPanel extends StatelessWidget {
  const _TimerPanel({
    required this.remaining,
    required this.running,
    required this.complete,
    required this.onToggle,
  });
  final int remaining;
  final bool running;
  final bool complete;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    final time =
        '${(remaining ~/ 60).toString().padLeft(2, '0')}:${(remaining % 60).toString().padLeft(2, '0')}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFE9EEE5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.timer_outlined, color: Color(0xFF234C3B)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              complete ? 'Timer complete' : 'Optional timer  $time',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          TextButton.icon(
            onPressed: onToggle,
            icon: Icon(running ? Icons.pause : Icons.play_arrow),
            label: Text(
              running
                  ? 'Pause'
                  : complete
                  ? 'Restart'
                  : 'Start',
            ),
          ),
        ],
      ),
    );
  }
}
