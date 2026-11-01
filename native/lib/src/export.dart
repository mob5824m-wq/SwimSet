import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'models.dart';

const XTypeGroup _jsonGroup = XTypeGroup(
  label: 'SwimSet JSON',
  extensions: ['json'],
  mimeTypes: ['application/json'],
);

/// Opens a JSON file chosen by the user, or null when cancelled.
Future<String?> pickJsonFile() async {
  final file = await openFile(acceptedTypeGroups: const [_jsonGroup]);
  if (file == null) return null;
  return file.readAsString();
}

/// Saves bytes through the platform save dialog, falling back to the app's
/// documents folder on platforms where the dialog is unavailable.
Future<String> saveBytes(String suggestedName, List<int> bytes) async {
  try {
    final location = await getSaveLocation(suggestedName: suggestedName);
    if (location != null) {
      final file = File(location.path);
      await file.writeAsBytes(bytes, flush: true);
      return file.path;
    }
  } catch (_) {
    // Fall through to the documents folder.
  }
  final directory = await getApplicationDocumentsDirectory();
  final file = File('${directory.path}/$suggestedName');
  await file.writeAsBytes(bytes, flush: true);
  return file.path;
}

String practiceJson(Practice practice) =>
    const JsonEncoder.withIndent('  ').convert(practice.toJson());

String slugify(String text) {
  var slug = text
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  if (slug.length > 60) slug = slug.substring(0, 60);
  return slug.isEmpty ? 'swimset' : slug;
}

