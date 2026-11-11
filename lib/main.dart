import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const MyContactsApp());
}

const mint = Color(0xFFBFE8D5);
const mintDark = Color(0xFF39765B);
const mintLight = Color(0xFFEAF7F0);
const cream = Color(0xFFFFFCF7);
const ink = Color(0xFF34483D);
const softPink = Color(0xFFF8DCE7);

class MyContactsApp extends StatelessWidget {
  const MyContactsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'My Contacts',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: cream,
        colorScheme: ColorScheme.fromSeed(seedColor: mintDark),
        appBarTheme: const AppBarTheme(
          backgroundColor: cream,
          foregroundColor: ink,
          elevation: 0,
        ),
      ),
      home: const ContactsScreen(),
    );
  }
}

// DATABASE

class ContactStore {
  static Database? _db;

  static Future<Database> get db async {
    if (_db != null) return _db!;

    final location = p.join(await getDatabasesPath(), 'contacts.db');

    _db = await openDatabase(
      location,
      version: 1,
      onCreate: (database, version) async {
        await database.execute('''
          CREATE TABLE contacts (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            phone TEXT NOT NULL,
            email TEXT,
            isFavorite INTEGER NOT NULL DEFAULT 0
          )
        ''');
      },
    );

    return _db!;
  }

  static Future<List<Map<String, dynamic>>> all() async {
    final database = await db;
    return database.query('contacts', orderBy: 'name COLLATE NOCASE ASC');
  }

  static Future<void> save({
    int? id,
    required String name,
    required String phone,
    required String email,
    bool favorite = false,
  }) async {
    final database = await db;

    final values = {
      'name': name.trim(),
      'phone': phone.trim(),
      'email': email.trim(),
      'isFavorite': favorite ? 1 : 0,
    };

    if (id == null) {
      await database.insert('contacts', values);
    } else {
      await database.update(
        'contacts',
        values,
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }

  static Future<void> remove(int id) async {
    final database = await db;
    await database.delete('contacts', where: 'id = ?', whereArgs: [id]);
  }
}

// CONTACTS SCREEN

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  List<Map<String, dynamic>> contacts = [];
  final search = TextEditingController();

  bool onlyFavorites = false;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadContacts();
    search.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  Future<void> loadContacts() async {
    try {
      final result = await ContactStore.all();
      if (!mounted) return;

      setState(() {
        contacts = result;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => loading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Could not load contacts: $e')));
    }
  }

  List<Map<String, dynamic>> get visibleContacts {
    return contacts.where((c) {
      final query = search.text.toLowerCase();
      final name = (c['name'] ?? '').toString();
      final phone = (c['phone'] ?? '').toString();

      final matchesSearch =
          name.toLowerCase().contains(query) || phone.contains(search.text);

      final matchesFavorite = !onlyFavorites || c['isFavorite'] == 1;

      return matchesSearch && matchesFavorite;
    }).toList();
  }

  Future<void> openEditor([Map<String, dynamic>? contact]) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => ContactForm(contact: contact)),
    );

    if (result == true) loadContacts();
  }

  Future<void> toggleFavorite(Map<String, dynamic> c) async {
    await ContactStore.save(
      id: c['id'] as int,
      name: c['name'] as String,
      phone: c['phone'] as String,
      email: (c['email'] ?? '').toString(),
      favorite: c['isFavorite'] != 1,
    );

    await loadContacts();
  }

