import 'package:heartforcharity_shared/model/responses/review.dart';
import 'package:heartforcharity_shared/providers/base_provider.dart';

class ReviewProvider extends BaseProvider<Review> {
  ReviewProvider() : super('review');

  @override
  Review fromJson(data) => Review.fromJson(data);
}
