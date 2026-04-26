import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../models/address.dart';
import '../providers/address_provider.dart';

/// Address Screen
///
/// Shows saved addresses and allows adding/editing/deleting.
class AddressScreen extends StatefulWidget {
  const AddressScreen({super.key});

  @override
  State<AddressScreen> createState() => _AddressScreenState();
}

class _AddressScreenState extends State<AddressScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AddressProvider>().loadAddresses();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final provider = context.watch<AddressProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text('My Addresses', style: theme.textTheme.headlineMedium),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _openAddressForm(context, null),
          ),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.addresses.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.location_off_outlined,
                    size: 64,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const Text('No saved addresses'),
                  const SizedBox(height: AppSpacing.md),
                  FilledButton.icon(
                    onPressed: () => _openAddressForm(context, null),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add Address'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: provider.addresses.length,
              itemBuilder: (context, index) {
                final addr = provider.addresses[index];
                return _AddressTile(
                  address: addr,
                  isDark: isDark,
                  onEdit: () => _openAddressForm(context, addr),
                  onDelete: () => _confirmDelete(context, addr),
                );
              },
            ),
    );
  }

  void _openAddressForm(BuildContext context, AddressResponse? existing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddressForm(existing: existing),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    AddressResponse addr,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Delete Address'),
        content: const Text('Remove this address?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<AddressProvider>().deleteAddress(addr.id);
    }
  }
}

class _AddressTile extends StatelessWidget {
  const _AddressTile({
    required this.address,
    required this.isDark,
    required this.onEdit,
    required this.onDelete,
  });
  final AddressResponse address;
  final bool isDark;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.06)
              : Colors.black.withOpacity(0.06),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.location_on_outlined, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      address.fullName,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    if (address.isDefault) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: const Text(
                          'Default',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(address.singleLine, style: theme.textTheme.bodySmall),
                Text(address.phone, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 18),
                onPressed: onEdit,
                visualDensity: VisualDensity.compact,
              ),
              IconButton(
                icon: Icon(
                  Icons.delete_outline_rounded,
                  size: 18,
                  color: AppColors.error,
                ),
                onPressed: onDelete,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AddressForm extends StatefulWidget {
  const _AddressForm({this.existing});
  final AddressResponse? existing;

  @override
  State<_AddressForm> createState() => _AddressFormState();
}

class _AddressFormState extends State<_AddressForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _addr1;
  late final TextEditingController _addr2;
  late final TextEditingController _city;
  late final TextEditingController _state;
  late final TextEditingController _pincode;
  bool _isDefault = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.fullName ?? '');
    _phone = TextEditingController(text: e?.phone ?? '');
    _addr1 = TextEditingController(text: e?.addressLine1 ?? '');
    _addr2 = TextEditingController(text: e?.addressLine2 ?? '');
    _city = TextEditingController(text: e?.city ?? '');
    _state = TextEditingController(text: e?.state ?? '');
    _pincode = TextEditingController(text: e?.pincode ?? '');
    _isDefault = e?.isDefault ?? false;
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _addr1.dispose();
    _addr2.dispose();
    _city.dispose();
    _state.dispose();
    _pincode.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final request = AddressRequest(
      fullName: _name.text.trim(),
      phone: _phone.text.trim(),
      addressLine1: _addr1.text.trim(),
      addressLine2: _addr2.text.trim().isEmpty ? null : _addr2.text.trim(),
      city: _city.text.trim(),
      state: _state.text.trim(),
      pincode: _pincode.text.trim(),
      isDefault: _isDefault,
    );

    final provider = context.read<AddressProvider>();
    final existing = widget.existing;

    if (existing != null) {
      await provider.updateAddress(existing.id, request);
    } else {
      await provider.createAddress(request);
    }

    if (mounted) {
      setState(() => _saving = false);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      maxChildSize: 0.95,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: controller,
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        widget.existing != null
                            ? 'Edit Address'
                            : 'Add Address',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _field('Full Name', _name, required: true),
                      _field(
                        'Phone',
                        _phone,
                        required: true,
                        keyboardType: TextInputType.phone,
                      ),
                      _field('Address Line 1', _addr1, required: true),
                      _field('Address Line 2 (optional)', _addr2),
                      _field('City', _city, required: true),
                      _field('State', _state, required: true),
                      _field(
                        'Pincode',
                        _pincode,
                        required: true,
                        keyboardType: TextInputType.number,
                      ),
                      SwitchListTile(
                        title: const Text('Set as Default'),
                        value: _isDefault,
                        onChanged: (v) => setState(() => _isDefault = v),
                        activeColor: AppColors.primary,
                        contentPadding: EdgeInsets.zero,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      FilledButton(
                        onPressed: _saving ? null : _save,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusLg,
                            ),
                          ),
                        ),
                        child: _saving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Save Address'),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController ctrl, {
    bool required = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: TextFormField(
        controller: ctrl,
        keyboardType: keyboardType,
        decoration: InputDecoration(labelText: label),
        validator: required
            ? (v) {
                if (v == null || v.trim().isEmpty) return '$label is required';
                return null;
              }
            : null,
      ),
    );
  }
}
