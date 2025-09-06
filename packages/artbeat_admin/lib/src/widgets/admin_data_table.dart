import 'package:flutter/material.dart';

/// Reusable data table widget for admin dashboard
class AdminDataTable extends StatelessWidget {
  final List<String> columns;
  final List<List<dynamic>> rows;
  final bool sortable;
  final int? sortColumnIndex;
  final bool sortAscending;
  final void Function(int)? onSort;
  final bool showCheckboxColumn;
  final void Function(bool?)? onSelectAll;
  final void Function(int, bool?)? onSelectRow;
  final List<bool>? selectedRows;

  const AdminDataTable({
    super.key,
    required this.columns,
    required this.rows,
    this.sortable = false,
    this.sortColumnIndex,
    this.sortAscending = true,
    this.onSort,
    this.showCheckboxColumn = false,
    this.onSelectAll,
    this.onSelectRow,
    this.selectedRows,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: MediaQuery.of(context).size.width - 32,
        ),
        child: DataTable(
          showCheckboxColumn: showCheckboxColumn,
          sortColumnIndex: sortColumnIndex,
          sortAscending: sortAscending,
          columns: columns.asMap().entries.map((entry) {
            final column = entry.value;

            return DataColumn(
              label: Expanded(
                child: Text(
                  column,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              onSort: sortable && onSort != null
                  ? (columnIndex, ascending) => onSort!(columnIndex)
                  : null,
            );
          }).toList(),
          rows: rows.asMap().entries.map((entry) {
            final rowIndex = entry.key;
            final row = entry.value;

            return DataRow(
              selected: selectedRows != null &&
                  rowIndex < selectedRows!.length &&
                  selectedRows![rowIndex],
              onSelectChanged: onSelectRow != null
                  ? (selected) => onSelectRow!(rowIndex, selected)
                  : null,
              cells: row.map((cell) {
                return DataCell(
                  _buildCellContent(cell),
                );
              }).toList(),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildCellContent(dynamic cell) {
    if (cell is Widget) {
      return cell;
    } else if (cell is String) {
      return Text(cell);
    } else if (cell is num) {
      return Text(cell.toString());
    } else if (cell is bool) {
      return Icon(
        cell ? Icons.check_circle : Icons.cancel,
        color: cell ? Colors.green : Colors.red,
        size: 20,
      );
    } else {
      return Text(cell?.toString() ?? '');
    }
  }
}

/// Extension to provide additional functionality for AdminDataTable
extension AdminDataTableExtension on AdminDataTable {
  /// Create a sortable version of the table
  AdminDataTable sortable({
    required int sortColumnIndex,
    required bool sortAscending,
    required void Function(int) onSort,
  }) {
    return AdminDataTable(
      columns: columns,
      rows: rows,
      sortable: true,
      sortColumnIndex: sortColumnIndex,
      sortAscending: sortAscending,
      onSort: onSort,
      showCheckboxColumn: showCheckboxColumn,
      onSelectAll: onSelectAll,
      onSelectRow: onSelectRow,
      selectedRows: selectedRows,
    );
  }

  /// Create a selectable version of the table
  AdminDataTable selectable({
    required void Function(bool?) onSelectAll,
    required void Function(int, bool?) onSelectRow,
    required List<bool> selectedRows,
  }) {
    return AdminDataTable(
      columns: columns,
      rows: rows,
      sortable: this.sortable,
      sortColumnIndex: sortColumnIndex,
      sortAscending: sortAscending,
      onSort: onSort,
      showCheckboxColumn: true,
      onSelectAll: onSelectAll,
      onSelectRow: onSelectRow,
      selectedRows: selectedRows,
    );
  }
}
