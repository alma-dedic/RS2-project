import 'package:heartforcharity_desktop/model/responses/category.dart';
import 'package:heartforcharity_desktop/providers/base_provider.dart';

class CategoryProvider extends BaseProvider<Category> {
  CategoryProvider() : super('category');

  @override
  Category fromJson(data) => Category.fromJson(data);
}
