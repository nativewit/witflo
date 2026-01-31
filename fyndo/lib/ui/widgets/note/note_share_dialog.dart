// ═══════════════════════════════════════════════════════════════════════════
// FYNDO - Zero-Trust Notes OS
// Note Share Dialog - Share Notes, Notebooks, and Vaults
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fyndo_app/core/agentic/fyndo_keys.dart';
import 'package:fyndo_app/ui/theme/fyndo_theme.dart';

/// Type of item being shared.
enum ShareItemType { note, notebook, vault }

/// Dialog for sharing notes, notebooks, or vaults.
class ShareDialog extends StatefulWidget {
  /// Item name.
  final String itemName;

  /// Item type.
  final ShareItemType itemType;

  /// Callback when share link is generated.
  final Future<String> Function()? onGenerateLink;

  /// Callback when sharing with user.
  final void Function(String email, String role)? onShareWithUser;

  const ShareDialog({
    super.key,
    required this.itemName,
    required this.itemType,
    this.onGenerateLink,
    this.onShareWithUser,
  });

  /// Shows the share dialog.
  static Future<void> show(
    BuildContext context, {
    required String itemName,
    required ShareItemType itemType,
    Future<String> Function()? onGenerateLink,
    void Function(String email, String role)? onShareWithUser,
  }) {
    return showDialog(
      context: context,
      builder: (context) => ShareDialog(
        itemName: itemName,
        itemType: itemType,
        onGenerateLink: onGenerateLink,
        onShareWithUser: onShareWithUser,
      ),
    );
  }

  @override
  State<ShareDialog> createState() => _ShareDialogState();
}

class _ShareDialogState extends State<ShareDialog> {
  final _emailController = TextEditingController();
  String _selectedRole = 'viewer';
  String? _shareLink;
  bool _isGeneratingLink = false;
  bool _isSharing = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _generateLink() async {
    if (widget.onGenerateLink == null) return;

    setState(() => _isGeneratingLink = true);

    try {
      final link = await widget.onGenerateLink!();
      setState(() => _shareLink = link);
    } finally {
      setState(() => _isGeneratingLink = false);
    }
  }

  void _shareWithUser() {
    if (_emailController.text.isEmpty) return;
    if (widget.onShareWithUser == null) return;

    setState(() => _isSharing = true);

    widget.onShareWithUser!(_emailController.text.trim(), _selectedRole);

    _emailController.clear();
    setState(() => _isSharing = false);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Invitation sent')));
  }

  void _copyLink() {
    if (_shareLink == null) return;
    Clipboard.setData(ClipboardData(text: _shareLink!));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Link copied to clipboard')));
  }

  String get _itemTypeLabel {
    switch (widget.itemType) {
      case ShareItemType.note:
        return 'note';
      case ShareItemType.notebook:
        return 'notebook';
      case ShareItemType.vault:
        return 'vault';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480),
        padding: const EdgeInsets.all(FyndoTheme.paddingLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.share, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Share $_itemTypeLabel',
                        style: theme.textTheme.titleLarge,
                      ),
                      Text(
                        widget.itemName,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Share with user section
            Text('Share with people', style: theme.textTheme.titleSmall),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    key: FyndoKeys.inputShareEmail,
                    controller: _emailController,
                    decoration: const InputDecoration(
                      hintText: 'Enter email address',
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: DropdownButton<String>(
                    key: FyndoKeys.dropdownShareRole,
                    value: _selectedRole,
                    underline: const SizedBox(),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    items: const [
                      DropdownMenuItem(
                        value: 'viewer',
                        child: Text('Can view'),
                      ),
                      DropdownMenuItem(
                        value: 'editor',
                        child: Text('Can edit'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedRole = value);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                key: FyndoKeys.btnShareInvite,
                onPressed: _isSharing ? null : _shareWithUser,
                icon: _isSharing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.person_add, size: 18),
                label: const Text('Invite'),
              ),
            ),

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 24),

            // Link sharing section
            Text('Get shareable link', style: theme.textTheme.titleSmall),
            const SizedBox(height: 12),
            if (_shareLink != null) ...[
              Container(
                padding: const EdgeInsets.all(FyndoTheme.padding),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  border: Border.all(color: theme.dividerColor),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _shareLink!,
                        style: theme.textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      key: FyndoKeys.btnShareCopyLink,
                      icon: const Icon(Icons.copy, size: 18),
                      onPressed: _copyLink,
                      tooltip: 'Copy link',
                    ),
                  ],
                ),
              ),
            ] else ...[
              OutlinedButton.icon(
                key: FyndoKeys.btnShareGenerateLink,
                onPressed: _isGeneratingLink ? null : _generateLink,
                icon: _isGeneratingLink
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.link, size: 18),
                label: const Text('Generate link'),
              ),
            ],

            const SizedBox(height: 24),

            // Security notice
            Container(
              padding: const EdgeInsets.all(FyndoTheme.padding),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(
                  alpha: 0.2,
                ),
                border: Border.all(color: theme.colorScheme.primary),
              ),
              child: Row(
                children: [
                  Icon(Icons.lock, size: 16, color: theme.colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Shared content is end-to-end encrypted. '
                      'Only people you share with can read it.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                key: FyndoKeys.btnShareDone,
                onPressed: () => Navigator.pop(context),
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
