// lib/resident/presentation/fees_page.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../admin/data/fees_repository.dart';
import '../../.authentication/data/auth_service.dart';
import '../../../core/theme/app_theme.dart';

class FeesPage extends StatefulWidget {
  final AuthenticationService authService;
  final String uid;
  final String idToken;

  const FeesPage({
    super.key,
    required this.authService,
    required this.uid,
    required this.idToken,
  });

  @override
  _FeesPageState createState() => _FeesPageState();
}

class _FeesPageState extends State<FeesPage> {
  late FeesRepository feesRepository;
  List<dynamic> allFees = [];
  List<dynamic> filteredFees = [];
  bool isLoading = true;
  String selectedFilter = 'Tất cả';
  String searchQuery = '';
  
  final NumberFormat currencyFormat = NumberFormat('#,##0', 'vi_VN');

  @override
  void initState() {
    super.initState();
    feesRepository = FeesRepository(
      apiKey: widget.authService.apiKey,
      projectId: widget.authService.projectId,
    );
    _loadFees();
  }

  Future<void> _loadFees() async {
    setState(() {
      isLoading = true;
    });

    try {
      final fees = await feesRepository.fetchAllFees(widget.idToken);
      setState(() {
        allFees = fees;
        _applyFilters();
        isLoading = false;
      });
    } catch (e) {
      print('Lỗi khi tải phí: $e');
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể tải danh sách phí: $e')),
      );
    }
  }

  void _applyFilters() {
    filteredFees = allFees.where((fee) {
      final fields = fee['fields'];
      final name = fields['name']?['stringValue'] ?? '';
      final frequency = fields['frequency']?['stringValue'] ?? '';
      final commonFee = fields['commonFee']?['booleanValue'] ?? false;

      // Filter by category
      bool matchesCategory = selectedFilter == 'Tất cả' ||
          (selectedFilter == 'Phí chung' && commonFee) ||
          (selectedFilter == 'Đóng góp' && !commonFee) ||
          (selectedFilter == frequency);

      // Filter by search query
      bool matchesSearch = searchQuery.isEmpty ||
          name.toLowerCase().contains(searchQuery.toLowerCase());

      return matchesCategory && matchesSearch;
    }).toList();

    // Sort by due date
    filteredFees.sort((a, b) {
      final dueDateA = a['fields']['dueDate']?['stringValue'] ?? '';
      final dueDateB = b['fields']['dueDate']?['stringValue'] ?? '';
      return dueDateA.compareTo(dueDateB);
    });
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  String _getFrequencyLabel(String frequency) {
    const Map<String, String> frequencyMap = {
      'Hàng tháng': 'Tháng',
      'Hàng quý': 'Quý',
      'Hàng năm': 'Năm',
      'Không bắt buộc': 'Tự nguyện',
    };
    return frequencyMap[frequency] ?? frequency;
  }

  Color _getFeeTypeColor(bool isCommonFee) {
    return isCommonFee ? AppTheme.accentColor2 : AppTheme.successColor;
  }

  IconData _getFeeTypeIcon(bool isCommonFee) {
    return isCommonFee ? Icons.account_balance : Icons.volunteer_activism;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Phí & Đóng góp',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppTheme.primaryColor,
        elevation: 2,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFees,
            tooltip: 'Tải lại',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Section
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm khoản phí...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value;
                      _applyFilters();
                    });
                  },
                ),
                const SizedBox(height: 12),
                // Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('Tất cả'),
                      _buildFilterChip('Phí chung'),
                      _buildFilterChip('Đóng góp'),
                      _buildFilterChip('Hàng tháng'),
                      _buildFilterChip('Hàng quý'),
                      _buildFilterChip('Hàng năm'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Fees List
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredFees.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inbox_outlined,
                                size: 80, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'Không có khoản phí nào',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadFees,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredFees.length,
                          itemBuilder: (context, index) {
                            return _buildFeeCard(filteredFees[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = selectedFilter == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            selectedFilter = label;
            _applyFilters();
          });
        },
        backgroundColor: Colors.white,
        selectedColor: AppTheme.accentColor2.withOpacity(0.2),
        checkmarkColor: AppTheme.primaryColor,
        labelStyle: TextStyle(
          color: isSelected ? AppTheme.primaryColor : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        side: BorderSide(
          color: isSelected ? AppTheme.primaryColor : Colors.grey[300]!,
        ),
      ),
    );
  }

  Widget _buildFeeCard(Map<String, dynamic> fee) {
    final fields = fee['fields'];
    final name = fields['name']?['stringValue'] ?? 'Không có tên';
    final description = fields['description']?['stringValue'] ?? '';
    final amount = fields['amount']?['integerValue'] ?? '0';
    final frequency = fields['frequency']?['stringValue'] ?? '';
    final dueDate = fields['dueDate']?['stringValue'] ?? '';
    final commonFee = fields['commonFee']?['booleanValue'] ?? false;

    final amountInt = int.tryParse(amount.toString()) ?? 0;
    final isOverdue = _isOverdue(dueDate);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isOverdue ? AppTheme.dangerColor.withOpacity(0.3) : Colors.grey[200]!,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: () => _showFeeDetails(fee),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getFeeTypeColor(commonFee).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getFeeTypeIcon(commonFee),
                      color: _getFeeTypeColor(commonFee),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _getFeeTypeColor(commonFee).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                commonFee ? 'Phí chung' : 'Đóng góp',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _getFeeTypeColor(commonFee),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            if (frequency.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Text(
                                _getFrequencyLabel(frequency),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (description.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Số tiền',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${currencyFormat.format(amountInt)} ₫',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  if (dueDate.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Hạn thanh toán',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isOverdue
                                ? AppTheme.dangerColor.withOpacity(0.1)
                                : AppTheme.successColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isOverdue
                                    ? Icons.warning_amber_rounded
                                    : Icons.calendar_today,
                                size: 14,
                                color: isOverdue ? AppTheme.dangerColor : AppTheme.successColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _formatDate(dueDate),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: isOverdue
                                      ? AppTheme.dangerColor
                                      : AppTheme.successColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isOverdue(String dueDate) {
    if (dueDate.isEmpty) return false;
    try {
      final date = DateTime.parse(dueDate);
      return date.isBefore(DateTime.now());
    } catch (e) {
      return false;
    }
  }

  void _showFeeDetails(Map<String, dynamic> fee) {
    final fields = fee['fields'];
    final name = fields['name']?['stringValue'] ?? 'Không có tên';
    final description = fields['description']?['stringValue'] ?? 'Không có mô tả';
    final amount = fields['amount']?['integerValue'] ?? '0';
    final frequency = fields['frequency']?['stringValue'] ?? 'Không rõ';
    final dueDate = fields['dueDate']?['stringValue'] ?? '';
    final commonFee = fields['commonFee']?['booleanValue'] ?? false;

    final amountInt = int.tryParse(amount.toString()) ?? 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _getFeeTypeColor(commonFee).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getFeeTypeIcon(commonFee),
                        color: _getFeeTypeColor(commonFee),
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getFeeTypeColor(commonFee).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              commonFee ? 'Phí chung' : 'Đóng góp',
                              style: TextStyle(
                                fontSize: 12,
                                color: _getFeeTypeColor(commonFee),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildDetailRow(
                  'Mô tả',
                  description,
                  Icons.description_outlined,
                ),
                const SizedBox(height: 16),
                _buildDetailRow(
                  'Số tiền',
                  '${currencyFormat.format(amountInt)} ₫',
                  Icons.attach_money,
                  valueColor: AppTheme.primaryColor,
                  valueBold: true,
                ),
                const SizedBox(height: 16),
                _buildDetailRow(
                  'Chu kỳ',
                  frequency,
                  Icons.loop,
                ),
                if (dueDate.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildDetailRow(
                    'Hạn thanh toán',
                    _formatDate(dueDate),
                    Icons.calendar_today,
                    valueColor: _isOverdue(dueDate)
                        ? AppTheme.dangerColor
                        : AppTheme.successColor,
                  ),
                ],
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _showPaymentDialog(fee);
                    },
                    icon: const Icon(Icons.payment),
                    label: const Text(
                      'Thanh toán',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
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

  Widget _buildDetailRow(
    String label,
    String value,
    IconData icon, {
    Color? valueColor,
    bool valueBold = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  color: valueColor ?? Colors.black87,
                  fontWeight: valueBold ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showPaymentDialog(Map<String, dynamic> fee) {
    final fields = fee['fields'];
    final name = fields['name']?['stringValue'] ?? '';
    final amount = fields['amount']?['integerValue'] ?? '0';
    final amountInt = int.tryParse(amount.toString()) ?? 0;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận thanh toán'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bạn có chắc chắn muốn thanh toán khoản phí:'),
            const SizedBox(height: 12),
            Text(
              name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Số tiền: ${currencyFormat.format(amountInt)} ₫',
              style: TextStyle(
                color: Colors.blue.shade700,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.warningColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.warningColor.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Image.asset(
                    'assets/QR/thanhtoan.jpg',
                    width: 500,
                    height: 500,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Quét mã QR để thanh toán',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Chức năng thanh toán đang được phát triển'),
                  backgroundColor: AppTheme.warningColor,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
  }
}
