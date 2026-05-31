import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class PartnerService {
  final _db = FirebaseFirestore.instance;

  Future<String?> sendInvitation(String currentUid, String toEmail) async {
    final currentDoc = await _db.collection('users').doc(currentUid).get();
    final currentData = currentDoc.data()!;

    if (toEmail == currentData['email']) {
      return 'Vous ne pouvez pas vous inviter vous-même';
    }

    final targetQuery = await _db
        .collection('users')
        .where('email', isEqualTo: toEmail)
        .limit(1)
        .get();
    if (targetQuery.docs.isEmpty) {
      return 'Aucun compte trouvé avec cet email';
    }

    final targetData = targetQuery.docs.first.data();
    if (targetData['partnerId'] != null) {
      return 'Cet utilisateur est déjà connecté à un partenaire';
    }

    if (currentData['partnerId'] != null) {
      return 'Vous êtes déjà connecté à un partenaire';
    }

    final pendingQuery = await _db
        .collection('invitations')
        .where('fromUid', isEqualTo: currentUid)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();
    if (pendingQuery.docs.isNotEmpty) {
      return 'Une invitation est déjà en attente';
    }

    await _db.collection('invitations').add({
      'fromUid': currentUid,
      'fromEmail': currentData['email'],
      'toEmail': toEmail,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });

    await _db.collection('users').doc(currentUid).update({
      'partnerEmail': toEmail,
    });

    return null;
  }

  Future<void> cancelInvitation(String currentUid) async {
    final query = await _db
        .collection('invitations')
        .where('fromUid', isEqualTo: currentUid)
        .where('status', isEqualTo: 'pending')
        .get();

    final batch = _db.batch();
    for (final doc in query.docs) {
      batch.delete(doc.reference);
    }
    batch.update(
      _db.collection('users').doc(currentUid),
      {'partnerEmail': null},
    );
    await batch.commit();
  }

  Future<void> checkAndShowPendingInvitation(
    BuildContext context,
    String currentUid,
    String currentEmail,
  ) async {
    final query = await _db
        .collection('invitations')
        .where('toEmail', isEqualTo: currentEmail)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();

    if (query.docs.isEmpty) return;
    if (!context.mounted) return;

    final invitationDoc = query.docs.first;
    final fromUid = invitationDoc.data()['fromUid'] as String;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.favorite, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Invitation reçue'),
          ],
        ),
        content: const Text(
          'Une personne vous a invité à rejoindre WePact. Accepter ?',
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await invitationDoc.reference.update({'status': 'declined'});
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text(
              'Refuser',
              style: TextStyle(color: AppColors.textGrey),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final now = Timestamp.now();
              final inviterDoc =
                  await _db.collection('users').doc(fromUid).get();
              final inviterEmail = inviterDoc.data()?['email'] as String?;

              await Future.wait([
                _db.collection('users').doc(currentUid).update({
                  'partnerId': fromUid,
                  'partnerEmail': inviterEmail,
                  'partnerSince': now,
                }),
                _db.collection('users').doc(fromUid).update({
                  'partnerId': currentUid,
                  'partnerEmail': currentEmail,
                  'partnerSince': now,
                }),
                invitationDoc.reference.update({'status': 'accepted'}),
              ]);

              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/home');
              }
            },
            child: const Text('Accepter'),
          ),
        ],
      ),
    );
  }
}
