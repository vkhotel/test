import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../domain/entities/discovered_host.dart';
import '../controllers/connection_notifier.dart';

/// Modal sheet shown from the Home screen's Connect button: scans the LAN
/// for AeroTouch-compatible receivers and lets the user tap one to connect,
/// with a manual IP fallback for networks where broadcast discovery is
/// blocked (some corporate/guest WiFi networks isolate clients).
class DiscoveredHostsSheet extends ConsumerStatefulWidget {
  const DiscoveredHostsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const DiscoveredHostsSheet(),
    );
  }

  @override
  ConsumerState<DiscoveredHostsSheet> createState() => _DiscoveredHostsSheetState();
}

class _DiscoveredHostsSheetState extends ConsumerState<DiscoveredHostsSheet> {
  List<DiscoveredHost> _hosts = [];
  bool _isScanning = true;
  String? _errorText;
  String? _connectingKey;
  StreamSubscription<List<DiscoveredHost>>? _sub;
  bool _showManualEntry = false;

  final _manualIpController = TextEditingController();
  final _manualPortController = TextEditingController(
    text: '${AppConstants.defaultServerPort}',
  );

  @override
  void initState() {
    super.initState();
    _startScan();
  }

  void _startScan() {
    _sub?.cancel();
    setState(() {
      _isScanning = true;
      _hosts = [];
      _errorText = null;
    });
    _sub = ref.read(connectionNotifierProvider.notifier).discoverHosts().listen(
      (hosts) {
        if (!mounted) return;
        setState(() => _hosts = hosts);
      },
      onDone: () {
        if (!mounted) return;
        setState(() => _isScanning = false);
      },
      onError: (Object _) {
        if (!mounted) return;
        setState(() {
          _isScanning = false;
          _errorText = 'Discovery failed on this network.';
        });
      },
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    _manualIpController.dispose();
    _manualPortController.dispose();
    super.dispose();
  }

  Future<void> _connectToHost(DiscoveredHost host) async {
    setState(() {
      _connectingKey = '${host.ip}:${host.port}';
      _errorText = null;
    });
    final result = await ref.read(connectionNotifierProvider.notifier).connect(host);
    if (!mounted) return;
    setState(() => _connectingKey = null);
    result.fold(
      onSuccess: (_) => Navigator.of(context).pop(),
      onFailure: (failure) => setState(() => _errorText = failure.message),
    );
  }

  Future<void> _connectManually() async {
    final ip = _manualIpController.text.trim();
    final port = int.tryParse(_manualPortController.text.trim());
    if (ip.isEmpty || port == null) {
      setState(() => _errorText = 'Enter a valid IP address and port.');
      return;
    }
    setState(() {
      _connectingKey = 'manual';
      _errorText = null;
    });
    final result = await ref.read(connectionNotifierProvider.notifier).connectManual(ip, port);
    if (!mounted) return;
    setState(() => _connectingKey = null);
    result.fold(
      onSuccess: (_) => Navigator.of(context).pop(),
      onFailure: (failure) => setState(() => _errorText = failure.message),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        child: GlassContainer(
          borderRadius: 28,
          blurSigma: 24,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text('Select a Device', style: AppTextStyles.titleLarge)),
                    IconButton(
                      onPressed: _isScanning ? null : _startScan,
                      icon: const Icon(Icons.refresh_rounded),
                      tooltip: 'Scan again',
                    ),
                  ],
                ),
                Text(_subtitle, style: AppTextStyles.bodyMuted),
                const SizedBox(height: 12),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_isScanning && _hosts.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 28),
                            child: Center(
                              child: SizedBox(
                                width: 28,
                                height: 28,
                                child: CircularProgressIndicator(strokeWidth: 2.6),
                              ),
                            ),
                          ),
                        for (final host in _hosts)
                          _HostTile(
                            host: host,
                            isConnecting: _connectingKey == '${host.ip}:${host.port}',
                            onTap: () => _connectToHost(host),
                          ),
                        if (!_isScanning && _hosts.isEmpty) _EmptyState(onManual: () {
                          setState(() => _showManualEntry = true);
                        }),
                        const SizedBox(height: 8),
                        if (!_showManualEntry)
                          TextButton.icon(
                            onPressed: () => setState(() => _showManualEntry = true),
                            icon: const Icon(Icons.keyboard_rounded, size: 18),
                            label: const Text('Enter IP address manually'),
                          )
                        else
                          _ManualEntryForm(
                            ipController: _manualIpController,
                            portController: _manualPortController,
                            isConnecting: _connectingKey == 'manual',
                            onConnect: _connectManually,
                          ),
                        if (_errorText != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Text(
                              _errorText!,
                              style: AppTextStyles.caption.copyWith(color: AppColors.danger),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String get _subtitle {
    if (_isScanning) return 'Scanning your Wi-Fi network for receivers…';
    if (_hosts.isEmpty) return 'No receivers found on this network.';
    return '${_hosts.length} device${_hosts.length == 1 ? '' : 's'} found';
  }
}

class _HostTile extends StatelessWidget {
  const _HostTile({required this.host, required this.isConnecting, required this.onTap});

  final DiscoveredHost host;
  final bool isConnecting;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: isConnecting ? null : onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.blue.withValues(alpha: 0.16),
                  ),
                  child: const Icon(Icons.desktop_windows_rounded, color: AppColors.info, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(host.name, style: AppTextStyles.titleMedium),
                      Text('${host.ip}:${host.port}', style: AppTextStyles.caption),
                    ],
                  ),
                ),
                if (isConnecting)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.2),
                  )
                else
                  const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onManual});

  final VoidCallback onManual;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.wifi_find_rounded, color: AppColors.textMuted, size: 28),
          const SizedBox(height: 8),
          Text(
            'Make sure the AeroTouch desktop receiver is running and this '
            'phone is on the same Wi-Fi network.',
            style: AppTextStyles.bodyMuted,
          ),
        ],
      ),
    );
  }
}

class _ManualEntryForm extends StatelessWidget {
  const _ManualEntryForm({
    required this.ipController,
    required this.portController,
    required this.isConnecting,
    required this.onConnect,
  });

  final TextEditingController ipController;
  final TextEditingController portController;
  final bool isConnecting;
  final VoidCallback onConnect;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: _GlassField(controller: ipController, hint: '192.168.1.42', label: 'IP address'),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: _GlassField(
              controller: portController,
              hint: '${AppConstants.defaultServerPort}',
              label: 'Port',
              numeric: true,
            ),
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(top: 18),
            child: IconButton.filled(
              onPressed: isConnecting ? null : onConnect,
              icon: isConnecting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.arrow_forward_rounded),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassField extends StatelessWidget {
  const _GlassField({
    required this.controller,
    required this.hint,
    required this.label,
    this.numeric = false,
  });

  final TextEditingController controller;
  final String hint;
  final String label;
  final bool numeric;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.caption),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: numeric ? TextInputType.number : TextInputType.numberWithOptions(decimal: true),
          style: AppTextStyles.body,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyles.body.copyWith(color: AppColors.textMuted),
            isDense: true,
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}
