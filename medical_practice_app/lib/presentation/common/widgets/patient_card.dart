import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../core/models/patient_model.dart';
import '../animations/page_transitions.dart';

class PatientCard extends StatefulWidget {
  final Patient patient;
  final Function(Patient) onTap;
  final Function(Patient, bool) onPinToggle;
  final bool compact;
  
  const PatientCard({
    Key? key,
    required this.patient,
    required this.onTap,
    required this.onPinToggle,
    this.compact = false,
  }) : super(key: key);

  @override
  _PatientCardState createState() => _PatientCardState();
}

class _PatientCardState extends State<PatientCard> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.03,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: MouseRegion(
        onEnter: (_) {
          setState(() {
            _isHovered = true;
            _animationController.forward();
          });
        },
        onExit: (_) {
          setState(() {
            _isHovered = false;
            _animationController.reverse();
          });
        },
        child: GestureDetector(
          onTap: () => widget.onTap(widget.patient),
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: _isHovered
                      ? Colors.black.withOpacity(0.1)
                      : Colors.black.withOpacity(0.05),
                  blurRadius: _isHovered ? 8 : 5,
                  offset: _isHovered ? const Offset(0, 4) : const Offset(0, 2),
                ),
              ],
              border: Border.all(
                color: _isHovered
                    ? AppTheme.primaryColor.withOpacity(0.3)
                    : theme.dividerColor,
                width: _isHovered ? 1.5 : 1,
              ),
            ),
            child: widget.compact
                ? _buildCompactPatientCard(theme)
                : _buildFullPatientCard(theme),
          ),
        ),
      ),
    );
  }
  
  Widget _buildCompactPatientCard(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        children: [
          // Patient Photo
          _buildPatientAvatar(size: 40),
          const SizedBox(width: 12),
          
          // Patient Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.patient.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${widget.patient.age} years, ${widget.patient.gender}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onBackground.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          
          // Pin Icon
          IconButton(
            icon: Icon(
              widget.patient.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
              size: 18,
              color: widget.patient.isPinned
                  ? AppTheme.warning
                  : theme.colorScheme.onBackground.withOpacity(0.4),
            ),
            onPressed: () => widget.onPinToggle(widget.patient, !widget.patient.isPinned),
            tooltip: widget.patient.isPinned ? 'Unpin patient' : 'Pin patient',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 24,
              minHeight: 24,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFullPatientCard(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Card Header
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.background.withOpacity(0.5),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            border: Border(
              bottom: BorderSide(
                color: theme.dividerColor,
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              // Patient avatar
              _buildPatientAvatar(size: 48),
              const SizedBox(width: 12),
              
              // Patient name and basic info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.patient.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${widget.patient.age} years, ${widget.patient.gender}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onBackground.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Pin Icon
              IconButton(
                icon: Icon(
                  widget.patient.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                  color: widget.patient.isPinned
                      ? AppTheme.warning
                      : theme.colorScheme.onBackground.withOpacity(0.4),
                ),
                onPressed: () => widget.onPinToggle(widget.patient, !widget.patient.isPinned),
                tooltip: widget.patient.isPinned ? 'Unpin patient' : 'Pin patient',
              ),
            ],
          ),
        ),
        
        // Card Content
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Contact & Visit Info
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      theme,
                      Icons.phone,
                      'Phone',
                      widget.patient.phoneNumber,
                    ),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      theme,
                      Icons.calendar_today,
                      'First Visit',
                      _formatDate(widget.patient.firstVisitDate),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Address
              if (widget.patient.address.isNotEmpty) ...[
                _buildInfoItem(
                  theme,
                  Icons.location_on_outlined,
                  'Address',
                  widget.patient.address,
                ),
                const SizedBox(height: 12),
              ],
              
              // Medical Info
              if (widget.patient.chronicDiseases.isNotEmpty) ...[
                _buildInfoItem(
                  theme,
                  Icons.medical_services_outlined,
                  'Chronic',
                  widget.patient.formattedChronicDiseases,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildPatientAvatar({required double size}) {
    return Hero(
      tag: 'patient_avatar_${widget.patient.id}',
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.1),
          shape: BoxShape.circle,
          image: widget.patient.photoUrl.isNotEmpty
              ? DecorationImage(
                  image: NetworkImage(widget.patient.photoUrl),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: widget.patient.photoUrl.isEmpty
            ? Center(
                child: Text(
                  widget.patient.name.isNotEmpty
                      ? widget.patient.name[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: size / 2,
                  ),
                ),
              )
            : null,
      ),
    );
  }
  
  Widget _buildInfoItem(ThemeData theme, IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: theme.colorScheme.primary.withOpacity(0.7),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onBackground.withOpacity(0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
