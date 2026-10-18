import 'package:flutter/material.dart';

import '../../config/app_config.dart';
import '../../services/android_image_picker.dart';
import '../../services/page_content_defaults.dart';
import '../../services/page_content_service.dart';

class PageContentHost extends StatefulWidget {
  const PageContentHost({
    super.key,
    required this.pageKey,
    required this.editing,
    required this.builder,
  });

  final String pageKey;
  final bool editing;
  final Widget Function(BuildContext context, Map<String, String> data) builder;

  @override
  State<PageContentHost> createState() => _PageContentHostState();
}

class _PageContentHostState extends State<PageContentHost> {
  late Map<String, String> _data = mergePageData(widget.pageKey, null);
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    PageContentService.instance.revision.addListener(_onRevision);
    _load();
  }

  @override
  void dispose() {
    PageContentService.instance.revision.removeListener(_onRevision);
    super.dispose();
  }

  void _onRevision() {
    final cached = PageContentService.instance.cached(widget.pageKey);
    if (cached == null || !mounted) return;
    setState(() => _data = cached.data);
  }

  Future<void> _load() async {
    final cached = PageContentService.instance.cached(widget.pageKey);
    if (cached != null && mounted) {
      setState(() => _data = cached.data);
    }
    final next = await PageContentService.instance.load(widget.pageKey);
    if (!mounted) return;
    setState(() => _data = next.data);
  }

  void _onUpdated(PageContentSnapshot snapshot) {
    if (!mounted) return;
    setState(() {
      _data = snapshot.data;
      _saving = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PageContentScope(
      pageKey: widget.pageKey,
      data: _data,
      editing: widget.editing,
      saving: _saving,
      onUpdated: (snapshot) {
        setState(() => _saving = true);
        _onUpdated(snapshot);
      },
      child: widget.builder(context, _data),
    );
  }
}

class PageContentScope extends InheritedWidget {
  const PageContentScope({
    super.key,
    required this.pageKey,
    required this.data,
    required this.editing,
    required this.saving,
    required this.onUpdated,
    required super.child,
  });

  final String pageKey;
  final Map<String, String> data;
  final bool editing;
  final bool saving;
  final ValueChanged<PageContentSnapshot> onUpdated;

  String t(String field) => data[field] ?? '';

  static PageContentScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<PageContentScope>();
    assert(scope != null, 'PageContentScope not found');
    return scope!;
  }

  static PageContentScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<PageContentScope>();
  }

  @override
  bool updateShouldNotify(PageContentScope oldWidget) {
    return pageKey != oldWidget.pageKey ||
        editing != oldWidget.editing ||
        saving != oldWidget.saving ||
        data != oldWidget.data;
  }
}

class PageText extends StatelessWidget {
  const PageText(
    this.field, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.hideIfEmpty = false,
    this.placeholder = 'Tap to edit',
    this.maxLength = 400,
  });

  final String field;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool hideIfEmpty;
  final String placeholder;
  final int maxLength;

  @override
  Widget build(BuildContext context) {
    final scope = PageContentScope.of(context);
    final value = scope.t(field);
    if (value.isEmpty && hideIfEmpty && !scope.editing) {
      return const SizedBox.shrink();
    }
    final shown = value.isEmpty ? placeholder : value;
    final child = Text(
      shown,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      style: value.isEmpty
          ? (style ?? const TextStyle()).copyWith(
              fontStyle: FontStyle.italic,
              color: (style?.color ?? Colors.white).withValues(alpha: 0.55),
            )
          : style,
    );
    if (!scope.editing) return child;
    return _EditWrap(
      onTap: () => _editText(context, scope, field, value, maxLength),
      child: child,
    );
  }
}

class PageImage extends StatelessWidget {
  const PageImage({
    super.key,
    required this.field,
    required this.assetFallback,
    this.height,
    this.width,
    this.fit = BoxFit.contain,
  });

