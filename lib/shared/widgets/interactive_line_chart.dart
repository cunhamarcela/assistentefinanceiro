import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Dados para um ponto no gráfico
class ChartPointData {
  final String label;
  final String fullLabel;
  final double value;
  final DateTime? date;
  final Map<String, dynamic>? metadata;

  const ChartPointData({
    required this.label,
    required this.fullLabel,
    required this.value,
    this.date,
    this.metadata,
  });
}

/// Widget de gráfico de linha interativo com drill-down
/// 
/// Tokens utilizados:
/// - Background: colorSurfaceCard
/// - Linha: colorBrandPrimary -> colorBrandSoft (gradiente)
/// - Pontos: colorSurfaceCard com borda colorBrandPrimary
/// - Ponto selecionado: colorActionPrimary
/// - Grid: colorBorderSubtle
/// - Texto: colorTextPrimary, colorTextMuted, colorTextOnDark
class InteractiveLineChart extends StatefulWidget {
  final List<ChartPointData> data;
  final String? title;
  final IconData? titleIcon;
  final double? height;
  final bool showGrid;
  final bool showDots;
  final bool showArea;
  final bool enableTouchInteraction;
  final void Function(ChartPointData, int)? onPointTap;
  final void Function(ChartPointData)? onPointLongPress;
  final Color? lineColor;
  final Color? areaColor;
  final String Function(double)? formatValue;
  final String Function(double)? formatAxisValue;

  const InteractiveLineChart({
    super.key,
    required this.data,
    this.title,
    this.titleIcon,
    this.height,
    this.showGrid = true,
    this.showDots = true,
    this.showArea = true,
    this.enableTouchInteraction = true,
    this.onPointTap,
    this.onPointLongPress,
    this.lineColor,
    this.areaColor,
    this.formatValue,
    this.formatAxisValue,
  });

  @override
  State<InteractiveLineChart> createState() => _InteractiveLineChartState();
}

