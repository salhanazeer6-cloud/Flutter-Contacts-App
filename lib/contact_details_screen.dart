import 'package:contacts_app/screens/add_contact_screen.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../database/contact_database.dart';

const Color detailsMint = Color(0xFF75BDA7);
const Color detailsBackground = Color(0xFFF7FBF9);
const Color detailsText = Color(0xFF40534D);
const Color detailsBlue = Color(0xFFE5F0FA);

class ContactDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> contact;

  const ContactDetailsScreen({super.key, required this.contact});

  @override
  State<ContactDetailsScreen> createState() => _ContactDetailsScreenState();
}

class _ContactDetailsScreenState extends State<ContactDetailsScreen> {
  final ContactDatabase _database = ContactDatabase();

  late Map<String, dynamic> _contact;

  @override
  void initState() {
    super.initState();
    _contact = Map<String, dynamic>.from(widget.contact);
  }

  Future<void> _callContact() async {
    final phone = (_contact['phone'] ?? '').toString().trim();

    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phone number is not available.')),
      );
      return;
    }

    final phoneUri = Uri(scheme: 'tel', path: phone);

    try {
      final opened = await launchUrl(phoneUri);

      if (!opened && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the phone dialer.')),
        );
      }
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the phone dialer.')),
      );
    }
  }

  Future<void> _editContact() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (context) {
          return AddContactScreen(contact: _contact);
        },
      ),
    );

    if (!mounted || result != true) return;

    final updatedContacts = await _database.getContacts();

    final updatedContact = updatedContacts.firstWhere(
      (item) => item['id'] == _contact['id'],
      orElse: () => _contact,
    );

    if (!mounted) return;

    setState(() {
      _contact = Map<String, dynamic>.from(updatedContact);
    });

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final name = (_contact['name'] ?? '').toString();
    final phone = (_contact['phone'] ?? '').toString();
    final email = (_contact['email'] ?? '').toString();
    final isFavorite = _contact['isFavorite'] == 1;

    return Scaffold(
      backgroundColor: detailsBackground,
      appBar: AppBar(
        backgroundColor: detailsBackground,
        foregroundColor: detailsText,
        title: const Text(
          'Contact Details',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(22),
        children: [
          const SizedBox(height: 12),
          Center(
            child: CircleAvatar(
              radius: 52,
              backgroundColor: detailsBlue,
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: detailsText,
                  fontSize: 38,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Center(
            child: Text(
              name.isNotEmpty ? name : 'Unnamed Contact',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 27,
                fontWeight: FontWeight.bold,
                color: detailsText,
              ),
            ),
          ),
          const SizedBox(height: 7),
          Center(
            child: Text(
              isFavorite ? '★ Favourite contact' : 'Contact',
              style: const TextStyle(color: detailsMint, fontSize: 14),
            ),
          ),
          const SizedBox(height: 28),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              children: [
                _detailRow(
                  icon: Icons.phone_rounded,
                  title: 'Phone number',
                  value: phone,
                  iconColor: detailsMint,
                ),
                if (email.isNotEmpty) ...[
                  const Divider(height: 30, color: detailsBackground),
                  _detailRow(
                    icon: Icons.email_outlined,
                    title: 'Email address',
                    value: email,
                    iconColor: const Color(0xFF91AFCB),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 52,
            child: FilledButton.icon(
              onPressed: _callContact,
              icon: const Icon(Icons.call_rounded),
              label: const Text('Call Contact'),
              style: FilledButton.styleFrom(
                backgroundColor: detailsMint,
                foregroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 52,
            child: OutlinedButton.icon(
              onPressed: _editContact,
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Edit Contact'),
              style: OutlinedButton.styleFrom(
                foregroundColor: detailsMint,
                side: const BorderSide(color: detailsMint),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow({
    required IconData icon,
    required String title,
    required String value,
    required Color iconColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            color: detailsBackground,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(icon, color: iconColor),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 5),
              SelectableText(
                value,
                style: const TextStyle(
                  color: detailsText,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
