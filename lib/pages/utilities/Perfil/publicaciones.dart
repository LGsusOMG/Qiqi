import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:timeago/timeago.dart' as timeago;

class PublicacionesScreen extends StatefulWidget {
  final String userId;
  final String username;
  final String profilePicture;
  final int initialIndex;

  const PublicacionesScreen({
    super.key,
    required this.userId,
    required this.username,
    required this.profilePicture,
    required Map<String, dynamic> userData,
    required mediaUrl,
    required this.initialIndex,
  });

  @override
  State createState() => _PublicacionesScreenState();
}

class _PublicacionesScreenState extends State<PublicacionesScreen>
    with TickerProviderStateMixin {
  late AnimationController _likeAnimationController;
  List<Map<String, dynamic>> publicaciones = [];

  late AnimationController _favoritoAnimationController;
  late ScrollController _scrollController;
  late CarouselSliderController _carouselController;

  int currentIndex = 0; // Declarar currentIndex a nivel de clase

  @override
  void initState() {
    super.initState();
    _likeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _favoritoAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scrollController = ScrollController();
    _carouselController = CarouselSliderController();
    _fetchPublicaciones();
  }

  @override
  void dispose() {
    _favoritoAnimationController.dispose();
    _likeAnimationController.dispose();
    _scrollController.dispose(); 
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

  Future<void> _fetchPublicaciones() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('posts')
        .where('userId', isEqualTo: widget.userId)
        .get();

    setState(() {
      publicaciones = snapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data(),
              })
          .toList();
    });

    // Una vez que se hayan cargado las publicaciones, desplázate al índice inicial
    if (widget.initialIndex < publicaciones.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToPost(widget.initialIndex);
      });
    }
  }

  void _handleLike(String postId, int index) async {
    try {
      final postRef =
          FirebaseFirestore.instance.collection('posts').doc(postId);
      final postSnapshot = await postRef.get();
      final postData = postSnapshot.data() as Map<String, dynamic>;
      final hasLiked =
          (postData['likes']['users'] as List).contains(widget.userId);

      if (hasLiked) {
        await postRef.update({
          'likes.count': FieldValue.increment(-1),
          'likes.users': FieldValue.arrayRemove([widget.userId])
        });
        setState(() {
          publicaciones[index]['likes']['count']--;
          publicaciones[index]['likes']['users'].remove(widget.userId);
        });
      } else {
        await postRef.update({
          'likes.count': FieldValue.increment(1),
          'likes.users': FieldValue.arrayUnion([widget.userId])
        });
        setState(() {
          publicaciones[index]['likes']['count']++;
          publicaciones[index]['likes']['users'].add(widget.userId);
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
          _fetchPublicaciones(); // Refrescar publicaciones para mostrar nuevos comentarios
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
        title: Text('Publicaciones de ${widget.username}'),
      ),
      body: publicaciones.isEmpty
          ? const Center(child: Text('No hay publicaciones disponibles.'))
          : ListView.builder(
              controller: _scrollController,
              itemCount: publicaciones.length,
              itemBuilder: (context, index) {
                final post = publicaciones[index];
                final postId = post['id'];
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

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundImage: widget.profilePicture.isNotEmpty
                                ? NetworkImage(widget.profilePicture)
                                : const AssetImage('images/logo.png')
                                    as ImageProvider,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              widget.username,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_horiz),
                            itemBuilder: (BuildContext context) {
                              return [
                                const PopupMenuItem<String>(
                                  value: 'editar',
                                  child: Text('Editar'),
                                ),
                                const PopupMenuItem<String>(
                                  value: 'eliminar',
                                  child: Text('Eliminar'),
                                ),
                              ];
                            },
                            onSelected: (value) {
                              if (value == 'editar') {
                                _editarPublicacion(index, context);
                              } else if (value == 'eliminar') {
                                _eliminarPublicacion(index, context);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onDoubleTap: () {
                        _handleLike(postId, index);
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
                                  post['likes']['users'].contains(widget.userId)
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: post['likes']['users']
                                          .contains(widget.userId)
                                      ? Colors.red
                                      : null,
                                ),
                                onPressed: () => _handleLike(postId, index),
                              ),
                              Text('${post['likes']['count']}'),
                              const SizedBox(
                                  width: 3), // Espacio entre los iconos
                              IconButton(
                                icon: const Icon(Icons.comment),
                                onPressed: () =>
                                    _showCommentsBottomSheet(postId),
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

  void _editarPublicacion(int index, BuildContext context) {
    final post = publicaciones[index];
    final TextEditingController descriptionController =
        TextEditingController(text: post['description']);
    final TextEditingController hashtagsController =
        TextEditingController(text: post['hashtags'].join(' '));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar publicación'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: descriptionController,
              maxLines: null,
              decoration: const InputDecoration(
                hintText: 'Escribe una nueva descripción...',
              ),
            ),
            const SizedBox(height: 16), // Espacio entre los campos
            TextField(
              controller: hashtagsController,
              maxLines: null,
              decoration: const InputDecoration(
                hintText: 'Escribe nuevos hashtags...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              final newDescription = descriptionController.text.trim();
              final newHashtags = hashtagsController.text.trim().split(' ');

              if (newDescription.isNotEmpty || newHashtags.isNotEmpty) {
                try {
                  await FirebaseFirestore.instance
                      .collection('posts')
                      .doc(post['id'])
                      .update({
                    'description': newDescription,
                    'hashtags': newHashtags
                        .where((hashtag) => hashtag.isNotEmpty)
                        .toList(),
                  });

                  setState(() {
                    publicaciones[index]['description'] = newDescription;
                    publicaciones[index]['hashtags'] = newHashtags;
                  });

                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Publicación editado exitosamente')),
                  );
                } catch (e) {
                  print('Error al editar la publicación o hashtags: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Error al editar la publicación')),
                  );
                }
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _eliminarPublicacion(int index, BuildContext context) async {
    try {
      final postId = publicaciones[index]['id'];
      await FirebaseFirestore.instance.collection('posts').doc(postId).delete();

      setState(() {
        publicaciones.removeAt(index);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Publicación eliminada exitosamente')),
      );
    } catch (e) {
      print('Error al eliminar la publicación: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al eliminar la publicación')),
      );
    }
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