  Future<void> deleteContact(Map<String, dynamic> c) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete contact?'),
        content: Text('Delete ${c['name']} from your contacts?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ContactStore.remove(c['id'] as int);
      await loadContacts();
    }
  }

  Future<void> callContact(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);

    if (!await launchUrl(uri)) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not open phone app')));
    }
  }

  Widget filterButton(String text, bool selected, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: selected ? mintDark : Colors.white,
        foregroundColor: selected ? Colors.white : ink,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      child: Text(text),
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = visibleContacts;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Contacts',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: mintDark,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Favourites',
            onPressed: () {
              setState(() {
                onlyFavorites = !onlyFavorites;
              });
            },
            icon: Icon(
              onlyFavorites ? Icons.favorite : Icons.favorite_border,
              color: softPink.computeLuminance() < 0.5 ? Colors.pink : mintDark,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => openEditor(),
        backgroundColor: mintDark,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add, size: 30),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: mintDark))
          : Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: search,
                    decoration: InputDecoration(
                      hintText: 'Search contacts...',
                      prefixIcon: const Icon(Icons.search, color: mintDark),
                      suffixIcon: search.text.isEmpty
                          ? null
                          : IconButton(
                              onPressed: search.clear,
                              icon: const Icon(Icons.close),
                            ),
                      filled: true,
                      fillColor: mintLight,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(22),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: filterButton(
                          'All Contacts',
                          !onlyFavorites,
                          () => setState(() => onlyFavorites = false),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: filterButton(
                          'Favourites ♥',
                          onlyFavorites,
                          () => setState(() => onlyFavorites = true),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: list.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.contacts_outlined,
                                  size: 64,
                                  color: mintDark,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  search.text.isNotEmpty
                                      ? 'No matching contacts'
                                      : onlyFavorites
                                      ? 'No favourites yet'
                                      : 'Your contacts will appear here',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: ink,
                                    fontSize: 16,
                                  ),
                                ),
                                if (!onlyFavorites && search.text.isEmpty)
                                  TextButton.icon(
                                    onPressed: () => openEditor(),
                                    icon: const Icon(Icons.add),
                                    label: const Text('Add your first contact'),
                                  ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: list.length,
                            itemBuilder: (context, index) {
                              final c = list[index];
                              final name = (c['name'] ?? '').toString();
                              final phone = (c['phone'] ?? '').toString();
                              final initial = name.isEmpty
                                  ? '?'
                                  : name[0].toUpperCase();

                              final showLetter =
                                  index == 0 ||
                                  list[index - 1]['name']
                                          .toString()
                                          .substring(0, 1)
                                          .toUpperCase() !=
                                      initial;

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (showLetter)
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        5,
                                        12,
                                        0,
                                        8,
                                      ),
                                      child: Text(
                                        initial,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 17,
                                          color: mintDark,
                                        ),
                                      ),
                                    ),
                                  Card(
                                    color: Colors.white,
                                    elevation: 1,
                                    margin: const EdgeInsets.only(bottom: 9),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    child: ListTile(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 4,
                                          ),
                                      leading: CircleAvatar(
                                        radius: 25,
                                        backgroundColor: mint,
                                        child: Text(
                                          initial,
                                          style: const TextStyle(
                                            color: mintDark,
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      title: Text(
                                        name,
                                        style: const TextStyle(
                                          color: ink,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      subtitle: Text(phone),
                                      trailing: PopupMenuButton<String>(
                                        onSelected: (action) {
                                          if (action == 'call') {
                                            callContact(phone);
                                          } else if (action == 'favorite') {
                                            toggleFavorite(c);
                                          } else if (action == 'edit') {
                                            openEditor(c);
                                          } else if (action == 'delete') {
                                            deleteContact(c);
                                          }
                                        },
                                        itemBuilder: (_) => [
                                          const PopupMenuItem(
                                            value: 'call',
                                            child: Text('Call'),
                                          ),
                                          const PopupMenuItem(
                                            value: 'favorite',
                                            child: Text('Toggle favourite'),
                                          ),
                                          const PopupMenuItem(
                                            value: 'edit',
                                            child: Text('Edit'),
                                          ),
                                          const PopupMenuItem(
                                            value: 'delete',
                                            child: Text('Delete'),
                                          ),
                                        ],
                                        child: Icon(
                                          c['isFavorite'] == 1
                                              ? Icons.favorite
                                              : Icons.more_vert,
                                          color: c['isFavorite'] == 1
                                              ? Colors.pinkAccent
                                              : mintDark,
                                        ),
                                      ),
                                      onTap: () {
                                        showModalBottomSheet<void>(
                                          context: context,
                                          showDragHandle: true,
                                          backgroundColor: cream,
                                          builder: (sheetContext) {
                                            return Padding(
                                              padding: const EdgeInsets.all(24),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  CircleAvatar(
                                                    radius: 38,
                                                    backgroundColor: mint,
                                                    child: Text(
                                                      initial,
                                                      style: const TextStyle(
                                                        fontSize: 30,
                                                        color: mintDark,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 12),
                                                  Text(
                                                    name,
                                                    style: const TextStyle(
                                                      fontSize: 24,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: ink,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Text(phone),
                                                  if ((c['email'] ?? '')
                                                      .toString()
                                                      .isNotEmpty)
                                                    Text(c['email'].toString()),
                                                  const SizedBox(height: 20),
                                                  Wrap(
                                                    spacing: 10,
                                                    children: [
                                                      FilledButton.icon(
                                                        onPressed: () =>
                                                            callContact(phone),
                                                        icon: const Icon(
                                                          Icons.call,
                                                        ),
                                                        label: const Text(
                                                          'Call',
                                                        ),
                                                      ),
                                                      OutlinedButton.icon(
                                                        onPressed: () {
                                                          Navigator.pop(
                                                            sheetContext,
                                                          );
                                                          openEditor(c);
                                                        },
                                                        icon: const Icon(
                                                          Icons.edit,
                                                        ),
                                                        label: const Text(
                                                          'Edit',
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 20),
                                                ],
                                              ),
                                            );
                                          },
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}

// ADD / EDIT CONTACT FORM

class ContactForm extends StatefulWidget {
  final Map<String, dynamic>? contact;

  const ContactForm({super.key, this.contact});

  @override
  State<ContactForm> createState() => _ContactFormState();
}

class _ContactFormState extends State<ContactForm> {
  final formKey = GlobalKey<FormState>();

  late final TextEditingController name;
  late final TextEditingController phone;
  late final TextEditingController email;

  bool favorite = false;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    final c = widget.contact;
    name = TextEditingController(text: c?['name'] ?? '');
    phone = TextEditingController(text: c?['phone'] ?? '');
    email = TextEditingController(text: c?['email'] ?? '');
    favorite = c?['isFavorite'] == 1;
  }

  @override
  void dispose() {
    name.dispose();
    phone.dispose();
    email.dispose();
    super.dispose();
  }

  Future<void> saveContact() async {
    if (!formKey.currentState!.validate()) return;

    setState(() => saving = true);

    try {
      await ContactStore.save(
        id: widget.contact?['id'] as int?,
        name: name.text,
        phone: phone.text,
        email: email.text,
        favorite: favorite,
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => saving = false);

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Could not save contact: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.contact != null;

    return Scaffold(
      appBar: AppBar(title: Text(editing ? 'Edit Contact' : 'Add Contact')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Form(
          key: formKey,
          child: Column(
            children: [
              CircleAvatar(
                radius: 48,
                backgroundColor: mint,
                child: Text(
                  name.text.isEmpty ? '?' : name.text[0].toUpperCase(),
                  style: const TextStyle(
                    fontSize: 35,
                    color: mintDark,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 26),
              _field(
                controller: name,
                label: 'Full Name',
                icon: Icons.person_outline,
                required: true,
              ),
              const SizedBox(height: 16),
              _field(
                controller: phone,
                label: 'Phone Number',
                icon: Icons.phone_outlined,
                required: true,
                phone: true,
              ),
              const SizedBox(height: 16),
              _field(
                controller: email,
                label: 'Email (Optional)',
                icon: Icons.email_outlined,
              ),
              const SizedBox(height: 10),
              SwitchListTile(
                value: favorite,
                onChanged: (v) => setState(() => favorite = v),
                activeThumbColor: mintDark,
                secondary: const Icon(Icons.favorite, color: Colors.pinkAccent),
                title: const Text('Add to Favourites'),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                tileColor: Colors.white,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: saving ? null : saveContact,
                  icon: const Icon(Icons.save_outlined),
                  label: Text(saving ? 'Saving...' : 'Save Contact'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: mintDark,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool required = false,
    bool phone = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: phone
          ? TextInputType.phone
          : label.startsWith('Email')
          ? TextInputType.emailAddress
          : TextInputType.text,
      validator: (value) {
        if (required && (value == null || value.trim().isEmpty)) {
          return 'Please enter $label';
        }

        if (label.startsWith('Email') &&
            value != null &&
            value.trim().isNotEmpty &&
            !value.contains('@')) {
          return 'Please enter a valid email';
        }

        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: mintDark),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