  final String field;
  final String assetFallback;
  final double? height;
  final double? width;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final scope = PageContentScope.of(context);
    final url = AppConfig.mediaUrl(scope.t(field));
    final image = url.isEmpty
        ? Image.asset(assetFallback, height: height, width: width, fit: fit)
        : Image.network(
            url,
            height: height,
            width: width,
            fit: fit,
            errorBuilder: (context, error, stackTrace) => Image.asset(
              assetFallback,
              height: height,
              width: width,
              fit: fit,
            ),
          );
    if (!scope.editing) return image;
    return _EditWrap(
      onTap: () => _editImage(context, scope, field),
      child: Stack(
        alignment: Alignment.topRight,
        children: [
          image,
          const Padding(
            padding: EdgeInsets.all(6),
            child: CircleAvatar(
              radius: 12,
              backgroundColor: Color(0xCC2563EB),
              child: Icon(Icons.edit_rounded, size: 14, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class PageIcon extends StatelessWidget {
  const PageIcon(
    this.field, {
    super.key,
    required this.color,
    required this.size,
  });

  final String field;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scope = PageContentScope.of(context);
    final icon = Icon(pageIconData(scope.t(field)), color: color, size: size);
    if (!scope.editing) return icon;
    return _EditWrap(
      onTap: () => _editIcon(context, scope, field),
      child: icon,
    );
  }
}

class AutoGeneratedCodeBox extends StatelessWidget {
  const AutoGeneratedCodeBox({
    super.key,
    required this.code,
    required this.scale,
    this.onCopy,
  });

  final String code;
  final double scale;
  final VoidCallback? onCopy;

  @override
  Widget build(BuildContext context) {
    final scope = PageContentScope.maybeOf(context);
    final editing = scope?.editing == true;
    final shown = editing ? 'AUTO CODE' : code.toUpperCase();

    final box = Material(
      color: editing ? const Color(0xFFE8F1FF) : Colors.white,
      borderRadius: BorderRadius.circular(10),
      elevation: 1,
      child: InkWell(
        onTap: editing || shown == '—' ? null : onCopy,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: 12 * scale,
            vertical: 7 * scale,
          ),
          decoration: BoxDecoration(
            border: Border.all(
              color: editing ? const Color(0xFF2563EB) : const Color(0xFFE5E7EB),
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  shown,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: editing
                        ? const Color(0xFF1D4ED8)
                        : const Color(0xFF111827),
                    fontSize: 18 * scale,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
              if (!editing) ...[
                SizedBox(width: 8 * scale),
                Icon(
                  Icons.copy_rounded,
                  color: const Color(0xFF6B7280),
                  size: 17 * scale,
                ),
              ],
            ],
          ),
        ),
      ),
    );

    if (!editing) return box;
    return Column(
      children: [
        box,
        SizedBox(height: 6 * scale),
        Text(
          'Auto generated — each user sees their own invite code',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: const Color(0xFF2563EB),
            fontSize: 11 * scale,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class PageEditBanner extends StatelessWidget {
  const PageEditBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = PageContentScope.maybeOf(context);
    if (scope?.editing != true) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1D4ED8).withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF60A5FA)),
      ),
      child: Text(
        scope!.saving
            ? 'Saving…'
            : 'Tap any text, icon, or image to edit. Users see the saved version next time they open this page.',
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Color(0xFF93C5FD),
          fontSize: 12,
          fontWeight: FontWeight.w600,
          height: 1.3,
        ),
      ),
    );
  }
}

class _EditWrap extends StatelessWidget {
  const _EditWrap({required this.onTap, required this.child});

  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: child,
      ),
    );
  }
}

Future<void> _editText(
  BuildContext context,
  PageContentScope scope,
  String field,
  String current,
  int maxLength,
) async {
  final controller = TextEditingController(text: current);
  final next = await showDialog<String>(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: const Color(0xFF171C23),
        title: const Text(
          'Edit text',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
        ),
        content: TextField(
          controller: controller,
          maxLines: 5,
          minLines: 1,
          maxLength: maxLength,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Enter text',
            hintStyle: TextStyle(color: Color(0xFF8B95A1)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      );
    },
  );
  controller.dispose();
  if (next == null || next == current || !context.mounted) return;
  await _persist(
    context,
    scope,
    () => PageContentService.instance.saveText(
      key: scope.pageKey,
      field: field,
      value: next,
    ),
  );
}

Future<void> _editImage(
  BuildContext context,
  PageContentScope scope,
  String field,
) async {
  try {
    final path = await AndroidImagePicker.pickImage();
    if (path == null || path.isEmpty || !context.mounted) return;
    await _persist(
      context,
      scope,
      () => PageContentService.instance.saveImage(
        key: scope.pageKey,
        field: field,
        path: path,
      ),
    );
  } catch (error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
    );
  }
}

Future<void> _editIcon(
  BuildContext context,
  PageContentScope scope,
  String field,
) async {
  final selected = await showModalBottomSheet<String>(
    context: context,
    backgroundColor: const Color(0xFF171C23),
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Choose icon',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final entry in kPageIconChoices.entries)
                    InkWell(
                      onTap: () => Navigator.pop(context, entry.key),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: scope.t(field) == entry.key
                                ? const Color(0xFF60A5FA)
                                : const Color(0xFF334155),
                          ),
                        ),
                        child: Icon(entry.value, color: Colors.white),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
  if (selected == null || selected == scope.t(field) || !context.mounted) {
    return;
  }
  await _persist(
    context,
    scope,
    () => PageContentService.instance.saveText(
      key: scope.pageKey,
      field: field,
      value: selected,
    ),
  );
}

Future<void> _persist(
  BuildContext context,
  PageContentScope scope,
  Future<PageContentSnapshot> Function() save,
) async {
  try {
    final next = await save();
    if (!context.mounted) return;
    scope.onUpdated(next);
  } catch (error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
    );
  }
}
