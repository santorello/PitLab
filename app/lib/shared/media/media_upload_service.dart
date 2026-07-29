import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/application/auth_providers.dart';
import 'media_upload_state.dart';

// ── Bucket e path convention ───────────────────────────────────────────────────
//
//  Bucket pubblico unico: "media"
//  Path obbligatorio: <user_id>/<entity_type>/<filename>
//  entity_type ammessi: tracks | shops | events | spots | profiles | builds | places
//  Filename: <prefix>-<timestamp_ms>.<ext>  es. cover-1718012345678.jpg
//
// ── Limiti bucket (applicati lato Supabase) ───────────────────────────────────
//  Dimensione massima: 5 MB
//  MIME ammessi: image/jpeg, image/png, image/webp, image/gif
//
// ── Progresso ─────────────────────────────────────────────────────────────────
//  L'SDK supabase_flutter non espone progress nativo per upload singolo.
//  Il progresso reale viene modellato come avanzamento per-file della coda:
//   - preparing  (0.05 → 0.50): resize + encode lato client
//   - uploading  (0.50 → 0.95): upload binario su Storage
//   - done       (1.0)         : URL persistente disponibile
//  Il chiamante gestisce il MediaUploadController; questo servizio chiama
//  [onProgress] con lo stage e il valore normalizzato [0, 1].

const _mediaBucket = 'media';
const _maxInputBytes = 5 * 1024 * 1024; // 5 MB — limite bucket

// Resize target: lato lungo 1600 px, qualità 82 JPEG.
// TODO: se in futuro si aggiunge flutter_image_compress, sostituire
// _prepareBytes con la versione nativa (più veloce su mobile, EXIF corretto).
const _maxDimension = 1600;
const _encodeQuality = 82;

/// Risultato di un upload andato a buon fine.
class MediaUploadResult {
  const MediaUploadResult({
    required this.publicUrl,
    required this.storagePath,
    required this.mimeType,
    required this.bytesUploaded,
  });

  final String publicUrl;
  final String storagePath;
  final String mimeType;
  final int bytesUploaded;
}

/// Eccezione specifica del layer upload — porta sempre un messaggio leggibile
/// dall'utente (già localizzato al momento del lancio).
class MediaUploadException implements Exception {
  const MediaUploadException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => 'MediaUploadException: $message${cause != null ? ' (cause: $cause)' : ''}';
}

/// Servizio centrale per upload di immagini su Supabase Storage.
///
/// Responsabilità:
///  1. Validazione MIME e size lato client.
///  2. Resize/compress con il package `image` già presente.
///  3. EXIF orientation fix.
///  4. Upload binario su Storage (`uploadBinary`).
///  5. Ritorna la public URL persistente.
///
/// NON gestisce moderazione, NON ha logica di prodotto su chi può caricare cosa
/// (quella sta nei provider Riverpod delle singole feature).
class MediaUploadService {
  const MediaUploadService(this._client);

  final SupabaseClient _client;

