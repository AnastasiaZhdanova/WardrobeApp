abstract final class Routes {
  static const wardrobe = '/';

  static const style = '/style';

  static const reviewQueue = '/review';

  static String review(String id) => '/review/$id';

  static String item(String id) => '/item/$id';
}