class _InteractiveLineChartState extends State<InteractiveLineChart>
    with SingleTickerProviderStateMixin {
  int? _selectedIndex;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Color get _lineColor => widget.lineColor ?? AppColors.colorBrandPrimary;
  Color get _areaColor => widget.areaColor ?? AppColors.colorBrandPrimary;

  String _formatValue(double value) {
    if (widget.formatValue != null) return widget.formatValue!(value);
    return 'R\$ ${value.toStringAsFixed(2)}';
  }

  String _formatAxisValue(double value) {
    if (widget.formatAxisValue != null) return widget.formatAxisValue!(value);
    if (value >= 1000) return 'R\$ ${(value / 1000).toStringAsFixed(0)}k';
    return 'R\$ ${value.toStringAsFixed(0)}';
  }

  void _handleTouchResponse(FlTouchEvent event, LineTouchResponse? response) {
    if (response?.lineBarSpots == null || response!.lineBarSpots!.isEmpty) {
      if (_selectedIndex != null) {
        setState(() => _selectedIndex = null);
        _animationController.reverse();
      }
      return;
    }

    final spot = response.lineBarSpots!.first;
    final index = spot.x.toInt();

    if (index >= 0 && index < widget.data.length) {
      final wasNull = _selectedIndex == null;
      setState(() => _selectedIndex = index);
      
      if (wasNull) {
        _animationController.forward();
      }

      if (event is FlTapUpEvent) {
        widget.onPointTap?.call(widget.data[index], index);
      } else if (event is FlLongPressStart) {
        widget.onPointLongPress?.call(widget.data[index]);
        _showDetailBottomSheet(widget.data[index], index);
      }
    }
  }

  void _showDetailBottomSheet(ChartPointData point, int index) {
    Get.bottomSheet(
      _ChartDetailBottomSheet(
        point: point,
        index: index,
        total: widget.data.length,
        formatValue: _formatValue,
        data: widget.data,
      ),
      backgroundColor: AppColors.colorSurfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppColors.colorSurfaceCard,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: _lineColor.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título
          if (widget.title != null) ...[
            Row(
              children: [
                if (widget.titleIcon != null)
                  Icon(widget.titleIcon, color: _lineColor, size: 24.sp),
                if (widget.titleIcon != null) SizedBox(width: 12.w),
                Text(
                  widget.title!,
                  style: AppTextStyles.headingSmall.copyWith(
                    color: AppColors.colorTextPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            
            // Dica de interação
            if (widget.enableTouchInteraction)
              Text(
                'Toque nos pontos para ver detalhes • Segure para expandir',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.colorTextMuted,
                  fontSize: 11.sp,
                ),
              ),
            SizedBox(height: 16.h),
          ],
          
          // Card de ponto selecionado
          if (_selectedIndex != null)
            AnimatedBuilder(
              animation: _scaleAnimation,
              builder: (context, child) => Transform.scale(
                scale: _scaleAnimation.value,
                child: _SelectedPointCard(
                  point: widget.data[_selectedIndex!],
                  index: _selectedIndex!,
                  total: widget.data.length,
                  formatValue: _formatValue,
                  color: _lineColor,
                ),
              ),
            ),
          
          if (_selectedIndex != null) SizedBox(height: 16.h),
          
          // Gráfico
          SizedBox(
            height: widget.height ?? 200.h,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: widget.showGrid,
                  drawVerticalLine: false,
                  horizontalInterval: _calculateInterval(),
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: AppColors.colorBorderSubtle.withOpacity(0.5),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= widget.data.length) {
                          return const SizedBox.shrink();
                        }
                        final isSelected = index == _selectedIndex;
                        return Padding(
                          padding: EdgeInsets.only(top: 8.h),
                          child: Text(
                            widget.data[index].label,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: isSelected
                                  ? AppColors.colorActionPrimary
                                  : AppColors.colorTextMuted,
                              fontSize: 10.sp,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 55,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          _formatAxisValue(value),
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.colorTextMuted,
                            fontSize: 10.sp,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: (widget.data.length - 1).toDouble(),
                minY: 0,
                maxY: _calculateMaxY(),
                lineBarsData: [
                  LineChartBarData(
                    spots: widget.data.asMap().entries.map((entry) {
                      return FlSpot(
                        entry.key.toDouble(),
                        entry.value.value,
                      );
                    }).toList(),
                    isCurved: true,
                    curveSmoothness: 0.3,
                    gradient: LinearGradient(
                      colors: [_lineColor, AppColors.colorBrandSoft],
                    ),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: widget.showDots,
                      getDotPainter: (spot, percent, barData, index) {
                        final isSelected = index == _selectedIndex;
                        return FlDotCirclePainter(
                          radius: isSelected ? 6 : 4,
                          color: isSelected
                              ? AppColors.colorActionPrimary
                              : AppColors.colorSurfaceCard,
                          strokeWidth: isSelected ? 3 : 2,
                          strokeColor: isSelected
                              ? AppColors.colorActionPrimary
                              : _lineColor,
                        );
                      },
                    ),
                    belowBarData: widget.showArea
                        ? BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: [
                                _areaColor.withOpacity(0.3),
                                _areaColor.withOpacity(0.0),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          )
                        : null,
                  ),
                ],
                lineTouchData: widget.enableTouchInteraction
                    ? LineTouchData(
                        enabled: true,
                        handleBuiltInTouches: false,
                        touchCallback: _handleTouchResponse,
                        touchTooltipData: LineTouchTooltipData(
                          fitInsideHorizontally: true,
                          fitInsideVertically: true,
                          getTooltipItems: (touchedSpots) {
                            return touchedSpots.map((spot) {
                              return LineTooltipItem(
                                _formatValue(spot.y),
                                TextStyle(
                                  color: AppColors.colorTextOnDark,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14.sp,
                                ),
                              );
                            }).toList();
                          },
                        ),
                      )
                    : const LineTouchData(enabled: false),
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _calculateInterval() {
    final max = widget.data.fold(0.0, (max, d) => d.value > max ? d.value : max);
    if (max >= 10000) return 2000;
    if (max >= 5000) return 1000;
    if (max >= 1000) return 500;
    return 200;
  }

  double _calculateMaxY() {
    final max = widget.data.fold(0.0, (max, d) => d.value > max ? d.value : max);
    return max * 1.2;
  }
}

class _SelectedPointCard extends StatelessWidget {
  final ChartPointData point;
  final int index;
  final int total;
  final String Function(double) formatValue;
  final Color color;

  const _SelectedPointCard({
    required this.point,
    required this.index,
    required this.total,
    required this.formatValue,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.15),
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  color: color,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  point.fullLabel,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.colorTextPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  formatValue(point.value),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.colorTextMuted,
                  ),
                ),
              ],
            ),
          ),
          // Comparação com período anterior
          if (index > 0) _buildComparison(context),
        ],
      ),
    );
  }

  Widget _buildComparison(BuildContext context) {
    // Esta seria a lógica para comparar com o período anterior
    // Para isso precisaria acessar os outros pontos de dados
    return Icon(
      Icons.touch_app,
      color: AppColors.colorTextMuted,
      size: 20.sp,
    );
  }
}