  /// Carica [bytes] su Storage e restituisce il risultato con la public URL.
  ///
  /// [userId]      – ID dell'utente autenticato (primo segmento del path).
  /// [entityType]  – tipo entità: tracks | shops | events | spots | profiles | builds | places
  /// [filePrefix]  – prefisso del nome file, es. "cover", "avatar", "gallery"
  /// [onProgress]  – callback opzionale (stage, progress in [0,1])
  Future<MediaUploadResult> uploadImage({
    required Uint8List bytes,
    required String userId,
    required String entityType,
    required String filePrefix,
    void Function(MediaUploadStage stage, double progress)? onProgress,
  }) async {
    // ── Guard: utente autenticato ─────────────────────────────────────────────
    if (userId.trim().isEmpty) {
      throw const MediaUploadException(
        'Devi essere autenticato per caricare immagini.',
      );
    }

    // ── Validazione dimensione input ───────────────────────────────────────────
    if (bytes.lengthInBytes > _maxInputBytes) {
      throw const MediaUploadException(
        'L\'immagine supera il limite di 5 MB. Scegli un file più piccolo.',
      );
    }

    onProgress?.call(MediaUploadStage.preparing, 0.05);

    // ── Decode + EXIF orientation fix ─────────────────────────────────────────
    final source = img.decodeImage(bytes);
    if (source == null) {
      throw const MediaUploadException(
        'Non è stato possibile leggere l\'immagine selezionata.',
      );
    }
    onProgress?.call(MediaUploadStage.preparing, 0.20);

    final oriented = img.bakeOrientation(source);
    onProgress?.call(MediaUploadStage.preparing, 0.30);

    // ── Resize ────────────────────────────────────────────────────────────────
    final resized = _resizeLongEdge(oriented, _maxDimension);
    onProgress?.call(MediaUploadStage.preparing, 0.40);

    // ── Encode JPEG ───────────────────────────────────────────────────────────
    final encoded = Uint8List.fromList(
      img.encodeJpg(resized, quality: _encodeQuality),
    );
    onProgress?.call(MediaUploadStage.preparing, 0.50);

    // ── Validazione dimensione output ─────────────────────────────────────────
    if (encoded.lengthInBytes > _maxInputBytes) {
      throw const MediaUploadException(
        'L\'immagine elaborata supera ancora 5 MB. Prova con un\'immagine più piccola.',
      );
    }

    // ── Genera path univoco ───────────────────────────────────────────────────
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filename = '$filePrefix-$timestamp.jpg';
    final storagePath = '$userId/$entityType/$filename';
    const mimeType = 'image/jpeg';

    onProgress?.call(MediaUploadStage.uploading, 0.55);

    // ── Upload binario ────────────────────────────────────────────────────────
    try {
      await _client.storage.from(_mediaBucket).uploadBinary(
        storagePath,
        encoded,
        fileOptions: const FileOptions(
          contentType: mimeType,
          upsert: false,
        ),
      );
    } on StorageException catch (e) {
      throw MediaUploadException(
        'Errore durante il caricamento dell\'immagine (${e.statusCode ?? e.message}). Riprova.',
        cause: e,
      );
    } catch (e) {
      throw MediaUploadException(
        'Errore imprevisto durante il caricamento. Riprova.',
        cause: e,
      );
    }

    onProgress?.call(MediaUploadStage.uploading, 0.95);

    // ── Ottieni public URL ────────────────────────────────────────────────────
    final publicUrl = _client.storage
        .from(_mediaBucket)
        .getPublicUrl(storagePath);

    onProgress?.call(MediaUploadStage.done, 1.0);

    debugPrint('[MediaUploadService] uploaded → $publicUrl (${encoded.lengthInBytes} bytes)');

    return MediaUploadResult(
      publicUrl: publicUrl,
      storagePath: storagePath,
      mimeType: mimeType,
      bytesUploaded: encoded.lengthInBytes,
    );
  }

  /// Elimina un file da Storage dato il path completo.
  /// Non lancia eccezioni se il file non esiste (silenzioso).
  Future<void> deleteImage({required String storagePath}) async {
    try {
      await _client.storage.from(_mediaBucket).remove([storagePath]);
    } catch (e) {
      debugPrint('[MediaUploadService] deleteImage failed for $storagePath: $e');
    }
  }
}

// ── Helpers privati ───────────────────────────────────────────────────────────

img.Image _resizeLongEdge(img.Image source, int maxDimension) {
  if (source.width <= maxDimension && source.height <= maxDimension) {
    return source;
  }
  if (source.width >= source.height) {
    return img.copyResize(source, width: maxDimension, maintainAspect: true);
  }
  return img.copyResize(source, height: maxDimension, maintainAspect: true);
}

// ── Provider Riverpod ─────────────────────────────────────────────────────────

final mediaUploadServiceProvider = Provider<MediaUploadService?>((ref) {
  final client = ref.watch(authClientProvider);
  if (client == null) return null;
  return MediaUploadService(client);
});
