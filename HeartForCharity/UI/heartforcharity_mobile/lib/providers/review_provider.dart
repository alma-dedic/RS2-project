import 'package:heartforcharity_mobile/model/responses/review.dart';
import 'package:heartforcharity_mobile/providers/base_provider.dart';

class ReviewProvider extends BaseProvider<Review> {
  ReviewProvider() : super('review');

  @override
  Review fromJson(data) => Review.fromJson(data);
}
