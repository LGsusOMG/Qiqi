import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:xtats001/pages/utilities/Perfil/fetchFavoritos.dart';
import 'package:xtats001/pages/utilities/Perfil/fetchShared.dart';
import 'package:xtats001/pages/utilities/Perfil/perfilscreen.dart';
import 'package:xtats001/pages/utilities/Perfil/publicaciones.dart';

class PerfilUsu extends StatefulWidget {
  final String userId;

  const PerfilUsu({super.key, required this.userId});

  @override
  PerfilUsuState createState() => PerfilUsuState();
}

class PerfilUsuState extends State<PerfilUsu>
    with SingleTickerProviderStateMixin {
  String? userId;
  Map<String, dynamic>? userData;
  Map<String, dynamic>? userFavorites;
  Map<String, dynamic>? userShared;

  bool isLoading = true;
  bool isFollowing = false;

  List<Map<String, dynamic>> userPosts = [];

  late TabController _tabController;

  List<dynamic> mediaUrls = []; // para almacenar URLs de las publicaciones
  List<dynamic> favoritesUrls = []; // para almacenar URLs de los favoritios
  List<dynamic> sharedUrls = []; // para almacenar URLs de los compartidos

  @override
  void initState() {
    super.initState();
    getUserData();
    getUserFavorites();
    getUserShared();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> getUserFavorites() async {
    try {
      // Obtener el usuario autenticado
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        String userId = user.uid;

        // Obtener el documento del usuario
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();

        if (userDoc.exists) {
          // Verificar si el campo 'favorites' existe y no está vacío
          Map<String, dynamic>? userFavorites =
              userDoc.data() as Map<String, dynamic>?;
          List<dynamic> favoritePostIds =
              userFavorites?['favorites'] ?? []; // Lista de IDs en 'favorites'

          if (favoritePostIds.isNotEmpty) {
            // Obtener los posts favoritos basados en los IDs
            await fetchFavoritePosts(favoritePostIds);
          } else {
            // Si no hay favoritos, limpiar el estado
            setState(() {
              favoritesUrls = []; // Sin datos
              isLoading = false; // Detener el indicador de carga
            });
          }
        } else {
          setState(() {
            isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text("El perfil no existe en la base de datos")));
        }
      } else {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("No hay un usuario autenticado")));
      }
    } catch (e) {
      print('Error obteniendo datos del perfil: $e');
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Error obteniendo los datos del perfil")));
    }
  }

  Future<void> fetchFavoritePosts(List<dynamic> favoritePostIds) async {
    try {
      List<dynamic> favoritePosts = [];

      // Dividir los IDs en bloques de 10 si exceden el límite de Firebase
      for (int i = 0; i < favoritePostIds.length; i += 10) {
        List<dynamic> chunk = favoritePostIds.sublist(
          i,
          i + 10 > favoritePostIds.length ? favoritePostIds.length : i + 10,
        );

        // Realizar la consulta por cada bloque de IDs
        QuerySnapshot postsQuery = await FirebaseFirestore.instance
            .collection('posts')
            .where(FieldPath.documentId, whereIn: chunk)
            .get();

        // Agregar los resultados al arreglo final
        favoritePosts.addAll(postsQuery.docs.map((doc) => doc.data()).toList());
      }

      setState(() {
        favoritesUrls =
            favoritePosts; // Actualiza el estado con los datos obtenidos
        isLoading = false; // Finaliza la carga
      });
    } catch (e) {
      print('Error obteniendo posts favoritos: $e');
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Error obteniendo los posts favoritos")));
    }
  }

  Future<void> getUserShared() async {
    try {
      // Obtener el usuario autenticado
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        String userId = user.uid;

        // Obtener el documento del usuario
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();

        if (userDoc.exists) {
          // Verificar si el campo 'sharedPosts' existe y no está vacío
          Map<String, dynamic>? userShared =
              userDoc.data() as Map<String, dynamic>?;
          List<dynamic> sharedPostIds =
              userShared?['sharedPosts'] ?? []; // Lista de IDs en 'sharedPosts'

          if (sharedPostIds.isNotEmpty) {
            // Obtener los posts compartidos basados en los IDs
            await fetchSharedPosts(sharedPostIds);
          } else {
            // Si no hay compartidos, limpiar el estado
            setState(() {
              sharedUrls = []; // Sin datos
              isLoading = false; // Detener el indicador de carga
            });
          }
        } else {
          setState(() {
            isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text("El perfil no existe en la base de datos")));
        }
      } else {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("No hay un usuario autenticado")));
      }
    } catch (e) {
      print('Error obteniendo datos del perfil: $e');
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Error obteniendo los datos del perfil")));
    }
  }

  Future<void> fetchSharedPosts(List<dynamic> sharedPostIds) async {
    try {
      List<dynamic> sharedPosts = [];

      // Dividir los IDs en bloques de 10 si exceden el límite de Firebase
      for (int i = 0; i < sharedPostIds.length; i += 10) {
        List<dynamic> chunk = sharedPostIds.sublist(
          i,
          i + 10 > sharedPostIds.length ? sharedPostIds.length : i + 10,
        );

        // Realizar la consulta por cada bloque de IDs
        QuerySnapshot postsQuery = await FirebaseFirestore.instance
            .collection('posts')
            .where(FieldPath.documentId, whereIn: chunk)
            .get();

        // Agregar los resultados al arreglo final
        sharedPosts.addAll(postsQuery.docs.map((doc) => doc.data()).toList());
      }

      setState(() {
        sharedUrls = sharedPosts; // Actualiza el estado con los datos obtenidos
        isLoading = false; // Finaliza la carga
      });
    } catch (e) {
      print('Error obteniendo posts favoritos: $e');
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Error obteniendo los posts favoritos")));
    }
  }

  Future<void> getUserData() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        userId = user.uid;

        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();

        if (userDoc.exists) {
          setState(() {
            userData = userDoc.data() as Map<String, dynamic>? ?? {};
          });
          await getUserPosts(
              userData!['publicaciones']); // Obtener publicaciones
        } else {
          setState(() {
            isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text("El perfil no existe en la base de datos")));
        }
      } else {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("No hay un usuario autenticado")));
      }
    } catch (e) {
      print('Error obteniendo datos del perfil: $e');
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Error obteniendo los datos del perfil")));
    }
  }

  Future<void> getUserPosts(List<dynamic> postIds) async {
    if (postIds.isNotEmpty) {
      List<dynamic> posts = [];

      for (var postId in postIds) {
        DocumentSnapshot postDoc = await FirebaseFirestore.instance
            .collection('posts')
            .doc(postId)
            .get();

        if (postDoc.exists) {
          posts.add(postDoc.data());
        }
      }
      //estado de carga
      setState(() {
        mediaUrls = posts;
        isLoading = false;
      });
    } else {
      setState(() {
        mediaUrls = [];
        isLoading = false;
      });
    }
  }

  Future<void> _handleRefresh() async {
    await getUserData();
  }

  void _setSystemUIOverlayStyle({required bool darkMode}) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      systemNavigationBarColor: darkMode ? Colors.black : Colors.white,
      systemNavigationBarIconBrightness:
          darkMode ? Brightness.light : Brightness.dark,
    ));
  }

  Future<void> loadUserPosts(List<dynamic> postIds) async {
    List<Map<String, dynamic>> loadedPosts = [];

    for (String postId in postIds) {
      DocumentSnapshot postDoc = await FirebaseFirestore.instance
          .collection('posts')
          .doc(postId)
          .get();

      if (postDoc.exists) {
        loadedPosts.add(postDoc.data() as Map<String, dynamic>);
      }
    }

    setState(() {
      userPosts = loadedPosts;
    });
  }

  Future<void> checkIfFollowing() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      DocumentSnapshot currentUserDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (currentUserDoc.exists) {
        List<dynamic> followingList = currentUserDoc['following'] ?? [];
        setState(() {
          isFollowing = followingList.contains(widget.userId);
        });
      }
    }
  }

  Future<void> toggleFollow() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      DocumentReference userRef =
          FirebaseFirestore.instance.collection('users').doc(currentUser.uid);
      DocumentReference followedUserRef =
          FirebaseFirestore.instance.collection('users').doc(widget.userId);

      if (isFollowing) {
        await userRef.update({
          'following': FieldValue.arrayRemove([widget.userId])
        });
        await followedUserRef.update({
          'followers': FieldValue.arrayRemove([currentUser.uid])
        });
      } else {
        await userRef.update({
          'following': FieldValue.arrayUnion([widget.userId])
        });
        await followedUserRef.update({
          'followers': FieldValue.arrayUnion([currentUser.uid])
        });
      }

      setState(() {
        isFollowing = !isFollowing;
      });
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      isLoading = true;
    });
    await getUserData();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = AdaptiveTheme.of(context).mode == AdaptiveThemeMode.dark;
    _setSystemUIOverlayStyle(darkMode: isDarkMode);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: Text(
            userData != null ? userData!['username'] ?? 'Perfil' : 'Perfil'),
        backgroundColor: Colors.deepPurple,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : userData != null
              ? RefreshIndicator(
                  onRefresh: _handleRefresh,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundImage: userData!['profilePicture'] != ''
                                  ? NetworkImage(userData!['profilePicture'])
                                  : const AssetImage('images/logo.png')
                                      as ImageProvider,
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
                                    children: [
                                      _buildStatColumn(
                                        count: mediaUrls.length,
                                        label: 'Publicaciones',
                                      ),
                                      _buildStatColumn(
                                        count:
                                            userData!['followers']?.length ?? 0,
                                        label: 'Seguidores',
                                      ),
                                      _buildStatColumn(
                                        count:
                                            userData!['following']?.length ?? 0,
                                        label: 'Seguidos',
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (userData!['nickname'] != null &&
                            userData!['nickname'].isNotEmpty) ...[
                          Text(
                            userData!['nickname'],
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                        if (userData!['description'] != null &&
                            userData!['description'].isNotEmpty) ...[
                          Text(
                            userData!['description'],
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PerfilScreen(
                                  userId: userId!,
                                  userData: userData!,
                                ),
                              ),
                            );
                          },
                          child: const Text('Editar perfil'),
                        ),
                        const SizedBox(height: 20),
                        const Divider(),
                        TabBar(
                          controller: _tabController,
                          tabs: const [
                            Tab(text: 'Publicaciones'),
                            Tab(text: 'Favoritos'),
                            Tab(text: 'Compartidos'),
                          ],
                        ),
                        Expanded(
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              _buildPublicacionesView(),
                              _buildFavoritesView(),
                              _buildShareView()
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : const Center(
                  child: Text('No se encontraron datos del usuario')),
    );
  }

  Column _buildStatColumn({required int count, required String label}) {
    return Column(
      children: [
        Text(
          '$count',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Text(label),
      ],
    );
  }

  Widget _buildPublicacionesView() {
    return mediaUrls.isNotEmpty
        ? GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 1,
            ),
            itemCount: mediaUrls.length,
            itemBuilder: (context, index) {
              var imageUrl = mediaUrls[index]['imageUrl'];

              String mediaUrl = '';

              // Si hay una lista de imágenes, tomar el primer elemento
              if (imageUrl is List && imageUrl.isNotEmpty) {
                mediaUrl = imageUrl.first;
              } else if (imageUrl is String) {
                mediaUrl = imageUrl;
              }

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PublicacionesScreen(
                        userId: userData!['uid'] ?? '',
                        username: userData!['username'] ?? 'Usuario',
                        profilePicture: userData!['profilePicture'] ?? '',
                        userData: userData!,
                        mediaUrl: mediaUrl,
                        initialIndex: index,
                      ),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(2.0),
                  child: Image.network(
                    mediaUrl.isNotEmpty ? mediaUrl : 'images/logo.png',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Image.asset('images/logo.png', fit: BoxFit.cover);
                    },
                  ),
                ),
              );
            },
          )
        : const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.public, size: 48, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'No hay Publicaciones.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          );
  }

  Widget _buildFavoritesView() {
    return favoritesUrls.isNotEmpty
        ? GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, // Tres columnas
              childAspectRatio: 1, // Relación de aspecto cuadrada
            ),
            itemCount: favoritesUrls.length,
            itemBuilder: (context, index) {
              var favoritePost = favoritesUrls[index];
              var imageUrl = favoritePost?['imageUrl'];

              String mediaUrl = '';

              // Validar y asignar URL de la imagen
              if (imageUrl is List && imageUrl.isNotEmpty) {
                mediaUrl =
                    imageUrl.first; // Tomar la primera imagen de la lista
              } else if (imageUrl is String) {
                mediaUrl =
                    imageUrl; // Usar la URL directamente si es una cadena
              }

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FetchFavoritos(
                        mediaUrl: mediaUrl,
                        initialIndex: index, // Usar directamente el índice
                      ),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(2.0),
                  child: Image.network(
                    mediaUrl.isNotEmpty ? mediaUrl : 'images/logo.png',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Image.asset('images/logo.png', fit: BoxFit.cover);
                    },
                  ),
                ),
              );
            },
          )
        : const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.favorite_border, size: 48, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'No hay Favoritos.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          );
  }

  Widget _buildShareView() {
    return sharedUrls.isNotEmpty
        ? GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 1,
            ),
            itemCount: sharedUrls.length,
            itemBuilder: (context, index) {
              var sharedPost = sharedUrls[index];
              var imageUrl = sharedPost?['imageUrl'];

              String mediaUrl = '';

              if (imageUrl is List && imageUrl.isNotEmpty) {
                mediaUrl = imageUrl.first;
              } else if (imageUrl is String) {
                mediaUrl = imageUrl;
              }

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FetchShared(
                        mediaUrl: mediaUrl,
                        initialIndex: index,
                      ),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(2.0),
                  child: Image.network(
                    mediaUrl.isNotEmpty ? mediaUrl : 'images/logo.png',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Image.asset('images/logo.png', fit: BoxFit.cover);
                    },
                  ),
                ),
              );
            },
          )
        : const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.share, size: 48, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'No hay Compartidos.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          );
  }
}