Future<Uint8List> buildPracticePdf(Practice practice) async {
  final regular = pw.Font.ttf(await rootBundle.load('assets/fonts/Lato-Regular.ttf'));
  final bold = pw.Font.ttf(await rootBundle.load('assets/fonts/Lato-Bold.ttf'));
  final italic = pw.Font.ttf(await rootBundle.load('assets/fonts/Lato-Italic.ttf'));

  final document = pw.Document(
    title: practice.title,
    author: 'SwimSet',
    creator: 'SwimSet',
    theme: pw.ThemeData.withFont(base: regular, bold: bold, italic: italic),
  );

  final totals = practiceTotals(practice);
  final unit = practice.course.unit;
  final meta = [
    formatDate(practice.date),
    '${practice.course.code} · ${practice.course.poolLabel}',
    if (practice.group.isNotEmpty) practice.group,
    if (practice.focus.isNotEmpty) practice.focus,
  ].join('  ·  ');

  pw.Widget cell(String text,
          {bool header = false, double size = 9, pw.TextAlign align = pw.TextAlign.left}) =>
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5),
        child: pw.Text(
          text,
          textAlign: align,
          style: pw.TextStyle(
            fontSize: size,
            fontWeight: header ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: header ? PdfColors.grey800 : PdfColors.grey900,
          ),
        ),
      );

  final rows = <pw.TableRow>[
    pw.TableRow(
      decoration: const pw.BoxDecoration(color: PdfColors.grey100),
      children: [
        cell('#', header: true, size: 7.5),
        cell('TYPE', header: true, size: 7.5),
        cell('SET', header: true, size: 7.5),
        cell('ON', header: true, size: 7.5),
        cell('COMPLETED', header: true, size: 7.5),
      ],
    ),
  ];

  final expandedSets = expandSets(practice);
  for (var i = 0; i < expandedSets.length; i++) {
    final entry = expandedSets[i];
    final set = entry.set;
    final sendOff = sendOffForSet(set, practice);
    final notes = [
      if (set.notes.isNotEmpty) set.notes,
      if (set.equipment.isNotEmpty) 'w/ ${set.equipment.join(' + ')}',
    ].join('  ·  ');
    final checks = <pw.Widget>[
      for (var rep = 0; rep < set.reps && rep < 20; rep++)
        pw.Container(
          width: 7,
          height: 7,
          margin: const pw.EdgeInsets.only(right: 2.5, bottom: 2.5),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey500, width: 0.5),
          ),
        ),
      if (set.reps > 20) pw.Text('+${set.reps - 20}', style: const pw.TextStyle(fontSize: 7)),
    ];
    rows.add(pw.TableRow(
      children: [
        cell('${i + 1}', align: pw.TextAlign.center, size: 8.5),
        cell(set.type.label.toUpperCase(), size: 7.5),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (entry.rounds > 1)
                pw.Text(
                  'Round ${entry.round} of ${entry.rounds}',
                  style: pw.TextStyle(
                      fontSize: 7, color: PdfColors.grey600, fontWeight: pw.FontWeight.bold),
                ),
              pw.Text(
                '${set.reps} × ${set.distance} $unit ${set.stroke.label}',
                style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
              ),
              if (notes.isNotEmpty)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 1),
                  child: pw.Text(notes,
                      style: pw.TextStyle(
                          fontSize: 7.5, color: PdfColors.grey600, fontStyle: pw.FontStyle.italic)),
                ),
              if (practice.heats.isNotEmpty)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 2),
                  child: pw.Text(
                    practice.heats.map((heat) {
                      final heatSend = sendOffForSet(set, practice, heat: heat);
                      return '${heat.name} ${heatSend == null ? 'swim' : formatClock(heatSend)}';
                    }).join('  ·  '),
                    style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700),
                  ),
                ),
            ],
          ),
        ),
        cell(sendOff == null ? 'swim' : formatClock(sendOff), size: 9),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5),
          child: pw.Wrap(spacing: 0, runSpacing: 0, children: checks),
        ),
      ],
    ));
  }

  document.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(40, 36, 40, 32),
      footer: (context) => pw.Padding(
        padding: const pw.EdgeInsets.only(top: 10),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('SwimSet · swimset',
                style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey500)),
            pw.Text('Base pace and send-offs are targets; adjust on deck as needed.',
                style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey500)),
          ],
        ),
      ),
      build: (context) => [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(practice.title,
                      style: pw.TextStyle(fontSize: 26, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 4),
                  pw.Text(meta,
                      style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                ],
              ),
            ),
            pw.SizedBox(width: 24),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text('${formatNumber(totals.distance)} $unit',
                    style: pw.TextStyle(fontSize: 21, fontWeight: pw.FontWeight.bold)),
                pw.Text(
                    '${totals.setCount} sets · ${totals.reps} reps · ~${formatDuration(totals.seconds)}',
                    style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700)),
                pw.Text('Base pace ${formatClock(practice.basePace)} / 100 $unit',
                    style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700)),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Divider(color: PdfColors.grey800, thickness: 1.2),
        if (practice.heats.isNotEmpty) ...[
          pw.SizedBox(height: 6),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('HEATS',
                    style: pw.TextStyle(
                        fontSize: 7.5,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.grey700)),
                pw.SizedBox(width: 10),
                pw.Expanded(
                  child: pw.Wrap(
                    spacing: 14,
                    runSpacing: 3,
                    children: [
                      for (final heat in practice.heats)
                        pw.Text(
                            '${heat.name}: ${formatClock(basePaceForHeat(practice, heat))} / 100 $unit',
                            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey800)),
                      if (practice.heatInterval > 0)
                        pw.Text('starts every ${formatClock(practice.heatInterval)}',
                            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 8),
        ],
        pw.Table(
          columnWidths: const {
            0: pw.FixedColumnWidth(18),
            1: pw.FixedColumnWidth(52),
            2: pw.FlexColumnWidth(3),
            3: pw.FixedColumnWidth(38),
            4: pw.FixedColumnWidth(112),
          },
          border: const pw.TableBorder(
            horizontalInside: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
          ),
          children: rows,
        ),
        if (practice.notes.isNotEmpty) ...[
          pw.SizedBox(height: 14),
          pw.Text('NOTES',
              style: pw.TextStyle(
                  fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.grey600)),
          pw.SizedBox(height: 3),
          pw.Text(practice.notes,
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800)),
        ],
      ],
    ),
  );

  return document.save();
}