class _ChartDetailBottomSheet extends StatelessWidget {
  final ChartPointData point;
  final int index;
  final int total;
  final String Function(double) formatValue;
  final List<ChartPointData> data;

  const _ChartDetailBottomSheet({
    required this.point,
    required this.index,
    required this.total,
    required this.formatValue,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final prevPoint = index > 0 ? data[index - 1] : null;
    final nextPoint = index < data.length - 1 ? data[index + 1] : null;
    
    double? changeFromPrev;
    if (prevPoint != null && prevPoint.value > 0) {
      changeFromPrev = ((point.value - prevPoint.value) / prevPoint.value) * 100;
    }

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.colorBorderSubtle,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          
          // Título
          Row(
            children: [
              Icon(
                Icons.calendar_month,
                color: AppColors.colorBrandPrimary,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                point.fullLabel,
                style: TextStyle(
                  color: AppColors.colorTextPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Valor principal
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.colorBrandPrimary,
                  AppColors.colorBrandDark,
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(
                  'Total do Período',
                  style: TextStyle(
                    color: AppColors.colorTextOnDark.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  formatValue(point.value),
                  style: TextStyle(
                    color: AppColors.colorTextOnDark,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (changeFromPrev != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.colorTextOnDark.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          changeFromPrev > 0
                              ? Icons.arrow_upward
                              : Icons.arrow_downward,
                          color: AppColors.colorTextOnDark,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${changeFromPrev > 0 ? '+' : ''}${changeFromPrev.toStringAsFixed(1)}% vs anterior',
                          style: TextStyle(
                            color: AppColors.colorTextOnDark,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Comparação com outros períodos
          if (prevPoint != null || nextPoint != null) ...[
            Text(
              'Comparação',
              style: TextStyle(
                color: AppColors.colorTextPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (prevPoint != null)
                  Expanded(
                    child: _ComparisonCard(
                      label: 'Anterior',
                      period: prevPoint.label,
                      value: formatValue(prevPoint.value),
                    ),
                  ),
                if (prevPoint != null && nextPoint != null)
                  const SizedBox(width: 12),
                if (nextPoint != null)
                  Expanded(
                    child: _ComparisonCard(
                      label: 'Próximo',
                      period: nextPoint.label,
                      value: formatValue(nextPoint.value),
                    ),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _ComparisonCard extends StatelessWidget {
  final String label;
  final String period;
  final String value;

  const _ComparisonCard({
    required this.label,
    required this.period,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.colorBackgroundPrimary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.colorBorderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppColors.colorTextMuted,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            period,
            style: TextStyle(
              color: AppColors.colorTextPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: AppColors.colorTextMuted,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}



