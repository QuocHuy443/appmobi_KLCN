import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../core/app_colors.dart';
import '../services/patient_api_service.dart';
import '../widgets/request_error.dart';
import 'appointment_screen.dart';

class ArticlesScreen extends StatefulWidget {
  const ArticlesScreen({super.key, this.initialCategory});

  final String? initialCategory;

  @override
  State<ArticlesScreen> createState() => _ArticlesScreenState();
}

class _ArticlesScreenState extends State<ArticlesScreen> {
  final PatientApiService _api = PatientApiService();
  final TextEditingController _searchController = TextEditingController();
  bool _loading = true;
  String? _error;
  late String? _activeCategory = widget.initialCategory;
  List<Map<String, dynamic>> _articles = [];
  List<Map<String, dynamic>> _categories = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _api.getPublicArticles(
        category: _activeCategory,
      );
      if (!mounted) return;
      setState(() {
        _articles = List<Map<String, dynamic>>.from(
          (data['articles'] as List? ?? [])
              .map((e) => Map<String, dynamic>.from(e as Map)),
        );
        _categories = List<Map<String, dynamic>>.from(
          (data['categories'] as List? ?? [])
              .map((e) => Map<String, dynamic>.from(e as Map)),
        );
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredArticles {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return _articles;
    return _articles.where((a) {
      final text = [
        a['title'],
        a['summary'],
        a['category_name'],
        a['author'],
      ].map((e) => (e ?? '').toString().toLowerCase()).join(' ');
      return text.contains(q);
    }).toList();
  }

  void _openDetail(Map<String, dynamic> article) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ArticleDetailScreen(
          slug: (article['slug'] ?? '').toString(),
          initialArticle: article,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredArticles;
    final featured = filtered.isNotEmpty ? filtered.first : null;
    final remaining =
        filtered.length > 1 ? filtered.sublist(1) : <Map<String, dynamic>>[];

    return Scaffold(
      backgroundColor: AppColors.slate50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          'Tin tức và Cẩm nang Y khoa',
          style: TextStyle(
            color: AppColors.slate800,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Làm mới bài viết',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh, color: AppColors.medical600),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Tìm bài viết, cẩm nang sức khỏe, triệu chứng...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.slate200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.slate200),
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (_categories.isNotEmpty)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ChoiceChip(
                      label: const Text('Tất cả'),
                      selected: _activeCategory == null,
                      onSelected: (_) {
                        setState(() => _activeCategory = null);
                        _load();
                      },
                    ),
                    const SizedBox(width: 8),
                    ..._categories.map((cat) {
                      final slug = (cat['slug'] ?? '').toString();
                      final name = (cat['name'] ?? '').toString();
                      final count = cat['count'] ?? 0;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text('$name ($count)'),
                          selected: _activeCategory == slug,
                          onSelected: (_) {
                            setState(
                              () => _activeCategory =
                                  _activeCategory == slug ? null : slug,
                            );
                            _load();
                          },
                        ),
                      );
                    }),
                  ],
                ),
              ),
            const SizedBox(height: 14),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              RequestError(message: _error!, onRetry: _load)
            else if (filtered.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.slate200),
                ),
                child: const Text(
                  'Chưa có bài viết nào trong chuyên mục này.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.slate600),
                ),
              )
            else ...[
              if (featured != null) ...[
                _buildFeaturedCard(featured),
                const SizedBox(height: 14),
              ],
              ...remaining.map(_buildArticleRowCard),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedCard(Map<String, dynamic> art) {
    final imgUrl = PatientApiService.mediaUrl(art['image']);
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => _openDetail(art),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.slate200),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 165,
              width: double.infinity,
              color: AppColors.medical600,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (imgUrl != null)
                    Image.network(
                      imgUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Center(
                        child: FaIcon(
                          FontAwesomeIcons.newspaper,
                          color: Colors.white54,
                          size: 42,
                        ),
                      ),
                    )
                  else
                    const Center(
                      child: FaIcon(
                        FontAwesomeIcons.newspaper,
                        color: Colors.white54,
                        size: 42,
                      ),
                    ),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade400,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        '★ BÀI VIẾT NỔI BẬT',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppColors.slate900,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.medical50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${art['category_name'] ?? 'Cẩm Nang Y Tế'}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.medical700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${art['title'] ?? ''}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.slate800,
                      height: 1.3,
                    ),
                  ),
                  if ((art['summary'] ?? '').toString().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      '${art['summary']}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.slate600,
                        height: 1.4,
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(
                        Icons.person_outline,
                        size: 14,
                        color: AppColors.slate400,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${art['author'] ?? 'H2T Healthcare'} • ${art['published_at'] ?? ''}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AppColors.slate500,
                          ),
                        ),
                      ),
                      Text(
                        '${art['views'] ?? 0} lượt xem',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.slate400,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArticleRowCard(Map<String, dynamic> art) {
    final imgUrl = PatientApiService.mediaUrl(art['image']);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openDetail(art),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.slate200),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 78,
                  height: 78,
                  color: AppColors.medical50,
                  child: imgUrl != null
                      ? Image.network(
                          imgUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.article_outlined,
                            color: AppColors.medical600,
                          ),
                        )
                      : const Icon(
                          Icons.article_outlined,
                          color: AppColors.medical600,
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.medical50,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        '${art['category_name'] ?? 'Tin tức Y tế'}',
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.medical700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${art['title'] ?? ''}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.slate800,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${art['published_at'] ?? ''} • ${art['read_time'] ?? 5} phút đọc • ${art['views'] ?? 0} lượt xem',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.slate400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ArticleDetailScreen extends StatefulWidget {
  const ArticleDetailScreen({
    super.key,
    required this.slug,
    this.initialArticle,
  });

  final String slug;
  final Map<String, dynamic>? initialArticle;

  @override
  State<ArticleDetailScreen> createState() => _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends State<ArticleDetailScreen> {
  final PatientApiService _api = PatientApiService();
  late Map<String, dynamic>? _article = widget.initialArticle;
  List<Map<String, dynamic>> _related = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (widget.slug.isEmpty) {
      setState(() => _loading = false);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _api.getPublicArticleDetail(widget.slug);
      if (!mounted) return;
      setState(() {
        if (data['article'] is Map) {
          _article = Map<String, dynamic>.from(data['article'] as Map);
        }
        _related = List<Map<String, dynamic>>.from(
          (data['related_articles'] as List? ?? [])
              .map((e) => Map<String, dynamic>.from(e as Map)),
        );
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  String _formatReadableContent(String raw) {
    if (raw.isEmpty) return '';
    return raw
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</p>', caseSensitive: false), '\n\n')
        .replaceAll(RegExp(r'</h[1-6]>', caseSensitive: false), '\n\n')
        .replaceAll(RegExp(r'<li[^>]*>', caseSensitive: false), '• ')
        .replaceAll(RegExp(r'</li>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<[^>]+>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', ' và ')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
  }

  @override
  Widget build(BuildContext context) {
    final art = _article;
    final imgUrl = PatientApiService.mediaUrl(art?['image']);
    final content = _formatReadableContent((art?['content'] ?? '').toString());
    final summary = (art?['summary'] ?? '').toString().trim();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Text(
          '${art?['category_name'] ?? 'Bài viết Y khoa'}',
          style: const TextStyle(
            color: AppColors.slate800,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: art == null && _loading
          ? const Center(child: CircularProgressIndicator())
          : art == null && _error != null
              ? Center(child: RequestError(message: _error!, onRetry: _load))
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    if (imgUrl != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: SizedBox(
                          height: 190,
                          width: double.infinity,
                          child: Image.network(
                            imgUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: AppColors.medical50,
                              child: const Icon(
                                Icons.article_outlined,
                                size: 48,
                                color: AppColors.medical600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.medical50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${art?['category_name'] ?? 'Cẩm Nang Y Tế'}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.medical700,
                            ),
                          ),
                        ),
                        Text(
                          '${art?['published_at'] ?? ''} • ${art?['read_time'] ?? 5} phút đọc • ${art?['views'] ?? 0} lượt xem',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.slate500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${art?['title'] ?? ''}',
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                        color: AppColors.slate900,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const CircleAvatar(
                          radius: 15,
                          backgroundColor: AppColors.medical100,
                          child: Icon(
                            Icons.verified_user,
                            size: 16,
                            color: AppColors.medical700,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '${art?['author'] ?? 'H2T Healthcare'} (${art?['author_title'] ?? 'Ban Biên Tập Y Khoa'})',
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.slate700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (summary.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.slate50,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.slate200),
                        ),
                        child: Text(
                          summary,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            fontStyle: FontStyle.italic,
                            color: AppColors.slate700,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    if (_loading && content.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else
                      SelectableText(
                        content.isNotEmpty
                            ? content
                            : 'Đang cập nhật nội dung chi tiết bài viết.',
                        style: const TextStyle(
                          fontSize: 15,
                          color: AppColors.slate800,
                          height: 1.65,
                        ),
                      ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.medical600, AppColors.medical700],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Cần bác sĩ chuyên khoa tư vấn?',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14.5,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Đặt lịch khám trực tuyến để được ưu tiên tiếp đón.',
                                  style: TextStyle(
                                    color: AppColors.medical50,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppColors.medical700,
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const AppointmentScreen(initialTab: 0),
                                ),
                              );
                            },
                            child: const Text(
                              'Đặt lịch',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_related.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      const Text(
                        'Bài viết liên quan',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppColors.slate800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ..._related.map(
                        (rel) => Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: const BorderSide(color: AppColors.slate200),
                          ),
                          child: ListTile(
                            title: Text(
                              '${rel['title'] ?? ''}',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13.5,
                              ),
                            ),
                            subtitle: Text(
                              '${rel['category_name'] ?? ''} • ${rel['published_at'] ?? ''}',
                              style: const TextStyle(fontSize: 11.5),
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ArticleDetailScreen(
                                    slug: (rel['slug'] ?? '').toString(),
                                    initialArticle: rel,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
    );
  }
}
