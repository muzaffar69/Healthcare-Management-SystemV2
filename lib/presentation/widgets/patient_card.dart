import 'package:flutter/material.dart';
import '../../data/models/patient_model.dart';
import '../themes/app_theme.dart';
import '../../core/animations/fade_animation.dart';

class PatientCard extends StatefulWidget {
  final Patient patient;
  final VoidCallback onTap;
  final int index;

  const PatientCard({
    Key? key,
    required this.patient,
    required this.onTap,
    required this.index,
  }) : super(key: key);

  @override
  State<PatientCard> createState() => _PatientCardState();
}

class _PatientCardState extends State<PatientCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return FadeAnimation(
      delay: 0.1 * widget.index,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: _isHovered
                      ? AppTheme.primaryColor.withOpacity(0.3)
                      : Colors.black.withOpacity(0.05),
                  blurRadius: _isHovered ? 10 : 5,
                  offset: Offset(0, _isHovered ? 5 : 3),
                ),
              ],
              border: _isHovered
                  ? Border.all(color: AppTheme.primaryColor.withOpacity(0.3), width: 1.5)
                  : null,
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  _buildPatientAvatar(),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.patient.name,
                          style: AppTheme.subheadingStyle.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        _buildPatientInfo(),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: _isHovered
                        ? AppTheme.primaryColor
                        : AppTheme.textLightColor,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPatientAvatar() {
    return CircleAvatar(
      radius: 30,
      backgroundColor: AppTheme.primaryColor.withOpacity(0.15),
      backgroundImage: widget.patient.profilePicPath != null
          ? AssetImage(widget.patient.profilePicPath!)
          : null,
      child: widget.patient.profilePicPath == null
          ? Text(
              widget.patient.name.isNotEmpty
                  ? widget.patient.name.substring(0, 1).toUpperCase()
                  : '',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            )
          : null,
    );
  }

  Widget _buildPatientInfo() {
    return Row(
      children: [
        _buildInfoItem(Icons.cake_outlined, '${widget.patient.age} years'),
        const SizedBox(width: 12),
        _buildInfoItem(
          widget.patient.gender.toLowerCase() == 'male'
              ? Icons.male_outlined
              : Icons.female_outlined,
          widget.patient.gender,
        ),
        const SizedBox(width: 12),
        _buildInfoItem(Icons.phone_outlined, widget.patient.phoneNumber),
      ],
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          color: AppTheme.textLightColor,
          size: 16,
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: AppTheme.bodyStyle.copyWith(
            color: AppTheme.textLightColor,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}