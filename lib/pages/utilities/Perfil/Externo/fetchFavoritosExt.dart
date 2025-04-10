import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:xtats001/pantallas/Perfil/Perfilusuario.dart';
import 'package:xtats001/pantallas/Perfil/perfilusuext.dart';

class FetchFavoritosExternos extends StatefulWidget {
  final String userId;
  final String mediaUrl;
  final int initialIndex;

  const FetchFavoritosExternos({
    super.key,
    required this.userId,
    required this.mediaUrl,
    required this.initialIndex,
  });

  @override
  State createState() => _FetchFavoritosExternosState();
}

class _FetchFavoritosExternosState extends State<FetchFavoritosExternos>
    with TickerProviderStateMixin {
  late AnimationController _likeAnimationController;
  List<Map<String, dynamic>> publicaciones = [];
  late AnimationController _favoritoAnimationController;
  late ScrollController _scrollController;
  late CarouselSliderController _carouselController;

  int currentIndex = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();

    // Inicializar el likeAnimationController
    _likeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Inicializar el favoritoAnimationController
    _favoritoAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scrollController = ScrollController();
    _carouselController = CarouselSliderController();
    isLoading = true;
    _fetchPublicaciones(widget.userId);
  }

  @override
  void dispose() {
    _likeAnimationController.dispose();
    _favoritoAnimationController.dispose();
    _scrollController.dispose(); // Liberar recursos del controlador
    super.dispose();
  }

  void _scrollToPost(int index) {
    if (_scrollController.hasClients) {
      // Altura aproximada de cada elemento
      const double itemHeight = 600.0;

      // Calcular la posición de desplazamiento
      final double targetOffset = index * itemHeight;

      // Desplazarse suavemente
      _scrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
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

  Future<void> _fetchPublicaciones(String userId) async {
    try {
      // Obtener el documento del usuario
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        // Verificar si el campo 'favorites' existe y no está vacío
        Map<String, dynamic>? userData =
            userDoc.data() as Map<String, dynamic>?;
        List<dynamic> favoritePostIds =
            userData?['favorites'] ?? []; // Lista de IDs en 'favorites'

        if (favoritePostIds.isNotEmpty) {
          // Obtener los posts favoritos basados en los IDs
          await fetchFavoritePosts(favoritePostIds);
        } else {
          // Si no hay favoritos, limpiar el estado
          setState(() {
            publicaciones = []; // Sin datos
            isLoading = false; // Detener el indicador de carga
          });
        }

        // Una vez que se hayan cargado las publicaciones, desplázate al índice inicial
        if (widget.initialIndex < publicaciones.length) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToPost(widget.initialIndex);
          });
        }
      } else {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("El perfil no existe en la base de datos")));
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
      List<Map<String, dynamic>> favoritePosts = [];

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

        // Agregar los resultados al arreglo final con `postId`
        for (var doc in postsQuery.docs) {
          final postData = doc.data() as Map<String, dynamic>;
          final userId = postData['userId'];
          final userDetails = await _getUserDetails(userId);

          favoritePosts.add({
            'id': doc.id, // Agregar el postId
            ...postData, // Los datos del post
            ...userDetails, // Detalles del usuario
          });
        }
      }

      // Actualizar el estado con los datos obtenidos
      setState(() {
        publicaciones = favoritePosts;
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

  void _handleLike(String? postId, int index) async {
    if (postId == null || postId.isEmpty) {
      print("El postId es nulo o vacío");
      return;
    }

    try {
      final currentUserId = FirebaseAuth.instance.currentUser!.uid;
      final postRef =
          FirebaseFirestore.instance.collection('posts').doc(postId);
      final postSnapshot = await postRef.get();

      if (!postSnapshot.exists) {
        print("El post no existe");
        return;
      }

      final postData = postSnapshot.data() as Map<String, dynamic>;
      final likesData = postData['likes'];

      // Verifica que likes y likes['users'] existan y sean de tipo List
      if (likesData == null || !(likesData['users'] is List)) {
        print("Los datos de likes o users no están correctamente definidos");
        return;
      }

      final hasLiked = (likesData['users'] as List).contains(currentUserId);

      if (hasLiked) {
        await postRef.update({
          'likes.count': FieldValue.increment(-1),
          'likes.users': FieldValue.arrayRemove([currentUserId])
        });
        setState(() {
          publicaciones[index]['likes']['count']--;
          publicaciones[index]['likes']['users'].remove(currentUserId);
        });
      } else {
        await postRef.update({
          'likes.count': FieldValue.increment(1),
          'likes.users': FieldValue.arrayUnion([currentUserId])
        });
        setState(() {
          publicaciones[index]['likes']['count']++;
          publicaciones[index]['likes']['users'].add(currentUserId);
        });
      }

      _likeAnimationController.forward(from: 0);
      Future.delayed(const Duration(milliseconds: 350), () {
        _likeAnimationController.reverse();
      });
    } catch (e) {
      print('Error al dar like: $e');
    }
  }

  void _showCommentsBottomSheet(String postId) {
    showModalBottomSheet(
      context: context,
      builder: (context) => _CommentsBottomSheet(
        postId: postId,
        onCommentAdded: () {
          _fetchPublicaciones(widget
              .userId); // Refrescar publicaciones para mostrar nuevos comentarios
        },
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            'Favoritos de ${publicaciones.isNotEmpty ? publicaciones[0]['username'] : 'Usuario'}'),
      ),
      body: publicaciones.isEmpty
          ? const Center(child: Text('No hay publicaciones disponibles.'))
          : ListView.builder(
              controller: _scrollController,
              itemCount: publicaciones.length,
              itemBuilder: (context, index) {
                final post = publicaciones[index];
                final mediaUrls = (post['imageUrl'] as List?)?.cast<String>() ??
                    []; // Validar lista

                final currentUserId = FirebaseAuth.instance.currentUser!.uid;

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

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          GestureDetector(
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
                          const SizedBox(width: 10),
                          Expanded(
                            child: GestureDetector(
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
                              child: Text(
                                post['username'] ?? 'Usuario',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onDoubleTap: () {
                        _handleLike(post['id'], index);
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
                                  post['likes']['users'].contains(FirebaseAuth
                                          .instance.currentUser!.uid)
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: post['likes']['users'].contains(
                                          FirebaseAuth
                                              .instance.currentUser!.uid)
                                      ? Colors.red
                                      : null,
                                ),
                                onPressed: () => _handleLike(post['id'], index),
                              ),
                              Text('${post['likes']['count']}'),
                              const SizedBox(
                                  width: 3), // Espacio entre los iconos
                              IconButton(
                                icon: const Icon(Icons.comment),
                                onPressed: () =>
                                    _showCommentsBottomSheet(post['id']),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(left: 1.0),
                                child: Text(
                                  '${post['comments']['count'] ?? 0}',
                                ),
                              ),
                              const SizedBox(width: 3),
                              IconButton(
                                icon: const Icon(Icons.share),
                                onPressed: () => _sharePost(post['id']),
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
                              post['favorites']['users'].contains(currentUserId)
                                  ? Icons.bookmark
                                  : Icons.bookmark_border,
                              color: post['favorites']['users']
                                      .contains(currentUserId)
                                  ? const Color.fromARGB(255, 201, 126, 15)
                                  : null,
                            ),
                            onPressed: () => _favoritesPost(post['id'], index),
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
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: Text(
                        post['description'] ?? '', // descripcion
                        style: const TextStyle(fontSize: 14),
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
                    const Divider(),
                  ],
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
