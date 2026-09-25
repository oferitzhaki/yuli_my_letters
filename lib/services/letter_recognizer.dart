// lib/services/letter_recognizer.dart
// Recognises a hand-written Hebrew letter by comparing its shape with
// every letter drawn in the app's font.
//
// Both the drawing and each letter are scaled into a small 32x32 grid,
// thinned to 1-pixel lines, and compared with a "chamfer distance":
// the average distance from each line pixel of one shape to the nearest
// line pixel of the other (both ways), plus a small penalty when the
// width/height proportions differ. Lower score = more similar.
//
// This is an approximation (no machine learning), tuned to be forgiving.
// Look-alike letters (ד/ר, ה/ח/ת, ו/י) are sometimes confused.

import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../constants/hebrew_characters.dart';

const int _n = 32;

class _Shape {
  _Shape(this.grid, this.distance, this.aspect);
  final List<bool> grid;
  final List<double> distance;
  final double aspect;
}

class LetterRecognizer {
  LetterRecognizer._();
  static final LetterRecognizer instance = LetterRecognizer._();

  final Map<String, _Shape> _templates = {};
  final Map<String, Future<void>> _preparing = {};

  /// Builds the templates for one alphabet once (a moment the first time).
  Future<void> prepare(List<HebrewCharacter> letters) =>
      _preparing[letters.first.id] ??= _prepareAll(letters);

  Future<void> _prepareAll(List<HebrewCharacter> letters) async {
    for (final c in letters) {
      for (var attempt = 0; attempt < 8; attempt++) {
        final shape = await _renderLetter(c.letter);
        if (shape != null) {
          _templates[c.id] = shape;
          break;
        }
        // Font may still be loading on the web - wait and retry.
        await Future.delayed(const Duration(milliseconds: 400));
      }
    }
  }

  /// The given letters, ordered from most to least similar to the drawing.
  List<({String id, double score})> rank(
    List<List<Offset>> strokes,
    List<HebrewCharacter> letters,
  ) {
    final drawing = _shapeFromStrokes(strokes);
    if (drawing == null) return const [];
    final results = [
      for (final c in letters)
        if (_templates[c.id] != null)
          (id: c.id, score: _score(drawing, _templates[c.id]!)),
    ]..sort((a, b) => a.score.compareTo(b.score));
    return results;
  }

  // ---------- shapes ----------

  Future<_Shape?> _renderLetter(String letter) async {
    const size = 256;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final tp = TextPainter(
      text: TextSpan(
        text: letter,
        style: const TextStyle(
          fontSize: 160,
          color: Color(0xFF000000),
          height: 1.0,
        ),
      ),
      textDirection: TextDirection.rtl,
    )..layout();
    tp.paint(canvas, Offset((size - tp.width) / 2, (size - tp.height) / 2));
    final image = await recorder.endRecording().toImage(size, size);
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    image.dispose();
    if (data == null) return null;

    final bytes = data.buffer.asUint8List();
    final points = <Offset>[];
    for (var y = 0; y < size; y++) {
      for (var x = 0; x < size; x++) {
        if (bytes[(y * size + x) * 4 + 3] > 100) {
          points.add(Offset(x.toDouble(), y.toDouble()));
        }
      }
    }
    if (points.length < 50) return null;

    final box = _Box.of(points);
    final grid = List<bool>.filled(_n * _n, false);
    for (final p in points) {
      _set(grid, box.toGrid(p));
    }
    final thin = _thin(grid);
    return _Shape(thin, _distanceMap(thin), box.aspect);
  }

  _Shape? _shapeFromStrokes(List<List<Offset>> strokes) {
    final all = [for (final s in strokes) ...s];
    if (all.length < 2) return null;
    final box = _Box.of(all);
    final grid = List<bool>.filled(_n * _n, false);
    for (final stroke in strokes) {
      for (var i = 0; i < stroke.length; i++) {
        final a = box.toGrid(stroke[i]);
        final b = box.toGrid(stroke[i + 1 < stroke.length ? i + 1 : i]);
        final steps = max(1, ((b - a).distance * 2).ceil());
        for (var s = 0; s <= steps; s++) {
          _set(grid, Offset.lerp(a, b, s / steps)!);
        }
      }
    }
    return _Shape(grid, _distanceMap(grid), box.aspect);
  }

  void _set(List<bool> grid, Offset p) {
    final x = p.dx.round().clamp(0, _n - 1);
    final y = p.dy.round().clamp(0, _n - 1);
    grid[y * _n + x] = true;
  }

