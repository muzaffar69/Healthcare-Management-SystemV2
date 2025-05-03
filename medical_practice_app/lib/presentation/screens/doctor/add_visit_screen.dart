import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../config/theme.dart';
import '../../../config/constants.dart';
import '../../../core/models/patient_model.dart';
import '../../../core/models/visit_model.dart';
import '../../common/widgets/custom_button.dart';
import '../../common/widgets/custom_text_field.dart';
import '../../common/widgets/loading_animation.dart';
import '../../state/visit_provider.dart';

class AddVisitScreen extends StatefulWidget {
  final Patient patient;

  const AddVisitScreen({Key? key, required this.patient}) : super(key: key);

  @override
  _AddVisitScreenState createState() => _AddVisitScreenState();
}

class _AddVisitScreenState extends State<AddVisitScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  DateTime _visitDate = DateTime.now();
  bool _isLoading = false;
  int _visitNumber = 1;

  @override
  void initState() {
    super.initState();
    _loadVisitNumber();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadVisitNumber() async {
    try {
      final visitProvider = Provider.of<VisitProvider>(context, listen: false);
      final visits = await visitProvider.getVisits(widget.patient.id);

      setState(() {
        _visitNumber = visits.length + 1;
      });
    } catch (e) {
      debugPrint('Error loading visit number: $e');
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _visitDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != _visitDate) {
      setState(() {
        _visitDate = picked;
      });
    }
  }

  Future<void> _saveVisit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Create the visit
      final visit = Visit(
        id: const Uuid().v4(),
        patientId: widget.patient.id,
        doctorId: '', // Will be set by the API
        visitDate: _visitDate,
        visitNumber: _visitNumber,
        notes: _notesController.text,
        lastModified: DateTime.now(),
      );

      final visitProvider = Provider.of<VisitProvider>(context, listen: false);
      await visitProvider.createVisit(visit: visit);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Visit added successfully'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate back
        Navigator.pop(context);
      }
    } catch (e) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add visit: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Add New Visit')),
      body:
          _isLoading
              ? const Center(child: LoadingAnimation())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Patient Info Card
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 30,
                                backgroundColor: AppTheme.primaryColor
                                    .withOpacity(0.1),
                                backgroundImage:
                                    widget.patient.photoUrl.isNotEmpty
                                        ? NetworkImage(widget.patient.photoUrl)
                                        : null,
                                child:
                                    widget.patient.photoUrl.isEmpty
                                        ? Text(
                                          widget.patient.name.isNotEmpty
                                              ? widget.patient.name[0]
                                                  .toUpperCase()
                                              : '?',
                                          style: const TextStyle(
                                            color: AppTheme.primaryColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 24,
                                          ),
                                        )
                                        : null,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.patient.name,
                                      style: theme.textTheme.titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${widget.patient.age} years, ${widget.patient.gender}',
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Visit Details
                      Text(
                        'Visit Details',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Visit Number
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          border: Border.all(color: theme.dividerColor),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Visit Number',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '#$_visitNumber',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Visit Date
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          border: Border.all(color: theme.dividerColor),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Visit Date',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            TextButton(
                              onPressed: () => _selectDate(context),
                              child: Text(
                                DateFormat('dd/MM/yyyy').format(_visitDate),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Notes
                      CustomTextField(
                        label: 'Visit Notes',
                        controller: _notesController,
                        maxLines: 5,
                        placeholder:
                            'Enter visit notes, symptoms, diagnosis, etc.',
                      ),
                      const SizedBox(height: 32),

                      // Save button
                      CustomButton(
                        label: 'Save Visit',
                        onPressed: _saveVisit,
                        isFullWidth: true,
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
    );
  }
}
