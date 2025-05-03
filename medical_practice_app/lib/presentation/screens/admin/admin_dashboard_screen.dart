import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../config/constants.dart';
import '../../../core/models/user_model.dart';
import '../../common/widgets/custom_button.dart';
import '../../common/widgets/custom_text_field.dart';
import '../../common/widgets/loading_animation.dart';
import '../../state/auth_provider.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  _AdminDashboardScreenState createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = true;
  List<User> _doctors = [];
  String _filter = 'all'; // all, active, inactive, expiring

  @override
  void initState() {
    super.initState();
    _loadDoctors();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
  }

  Future<void> _loadDoctors() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Implement API call to fetch doctors
      // For now, using mock data
      await Future.delayed(const Duration(seconds: 1));

      setState(() {
        _doctors = [];
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load doctors: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<User> get _filteredDoctors {
    var filtered = _doctors;

    // Apply status filter
    if (_filter == 'active') {
      filtered = filtered.where((d) => d.isActive).toList();
    } else if (_filter == 'inactive') {
      filtered = filtered.where((d) => !d.isActive).toList();
    } else if (_filter == 'expiring') {
      filtered =
          filtered.where((d) => d.isSubscriptionExpiringInDays(30)).toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered =
          filtered.where((d) {
            return d.displayName.toLowerCase().contains(_searchQuery) ||
                d.email.toLowerCase().contains(_searchQuery);
          }).toList();
    }

    return filtered;
  }

  Future<void> _toggleDoctorAccount(User doctor) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              doctor.isActive ? 'Deactivate Account' : 'Activate Account',
            ),
            content: Text(
              'Are you sure you want to ${doctor.isActive ? 'deactivate' : 'activate'} ${doctor.displayName}\'s account?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(doctor.isActive ? 'Deactivate' : 'Activate'),
              ),
            ],
          ),
    );

    if (confirm == true) {
      try {
        // TODO: Implement API call to toggle account status
        await Future.delayed(const Duration(seconds: 1));

        _loadDoctors();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Account ${doctor.isActive ? 'deactivated' : 'activated'} successfully',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update account: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _toggleAssociatedAccount(User doctor, String accountType) async {
    final bool isPharmacy = accountType == 'pharmacy';
    final bool isActive =
        isPharmacy ? doctor.pharmacyAccountActive : doctor.labAccountActive;

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              '${isActive ? 'Deactivate' : 'Activate'} ${accountType.toUpperCase()} Account',
            ),
            content: Text(
              'Are you sure you want to ${isActive ? 'deactivate' : 'activate'} the $accountType account for ${doctor.displayName}?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(isActive ? 'Deactivate' : 'Activate'),
              ),
            ],
          ),
    );

    if (confirm == true) {
      try {
        // TODO: Implement API call to toggle associated account status
        await Future.delayed(const Duration(seconds: 1));

        _loadDoctors();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${accountType.toUpperCase()} account ${isActive ? 'deactivated' : 'activated'} successfully',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update account: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _regenerateAccessCode(User doctor, String accountType) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Regenerate Access Code'),
            content: Text(
              'Are you sure you want to regenerate the access code for ${doctor.displayName}\'s $accountType account?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Regenerate'),
              ),
            ],
          ),
    );

    if (confirm == true) {
      try {
        // TODO: Implement API call to regenerate access code
        final newCode = 'NEW-${DateTime.now().millisecondsSinceEpoch}';

        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: Text('New Access Code'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'New access code for ${doctor.displayName}\'s $accountType account:',
                    ),
                    const SizedBox(height: 16),
                    SelectableText(
                      newCode,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              ),
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Access code regenerated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to regenerate access code: ${e.toString()}',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _showDoctorDetails(User doctor) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Doctor Details',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.person),
                      title: const Text('Name'),
                      subtitle: Text(doctor.displayName),
                    ),
                    ListTile(
                      leading: const Icon(Icons.email),
                      title: const Text('Email'),
                      subtitle: Text(doctor.email),
                    ),
                    ListTile(
                      leading: const Icon(Icons.calendar_today),
                      title: const Text('Subscription'),
                      subtitle: Text(
                        doctor.subscriptionEndDate != null
                            ? 'Expires on ${doctor.subscriptionEndDate!.day}/${doctor.subscriptionEndDate!.month}/${doctor.subscriptionEndDate!.year}'
                            : 'No active subscription',
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.medical_services),
                      title: const Text('Pharmacy Account'),
                      subtitle: Text(
                        doctor.hasPharmacyAccount ? 'Active' : 'Not available',
                      ),
                      trailing:
                          doctor.hasPharmacyAccount
                              ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Switch(
                                    value: doctor.pharmacyAccountActive,
                                    onChanged:
                                        (_) => _toggleAssociatedAccount(
                                          doctor,
                                          'pharmacy',
                                        ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.refresh),
                                    onPressed:
                                        () => _regenerateAccessCode(
                                          doctor,
                                          'pharmacy',
                                        ),
                                    tooltip: 'Regenerate access code',
                                  ),
                                ],
                              )
                              : null,
                    ),
                    ListTile(
                      leading: const Icon(Icons.science),
                      title: const Text('Lab Account'),
                      subtitle: Text(
                        doctor.hasLabAccount ? 'Active' : 'Not available',
                      ),
                      trailing:
                          doctor.hasLabAccount
                              ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Switch(
                                    value: doctor.labAccountActive,
                                    onChanged:
                                        (_) => _toggleAssociatedAccount(
                                          doctor,
                                          'lab',
                                        ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.refresh),
                                    onPressed:
                                        () => _regenerateAccessCode(
                                          doctor,
                                          'lab',
                                        ),
                                    tooltip: 'Regenerate access code',
                                  ),
                                ],
                              )
                              : null,
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // TODO: Navigate to add doctor screen
            },
            tooltip: 'Add Doctor',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDoctors,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filters
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Search bar
                CustomTextField(
                  controller: _searchController,
                  label: 'Search Doctors',
                  placeholder: 'Search by name or email',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon:
                      _searchQuery.isNotEmpty
                          ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => _searchController.clear(),
                          )
                          : null,
                ),
                const SizedBox(height: 16),

                // Filter chips
                Wrap(
                  spacing: 8,
                  children: [
                    FilterChip(
                      label: const Text('All'),
                      selected: _filter == 'all',
                      onSelected: (selected) {
                        setState(() {
                          _filter = 'all';
                        });
                      },
                    ),
                    FilterChip(
                      label: const Text('Active'),
                      selected: _filter == 'active',
                      onSelected: (selected) {
                        setState(() {
                          _filter = selected ? 'active' : 'all';
                        });
                      },
                    ),
                    FilterChip(
                      label: const Text('Inactive'),
                      selected: _filter == 'inactive',
                      onSelected: (selected) {
                        setState(() {
                          _filter = selected ? 'inactive' : 'all';
                        });
                      },
                    ),
                    FilterChip(
                      label: const Text('Expiring Soon'),
                      selected: _filter == 'expiring',
                      onSelected: (selected) {
                        setState(() {
                          _filter = selected ? 'expiring' : 'all';
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Doctors List
          Expanded(
            child:
                _isLoading
                    ? const Center(child: LoadingAnimation())
                    : _filteredDoctors.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.person_search,
                            size: 64,
                            color: theme.colorScheme.onBackground.withOpacity(
                              0.3,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No doctors found',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.onBackground.withOpacity(
                                0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                    : RefreshIndicator(
                      onRefresh: _loadDoctors,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: _filteredDoctors.length,
                        itemBuilder: (context, index) {
                          final doctor = _filteredDoctors[index];

                          return Card(
                            margin: const EdgeInsets.only(bottom: 16.0),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 24,
                                        backgroundColor: AppTheme.primaryColor
                                            .withOpacity(0.1),
                                        child: Text(
                                          doctor.displayName[0].toUpperCase(),
                                          style: const TextStyle(
                                            color: AppTheme.primaryColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 20,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              doctor.displayName,
                                              style: theme.textTheme.titleMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                            ),
                                            Text(
                                              doctor.email,
                                              style: theme.textTheme.bodySmall,
                                            ),
                                          ],
                                        ),
                                      ),
                                      Switch(
                                        value: doctor.isActive,
                                        onChanged:
                                            (_) => _toggleDoctorAccount(doctor),
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 24),

                                  // Subscription status
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.calendar_today,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 8),
                                      if (doctor.subscriptionEndDate !=
                                          null) ...[
                                        Text(
                                          'Subscription expires on ${doctor.subscriptionEndDate!.day}/${doctor.subscriptionEndDate!.month}/${doctor.subscriptionEndDate!.year}',
                                          style: theme.textTheme.bodySmall,
                                        ),
                                        const SizedBox(width: 8),
                                        if (doctor.isSubscriptionExpiringInDays(
                                          30,
                                        ))
                                          Chip(
                                            label: const Text('Expiring Soon'),
                                            backgroundColor: Colors.orange
                                                .withOpacity(0.2),
                                            labelStyle: const TextStyle(
                                              color: Colors.orange,
                                            ),
                                          ),
                                      ] else
                                        Text(
                                          'No active subscription',
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(color: Colors.red),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),

                                  // Associated accounts
                                  Row(
                                    children: [
                                      // Pharmacy
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color:
                                              doctor.hasPharmacyAccount
                                                  ? (doctor
                                                          .pharmacyAccountActive
                                                      ? Colors.green
                                                          .withOpacity(0.1)
                                                      : Colors.grey.withOpacity(
                                                        0.1,
                                                      ))
                                                  : Colors.red.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.medication,
                                              size: 16,
                                              color:
                                                  doctor.hasPharmacyAccount
                                                      ? (doctor
                                                              .pharmacyAccountActive
                                                          ? Colors.green
                                                          : Colors.grey)
                                                      : Colors.red,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Pharmacy',
                                              style: TextStyle(
                                                color:
                                                    doctor.hasPharmacyAccount
                                                        ? (doctor
                                                                .pharmacyAccountActive
                                                            ? Colors.green
                                                            : Colors.grey)
                                                        : Colors.red,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),

                                      // Laboratory
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color:
                                              doctor.hasLabAccount
                                                  ? (doctor.labAccountActive
                                                      ? Colors.green
                                                          .withOpacity(0.1)
                                                      : Colors.grey.withOpacity(
                                                        0.1,
                                                      ))
                                                  : Colors.red.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.science,
                                              size: 16,
                                              color:
                                                  doctor.hasLabAccount
                                                      ? (doctor.labAccountActive
                                                          ? Colors.green
                                                          : Colors.grey)
                                                      : Colors.red,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Lab',
                                              style: TextStyle(
                                                color:
                                                    doctor.hasLabAccount
                                                        ? (doctor
                                                                .labAccountActive
                                                            ? Colors.green
                                                            : Colors.grey)
                                                        : Colors.red,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),

                                  // Actions
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      TextButton.icon(
                                        icon: const Icon(
                                          Icons.info_outline,
                                          size: 18,
                                        ),
                                        label: const Text('Details'),
                                        onPressed:
                                            () => _showDoctorDetails(doctor),
                                      ),
                                      const SizedBox(width: 8),
                                      TextButton.icon(
                                        icon: const Icon(
                                          Icons.settings,
                                          size: 18,
                                        ),
                                        label: const Text('Manage'),
                                        onPressed: () {
                                          // TODO: Navigate to manage doctor screen
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
          ),
        ],
      ),
    );
  }
}
