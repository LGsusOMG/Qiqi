class UnboardingContent {
  String image;
  String title;
  String description;
  UnboardingContent(
      {required this.description, required this.image, required this.title});
}

List<UnboardingContent> contents = [
  UnboardingContent(
      description: 'wachiwachiwa',
      image: 'images/portada1.jpg',
      title: 'sepalabola'),
  UnboardingContent(
      description: 'description',
      image: 'images/portada2.jpg',
      title: 'sepalabola2'),
  UnboardingContent(
      description: 'description2',
      image: 'images/portada3.jpg',
      title: 'sepalabola3')
];
