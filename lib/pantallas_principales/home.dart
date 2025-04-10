import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:intl/intl.dart';
import 'package:xtats001/pantallas/Perfil/Perfilusuario.dart';
import 'package:xtats001/pantallas/Perfil/perfilusuext.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  HomeState createState() => HomeState();
}

class HomeState extends State<Home> with TickerProviderStateMixin {
  List<Map<String, dynamic>> publicaciones = [];
  bool showPopularPosts = false; // Alternar entre recientes y populares

  final ScrollController _scrollController = ScrollController();
  DocumentSnapshot? lastDocument;
  bool isLoading = false;

  late AnimationController _likeAnimationController;
  late AnimationController _favoritoAnimationController;
  late CarouselSliderController _carouselController;

  int currentIndex = 0; // Declarar currentIndex a nivel de clase

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        _fetchPosts(sortByLikes: showPopularPosts, isLoadMore: true);
      }
    });

    _likeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _favoritoAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _carouselController = CarouselSliderController();
    _fetchPosts(); // Primera carga de publicaciones
  }

  @override
  void dispose() {
    _likeAnimationController.dispose();
    _favoritoAnimationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Obtener detalles de un usuario
  Future<Map<String, dynamic>> _getUserDetails(String userId) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data()!;
        return {
          'username': userData['username'] ?? 'Usuario',
          'profilePicture': userData['profilePicture'] ?? '',
        };
      }
    } catch (e) {
      print("Error al obtener detalles del usuario: $e");
    }

    return {
      'username': 'Usuario ',
      'profilePicture': '',
    };
  }

  // Obtener publicaciones de Firestore
  Future<void> _fetchPosts(
      {bool sortByLikes = false, bool isLoadMore = false}) async {
    if (isLoading) return; // Evitar múltiples cargas simultáneas
    if (!mounted) return;
    setState(() {
      isLoading = true;
    });

    try {
      final currentUserId = FirebaseAuth.instance.currentUser!.uid;
      final followersSnapshot = await FirebaseFirestore.instance
          .collection('followers')
          .doc(currentUserId)
          .get();

      final followingList = followersSnapshot.exists
          ? List<String>.from(followersSnapshot['followers'] ?? [])
          : [];

      Query query = FirebaseFirestore.instance.collection('posts');

      if (followingList.isNotEmpty) {
        query = query.where('userId', whereIn: followingList);
      }

      if (sortByLikes) {
        query = query.orderBy('likes.count', descending: true);
      } else {
        query = query.orderBy('timestamp', descending: true);
      }

      if (lastDocument != null && isLoadMore) {
        query = query.startAfterDocument(lastDocument!);
      }

      query = query.limit(10); // Límite de publicaciones

      final postSnapshot = await query.get();
      if (postSnapshot.docs.isNotEmpty) {
        lastDocument = postSnapshot.docs.last;

        final nuevasPublicaciones =
            await Future.wait(postSnapshot.docs.map((doc) async {
          final postData = doc.data();
          final userId = (postData as Map<String, dynamic>)['userId'];
          final userDetails = await _getUserDetails(userId);

          return {
            'id': doc.id,
            ...postData,
            ...userDetails, // Combinar detalles de la publicación y usuario
          };
        }).toList());

        if (mounted) {
          setState(() {
            publicaciones = isLoadMore
                ? [...publicaciones, ...nuevasPublicaciones]
                : nuevasPublicaciones;
          });
        }
      }
    } catch (e) {
      print("Error al cargar publicaciones: $e");
    }
    if (!mounted) return;
    setState(() {
      isLoading = false;
    });
  }

  // Alternar entre publicaciones recientes y populares
  void _toggleSort() {
    setState(() {
      showPopularPosts = !showPopularPosts;
      _fetchPosts(sortByLikes: showPopularPosts);
    });
  }

  // Función para darle "me gusta" a una publicación
  void _likePost(String postId, int index) async {
    try {
      // Obtener la referencia al documento de la publicación en Firestore
      final postRef =
          FirebaseFirestore.instance.collection('posts').doc(postId);

      // Obtener los datos de la publicación
      final postSnapshot = await postRef.get();
      final postData = postSnapshot.data() as Map<String, dynamic>;

      // Obtener el ID del usuario actual
      final currentUserId = FirebaseAuth.instance.currentUser!.uid;

      // Verificar si el usuario ya ha dado "me gusta" a la publicación
      final hasLiked =
          (postData['likes']['users'] as List).contains(currentUserId);

      // Si el usuario ya dio "me gusta", quitar el "me gusta"
      if (hasLiked) {
        await postRef.update({
          'likes.count':
              FieldValue.increment(-1), // Reducir el contador de "me gusta"
          'likes.users': FieldValue.arrayRemove(
              [currentUserId]) // Quitar al usuario de la lista
        });

        // Actualizar el estado local
        setState(() {
          publicaciones[index]['likes']['count']--; // Reducir el contador local
          publicaciones[index]['likes']['users']
              .remove(currentUserId); // Eliminar al usuario de la lista local
        });
      } else {
        // Si el usuario no ha dado "me gusta", agregarlo
        await postRef.update({
          'likes.count':
              FieldValue.increment(1), // Aumentar el contador de "me gusta"
          'likes.users': FieldValue.arrayUnion(
              [currentUserId]) // Agregar al usuario a la lista
        });

        // Actualizar el estado local
        setState(() {
          publicaciones[index]['likes']
              ['count']++; // Aumentar el contador local
          publicaciones[index]['likes']['users']
              .add(currentUserId); // Agregar al usuario a la lista local
        });
      }

      // Animación de "me gusta" (para feedback visual)
      _likeAnimationController.forward(from: 0);
      Future.delayed(const Duration(milliseconds: 350), () {
        _likeAnimationController
            .reverse(); // Revertir la animación después de un corto retraso
      });
    } catch (e) {
      // En caso de error, imprimir un mensaje en la consola
      print('Error al dar like: $e');
    }
  }

  void _addComentario(String postId) {
    showModalBottomSheet(
      context: context,
      builder: (context) => _CommentsBottomSheet(
        postId: postId,
        onCommentAdded: () {
          _fetchPosts(); // Refrescar publicaciones para mostrar nuevos comentarios
        },
      ),
    );
  }

  // Función para compartir una publicación
  Future<void> _sharePost(String postId) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        print('Error: Usuario no autenticado.');
        return;
      }

      final postRef =
          FirebaseFirestore.instance.collection('posts').doc(postId);
      final postSnapshot = await postRef.get();

      if (!postSnapshot.exists) {
        print('La publicación no existe.');
        return;
      }

      // Obtén los datos actuales de la publicación
      final postData = postSnapshot.data() as Map<String, dynamic>;
      final shares = postData['shares'] as Map<String, dynamic>? ?? {};
      final currentUsers = (shares['users'] as List<dynamic>? ?? []);

      // Verifica si el usuario ya compartió la publicación
      if (currentUsers.contains(userId)) {
        print('Ya has compartido esta publicación.');
        return;
      }

      // Actualiza la lista de usuarios y el contador
      await postRef.update({
        'shares.users': FieldValue.arrayUnion([userId]),
        'shares.count': FieldValue.increment(1),
      });

      // Agrega la publicación compartida al perfil del usuario
      final userRef =
          FirebaseFirestore.instance.collection('users').doc(userId);
      await userRef.update({
        'sharedPosts': FieldValue.arrayUnion(
            [postId]), // Agrega el ID de la publicación a los compartidos
      });

      print('Publicación compartida exitosamente.');
    } catch (e) {
      print('Error al compartir la publicación: $e');
    }
  }

  // Función para darle "Favorito" a una publicación
  void _favoritesPost(String postId, int index) async {
    try {
      // Obtener la referencia al documento de la publicación
      final postRef =
          FirebaseFirestore.instance.collection('posts').doc(postId);
      final postSnapshot = await postRef.get();
      final postData = postSnapshot.data() as Map<String, dynamic>;

      // Obtener el ID del usuario actual
      final currentUserId = FirebaseAuth.instance.currentUser!.uid;

      // Asegurarse de que el campo 'favorites' esté inicializado en la publicación
      final favorites = postData['favorites'] ?? {'count': 0, 'users': []};

      // Verificar si el usuario ya marcó la publicación como favorita
      final hasFavorited = (favorites['users'] as List).contains(currentUserId);

      if (hasFavorited) {
        // Si ya está en favoritos, eliminarlo
        await postRef.update({
          'favorites.count': FieldValue.increment(-1),
          'favorites.users': FieldValue.arrayRemove([currentUserId]),
        });

        // Actualizar el estado local
        setState(() {
          publicaciones[index]['favorites']['count']--;
          publicaciones[index]['favorites']['users'].remove(currentUserId);
        });

        // Eliminar de los favoritos del usuario
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUserId)
            .update({
          'favorites': FieldValue.arrayRemove([postId]),
        });
      } else {
        // Si no está en favoritos, agregarlo
        await postRef.update({
          'favorites.count': FieldValue.increment(1),
          'favorites.users': FieldValue.arrayUnion([currentUserId]),
        });

        // Actualizar el estado local
        setState(() {
          publicaciones[index]['favorites']['count']++;
          publicaciones[index]['favorites']['users'].add(currentUserId);
        });

        // Agregar a los favoritos del usuario
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUserId)
            .update({
          'favorites': FieldValue.arrayUnion([postId]),
        });
      }

      // Animación de feedback visual
      _favoritoAnimationController.forward(from: 0);
      Future.delayed(const Duration(milliseconds: 350), () {
        _favoritoAnimationController.reverse();
      });
    } catch (e) {
      print('Error al guardar en favoritos: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inicio'),
        actions: [
          IconButton(
            icon:
                Icon(showPopularPosts ? Icons.access_time : Icons.trending_up),
            onPressed: _toggleSort,
            tooltip:
                showPopularPosts ? 'Ver más recientes' : 'Ver más populares',
          ),
        ],
      ),
      body: publicaciones.isEmpty && !isLoading
          ? const Center(child: Text('No hay publicaciones disponibles.'))
          : ListView.builder(
              controller: _scrollController,
              itemCount: publicaciones.length,
              itemBuilder: (context, index) {
                final post = publicaciones[index];
                final mediaUrls = (post['imageUrl'] as List?)?.cast<String>() ??
                    []; // Validar lista

                // Convertir el timestamp a tiempo transcurrido
                final postTimestamp = post['timestamp']?.toDate();
                final currentTime = DateTime.now();
                final timeDifference = postTimestamp != null
                    ? currentTime.difference(postTimestamp)
                    : Duration.zero;

                String timeAgo;
                if (timeDifference.inHours < 24) {
                  timeAgo = postTimestamp != null
                      ? timeago.format(postTimestamp)
                      : 'Hace un momento';
                } else {
                  timeAgo = postTimestamp != null
                      ? DateFormat('d MMM y').format(postTimestamp)
                      : 'Fecha desconocida';
                }

                final currentUserId = FirebaseAuth.instance.currentUser!.uid;

                return Card(
                  margin: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        leading: GestureDetector(
                          onTap: () {
                            // Verifica si el userId del post es igual al currentUserId
                            if (post['userId'] == currentUserId) {
                              // Si es el usuario actual, navegar al perfil propio
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      PerfilUsu(userId: post['userId']),
                                  // Tu pantalla de perfil
                                ),
                              );
                            } else {
                              // Si no es el usuario actual, navegar al perfil del usuario externo
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PerfilUsuarioScreen(
                                      userId: post['userId']),
                                ),
                              );
                            }
                          },
                          child: CircleAvatar(
                            backgroundImage: post['profilePicture'].isNotEmpty
                                ? NetworkImage(post['profilePicture'])
                                : const AssetImage('images/logo.png')
                                    as ImageProvider,
                          ),
                        ),
                        title: GestureDetector(
                          onTap: () {
                            // Verifica si el userId del post es igual al currentUserId
                            if (post['userId'] == currentUserId) {
                              // Si es el usuario actual, navegar al perfil propio
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  // Tu pantalla de perfil
                                  builder: (context) => PerfilUsu(
                                    userId: post['userId'],
                                  ),
                                ),
                              );
                            } else {
                              // Si no es el usuario actual, navegar al perfil del usuario externo
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PerfilUsuarioScreen(
                                      userId: post['userId']),
                                ),
                              );
                            }
                          },
                          child: Text(post['username']),
                        ),
                      ),
                      GestureDetector(
                        onDoubleTap: () {
                          _likePost(post['id'], index);
                        },
                        child: _buildImageCarousel(mediaUrls),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 3.0, vertical: 0),
                        child: Row(
                          children: [
                            Row(
                              children: [
                                IconButton(
                                  icon: Icon(
                                    post['likes']['users']
                                            .contains(currentUserId)
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    color: post['likes']['users']
                                            .contains(currentUserId)
                                        ? Colors.red
                                        : null,
                                  ),
                                  onPressed: () => _likePost(post['id'], index),
                                ),
                                Text('${post['likes']['count']}'),
                                const SizedBox(width: 3),
                                IconButton(
                                  icon: const Icon(Icons.comment),
                                  onPressed: () => _addComentario(post['id']),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(left: 1.0),
                                  child: Text(
                                    '${post['comments']['count'] ?? 0}',
                                  ),
                                ),
                                const SizedBox(width: 2),
                                IconButton(
                                  icon: const Icon(Icons.share),
                                  onPressed: () {
                                    _sharePost(post['id']);
                                  },
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(left: 1.0),
                                  child: Text(
                                    '${post['shares']['count'] ?? 0}',
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            IconButton(
                              icon: Icon(
                                post['favorites']['users']
                                        .contains(currentUserId)
                                    ? Icons.bookmark
                                    : Icons.bookmark_border,
                                color: post['favorites']['users']
                                        .contains(currentUserId)
                                    ? const Color.fromARGB(255, 201, 126, 15)
                                    : null,
                              ),
                              onPressed: () =>
                                  _favoritesPost(post['id'], index),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 1.0),
                              child: Text(
                                '${post['favorites']['count'] ?? 0}',
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (post['description'] != null &&
                          post['description'].isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(
                            post['description'],
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      if (post['hashtags'] != null &&
                          post['hashtags'].isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(
                            (post['hashtags'] as List<dynamic>).join(' '),
                            style: const TextStyle(
                                fontSize: 16, color: Colors.blue),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          timeAgo,
                          style:
                              const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildImageCarousel(List<String> mediaUrls) {
    return Column(
      children: [
        CarouselSlider.builder(
          carouselController: _carouselController,
          itemCount: mediaUrls.length,
          itemBuilder: (context, index, realIndex) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  mediaUrls[index],
                  fit: BoxFit.scaleDown, // Ajustar la imagen al contenedor
                ),
              ),
            );
          },
          options: CarouselOptions(
            height: MediaQuery.of(context).size.height * 0.5,
            viewportFraction: 1.0,
            enableInfiniteScroll: false,
            enlargeCenterPage: false,
            onPageChanged: (index, reason) {
              setState(() {
                currentIndex = index; // Actualizar currentIndex global
              });
            },
          ),
        ),
        const SizedBox(height: 8),
        if (mediaUrls.length > 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: mediaUrls.asMap().entries.map((entry) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                width: currentIndex == entry.key ? 12.0 : 8.0,
                height: 8.0,
                margin:
                    const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: currentIndex == entry.key
                      ? Colors.blue
                      : Colors.grey.shade400,
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}

class _CommentsBottomSheet extends StatefulWidget {
  final String postId;
  final VoidCallback onCommentAdded;

  const _CommentsBottomSheet({
    required this.postId,
    required this.onCommentAdded,
  });

  @override
  __CommentsBottomSheetState createState() => __CommentsBottomSheetState();
}

class __CommentsBottomSheetState extends State<_CommentsBottomSheet> {
  final TextEditingController _commentController = TextEditingController();
  List<Map<String, dynamic>> comments = [];

  @override
  void initState() {
    super.initState();
    _fetchComments();
  }

  Future<void> _fetchComments() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId)
        .collection('comments')
        .orderBy('timestamp', descending: true) // mss reciente a mas antiguo
        .get();

    setState(() {
      comments = snapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data(),
              })
          .toList();
    });
  }

  void _addComment() async {
    final commentText = _commentController.text.trim();
    if (commentText.isNotEmpty) {
      try {
        final currentUser = FirebaseAuth.instance.currentUser;

        if (currentUser != null) {
          final userData = await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .get();

          final profilePicture = userData['profilePicture'] ?? '';
          final username = userData['username'] ?? 'Usuario';

          await FirebaseFirestore.instance
              .collection('posts')
              .doc(widget.postId)
              .collection('comments')
              .add({
            'description': commentText,
            'timestamp': FieldValue.serverTimestamp(),
            'userId': currentUser.uid,
            'profilePicture': profilePicture,
            'username': username,
          });

          //ncrementar el contador de comentarios
          FirebaseFirestore.instance
              .collection('posts')
              .doc(widget.postId)
              .update({
            'comments.count': FieldValue.increment(1),
          });

          _commentController.clear();
          widget.onCommentAdded();
          _fetchComments(); //actualiza la lista de comentarios
        }
      } catch (e) {
        print('Error al agregar comentario: $e');
      }
    }
  }

  void _deleteComment(String commentId) async {
    try {
      await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .collection('comments')
          .doc(commentId)
          .delete();

      // decrementar el contador de comentarios en Firestore
      FirebaseFirestore.instance.collection('posts').doc(widget.postId).update({
        'comments.count': FieldValue.increment(-1),
      });
      _commentController.clear();
      widget.onCommentAdded();
      _fetchComments();
    } catch (e) {
      print('Error al eliminar comentario: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: comments.length,
              itemBuilder: (context, index) {
                final comment = comments[index];
                return GestureDetector(
                  onLongPress: () {
                    //alerta para confirmar la eliminación
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Eliminar comentario'),
                        content: const Text(
                            '¿Estás seguro de que deseas eliminar este comentario?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Cancelar'),
                          ),
                          TextButton(
                            onPressed: () {
                              _deleteComment(comment['id']);
                              Navigator.of(context).pop();
                            },
                            child: const Text('Eliminar'),
                          ),
                        ],
                      ),
                    );
                  },
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundImage: NetworkImage(comment['profilePicture']),
                    ),
                    title: Text(comment['username']),
                    subtitle: Text(comment['description']),
                    trailing: Text(
                      _getTimeAgo(comment['timestamp']),
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: const InputDecoration(
                      hintText: 'Escribe un comentario...',
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _addComment,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getTimeAgo(dynamic timestamp) {
    if (timestamp is Timestamp) {
      final now = DateTime.now();
      final difference = now.difference(timestamp.toDate());

      if (difference.inDays > 0) {
        return '${difference.inDays}d';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m';
      } else {
        return 'justo ahora';
      }
    } else {
      // Maneja casos donde el timestamp no es válido
      return 'Fecha inválida';
    }
  }
}
