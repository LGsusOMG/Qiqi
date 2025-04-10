import 'package:flutter/material.dart';
//import 'package:xtats001/pages/widget/widget_support.dart';
import 'package:xtats001/pages/widget/widget_support.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class Desc extends StatefulWidget {
  const Desc({super.key});

  @override
  State<Desc> createState() => _DescState();
}

class _DescState extends State<Desc> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        margin: const EdgeInsets.only(top: 80.0, left: 10.0, right: 1.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                },
                child: const Icon(
                  Icons.arrow_back_ios_new_outlined,
                  color: Color.fromARGB(255, 0, 0, 0),
                )),
            // Image.asset("images/portada1.png",
            //   height: MediaQuery.of(context).size.height / 4,
            // width: MediaQuery.of(context).size.width / 3,
            // fit: BoxFit.fill),

            // SizedBox(height: 5.0,),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  child: Material(
                      elevation: .1,
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Image.asset("images/portada1.jpg",
                                height: MediaQuery.of(context).size.height / 4,
                                width: MediaQuery.of(context).size.width / 2,
                                fit: BoxFit.cover),
                            const SizedBox(height: 9.0),
                            Text("Paradoom",
                                style: AppWidget.boldTextFeildStyle()),
                            const SizedBox(height: 5.0),
                            // RatingBar
                            RatingBar.builder(
                              initialRating: 4.5, // Calificación inicial
                              minRating: 1, // Calificación mínima
                              direction: Axis.horizontal,
                              allowHalfRating: true,
                              itemCount: 5,
                              itemPadding:
                                  const EdgeInsets.symmetric(horizontal: 4.0),
                              itemBuilder: (context, _) => const Icon(
                                Icons.star,
                                color: Colors.amber,
                              ),
                              onRatingUpdate: (rating) {
                                print(rating);
                              },
                            ),
                          ],
                        ),
                      )),
                )
              ],
            ),
            //Descripcion
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SingleChildScrollView(
                  child: Material(
                      child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        "Género:\n- Acción en primera persona (FPS)\n- Ciencia ficción\n- Terror psicológico",
                        style: AppWidget.boldTextFeildStyle()
                            .copyWith(fontSize: 13),
                        textAlign: TextAlign.start,
                      ),
                    ],
                  )),
                )
              ],
            ),

            const Text(
              "Sinopsis: En un futuro distópico, la humanidad ha alcanzado avances científicos impensables, pero estos avances trajeron consigo horrores incontrolables. Paradoom es un videojuego de acción en primera persona donde el jugador encarna a Ethan Wolfe, un ingeniero cibernético que trabaja en Paradoom Industries, una megacorporación que accidentalmente ha abierto portales a realidades alternas y desatado criaturas indescriptibles que amenazan con destruir la realidad misma.",
              maxLines: 15,
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(bottom: 40.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Precio:",
                        style: AppWidget.boldTextFeildStyle(),
                      ),
                      Text(
                        "\$200",
                        style: AppWidget.boldTextFeildStyle(),
                      ),
                      Container(
                          width: MediaQuery.of(context).size.width / 2,
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Flexible(
                                child: Text(
                                  "Añadir al carrito",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18.0,
                                    fontFamily: 'Ubuntu',
                                  ),
                                  overflow: TextOverflow
                                      .ellipsis, // Evita desbordamiento del texto
                                ),
                              ),
                              const SizedBox(
                                width: 10,
                              ),
                              Container(
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  color: Colors.purple,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.shopping_cart_outlined,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ))
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
