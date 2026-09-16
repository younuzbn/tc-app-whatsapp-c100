import 'package:flutter/material.dart';

import '../home/game_chat_data.dart';
import 'admin_game_settings_view.dart';
import 'admin_position_data_view.dart';
import 'admin_result_editor_view.dart';
import 'admin_ticket_data_view.dart';
import 'admin_time_and_count_settings_view.dart';

class AdminGameChatOptionsView extends StatefulWidget {
  const AdminGameChatOptionsView({super.key, this.game});

  final GameChatData? game;

  @override
  State<AdminGameChatOptionsView> createState() =>
      _AdminGameChatOptionsViewState();
}

class _AdminGameChatOptionsViewState extends State<AdminGameChatOptionsView> {
  late GameChatData _game;

  @override
  void initState() {
    super.initState();
    _game = widget.game ?? gameChats.first;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Game Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Select game',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: _game.timeSlot,
                items: [
                  for (final game in gameChats)
                    DropdownMenuItem<String>(
                      value: game.timeSlot,
                      child: Text(game.name),
                    ),
                ],
                onChanged: (slot) {
                  if (slot == null) return;
                  setState(() => _game = gameForTimeSlot(slot));
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          _OptionTile(
            title: 'Game Settings',
            subtitle: 'Enable/disable and stop booking for ${_game.name}',
            icon: Icons.settings,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => AdminGameSettingsView(game: _game),
                ),
              );
            },
          ),
          _OptionTile(
            title: 'Time And Count Settings',
            subtitle:
                'Times, limits, and optional second yellow banner on the sale chat',
            icon: Icons.schedule,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => AdminTimeAndCountSettingsView(
                    timeSlotFilter: _game.timeSlot,
                    gameTitle: _game.name,
                  ),
                ),
              );
            },
          ),
          _OptionTile(
            title: 'Ticket Data',
            subtitle: 'Rate settings used for customer sales',
            icon: Icons.confirmation_num_outlined,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => AdminTicketDataView(game: _game),
                ),
              );
            },
          ),
          _OptionTile(
            title: 'Position Data',
            subtitle: 'Update position rate settings',
            icon: Icons.grid_on_outlined,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => AdminPositionDataView(game: _game),
                ),
              );
            },
          ),
          _OptionTile(
            title: 'Add Result',
            subtitle: 'Publish result and send to customers',
            icon: Icons.add_circle_outline,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => AdminResultEditorView(
                    game: _game,
                    editMode: false,
                  ),
                ),
              );
            },
          ),
          _OptionTile(
            title: 'Edit Result',
            subtitle: 'Edit existing result and resend update',
            icon: Icons.edit_outlined,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => AdminResultEditorView(
                    game: _game,
                    editMode: true,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
