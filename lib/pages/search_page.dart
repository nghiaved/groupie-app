import 'package:chatapp/helpers/helper_function.dart';
import 'package:chatapp/pages/chat_page.dart';
import 'package:chatapp/services/database_service.dart';
import 'package:chatapp/widgets/widgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  QuerySnapshot? searchSnapshot;
  bool hasUserSearched = false;
  String userName = '';
  bool isJoined = false;
  User? user;

  @override
  void initState() {
    super.initState();
    getCurrentUserIdAndName();
  }

  getCurrentUserIdAndName() async {
    await HelperFunction.getUserNameFromSF().then((value) {
      setState(() {
        userName = value!;
      });
    });
    user = FirebaseAuth.instance.currentUser;
  }

  String getId(String res) {
    return res.substring(0, res.indexOf('_'));
  }

  String getName(String res) {
    return res.substring(res.indexOf('_') + 1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
        title: const Text(
          'Search',
          style: TextStyle(
            fontSize: 27,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: Column(children: [
        Container(
          color: Theme.of(context).primaryColor,
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Search groups...',
                    hintStyle: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  initialSearchMethod();
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: const Icon(Icons.search, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
        _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  color: Theme.of(context).primaryColor,
                ),
              )
            : groupList(),
      ]),
    );
  }

  initialSearchMethod() async {
    if (_searchController.text.isNotEmpty) {
      setState(() {
        _isLoading = true;
      });
      await DatabaseService()
          .searchByName(_searchController.text)
          .then((snapshot) {
        setState(() {
          searchSnapshot = snapshot;
          _isLoading = false;
          hasUserSearched = true;
        });
      });
    }
  }

  groupList() {
    return hasUserSearched
        ? ListView.builder(
            shrinkWrap: true,
            itemCount: searchSnapshot!.docs.length,
            itemBuilder: (context, index) {
              return grouTile(
                userName,
                searchSnapshot!.docs[index]['groupId'],
                searchSnapshot!.docs[index]['groupName'],
                searchSnapshot!.docs[index]['admin'],
              );
            },
          )
        : Container();
  }

  joinedOrNot(
      String userName, String groupId, String groupName, String admin) async {
    await DatabaseService(uid: user!.uid)
        .isUserJoined(groupName, groupId, userName)
        .then((value) {
      setState(() {
        isJoined = value;
      });
    });
  }

  Widget grouTile(
      String userName, String groupId, String groupName, String admin) {
    joinedOrNot(userName, groupId, groupName, admin);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      leading: CircleAvatar(
        radius: 30,
        backgroundColor: Theme.of(context).primaryColor,
        child: Text(
          groupName.substring(0, 1).toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
          ),
        ),
      ),
      title: Text(
        groupName,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text('Admin: ${getName(admin)}'),
      trailing: InkWell(
        onTap: () async {
          await DatabaseService(uid: user!.uid)
              .toggleGroupJoin(groupId, userName, groupName);
          if (isJoined) {
            setState(() {
              isJoined = !isJoined;
            });
            // ignore: use_build_context_synchronously
            showSnackBar(context, Colors.green, 'Successfully joined he group');
            Future.delayed(const Duration(seconds: 2), () {
              nextScreen(
                context,
                ChatPage(
                  groupId: groupId,
                  groupName: groupName,
                  userName: userName,
                ),
              );
            });
          } else {
            setState(() {
              isJoined = !isJoined;
            });
            // ignore: use_build_context_synchronously
            showSnackBar(context, Colors.red, 'Left the group $groupName');
          }
        },
        child: isJoined
            ? Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.black,
                  border: Border.all(color: Colors.white, width: 1),
                ),
                child: const Text(
                  'Joined',
                  style: TextStyle(color: Colors.white),
                ),
              )
            : Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Theme.of(context).primaryColor,
                  border: Border.all(color: Colors.white, width: 1),
                ),
                child: const Text(
                  'Join Now',
                  style: TextStyle(color: Colors.white),
                ),
              ),
      ),
    );
  }
}