  double _score(_Shape a, _Shape b) {
    double sumA = 0, sumB = 0;
    var countA = 0, countB = 0;
    for (var i = 0; i < _n * _n; i++) {
      if (a.grid[i]) {
        sumA += b.distance[i];
        countA++;
      }
      if (b.grid[i]) {
        sumB += a.distance[i];
        countB++;
      }
    }
    if (countA == 0 || countB == 0) return double.infinity;
    double clampAspect(double v) => v.clamp(0.2, 5.0).toDouble();
    final aspectPenalty =
        log(clampAspect(a.aspect) / clampAspect(b.aspect)).abs();
    return (sumA / countA + sumB / countB) / 2 + 2.0 * aspectPenalty;
  }

  // ---------- image helpers ----------

  /// Distance from every cell to the nearest line cell (two-pass chamfer).
  List<double> _distanceMap(List<bool> grid) {
    const big = 1e9;
    const diag = 1.4142;
    final d = List<double>.generate(_n * _n, (i) => grid[i] ? 0 : big);
    for (var y = 0; y < _n; y++) {
      for (var x = 0; x < _n; x++) {
        final i = y * _n + x;
        var v = d[i];
        if (x > 0) v = min(v, d[i - 1] + 1);
        if (y > 0) {
          v = min(v, d[i - _n] + 1);
          if (x > 0) v = min(v, d[i - _n - 1] + diag);
          if (x < _n - 1) v = min(v, d[i - _n + 1] + diag);
        }
        d[i] = v;
      }
    }
    for (var y = _n - 1; y >= 0; y--) {
      for (var x = _n - 1; x >= 0; x--) {
        final i = y * _n + x;
        var v = d[i];
        if (x < _n - 1) v = min(v, d[i + 1] + 1);
        if (y < _n - 1) {
          v = min(v, d[i + _n] + 1);
          if (x < _n - 1) v = min(v, d[i + _n + 1] + diag);
          if (x > 0) v = min(v, d[i + _n - 1] + diag);
        }
        d[i] = v;
      }
    }
    return d;
  }

  /// Zhang-Suen thinning: reduces filled shapes to 1-pixel lines.
  List<bool> _thin(List<bool> input) {
    final g = List<bool>.of(input);
    bool at(int x, int y) =>
        x >= 0 && y >= 0 && x < _n && y < _n && g[y * _n + x];
    var changed = true;
    while (changed) {
      changed = false;
      for (var pass = 0; pass < 2; pass++) {
        final remove = <int>[];
        for (var y = 0; y < _n; y++) {
          for (var x = 0; x < _n; x++) {
            if (!g[y * _n + x]) continue;
            final p = [
              at(x, y - 1), at(x + 1, y - 1), at(x + 1, y),
              at(x + 1, y + 1), at(x, y + 1), at(x - 1, y + 1),
              at(x - 1, y), at(x - 1, y - 1),
            ];
            final neighbours = p.where((v) => v).length;
            if (neighbours < 2 || neighbours > 6) continue;
            var transitions = 0;
            for (var k = 0; k < 8; k++) {
              if (!p[k] && p[(k + 1) % 8]) transitions++;
            }
            if (transitions != 1) continue;
            if (pass == 0) {
              if (p[0] && p[2] && p[4]) continue;
              if (p[2] && p[4] && p[6]) continue;
            } else {
              if (p[0] && p[2] && p[6]) continue;
              if (p[0] && p[4] && p[6]) continue;
            }
            remove.add(y * _n + x);
          }
        }
        for (final i in remove) {
          g[i] = false;
        }
        if (remove.isNotEmpty) changed = true;
      }
    }
    return g;
  }
}

/// Bounding box that maps points into the grid, keeping proportions.
class _Box {
  _Box(this.minX, this.minY, this.width, this.height);

  factory _Box.of(List<Offset> points) {
    var minX = double.infinity, minY = double.infinity;
    var maxX = -double.infinity, maxY = -double.infinity;
    for (final p in points) {
      minX = min(minX, p.dx);
      minY = min(minY, p.dy);
      maxX = max(maxX, p.dx);
      maxY = max(maxY, p.dy);
    }
    return _Box(minX, minY, max(maxX - minX, 1e-6), max(maxY - minY, 1e-6));
  }

  final double minX, minY, width, height;

  double get aspect => width / height;

  Offset toGrid(Offset p) {
    final scale = (_n - 3) / max(width, height);
    final offsetX = (_n - 1 - width * scale) / 2;
    final offsetY = (_n - 1 - height * scale) / 2;
    return Offset(
      (p.dx - minX) * scale + offsetX,
      (p.dy - minY) * scale + offsetY,
    );
  }
}
