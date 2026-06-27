// lib/screens/cycles/hall_selection_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/breeding_cycle.dart';
import 'cycle_aggregate_dashboard_screen.dart';
import 'cycle_dashboard_screen.dart';

class HallSelectionScreen extends StatelessWidget {
  final BreedingCycle parent;
  final List<BreedingCycle> halls;

  const HallSelectionScreen({
    super.key,
    required this.parent,
    required this.halls,
  });

  static const Color primary = Color(0xFF0F766E);
  static const Color secondary = Color(0xFF14B8A6);
  static const Color background = Color(0xFFF8FAF9);

  String _formatNumber(num value) {
    return NumberFormat('#,###', 'en_US').format(value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF1B5E20),
                Color(0xFF2E7D32),
                Color(0xFF4CAF50),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              parent.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 18,
              ),
            ),
            Text(
              'انتخاب سالن',
              style: TextStyle(
                color: Colors.white.withOpacity(0.88),
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics_rounded, color: Colors.white),
            tooltip: 'داشبورد کلی',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CycleAggregateDashboardScreen(
                    parent: parent,
                    halls: halls,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Top Summary Card
          _buildTopSummary(),

          const SizedBox(height: 12),

          // Aggregate Dashboard Quick Access
          _buildAggregateDashboardCard(context),

          const SizedBox(height: 16),

          // List Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: secondary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${halls.length} سالن',
                    style: TextStyle(
                      color: secondary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
                Text(
                  'لیست سالن‌ها',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onBackground,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Halls List
          Expanded(
            child: halls.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    itemCount: halls.length,
                    itemBuilder: (context, index) {
                      final hall = halls[index];
                      return _buildHallCard(context, hall, index);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopSummary() {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 14, 14, 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _TopInfo(
              icon: Icons.calendar_month_rounded,
              title: parent.formattedStartDate,
              subtitle: 'تاریخ شروع',
            ),
          ),
          _divider(),
          Expanded(
            child: _TopInfo(
              icon: Icons.apartment_rounded,
              title: '${halls.length}',
              subtitle: 'سالن',
            ),
          ),
          _divider(),
          Expanded(
            child: _TopInfo(
              icon: Icons.catching_pokemon,
              title: _formatNumber(parent.chickCount),
              subtitle: 'جوجه',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAggregateDashboardCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Material(
        color: Colors.grey.shade100.withOpacity(0.6),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CycleAggregateDashboardScreen(
                  parent: parent,
                  halls: halls,
                ),
              ),
            );
          },
          child: Ink(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blueGrey.withOpacity(0.12),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: secondary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.analytics_rounded,
                    color: secondary,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: const [
                      Text(
                        'داشبورد کلی سالن‌ها',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15.5),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'مشاهده آمار تجمیعی همه سالن‌ها',
                        style: TextStyle(color: Colors.grey, fontSize: 12.5),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 18,
                  color: Colors.grey.shade400,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHallCard(BuildContext context, BreedingCycle hall, int index) {
    final percent = parent.chickCount > 0 ? hall.chickCount / parent.chickCount : 0.0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CycleDashboardScreen(cycle: hall),
              ),
            );
          },
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFFFF80), // روشن
                  const Color(0xFF80E08), // فیروزه‌ای ملایم
                  secondary.withOpacity(0.85),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.more_vert, color: Colors.black54, size: 22),

                  const SizedBox(width: 12),

                  // Hall Number
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: secondary.withOpacity(0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: secondary.withOpacity(0.3)),
                              ),
                              child: Text(
                                '${(percent * 100).toStringAsFixed(0)}٪',
                                style: TextStyle(
                                  color: secondary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12.5,
                                ),
                              ),
                            ),
                            Text(
                              'سالن ${hall.hallNumber}',
                              style: const TextStyle(
                                fontSize: 16.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        Row(
                          children: [
                            const Spacer(),
                            Text(
                              '${_formatNumber(hall.chickCount)} جوجه',
                              style: const TextStyle(
                                color: Color(0xFF374151),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(Icons.catching_pokemon, size: 18, color: secondary),
                            
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.apartment_rounded, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'هیچ سالنی یافت نشد',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'سالن‌ها بعداً به این دوره اضافه خواهند شد',
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Container(
      width: 1,
      height: 48,
      color: Colors.white.withOpacity(0.3),
    );
  }
}

class _TopInfo extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _TopInfo({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 23),
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            color: Colors.white.withOpacity(0.78),
            fontSize: 11.5,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}