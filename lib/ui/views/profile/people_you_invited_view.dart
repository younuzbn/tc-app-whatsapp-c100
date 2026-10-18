import 'package:flutter/material.dart';

import '../../../services/referral_service.dart';
import '../../theme/win_theme.dart';

class PeopleYouInvitedView extends StatefulWidget {
  const PeopleYouInvitedView({super.key});

  @override
  State<PeopleYouInvitedView> createState() => _PeopleYouInvitedViewState();
}

class _PeopleYouInvitedViewState extends State<PeopleYouInvitedView> {
  static const _bgAsset = 'assets/profile_bg.jpeg';

  final _service = const ReferralService();
  bool _loading = true;
  String? _error;
  int _total = 0;
  List<InvitedPerson> _invites = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await _service.listMyInvites();
      if (!mounted) return;
      setState(() {
        _total = result.total;
        _invites = result.invites;
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

  @override
  Widget build(BuildContext context) {
    return WinStatusBar(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: WinTheme.bg),
            const DecoratedBox(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(_bgAsset),
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 6, 16, 8),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).maybePop(),
                          icon: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 20,
                          ),
                          color: Colors.white,
                        ),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'People you invited',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(height: 6),
                              SizedBox(
                                width: 46,
                                height: 4,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: WinTheme.green,
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0x33101820),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0x554ADE80),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '$_total',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.person_rounded,
                                color: WinTheme.green,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _loading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: WinTheme.green,
                            ),
                          )
                        : RefreshIndicator(
                            color: WinTheme.green,
                            onRefresh: _load,
                            child: ListView(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                              children: [
                                if (_error != null)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Text(
                                      _error!,
                                      style: const TextStyle(
                                        color: Colors.redAccent,
                                      ),
                                    ),
                                  ),
                                if (_invites.isEmpty && _error == null)
                                  const Padding(
                                    padding: EdgeInsets.only(top: 48),
                                    child: Center(
                                      child: Text(
                                        'No one has joined with your invite code yet.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: WinTheme.muted,
                                        ),
                                      ),
                                    ),
                                  ),
                                ..._invites.map((person) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: WinGlass(
                                      borderRadius: 14,
                                      color: const Color(0x33101820),
                                      borderColor: const Color(0x334ADE80),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 16,
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                person.displayPhoneNumber,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 15,
                                                ),
                                              ),
                                            ),
                                            Text(
                                              WinTheme.monthDay(person.joinedAt),
                                              style: const TextStyle(
                                                color: WinTheme.muted,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
