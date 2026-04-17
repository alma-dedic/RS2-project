import 'package:heartforcharity_desktop/model/responses/review.dart';
import 'package:heartforcharity_desktop/providers/base_provider.dart';

class ReviewProvider extends BaseProvider<Review> {
  ReviewProvider() : super('review');

  @override
  Review fromJson(data) => Review.fromJson(data);
}
